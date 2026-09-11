// Verifies the chart-style setting: Settings shows the three options and emits
// the selection, and the dashboard renders in every style without overflow.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:taj/core/chart_style.dart';
import 'package:taj/core/theme/app_themes.dart';
import 'package:taj/core/theme/taj_colors.dart';
import 'package:taj/modules/dashboard/dashboard_screen.dart';
import 'package:taj/modules/settings/settings_screen.dart';

Widget _host(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_host(child));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Settings shows the 3 chart styles and emits the choice',
      (tester) async {
    ChartStyle? picked;
    await _pumpAt(
      tester,
      const Size(900, 1200),
      SettingsScreen(
        currentPrimary: TajColors.primarySwatch,
        onPrimaryChanged: (_) {},
        onToggleTheme: () {},
        chartStyle: ChartStyle.area,
        onChartStyleChanged: (s) => picked = s,
      ),
    );

    expect(find.text('شكل الرسم البياني'), findsOneWidget);
    for (final s in ChartStyle.values) {
      expect(find.text(s.label), findsWidgets, reason: 'option ${s.label}');
    }

    await tester.tap(find.text('أعمدة'));
    await tester.pump();
    expect(picked, ChartStyle.bars);
    expect(tester.takeException(), isNull);
  });

  for (final style in ChartStyle.values) {
    for (final (label, size) in const [
      ('wide', Size(1280, 900)),
      ('narrow', Size(380, 820)),
    ]) {
      testWidgets('Dashboard renders ${style.name} chart without overflow ($label)',
          (tester) async {
        await _pumpAt(tester, size, DashboardScreen(chartStyle: style));
        expect(find.text('نظرة عامة'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
