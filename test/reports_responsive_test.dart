// Reports-centre responsive regression tests.
//
// Opens EVERY report (not a sample) at a narrow and a wide size, in both RTL
// and LTR, plus a resize sweep across the index-rail threshold, and fails if
// any of them throws a layout/overflow error. Overflow surfaces via
// `tester.takeException()`, so an unintended overflow at any size fails here.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taj/core/theme/app_themes.dart';
import 'package:taj/modules/reports/report_catalog.dart';
import 'package:taj/modules/reports/reports_screen.dart';

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

/// A narrow (single-pane pushed result) and a wide (master-detail rail +
/// result + insights) size, so both layouts of every report are exercised.
const _narrow = (380.0, 720.0);
const _wide = (1440.0, 900.0);

void main() {
  final ids = [for (final r in reportCatalog) r.id];

  group('Every report — narrow & wide, RTL & LTR, no overflow', () {
    for (final id in ids) {
      for (final dir in TextDirection.values) {
        final dl = dir == TextDirection.rtl ? 'rtl' : 'ltr';
        testWidgets('$id narrow ($dl)', (tester) async {
          await _pumpAt(tester, _narrow.$1, _narrow.$2,
              _host(ReportsScreen(testInitialReportId: id), dir: dir));
          expect(tester.takeException(), isNull);
        });
        testWidgets('$id wide ($dl)', (tester) async {
          await _pumpAt(tester, _wide.$1, _wide.$2,
              _host(ReportsScreen(testInitialReportId: id), dir: dir));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  // A representative report across every acceptance viewport, portrait and
  // landscape, to catch size-specific overflow in the result screen itself.
  group('Result screen — full acceptance size spread', () {
    const sizes = <(String, double, double)>[
      ('320x568', 320, 568),
      ('568x320', 568, 320), // landscape phone
      ('360x640', 360, 640),
      ('390x844', 390, 844),
      ('430x932', 430, 932),
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
    // Payroll has the widest numeric column set; balance sheet is hierarchical.
    for (final id in ['payroll', 'balance_sheet', 'ledger']) {
      for (final (label, w, h) in sizes) {
        testWidgets('$id @ $label', (tester) async {
          await _pumpAt(tester, w, h, _host(ReportsScreen(testInitialReportId: id)));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  // Resize sweep 1280 → 500 must fold the rail into an index page without
  // throwing at any intermediate width.
  group('Resize sweep folds rail into index', () {
    testWidgets('1280 → 1100 → 900 → 700 → 500', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final w in [1280.0, 1100.0, 900.0, 700.0, 500.0]) {
        tester.view.physicalSize = Size(w, 900);
        await tester.pumpWidget(_host(const ReportsScreen(testInitialReportId: 'trial_balance')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'overflow at width $w');
      }
    });
  });
}
