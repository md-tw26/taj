import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/branches.dart';
import '../../core/chart_style.dart';
import '../../core/theme/taj_colors.dart';
import '../../core/responsive.dart';
import '../../modules/customers/customers_screen.dart';
import '../../modules/dashboard/dashboard_screen.dart';
import '../../modules/employees/employees_screen.dart';
import '../../modules/expenses/expenses_screen.dart';
import '../../modules/inventory/inventory_screen.dart';
import '../../modules/notifications/notifications_screen.dart';
import '../../modules/pos_management/pos_management_screen.dart';
import '../../modules/products/products_screen.dart';
import '../../modules/purchases/purchases_screen.dart';
import '../../modules/reports/reports_screen.dart';
import '../../modules/smart_reports/smart_reports_screen.dart';
import '../../modules/assistant/assistant_screen.dart';
import '../../modules/sales/sales_screen.dart';
import '../../modules/accounting/accounting_screen.dart';
import '../../modules/settings/settings_screen.dart';
import '../../modules/treasury/treasury_screen.dart';
import '../../modules/users/users_screen.dart';
import '../../modules/day_closing/day_closing_screen.dart';
import 'taj_ui.dart';

// ---------------------------------------------------------------------------
// Navigation model
// ---------------------------------------------------------------------------

class NavItem {
  const NavItem(
    this.id,
    this.icon,
    this.selectedIcon,
    this.label, {
    this.shortcut,
  });
  final String id;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? shortcut;
}

class NavGroup {
  const NavGroup(this.title, this.items);
  final String title;
  final List<NavItem> items;
}

const _pinned = <NavItem>[
  NavItem(
    'dashboard',
    Icons.dashboard_outlined,
    Icons.dashboard_rounded,
    'لوحة التحكم',
    shortcut: 'G D',
  ),
  NavItem(
    'inbox',
    Icons.notifications_none_rounded,
    Icons.notifications_rounded,
    'الإشعارات',
    shortcut: 'G I',
  ),
  NavItem('day', Icons.today_outlined, Icons.today_rounded, 'اليوم التشغيلي'),
];

const _groups = <NavGroup>[
  NavGroup('المبيعات', [
    NavItem(
      'pos',
      Icons.point_of_sale_outlined,
      Icons.point_of_sale_rounded,
      'نقاط البيع',
    ),
    NavItem(
      'sales',
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
      'المبيعات',
    ),
    NavItem(
      'customers',
      Icons.groups_outlined,
      Icons.groups_rounded,
      'العملاء والموردون',
    ),
  ]),
  NavGroup('المخزون', [
    NavItem(
      'items',
      Icons.inventory_2_outlined,
      Icons.inventory_2_rounded,
      'الأصناف',
    ),
    NavItem(
      'inventory',
      Icons.fact_check_outlined,
      Icons.fact_check_rounded,
      'المخزون والجرد',
    ),
    NavItem(
      'purchases',
      Icons.shopping_cart_outlined,
      Icons.shopping_cart_rounded,
      'المشتريات',
    ),
  ]),
  NavGroup('المالية', [
    NavItem(
      'expenses',
      Icons.payments_outlined,
      Icons.payments_rounded,
      'المصروفات',
    ),
    NavItem(
      'treasury',
      Icons.account_balance_outlined,
      Icons.account_balance_rounded,
      'الخزائن والبنوك',
    ),
    NavItem(
      'accounting',
      Icons.account_tree_outlined,
      Icons.account_tree_rounded,
      'المحاسبة',
    ),
  ]),
  NavGroup('الموارد البشرية', [
    NavItem(
      'employees',
      Icons.badge_outlined,
      Icons.badge_rounded,
      'الموظفون والرواتب',
    ),
  ]),
  NavGroup('التقارير', [
    NavItem(
      'reports',
      Icons.summarize_outlined,
      Icons.summarize_rounded,
      'التقارير',
    ),
    NavItem(
      'smart',
      Icons.insights_outlined,
      Icons.insights_rounded,
      'التقارير الذكية',
    ),
    NavItem(
      'assistant',
      Icons.auto_awesome_outlined,
      Icons.auto_awesome_rounded,
      'المساعد الذكي',
    ),
  ]),
  NavGroup('النظام', [
    NavItem(
      'users',
      Icons.admin_panel_settings_outlined,
      Icons.admin_panel_settings_rounded,
      'المستخدمون والصلاحيات',
    ),
    NavItem(
      'settings',
      Icons.settings_outlined,
      Icons.settings_rounded,
      'الإعدادات',
    ),
  ]),
];

