import 'package:flutter/material.dart';

import '../../core/demo/demo_provider.dart';
import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_filters.dart';
import '../../shared/widgets/taj_table.dart';
import '../../shared/widgets/taj_ui.dart';

/// POS Management module — the control tower for the whole point-of-sale
/// operation. Not a sales page: it monitors and manages the hierarchy
/// **Company → Branches → Terminals → Cashiers → Shifts → Sales → Cash**.
///
/// Sections: live overview, terminals, cashiers, shifts + reconciliation,
/// branch performance, cashier performance and reports. Everything reads off
/// the mock model at the bottom of this file so branches/terminals/cashiers can
/// grow without touching the UI.
class PosManagementScreen extends StatefulWidget {
  const PosManagementScreen({super.key, this.branchId});

  final String? branchId;

  @override
  State<PosManagementScreen> createState() => _PosManagementScreenState();
}

class _PosManagementScreenState extends State<PosManagementScreen> {
  _Section _section = _Section.overview;
  _Period _period = _Period.today;
  String? _branchId; // null → all branches

  @override
  void initState() {
    super.initState();
    _branchId = widget.branchId;
  }

  @override
  void didUpdateWidget(covariant PosManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.branchId != oldWidget.branchId) {
      _branchId = widget.branchId;
    }
  }

  List<_Terminal> get _terminalsInScope =>
      _branchId == null
          ? _mockTerminals
          : _mockTerminals.where((t) => t.branchId == _branchId).toList();

  List<_Branch> get _branchesInScope =>
      _branchId == null
          ? _mockBranches
          : _mockBranches.where((b) => b.id == _branchId).toList();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final pad = pagePaddingForWidth(c.maxWidth);
        final terminals = _terminalsInScope;

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header + global filters
              Padding(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, 12),
                child: SectionHeading(
                  title: 'إدارة نقاط البيع',
                  subtitle: 'مراقبة الفروع والأجهزة والكاشيرين والورديات',
                  trailing: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PickerPill<String?>(
                        icon: Icons.store_mall_directory_outlined,
                        value: _branchId,
                        items: [null, for (final b in _mockBranches) b.id],
                        labelOf:
                            (id) =>
                                id == null
                                    ? 'كل الفروع'
                                    : _mockBranches
                                        .firstWhere((b) => b.id == id)
                                        .name,
                        onChanged: (v) => setState(() => _branchId = v),
                      ),
                      _PickerPill<_Period>(
                        icon: Icons.calendar_today_outlined,
                        value: _period,
                        items: _Period.values,
                        labelOf: (p) => p.label,
                        onChanged: (v) => setState(() => _period = v),
                      ),
                    ],
                  ),
                ),
              ),

              // Section sub-navigation
              _SectionTabs(
                selected: _section,
                onSelect: (s) => setState(() => _section = s),
              ),
              Divider(height: 1, color: context.taj.divider),

              // Section body
              Expanded(child: _buildSection(context, terminals, pad)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    List<_Terminal> terminals,
    double pad,
  ) {
    switch (_section) {
      case _Section.overview:
        return _OverviewSection(
          terminals: terminals,
          branches: _branchesInScope,
          period: _period,
          pad: pad,
        );
      case _Section.terminals:
        return _TerminalsSection(terminals: terminals, pad: pad);
      case _Section.cashiers:
        return _CashiersSection(terminals: terminals, pad: pad);
      case _Section.shifts:
        return _ShiftsSection(terminals: terminals, pad: pad);
      case _Section.branches:
        return _BranchesSection(branches: _branchesInScope, pad: pad);
      case _Section.performance:
        return _PerformanceSection(terminals: terminals, pad: pad);
      case _Section.reports:
        return _ReportsSection(period: _period, terminals: terminals, pad: pad);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section sub-navigation
// ─────────────────────────────────────────────────────────────────────────────

enum _Section {
  overview('نظرة عامة', Icons.dashboard_outlined),
  terminals('الأجهزة', Icons.point_of_sale_outlined),
  cashiers('الكاشيرون', Icons.badge_outlined),
  shifts('الورديات', Icons.schedule_outlined),
  branches('الفروع', Icons.store_mall_directory_outlined),
  performance('الأداء', Icons.leaderboard_outlined),
  reports('التقارير', Icons.summarize_outlined);

  const _Section(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.selected, required this.onSelect});
  final _Section selected;
  final ValueChanged<_Section> onSelect;

  @override
  Widget build(BuildContext context) {
    // A Row inside a horizontal scroll view (rather than a lazy ListView) so
    // every tab is always built — it stays reachable when scrolled off-screen
    // on narrow widths, and scrolls sideways when the row is wider than the pane.
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            for (final s in _Section.values) ...[
              if (s != _Section.values.first) const SizedBox(width: 6),
              _SectionTab(
                section: s,
                selected: s == selected,
                onTap: () => onSelect(s),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _Section section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final sel = selected;
    return Material(
      color: sel ? taj.primary.lighter : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        hoverColor: taj.hover,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: sel ? taj.primary.main : taj.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                section.icon,
                size: 16,
                color: sel ? taj.primary.dark : taj.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                section.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: sel ? taj.primary.dark : taj.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1) Overview — KPIs + live terminal board
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.terminals,
    required this.branches,
    required this.period,
    required this.pad,
  });

  final List<_Terminal> terminals;
  final List<_Branch> branches;
  final _Period period;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final demo = DemoStoreProvider.of(context);
    final agg = _Agg.of(terminals);
    final stats = period.scale(agg);
    final scopedSales = branches.fold<double>(
      0,
      (sum, branch) => sum + demo.salesForBranch(branch.id),
    );

    final active = terminals.where((t) => t.status == PosStatus.active).length;
    final offline =
        terminals.where((t) => t.status == PosStatus.offline).length;
    final onBreak =
        terminals.where((t) => t.status == PosStatus.onBreak).length;
    final openShifts = terminals.where((t) => t.shiftOpen).length;

    final tiles = <Widget>[
      _StatTile(
        icon: Icons.store_mall_directory_outlined,
        label: 'الفروع',
        value: arNum(
          demo.branches.isEmpty ? branches.length : demo.branches.length,
        ),
        swatch: taj.info,
      ),
      _StatTile(
        icon: Icons.point_of_sale_outlined,
        label: 'أجهزة نقاط البيع',
        value: arNum(terminals.length),
        swatch: taj.primary,
      ),
      _StatTile(
        icon: Icons.person_pin_circle_outlined,
        label: 'كاشيرون نشطون',
        value: arNum(active),
        swatch: taj.success,
      ),
      _StatTile(
        icon: Icons.cloud_off_outlined,
        label: 'غير متصل',
        value: arNum(offline),
        swatch: taj.neutral,
      ),
      _StatTile(
        icon: Icons.free_breakfast_outlined,
        label: 'في استراحة',
        value: arNum(onBreak),
        swatch: taj.warning,
      ),
      _StatTile(
        icon: Icons.lock_clock_outlined,
        label: 'ورديات مفتوحة',
        value: arNum(openShifts),
        swatch: taj.info,
      ),
      _StatTile(
        icon: Icons.payments_outlined,
        label: 'مبيعات ${period.label}',
        value: arDinar(
          scopedSales == 0 ? stats.totalSales : scopedSales * period.factor,
        ),
        swatch: taj.primary,
        emphasize: true,
      ),
      _StatTile(
        icon: Icons.receipt_long_outlined,
        label: 'عدد الفواتير',
        value: arNum(stats.invoices),
        swatch: taj.primary,
      ),
      _StatTile(
        icon: Icons.assignment_return_outlined,
        label: 'المرتجعات',
        value: arDinar(stats.returns),
        swatch: taj.error,
      ),
      _StatTile(
        icon: Icons.percent_rounded,
        label: 'الخصومات',
        value: arDinar(stats.discounts),
        swatch: taj.warning,
      ),
      _StatTile(
        icon: Icons.account_balance_wallet_outlined,
        label: 'النقد في الأدراج',
        value: arDinar(agg.cashInDrawers),
        swatch: taj.success,
        emphasize: true,
      ),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      children: [
        _CardGrid(minItemWidth: 190, children: tiles),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.sensors_rounded, size: 18, color: taj.success.main),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'الحالة المباشرة للأجهزة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Status legend — a reflowing row so it never overflows on phones.
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            for (final s in PosStatus.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusDot(status: s),
                  const SizedBox(width: 5),
                  Text(
                    _statusVisual(context, s).label,
                    style: TextStyle(fontSize: 11, color: taj.textSecondary),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        _CardGrid(
          minItemWidth: 230,
          children: [
            for (final t in terminals) _TerminalStatusCard(terminal: t),
          ],
        ),
      ],
    );
  }
}

class _TerminalStatusCard extends StatelessWidget {
  const _TerminalStatusCard({required this.terminal});
  final _Terminal terminal;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return TajCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showTerminalSheet(context, terminal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusDot(status: terminal.status),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  terminal.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.numeralStyle(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _PosStatusBadge(terminal.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 15,
                color: taj.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  terminal.cashier,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.store_outlined, size: 15, color: taj.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  terminal.branchName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: taj.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: taj.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'المبيعات',
                  value: arDinar(terminal.totalSales),
                  color: taj.accentText,
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'الفواتير',
                  value: arNum(terminal.invoices),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: taj.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppThemes.numeralStyle(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2) Terminals
// ─────────────────────────────────────────────────────────────────────────────

class _TerminalsSection extends StatelessWidget {
  const _TerminalsSection({required this.terminals, required this.pad});
  final List<_Terminal> terminals;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'أجهزة نقاط البيع (${arNum(terminals.length)})',
                style: text.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _toast(context, 'إضافة جهاز جديد'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة جهاز'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TajCard(
          padding: EdgeInsets.zero,
          child: TajTable(
            minWidth: 760,
            columns: const [
              TajColumn('الجهاز', flex: 3),
              TajColumn('الفرع', flex: 3),
              TajColumn('الكاشير', flex: 3),
              TajColumn('الحالة', flex: 2),
              TajColumn('آخر نشاط', flex: 2),
              TajColumn('المبيعات', flex: 2, numeric: true),
              TajColumn('الفواتير', flex: 2, numeric: true),
            ],
            rows: [
              for (final t in terminals)
                TajRowData(
                  onTap: () => _showTerminalSheet(context, t),
                  actions: [_TerminalMenu(terminal: t)],
                  cells: [
                    Row(
                      children: [
                        _StatusDot(status: t.status),
                        const SizedBox(width: 8),
                        Text(
                          t.id,
                          style: AppThemes.numeralStyle(
                            context,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(t.branchName, style: text.bodyMedium),
                    Text(t.cashier, style: text.bodyMedium),
                    _PosStatusBadge(t.status),
                    Text(
                      t.lastActivity,
                      style: text.bodySmall?.copyWith(color: taj.textSecondary),
                    ),
                    Text(
                      arDinar(t.totalSales),
                      style: AppThemes.numeralStyle(context, fontSize: 13),
                    ),
                    Text(
                      arNum(t.invoices),
                      style: AppThemes.numeralStyle(context, fontSize: 13),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TerminalMenu extends StatelessWidget {
  const _TerminalMenu({required this.terminal});
  final _Terminal terminal;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'إجراءات',
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 18,
        color: context.taj.textSecondary,
      ),
      onSelected: (v) => _toast(context, '$v — ${terminal.id}'),
      itemBuilder:
          (_) => const [
            PopupMenuItem(value: 'تعديل الجهاز', child: Text('تعديل الجهاز')),
            PopupMenuItem(value: 'تعيين كاشير', child: Text('تعيين كاشير')),
            PopupMenuItem(
              value: 'نقل إلى فرع آخر',
              child: Text('نقل إلى فرع آخر'),
            ),
            PopupMenuItem(value: 'سجل الجهاز', child: Text('سجل الجهاز')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'تعطيل الجهاز', child: Text('تعطيل الجهاز')),
          ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3) Cashiers
// ─────────────────────────────────────────────────────────────────────────────

class _CashiersSection extends StatelessWidget {
  const _CashiersSection({required this.terminals, required this.pad});
  final List<_Terminal> terminals;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      children: [
        Text('أداء الكاشيرين اليوم', style: text.titleMedium),
        const SizedBox(height: 14),
        TajCard(
          padding: EdgeInsets.zero,
          child: TajTable(
            minWidth: 1080,
            columns: const [
              TajColumn('الكاشير', flex: 3),
              TajColumn('الجهاز', flex: 2),
              TajColumn('الحالة', flex: 2),
              TajColumn('الدخول', flex: 2),
              TajColumn('الفواتير', flex: 2, numeric: true),
              TajColumn('المرتجعات', flex: 2, numeric: true),
              TajColumn('نقدي', flex: 2, numeric: true),
              TajColumn('بطاقة', flex: 2, numeric: true),
              TajColumn('الإجمالي', flex: 2, numeric: true),
            ],
            rows: [
              for (final t in terminals)
                TajRowData(
                  onTap: () => _showTerminalSheet(context, t),
                  cells: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: taj.primary.lighter,
                          child: Text(
                            t.cashier.characters.first,
                            style: TextStyle(
                              color: taj.primary.dark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t.cashier,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      t.id,
                      style: AppThemes.numeralStyle(context, fontSize: 13),
                    ),
                    _PosStatusBadge(t.status),
                    Text(
                      t.loginTime,
                      style: text.bodySmall?.copyWith(color: taj.textSecondary),
                    ),
                    Text(
                      arNum(t.invoices),
                      style: AppThemes.numeralStyle(context, fontSize: 13),
                    ),
                    Text(
                      arDinar(t.returnsAmt),
                      style: AppThemes.numeralStyle(
                        context,
                        fontSize: 13,
                        color: taj.error.main,
                      ),
                    ),
                    Text(
                      arDinar(t.cashSales),
                      style: AppThemes.numeralStyle(context, fontSize: 13),
                    ),
                    Text(
                      arDinar(t.cardSales),
                      style: AppThemes.numeralStyle(context, fontSize: 13),
                    ),
                    Text(
                      arDinar(t.totalSales),
                      style: AppThemes.numeralStyle(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: taj.accentText,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4) Shifts + cash reconciliation
// ─────────────────────────────────────────────────────────────────────────────

class _ShiftsSection extends StatelessWidget {
  const _ShiftsSection({required this.terminals, required this.pad});
  final List<_Terminal> terminals;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final open = terminals.where((t) => t.shiftOpen).toList();
    final closed = terminals.where((t) => !t.shiftOpen).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'الورديات المفتوحة (${arNum(open.length)})',
                style: text.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _toast(context, 'فتح وردية جديدة'),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text('فتح وردية'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _CardGrid(
          minItemWidth: 320,
          children: [for (final t in open) _ShiftCard(terminal: t)],
        ),
        const SizedBox(height: 24),
        Text('ورديات مُقفلة — التسوية النقدية', style: text.titleMedium),
        const SizedBox(height: 14),
        _CardGrid(
          minItemWidth: 320,
          children: [for (final t in closed) _ShiftCard(terminal: t)],
        ),
      ],
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.terminal});
  final _Terminal terminal;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final t = terminal;
    final expected = t.expectedCash;
    final diff = t.shiftOpen ? null : (t.actualCash - expected);

    return TajCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusDot(status: t.status),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.cashier,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${t.id} • ${t.branchName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: taj.textSecondary),
                    ),
                  ],
                ),
              ),
              _ShiftStateBadge(open: t.shiftOpen),
            ],
          ),
          const SizedBox(height: 12),
          _KvRow(label: 'رصيد الافتتاح', value: arDinar(t.openingCash)),
          _KvRow(label: 'مبيعات نقدية', value: arDinar(t.cashSales)),
          _KvRow(
            label: 'بطاقة / أخرى',
            value: arDinar(t.cardSales + t.otherSales),
          ),
          _KvRow(label: 'سحوبات', value: '- ${arDinar(t.withdrawals)}'),
          _KvRow(label: 'مصروفات', value: '- ${arDinar(t.expenses)}'),
          const SizedBox(height: 6),
          Divider(height: 1, color: taj.divider),
          const SizedBox(height: 8),
          _KvRow(
            label: 'النقد المتوقع',
            value: arDinar(expected),
            strong: true,
          ),
          if (!t.shiftOpen) ...[
            _KvRow(
              label: 'النقد الفعلي',
              value: arDinar(t.actualCash),
              strong: true,
            ),
            const SizedBox(height: 10),
            _ReconciliationChip(difference: diff!),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _toast(context, 'إغلاق وردية ${t.id}'),
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: const Text('إغلاق الوردية والتسوية'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShiftStateBadge extends StatelessWidget {
  const _ShiftStateBadge({required this.open});
  final bool open;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final s = open ? taj.success : taj.neutral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: s.lighter,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        open ? 'مفتوحة' : 'مقفلة',
        style: TextStyle(
          color: s.dark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReconciliationChip extends StatelessWidget {
  const _ReconciliationChip({required this.difference});
  final double difference;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final (swatch, label, icon) =
        difference == 0
            ? (taj.success, 'لا يوجد فرق', Icons.check_circle_outline_rounded)
            : difference < 0
            ? (taj.error, 'عجز نقدي', Icons.trending_down_rounded)
            : (taj.warning, 'فائض نقدي', Icons.trending_up_rounded);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: swatch.lighter,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: swatch.dark),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: swatch.dark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            difference == 0 ? '—' : arDinar(difference.abs()),
            style: AppThemes.numeralStyle(
              context,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: swatch.dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  strong
                      ? text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
                      : text.bodySmall?.copyWith(color: taj.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppThemes.numeralStyle(
              context,
              fontSize: strong ? 15 : 13,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5) Branch performance
// ─────────────────────────────────────────────────────────────────────────────

class _BranchesSection extends StatelessWidget {
  const _BranchesSection({required this.branches, required this.pad});
  final List<_Branch> branches;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows = [
      for (final b in branches)
        (
          branch: b,
          agg: _Agg.of(
            _mockTerminals.where((t) => t.branchId == b.id).toList(),
          ),
        ),
    ]..sort((a, b) => b.agg.totalSales.compareTo(a.agg.totalSales));
    final maxSales =
        rows.isEmpty
            ? 1.0
            : rows.map((r) => r.agg.totalSales).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      children: [
        Text('أداء الفروع', style: text.titleMedium),
        const SizedBox(height: 14),
        _CardGrid(
          minItemWidth: 300,
          children: [
            for (final r in rows)
              _BranchCard(
                branch: r.branch,
                agg: r.agg,
                share: maxSales == 0 ? 0 : r.agg.totalSales / maxSales,
              ),
          ],
        ),
      ],
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.agg,
    required this.share,
  });
  final _Branch branch;
  final _Agg agg;
  final double share;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final terminals =
        _mockTerminals.where((t) => t.branchId == branch.id).toList();
    final active = terminals.where((t) => t.status == PosStatus.active).length;

    return TajCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: taj.primary.lighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.store_rounded,
                  size: 20,
                  color: taj.primary.dark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      branch.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    Text(
                      '${arNum(terminals.length)} أجهزة • ${arNum(active)} نشط',
                      style: text.bodySmall?.copyWith(color: taj.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            arDinar(agg.totalSales),
            style: AppThemes.numeralStyle(
              context,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'صافي: ${arDinar(agg.netSales)}',
            style: text.bodySmall?.copyWith(color: taj.textSecondary),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share.clamp(0, 1),
              minHeight: 6,
              backgroundColor: taj.primary.lighter,
              valueColor: AlwaysStoppedAnimation(taj.primary.main),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _InlineStat(label: 'الفواتير', value: arNum(agg.invoices)),
              _InlineStat(label: 'م. الفاتورة', value: arDinar(agg.avgInvoice)),
              _InlineStat(label: 'المرتجعات', value: arDinar(agg.returns)),
              _InlineStat(label: 'الخصومات', value: arDinar(agg.discounts)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: taj.textSecondary)),
        const SizedBox(height: 1),
        Text(
          value,
          style: AppThemes.numeralStyle(
            context,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6) Cashier performance — highlights + ranked comparison
// ─────────────────────────────────────────────────────────────────────────────

class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection({required this.terminals, required this.pad});
  final List<_Terminal> terminals;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    final ranked = [...terminals]
      ..sort((a, b) => b.totalSales.compareTo(a.totalSales));
    if (ranked.isEmpty) {
      return const TajEmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'لا توجد بيانات أداء',
        message: 'اختر فرعًا يحتوي على أجهزة.',
      );
    }
    final maxSales =
        ranked.first.totalSales == 0 ? 1.0 : ranked.first.totalSales;
    final topSales = ranked.first;
    final lowSales = ranked.last;
    final mostTxns = [...terminals]
      ..sort((a, b) => b.invoices.compareTo(a.invoices));
    final bestPerHour = [...terminals]
      ..sort((a, b) => b.salesPerHour.compareTo(a.salesPerHour));

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      children: [
        Text('لوحة الأبطال', style: text.titleMedium),
        const SizedBox(height: 14),
        _CardGrid(
          minItemWidth: 220,
          children: [
            _HighlightCard(
              icon: Icons.emoji_events_outlined,
              swatch: taj.success,
              title: 'الأعلى مبيعًا',
              name: topSales.cashier,
              value: arDinar(topSales.totalSales),
            ),
            _HighlightCard(
              icon: Icons.bolt_outlined,
              swatch: taj.info,
              title: 'الأكثر معاملات',
              name: mostTxns.first.cashier,
              value: '${arNum(mostTxns.first.invoices)} فاتورة',
            ),
            _HighlightCard(
              icon: Icons.speed_outlined,
              swatch: taj.primary,
              title: 'الأعلى بيعًا/ساعة',
              name: bestPerHour.first.cashier,
              value: arDinar(bestPerHour.first.salesPerHour),
            ),
            _HighlightCard(
              icon: Icons.trending_down_rounded,
              swatch: taj.warning,
              title: 'الأقل مبيعًا',
              name: lowSales.cashier,
              value: arDinar(lowSales.totalSales),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('مقارنة الكاشيرين', style: text.titleMedium),
        const SizedBox(height: 14),
        TajCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              for (var i = 0; i < ranked.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _RankRow(
                  rank: i + 1,
                  terminal: ranked[i],
                  share: maxSales == 0 ? 0 : ranked[i].totalSales / maxSales,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.swatch,
    required this.title,
    required this.name,
    required this.value,
  });
  final IconData icon;
  final TajSwatch swatch;
  final String title;
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return TajCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: swatch.lighter,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: swatch.dark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: taj.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.numeralStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: taj.accentFor(swatch),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.terminal,
    required this.share,
  });
  final int rank;
  final _Terminal terminal;
  final double share;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final t = terminal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank <= 3 ? taj.primary.lighter : taj.background,
            shape: BoxShape.circle,
          ),
          child: Text(
            arNum(rank),
            style: AppThemes.numeralStyle(
              context,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: rank <= 3 ? taj.primary.dark : taj.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.cashier,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    arDinar(t.totalSales),
                    style: AppThemes.numeralStyle(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: share.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: taj.background,
                  valueColor: AlwaysStoppedAnimation(taj.primary.main),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _InlineStat(label: 'معاملات', value: arNum(t.invoices)),
                  _InlineStat(
                    label: 'م. المعاملة',
                    value: arDinar(t.avgInvoice),
                  ),
                  _InlineStat(label: 'مرتجعات', value: arDinar(t.returnsAmt)),
                  _InlineStat(label: 'ساعات', value: arNum(t.hoursWorked)),
                  _InlineStat(
                    label: 'بيع/ساعة',
                    value: arDinar(t.salesPerHour),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7) Reports
// ─────────────────────────────────────────────────────────────────────────────

class _ReportsSection extends StatefulWidget {
  const _ReportsSection({
    required this.period,
    required this.terminals,
    required this.pad,
  });
  final _Period period;
  final List<_Terminal> terminals;
  final double pad;

  @override
  State<_ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<_ReportsSection> {
  final List<TajFilter> _filters = [];

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final stats = widget.period.scale(_Agg.of(widget.terminals));

    const reports = [
      ('مبيعات الكاشيرين', Icons.badge_outlined),
      ('مبيعات الأجهزة', Icons.point_of_sale_outlined),
      ('مبيعات الفروع', Icons.store_outlined),
      ('المبيعات اليومية', Icons.today_outlined),
      ('تقارير الورديات', Icons.schedule_outlined),
      ('التسوية النقدية', Icons.account_balance_wallet_outlined),
      ('المرتجعات', Icons.assignment_return_outlined),
      ('طرق الدفع', Icons.credit_card_outlined),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(widget.pad, 16, widget.pad, 24),
      children: [
        Text('مكتبة التقارير', style: text.titleMedium),
        const SizedBox(height: 14),
        _CardGrid(
          minItemWidth: 210,
          children: [
            for (final (title, icon) in reports)
              TajCard(
                padding: const EdgeInsets.all(16),
                onTap: () => _toast(context, 'فتح تقرير: $title'),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: taj.primary.lighter,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 20, color: taj.primary.dark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        TajCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'تقرير المبيعات — ${widget.period.label}',
                      style: text.titleMedium,
                    ),
                  ),
                  _ExportButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    onTap: () => _toast(context, 'تصدير PDF'),
                  ),
                  const SizedBox(width: 8),
                  _ExportButton(
                    icon: Icons.grid_on_outlined,
                    label: 'Excel',
                    onTap: () => _toast(context, 'تصدير Excel'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TajFilterBar(
                filters: _filters,
                onAdd:
                    () => setState(
                      () => _filters.add(
                        const TajFilter(
                          field: 'طريقة الدفع',
                          operator: 'هي',
                          value: 'نقدي',
                        ),
                      ),
                    ),
                onRemove: (i) => setState(() => _filters.removeAt(i)),
                onClearAll: () => setState(_filters.clear),
                onGroupBy: () => _toast(context, 'تجميع'),
                onSortBy: () => _toast(context, 'ترتيب'),
              ),
              const SizedBox(height: 14),
              _CardGrid(
                minItemWidth: 170,
                gap: 12,
                children: [
                  _SummaryStat(
                    label: 'إجمالي المبيعات',
                    value: arDinar(stats.totalSales),
                  ),
                  _SummaryStat(
                    label: 'صافي المبيعات',
                    value: arDinar(stats.netSales),
                  ),
                  _SummaryStat(label: 'الفواتير', value: arNum(stats.invoices)),
                  _SummaryStat(
                    label: 'متوسط الفاتورة',
                    value: arDinar(stats.avgInvoice),
                  ),
                  _SummaryStat(label: 'نقدي', value: arDinar(stats.cashSales)),
                  _SummaryStat(label: 'بطاقة', value: arDinar(stats.cardSales)),
                  _SummaryStat(
                    label: 'طرق أخرى',
                    value: arDinar(stats.otherSales),
                  ),
                  _SummaryStat(label: 'العملاء', value: arNum(stats.customers)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taj.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: taj.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.numeralStyle(
              context,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared building blocks
// ─────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.swatch,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final TajSwatch swatch;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: emphasize ? swatch.main : taj.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: swatch.lighter,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: taj.accentFor(swatch)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: taj.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.numeralStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// A responsive equal-width grid built on [Wrap] + [gridColumnsFor].
class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.children,
    this.minItemWidth = 200,
    this.gap = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) {
        final cols = gridColumnsFor(
          c.maxWidth,
          minItemWidth: minItemWidth,
          spacing: gap,
        );
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: w, child: child),
          ],
        );
      },
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final PosStatus status;
  @override
  Widget build(BuildContext context) {
    final v = _statusVisual(context, status);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: v.dot, shape: BoxShape.circle),
    );
  }
}

class _PosStatusBadge extends StatelessWidget {
  const _PosStatusBadge(this.status);
  final PosStatus status;
  @override
  Widget build(BuildContext context) {
    final v = _statusVisual(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: v.swatch.lighter,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        v.label,
        style: TextStyle(
          color: v.swatch.dark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PickerPill<T> extends StatelessWidget {
  const _PickerPill({
    required this.icon,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return PopupMenuButton<T>(
      tooltip: '',
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder:
          (_) => [
            for (final it in items)
              PopupMenuItem<T>(value: it, child: Text(labelOf(it))),
          ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: taj.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: taj.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: taj.textSecondary),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                labelOf(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: taj.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Status → colour + label, resolved against the active theme so it reads in
/// both light and dark. Offline maps to the neutral grey swatch.
({TajSwatch swatch, String label, Color dot}) _statusVisual(
  BuildContext context,
  PosStatus s,
) {
  final taj = context.taj;
  return switch (s) {
    PosStatus.active => (
      swatch: taj.success,
      label: 'نشط',
      dot: taj.success.main,
    ),
    PosStatus.offline => (
      swatch: taj.neutral,
      label: 'غير متصل',
      dot: taj.textDisabled,
    ),
    PosStatus.onBreak => (
      swatch: taj.warning,
      label: 'في استراحة',
      dot: taj.warning.main,
    ),
    PosStatus.closed => (swatch: taj.error, label: 'مغلق', dot: taj.error.main),
  };
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void _showTerminalSheet(BuildContext context, _Terminal t) {
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _TerminalDetailSheet(terminal: t),
  );
}

class _TerminalDetailSheet extends StatelessWidget {
  const _TerminalDetailSheet({required this.terminal});
  final _Terminal terminal;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final t = terminal;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder:
          (ctx, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: taj.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatusDot(status: t.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemes.numeralStyle(
                        context,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PosStatusBadge(t.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${t.cashier} • ${t.branchName}',
                style: text.bodyMedium?.copyWith(color: taj.textSecondary),
              ),
              const SizedBox(height: 20),
              _KvRow(label: 'وقت الدخول', value: t.loginTime),
              _KvRow(label: 'بداية الوردية', value: t.shiftStart),
              _KvRow(label: 'آخر نشاط', value: t.lastActivity),
              const Divider(height: 24),
              _KvRow(label: 'عدد الفواتير', value: arNum(t.invoices)),
              _KvRow(label: 'المرتجعات', value: arDinar(t.returnsAmt)),
              _KvRow(label: 'الخصومات', value: arDinar(t.discountsAmt)),
              const Divider(height: 24),
              _KvRow(label: 'مبيعات نقدية', value: arDinar(t.cashSales)),
              _KvRow(label: 'مبيعات بطاقة', value: arDinar(t.cardSales)),
              _KvRow(label: 'طرق دفع أخرى', value: arDinar(t.otherSales)),
              _KvRow(
                label: 'إجمالي المبيعات',
                value: arDinar(t.totalSales),
                strong: true,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Models & mock data
// ─────────────────────────────────────────────────────────────────────────────

/// Real-time terminal / cashier status. 🟢 active · ⚪ offline · 🟠 break · 🔴 closed
enum PosStatus { active, offline, onBreak, closed }

class _Branch {
  const _Branch(this.id, this.name, this.city);
  final String id;
  final String name;
  final String city;
}

class _Terminal {
  const _Terminal({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.cashier,
    required this.status,
    required this.shiftOpen,
    required this.loginTime,
    required this.shiftStart,
    required this.lastActivity,
    required this.invoices,
    required this.returnsAmt,
    required this.discountsAmt,
    required this.cashSales,
    required this.cardSales,
    required this.otherSales,
    required this.openingCash,
    required this.withdrawals,
    required this.expenses,
    required this.actualCash,
    required this.hoursWorked,
  });

  final String id;
  final String branchId;
  final String branchName;
  final String cashier;
  final PosStatus status;
  final bool shiftOpen;
  final String loginTime;
  final String shiftStart;
  final String lastActivity;
  final int invoices;
  final double returnsAmt;
  final double discountsAmt;
  final double cashSales;
  final double cardSales;
  final double otherSales;
  final double openingCash;
  final double withdrawals;
  final double expenses;
  final double actualCash;
  final double hoursWorked;

  double get totalSales => cashSales + cardSales + otherSales;
  double get netSales => totalSales - returnsAmt - discountsAmt;
  double get avgInvoice => invoices == 0 ? 0 : totalSales / invoices;
  double get expectedCash => openingCash + cashSales - withdrawals - expenses;
  double get salesPerHour => hoursWorked == 0 ? 0 : totalSales / hoursWorked;
}

/// Aggregated figures over a set of terminals (the day's base numbers).
class _Agg {
  const _Agg({
    required this.totalSales,
    required this.invoices,
    required this.returns,
    required this.discounts,
    required this.cashSales,
    required this.cardSales,
    required this.otherSales,
    required this.cashInDrawers,
    required this.customers,
  });

  final double totalSales;
  final int invoices;
  final double returns;
  final double discounts;
  final double cashSales;
  final double cardSales;
  final double otherSales;
  final double cashInDrawers;
  final int customers;

  double get netSales => totalSales - returns - discounts;
  double get avgInvoice => invoices == 0 ? 0 : totalSales / invoices;

  factory _Agg.of(List<_Terminal> ts) {
    double sales = 0,
        ret = 0,
        disc = 0,
        cash = 0,
        card = 0,
        other = 0,
        drawer = 0;
    int inv = 0;
    for (final t in ts) {
      sales += t.totalSales;
      ret += t.returnsAmt;
      disc += t.discountsAmt;
      cash += t.cashSales;
      card += t.cardSales;
      other += t.otherSales;
      inv += t.invoices;
      if (t.shiftOpen) drawer += t.expectedCash;
    }
    return _Agg(
      totalSales: sales,
      invoices: inv,
      returns: ret,
      discounts: disc,
      cashSales: cash,
      cardSales: card,
      otherSales: other,
      cashInDrawers: drawer,
      customers: (inv * 0.9).round(),
    );
  }
}

/// A scaled snapshot for a time period (mock: today's base × a factor).
class _PeriodStats {
  const _PeriodStats({
    required this.totalSales,
    required this.invoices,
    required this.returns,
    required this.discounts,
    required this.cashSales,
    required this.cardSales,
    required this.otherSales,
    required this.customers,
  });

  final double totalSales;
  final int invoices;
  final double returns;
  final double discounts;
  final double cashSales;
  final double cardSales;
  final double otherSales;
  final int customers;

  double get netSales => totalSales - returns - discounts;
  double get avgInvoice => invoices == 0 ? 0 : totalSales / invoices;
}

/// Time filters for sales analytics.
enum _Period {
  hour('هذه الساعة', 0.09),
  today('اليوم', 1),
  yesterday('أمس', 0.92),
  thisWeek('هذا الأسبوع', 5.7),
  lastWeek('الأسبوع الماضي', 6.1),
  thisMonth('هذا الشهر', 23),
  lastMonth('الشهر الماضي', 26),
  thisYear('هذا العام', 240),
  lastYear('العام الماضي', 205),
  custom('نطاق مخصص', 3.4);

  const _Period(this.label, this.factor);
  final String label;
  final double factor;

  _PeriodStats scale(_Agg a) => _PeriodStats(
    totalSales: a.totalSales * factor,
    invoices: (a.invoices * factor).round(),
    returns: a.returns * factor,
    discounts: a.discounts * factor,
    cashSales: a.cashSales * factor,
    cardSales: a.cardSales * factor,
    otherSales: a.otherSales * factor,
    customers: (a.customers * factor).round(),
  );
}

const _mockBranches = <_Branch>[
  _Branch('b1', 'طرابلس - المركز', 'طرابلس'),
  _Branch('b2', 'بنغازي - الفرع', 'بنغازي'),
  _Branch('b3', 'مصراتة - السوق', 'مصراتة'),
];

const _mockTerminals = <_Terminal>[
  // ── Branch 1 — طرابلس (4 terminals) ──
  _Terminal(
    id: 'POS-01',
    branchId: 'b1',
    branchName: 'طرابلس - المركز',
    cashier: 'أحمد الفيتوري',
    status: PosStatus.active,
    shiftOpen: true,
    loginTime: '8:05 ص',
    shiftStart: '8:00 ص',
    lastActivity: 'قبل 1 د',
    invoices: 48,
    returnsAmt: 120,
    discountsAmt: 85,
    cashSales: 4200,
    cardSales: 3100,
    otherSales: 900,
    openingCash: 500,
    withdrawals: 300,
    expenses: 150,
    actualCash: 0,
    hoursWorked: 6.5,
  ),
  _Terminal(
    id: 'POS-02',
    branchId: 'b1',
    branchName: 'طرابلس - المركز',
    cashier: 'سالم المبروك',
    status: PosStatus.active,
    shiftOpen: true,
    loginTime: '8:12 ص',
    shiftStart: '8:00 ص',
    lastActivity: 'قبل 3 د',
    invoices: 33,
    returnsAmt: 60,
    discountsAmt: 40,
    cashSales: 2800,
    cardSales: 2400,
    otherSales: 300,
    openingCash: 500,
    withdrawals: 0,
    expenses: 80,
    actualCash: 0,
    hoursWorked: 6.3,
  ),
  _Terminal(
    id: 'POS-03',
    branchId: 'b1',
    branchName: 'طرابلس - المركز',
    cashier: 'نادية عبد السلام',
    status: PosStatus.onBreak,
    shiftOpen: true,
    loginTime: '9:00 ص',
    shiftStart: '9:00 ص',
    lastActivity: 'قبل 15 د',
    invoices: 21,
    returnsAmt: 0,
    discountsAmt: 25,
    cashSales: 1500,
    cardSales: 900,
    otherSales: 0,
    openingCash: 400,
    withdrawals: 0,
    expenses: 0,
    actualCash: 0,
    hoursWorked: 4.0,
  ),
  _Terminal(
    id: 'POS-04',
    branchId: 'b1',
    branchName: 'طرابلس - المركز',
    cashier: 'خالد مخلوف',
    status: PosStatus.offline,
    shiftOpen: true,
    loginTime: '8:30 ص',
    shiftStart: '8:30 ص',
    lastActivity: 'قبل 42 د',
    invoices: 12,
    returnsAmt: 200,
    discountsAmt: 0,
    cashSales: 800,
    cardSales: 400,
    otherSales: 0,
    openingCash: 300,
    withdrawals: 0,
    expenses: 0,
    actualCash: 0,
    hoursWorked: 3.2,
  ),

  // ── Branch 2 — بنغازي (2 terminals) ──
  _Terminal(
    id: 'POS-05',
    branchId: 'b2',
    branchName: 'بنغازي - الفرع',
    cashier: 'فاطمة الزائدي',
    status: PosStatus.active,
    shiftOpen: true,
    loginTime: '8:00 ص',
    shiftStart: '8:00 ص',
    lastActivity: 'الآن',
    invoices: 54,
    returnsAmt: 90,
    discountsAmt: 130,
    cashSales: 5100,
    cardSales: 3800,
    otherSales: 1200,
    openingCash: 600,
    withdrawals: 400,
    expenses: 220,
    actualCash: 0,
    hoursWorked: 6.6,
  ),
  _Terminal(
    id: 'POS-06',
    branchId: 'b2',
    branchName: 'بنغازي - الفرع',
    cashier: 'محمد الترهوني',
    status: PosStatus.closed,
    shiftOpen: false,
    loginTime: '8:00 ص',
    shiftStart: '8:00 ص',
    lastActivity: 'قبل 2 س',
    invoices: 40,
    returnsAmt: 150,
    discountsAmt: 60,
    cashSales: 3200,
    cardSales: 1500,
    otherSales: 400,
    openingCash: 500,
    withdrawals: 200,
    expenses: 100,
    actualCash: 3380,
    hoursWorked: 8.0,
  ),

  // ── Branch 3 — مصراتة (5 terminals) ──
  _Terminal(
    id: 'POS-07',
    branchId: 'b3',
    branchName: 'مصراتة - السوق',
    cashier: 'علي الطرابلسي',
    status: PosStatus.active,
    shiftOpen: true,
    loginTime: '7:50 ص',
    shiftStart: '8:00 ص',
    lastActivity: 'قبل 2 د',
    invoices: 61,
    returnsAmt: 75,
    discountsAmt: 110,
    cashSales: 5400,
    cardSales: 4200,
    otherSales: 800,
    openingCash: 700,
    withdrawals: 300,
    expenses: 180,
    actualCash: 0,
    hoursWorked: 6.7,
  ),
  _Terminal(
    id: 'POS-08',
    branchId: 'b3',
    branchName: 'مصراتة - السوق',
    cashier: 'سارة بنور',
    status: PosStatus.active,
    shiftOpen: true,
    loginTime: '8:05 ص',
    shiftStart: '8:00 ص',
    lastActivity: 'قبل 5 د',
    invoices: 29,
    returnsAmt: 40,
    discountsAmt: 20,
    cashSales: 2100,
    cardSales: 1800,
    otherSales: 200,
    openingCash: 500,
    withdrawals: 0,
    expenses: 60,
    actualCash: 0,
    hoursWorked: 6.4,
  ),
  _Terminal(
    id: 'POS-09',
    branchId: 'b3',
    branchName: 'مصراتة - السوق',
    cashier: 'يوسف علي',
    status: PosStatus.onBreak,
    shiftOpen: true,
    loginTime: '9:15 ص',
    shiftStart: '9:15 ص',
    lastActivity: 'قبل 8 د',
    invoices: 18,
    returnsAmt: 0,
    discountsAmt: 15,
    cashSales: 1300,
    cardSales: 700,
    otherSales: 100,
    openingCash: 400,
    withdrawals: 0,
    expenses: 0,
    actualCash: 0,
    hoursWorked: 3.5,
  ),
  _Terminal(
    id: 'POS-10',
    branchId: 'b3',
    branchName: 'مصراتة - السوق',
    cashier: 'هدى سالم',
    status: PosStatus.active,
    shiftOpen: true,
    loginTime: '8:20 ص',
    shiftStart: '8:30 ص',
    lastActivity: 'قبل 1 د',
    invoices: 37,
    returnsAmt: 55,
    discountsAmt: 45,
    cashSales: 3000,
    cardSales: 2100,
    otherSales: 500,
    openingCash: 500,
    withdrawals: 100,
    expenses: 90,
    actualCash: 0,
    hoursWorked: 6.2,
  ),
  _Terminal(
    id: 'POS-11',
    branchId: 'b3',
    branchName: 'مصراتة - السوق',
    cashier: 'ليان أحمد',
    status: PosStatus.closed,
    shiftOpen: false,
    loginTime: '8:00 ص',
    shiftStart: '8:00 ص',
    lastActivity: 'قبل 3 س',
    invoices: 44,
    returnsAmt: 95,
    discountsAmt: 70,
    cashSales: 3600,
    cardSales: 1900,
    otherSales: 300,
    openingCash: 500,
    withdrawals: 250,
    expenses: 130,
    actualCash: 3700,
    hoursWorked: 8.0,
  ),
];
