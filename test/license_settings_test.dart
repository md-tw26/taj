// Settings → «الترخيص والتفعيل» — status, data and deactivation.
//
// Proves the license section behaves on its own:
//   • Mounted standalone (no LicenseScope) it degrades to a safe, read-only
//     «غير مفعّل» state with the destructive action disabled.
//   • Mounted inside a licensed scope it shows the badge, the signed payload
//     (customer, id, plan, dates, days left, fingerprint).
//   • Every badge branch: healthy, soon-to-expire (warning) and expired.
//   • Deactivation is gated behind the confirm dialog — «تراجع» aborts,
//     «نعم، إلغاء التفعيل» clears storage and flips the section.
//   • No overflow at 320px with long values, in RTL and LTR.

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taj_license_core/taj_license_core.dart';

import 'package:taj/core/chart_style.dart';
import 'package:taj/core/format.dart';
import 'package:taj/core/theme/app_themes.dart';
import 'package:taj/core/theme/taj_colors.dart';
import 'package:taj/data/database_provider.dart';
import 'package:taj/data/local/app_database.dart';
import 'package:taj/modules/activation/license_scope.dart';
import 'package:taj/modules/activation/license_service.dart';
import 'package:taj/modules/settings/settings_models.dart';
import 'package:taj/modules/settings/settings_screen.dart';

const _customer = 'متجر النور';
const _licenseId = 'TJ-20260925-1A2B3C4D';
const _fingerprint = 'A1B2-C3D4-E5F6-0718-293A-4B5C-6D7E-8F90';

LicensePayload _payload({required int daysLeft}) {
  final now = DateTime.now().toUtc();
  return LicensePayload(
    licenseId: _licenseId,
    customerName: _customer,
    fingerprint: _fingerprint,
    planCode: 'taj_pos_pro',
    deviceCount: 1,
    issuedAt: now.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
    expiresAt: now.add(Duration(days: daysLeft)).millisecondsSinceEpoch,
  );
}

MaterialApp _app(Widget home, TextDirection dir) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      locale: Locale(dir == TextDirection.rtl ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(textDirection: dir, child: home),
    );

/// Settings alone — no `LicenseScope` anywhere above it.
Widget _standaloneHost(TextDirection dir) => _app(
      Scaffold(
        body: SettingsScreen(
          currentPrimary: TajColors.blueSwatch,
          onPrimaryChanged: _noop,
          onToggleTheme: _noopVoid,
          chartStyle: ChartStyle.area,
          onChartStyleChanged: _noopChart,
          testInitialSection: SettingsSectionId.license,
        ),
      ),
      dir,
    );

void _noop(TajSwatch _) {}
void _noopVoid() {}
void _noopChart(ChartStyle _) {}

/// Settings under the real gate: database + license scope, exactly like
/// `TajApp` mounts them.
Widget _scopedHost({
  required TextDirection dir,
  required ValueNotifier<LicenseGateState> state,
  required AppDatabase db,
  required Future<void> Function() refresh,
}) =>
    _app(
      DatabaseProvider(
        db: db,
        child: LicenseScope(
          state: state,
          refresh: refresh,
          child: Scaffold(
            body: SettingsScreen(
              currentPrimary: TajColors.blueSwatch,
              onPrimaryChanged: _noop,
              onToggleTheme: _noopVoid,
              chartStyle: ChartStyle.area,
              onChartStyleChanged: _noopChart,
              testInitialSection: SettingsSectionId.license,
            ),
          ),
        ),
      ),
      dir,
    );

