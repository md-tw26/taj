import 'package:flutter/material.dart';

import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_provider.dart';
import '../../core/demo/demo_store.dart';
import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_table.dart';
import '../../shared/widgets/taj_ui.dart';

/// POS Management module — the control tower for the point-of-sale operation:
/// **Company → Branches → Terminals → Sales**.
///
/// Everything here reads off [DemoStore]: branches and terminals are real
/// records, and the period figures are computed from the actual sales (with
/// their real dates and branches). Data the system does not record yet —
/// per-terminal/per-cashier sales, shifts and cash reconciliation — is shown
/// as an honest empty state rather than invented numbers.
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

  List<_Branch> _branchesInScope(DemoStore store) => [
    for (final b in store.branches)
      if (_branchId == null || b.id == _branchId) _Branch(b.id, b.name, b.city),
  ];

  List<_Terminal> _terminalsInScope(DemoStore store) => [
    for (final t in store.terminals)
      if (_branchId == null || t.branchId == _branchId)
        _Terminal(
          id: t.id,
          branchId: t.branchId,
          branchName: _branchName(store, t.branchId),
          status: _statusFromKey(t.status),
        ),
  ];

  static String _branchName(DemoStore store, String id) {
    final m = store.branches.where((b) => b.id == id);
    return m.isEmpty ? '—' : m.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoStoreProvider.of(context);
    return AnimatedBuilder(
      animation: store,
      builder:
          (context, _) => LayoutBuilder(
            builder: (context, c) {
              final pad = pagePaddingForWidth(c.maxWidth);
              final branches = _branchesInScope(store);
              final terminals = _terminalsInScope(store);

              return PageContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, pad, pad, 12),
                      child: SectionHeading(
                        title: 'إدارة نقاط البيع',
                        subtitle: 'مراقبة الفروع والأجهزة والمبيعات',
                        trailing: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _PickerPill<String?>(
                              icon: Icons.store_mall_directory_outlined,
                              value: _branchId,
                              items: [
                                null,
                                for (final b in store.branches) b.id,
                              ],
                              labelOf:
                                  (id) =>
                                      id == null
                                          ? 'كل الفروع'
                                          : _branchName(store, id),
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
                    _SectionTabs(
                      selected: _section,
                      onSelect: (s) => setState(() => _section = s),
                    ),
                    Divider(height: 1, color: context.taj.divider),
                    Expanded(
                      child: _buildSection(
                        context,
                        store,
                        branches,
                        terminals,
                        pad,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    DemoStore store,
    List<_Branch> branches,
    List<_Terminal> terminals,
    double pad,
  ) {
    final agg = _periodAgg(store, branches, _period);
    switch (_section) {
      case _Section.overview:
        return _OverviewSection(
          terminals: terminals,
          branches: branches,
          period: _period,
          agg: agg,
          pad: pad,
        );
      case _Section.terminals:
        return _TerminalsSection(terminals: terminals, pad: pad);
      case _Section.cashiers:
        return _CashiersSection(pad: pad);
      case _Section.shifts:
        return _ShiftsSection(pad: pad);
      case _Section.branches:
        return _BranchesSection(
          store: store,
          branches: branches,
          terminals: terminals,
          pad: pad,
        );
      case _Section.performance:
        return _PerformanceSection(pad: pad);
      case _Section.reports:
        return _ReportsSection(period: _period, agg: agg, pad: pad);
    }
  }
}

// ─── Period aggregate, computed from real sales ──────────────────────────────

class _PeriodAgg {
  const _PeriodAgg({
    required this.totalSales,
    required this.invoices,
    required this.customers,
  });
  final double totalSales;
  final int invoices;
  final int customers;
  double get avgInvoice => invoices == 0 ? 0 : totalSales / invoices;
}

_PeriodAgg _periodAgg(DemoStore store, List<_Branch> branches, _Period period) {
  final now = DateTime.now();
  final branchIds = branches.map((b) => b.id).toSet();
  final sales = store.sales.where(
    (s) =>
        branchIds.contains(s.branchId) &&
        s.status != DemoSaleStatus.cancelled &&
        s.status != DemoSaleStatus.returned &&
        period.includes(s.date, now),
  );
  var total = 0.0;
  var count = 0;
  final custs = <String>{};
  for (final s in sales) {
    total += s.total;
    count++;
    if (s.customerId != null) custs.add(s.customerId!);
  }
  return _PeriodAgg(
    totalSales: total,
    invoices: count,
    customers: custs.length,
  );
}

// ─── Section sub-navigation ──────────────────────────────────────────────────

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

// ─── 1) Overview ─────────────────────────────────────────────────────────────

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.terminals,
    required this.branches,
    required this.period,
    required this.agg,
    required this.pad,
  });

  final List<_Terminal> terminals;
  final List<_Branch> branches;
  final _Period period;
  final _PeriodAgg agg;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final active = terminals.where((t) => t.status == PosStatus.active).length;
    final offline =
        terminals.where((t) => t.status == PosStatus.offline).length;

    final tiles = <Widget>[
      _StatTile(
        icon: Icons.store_mall_directory_outlined,
        label: 'الفروع',
        value: arNum(branches.length),
        swatch: taj.info,
      ),
      _StatTile(
        icon: Icons.point_of_sale_outlined,
        label: 'أجهزة نقاط البيع',
        value: arNum(terminals.length),
        swatch: taj.primary,
      ),
      _StatTile(
        icon: Icons.check_circle_outline_rounded,
        label: 'أجهزة متصلة',
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
        icon: Icons.payments_outlined,
        label: 'مبيعات ${period.label}',
        value: arDinar(agg.totalSales),
        swatch: taj.primary,
        emphasize: true,
      ),
      _StatTile(
        icon: Icons.receipt_long_outlined,
        label: 'عدد الفواتير',
        value: arNum(agg.invoices),
        swatch: taj.primary,
      ),
      _StatTile(
        icon: Icons.groups_outlined,
        label: 'العملاء',
        value: arNum(agg.customers),
        swatch: taj.info,
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
        const SizedBox(height: 14),
        if (terminals.isEmpty)
          const TajEmptyState(
            icon: Icons.point_of_sale_outlined,
            title: 'لا توجد أجهزة',
            message: 'لا توجد أجهزة نقاط بيع لهذا الفرع.',
          )
        else
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
        ],
      ),
    );
  }
}

