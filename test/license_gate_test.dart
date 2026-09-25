// Offline activation gate — end-to-end widget tests.
//
// The gate is the first thing a fresh install shows, so it has to be right
// without ever touching the network. These tests prove:
//   • `testLicensed: false` / an empty database lands on the activation
//     screen (branding, fingerprint card, form, offline badge) — never on
//     the login or the signed-in app.
//   • The real gate re-validates on **every** start: a valid stored license
//     opens the app, while an expired one or one bound to another device
//     falls straight back to activation.
//   • A complete paste-code → activate → licensed hand-off flips the gate.
//   • Every rejection status maps to its exact Arabic copy (and raw
//     exceptions never leak).
//   • The form disables its action until both fields hold text, enforces the
//     minimum name length, and lays out without overflow at 320px.

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taj_license_core/taj_license_core.dart';

import 'package:taj/core/format.dart';
import 'package:taj/data/local/app_database.dart';
import 'package:taj/main.dart';
import 'package:taj/modules/activation/license_service.dart';

const _customer = 'متجر النور';
const _activateLabel = 'تفعيل النظام أوفلاين';

/// Payload with sane defaults: issued an hour ago, valid for a year.
LicensePayload _payload({
  required String fingerprint,
  String customerName = _customer,
  String planCode = 'taj_pos_pro',
  DateTime? issuedAt,
  DateTime? expiresAt,
}) {
  final now = DateTime.now().toUtc();
  return LicensePayload(
    licenseId: 'TJ-20260925-TEST00001',
    customerName: customerName,
    fingerprint: fingerprint,
    planCode: planCode,
    deviceCount: 1,
    issuedAt:
        (issuedAt ?? now.subtract(const Duration(hours: 1))).millisecondsSinceEpoch,
    expiresAt: (expiresAt ?? now.add(const Duration(days: 365))).millisecondsSinceEpoch,
  );
}

String _code(LicensePayload payload) => TajLicenseCodec.issue(payload);

/// Resolves this machine's fingerprint once for the whole test file.
///
/// The underlying lookups are real I/O, so they have to run outside the fake
/// async zone; after this the cached future is already completed and the
/// screen can await it inside the test zone.
Future<String> _warmFingerprint(WidgetTester tester) async {
  final fp = await tester.runAsync(() => LicenseService.deviceFingerprint());
  expect(fp, isNotNull, reason: 'fingerprint should resolve');
  return fp!;
}

AppDatabase _db(WidgetTester tester) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

/// One real-zone yield followed by one frame.
///
/// The device fingerprint comes from real I/O (`tester.runAsync`), so the
/// listeners the app attaches to it only run once control goes back to the
/// *real* event loop — pumping the fake zone alone never flushes them. Every
/// step therefore yields for a tick and then advances a frame.
Future<void> _step(
  WidgetTester tester, {
  Duration time = const Duration(milliseconds: 120),
}) async {
  await tester.runAsync(() async {});
  await tester.pump(time);
}

/// Bounded steps — the gate splash and the fingerprint card both show an
/// indeterminate spinner, so `pumpAndSettle` would never return.
Future<void> _pumps(WidgetTester tester, {int count = 5}) async {
  for (var i = 0; i < count; i++) {
    await _step(tester);
  }
}

Future<void> _setSize(WidgetTester tester, double w, double h) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(w, h);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pump();
}

Future<void> _pumpGate(
  WidgetTester tester,
  AppDatabase db, {
  bool? licensed,
}) async {
  await tester.pumpWidget(TajApp(
    testDatabase: db,
    testLicensed: licensed,
  ));
  await _pumps(tester);
}

Future<void> _fill({
  required WidgetTester tester,
  required String name,
  required String code,
}) async {
  final fields = find.byType(TextFormField);
  expect(fields, findsNWidgets(2), reason: 'name + license code');
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), code);
  await tester.pump();
}

Future<void> _tapActivate(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, _activateLabel);
  expect(button, findsOneWidget);
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await _pumps(tester, count: 3);
}

/// The activation screen, ready for input.
Future<void> _pumpActivation(
  WidgetTester tester,
  AppDatabase db, {
  double width = 1200,
  double height = 900,
}) async {
  await _setSize(tester, width, height);
  await _pumpGate(tester, db, licensed: false);
}

