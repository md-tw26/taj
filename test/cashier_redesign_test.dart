// Renders the redesigned cashier POS in both simple and professional modes at
// wide and narrow sizes, asserting the new payment controls are present and
// that nothing overflows (RenderFlex overflow surfaces via takeException).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taj/core/user_role.dart';
import 'package:taj/main.dart';

const _cart = {'p1': 2, 'p2': 1, 'p3': 1};

/// Pumps the cashier screen without pumpAndSettle: the search field auto-focuses
/// (a blinking cursor never settles), so we advance a fixed amount instead.
Future<void> _pumpCashier(
  WidgetTester tester, {
  required Size size,
  required bool professional,
}) async {
  SharedPreferences.setMockInitialValues(
    professional ? {'pos_mode_professional_cashier': true} : {},
  );
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    const TajApp(
      testSignedIn: true,
      testRole: UserRole.cashier,
      testUserName: 'cashier',
      testInitialCart: _cart,
    ),
  );
  await tester.pump(); // first frame
  await tester.pump(const Duration(milliseconds: 600)); // focus + prefs load
}

void main() {
  setUpAll(() {
    // Keep font loading offline so tests never hit the network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('simple mode — wide: primary charge bar + grouped tenders, no overflow',
      (tester) async {
    await _pumpCashier(tester,
        size: const Size(1280, 900), professional: false);

    expect(find.text('بيع نقداً'), findsOneWidget);
    expect(find.text('تحويلات ومحافظ'), findsOneWidget);
    // A couple of the neutral tender buttons.
    expect(find.text('سداد'), findsOneWidget);
    expect(find.text('NUMO QR'), findsOneWidget);
    // Simple mode must NOT show the professional toolbar.
    expect(find.text('تقسيم'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('simple mode — narrow: cart sheet renders without overflow',
      (tester) async {
    await _pumpCashier(tester,
        size: const Size(390, 844), professional: false);

    // On narrow layout the cart lives behind the bottom bar; open it.
    final cartBar = find.textContaining('منتج');
    expect(cartBar, findsWidgets);
    await tester.tap(cartBar.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('بيع نقداً'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('professional mode — wide: quick-action toolbar present, no overflow',
      (tester) async {
    await _pumpCashier(tester,
        size: const Size(1280, 900), professional: true);

    // The four professional quick-action tiles.
    expect(find.text('خصم'), findsOneWidget);
    expect(find.text('ملاحظة'), findsOneWidget);
    expect(find.text('حفظ'), findsOneWidget);
    expect(find.text('تقسيم'), findsOneWidget);
    // Still shows the primary charge bar and grouped tenders.
    expect(find.text('بيع نقداً'), findsOneWidget);
    expect(find.text('تحويلات ومحافظ'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('professional mode — narrow: cart sheet header + toolbar, no overflow',
      (tester) async {
    await _pumpCashier(tester,
        size: const Size(390, 844), professional: true);

    final cartBar = find.textContaining('منتج');
    expect(cartBar, findsWidgets);
    await tester.tap(cartBar.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('بيع نقداً'), findsOneWidget);
    // Professional quick actions render inside the narrow sheet too.
    expect(find.text('تقسيم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