// ─── 2) Terminals ────────────────────────────────────────────────────────────

class _TerminalsSection extends StatelessWidget {
  const _TerminalsSection({required this.terminals, required this.pad});
  final List<_Terminal> terminals;
  final double pad;

  @override
  Widget build(BuildContext context) {
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
        if (terminals.isEmpty)
          const TajEmptyState(
            icon: Icons.point_of_sale_outlined,
            title: 'لا توجد أجهزة',
            message: 'أضِف جهاز نقطة بيع ليظهر هنا.',
          )
        else
          TajCard(
            padding: EdgeInsets.zero,
            child: TajTable(
              minWidth: 480,
              columns: const [
                TajColumn('الجهاز', flex: 3),
                TajColumn('الفرع', flex: 3),
                TajColumn('الحالة', flex: 2),
              ],
              rows: [
                for (final t in terminals)
                  TajRowData(
                    onTap: () => _showTerminalSheet(context, t),
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
                      _PosStatusBadge(t.status),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── 3) Cashiers (not recorded yet) ──────────────────────────────────────────

class _CashiersSection extends StatelessWidget {
  const _CashiersSection({required this.pad});
  final double pad;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      children: [
        Text('أداء الكاشيرين اليوم', style: text.titleMedium),
        const SizedBox(height: 14),
        const TajEmptyState(
          icon: Icons.badge_outlined,
          title: 'لا تتوفّر بيانات كاشيرين',
          message:
              'المبيعات غير مرتبطة بكاشير محدد في هذا الإصدار، لذا لا يمكن عرض '
              'أداء فردي للكاشيرين.',
        ),
      ],
    );
  }
}

// ─── 4) Shifts (not recorded yet) ────────────────────────────────────────────

class _ShiftsSection extends StatelessWidget {
  const _ShiftsSection({required this.pad});
  final double pad;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      children: [
        Row(
          children: [
            Expanded(child: Text('الورديات', style: text.titleMedium)),
            FilledButton.icon(
              onPressed: () => _toast(context, 'فتح وردية جديدة'),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text('فتح وردية'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const TajEmptyState(
          icon: Icons.schedule_outlined,
          title: 'لا توجد ورديات مسجّلة',
          message:
              'لا يسجّل النظام الورديات أو التسوية النقدية بعد؛ ستظهر هنا عند '
              'توفّرها.',
        ),
      ],
    );
  }
}

// ─── 5) Branch performance (real sales) ──────────────────────────────────────

class _BranchesSection extends StatelessWidget {
  const _BranchesSection({
    required this.store,
    required this.branches,
    required this.terminals,
    required this.pad,
  });
  final DemoStore store;
  final List<_Branch> branches;
  final List<_Terminal> terminals;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows = [
      for (final b in branches) (branch: b, sales: store.salesForBranch(b.id)),
    ]..sort((a, b) => b.sales.compareTo(a.sales));
    final maxSales =
        rows.isEmpty
            ? 1.0
            : rows.map((r) => r.sales).fold<double>(0, (a, b) => a > b ? a : b);

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      children: [
        Text('أداء الفروع', style: text.titleMedium),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          const TajEmptyState(
            icon: Icons.store_mall_directory_outlined,
            title: 'لا توجد فروع',
            message: 'لا توجد فروع لعرض أدائها.',
          )
        else
          _CardGrid(
            minItemWidth: 300,
            children: [
              for (final r in rows)
                _BranchCard(
                  name: r.branch.name,
                  sales: r.sales,
                  terminals:
                      terminals.where((t) => t.branchId == r.branch.id).length,
                  active:
                      terminals
                          .where(
                            (t) =>
                                t.branchId == r.branch.id &&
                                t.status == PosStatus.active,
                          )
                          .length,
                  share: maxSales == 0 ? 0 : r.sales / maxSales,
                ),
            ],
          ),
      ],
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.name,
    required this.sales,
    required this.terminals,
    required this.active,
    required this.share,
  });
  final String name;
  final double sales;
  final int terminals;
  final int active;
  final double share;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
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
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    Text(
                      '${arNum(terminals)} أجهزة • ${arNum(active)} متصل',
                      style: text.bodySmall?.copyWith(color: taj.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            arDinar(sales),
            style: AppThemes.numeralStyle(
              context,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'إجمالي مبيعات الفرع',
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
        ],
      ),
    );
  }
}

// ─── 6) Performance (not recorded yet) ───────────────────────────────────────

class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection({required this.pad});
  final double pad;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      children: [
        Text('لوحة الأبطال', style: text.titleMedium),
        const SizedBox(height: 14),
        const TajEmptyState(
          icon: Icons.leaderboard_outlined,
          title: 'لا تتوفّر مقارنة أداء',
          message:
              'تعتمد لوحة الأبطال على مبيعات كل كاشير، وهي غير مسجّلة بعد. '
              'راجع «الفروع» لأداء المبيعات حسب الفرع.',
        ),
      ],
    );
  }
}

