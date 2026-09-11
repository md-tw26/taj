import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_provider.dart';
import '../../core/demo/demo_store.dart';
import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_ui.dart';

/// Employees & Payroll: employee list/table, a dense tabbed profile (salary
/// breakdown · advances/withdrawals · linked expenses), monthly payroll run,
/// summary cards, filters and add/edit + pay-salary dialogs.
///
/// Every numeric field reads in full at 320px — no shrunk fonts, no truncated
/// figures (long amounts go compact with the exact value one tap/hover away),
/// no payroll column dropped (wide tables scroll with a frozen name column and
/// net/status surfaced up front). Net pay is always visible or one tap away.
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

enum _Section { employees, payroll }

class _EmployeesScreenState extends State<EmployeesScreen> {
  _Section _section = _Section.employees;
  String? _selectedId;
  bool _profilePushed = false; // single-pane: showing profile full page
  String? _branchFilter;
  String _statusFilter = 'all'; // all · paid · unpaid
  final Set<String> _selected = {}; // payroll-run selection

  DemoStore get _store => DemoStoreProvider.of(context);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (_, __) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final taj = context.taj;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, c) {
          return PageContainer(
            maxWidth: AppBreakpoints.employeeContentMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionBar(
                  current: _section,
                  onSelect: (s) => setState(() => _section = s),
                ),
                Divider(height: 1, color: taj.divider),
                Expanded(
                  child: _section == _Section.employees
                      ? _employeesBody(c.maxWidth, c.maxHeight)
                      : _PayrollRun(
                          store: _store,
                          width: c.maxWidth,
                          selected: _selected,
                          branchFilter: _branchFilter,
                          onToggle: (id) => setState(() {
                            _selected.contains(id)
                                ? _selected.remove(id)
                                : _selected.add(id);
                          }),
                          onBranch: (v) => setState(() => _branchFilter = v),
                          onClear: () => setState(_selected.clear),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<DemoEmployee> _visible() => _store.employees.where((e) {
        if (_branchFilter != null && e.branchId != _branchFilter) return false;
        if (_statusFilter == 'paid' && !_store.isSalaryPaid(e.id)) return false;
        if (_statusFilter == 'unpaid' && _store.isSalaryPaid(e.id)) return false;
        return true;
      }).toList();

  Widget _employeesBody(double width, double height) {
    final master = width >= AppBreakpoints.employeeSplit;
    final employees = _visible();
    final selected = (_selectedId != null &&
            _store.employees.any((e) => e.id == _selectedId))
        ? _selectedId
        : null;

    if (!master) {
      // Single pane: a selected employee opens the profile full-page.
      if (selected != null && _profilePushed) {
        return _EmployeeProfile(
          store: _store,
          employeeId: selected,
          width: width,
          height: height,
          showBack: true,
          onBack: () => setState(() => _profilePushed = false),
          onEdit: () => _openEmployeeDialog(edit: _store.employeeById(selected)),
          onPay: () => _openPayDialog(selected),
        );
      }
      return _EmployeesList(
        store: _store,
        employees: employees,
        width: width,
        selectedId: null,
        branchFilter: _branchFilter,
        statusFilter: _statusFilter,
        onBranch: (v) => setState(() => _branchFilter = v),
        onStatus: (v) => setState(() => _statusFilter = v),
        onAdd: () => _openEmployeeDialog(),
        onTap: (id) => setState(() {
          _selectedId = id;
          _profilePushed = true;
        }),
      );
    }

    // Master-detail.
    final paneWidth = (width * 0.30).clamp(
        AppBreakpoints.employeeListPaneMin, AppBreakpoints.employeeListPaneMax);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: paneWidth.toDouble(),
          child: _EmployeesList(
            store: _store,
            employees: employees,
            width: paneWidth.toDouble(),
            selectedId: selected,
            branchFilter: _branchFilter,
            statusFilter: _statusFilter,
            onBranch: (v) => setState(() => _branchFilter = v),
            onStatus: (v) => setState(() => _statusFilter = v),
            onAdd: () => _openEmployeeDialog(),
            onTap: (id) => setState(() => _selectedId = id),
          ),
        ),
        Container(width: 1, color: context.taj.divider),
        Expanded(
          child: selected == null
              ? const TajEmptyState(
                  icon: Icons.badge_outlined,
                  title: 'اختر موظفًا',
                  message: 'اختر موظفًا من القائمة لعرض ملفه وراتبه.')
              : _EmployeeProfile(
                  store: _store,
                  employeeId: selected,
                  width: width - paneWidth.toDouble(),
                  height: height,
                  showBack: false,
                  onBack: () {},
                  onEdit: () =>
                      _openEmployeeDialog(edit: _store.employeeById(selected)),
                  onPay: () => _openPayDialog(selected),
                ),
        ),
      ],
    );
  }

  Future<void> _openEmployeeDialog({DemoEmployee? edit}) =>
      showEmployeeDialog(context, _store, edit: edit);

  Future<void> _openPayDialog(String employeeId) =>
      showPaySalaryDialog(context, _store, employeeId);
}

// ===========================================================================
// Section bar
// ===========================================================================

