// Notifications — responsive + behavioural regression tests.
//
// Covers both surfaces of the module: the full notification centre
// (NotificationsScreen) at every acceptance size in RTL + LTR, and the top-bar
// bell's popover / bottom-sheet / full-page behaviour — including the key
// guarantee that the popover never escapes the window bounds in either
// direction or near a screen edge.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taj/core/theme/app_themes.dart';
import 'package:taj/modules/notifications/notifications_screen.dart';

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

Widget _host(Widget child, TextDirection dir) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      locale: Locale(dir == TextDirection.rtl ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(textDirection: dir, child: child),
    );

// A bell hosted at the top-trailing corner, i.e. the worst case for a popover
// clamping against the screen edge (mirrors in RTL).
Widget _bellHost(TextDirection dir, VoidCallback onFull) => _host(
      Scaffold(
        body: Align(
          alignment: AlignmentDirectional.topEnd,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: NotificationBell(onOpenFull: onFull),
          ),
        ),
      ),
      dir,
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
  group('Notification centre — no overflow at any size (RTL + LTR)', () {
    for (final (label, w, h) in _sizes) {
      for (final dir in const [TextDirection.rtl, TextDirection.ltr]) {
        final dl = dir == TextDirection.rtl ? 'rtl' : 'ltr';
        testWidgets('$label $dl ($w×$h)', (tester) async {
          await _pumpAt(
            tester,
            w,
            h,
            _host(const Scaffold(body: NotificationsScreen()), dir),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Bell popover never escapes window bounds', () {
    // Sizes with width ≥ 600 and height ≥ 760 → an anchored popover shows.
    const popoverSizes = <(String, double, double)>[
      ('tablet-sm', 600, 960),
      ('tablet-portrait', 768, 1024),
      ('tablet-landscape', 1024, 768),
      ('desktop', 1920, 1080),
      ('4k', 3840, 2160),
    ];
    for (final (label, w, h) in popoverSizes) {
      for (final dir in const [TextDirection.rtl, TextDirection.ltr]) {
        final dl = dir == TextDirection.rtl ? 'rtl' : 'ltr';
        testWidgets('popover in-bounds @ $label $dl', (tester) async {
          await _pumpAt(tester, w, h, _bellHost(dir, () {}));
          await tester.tap(find.byIcon(Icons.notifications_none_rounded));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final panel = find.byKey(const Key('notif-popover'));
          expect(panel, findsOneWidget, reason: 'popover shown @ $label $dl');
          final box = tester.renderObject<RenderBox>(panel);
          final tl = box.localToGlobal(Offset.zero);
          final rect = tl & box.size;
          expect(rect.left, greaterThanOrEqualTo(-0.5),
              reason: 'left edge in-bounds @ $label $dl');
          expect(rect.top, greaterThanOrEqualTo(-0.5),
              reason: 'top edge in-bounds @ $label $dl');
          expect(rect.right, lessThanOrEqualTo(w + 0.5),
              reason: 'right edge in-bounds @ $label $dl');
          expect(rect.bottom, lessThanOrEqualTo(h + 0.5),
              reason: 'bottom edge in-bounds @ $label $dl');
        });
      }
    }
  });

  testWidgets('phone width opens the full page, not a popover', (tester) async {
    var openedFull = false;
    await _pumpAt(tester, 360, 740, _bellHost(TextDirection.rtl, () {
      openedFull = true;
    }));
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    expect(openedFull, isTrue, reason: 'bell delegates to full page on phone');
    expect(find.byKey(const Key('notif-popover')), findsNothing);
  });

  testWidgets('short viewport opens a bottom sheet, not a hanging popover',
      (tester) async {
    // 1280×720: width ≥ 600 but height < notifPopoverMinHeight (760).
    await _pumpAt(tester, 1280, 720, _bellHost(TextDirection.rtl, () {}));
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // A sheet renders the shared panel content but not the keyed popover Material.
    expect(find.byKey(const Key('notif-popover')), findsNothing);
    expect(find.text('عرض كل الإشعارات'), findsOneWidget);
  });

  testWidgets('tapping a notification in two-pane shows the detail pane',
      (tester) async {
    await _pumpAt(
      tester,
      1200,
      900,
      _host(const Scaffold(body: NotificationsScreen()), TextDirection.rtl),
    );
    // Two-pane at ≥820: detail starts empty.
    expect(find.text('اختر إشعارًا لعرض تفاصيله'), findsOneWidget);
    await tester.tap(find.text('مخزون منخفض: عود ملكي').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The detail pane now shows an action for the selected notification.
    expect(find.text('اختر إشعارًا لعرض تفاصيله'), findsNothing);
    expect(find.byIcon(Icons.done_all_rounded), findsWidgets);
  });
}