void main() {
  // Every test builds its own in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('gate — where a device lands on start', () {
    testWidgets('forced unlicensed shows the activation screen', (tester) async {
      await _warmFingerprint(tester);
      await _pumpActivation(tester, _db(tester));

      expect(find.text('تفعيل نظام تاج'), findsWidgets);
      expect(find.text('تفعيل النظام أوفلاين'), findsOneWidget);
      expect(find.text('تفعيل أوفلاين — دون إنترنت'), findsWidgets);
      expect(find.text('بصمة الجهاز'), findsOneWidget);
      expect(find.text('اسم الزبون'), findsOneWidget);
      expect(find.text('كود الترخيص'), findsOneWidget);
      expect(find.text('استيراد ملف ترخيص (.tajlic)'), findsOneWidget);

      // Never the signed-in app or the login page.
      expect(find.text('تسجيل الدخول'), findsNothing);
      expect(find.text('لوحة التحكم'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty database: splash, then activation', (tester) async {
      await _warmFingerprint(tester);
      await _setSize(tester, 1200, 900);
      await tester.pumpWidget(TajApp(testDatabase: _db(tester)));

      // Phase 1 — status is still being read (first frame).
      expect(find.text('جارٍ التحقق من الترخيص…'), findsOneWidget);
      expect(find.text('تفعيل نظام تاج'), findsNothing);

      // Phase 2 — nothing stored → activation.
      await _pumps(tester);
      expect(find.text('جارٍ التحقق من الترخيص…'), findsNothing);
      expect(find.text('تفعيل نظام تاج'), findsWidgets);
      expect(find.text('تسجيل الدخول'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('valid stored license opens the app', (tester) async {
      final db = _db(tester);
      final fp = await _warmFingerprint(tester);
      final payload = _payload(fingerprint: fp);
      await tester.runAsync(() => LicenseService.activate(
            db: db,
            code: _code(payload),
            customerName: _customer,
          ));

      await _setSize(tester, 1200, 900);
      await tester.pumpWidget(TajApp(testDatabase: db));
      await _pumps(tester);

      expect(find.text('تفعيل نظام تاج'), findsNothing);
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('license bound to another device is rejected again',
        (tester) async {
      await _warmFingerprint(tester);
      final db = _db(tester);
      final foreign = TajDeviceFingerprint.deriveFromSource('another-machine');
      final payload = _payload(fingerprint: foreign);
      final code = _code(payload);
      await tester.runAsync(() async {
        await db.upsertLicense(
          id: 'lic_foreign',
          code: code,
          customerName: payload.customerName,
          fingerprint: payload.fingerprint,
          planCode: payload.planCode,
          issuedAt: payload.issuedAtDate,
          expiresAt: payload.expiresAtDate,
          activatedAt: DateTime.now().toUtc(),
        );
      });

      await _setSize(tester, 1200, 900);
      await tester.pumpWidget(TajApp(testDatabase: db));
      await _pumps(tester);

      // Re-validated on start → back to the gate, not the app.
      expect(find.text('تفعيل نظام تاج'), findsWidgets);
      expect(find.text('تسجيل الدخول'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expired stored license is rejected again', (tester) async {
      final db = _db(tester);
      final fp = await _warmFingerprint(tester);
      final payload = _payload(
        fingerprint: fp,
        issuedAt: DateTime.now().toUtc().subtract(const Duration(days: 400)),
        expiresAt: DateTime.now().toUtc().subtract(const Duration(days: 5)),
      );
      await tester.runAsync(() async {
        await db.upsertLicense(
          id: 'lic_expired',
          code: _code(payload),
          customerName: payload.customerName,
          fingerprint: payload.fingerprint,
          planCode: payload.planCode,
          issuedAt: payload.issuedAtDate,
          expiresAt: payload.expiresAtDate,
          activatedAt: DateTime.now().toUtc(),
        );
      });

      await _setSize(tester, 1200, 900);
      await tester.pumpWidget(TajApp(testDatabase: db));
      await _pumps(tester);

      expect(find.text('تفعيل نظام تاج'), findsWidgets);
      expect(find.text('تسجيل الدخول'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('gate — activation hand-off', () {
    testWidgets('paste a code, activate, the gate flips to the app',
        (tester) async {
      final db = _db(tester);
      final fp = await _warmFingerprint(tester);

      await _setSize(tester, 1200, 900);
      await tester.pumpWidget(TajApp(testDatabase: db));
      await _pumps(tester);
      expect(find.text('تفعيل نظام تاج'), findsWidgets);

      final payload = _payload(fingerprint: fp);
      await _fill(tester: tester, name: _customer, code: _code(payload));
      await _tapActivate(tester);

      // Success is shown while the gate re-reads storage.
      expect(find.text('تم التفعيل بنجاح'), findsOneWidget);
      expect(find.text('تعذّر إتمام التفعيل — تأكد من الكود وحاول مرة أخرى.'),
          findsNothing);

      final stored = await tester.runAsync(() => db.getActiveLicense());
      expect(stored, isNotNull, reason: 'license persisted locally');
      expect(stored!.fingerprint, fp);
      expect(stored.planCode, 'taj_pos_pro');
      // The name signed into the payload wins over the typed one.
      expect(stored.customerName, payload.customerName);
      expect(stored.code, _code(payload));

      // The delayed hand-off re-enters the gate → licensed → login page.
      await _step(tester, time: const Duration(milliseconds: 900));
      await _pumps(tester, count: 3);
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('تفعيل نظام تاج'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('deactivate clears storage, so the gate reopens',
        (tester) async {
      final db = _db(tester);
      final fp = await _warmFingerprint(tester);
      final payload = _payload(fingerprint: fp);
      await tester.runAsync(() => LicenseService.activate(
            db: db,
            code: _code(payload),
            customerName: _customer,
          ));
      await tester.runAsync(() => LicenseService.deactivate(db));

      final stored = await tester.runAsync(() => db.getActiveLicense());
      expect(stored, isNull, reason: 'deactivate clears the single row');

      await _setSize(tester, 1200, 900);
      await tester.pumpWidget(TajApp(testDatabase: db));
      await _pumps(tester);
      expect(find.text('تفعيل نظام تاج'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('gate — exact Arabic copy per rejection', () {
    testWidgets('malformed code', (tester) async {
      await _warmFingerprint(tester);
      await _pumpActivation(tester, _db(tester));
      await _fill(tester: tester, name: _customer, code: 'XYZ');
      await _tapActivate(tester);

      expect(find.text('كود الترخيص غير صالح — تأكد من نسخه كاملاً'),
          findsOneWidget);
      expect(find.text('تم التفعيل بنجاح'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty code never leaves the button enabled', (tester) async {
      await _warmFingerprint(tester);
      await _pumpActivation(tester, _db(tester));
      final button = find.widgetWithText(FilledButton, _activateLabel);
      expect(tester.widget<FilledButton>(button).onPressed, isNull,
          reason: 'both fields are empty');

      await _fill(tester: tester, name: _customer, code: '   ');
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNull,
          reason: 'whitespace-only code counts as empty');
      expect(tester.takeException(), isNull);
    });

    testWidgets('name shorter than 2 characters', (tester) async {
      await _warmFingerprint(tester);
      await _pumpActivation(tester, _db(tester));
      final payload = _payload(fingerprint: 'AABB-CCDD-EEFF-0011-2233-4455-'
          '6677-8899');
      await _fill(tester: tester, name: 'م', code: _code(payload));
      final button = find.widgetWithText(FilledButton, _activateLabel);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();

      expect(find.text('اسم الزبون قصير جداً'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expired code carries its date', (tester) async {
      // Must be bound to this device, otherwise the fingerprint check would
      // win and the expiry copy would never be reached.
      final fp = await _warmFingerprint(tester);
      await _pumpActivation(tester, _db(tester));
      final payload = _payload(
        fingerprint: fp,
        issuedAt: DateTime.now().toUtc().subtract(const Duration(days: 400)),
        expiresAt: DateTime.now().toUtc().subtract(const Duration(days: 5)),
      );
      await _fill(tester: tester, name: _customer, code: _code(payload));
      await _tapActivate(tester);

      expect(
        find.text(
            'انتهى الترخيص في ${arDate(payload.expiresAtDate.toLocal())}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fingerprint mismatch shows both fingerprints',
        (tester) async {
      await _warmFingerprint(tester);
      await _pumpActivation(tester, _db(tester));
      final foreign = TajDeviceFingerprint.deriveFromSource('another-machine');
      final payload = _payload(fingerprint: foreign);
      await _fill(tester: tester, name: _customer, code: _code(payload));
      await _tapActivate(tester);

      expect(find.textContaining('هذا الترخيص مرتبط بجهاز آخر'), findsOneWidget);
      expect(find.text(foreign), findsOneWidget, reason: 'required fingerprint');
      expect(find.text('بصمة الترخيص'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tampered signature', (tester) async {
      await _warmFingerprint(tester);
      await _pumpActivation(tester, _db(tester));
      final payload = _payload(fingerprint: 'AABB-CCDD-EEFF-0011-2233-4455-'
          '6677-8899');
      final code = _code(payload);
      final parts = code.split('.');
      final sig = parts[2];
      parts[2] = (sig[0] == 'A' ? 'B' : 'A') + sig.substring(1);

      await _fill(tester: tester, name: _customer, code: parts.join('.'));
      await _tapActivate(tester);

      expect(find.text('كود الترخيص تالِف أو تم العبث به'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('gate — layout', () {
    testWidgets('320×568 portrait renders without overflow', (tester) async {
      await _warmFingerprint(tester);
      await _pumpActivation(tester, _db(tester), width: 320, height: 568);

      expect(find.text('تفعيل نظام تاج'), findsWidgets);
      expect(find.text('تفعيل النظام أوفلاين'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('568×320 landscape renders without overflow', (tester) async {
      await _warmFingerprint(tester);
      await _pumpActivation(tester, _db(tester), width: 568, height: 320);

      expect(find.text('تفعيل نظام تاج'), findsWidgets);
      expect(find.text('تفعيل النظام أوفلاين'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