class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.current, required this.onSelect});
  final _Section current;
  final ValueChanged<_Section> onSelect;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _SectionChip(
            label: 'الموظفون',
            icon: Icons.groups_outlined,
            selected: current == _Section.employees,
            onTap: () => onSelect(_Section.employees),
          ),
          const SizedBox(width: 8),
          _SectionChip(
            label: 'مسير الرواتب',
            icon: Icons.payments_outlined,
            selected: current == _Section.payroll,
            onTap: () => onSelect(_Section.payroll),
          ),
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Material(
      color: selected ? taj.primary.lighter : taj.paper,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: selected ? taj.primary.light : taj.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 17,
                  color: selected ? taj.primary.dark : taj.textSecondary),
              const SizedBox(width: 7),
              Text(label,
                  style: text.labelLarge?.copyWith(
                      color: selected ? taj.primary.dark : taj.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Employees list (summary cards + filters + cards/table)
// ===========================================================================

class _EmployeesList extends StatelessWidget {
  const _EmployeesList({
    required this.store,
    required this.employees,
    required this.width,
    required this.selectedId,
    required this.branchFilter,
    required this.statusFilter,
    required this.onBranch,
    required this.onStatus,
    required this.onAdd,
    required this.onTap,
  });
  final DemoStore store;
  final List<DemoEmployee> employees;
  final double width;
  final String? selectedId;
  final String? branchFilter;
  final String statusFilter;
  final ValueChanged<String?> onBranch;
  final ValueChanged<String> onStatus;
  final VoidCallback onAdd;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final compactPane = width < AppBreakpoints.phone; // list-pane cards vs table

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('الموظفون',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('موظف'),
              ),
            ],
          ),
        ),
        // Summary cards adapt 1→4 columns.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _SummaryCards(store: store, width: width),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterPill<String?>(
                icon: Icons.store_outlined,
                value: branchFilter,
                options: [
                  const (null, 'كل الفروع'),
                  for (final b in store.branches) (b.id, b.city),
                ],
                onSelected: onBranch,
              ),
              _FilterPill<String>(
                icon: Icons.flag_outlined,
                value: statusFilter,
                options: const [
                  ('all', 'كل الحالات'),
                  ('paid', 'مدفوع'),
                  ('unpaid', 'غير مدفوع'),
                ],
                onSelected: onStatus,
              ),
            ],
          ),
        ),
        Expanded(
          child: employees.isEmpty
              ? const TajEmptyState(
                  icon: Icons.badge_outlined,
                  title: 'لا موظفين',
                  message: 'لا يوجد موظفون مطابقون للفلاتر الحالية.')
              : compactPane
                  ? _EmployeeCards(
                      store: store,
                      employees: employees,
                      selectedId: selectedId,
                      onTap: onTap)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _EmployeeTable(
                        store: store,
                        employees: employees,
                        selectedId: selectedId,
                        onTap: onTap,
                      ),
                    ),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.store, required this.width});
  final DemoStore store;
  final double width;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final emps = store.employees;
    final totalPayroll =
        emps.fold<double>(0, (s, e) => s + store.employeeNet(e.id));
    final paid = emps.where((e) => store.isSalaryPaid(e.id)).length;
    final unpaid = emps.length - paid;
    final tiles = <Widget>[
      _SummaryTile(
          label: 'الموظفون',
          valueText: '${emps.length}',
          icon: Icons.groups_outlined,
          swatch: taj.primary),
      _SummaryTile(
          label: 'إجمالي الرواتب',
          value: totalPayroll,
          icon: Icons.payments_outlined,
          swatch: taj.info),
      _SummaryTile(
          label: 'مدفوع',
          valueText: '$paid',
          icon: Icons.check_circle_outline_rounded,
          swatch: taj.success),
      _SummaryTile(
          label: 'غير مدفوع',
          valueText: '$unpaid',
          icon: Icons.pending_outlined,
          swatch: taj.warning),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1040
            ? 4
            : c.maxWidth >= 760
                ? 3
                : c.maxWidth >= 400
                    ? 2
                    : 1;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.icon,
    required this.swatch,
    this.value,
    this.valueText,
  });
  final String label;
  final IconData icon;
  final TajSwatch swatch;
  final double? value;
  final String? valueText;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return TajCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: swatch.lighter,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: swatch.dark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: taj.textSecondary)),
                const SizedBox(height: 3),
                if (value != null)
                  _Money(
                      value: value!,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      maxLines: 2,
                      color: taj.textPrimary)
                else
                  Text(valueText ?? '',
                      style: AppThemes.numeralStyle(context,
                          fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCards extends StatelessWidget {
  const _EmployeeCards({
    required this.store,
    required this.employees,
    required this.selectedId,
    required this.onTap,
  });
  final DemoStore store;
  final List<DemoEmployee> employees;
  final String? selectedId;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: employees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = employees[i];
        return _EmployeeCard(
          store: store,
          employee: e,
          selected: e.id == selectedId,
          onTap: () => onTap(e.id),
        );
      },
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.store,
    required this.employee,
    required this.selected,
    required this.onTap,
  });
  final DemoStore store;
  final DemoEmployee employee;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final net = store.employeeNet(employee.id);
    final paid = store.isSalaryPaid(employee.id);
    return TajCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _Avatar(employee: employee, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(employee.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(employee.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: taj.textSecondary)),
                const SizedBox(height: 6),
                _PayStatusBadge(paid: paid),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('الصافي: ',
                        style:
                            text.bodySmall?.copyWith(color: taj.textSecondary)),
                    Expanded(
                      child: _Money(
                          value: net,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: taj.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_left_rounded, color: taj.textDisabled),
        ],
      ),
    );
  }
}

