// Screenshot harness — temporary. Drives TajApp from URL params so a headless
// browser can capture each screen in both colour modes:
//   ?screen=login|cashier|merchant|admin&dark=1
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'core/user_role.dart';
import 'main.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  final p = Uri.base.queryParameters;
  final dark = p['dark'] == '1';
  final screen = p['screen'] ?? 'login';
  final role = switch (screen) {
    'cashier' => UserRole.cashier,
    'merchant' => UserRole.merchant,
    _ => UserRole.admin,
  };
  final signedIn = switch (screen) {
    'login' => false,
    _ => true,
  };
  final user = switch (screen) {
    'cashier' => 'cashier',
    'merchant' => 'merchant',
    _ => 'admin',
  };
  final initialCart = (screen == 'cashier' && p['cart'] == '1')
      ? const {'p1': 2, 'p2': 1, 'p3': 1}
      : null;
  runApp(
    TajApp(
      testSignedIn: signedIn,
      testRole: role,
      testUserName: user,
      initialDark: dark,
      testInitialCart: initialCart,
      testOpenReports: screen == 'cashier' && p['reports'] == '1',
    ),
  );
}
