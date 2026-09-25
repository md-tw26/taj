import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/branches.dart';
import 'core/chart_style.dart';
import 'core/demo/demo_provider.dart';
import 'core/demo/demo_store.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/taj_colors.dart';
import 'core/user_role.dart';
import 'data/database_provider.dart';
import 'data/local/app_database.dart';
import 'modules/activation/activation_screen.dart';
import 'modules/activation/license_scope.dart';
import 'modules/activation/license_service.dart';
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
    this.testLicensed,
    this.testDatabase,
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

  /// Offline activation gate override (the real gate is **opt-in** for tests):
  ///  * `null` (production / gate tests) — run the real license check.
  ///  * `true`  — skip the gate entirely and treat the app as licensed.
  ///  * `false` — force the unlicensed / activation screen.
  final bool? testLicensed;

  /// Test hook: use this database instead of opening the production file, so
  /// widget tests run against an in-memory (or temp-file) instance. The app
  /// never closes a database it did not open.
  final AppDatabase? testDatabase;

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
  late final AppDatabase _db;
  late final bool _ownsDb;
  late final ValueNotifier<LicenseGateState> _license;
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
    _ownsDb = widget.testDatabase == null;
    _db = widget.testDatabase ?? AppDatabase();
    _license = ValueNotifier<LicenseGateState>(
      const LicenseGateState.checking(),
    );
    _initLicense();
  }

  /// Evaluates the stored license — re-run on **every** start so a tampered,
  /// expired or moved license is caught again, not just at activation time.
  void _initLicense() {
    final mode = widget.testLicensed;
    if (mode == true) {
      _license.value = const LicenseGateState.licensed();
      return;
    }
    if (mode == false) {
      _license.value = const LicenseGateState.unlicensed();
      return;
    }
    _license.value = const LicenseGateState.checking();
    _refreshLicense();
  }

  Future<void> _refreshLicense() async {
    final mode = widget.testLicensed;
    if (mode == false) {
      _license.value = const LicenseGateState.unlicensed();
      return;
    }
    try {
      final state = await LicenseService.loadStatus(_db);
      if (!mounted) return;
      _license.value = mode == true && !state.isLicensed
          ? const LicenseGateState.licensed()
          : state;
    } catch (_) {
      if (!mounted) return;
      _license.value = const LicenseGateState.unlicensed(
        message: 'تعذّرت قراءة بيانات الترخيص على هذا الجهاز.',
      );
    }
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
      child: DatabaseProvider(
        db: _db,
        child: LicenseScope(
          state: _license,
          refresh: _refreshLicense,
          child: ValueListenableBuilder<LicenseGateState>(
            valueListenable: _license,
            builder: (context, gate, _) => _buildApp(context, gate),
          ),
        ),
      ),
    );
  }

  /// Gate order: checking → branded splash, unlicensed → activation screen,
  /// licensed (or `testLicensed: true`) → the normal signed-in/login tree.
  Widget _buildApp(BuildContext context, LicenseGateState gate) {
    return MaterialApp(
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
      home: _homeFor(gate),
    );
  }

  Widget _homeFor(LicenseGateState gate) {
    if (widget.testLicensed == false) {
      return ActivationScreen(
        onActivated: _refreshLicense,
        onToggleTheme: _toggleTheme,
      );
    }
    if (widget.testLicensed == null) {
      if (gate.isChecking) return const _LicenseSplash();
      if (gate.isUnlicensed) {
        return ActivationScreen(
          onActivated: _refreshLicense,
          onToggleTheme: _toggleTheme,
        );
      }
    }
    return _signedIn ? _signedInHome() : LoginScreen(
      onSignedIn: _onSignedIn,
      onToggleTheme: _toggleTheme,
    );
  }

  Widget _signedInHome() {
    if (_role == UserRole.cashier) {
      return CashierPosScreen(
        branchName: _getBranchName(_selectedBranch),
        userName: _userName,
        permissions: _permissions,
        initialCart: widget.testInitialCart,
        testOpenReports: widget.testOpenReports,
        onLogout: () => setState(() => _signedIn = false),
        onToggleTheme: _toggleTheme,
      );
    }
    if (_role == UserRole.merchant) {
      return MerchantPosScreen(
        branchName: _getBranchName(_selectedBranch),
        permissions: _permissions,
        onLogout: () => setState(() => _signedIn = false),
        onToggleTheme: _toggleTheme,
      );
    }
    return AppShell(
      onToggleTheme: _toggleTheme,
      onLogout: () => setState(() => _signedIn = false),
      currentPrimary: _primary,
      onPrimaryChanged: (s) => setState(() => _primary = s),
      chartStyle: _chartStyle,
      onChartStyleChanged: (s) => setState(() => _chartStyle = s),
      selectedBranch: _selectedBranch,
      onBranchChanged: (branch) => setState(() => _selectedBranch = branch),
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
    if (_ownsDb) _db.close();
    _license.dispose();
    _demoStore.dispose();
    super.dispose();
  }
}

/// Branded holding screen while the stored license is read and re-validated.
/// Nothing here can overflow: it is a centered, bounded column.
class _LicenseSplash extends StatelessWidget {
  const _LicenseSplash();

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: taj.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: taj.primary.main,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                'ت',
                style: TextStyle(
                  color: taj.primary.contrastText,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تاج',
              style: text.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: taj.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'جارٍ التحقق من الترخيص…',
              style: text.bodyMedium?.copyWith(color: taj.textSecondary),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