Future<void> _pump(WidgetTester tester, Widget host) async {
  await tester.pumpWidget(host);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _setSize(WidgetTester tester, double w, double h) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(w, h);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _label(String text) => find.text(text);

Finder _deactivateButton() =>
    find.widgetWithText(OutlinedButton, 'إلغاء تفعيل الجهاز');

Future<void> _tapDeactivate(WidgetTester tester) async {
  final button = _deactivateButton();
  expect(button, findsOneWidget);
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  // Every test builds its own in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('license section — standalone (no scope)', () {
    testWidgets('degrades to a safe, disabled «غير مفعّل» state',
        (tester) async {
      await _setSize(tester, 1200, 900);
      await _pump(tester, _standaloneHost(TextDirection.rtl));

      expect(find.text('الترخيص والتفعيل'), findsWidgets);
      expect(_label('غير مفعّل'), findsOneWidget);
      expect(_label('النظام في وضع التفعيل حتى إدخال كود صالح.'), findsOneWidget);
      expect(_label('—'), findsWidgets, reason: 'no payload → em dashes');

      final button = tester.widget<OutlinedButton>(_deactivateButton());
      expect(button.onPressed, isNull, reason: 'nothing to deactivate');
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at 320px in both directions without overflow',
        (tester) async {
      for (final dir in const [TextDirection.rtl, TextDirection.ltr]) {
        await _setSize(tester, 320, 568);
        await _pump(tester, _standaloneHost(dir));
        expect(find.text('حالة الترخيص'), findsWidgets);
        expect(_label('غير مفعّل'), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'license section @ 320 ${dir.name}');
      }
    });
  });

  group('license section — licensed scope', () {
    testWidgets('shows badge, signed payload and enabled deactivation',
        (tester) async {
      final payload = _payload(daysLeft: 365);
      final state = ValueNotifier<LicenseGateState>(
        LicenseGateState.licensed(payload),
      );
      addTearDown(state.dispose);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await _setSize(tester, 1200, 900);
      await _pump(tester, _scopedHost(
        dir: TextDirection.rtl,
        state: state,
        db: db,
        refresh: () async {},
      ));

      // Badge — healthy.
      expect(_label('ترخيص ساري'), findsOneWidget);

      // Signed payload, row by row.
      expect(_label(_customer), findsOneWidget);
      expect(_label(_licenseId), findsOneWidget);
      expect(_label('تاج برو POS'), findsOneWidget);
      expect(_label(arDate(payload.issuedAtDate.toLocal())), findsOneWidget);
      expect(_label(arDate(payload.expiresAtDate.toLocal())), findsOneWidget);
      expect(_label('${arNum(365)} يوم'), findsOneWidget);
      expect(_label(payload.fingerprint), findsOneWidget);

      // Row captions are present too.
      for (final caption in const [
        'اسم الزبون',
        'رقم الترخيص',
        'الباقة',
        'تاريخ الإصدار',
        'تاريخ الانتهاء',
        'الأيام المتبقية',
        'بصمة الجهاز',
      ]) {
        expect(_label(caption), findsWidgets, reason: caption);
      }

      final button = tester.widget<OutlinedButton>(_deactivateButton());
      expect(button.onPressed, isNotNull, reason: 'licensed → actionable');
      expect(tester.takeException(), isNull);
    });

    testWidgets('warns when 30 days or fewer remain', (tester) async {
      final state = ValueNotifier<LicenseGateState>(
        LicenseGateState.licensed(_payload(daysLeft: 10)),
      );
      addTearDown(state.dispose);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await _setSize(tester, 1200, 900);
      await _pump(tester, _scopedHost(
        dir: TextDirection.rtl,
        state: state,
        db: db,
        refresh: () async {},
      ));

      expect(_label('ينتهي خلال ${arNum(10)} يوم'), findsOneWidget);
      expect(_label('ترخيص ساري'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expired payload reports «منتهٍ»', (tester) async {
      final state = ValueNotifier<LicenseGateState>(
        LicenseGateState.unlicensed(
          status: LicenseStatus.expired,
          payload: _payload(daysLeft: -1),
        ),
      );
      addTearDown(state.dispose);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await _setSize(tester, 1200, 900);
      await _pump(tester, _scopedHost(
        dir: TextDirection.rtl,
        state: state,
        db: db,
        refresh: () async {},
      ));

      expect(_label('منتهٍ'), findsOneWidget);
      expect(_label('غير مفعّل'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('long values never overflow at 320px, RTL and LTR',
        (tester) async {
      final payload = _payload(daysLeft: 3);
      final state = ValueNotifier<LicenseGateState>(
        LicenseGateState.licensed(payload),
      );
      addTearDown(state.dispose);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      for (final dir in const [TextDirection.rtl, TextDirection.ltr]) {
        await _setSize(tester, 320, 568);
        await _pump(tester, _scopedHost(
          dir: dir,
          state: state,
          db: db,
          refresh: () async {},
        ));

        expect(_label('ترخيص ساري'), findsNothing);
        expect(_label('ينتهي خلال ${arNum(3)} يوم'), findsOneWidget);
        expect(_label(_customer), findsOneWidget);
        expect(_label(payload.fingerprint), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'licensed section @ 320 ${dir.name}');
      }
    });
  });

  group('license section — deactivation', () {
    testWidgets('«تراجع» aborts and keeps the license', (tester) async {
      final state = ValueNotifier<LicenseGateState>(
        LicenseGateState.licensed(_payload(daysLeft: 365)),
      );
      addTearDown(state.dispose);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await _setSize(tester, 1200, 900);
      await _pump(tester, _scopedHost(
        dir: TextDirection.rtl,
        state: state,
        db: db,
        refresh: () async {},
      ));

      await _tapDeactivate(tester);
      expect(find.text('تأكيد الإجراء'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);
      expect(find.text('نعم، إلغاء التفعيل'), findsOneWidget);

      await tester.tap(find.text('تراجع'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('تأكيد الإجراء'), findsNothing);
      expect(state.value.isLicensed, isTrue, reason: 'gate untouched');
      expect(_label('ترخيص ساري'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('confirm clears storage and flips the section',
        (tester) async {
      final payload = _payload(daysLeft: 365);
      final state = ValueNotifier<LicenseGateState>(
        LicenseGateState.licensed(payload),
      );
      addTearDown(state.dispose);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      // Mirrors `_TajAppState._refreshLicense`: re-read + re-validate.
      Future<void> refresh() async =>
          state.value = await LicenseService.loadStatus(db);

      await _setSize(tester, 1200, 900);
      await _pump(tester, _scopedHost(
        dir: TextDirection.rtl,
        state: state,
        db: db,
        refresh: refresh,
      ));
      expect(_label('ترخيص ساري'), findsOneWidget);

      await _tapDeactivate(tester);
      await tester.tap(find.text('نعم، إلغاء التفعيل'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('تأكيد الإجراء'), findsNothing);
      expect(state.value.isUnlicensed, isTrue);
      expect(_label('غير مفعّل'), findsOneWidget);
      expect(_label('ترخيص ساري'), findsNothing);

      final button = tester.widget<OutlinedButton>(_deactivateButton());
      expect(button.onPressed, isNull, reason: 'nothing left to deactivate');

      final stored = await tester.runAsync(() => db.getActiveLicense());
      expect(stored, isNull, reason: 'the row was removed');
      expect(tester.takeException(), isNull);
    });
  });
}
