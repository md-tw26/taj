import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/branches.dart';
import 'core/chart_style.dart';
import 'core/demo/demo_provider.dart';
import 'core/demo/demo_store.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/taj_colors.dart';
import 'core/user_role.dart';
import 'modules/auth/login_screen.dart';
import 'modules/cashier_pos/cashier_pos_screen.dart';
import 'modules/merchant_pos/merchant_pos_screen.dart';
import 'shared/widgets/app_shell.dart';

void main() => runApp(const TajApp());

class TajApp extends StatefulWidget {
  const TajApp({
    super.key,
    this.testSignedIn = false,
    this.testRole = UserRole.admin,
    this.testUserName = 'admin',
    this.initialDark = false,
    this.testInitialCart,
    this.testOpenReports = false,
  });

  final bool testSignedIn;
  final UserRole testRole;
  final String testUserName;

  /// Test hook: force the app to start in dark mode (used by the screenshot
  /// harness). The in-app toggle still works from this state.
  final bool initialDark;

  /// Test hook: pre-fill the cashier cart with {productId: quantity}.
  final Map<String, int>? testInitialCart;

  /// Test hook: open the professional session-report sheet on startup.
  final bool testOpenReports;

  @override
  State<TajApp> createState() => _TajAppState();
}

class _TajAppState extends State<TajApp> {
  ThemeMode _mode = ThemeMode.light;
  late bool _signedIn;
  late UserRole _role;
  late String _userName;
  late UserPermissions _permissions;
  late final DemoStore _demoStore;
  TajSwatch _primary = TajColors.primarySwatch;
  ChartStyle _chartStyle = ChartStyle.area;
  AppBranch _selectedBranch = kDefaultBranch;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialDark ? ThemeMode.dark : ThemeMode.light;
    _signedIn = widget.testSignedIn;
    _role = widget.testRole;
    _userName = widget.testUserName;
    _permissions = UserPermissions.forRole(_role);
    _demoStore = DemoStore();
  }

  void _toggleTheme() => setState(
    () => _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
  );

  void _onSignedIn(UserRole role, String userName) => setState(() {
    _signedIn = true;
    _role = role;
    _userName = userName;
    _permissions = UserPermissions.forRole(role);
  });

  @override
  Widget build(BuildContext context) {
    return DemoStoreProvider(
      store: _demoStore,
      child: MaterialApp(
        title: 'تاج',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.light(primary: _primary),
        darkTheme: AppThemes.dark(primary: _primary),
        themeMode: _mode,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home:
            _signedIn
                ? (_role == UserRole.cashier
                    ? CashierPosScreen(
                      branchName: _getBranchName(_selectedBranch),
                      userName: _userName,
                      permissions: _permissions,
                      initialCart: widget.testInitialCart,
                      testOpenReports: widget.testOpenReports,
                      onLogout: () => setState(() => _signedIn = false),
                      onToggleTheme: _toggleTheme,
                    )
                    : _role == UserRole.merchant
                    ? MerchantPosScreen(
                      branchName: _getBranchName(_selectedBranch),
                      permissions: _permissions,
                      onLogout: () => setState(() => _signedIn = false),
                      onToggleTheme: _toggleTheme,
                    )
                    : AppShell(
                      onToggleTheme: _toggleTheme,
                      onLogout: () => setState(() => _signedIn = false),
                      currentPrimary: _primary,
                      onPrimaryChanged: (s) => setState(() => _primary = s),
                      chartStyle: _chartStyle,
                      onChartStyleChanged:
                          (s) => setState(() => _chartStyle = s),
                      selectedBranch: _selectedBranch,
                      onBranchChanged:
                          (branch) => setState(() => _selectedBranch = branch),
                    ))
                : LoginScreen(
                  onSignedIn: _onSignedIn,
                  onToggleTheme: _toggleTheme,
                ),
      ),
    );
  }

  String _getBranchName(AppBranch branch) {
    switch (_role) {
      case UserRole.merchant:
        return 'نقطة البيع - الفرع الرئيسي';
      case UserRole.cashier:
        return 'نقطة البيع - الفرع الرئيسي';
      case UserRole.admin:
        return branch.name;
    }
  }

  @override
  void dispose() {
    _demoStore.dispose();
    super.dispose();
  }
}
