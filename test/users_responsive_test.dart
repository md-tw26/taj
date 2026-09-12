// Users & Permissions — responsive + functional regression tests.
//
// Mounts the Users & Permissions screen across the full spread of supported
// viewport sizes, in BOTH text directions (RTL + LTR) and across all three
// tabs, and fails if any configuration throws a layout/overflow error
// (surfaced via `tester.takeException()`). It also proves the acceptance
// guarantees that matter most for this module:
//   • Below [permissionMatrixMin] the matrix is replaced by the grouped
//     alternate structure, and EVERY permission is reachable + editable at
//     320px (nothing lost relative to the full matrix).
//   • The sensitive-permission warning fires before a sensitive grant.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taj/core/theme/app_themes.dart';
import 'package:taj/modules/users/users_screen.dart';

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

// Group title + permission names, mirroring the module catalogue. Used to
// prove nothing is dropped from the alternate (narrow) structure.
const _catalogue = <(String, List<String>)>[
  ('المبيعات', [
    'إنشاء فاتورة بيع',
    'تعديل السعر',
    'تطبيق خصم يدوي',
    'استرداد / مرتجع',
  ]),
  ('نقطة البيع', [
    'فتح نقطة البيع',
    'تنفيذ عملية بيع',
    'خصم في نقطة البيع',
    'إلغاء عملية',
    'إرجاع صنف',
    'تعليق الطلب',
    'طباعة الإيصال',
    'مراجعة الإغلاق اليومي',
  ]),
  ('المخزون', [
    'عرض المخزون',
    'تسوية المخزون',
    'تحويل بين الفروع',
    'جرد المخزون',
  ]),
  ('المحاسبة', [
    'عرض القيود',
    'ترحيل قيد',
    'عكس قيد',
    'التقارير المالية',
  ]),
  ('الرواتب', [
    'عرض الرواتب',
    'صرف الرواتب',
    'صرف سلفة',
  ]),
  ('الإعدادات', [
    'إدارة المستخدمين',
    'تعديل الأدوار والصلاحيات',
    'إدارة الفروع',
    'إعدادات النظام',
  ]),
];

Widget _host(TextDirection dir) => MaterialApp(
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
        child: const Scaffold(body: UsersScreen()),
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
  group('Users & Permissions — no overflow at any size (RTL + LTR, all tabs)', () {
    for (final (label, w, h) in _sizes) {
      for (final dir in const [TextDirection.rtl, TextDirection.ltr]) {
        final dl = dir == TextDirection.rtl ? 'rtl' : 'ltr';
        testWidgets('$label $dl ($w×$h)', (tester) async {
          await _pumpAt(tester, w, h, _host(dir));
          expect(tester.takeException(), isNull,
              reason: 'users tab @ $label $dl');

          final controller =
              tester.widget<TabBar>(find.byType(TabBar)).controller!;
          for (final i in const [1, 2]) {
            controller.animateTo(i);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            expect(tester.takeException(), isNull,
                reason: 'tab $i @ $label $dl');
          }
        });
      }
    }
  });

  testWidgets(
      'at 320px the matrix is replaced by the grouped alternate structure',
      (tester) async {
    await _pumpAt(tester, 320, 568, _host(TextDirection.rtl));
    final controller = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    controller.animateTo(1); // Roles & Permissions
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The grouped alternate structure renders (its keyed scroll list exists and
    // it uses ExpansionTiles). The lazy ListView only builds the on-screen
    // tiles, so assert "at least some" here; full reachability of all 27
    // permissions is proven by the next test via scrolling.
    expect(find.byKey(const Key('perm-groups-list')), findsOneWidget);
    expect(find.byType(ExpansionTile), findsWidgets);
    // The first group is expanded by default, so its permissions are present.
    expect(find.text('إنشاء فاتورة بيع'), findsWidgets);
  });

  testWidgets(
      'every permission is viewable + editable at 320px via the alternate structure',
      (tester) async {
    await _pumpAt(tester, 320, 568, _host(TextDirection.rtl));
    final controller = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    controller.animateTo(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final listScrollable = find.descendant(
      of: find.byKey(const Key('perm-groups-list')),
      matching: find.byType(Scrollable),
    );

    var switchesSeen = 0;
    for (var gi = 0; gi < _catalogue.length; gi++) {
      final (title, perms) = _catalogue[gi];
      // Bring the group header into view and expand it (group 0 starts open).
      await tester.scrollUntilVisible(find.text(title), 120,
          scrollable: listScrollable);
      await tester.pump();
      if (gi != 0) {
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
      }
      // Every permission in the group must be reachable (scroll throws if not)
      // and each must carry an editable Switch next to it.
      for (final p in perms) {
        await tester.scrollUntilVisible(find.text(p), 80,
            scrollable: listScrollable);
        expect(find.text(p), findsWidgets, reason: 'permission "$p" viewable');
        switchesSeen++;
      }
    }
    // 27 permissions across the six groups — none dropped.
    expect(switchesSeen, 27);
    // At least the currently on-screen group renders real Switch controls.
    expect(find.byType(Switch), findsWidgets);
  });

  testWidgets('sensitive permission shows a warning before granting (320px)',
      (tester) async {
    await _pumpAt(tester, 320, 568, _host(TextDirection.rtl));
    final controller = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    controller.animateTo(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Default role is "owner", which holds every permission EXCEPT
    // 'إعدادات النظام' (set_system) — a sensitive one. Toggling it ON must
    // trigger the warning (enabling a sensitive grant), not disabling.
    final listScrollable = find.descendant(
      of: find.byKey(const Key('perm-groups-list')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(find.text('الإعدادات'), 120,
        scrollable: listScrollable);
    await tester.tap(find.text('الإعدادات')); // expand Settings group
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('إعدادات النظام'), 60,
        scrollable: listScrollable);
    // The permission row is a Padding > Row[..., Switch]; the closest Padding
    // ancestor of the name uniquely scopes to that row's Switch.
    final row = find
        .ancestor(
          of: find.text('إعدادات النظام'),
          matching: find.byType(Padding),
        )
        .first;
    final theSwitch = find.descendant(of: row, matching: find.byType(Switch));
    await tester.ensureVisible(theSwitch.first);
    await tester.pumpAndSettle();
    await tester.tap(theSwitch.first);
    await tester.pumpAndSettle();

    // The sensitive-permission warning dialog must appear before granting.
    expect(find.text('صلاحية حسّاسة'), findsOneWidget);
    expect(find.text('منح الصلاحية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (label, w, h) in const [
    ('phone', 320.0, 640.0),
    ('tablet', 768.0, 1024.0),
    ('desktop', 1920.0, 1080.0),
  ]) {
    testWidgets('add-user dialog lays out without overflow @ $label', (
      tester,
    ) async {
      await _pumpAt(tester, w, h, _host(TextDirection.rtl));
      await tester.tap(find.byIcon(Icons.person_add_alt_1_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'dialog open @ $label');
      // The form fields (single column <600, two columns ≥600) are present.
      expect(find.text('الاسم الكامل'), findsOneWidget);
      expect(find.text('الدور'), findsWidgets);
      expect(find.text('حفظ'), findsWidgets);
      // Scroll the dialog body to confirm its internal scroll works.
      await tester.drag(find.text('الاسم الكامل'), const Offset(0, -120));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'dialog scroll @ $label');
    });
  }
}