class _EmployeeTable extends StatelessWidget {
  const _EmployeeTable({
    required this.store,
    required this.employees,
    required this.selectedId,
    required this.onTap,
  });
  final DemoStore store;
  final List<DemoEmployee> employees;
  final String? selectedId;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return _FinTable(
      frozenCol: const _FinCol('الموظف', 190),
      restCols: const [
        _FinCol('المسمى', 130),
        _FinCol('الفرع', 96),
        _FinCol('الصافي', 132, numeric: true),
        _FinCol('الحالة', 160),
      ],
      rows: [
        for (final e in employees)
          _FinRow(
            selected: e.id == selectedId,
            onTap: () => onTap(e.id),
            frozen: Row(
              children: [
                _Avatar(employee: e, size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            cells: [
              Text(e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall),
              Text(_branchCity(store, e.branchId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: taj.textSecondary)),
              _Money(
                  value: store.employeeNet(e.id),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  maxChars: 12,
                  color: taj.textPrimary),
              _PayStatusBadge(paid: store.isSalaryPaid(e.id)),
            ],
          ),
      ],
    );
  }
}

// ===========================================================================
// Employee profile (condensing header + tabs)
// ===========================================================================

class _EmployeeProfile extends StatelessWidget {
  const _EmployeeProfile({
    required this.store,
    required this.employeeId,
    required this.width,
    required this.height,
    required this.showBack,
    required this.onBack,
    required this.onEdit,
    required this.onPay,
  });
  final DemoStore store;
  final String employeeId;
  final double width;
  final double height;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final e = store.employeeById(employeeId);
    if (e == null) {
      return const TajEmptyState(icon: Icons.badge_outlined, title: 'غير موجود');
    }
    final phone = width < AppBreakpoints.phone;
    final compact = phone || height < 520;

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(
            store: store,
            employee: e,
            compact: compact,
            showBack: showBack,
            onBack: onBack,
            onEdit: onEdit,
            onPay: onPay,
          ),
          Material(
            color: taj.paper,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: taj.primary.dark,
              unselectedLabelColor: taj.textSecondary,
              indicatorColor: taj.primary.main,
              tabs: const [
                Tab(text: 'الراتب'),
                Tab(text: 'السلف والسحوبات'),
                Tab(text: 'المصروفات المرتبطة'),
              ],
            ),
          ),
          Divider(height: 1, color: taj.divider),
          Expanded(
            child: TabBarView(
              children: [
                _SalaryBreakdownTab(store: store, employee: e, width: width),
                _AdvancesTab(store: store, employee: e),
                _LinkedExpensesTab(store: store, employee: e),
              ],
            ),
          ),
          if (phone)
            _ProfileBottomBar(onEdit: onEdit, onPay: onPay, store: store, employeeId: employeeId),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.store,
    required this.employee,
    required this.compact,
    required this.showBack,
    required this.onBack,
    required this.onEdit,
    required this.onPay,
  });
  final DemoStore store;
  final DemoEmployee employee;
  final bool compact;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final net = store.employeeNet(employee.id);
    final paid = store.isSalaryPaid(employee.id);
    final avatarSize = compact ? 40.0 : 52.0;

    final identity = Row(
      children: [
        if (showBack)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_forward_rounded),
              tooltip: 'رجوع',
            ),
          ),
        _Avatar(employee: employee, size: avatarSize),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(employee.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium),
              const SizedBox(height: 2),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(employee.title,
                      style:
                          text.bodySmall?.copyWith(color: taj.textSecondary)),
                  Text(_branchCity(store, employee.branchId),
                      style:
                          text.bodySmall?.copyWith(color: taj.textDisabled)),
                  _PayStatusBadge(paid: paid),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    // Net card — always visible, prominent; the most important figure.
    final netCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: taj.primary.lighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('صافي الراتب',
              style: text.bodySmall?.copyWith(color: taj.primary.dark)),
          const SizedBox(height: 2),
          _Money(
              value: net,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              maxLines: 2,
              color: taj.primary.dark),
        ],
      ),
    );

    final actions = compact
        ? const SizedBox.shrink()
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('تعديل'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: paid ? null : onPay,
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('دفع الراتب'),
              ),
            ],
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                identity,
                const SizedBox(height: 12),
                netCard,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: identity),
                const SizedBox(width: 12),
                netCard,
                const SizedBox(width: 12),
                actions,
              ],
            ),
    );
  }
}

