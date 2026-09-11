// TEMPORARY diagnostic probe for the Employees module — deleted after verify.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taj/core/demo/demo_provider.dart';
import 'package:taj/core/demo/demo_store.dart';
import 'package:taj/core/theme/app_themes.dart';
import 'package:taj/modules/employees/employees_screen.dart';

Widget _host(DemoStore store, TextDirection dir) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      locale: Locale(dir == TextDirection.rtl ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: DemoStoreProvider(
        store: store,
        child: Directionality(
          textDirection: dir,
          child: const ColoredBox(
            color: Color(0xFFF4F6F8),
            child: EmployeesScreen(),
          ),
        ),
      ),
    );

String _short(FlutterErrorDetails d) {
  final full = d.toString();
  final over = RegExp(r'overflowed by [0-9.]+ pixels').firstMatch(full)?.group(0) ?? '';
  final cons = RegExp(r'constraints: BoxConstraints\([^)]*\)').firstMatch(full)?.group(0) ?? '';
  final size = RegExp(r'size: Size\([^)]*\)').firstMatch(full)?.group(0) ?? '';
  final stripped = full
      .replaceAll('file:///C:/Users/MSI/Desktop/taj/lib/modules/employees/', '')
      .replaceAll('file:///C:/Users/MSI/Desktop/taj/lib/', '');
  final i = stripped.indexOf('The relevant error-causing widget was');
  final w = i >= 0
      ? stripped.substring(i, (i + 130).clamp(0, stripped.length))
      : d.exceptionAsString();
  return '$over | $cons | $w'.replaceAll('\n', ' ').trim();
}

Future<List<String>> _run(
  WidgetTester tester,
  Size size,
  TextDirection dir, {
  List<String> taps = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final captured = <FlutterErrorDetails>[];
  final prev = FlutterError.onError;
  FlutterError.onError = (d) => captured.add(d);

  final failures = <String>[];
  await tester.pumpWidget(_host(DemoStore(), dir));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  if (captured.isNotEmpty) {
    failures.add('[initial] ${_short(captured.first)}');
    captured.clear();
  }

  for (final label in taps) {
    try {
      final f = find.text(label);
      if (f.evaluate().isNotEmpty) {
        await tester.ensureVisible(f.first);
        await tester.pump();
        await tester.tap(f.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
      }
    } catch (e) {
      failures.add('[$label] tap-threw: $e');
    }
    if (captured.isNotEmpty) {
      failures.add('[$label] ${_short(captured.first)}');
      captured.clear();
    }
  }

  FlutterError.onError = prev;
  dynamic ex;
  do {
    ex = tester.takeException();
  } while (ex != null);
  return failures;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const sizes = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(430, 932),
    Size(600, 960),
    Size(768, 1024),
    Size(1024, 1366),
    Size(1280, 720),
    Size(1366, 768),
    Size(1440, 900),
    Size(1920, 1080),
    Size(2560, 1440),
    Size(3440, 1440),
    Size(3840, 2160),
  ];

  testWidgets('employees: list + profile tabs + payroll, all sizes RTL+LTR',
      (t) async {
    final failures = <String>[];
    for (final s in sizes) {
      for (final swap in [false, true]) {
        final size = swap ? Size(s.height, s.width) : s;
        for (final dir in [TextDirection.rtl, TextDirection.ltr]) {
          final f = await _run(t, size, dir, taps: [
            'طارق بن عمر', // open profile
            'السلف والسحوبات', // tab 2
            'المصروفات المرتبطة', // tab 3
            'الراتب', // tab 1
            'مسير الرواتب', // payroll section
          ]);
          for (final e in f) {
            failures.add('${size.width.toInt()}x${size.height.toInt()} '
                '${dir == TextDirection.rtl ? 'RTL' : 'LTR'} $e');
          }
        }
      }
    }
    debugPrint('MATRIX_FAILURES=${failures.length}');
    for (final f in failures.take(40)) debugPrint('MATRIX_ERR>>> $f');
    expect(failures, isEmpty, reason: failures.take(20).join('\n'));
  });

  testWidgets('employees: dialogs (add / pay)', (t) async {
    final failures = <String>[];
    for (final s in [
      const Size(320, 568),
      const Size(430, 932),
      const Size(768, 1024),
      const Size(1440, 900),
      const Size(1920, 1080),
      const Size(932, 430),
    ]) {
      for (final dir in [TextDirection.rtl, TextDirection.ltr]) {
        // Open the profile of an unpaid employee, then pay-salary dialog.
        final f1 = await _run(t, s, dir, taps: ['طارق بن عمر', 'دفع الراتب']);
        // Add-employee dialog.
        final f2 = await _run(t, s, dir, taps: ['موظف']);
        for (final e in [...f1, ...f2]) {
          failures.add('${s.width.toInt()}x${s.height.toInt()} '
              '${dir == TextDirection.rtl ? 'RTL' : 'LTR'} $e');
        }
      }
    }
    debugPrint('DIALOG_FAILURES=${failures.length}');
    for (final f in failures.take(30)) debugPrint('DIALOG_ERR>>> $f');
    expect(failures, isEmpty, reason: failures.take(20).join('\n'));
  });
}
