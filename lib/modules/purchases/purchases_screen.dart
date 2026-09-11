import 'package:flutter/material.dart';

import '../../core/demo/demo_provider.dart';
import '../../core/demo/demo_models.dart';
import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_filters.dart';
import '../../shared/widgets/taj_table.dart';
import '../../shared/widgets/taj_ui.dart';

class _Purchase {
  const _Purchase(
    this.no,
    this.supplier,
    this.date,
    this.total,
    this.status,
    this.label,
  );
  final String no;
  final String supplier;
  final String date;
  final double total;
  final TajStatus status;
  final String label;
}

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<_Purchase> get _storePurchases {
    final store = DemoStoreProvider.of(context);
    return store.purchases.map((p) {
      final matches =
          store.suppliers.where((s) => s.id == p.supplierId).toList();
      final supplier = matches.isEmpty ? null : matches.first;
      return _Purchase(
        '#${p.id.replaceFirst('PUR-', 'ش')}',
        supplier?.name ?? 'مورد',
        '${p.date.year}/${p.date.month.toString().padLeft(2, '0')}/${p.date.day.toString().padLeft(2, '0')}',
        p.total,
        p.paid ? TajStatus.success : TajStatus.warning,
        p.paid ? 'مدفوع' : 'آجل',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DemoStoreProvider.of(context),
      builder: (_, __) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final taj = context.taj;
    final purchases = _storePurchases;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      endDrawer: Drawer(
        width: drawerWidth(context, desired: 520),
        backgroundColor: taj.paper,
        child: const _PurchaseForm(),
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final pad = pagePaddingForWidth(c.maxWidth);
          return PageContainer(
            child: ListView(
              padding: EdgeInsets.all(pad),
              children: [
                SectionHeading(
                  title: 'المشتريات',
                  subtitle: 'فواتير الموردين',
                  trailing: FilledButton.icon(
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('فاتورة شراء'),
                  ),
                ),
                const SizedBox(height: 20),
                const TajFilterBar(
                  filters: [
                    TajFilter(
                      field: 'المورد',
                      operator: 'هو',
                      value: 'مؤسسة العطور',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TajCard(
                  padding: EdgeInsets.zero,
                  child: TajTable(
                    columns: const [
                      TajColumn('رقم الفاتورة', flex: 2),
                      TajColumn('المورد', flex: 3),
                      TajColumn('التاريخ', flex: 2),
                      TajColumn('الإجمالي', flex: 2, numeric: true),
                      TajColumn('الحالة', flex: 2),
                    ],
                    rows: [
                      for (final p in purchases)
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
                            Text(
                              p.no,
                              style: AppThemes.numeralStyle(
                                context,
                                fontSize: 14,
                                color: taj.accentText,
                              ),
                            ),
                            Text(
                              p.supplier,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              p.date,
                              style: AppThemes.numeralStyle(
                                context,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: taj.textSecondary,
                              ),
                            ),
                            Text(
                              arDinar(p.total),
                              style: AppThemes.numeralStyle(
                                context,
                                fontSize: 14,
                              ),
                            ),
                            StatusBadge(label: p.label, status: p.status),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Line {
  _Line(this.name, this.qty, this.price);
  String name;
  int qty;
  double price;
  double get total => qty * price;
}

class _PurchaseForm extends StatefulWidget {
  const _PurchaseForm();
  @override
  State<_PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends State<_PurchaseForm> {
  String _supplier = 'مؤسسة العطور';
  String _payment = 'آجل';
  final List<_Line> _lines = [
    _Line('عود ملكي', 10, 300),
    _Line('بخور فاخر', 20, 110),
  ];

  double get _total => _lines.fold(0, (s, l) => s + l.total);

  void _addLine() => setState(() => _lines.add(_Line('صنف جديد', 1, 0)));
  void _removeLine(int i) => setState(() => _lines.removeAt(i));

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('فاتورة شراء جديدة', style: text.titleLarge),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: taj.divider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('المورد'),
                          DropdownButtonFormField<String>(
                            value: _supplier,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'مؤسسة العطور',
                                child: Text('مؤسسة العطور'),
                              ),
                              DropdownMenuItem(
                                value: 'مستودع البخور',
                                child: Text('مستودع البخور'),
                              ),
                              DropdownMenuItem(
                                value: 'شركة الزيوت',
                                child: Text('شركة الزيوت'),
                              ),
                            ],
                            onChanged:
                                (v) =>
                                    setState(() => _supplier = v ?? _supplier),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('رقم الفاتورة'),
                          const TextField(
                            decoration: InputDecoration(hintText: 'ش211'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _label('الأصناف'),
                const SizedBox(height: 4),
                for (var i = 0; i < _lines.length; i++) _lineRow(context, i),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('إضافة صنف'),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: taj.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: taj.divider),
                  ),
                  child: Row(
                    children: [
                      Text('الإجمالي', style: text.titleMedium),
                      const Spacer(),
                      Text(
                        arDinar(_total),
                        style: AppThemes.numeralStyle(
                          context,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: taj.accentText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _label('السداد'),
                DropdownButtonFormField<String>(
                  value: _payment,
                  items: const [
                    DropdownMenuItem(value: 'نقدي', child: Text('نقدي')),
                    DropdownMenuItem(value: 'آجل', child: Text('آجل')),
                  ],
                  onChanged: (v) => setState(() => _payment = v ?? _payment),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('إرفاق صورة الفاتورة'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () async {
                  final store = DemoStoreProvider.of(context);
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final supplier = store.suppliers.first;
                  await store.addPurchase(
                    DemoPurchase(
                      id: 'PUR-${210 + store.purchases.length}',
                      supplierId: supplier.id,
                      date: DateTime.now(),
                      total: _total,
                      paid: _payment == 'نقدي',
                    ),
                  );
                  navigator.maybePop();
                  messenger.showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: taj.success.dark,
                      content: const Text(
                        'تم الحفظ — حُدّث المخزون ورصيد المورد والقيد المحاسبي',
                      ),
                    ),
                  );
                },
                child: const Text('حفظ فاتورة الشراء'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineRow(BuildContext context, int i) {
    final taj = context.taj;
    final l = _lines[i];
    // Keyed to the line object so field state stays with its row across edits.
    return Padding(
      key: ObjectKey(l),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextFormField(
              initialValue: l.name,
              onChanged: (v) => l.name = v,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'الصنف',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: '${l.qty}',
              keyboardType: TextInputType.number,
              onChanged:
                  (v) => setState(() => l.qty = int.tryParse(v) ?? l.qty),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'كمية',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue:
                  l.price == l.price.roundToDouble()
                      ? '${l.price.toInt()}'
                      : '${l.price}',
              keyboardType: TextInputType.number,
              onChanged:
                  (v) =>
                      setState(() => l.price = double.tryParse(v) ?? l.price),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'سعر',
                suffixText: 'د.ل',
              ),
            ),
          ),
          IconButton(
            onPressed: _lines.length > 1 ? () => _removeLine(i) : null,
            icon: Icon(
              Icons.remove_circle_outline,
              size: 20,
              color: taj.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(s, style: Theme.of(context).textTheme.labelLarge),
  );
}