class _ProfileBottomBar extends StatelessWidget {
  const _ProfileBottomBar(
      {required this.onEdit,
      required this.onPay,
      required this.store,
      required this.employeeId});
  final VoidCallback onEdit;
  final VoidCallback onPay;
  final DemoStore store;
  final String employeeId;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final paid = store.isSalaryPaid(employeeId);
    return Container(
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(top: BorderSide(color: taj.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('تعديل'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: paid ? null : onPay,
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('دفع الراتب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalaryBreakdownTab extends StatelessWidget {
  const _SalaryBreakdownTab(
      {required this.store, required this.employee, required this.width});
  final DemoStore store;
  final DemoEmployee employee;
  final double width;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final e = employee;
    final advances = store.advancesTotal(e.id);
    final withdrawals = store.withdrawalsTotal(e.id);
    final totalDeductions = e.deductions + advances + withdrawals;
    final net = e.grossEarnings - totalDeductions;

    final earnings = <_Kv>[
      _Kv('الراتب الأساسي', e.baseSalary),
      _Kv('البدلات', e.allowances),
      _Kv('المكافآت', e.bonuses),
      _Kv('العمولات', e.commissions),
      _Kv('الوقت الإضافي', e.overtime),
      _Kv('إجمالي الاستحقاقات', e.grossEarnings, emphasize: true),
    ];
    final deductions = <_Kv>[
      _Kv('الاستقطاعات', e.deductions),
      _Kv('السلف', advances),
      _Kv('السحوبات', withdrawals),
      _Kv('إجمالي الاستقطاعات', totalDeductions, emphasize: true),
    ];

    // Column count for the field groups by available width.
    final twoCol = width >= AppBreakpoints.phone;
    final threeCol = width >= AppBreakpoints.employeeSplit;

    Widget group(String title, List<_Kv> rows, Color accent) => _KvGroup(
          title: title,
          rows: rows,
          accent: accent,
        );

    final netBox = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: taj.primary.lighter,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: taj.primary.light),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('صافي الراتب',
                style: text.titleMedium?.copyWith(color: taj.primary.dark)),
          ),
          const SizedBox(width: 12),
          _Money(
              value: net,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              maxLines: 2,
              color: taj.primary.dark),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (threeCol)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: group('الاستحقاقات', earnings, taj.success.main)),
              const SizedBox(width: 12),
              Expanded(
                  child: group('الاستقطاعات', deductions, taj.error.main)),
              const SizedBox(width: 12),
              Expanded(child: netBox),
            ],
          )
        else if (twoCol)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: group('الاستحقاقات', earnings, taj.success.main)),
              const SizedBox(width: 12),
              Expanded(
                  child: group('الاستقطاعات', deductions, taj.error.main)),
            ],
          )
        else ...[
          group('الاستحقاقات', earnings, taj.success.main),
          const SizedBox(height: 12),
          group('الاستقطاعات', deductions, taj.error.main),
        ],
        if (!threeCol) ...[
          const SizedBox(height: 12),
          netBox,
        ],
      ],
    );
  }
}

class _Kv {
  const _Kv(this.label, this.value, {this.emphasize = false});
  final String label;
  final double value;
  final bool emphasize;
}

class _KvGroup extends StatelessWidget {
  const _KvGroup(
      {required this.title, required this.rows, required this.accent});
  final String title;
  final List<_Kv> rows;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: taj.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: taj.background,
            child: Row(
              children: [
                Container(width: 4, height: 16, color: accent),
                const SizedBox(width: 8),
                Text(title,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: taj.divider),
            _KvRow(kv: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.kv});
  final _Kv kv;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      color: kv.emphasize ? taj.background : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Label wraps to two lines; never pushes the value off-screen.
          Expanded(
            child: Text(kv.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                    fontWeight:
                        kv.emphasize ? FontWeight.w800 : FontWeight.w400,
                    color: kv.emphasize ? taj.textPrimary : taj.textSecondary)),
          ),
          const SizedBox(width: 12),
          _Money(
              value: kv.value,
              fontSize: 14,
              fontWeight: kv.emphasize ? FontWeight.w800 : FontWeight.w700,
              maxChars: 13,
              color: taj.textPrimary),
        ],
      ),
    );
  }
}

class _AdvancesTab extends StatelessWidget {
  const _AdvancesTab({required this.store, required this.employee});
  final DemoStore store;
  final DemoEmployee employee;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final txns = store.payrollTxnsFor(employee.id);
    final advances =
        txns.where((t) => t.type == DemoPayrollTxnType.advance).toList();
    final withdrawals =
        txns.where((t) => t.type == DemoPayrollTxnType.withdrawal).toList();

    Widget section(String title, List<DemoPayrollTxn> list, TajSwatch swatch,
        DemoPayrollTxnType type) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title,
                      style:
                          text.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
              TextButton.icon(
                onPressed: () =>
                    showPayrollTxnDialog(context, store, employee.id, type),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('إضافة'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('لا يوجد',
                  style: text.bodySmall?.copyWith(color: taj.textDisabled)),
            )
          else
            for (final t in list) _TxnRow(txn: t, swatch: swatch),
        ],
      );
    }

    // The tab body is itself the scroll view; inner lists are inlined (no
    // nested unbounded scrollables).
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        section('السلف', advances, taj.warning, DemoPayrollTxnType.advance),
        const SizedBox(height: 16),
        section('السحوبات', withdrawals, taj.info,
            DemoPayrollTxnType.withdrawal),
      ],
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn, required this.swatch});
  final DemoPayrollTxn txn;
  final TajSwatch swatch;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: taj.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(txn.note.isEmpty ? _fmtDate(txn.date) : txn.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium),
                Text(_fmtDate(txn.date),
                    style: AppThemes.numeralStyle(context,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: taj.textDisabled)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _Money(
              value: txn.amount,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: taj.accentFor(swatch)),
        ],
      ),
    );
  }
}

