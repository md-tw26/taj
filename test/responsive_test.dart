// Responsive-layout regression tests.
//
// Mounts every screen across the full spread of supported viewport sizes
// (small phones → 4K/ultra-wide, both orientations) and fails if any of them
// throws a layout error. In widget tests a RenderFlex/overflow error is routed
// through FlutterError and surfaces via `tester.takeException()`, so an
// unintended overflow at any size fails the corresponding case.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taj/core/chart_style.dart';
import 'package:taj/core/theme/app_themes.dart';
import 'package:taj/core/theme/taj_colors.dart';
import 'package:taj/core/user_role.dart';
import 'package:taj/main.dart';
import 'package:taj/modules/customers/customers_screen.dart';
import 'package:taj/modules/dashboard/dashboard_screen.dart';
import 'package:taj/modules/expenses/expenses_screen.dart';
import 'package:taj/modules/inventory/inventory_screen.dart';
import 'package:taj/modules/pos_management/pos_management_screen.dart';
import 'package:taj/modules/products/products_screen.dart';
import 'package:taj/modules/purchases/purchases_screen.dart';
import 'package:taj/modules/reports/reports_screen.dart';
import 'package:taj/modules/smart_reports/smart_reports_screen.dart';
import 'package:taj/modules/assistant/assistant_screen.dart';
import 'package:taj/modules/sales/sales_screen.dart';
import 'package:taj/modules/settings/settings_screen.dart';
import 'package:taj/modules/accounting/accounting_screen.dart';
import 'package:taj/modules/employees/employees_screen.dart';
import 'package:taj/modules/treasury/treasury_screen.dart';

/// (label, logical width, logical height). Covers phones, tablets, laptops,
/// desktops, 2K/4K and ultra-wide, plus a couple of landscape/short cases.
const _sizes = <(String, double, double)>[
  ('phone-xs-portrait', 320, 568),
  ('phone-xs-landscape', 568, 320),
  ('phone-sm', 360, 740),
  ('phone-lg', 414, 896),
  ('phone-max', 430, 932),
  ('tablet-sm', 600, 960),
  ('tablet-portrait', 768, 1024),
  ('tablet-landscape', 1024, 768),
  ('laptop', 1366, 768),
  ('laptop-hidpi', 1440, 900),
  ('desktop', 1920, 1080),
  ('2k', 2560, 1440),
  ('ultrawide', 3440, 1440),
  ('4k', 3840, 2160),
];

Future<void> _pumpAt(
  WidgetTester tester,
  double w,
  double h,
  Widget child,
) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(w, h);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(child);
  // A couple of frames is enough to force layout (where overflow is detected)
  // without depending on animations settling.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Wrap a bare module screen in a themed, RTL, localized MaterialApp so it has
/// the same ambient context it gets inside the app shell.
Widget _host(Widget screen) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: screen),
    );

void main() {
  // Full app (shell + navigation chrome) in each role at every size.
  group('TajApp shell — no overflow at any size', () {
    for (final (label, w, h) in _sizes) {
      testWidgets('admin @ $label ($w×$h)', (tester) async {
        await _pumpAt(tester, w, h, const TajApp(testSignedIn: true));
        expect(tester.takeException(), isNull);
      });

      testWidgets('cashier @ $label ($w×$h)', (tester) async {
        await _pumpAt(
          tester,
          w,
          h,
          const TajApp(testSignedIn: true, testRole: UserRole.cashier),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('merchant @ $label ($w×$h)', (tester) async {
        await _pumpAt(
          tester,
          w,
          h,
          const TajApp(testSignedIn: true, testRole: UserRole.merchant),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('login @ $label ($w×$h)', (tester) async {
        await _pumpAt(tester, w, h, const TajApp(testSignedIn: false));
        expect(tester.takeException(), isNull);
      });
    }
  });

  // Individual admin content screens at every size.
  group('Content screens — no overflow at any size', () {
    final screens = <String, Widget>{
      'dashboard': const DashboardScreen(),
      'pos-management': const PosManagementScreen(),
      'products': const ProductsScreen(),
      'inventory': const InventoryScreen(),
      'sales': const SalesScreen(),
      'purchases': const PurchasesScreen(),
      'expenses': const ExpensesScreen(),
      'treasury': const TreasuryScreen(),
      'accounting': const AccountingScreen(),
      'employees': const EmployeesScreen(),
      'customers': const CustomersScreen(),
      'reports': const ReportsScreen(),
      'smart': const SmartReportsScreen(),
      'assistant': const AssistantScreen(),
      'settings': SettingsScreen(
        currentPrimary: TajColors.primarySwatch,
        onPrimaryChanged: (_) {},
        onToggleTheme: () {},
        chartStyle: ChartStyle.area,
        onChartStyleChanged: (_) {},
      ),
    };

    for (final entry in screens.entries) {
      for (final (label, w, h) in _sizes) {
        testWidgets('${entry.key} @ $label ($w×$h)', (tester) async {
          await _pumpAt(tester, w, h, _host(entry.value));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
