import 'package:flutter/material.dart';

import '../../core/chart_style.dart';
import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_provider.dart';
import '../../core/demo/demo_store.dart';
import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_filters.dart';
import '../../shared/widgets/taj_table.dart';
import '../../shared/widgets/taj_ui.dart';

/// The landing module: an at-a-glance overview of store performance.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.chartStyle = ChartStyle.area});

  final ChartStyle chartStyle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final pad = pagePaddingForWidth(c.maxWidth);
        final twoCol = c.maxWidth >= AppBreakpoints.splitPane;

        return PageContainer(
          child: ListView(
            padding: EdgeInsets.all(pad),
            children: [
              SectionHeading(
                title: 'نظرة عامة',
                subtitle: 'ملخص أداء المتجر لهذا الشهر',
                trailing: const _PeriodPill(),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: DemoStoreProvider.of(context),
                builder:
                    (_, __) => _KpiGrid(store: DemoStoreProvider.of(context)),
              ),
              const SizedBox(height: 16),
              if (twoCol)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _SalesCard(
                        chartStyle: chartStyle,
                        store: DemoStoreProvider.of(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _TopProductsCard(
                        store: DemoStoreProvider.of(context),
                      ),
                    ),
                  ],
                )
              else ...[
                _SalesCard(
                  chartStyle: chartStyle,
                  store: DemoStoreProvider.of(context),
                ),
                const SizedBox(height: 16),
                _TopProductsCard(store: DemoStoreProvider.of(context)),
              ],
              const SizedBox(height: 16),
              _RecentOrdersCard(store: DemoStoreProvider.of(context)),
            ],
          ),
        );
      },
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill();
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
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
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: taj.textSecondary,
            ),
            const SizedBox(width: 8),
            Text('هذا الشهر', style: text.labelLarge),
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

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.store});
  final DemoStore store;
  @override
  Widget build(BuildContext context) {
    final tiles = [
      KpiCard(
        label: 'المبيعات',
        value: arDinar(store.salesTotal),
        icon: Icons.payments_outlined,
        spark: store.lastSevenDaySales,
      ),
      KpiCard(
        label: 'الطلبات',
        value: '${store.orderCount}',
        icon: Icons.receipt_long_outlined,
        spark: store.lastSevenDaySales,
      ),
      KpiCard(
        label: 'العملاء',
        value: '${store.customers.length}',
        icon: Icons.groups_outlined,
        spark: store.lastSevenDaySales,
      ),
      KpiCard(
        label: 'مخزون منخفض',
        value: '${store.lowStockCount}',
        icon: Icons.inventory_2_outlined,
        spark: store.lastSevenDaySales,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
        const gap = 16.0;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({required this.chartStyle, required this.store});
  final ChartStyle chartStyle;
  final DemoStore store;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    const labels = ['سبت', 'أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع'];

    return TajCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المبيعات الأسبوعية', style: text.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      arDinar(store.salesTotal),
                      style: AppThemes.numeralStyle(
                        context,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: taj.primary.main,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'الإيراد',
                    style: text.bodySmall?.copyWith(color: taj.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: Sparkline(
              values: store.lastSevenDaySales,
              color: taj.primary.main,
              style: chartStyle,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final l in labels)
                Expanded(
                  child: Text(
                    l,
                    textAlign: TextAlign.center,
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

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final ranked =
        store.productSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final items =
        ranked.take(4).map((entry) {
          final product = store.products.firstWhere(
            (p) => p.id == entry.key,
            orElse:
                () => const DemoProduct(
                  id: '',
                  name: 'صنف محذوف',
                  barcode: '',
                  category: '',
                  price: 0,
                  cost: 0,
                  stock: 0,
                  reorderLevel: 0,
                ),
          );
          return (product.name, entry.value);
        }).toList();
    final max = items.isEmpty ? 1.0 : items.first.$2;

    return TajCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('أفضل المنتجات', style: text.titleMedium),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const TajEmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'لا توجد مبيعات',
              message: 'ستظهر أفضل المنتجات بعد تسجيل المبيعات.',
            ),
          for (final (name, amount) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: text.bodyMedium)),
                      Text(
                        arDinar(amount),
                        style: AppThemes.numeralStyle(context, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: amount / max,
                      minHeight: 6,
                      backgroundColor: taj.primary.lighter,
                      valueColor: AlwaysStoppedAnimation(taj.primary.main),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Order {
  const _Order(
    this.name,
    this.phone,
    this.id,
    this.amount,
    this.status,
    this.label,
    this.branch,
  );
  final String name;
  final String phone;
  final String id;
  final String amount;
  final TajStatus status;
  final String label; // status label
  final String branch;
}

/// Available filter options (field → operator → values).
const _statusValues = ['مكتمل', 'قيد التنفيذ', 'ملغى'];
const _branchValues = ['طرابلس', 'بنغازي'];

class _RecentOrdersCard extends StatefulWidget {
  const _RecentOrdersCard({required this.store});
  final DemoStore store;
  @override
  State<_RecentOrdersCard> createState() => _RecentOrdersCardState();
}

class _RecentOrdersCardState extends State<_RecentOrdersCard> {
  final List<TajFilter> _filters = [];

  List<_Order> get _orders =>
      widget.store.sales.map((sale) {
        final customerMatches = widget.store.customers.where(
          (c) => c.id == sale.customerId,
        );
        final customer = customerMatches.isEmpty ? null : customerMatches.first;
        final branchMatches = widget.store.branches.where(
          (b) => b.id == sale.branchId,
        );
        final branch =
            branchMatches.isEmpty ? 'غير محدد' : branchMatches.first.city;
        final (status, label) = switch (sale.status) {
          DemoSaleStatus.paid => (TajStatus.success, 'مكتمل'),
          DemoSaleStatus.credit => (TajStatus.warning, 'آجل'),
          DemoSaleStatus.pending => (TajStatus.warning, 'قيد التنفيذ'),
          DemoSaleStatus.cancelled => (TajStatus.error, 'ملغى'),
          DemoSaleStatus.returned => (TajStatus.error, 'مرتجع'),
        };
        return _Order(
          customer?.name ?? 'عميل نقدي',
          customer?.phone ?? '',
          '#${sale.id.replaceFirst('INV-', '')}',
          arNum(sale.total),
          status,
          label,
          branch,
        );
      }).toList();

  Iterable<_Order> get _filtered => _orders.where((o) {
    for (final f in _filters) {
      if (f.field == 'الحالة' && o.label != f.value) return false;
      if (f.field == 'الفرع' && o.branch != f.value) return false;
    }
    return true;
  });

  void _addFilter(String field, String value) {
    setState(() {
      // One active filter per field — replace if the field already exists.
      _filters.removeWhere((f) => f.field == field);
      _filters.add(
        TajFilter(
          field: field,
          operator: field == 'الحالة' ? 'هي' : 'هو',
          value: value,
        ),
      );
    });
  }

  Future<void> _openAddMenu() async {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final picked = await showDialog<(String, String)>(
      context: context,
      builder:
          (_) => SimpleDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            title: Text('إضافة فلتر', style: text.titleMedium),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Text(
                  'الحالة',
                  style: text.labelSmall?.copyWith(color: taj.textDisabled),
                ),
              ),
              for (final v in _statusValues)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, ('الحالة', v)),
                  child: Text(v),
                ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Text(
                  'الفرع',
                  style: text.labelSmall?.copyWith(color: taj.textDisabled),
                ),
              ),
              for (final v in _branchValues)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, ('الفرع', v)),
                  child: Text(v),
                ),
            ],
          ),
    );
    if (picked != null) _addFilter(picked.$1, picked.$2);
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final orders = _filtered.toList();

    return TajCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('أحدث الطلبات', style: text.titleMedium)),
              Text(
                '${orders.length}/${_orders.length}',
                style: AppThemes.numeralStyle(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: taj.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TajFilterBar(
            filters: _filters,
            onAdd: _openAddMenu,
            onRemove: (i) => setState(() => _filters.removeAt(i)),
            onClearAll: () => setState(_filters.clear),
            onGroupBy: _openAddMenu,
            onSortBy: _openAddMenu,
          ),
          const SizedBox(height: 8),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: TajEmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'لا طلبات مطابقة',
                message: 'عدّل الفلاتر أو امسح الكل.',
              ),
            )
          else
            TajTable(
              columns: const [
                TajColumn('العميل', flex: 4),
                TajColumn('الفرع', flex: 2),
                TajColumn('المبلغ', flex: 2, numeric: true),
                TajColumn('الحالة', flex: 2),
              ],
              rows: [
                for (final o in orders)
                  TajRowData(
                    onTap: () {},
                    actions: [
                      Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: taj.textSecondary,
                      ),
                    ],
                    cells: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: taj.primary.lighter,
                            child: Text(
                              o.name.characters.first,
                              style: TextStyle(
                                color: taj.primary.dark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  o.name,
                                  style: text.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  o.id,
                                  style: AppThemes.numeralStyle(
                                    context,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: taj.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(o.branch, style: text.bodyMedium),
                      Text(
                        '${o.amount} د.ل',
                        style: AppThemes.numeralStyle(context, fontSize: 14),
                      ),
                      StatusBadge(label: o.label, status: o.status),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