class _LinkedExpensesTab extends StatelessWidget {
  const _LinkedExpensesTab({required this.store, required this.employee});
  final DemoStore store;
  final DemoEmployee employee;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final linked = store.linkedExpensesFor(employee.id);
    if (linked.isEmpty) {
      return const TajEmptyState(
        icon: Icons.link_off_rounded,
        title: 'لا مصروفات مرتبطة',
        message: 'لم تُسجَّل رواتب مدفوعة مرتبطة بهذا الموظف بعد.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: linked.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final x = linked[i];
        return Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: taj.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: taj.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: taj.success.lighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.payments_outlined,
                    size: 19, color: taj.success.dark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('راتب — ${_branchCity(store, x.branchId)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(_fmtDate(x.date),
                        style: AppThemes.numeralStyle(context,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: taj.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Money(
                  value: x.amount,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: taj.textPrimary),
            ],
          ),
        );
      },
    );
  }
}

// ===========================================================================
// Monthly payroll run
// ===========================================================================

class _PayrollRun extends StatelessWidget {
  const _PayrollRun({
    required this.store,
    required this.width,
    required this.selected,
    required this.branchFilter,
    required this.onToggle,
    required this.onBranch,
    required this.onClear,
  });
  final DemoStore store;
  final double width;
  final Set<String> selected;
  final String? branchFilter;
  final ValueChanged<String> onToggle;
  final ValueChanged<String?> onBranch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final phone = width < AppBreakpoints.phone;
    final employees = store.employees
        .where((e) => branchFilter == null || e.branchId == branchFilter)
        .toList();
    final selectedNet = employees
        .where((e) => selected.contains(e.id))
        .fold<double>(0, (s, e) => s + store.employeeNet(e.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('مسير رواتب ${_monthLabel(DateTime.now())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium),
              ),
              const SizedBox(width: 8),
              _FilterPill<String?>(
                icon: Icons.store_outlined,
                value: branchFilter,
                options: [
                  const (null, 'كل الفروع'),
                  for (final b in store.branches) (b.id, b.city),
                ],
                onSelected: onBranch,
              ),
            ],
          ),
        ),
        Expanded(
          child: employees.isEmpty
              ? const TajEmptyState(
                  icon: Icons.payments_outlined, title: 'لا موظفين')
              : phone
                  ? _PayrollCards(
                      store: store,
                      employees: employees,
                      selected: selected,
                      onToggle: onToggle)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _PayrollTable(
                        store: store,
                        employees: employees,
                        selected: selected,
                        onToggle: onToggle,
                      ),
                    ),
        ),
        _PayrollActionBar(
          store: store,
          count: selected.length,
          totalNet: selectedNet,
          onClear: onClear,
          onPay: selected.isEmpty
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ids = selected.toList();
                  for (final id in ids) {
                    await store.paySalary(id);
                  }
                  onClear();
                  messenger.showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: taj.success.dark,
                    content: Text('تم دفع ${ids.length} راتب'),
                  ));
                },
        ),
      ],
    );
  }
}

