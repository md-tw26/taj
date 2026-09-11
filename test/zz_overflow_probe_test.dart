// TEMPORARY diagnostic probe — delete after locating overflow sources.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taj/core/user_role.dart';
import 'package:taj/main.dart';

Future<void> _probe(
  WidgetTester tester,
  Size size,
  Widget child, {
  Map<String, Object> prefs = const {},
  bool openCart = false,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final captured = <FlutterErrorDetails>[];
  final prev = FlutterError.onError;
  FlutterError.onError = (d) => captured.add(d);

  await tester.pumpWidget(child);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));

  if (openCart) {
    final cartBar = find.textContaining('منتج');
    if (cartBar.evaluate().isNotEmpty) {
      await tester.tap(cartBar.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  FlutterError.onError = prev;

  // Drain any exceptions the binding recorded so the test itself passes.
  dynamic ex;
  do {
    ex = tester.takeException();
  } while (ex != null);

  debugPrint('PROBE_COUNT=${captured.length}');
  for (final d in captured) {
    debugPrint('PROBE_ERR>>> ${d.exceptionAsString()}');
    debugPrint(
      'PROBE_WIDGET>>> ${d.toStringShort()} :: ${d.context?.toDescription()}',
    );
    // Full dump contains "The relevant error-causing widget was: X  file:line"
    debugPrint('PROBE_FULL_START');
    debugPrint(d.toString());
    debugPrint('PROBE_FULL_END');
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('probe admin @ tablet-sm 600x960', (tester) async {
    await _probe(tester, const Size(600, 960), const TajApp(testSignedIn: true));
  });

  testWidgets('probe merchant @ phone-xs-landscape 568x320', (tester) async {
    await _probe(
      tester,
      const Size(568, 320),
      const TajApp(testSignedIn: true, testRole: UserRole.merchant),
    );
  });

  testWidgets('probe cashier simple narrow 390x844', (tester) async {
    await _probe(
      tester,
      const Size(390, 844),
      const TajApp(
        testSignedIn: true,
        testRole: UserRole.cashier,
        testUserName: 'cashier',
        testInitialCart: {'p1': 2, 'p2': 1, 'p3': 1},
      ),
      openCart: true,
    );
  });

  testWidgets('probe cashier pro narrow 390x844', (tester) async {
    await _probe(
      tester,
      const Size(390, 844),
      const TajApp(
        testSignedIn: true,
        testRole: UserRole.cashier,
        testUserName: 'cashier',
        testInitialCart: {'p1': 2, 'p2': 1, 'p3': 1},
      ),
      prefs: {'pos_mode_professional_cashier': true},
      openCart: true,
    );
  });
}
