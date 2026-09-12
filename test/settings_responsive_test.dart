// Settings — responsive + behavioural regression tests.
//
// Mounts the Settings module across the full spread of supported viewport sizes,
// in BOTH text directions (RTL + LTR), and — crucially — opens EVERY section at
// EVERY size, failing if any configuration throws a layout/overflow error
// (surfaced via `tester.takeException()`). It also proves the module's key
// guarantees:
//   • < settingsSplit the section list is a full page; tapping pushes the
//     section page (with a back affordance), and back returns to the list.
//   • ≥ settingsSplit a persistent sub-navigation sidebar sits beside content.
//   • Resizing wide→narrow keeps the open section (does not lose it).
//   • Editing a form field raises the unsaved-changes save bar; Save/Discard
//     clear it. Appearance edits do NOT (they apply live, off the draft).
//   • The most dangerous element — a setting row with a long Arabic description
//     and a wide control — never overflows, at 320px, in both directions.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taj/core/chart_style.dart';
import 'package:taj/core/theme/app_themes.dart';
import 'package:taj/core/theme/taj_colors.dart';
import 'package:taj/modules/settings/settings_models.dart';
import 'package:taj/modules/settings/settings_screen.dart';

const _sizes = <(String, double, double)>[
  ('phone-xs-portrait', 320, 568),
  ('phone-xs-landscape', 568, 320),
  ('phone-sm-portrait', 360, 640),
  ('phone-sm-landscape', 640, 360),
  ('phone-md-portrait', 390, 844),
  ('phone-lg-portrait', 430, 932),
  ('phone-lg-landscape', 932, 430),
  ('tablet-sm', 600, 960),
  ('tablet-portrait', 768, 1024),
  ('tablet-landscape', 1024, 768),
  ('ipad-pro-portrait', 1024, 1366),
  ('laptop-720', 1280, 720),
  ('laptop', 1366, 768),
  ('laptop-hidpi', 1440, 900),
  ('desktop', 1920, 1080),
  ('2k', 2560, 1440),
  ('ultrawide', 3440, 1440),
  ('4k', 3840, 2160),
];

// Every section's on-screen title (as shown in the content header / top bar),
// used to open each one and assert it rendered.
const _sectionTitles = <(SettingsSectionId, String)>[
  (SettingsSectionId.appearance, 'المظهر'),
  (SettingsSectionId.localization, 'اللغة والعملة والضرائب'),
  (SettingsSectionId.invoice, 'الفواتير والطباعة'),
  (SettingsSectionId.discount, 'سياسة الخصم'),
  (SettingsSectionId.dayClosing, 'سياسة الإقفال اليومي'),
  (SettingsSectionId.sync, 'المزامنة والنسخ الاحتياطي'),
];

Widget _host(
  TextDirection dir, {
  SettingsSectionId? initial,
  ValueChanged<TajSwatch>? onPrimary,
  VoidCallback? onToggle,
  ValueChanged<ChartStyle>? onChart,
}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      locale: Locale(dir == TextDirection.rtl ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: dir,
        child: Scaffold(
          body: SettingsScreen(
            // A per-section key forces a fresh State when the loop re-pumps with
            // a different initial section (otherwise Flutter reuses the State and
            // initState's testInitialSection is only applied once).
            key: ValueKey(initial),
            currentPrimary: TajColors.blueSwatch,
            onPrimaryChanged: onPrimary ?? (_) {},
            onToggleTheme: onToggle ?? () {},
            chartStyle: ChartStyle.area,
            onChartStyleChanged: onChart ?? (_) {},
            testInitialSection: initial,
          ),
        ),
      ),
    );