class _PayrollTable extends StatelessWidget {
  const _PayrollTable({
    required this.store,
    required this.employees,
    required this.selected,
    required this.onToggle,
  });
  final DemoStore store;
  final List<DemoEmployee> employees;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    // Net and status are the first two columns after the frozen name, so they
    // are visible without scrolling; the components follow.
    return _FinTable(
      frozenCol: const _FinCol('الموظف', 220),
      restCols: const [
        _FinCol('الصافي', 132, numeric: true),
        _FinCol('الحالة', 160),
        _FinCol('الأساسي', 120, numeric: true),
        _FinCol('البدلات', 120, numeric: true),
        _FinCol('المكافآت', 120, numeric: true),
        _FinCol('العمولات', 120, numeric: true),
        _FinCol('الإضافي', 120, numeric: true),
        _FinCol('الاستقطاعات', 130, numeric: true),
        _FinCol('السلف', 120, numeric: true),
        _FinCol('السحوبات', 120, numeric: true),
      ],
      rows: [
        for (final e in employees)
          _FinRow(
            selected: selected.contains(e.id),
            onTap: () => onToggle(e.id),
            frozen: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Checkbox(
                    value: selected.contains(e.id),
                    onChanged: (_) => onToggle(e.id),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(e.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            cells: [
              _Money(
                  value: store.employeeNet(e.id),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  maxChars: 12,
                  color: taj.textPrimary),
              _PayStatusBadge(paid: store.isSalaryPaid(e.id)),
              _num(context, e.baseSalary),
              _num(context, e.allowances),
              _num(context, e.bonuses),
              _num(context, e.commissions),
              _num(context, e.overtime),
              _num(context, e.deductions),
              _num(context, store.advancesTotal(e.id)),
              _num(context, store.withdrawalsTotal(e.id)),
            ],
          ),
      ],
    );
  }

  Widget _num(BuildContext context, double v) => _Money(
      value: v,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      maxChars: 12,
      color: context.taj.textSecondary);
}

class _PayrollCards extends StatelessWidget {
  const _PayrollCards({
    required this.store,
    required this.employees,
    required this.selected,
    required this.onToggle,
  });
  final DemoStore store;
  final List<DemoEmployee> employees;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: employees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = employees[i];
        final sel = selected.contains(e.id);
        return TajCard(
          onTap: () => onToggle(e.id),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: sel,
                onChanged: (_) => onToggle(e.id),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              _Avatar(employee: e, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    _PayStatusBadge(paid: store.isSalaryPaid(e.id)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('الصافي: ',
                            style: text.bodySmall
                                ?.copyWith(color: taj.textSecondary)),
                        Expanded(
                          child: _Money(
                              value: store.employeeNet(e.id),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: taj.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PayrollActionBar extends StatelessWidget {
  const _PayrollActionBar({
    required this.store,
    required this.count,
    required this.totalNet,
    required this.onClear,
    required this.onPay,
  });
  final DemoStore store;
  final int count;
  final double totalNet;
  final VoidCallback onClear;
  final VoidCallback? onPay;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(top: BorderSide(color: taj.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: LayoutBuilder(
            builder: (context, c) {
              final summary = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('محدد: $count',
                      style:
                          text.bodySmall?.copyWith(color: taj.textSecondary)),
                  Row(
                    children: [
                      Flexible(
                        child: Text('الإجمالي: ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium
                                ?.copyWith(color: taj.textSecondary)),
                      ),
                      Flexible(
                        child: _Money(
                            value: totalNet,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: taj.textPrimary),
                      ),
                    ],
                  ),
                ],
              );
              final payBtn = FilledButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('دفع المحدد'),
              );
              final clearBtn = count > 0
                  ? TextButton(
                      onPressed: onClear, child: const Text('إلغاء'))
                  : null;
              // Narrow: stack the summary above full-width actions so a wide
              // button never squeezes the totals off-screen.
              if (c.maxWidth < 480) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    summary,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (clearBtn != null) ...[
                          Expanded(child: clearBtn),
                          const SizedBox(width: 8),
                        ],
                        Expanded(flex: 2, child: payBtn),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: summary),
                  if (clearBtn != null) ...[clearBtn, const SizedBox(width: 4)],
                  payBtn,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Reusable: avatar, money, badges, table, filter pill, dialogs
// ===========================================================================

class _Avatar extends StatelessWidget {
  const _Avatar({required this.employee, required this.size});
  final DemoEmployee employee;
  final double size;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: taj.primary.lighter,
        alignment: Alignment.center,
        child: Text(employee.initial,
            style: AppThemes.numeralStyle(context,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
                color: taj.primary.dark)),
      ),
    );
  }
}

class _PayStatusBadge extends StatelessWidget {
  const _PayStatusBadge({required this.paid});
  final bool paid;
  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: paid ? 'مدفوع' : 'غير مدفوع',
      status: paid ? TajStatus.success : TajStatus.warning,
      icon: paid ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
    );
  }
}

/// A monetary figure: tabular Almarai digits, compact past a length threshold,
/// exact value in a tooltip, never truncated.
class _Money extends StatelessWidget {
  const _Money({
    required this.value,
    required this.fontSize,
    this.fontWeight = FontWeight.w600,
    this.color,
    this.maxLines = 1,
    this.maxChars = 16,
  });
  final double value;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final int maxLines;
  final int maxChars;
  @override
  Widget build(BuildContext context) {
    final display = arDinarFit(value.abs(), maxChars: maxChars);
    final sign = value < 0 ? '−' : '';
    return Tooltip(
      message: arDinar(value),
      child: Text(
        '$sign$display',
        maxLines: maxLines,
        softWrap: maxLines > 1,
        overflow: maxLines > 1 ? TextOverflow.clip : TextOverflow.ellipsis,
        style: AppThemes.numeralStyle(context,
            fontSize: fontSize, fontWeight: fontWeight, color: color),
      ),
    );
  }
}

class _FinCol {
  const _FinCol(this.label, this.width, {this.numeric = false});
  final String label;
  final double width;
  final bool numeric;
}

class _FinRow {
  const _FinRow({
    required this.frozen,
    required this.cells,
    this.onTap,
    this.selected = false,
  });
  final Widget frozen;
  final List<Widget> cells;
  final VoidCallback? onTap;
  final bool selected;
}

/// Frozen first column + sticky header + horizontal scroll for the rest.
/// Expects a bounded height (place in an `Expanded`). No column is ever hidden;
/// off-screen columns are always reachable by horizontal scroll.
class _FinTable extends StatefulWidget {
  const _FinTable({
    required this.frozenCol,
    required this.restCols,
    required this.rows,
  });
  final _FinCol frozenCol;
  final List<_FinCol> restCols;
  final List<_FinRow> rows;
  @override
  State<_FinTable> createState() => _FinTableState();
}

class _FinTableState extends State<_FinTable> {
  static const double _rowHeight = 56;
  static const double _headerHeight = 44;
  final _bodyH = ScrollController();
  final _headerH = ScrollController();

  @override
  void initState() {
    super.initState();
    _bodyH.addListener(() {
      if (_headerH.hasClients && _bodyH.hasClients) {
        final t = _bodyH.offset.clamp(0.0, _headerH.position.maxScrollExtent);
        if ((_headerH.offset - t).abs() > 0.5) _headerH.jumpTo(t);
      }
    });
  }

  @override
  void dispose() {
    _bodyH.dispose();
    _headerH.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final rawRest = widget.restCols.fold<double>(0, (s, c) => s + c.width);
    final frozenW = widget.frozenCol.width;

    return LayoutBuilder(
      builder: (context, c) {
        final viewport = c.maxWidth - frozenW;
        final slack = math.max(0.0, viewport - rawRest);
        final effWidths = [
          for (var i = 0; i < widget.restCols.length; i++)
            widget.restCols[i].width + (i == 0 ? slack : 0),
        ];
        final restWidth = rawRest + slack;

        Widget headerCell(_FinCol col) => Align(
              alignment: col.numeric
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Text(col.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                      color: taj.textSecondary, fontWeight: FontWeight.w600)),
            );

        final header = DecoratedBox(
          decoration: BoxDecoration(
            color: taj.paper,
            border: Border(bottom: BorderSide(color: taj.divider)),
          ),
          child: SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                SizedBox(
                  width: frozenW,
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: 12, end: 12),
                    child: headerCell(widget.frozenCol),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerH,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: restWidth,
                      child: Row(
                        children: [
                          for (var i = 0; i < widget.restCols.length; i++)
                            SizedBox(
                              width: effWidths[i],
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    end: 12),
                                child: headerCell(widget.restCols[i]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final body = SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: frozenW,
                child: Column(
                  children: [
                    for (final r in widget.rows)
                      _rowBox(
                        selected: r.selected,
                        onTap: r.onTap,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                              start: 12, end: 12),
                          child: r.frozen,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _bodyH,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: restWidth,
                    child: Column(
                      children: [
                        for (final r in widget.rows)
                          _rowBox(
                            selected: r.selected,
                            onTap: r.onTap,
                            child: Row(
                              children: [
                                for (var i = 0; i < widget.restCols.length; i++)
                                  SizedBox(
                                    width: effWidths[i],
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.only(
                                              end: 12),
                                      child: Align(
                                        alignment: widget.restCols[i].numeric
                                            ? AlignmentDirectional.centerEnd
                                            : AlignmentDirectional.centerStart,
                                        child: i < r.cells.length
                                            ? r.cells[i]
                                            : const SizedBox(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: taj.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: taj.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [header, Expanded(child: body)]),
        );
      },
    );
  }

  Widget _rowBox(
      {required Widget child, bool selected = false, VoidCallback? onTap}) {
    final taj = context.taj;
    final row = Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        color: selected ? taj.primary.lighter : Colors.transparent,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
    if (onTap == null) return row;
    return GestureDetector(
        onTap: onTap, behavior: HitTestBehavior.opaque, child: row);
  }
}

class _FilterPill<T> extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.value,
    required this.options,
    required this.onSelected,
  });
  final IconData icon;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final current =
        options.firstWhere((o) => o.$1 == value, orElse: () => options.first).$2;
    return PopupMenuButton<T>(
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem<T>(value: o.$1, child: Text(o.$2)),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: taj.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: taj.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: taj.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(current,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(color: taj.textPrimary)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded,
                size: 18, color: taj.textSecondary),
          ],
        ),
      ),
    );
  }
}

String _branchCity(DemoStore store, String branchId) => store.branches
    .firstWhere((b) => b.id == branchId,
        orElse: () => store.branches.isEmpty
            ? const DemoBranch(id: '', name: '—', city: '—')
            : store.branches.first)
    .city;

String _fmtDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

String _monthLabel(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

Future<T?> _empDialog<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext, StateSetter) body,
  required List<Widget> Function(BuildContext) actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      final phone = size.width < AppBreakpoints.phone;
      final dialogW = phone
          ? size.width
          : math.min(AppBreakpoints.employeeFormMaxWidth, size.width - 48);
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final taj = ctx.taj;
          final insets = MediaQuery.viewInsetsOf(ctx).bottom;
          final maxH = (size.height - insets) * 0.92;
          return Dialog(
            insetPadding:
                EdgeInsets.symmetric(horizontal: phone ? 8 : 24, vertical: 24),
            backgroundColor: taj.paper,
            child: Padding(
              padding: EdgeInsets.only(bottom: insets),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: dialogW, maxHeight: maxH),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(20, 14, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(title,
                                  style: Theme.of(ctx).textTheme.titleLarge)),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: taj.divider),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: body(ctx, setLocal),
                      ),
                    ),
                    Divider(height: 1, color: taj.divider),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions(ctx),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showEmployeeDialog(BuildContext context, DemoStore store,
    {DemoEmployee? edit}) async {
  final name = TextEditingController(text: edit?.name ?? '');
  final title = TextEditingController(text: edit?.title ?? '');
  final phone = TextEditingController(text: edit?.phone ?? '');
  final base = TextEditingController(text: _init(edit?.baseSalary));
  final allowances = TextEditingController(text: _init(edit?.allowances));
  final bonuses = TextEditingController(text: _init(edit?.bonuses));
  final commissions = TextEditingController(text: _init(edit?.commissions));
  final overtime = TextEditingController(text: _init(edit?.overtime));
  final deductions = TextEditingController(text: _init(edit?.deductions));
  String branchId = edit?.branchId ??
      (store.branches.isNotEmpty ? store.branches.first.id : 'b1');

  await _empDialog<void>(
    context,
    title: edit == null ? 'موظف جديد' : 'تعديل الموظف',
    body: (ctx, setLocal) {
      final twoCol = MediaQuery.sizeOf(ctx).width >= AppBreakpoints.phone;
      Widget field(String label, TextEditingController c,
              {bool number = false}) =>
          _LabeledField(
            label: label,
            child: TextField(
              controller: c,
              keyboardType: number
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : null,
              style: number ? AppThemes.numeralStyle(ctx, fontSize: 15) : null,
              decoration: InputDecoration(
                  isDense: true, suffixText: number ? 'د.ل' : null),
            ),
          );
      Widget pair(Widget a, Widget b) => twoCol
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b)
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              a,
              const SizedBox(height: 12),
              b
            ]);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pair(field('الاسم', name), field('المسمى الوظيفي', title)),
          const SizedBox(height: 12),
          pair(
            _LabeledField(
              label: 'الفرع',
              child: DropdownButtonFormField<String>(
                value: branchId,
                isExpanded: true,
                items: [
                  for (final b in store.branches)
                    DropdownMenuItem(value: b.id, child: Text(b.city)),
                ],
                onChanged: (v) => setLocal(() => branchId = v ?? branchId),
              ),
            ),
            field('الهاتف', phone),
          ),
          const SizedBox(height: 12),
          pair(field('الراتب الأساسي', base, number: true),
              field('البدلات', allowances, number: true)),
          const SizedBox(height: 12),
          pair(field('المكافآت', bonuses, number: true),
              field('العمولات', commissions, number: true)),
          const SizedBox(height: 12),
          pair(field('الوقت الإضافي', overtime, number: true),
              field('الاستقطاعات', deductions, number: true)),
        ],
      );
    },
    actions: (ctx) => [
      TextButton(
          onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(ctx);
          final navigator = Navigator.of(ctx);
          double p(TextEditingController c) =>
              double.tryParse(c.text.trim()) ?? 0;
          if (name.text.trim().isEmpty) {
            messenger.showSnackBar(const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('الاسم مطلوب')));
            return;
          }
          if (edit == null) {
            await store.addEmployee(DemoEmployee(
              id: store.nextEmployeeId,
              name: name.text.trim(),
              title: title.text.trim(),
              branchId: branchId,
              hireDate: DateTime.now(),
              phone: phone.text.trim(),
              baseSalary: p(base),
              allowances: p(allowances),
              bonuses: p(bonuses),
              commissions: p(commissions),
              overtime: p(overtime),
              deductions: p(deductions),
            ));
          } else {
            await store.updateEmployee(edit.copyWith(
              name: name.text.trim(),
              title: title.text.trim(),
              branchId: branchId,
              phone: phone.text.trim(),
              baseSalary: p(base),
              allowances: p(allowances),
              bonuses: p(bonuses),
              commissions: p(commissions),
              overtime: p(overtime),
              deductions: p(deductions),
            ));
          }
          navigator.pop();
        },
        child: const Text('حفظ'),
      ),
    ],
  );

  for (final c in [
    name, title, phone, base, allowances, bonuses, commissions, overtime,
    deductions
  ]) {
    c.dispose();
  }
}