// ─── 7) Reports ──────────────────────────────────────────────────────────────

class _ReportsSection extends StatelessWidget {
  const _ReportsSection({
    required this.period,
    required this.agg,
    required this.pad,
  });
  final _Period period;
  final _PeriodAgg agg;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    const reports = [
      ('مبيعات الفروع', Icons.store_outlined),
      ('مبيعات الأجهزة', Icons.point_of_sale_outlined),
      ('المبيعات اليومية', Icons.today_outlined),
      ('المرتجعات', Icons.assignment_return_outlined),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
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
              Text('ملخّص المبيعات — ${period.label}', style: text.titleMedium),
              const SizedBox(height: 14),
              _CardGrid(
                minItemWidth: 170,
                gap: 12,
                children: [
                  _SummaryStat(
                    label: 'إجمالي المبيعات',
                    value: arDinar(agg.totalSales),
                  ),
                  _SummaryStat(label: 'الفواتير', value: arNum(agg.invoices)),
                  _SummaryStat(
                    label: 'متوسط الفاتورة',
                    value: arDinar(agg.avgInvoice),
                  ),
                  _SummaryStat(label: 'العملاء', value: arNum(agg.customers)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'تفصيل طرق الدفع لكل جهاز غير متاح بعد.',
                style: text.bodySmall?.copyWith(color: taj.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared building blocks ──────────────────────────────────────────────────

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

({TajSwatch swatch, String label, Color dot}) _statusVisual(
  BuildContext context,
  PosStatus s,
) {
  final taj = context.taj;
  return switch (s) {
    PosStatus.active => (
      swatch: taj.success,
      label: 'متصل',
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
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
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
                t.branchName,
                style: text.bodyMedium?.copyWith(color: taj.textSecondary),
              ),
              const SizedBox(height: 20),
              Text(
                'لا يسجّل النظام مبيعات أو ورديات لكل جهاز على حدة بعد، لذا لا تتوفّر '
                'تفاصيل إضافية لهذا الجهاز.',
                style: text.bodyMedium?.copyWith(color: taj.textSecondary),
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

// ─── Models ──────────────────────────────────────────────────────────────────

/// Terminal status. 🟢 active · ⚪ offline · 🟠 break · 🔴 closed
enum PosStatus { active, offline, onBreak, closed }

PosStatus _statusFromKey(String status) => switch (status) {
  'متصل' || 'متاح' || 'نشط' => PosStatus.active,
  'في استراحة' || 'استراحة' => PosStatus.onBreak,
  'مغلق' => PosStatus.closed,
  _ => PosStatus.offline,
};

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
    required this.status,
  });
  final String id;
  final String branchId;
  final String branchName;
  final PosStatus status;
}

/// Time filters for the sales figures, matched against real sale dates.
enum _Period {
  today('اليوم'),
  yesterday('أمس'),
  thisWeek('هذا الأسبوع'),
  thisMonth('هذا الشهر'),
  thisYear('هذا العام'),
  all('كل الفترات');

  const _Period(this.label);
  final String label;

  bool includes(DateTime d, DateTime now) {
    switch (this) {
      case _Period.today:
        return d.year == now.year && d.month == now.month && d.day == now.day;
      case _Period.yesterday:
        final y = now.subtract(const Duration(days: 1));
        return d.year == y.year && d.month == y.month && d.day == y.day;
      case _Period.thisWeek:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        return !d.isBefore(start);
      case _Period.thisMonth:
        return d.year == now.year && d.month == now.month;
      case _Period.thisYear:
        return d.year == now.year;
      case _Period.all:
        return true;
    }
  }
}
