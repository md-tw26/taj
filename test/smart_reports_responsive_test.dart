// Smart Reports & Analytics responsive regression tests.
//
// Opens EVERY question's visual answer at a narrow and a wide size, in RTL and
// LTR, sweeps chart-heavy questions across all acceptance viewports (portrait +
// landscape, incl. 3440×1440), and runs a resize sweep. Any layout/overflow
// error — including "RenderBox was not laid out" from an unbounded chart —
// surfaces via `tester.takeException()` and fails the case.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taj/core/theme/app_themes.dart';
import 'package:taj/modules/smart_reports/smart_analytics.dart';
import 'package:taj/modules/smart_reports/smart_reports_screen.dart';

Widget _host(Widget child, {TextDirection dir = TextDirection.rtl}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      locale: Locale(dir == TextDirection.rtl ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
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

const _narrow = (380.0, 720.0);
const _wide = (1440.0, 900.0);

void main() {
  final ids = [for (final q in smartQuestions) q.id];

  group('Every question — narrow & wide, RTL & LTR, no overflow', () {
    for (final id in ids) {
      for (final dir in TextDirection.values) {
        final dl = dir == TextDirection.rtl ? 'rtl' : 'ltr';
        testWidgets('$id narrow ($dl)', (tester) async {
          await _pumpAt(tester, _narrow.$1, _narrow.$2,
              _host(SmartReportsScreen(testInitialQuestionId: id), dir: dir));
          expect(tester.takeException(), isNull);
        });
        testWidgets('$id wide ($dl)', (tester) async {
          await _pumpAt(tester, _wide.$1, _wide.$2,
              _host(SmartReportsScreen(testInitialQuestionId: id), dir: dir));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Chart board — full acceptance size spread (portrait + landscape)', () {
    const sizes = <(String, double, double)>[
      ('320x568', 320, 568),
      ('568x320', 568, 320), // landscape phone
      ('360x640', 360, 640),
      ('390x844', 390, 844),
      ('430x932', 430, 932),
      ('932x430', 932, 430), // landscape phone (wide)
      ('600x960', 600, 960),
      ('768x1024', 768, 1024),
      ('1024x1366', 1024, 1366),
      ('1280x720', 1280, 720),
      ('1366x768', 1366, 768),
      ('1440x900', 1440, 900),
      ('1920x1080', 1920, 1080),
      ('2560x1440', 2560, 1440),
      ('3440x1440', 3440, 1440),
      ('3840x2160', 3840, 2160),
    ];
    // best_sellers: bars + donut; profitable_products: many products (grouping +
    // horizontal bars); revenue_vs_expense: multi-series line.
    for (final id in ['best_sellers', 'profitable_products', 'revenue_vs_expense']) {
      for (final (label, w, h) in sizes) {
        testWidgets('$id @ $label', (tester) async {
          await _pumpAt(tester, w, h, _host(SmartReportsScreen(testInitialQuestionId: id)));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Index grid — acceptance size spread', () {
    const sizes = <(String, double, double)>[
      ('320x568', 320, 568),
      ('600x960', 600, 960),
      ('1024x1366', 1024, 1366),
      ('1440x900', 1440, 900),
      ('3840x2160', 3840, 2160),
    ];
    for (final (label, w, h) in sizes) {
      testWidgets('index @ $label', (tester) async {
        await _pumpAt(tester, w, h, _host(const SmartReportsScreen()));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Resize sweep rebuilds charts without overflow', () {
    testWidgets('1280 → 1100 → 900 → 700 → 500 → 360', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final w in [1280.0, 1100.0, 900.0, 700.0, 500.0, 360.0]) {
        tester.view.physicalSize = Size(w, 820);
        await tester.pumpWidget(_host(const SmartReportsScreen(testInitialQuestionId: 'best_sellers')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'overflow at width $w');
      }
    });
  });
}