String _init(double? v) => (v == null || v == 0) ? '' : arNum(v);

Future<void> showPayrollTxnDialog(BuildContext context, DemoStore store,
    String employeeId, DemoPayrollTxnType type) async {
  final amount = TextEditingController();
  final note = TextEditingController();
  final label = type == DemoPayrollTxnType.advance ? 'سلفة' : 'سحب';
  await _empDialog<void>(
    context,
    title: 'إضافة $label',
    body: (ctx, setLocal) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledField(
          label: 'المبلغ',
          child: TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppThemes.numeralStyle(ctx, fontSize: 16),
            decoration: const InputDecoration(hintText: '0', suffixText: 'د.ل'),
          ),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'ملاحظة (اختياري)',
          child: TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(hintText: '…')),
        ),
      ],
    ),
    actions: (ctx) => [
      TextButton(
          onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(ctx);
          final navigator = Navigator.of(ctx);
          final amt = double.tryParse(amount.text.trim()) ?? 0;
          if (amt <= 0) {
            messenger.showSnackBar(const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('المبلغ غير صالح')));
            return;
          }
          await store.addPayrollTxn(DemoPayrollTxn(
            id: 'PT-${DateTime.now().microsecondsSinceEpoch}',
            employeeId: employeeId,
            type: type,
            amount: amt,
            date: DateTime.now(),
            note: note.text.trim(),
          ));
          navigator.pop();
        },
        child: const Text('حفظ'),
      ),
    ],
  );
  amount.dispose();
  note.dispose();
}

