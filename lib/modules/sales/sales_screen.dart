import 'package:flutter/material.dart';

import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_provider.dart';
import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_table.dart';
import '../../shared/widgets/taj_ui.dart';

class _Invoice {
  const _Invoice(
    this.no,
    this.customer,
    this.date,
    this.total,
    this.status,
    this.label,
  );
  final String no;
  final String customer;
  final String date;
  final double total;
  final TajStatus status;
  final String label;
}

const _statusTabs = ['الكل', 'مدفوعة', 'آجلة', 'مرتجع'];

/// Sales (spec 7.4): invoice list with search, status filter, stats + export.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _search = '';
  String _status = 'الكل';

  List<_Invoice> get _storeInvoices =>
      DemoStoreProvider.of(context).sales
          .map(
            (s) => _Invoice(
              '#${s.id.replaceFirst('INV-', '')}',
              s.customerId == null
                  ? 'عميل نقدي'
                  : DemoStoreProvider.of(context).customers
                      .firstWhere(
                        (c) => c.id == s.customerId,
                        orElse:
                            () => const DemoCustomer(
                              id: '',
                              name: 'عميل',
                              phone: '',
                              creditLimit: 0,
                            ),
                      )
                      .name,
              '${s.date.year}/${s.date.month.toString().padLeft(2, '0')}/${s.date.day.toString().padLeft(2, '0')}',
              s.total,
              _statusFor(s.status).$2,
              _statusFor(s.status).$1,
            ),
          )
          .toList();

  List<_Invoice> get _filtered =>
      _storeInvoices.where((v) {
        final sOk = _status == 'الكل' || v.label == _status;
        final qOk =
            _search.isEmpty ||
            v.customer.contains(_search.trim()) ||
            v.no.contains(_search.trim());
        return sOk && qOk;
      }).toList();

  double get _paid => _storeInvoices
      .where((v) => v.label == 'مدفوعة')
      .fold(0, (s, v) => s + v.total);
  double get _credit => _storeInvoices
      .where((v) => v.label == 'آجلة')
      .fold(0, (s, v) => s + v.total);
  double get _total => _storeInvoices.fold(0, (s, v) => s + v.total);

  static (String, TajStatus) _statusFor(DemoSaleStatus status) =>
      switch (status) {
        DemoSaleStatus.paid => ('مدفوعة', TajStatus.success),
        DemoSaleStatus.credit => ('آجلة', TajStatus.warning),
        DemoSaleStatus.returned => ('مرتجع', TajStatus.info),
        DemoSaleStatus.pending => ('قيد التنفيذ', TajStatus.warning),
        DemoSaleStatus.cancelled => ('ملغاة', TajStatus.error),
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DemoStoreProvider.of(context),
      builder: (_, __) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final taj = context.taj;
    return LayoutBuilder(
      builder: (context, c) {
        final pad = pagePaddingForWidth(c.maxWidth);
        final rows = _filtered;
        return PageContainer(
          child: ListView(
            padding: EdgeInsets.all(pad),
            children: [
              SectionHeading(
                title: 'المبيعات',
                subtitle: 'الفواتير والمرتجعات',
                trailing: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('تصدير'),
                    ),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('فاتورة جديدة'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _StatsRow(total: _total, paid: _paid, credit: _credit),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'ابحث برقم الفاتورة أو العميل…',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _DatePill(),
                ],
              ),
              const SizedBox(height: 12),
              _StatusTabs(
                value: _status,
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: TajEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'لا فواتير مطابقة',
                    message: 'غيّر البحث أو الحالة.',
                  ),
                )
              else
                TajCard(
                  padding: EdgeInsets.zero,
                  child: TajTable(
                    columns: const [
                      TajColumn('رقم الفاتورة', flex: 2),
                      TajColumn('العميل', flex: 3),
                      TajColumn('التاريخ', flex: 2),
                      TajColumn('الإجمالي', flex: 2, numeric: true),
                      TajColumn('الحالة', flex: 2),
                    ],
                    rows: [
                      for (final v in rows)
                        TajRowData(
                          onTap: () => _openSale(context, v),
                          actions: [
                            Icon(
                              Icons.print_outlined,
                              size: 17,
                              color: taj.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.more_horiz_rounded,
                              size: 18,
                              color: taj.textSecondary,
                            ),
                          ],
                          cells: [
                            Text(
                              v.no,
                              style: AppThemes.numeralStyle(
                                context,
                                fontSize: 14,
                                color: taj.accentText,
                              ),
                            ),
                            Text(
                              v.customer,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              v.date,
                              style: AppThemes.numeralStyle(
                                context,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: taj.textSecondary,
                              ),
                            ),
                            Text(
                              arDinar(v.total),
                              style: AppThemes.numeralStyle(
                                context,
                                fontSize: 14,
                              ),
                            ),
                            StatusBadge(label: v.label, status: v.status),
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

  Future<void> _openSale(BuildContext context, _Invoice invoice) async {
    final saleId = invoice.no.replaceFirst('#', 'INV-');
    final sale = DemoStoreProvider.of(
      context,
    ).sales.firstWhere((s) => s.id == saleId);
    final next = await showDialog<DemoSaleStatus>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('الفاتورة ${invoice.no}'),
            content: Text(
              'الإجمالي ${arDinar(invoice.total)}\nيمكن تحديث حالة الفاتورة من هنا.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إغلاق'),
              ),
              if (sale.status != DemoSaleStatus.returned)
                TextButton(
                  onPressed:
                      () =>
                          Navigator.pop(dialogContext, DemoSaleStatus.returned),
                  child: const Text('مرتجع'),
                ),
              if (sale.status != DemoSaleStatus.cancelled)
                TextButton(
                  onPressed:
                      () => Navigator.pop(
                        dialogContext,
                        DemoSaleStatus.cancelled,
                      ),
                  child: const Text('إلغاء الفاتورة'),
                ),
            ],
          ),
    );
    if (next == null) return;
    if (!context.mounted) return;
    await DemoStoreProvider.of(context).updateSaleStatus(sale.id, next);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم تحديث حالة الفاتورة')));
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.total,
    required this.paid,
    required this.credit,
  });
  final double total;
  final double paid;
  final double credit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 560 ? 3 : 1;
        const gap = 16.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        final tiles = [
          KpiCard(
            label: 'إجمالي المبيعات',
            value: arDinar(total),
            icon: Icons.payments_outlined,
            spark: const [20, 26, 24, 32, 30, 40, 46],
          ),
          KpiCard(
            label: 'مدفوعة',
            value: arDinar(paid),
            delta: '70٪',
            icon: Icons.check_circle_outline,
            spark: const [10, 14, 13, 18, 20, 24, 28],
          ),
          KpiCard(
            label: 'آجلة',
            value: arDinar(credit),
            delta: '30٪',
            deltaPositive: false,
            icon: Icons.schedule_outlined,
            spark: const [8, 7, 9, 6, 7, 6, 5],
          ),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _statusTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _statusTabs[i];
          final selected = t == value;
          return GestureDetector(
            onTap: () => onChanged(t),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? taj.primary.lighter : taj.paper,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? taj.primary.main : taj.divider,
                ),
              ),
              child: Text(
                t,
                style: TextStyle(
                  color: selected ? taj.primary.dark : taj.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: taj.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_outlined, size: 18, color: taj.textSecondary),
          const SizedBox(width: 8),
          Text('هذا الأسبوع', style: text.labelLarge),
        ],
      ),
    );
  }
}