List<NavItem> get _allItems => [
  ..._pinned,
  for (final g in _groups) ...g.items,
];

NavItem _itemById(String id) =>
    _allItems.firstWhere((e) => e.id == id, orElse: () => _pinned.first);

// ---------------------------------------------------------------------------
// Shell
// ---------------------------------------------------------------------------

enum SyncState { online, offline, syncing }

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.onToggleTheme,
    required this.currentPrimary,
    required this.onPrimaryChanged,
    required this.chartStyle,
    required this.onChartStyleChanged,
    this.onLogout,
    this.selectedBranch = kDefaultBranch,
    this.onBranchChanged,
  });

  final VoidCallback onToggleTheme;
  final TajSwatch currentPrimary;
  final ValueChanged<TajSwatch> onPrimaryChanged;
  final ChartStyle chartStyle;
  final ValueChanged<ChartStyle> onChartStyleChanged;
  final VoidCallback? onLogout;
  final AppBranch selectedBranch;
  final ValueChanged<AppBranch>? onBranchChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _selected = 'dashboard';
  late AppBranch _selectedBranch;
  bool _collapsed = false;
  final Set<String> _openGroups = {for (final g in _groups) g.title};
  final SyncState _sync = SyncState.online;
  final int _pending = 0;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.selectedBranch;
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedBranch != oldWidget.selectedBranch) {
      _selectedBranch = widget.selectedBranch;
    }
  }

  void _changeBranch(AppBranch branch) {
    setState(() => _selectedBranch = branch);
    widget.onBranchChanged?.call(branch);
  }

  void _select(String id, {bool closeDrawer = false}) {
    setState(() => _selected = id);
    if (closeDrawer) Navigator.of(context).maybePop();
  }

  Widget _pageFor(String id) {
    switch (id) {
      case 'dashboard':
        return DashboardScreen(chartStyle: widget.chartStyle);
      case 'day':
        return const DayClosingScreen();
      case 'pos':
        return PosManagementScreen(
          branchId: switch (_selectedBranch.id) {
            'main' || 'tripoli' => 'b1',
            'benghazi' => 'b2',
            'misrata' => 'b3',
            _ => null,
          },
        );
      case 'items':
        return const ProductsScreen();
      case 'inventory':
        return const InventoryScreen();
      case 'sales':
        return const SalesScreen();
      case 'purchases':
        return const PurchasesScreen();
      case 'expenses':
        return const ExpensesScreen();
      case 'treasury':
        return const TreasuryScreen();
      case 'accounting':
        return const AccountingScreen();
      case 'employees':
        return const EmployeesScreen();
      case 'customers':
        return const CustomersScreen();
      case 'reports':
        return const ReportsScreen();
      case 'smart':
        return const SmartReportsScreen();
      case 'assistant':
        return const AssistantScreen();
      case 'users':
        return const UsersScreen();
      case 'inbox':
        return const NotificationsScreen();
      case 'settings':
        return SettingsScreen(
          currentPrimary: widget.currentPrimary,
          onPrimaryChanged: widget.onPrimaryChanged,
          onToggleTheme: widget.onToggleTheme,
          chartStyle: widget.chartStyle,
          onChartStyleChanged: widget.onChartStyleChanged,
        );
      default:
        return _ComingSoon(title: _itemById(id).label);
    }
  }

  Future<void> _openCommandPalette() async {
    final id = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const _CommandPalette(),
    );
    if (id != null) _select(id);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _openCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _openCommandPalette,
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            if (w < AppBreakpoints.phone) return _buildPhone(context);
            final rail = w < AppBreakpoints.tablet || _collapsed;
            return _buildWide(context, rail: rail);
          },
        ),
      ),
    );
  }

  // ---- Wide / desktop ----
  Widget _buildWide(BuildContext context, {required bool rail}) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selected: _selected,
            selectedBranch: _selectedBranch,
            onBranchChanged: _changeBranch,
            rail: rail,
            openGroups: _openGroups,
            onSelect: (id) => _select(id),
            onToggleGroup:
                (t) => setState(
                  () =>
                      _openGroups.contains(t)
                          ? _openGroups.remove(t)
                          : _openGroups.add(t),
                ),
            onSearch: _openCommandPalette,
          ),
          VerticalDivider(width: 1, color: context.taj.divider),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  title: _itemById(_selected).label,
                  sync: _sync,
                  pending: _pending,
                  collapsed: _collapsed,
                  showCollapseToggle:
                      MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet,
                  onToggleCollapse:
                      () => setState(() => _collapsed = !_collapsed),
                  onToggleTheme: widget.onToggleTheme,
                  onSearch: _openCommandPalette,
                  onOpenInbox: () => _select('inbox'),
                  onLogout: widget.onLogout,
                ),
                Expanded(
                  child: SafeArea(top: false, child: _pageFor(_selected)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Phone ----
  Widget _buildPhone(BuildContext context) {
    const bottom = ['dashboard', 'pos', 'sales', 'reports'];
    final idx = bottom.indexOf(_selected);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Text(
          _itemById(_selected).label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          _SyncPill(state: _sync, pending: _pending, compact: true),
          IconButton(
            onPressed: _openCommandPalette,
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        width: drawerWidth(context, desired: 300),
        child: _Sidebar(
          selected: _selected,
          selectedBranch: _selectedBranch,
          onBranchChanged: _changeBranch,
          rail: false,
          openGroups: _openGroups,
          onSelect: (id) => _select(id, closeDrawer: true),
          onToggleGroup:
              (t) => setState(
                () =>
                    _openGroups.contains(t)
                        ? _openGroups.remove(t)
                        : _openGroups.add(t),
              ),
          onSearch: () {
            Navigator.of(context).maybePop();
            _openCommandPalette();
          },
        ),
      ),
      body: SafeArea(child: _pageFor(_selected)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx < 0 ? 0 : idx,
        onDestinationSelected: (i) => _select(bottom[i]),
        destinations: [
          for (final id in bottom)
            NavigationDestination(
              icon: Icon(_itemById(id).icon),
              selectedIcon: Icon(_itemById(id).selectedIcon),
              label: _itemById(id).label,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.selectedBranch,
    required this.onBranchChanged,
    required this.rail,
    required this.openGroups,
    required this.onSelect,
    required this.onToggleGroup,
    required this.onSearch,
  });

  final String selected;
  final AppBranch selectedBranch;
  final ValueChanged<AppBranch>? onBranchChanged;
  final bool rail;
  final Set<String> openGroups;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onToggleGroup;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Container(
      width: rail ? 76 : 264,
      color: taj.paper,
      child: SafeArea(
        right: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WorkspaceSwitcher(
              rail: rail,
              selectedBranch: selectedBranch,
              onBranchChanged: onBranchChanged,
            ),
            if (!rail)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: _SearchTrigger(onTap: onSearch),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _RailButton(
                  icon: Icons.search_rounded,
                  tip: 'بحث (⌘K)',
                  onTap: onSearch,
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final item in _pinned)
                    _NavTile(
                      item: item,
                      selected: item.id == selected,
                      rail: rail,
                      onTap: () => onSelect(item.id),
                    ),
                  const SizedBox(height: 4),
                  for (final group in _groups) ...[
                    if (!rail)
                      _GroupHeader(
                        title: group.title,
                        open: openGroups.contains(group.title),
                        onTap: () => onToggleGroup(group.title),
                      )
                    else
                      _RailDivider(),
                    if (rail || openGroups.contains(group.title))
                      for (final item in group.items)
                        _NavTile(
                          item: item,
                          selected: item.id == selected,
                          rail: rail,
                          onTap: () => onSelect(item.id),
                        ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceSwitcher extends StatelessWidget {
  const _WorkspaceSwitcher({
    required this.rail,
    required this.selectedBranch,
    required this.onBranchChanged,
  });
  final bool rail;
  final AppBranch selectedBranch;
  final ValueChanged<AppBranch>? onBranchChanged;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    final logo = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: taj.primary.main,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        'T',
        style: TextStyle(
          color: taj.primary.contrastText,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );

    if (rail) {
      return Padding(padding: const EdgeInsets.all(18), child: logo);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
      child: PopupMenuButton<AppBranch>(
        tooltip: 'تبديل الفرع',
        onSelected: onBranchChanged,
        itemBuilder:
            (context) => [
              for (final branch in kBranches)
                PopupMenuItem<AppBranch>(
                  value: branch,
                  child: Row(
                    children: [
                      Expanded(child: Text(branch.name)),
                      if (branch.id == selectedBranch.id)
                        Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: taj.primary.main,
                        ),
                    ],
                  ),
                ),
            ],
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            children: [
              logo,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('شركة تاج', style: text.titleSmall),
                    Text(
                      selectedBranch.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: taj.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                size: 18,
                color: taj.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchTrigger extends StatelessWidget {
  const _SearchTrigger({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: taj.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: taj.divider),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: taj.textSecondary),
              const SizedBox(width: 8),
              Text(
                'بحث…',
                style: text.bodyMedium?.copyWith(color: taj.textDisabled),
              ),
              const Spacer(),
              _Keycap(text: '⌘K'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keycap extends StatelessWidget {
  const _Keycap({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: taj.divider),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: taj.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.open,
    required this.onTap,
  });
  final String title;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
          child: Row(
            children: [
              Text(
                title.toUpperCase(),
                style: text.labelSmall?.copyWith(
                  color: taj.textDisabled,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: open ? 0 : -0.25,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: taj.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.rail,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final bool rail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final fg = selected ? taj.primary.dark : taj.textSecondary;

    final tile = Container(
      height: 42,
      margin: EdgeInsets.symmetric(horizontal: rail ? 12 : 10, vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: rail ? 0 : 10),
      decoration: BoxDecoration(
        color: selected ? taj.primary.lighter : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          rail
              ? Icon(
                selected ? item.selectedIcon : item.icon,
                size: 21,
                color: fg,
              )
              : Row(
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 20,
                    color: fg,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(
                        color: selected ? taj.primary.dark : taj.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (item.shortcut != null)
                    Text(
                      item.shortcut!,
                      style: text.labelSmall?.copyWith(color: taj.textDisabled),
                    ),
                ],
              ),
    );

    Widget result = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: tile,
      ),
    );
    if (rail) result = Tooltip(message: item.label, child: result);
    return result;
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.tip,
    required this.onTap,
  });
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Tooltip(
      message: tip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: taj.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: taj.divider),
            ),
            child: Icon(icon, size: 19, color: taj.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _RailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Divider(height: 1, color: context.taj.divider),
  );
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.sync,
    required this.pending,
    required this.collapsed,
    required this.showCollapseToggle,
    required this.onToggleCollapse,
    required this.onToggleTheme,
    required this.onSearch,
    required this.onOpenInbox,
    required this.onLogout,
  });

  final String title;
  final SyncState sync;
  final int pending;
  final bool collapsed;
  final bool showCollapseToggle;
  final VoidCallback onToggleCollapse;
  final VoidCallback onToggleTheme;
  final VoidCallback onSearch;
  final VoidCallback onOpenInbox;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Container(
        height: 66,
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        decoration: BoxDecoration(
          color: taj.background,
          border: Border(bottom: BorderSide(color: taj.divider)),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            // On narrow widths (small tablets / split windows) drop the
            // breadcrumb and language pill and collapse the sync pill so the
            // action cluster always fits without overflowing.
            final tight = c.maxWidth < 720;
            return Row(
              children: [
                if (showCollapseToggle)
                  IconButton(
                    tooltip: collapsed ? 'توسيع' : 'طي',
                    onPressed: onToggleCollapse,
                    icon: const Icon(Icons.menu_rounded, size: 22),
                  ),
                // Breadcrumb + title — flexible so they ellipsize before the
                // row can overflow.
                Expanded(
                  child: Row(
                    children: [
                      if (!tight) ...[
                        Text(
                          'الرئيسية',
                          style: text.bodyMedium?.copyWith(
                            color: taj.textSecondary,
                          ),
                        ),
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: taj.textSecondary,
                        ),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          style: text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SyncPill(state: sync, pending: pending, compact: tight),
                const SizedBox(width: 8),
                if (!tight) ...[
                  _LanguagePill(),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                  onPressed: onToggleTheme,
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                ),
                NotificationBell(onOpenFull: onOpenInbox),
                const SizedBox(width: 8),
                _UserMenu(onLogout: onLogout),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({
    required this.state,
    required this.pending,
    this.compact = false,
  });
  final SyncState state;
  final int pending;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final (label, swatch, icon) = switch (state) {
      SyncState.online => ('متصل', taj.success, Icons.cloud_done_outlined),
      SyncState.offline => ('غير متصل', taj.warning, Icons.cloud_off_outlined),
      SyncState.syncing => ('جارٍ المزامنة', taj.info, Icons.sync_rounded),
    };
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, size: 20, color: swatch.dark),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: swatch.lighter,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: swatch.dark),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: swatch.dark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (pending > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: swatch.dark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$pending',
                style: TextStyle(
                  color: swatch.contrastText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap:
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الإنجليزية — قريبًا')),
            ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: taj.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: taj.primary.lighter,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'ع',
                  style: TextStyle(
                    color: taj.primary.dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'EN',
                style: TextStyle(
                  color: taj.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({this.onLogout});
  final VoidCallback? onLogout;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return PopupMenuButton<String>(
      tooltip: 'الحساب',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        if (v == 'logout') onLogout?.call();
      },
      itemBuilder:
          (_) => const [
            PopupMenuItem(value: 'profile', child: Text('الملف الشخصي')),
            PopupMenuItem(value: 'settings', child: Text('الإعدادات')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
          ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: taj.primary.lighter,
        child: Text(
          'ط',
          style: TextStyle(
            color: taj.primary.dark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Command palette (⌘K)
// ---------------------------------------------------------------------------

class _CommandPalette extends StatefulWidget {
  const _CommandPalette();
  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final results =
        _allItems.where((e) => e.label.contains(_query.trim())).toList();

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 96, left: 24, right: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'انتقل إلى… أو ابحث',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            Divider(height: 1, color: taj.divider),
            Flexible(
              child:
                  results.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          'لا نتائج',
                          style: text.bodyMedium?.copyWith(
                            color: taj.textSecondary,
                          ),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final item = results[i];
                          return ListTile(
                            leading: Icon(
                              item.icon,
                              size: 20,
                              color: taj.textSecondary,
                            ),
                            title: Text(item.label, style: text.bodyMedium),
                            trailing:
                                item.shortcut != null
                                    ? _Keycap(text: item.shortcut!)
                                    : null,
                            onTap: () => Navigator.of(context).pop(item.id),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder
// ---------------------------------------------------------------------------

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return TajEmptyState(
      icon: Icons.construction_outlined,
      title: title,
      message: 'هذه الوحدة قيد الإنشاء — سيتم تصميمها ضمن الشاشات الـ18.',
    );
  }
}
