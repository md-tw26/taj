// Cross-app interoperability: a license issued by the Taj Activation Admin
// tool must activate inside this app.
//
// The fixture `test/fixtures/cross_app_license.tajlic` is produced by the
// admin tool's real code path (`AdminDatabase` + `LicensesRepository.issue`)
// and then copied here — regenerate it with:
//   1. cd ../taj_activation_admin && flutter test test/cross_app_fixture_test.dart
//   2. cp test/fixtures/cross_app_license.tajlic ../taj-main/test/fixtures/
//
// Part 1 is machine-independent (signature + policy are checked against the
// fingerprint embedded in the payload). Part 2 drives the real activation
// screen: on the issuing device it must fully activate; on any other device
// it must be rejected with the exact fingerprint-mismatch copy.

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taj_license_core/taj_license_core.dart';

import 'package:taj/data/local/app_database.dart';
import 'package:taj/main.dart';
import 'package:taj/modules/activation/license_service.dart';

const _activateLabel = 'تفعيل النظام أوفلاين';
const _fixturePath = 'test/fixtures/cross_app_license.tajlic';

({String code, LicensePayload payload}) _fixture() {
  final envelope = File(_fixturePath).readAsStringSync();
  final code = TajlicFile.decodeCode(envelope);
  final payload = TajLicenseCodec.verifyAndDecode(code);
  return (code: code, payload: payload);
}

Future<void> _step(WidgetTester tester, {Duration time = const Duration(milliseconds: 120)}) async {
  await tester.runAsync(() async {});
  await tester.pump(time);
}

Future<void> _pumps(WidgetTester tester, {int count = 5}) async {
  for (var i = 0; i < count; i++) {
    await _step(tester);
  }
}

Future<String> _warmFingerprint(WidgetTester tester) async {
  final fp = await tester.runAsync(() => LicenseService.deviceFingerprint());
  expect(fp, isNotNull, reason: 'fingerprint should resolve');
  return fp!;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('admin → POS compatibility', () {
    test('the admin-issued fixture is authentic and valid for its device', () {
      final (:code, :payload) = _fixture();

      expect(code, startsWith('TAJ1.'));
      expect(payload.version, LicensePayload.currentVersion);
      expect(payload.customerName, 'مطعم ومخبز السلام');
      expect(payload.planCode, TajPlan.posPro.code);
      expect(TajPlan.parse(payload.planCode).arabicLabel, 'تاج برو POS');
      expect(payload.deviceCount, 1);
      expect(TajDeviceFingerprint.isValid(payload.fingerprint), isTrue);

      // Valid for the fingerprint signed into it, expired never…
      expect(
        TajLicenseValidator.evaluate(code: code, deviceFingerprint: payload.fingerprint).status,
        LicenseStatus.valid,
      );
      // …but refused everywhere else.
      expect(
        TajLicenseValidator.evaluate(
          code: code,
          deviceFingerprint: TajDeviceFingerprint.deriveFromSource('other-machine'),
        ).status,
        LicenseStatus.fingerprintMismatch,
      );
      // And tampering with the code is caught before any policy check.
      expect(
        TajLicenseValidator.evaluate(
          code: '${code.substring(0, code.length - 2)}AA',
          deviceFingerprint: payload.fingerprint,
        ).status,
        anyOf(LicenseStatus.malformed, LicenseStatus.badSignature),
      );
    });

    testWidgets('the admin-issued license runs through the real activation screen',
        (tester) async {
      final (:code, :payload) = _fixture();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final fingerprint = await _warmFingerprint(tester);
      final onThisDevice = fingerprint == payload.fingerprint;

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Production gate (no `testLicensed` override): splash → activation.
      await tester.pumpWidget(TajApp(testDatabase: db));
      await _pumps(tester);
      expect(find.text('تفعيل نظام تاج'), findsWidgets);

      await tester.enterText(find.byType(TextFormField).at(0), payload.customerName);
      await tester.enterText(find.byType(TextFormField).at(1), code);
      await tester.pump();

      final button = find.widgetWithText(FilledButton, _activateLabel);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await _pumps(tester, count: 3);

      if (onThisDevice) {
        // The admin tool's code path activates this very machine.
        expect(find.text('تم التفعيل بنجاح'), findsOneWidget);

        final stored = await tester.runAsync(() => db.getActiveLicense());
        expect(stored, isNotNull, reason: 'license persisted locally');
        expect(stored!.code, code);
        expect(stored.customerName, payload.customerName);
        expect(stored.fingerprint, fingerprint);
        expect(stored.planCode, TajPlan.posPro.code);

        // Gate re-reads storage → the signed-in app's login page.
        await _step(tester, time: const Duration(milliseconds: 900));
        await _pumps(tester, count: 3);
        expect(find.text('تسجيل الدخول'), findsOneWidget);
        expect(find.text('تفعيل نظام تاج'), findsNothing);
      } else {
        // Foreign device: exact Arabic copy, still on the gate, nothing stored.
        expect(
          find.text(
            'هذا الترخيص مرتبط بجهاز آخر — البصمة المطلوبة: ${payload.fingerprint}',
          ),
          findsOneWidget,
        );
        expect(find.text('تم التفعيل بنجاح'), findsNothing);
        expect(await tester.runAsync(() => db.getActiveLicense()), isNull);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