Future<void> _pumpAt(WidgetTester tester, double w, double h, Widget child) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(w, h);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(child);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('Settings — every section, every size, no overflow (RTL + LTR)', () {
    for (final (label, w, h) in _sizes) {
      for (final dir in const [TextDirection.rtl, TextDirection.ltr]) {
        final dl = dir == TextDirection.rtl ? 'rtl' : 'ltr';
        testWidgets('$label $dl ($w×$h)', (tester) async {
          for (final (id, title) in _sectionTitles) {
            // Open each section directly (as if tapped) and verify it lays out
            // cleanly at this size in this direction.
            await _pumpAt(tester, w, h, _host(dir, initial: id));
            expect(tester.takeException(), isNull,
                reason: 'section "$title" @ $label $dl');
            expect(find.text(title), findsWidgets,
                reason: 'section "$title" rendered @ $label $dl');
          }
        });
      }
    }
  });

  testWidgets('narrow: list → pushed section → back to list', (tester) async {
    await _pumpAt(tester, 390, 844, _host(TextDirection.rtl));
    // The list page shows the section cards.
    expect(find.text('الإعدادات'), findsWidgets);
    expect(find.text('سياسة الخصم'), findsWidgets);

    // Tap a section → its page is pushed (a back button appears).
    await tester.tap(find.text('سياسة الخصم').first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget); // RTL back
    expect(find.text('تفعيل سياسة الخصم'), findsWidgets);

    // Back returns to the list.
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();
    expect(find.text('المظهر'), findsWidgets);
    expect(find.text('المزامنة والنسخ الاحتياطي'), findsWidgets);
  });

  testWidgets('wide: persistent sidebar shows content beside the nav', (tester) async {
    await _pumpAt(tester, 1200, 900, _host(TextDirection.rtl));
    // Sidebar title + a content header for the default (appearance) section.
    expect(find.text('اللون والوضع'), findsWidgets);
    // Selecting another section swaps the content in place.
    await tester.tap(find.text('الفواتير والطباعة').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('محتوى الفاتورة'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resize wide→narrow keeps the open section', (tester) async {
    await _pumpAt(tester, 1200, 900, _host(TextDirection.rtl));
    await tester.tap(find.text('الفواتير والطباعة').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('محتوى الفاتورة'), findsWidgets);

    // Shrink across settingsSplit (820) down to a phone width.
    for (final w in const [1100.0, 900.0, 700.0, 500.0]) {
      tester.view.physicalSize = Size(w, 900);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: 'resize @ $w');
    }
    // The invoice section is still open (not reset to the list).
    expect(find.text('محتوى الفاتورة'), findsWidgets);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
  });

  testWidgets('editing a form field raises the save bar; save + discard clear it',
      (tester) async {
    await _pumpAt(
        tester, 1200, 900, _host(TextDirection.rtl, initial: SettingsSectionId.localization));
    expect(find.text('لديك تغييرات غير محفوظة'), findsNothing);

    // Toggle "السعر شامل الضريبة" → dirty.
    final row = find.ancestor(
      of: find.text('السعر شامل الضريبة'),
      matching: find.byType(Row),
    );
    final theSwitch = find.descendant(of: row.first, matching: find.byType(Switch));
    await tester.tap(theSwitch.first);
    await tester.pump();
    expect(find.text('لديك تغييرات غير محفوظة'), findsOneWidget);

    // Discard clears it.
    await tester.tap(find.text('تجاهل'));
    await tester.pump();
    expect(find.text('لديك تغييرات غير محفوظة'), findsNothing);

    // Toggle again then Save clears it.
    await tester.tap(theSwitch.first);
    await tester.pump();
    expect(find.text('لديك تغييرات غير محفوظة'), findsOneWidget);
    await tester.tap(find.text('حفظ التغييرات'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('لديك تغييرات غير محفوظة'), findsNothing);
  });

  testWidgets('appearance edits apply live and do NOT raise the save bar',
      (tester) async {
    var toggled = false;
    await _pumpAt(
      tester,
      1200,
      900,
      _host(TextDirection.rtl,
          initial: SettingsSectionId.appearance, onToggle: () => toggled = true),
    );
    // Toggle dark mode from within Appearance.
    final row = find.ancestor(
      of: find.text('الوضع الداكن'),
      matching: find.byType(Row),
    );
    final theSwitch = find.descendant(of: row.first, matching: find.byType(Switch));
    await tester.tap(theSwitch.first);
    await tester.pump();
    expect(toggled, isTrue, reason: 'live callback fired');
    expect(find.text('لديك تغييرات غير محفوظة'), findsNothing,
        reason: 'appearance is live, not a draft edit');
  });

  testWidgets('discount multi-select opens a picker and edits the selection',
      (tester) async {
    await _pumpAt(tester, 390, 844,
        _host(TextDirection.rtl, initial: SettingsSectionId.discount));
    // Bring the first chips-field "edit" affordance into view and open it.
    final editChip = find.text('تعديل التحديد').first;
    await tester.ensureVisible(editChip);
    await tester.pumpAndSettle();
    await tester.tap(editChip);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The picker (bottom sheet on phone) shows the option list + a done button.
    expect(find.byType(CheckboxListTile), findsWidgets);
    expect(find.textContaining('تم ('), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
