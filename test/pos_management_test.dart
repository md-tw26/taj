// Renders the POS Management module and walks through every section at a wide
// and a narrow viewport, asserting no layout overflow (RenderFlex overflow
// surfaces via takeException) and that each section's key content is present.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:taj/core/theme/app_themes.dart';
import 'package:taj/modules/pos_management/pos_management_screen.dart';

Widget _host() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(body: PosManagementScreen()),
    );

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_host());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Tabs are always built (Row in a scroll view) so we can reveal + tap any of
/// them regardless of viewport width.
Future<void> _openSection(WidgetTester tester, String label) async {
  final tab = find.text(label);
  expect(tab, findsWidgets, reason: 'tab "$label" should exist');
  await tester.ensureVisible(tab.first);
  await tester.tap(tab.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Scroll the current section body (the sole vertical ListView) to the bottom so
/// lazily-built content below the fold is laid out — that is where an overflow
/// would otherwise go undetected on a single pump.
Future<void> _scrollThrough(WidgetTester tester) async {
  final list = find.byType(ListView);
  if (list.evaluate().isEmpty) return;
  for (var i = 0; i < 10; i++) {
    await tester.drag(list.first, const Offset(0, -400));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 200));
}

/// (tab label, a marker text at the TOP of that section's body).
const _sections = <(String, String)>[
  ('نظرة عامة', 'أجهزة نقاط البيع'),
  ('الأجهزة', 'إضافة جهاز'),
  ('الكاشيرون', 'أداء الكاشيرين اليوم'),
  ('الورديات', 'فتح وردية'),
  ('الفروع', 'أداء الفروع'),
  ('الأداء', 'لوحة الأبطال'),
  ('التقارير', 'مكتبة التقارير'),
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final (label, size) in const [('wide', Size(1280, 900)), ('narrow', Size(380, 820))]) {
    testWidgets('POS management — all sections render without overflow ($label)',
        (tester) async {
      await _pump(tester, size);

      // Overview is the default section.
      expect(find.text('إدارة نقاط البيع'), findsOneWidget);
      expect(find.text('الفروع'), findsWidgets); // KPI + tab
      expect(tester.takeException(), isNull);

      for (final (tab, marker) in _sections) {
        final errs = <FlutterErrorDetails>[];
        final prev = FlutterError.onError;
        FlutterError.onError = errs.add;
        await _openSection(tester, tab);
        expect(find.text(marker), findsWidgets,
            reason: 'section "$tab" should show "$marker"');
        // Force the rest of the section to lay out and re-check.
        await _scrollThrough(tester);
        FlutterError.onError = prev;
        expect(errs, isEmpty,
            reason: 'section "$tab" overflowed at $label: '
                '${errs.map((e) => e.exceptionAsString()).join("; ")}');
      }
    });
  }

  testWidgets('POS management — branch filter narrows the terminal set',
      (tester) async {
    await _pump(tester, const Size(1280, 900));

    // 11 terminals across all branches → POS-11 exists on the overview board.
    expect(find.text('POS-11'), findsWidgets);

    // Filter to branch 2 (بنغازي, 2 terminals: POS-05/06).
    await tester.tap(find.text('كل الفروع'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بنغازي - الفرع').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('POS-05'), findsWidgets);
    expect(find.text('POS-11'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