Future<void> showPaySalaryDialog(
    BuildContext context, DemoStore store, String employeeId) async {
  final e = store.employeeById(employeeId);
  if (e == null) return;
  await _empDialog<void>(
    context,
    title: 'دفع الراتب',
    body: (ctx, setLocal) {
      final net = store.employeeNet(employeeId);
      final taj = ctx.taj;
      final text = Theme.of(ctx).textTheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('سيتم تسجيل مصروف راتب مرتبط بالموظف:',
              style: text.bodyMedium),
          const SizedBox(height: 6),
          Text(e.name,
              style: text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: taj.primary.lighter,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text('صافي الراتب',
                        style:
                            text.titleMedium?.copyWith(color: taj.primary.dark))),
                _Money(
                    value: net,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    maxLines: 2,
                    color: taj.primary.dark),
              ],
            ),
          ),
        ],
      );
    },
    actions: (ctx) => [
      TextButton(
          onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(ctx);
          final navigator = Navigator.of(ctx);
          final success = ctx.taj.success.dark;
          await store.paySalary(employeeId);
          navigator.pop();
          messenger.showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: success,
            content: const Text('تم دفع الراتب'),
          ));
        },
        child: const Text('تأكيد الدفع'),
      ),
    ],
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        child,
      ],
    );
  }
}
