import 'package:flutter/material.dart';

import '../../core/theme/taj_colors.dart';
import '../../core/format.dart';
import 'pos_models.dart';

class PosShiftClosedSheet extends StatelessWidget {
  const PosShiftClosedSheet({
    required this.totalSales,
    required this.transactionCount,
    required this.cashTotal,
    required this.itemCount, super.key,});

  final double totalSales;
  final int transactionCount;
  final double cashTotal;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        24,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: taj.success.lighter,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.lock_clock_rounded,
              size: 32,
              color: taj.success.dark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تم إغلاق الوردية',
            style: TextStyle(
              color: taj.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'مجموع المبيعات: ${arDinar(totalSales)}',
            style: TextStyle(color: taj.textSecondary, fontSize: 14),
          ),
          Text(
            '$transactionCount معاملة · $itemCount منتج',
            style: TextStyle(color: taj.textSecondary, fontSize: 14),
          ),
          Text(
            'نقد بالصندوق: ${arDinar(cashTotal)}',
            style: TextStyle(
              color: taj.accentFor(taj.success),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PosReportsSheet extends StatelessWidget {
  const PosReportsSheet({
    required this.sales,
    required this.totalSales,
    required this.cashTotal,
    required this.itemCount,
    required this.onCloseShift, super.key,});

  final List<PosCompletedSale> sales;
  final double totalSales;
  final double cashTotal;
  final int itemCount;
  final VoidCallback onCloseShift;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    // Breakdown by payment method.
    final byMethod = <PaymentMethod, double>{};
    final methodCount = <PaymentMethod, int>{};
    for (final s in sales) {
      byMethod[s.method] = (byMethod[s.method] ?? 0) + s.total;
      methodCount[s.method] = (methodCount[s.method] ?? 0) + 1;
    }
    final methods =
        byMethod.keys.toList()
          ..sort((a, b) => (byMethod[b] ?? 0).compareTo(byMethod[a] ?? 0));

    String methodName(PaymentMethod m) => switch (m) {
      PaymentMethod.cash => 'نقدي',
      PaymentMethod.credit => 'آجل',
      PaymentMethod.bank => 'تحويل مصرفي',
      PaymentMethod.sadad => 'سداد',
      PaymentMethod.numoQr => 'NUMO QR',
      PaymentMethod.mobicash => 'MobiCash',
      PaymentMethod.bankTransfer => 'تحويل الى حساب',
      PaymentMethod.bankTransferSadad => 'تحويل عبر سداد',
      PaymentMethod.bankTransferMobCash => 'تحويل عبر MobiCash',
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تقرير الجلسة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: taj.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ملخص مبيعات هذه الوردية',
              textAlign: TextAlign.center,
              style: TextStyle(color: taj.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // KPI cards
            Row(
              children: [
                Expanded(
                  child: _ReportKpi(
                    label: 'إجمالي المبيعات',
                    value: arDinar(totalSales),
                    color: taj.primary.main,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportKpi(
                    label: 'معاملات',
                    value: '${sales.length}',
                    color: taj.info.main,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportKpi(
                    label: 'منتجات',
                    value: '$itemCount',
                    color: taj.warning.main,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Cash drawer highlight
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: taj.success.lighter,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: taj.success.main),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.payments_rounded,
                    size: 18,
                    color: taj.success.dark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'نقد بالدرج',
                    style: TextStyle(
                      color: taj.success.dark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    arDinar(cashTotal),
                    style: TextStyle(
                      color: taj.success.dark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Breakdown by payment method
            if (methods.isNotEmpty) ...[
              Text(
                'توزيع طرق الدفع',
                style: TextStyle(
                  color: taj.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final m in methods) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          methodName(m),
                          style: TextStyle(
                            color: taj.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${methodCount[m]} فاتورة',
                        style: TextStyle(
                          color: taj.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        arDinar(byMethod[m] ?? 0),
                        style: TextStyle(
                          color: taj.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: taj.divider),
              ],
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCloseShift,
                    icon: const Icon(Icons.lock_clock_rounded, size: 18),
                    label: const Text('إغلاق الوردية'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: taj.error.main,
                      side: BorderSide(color: taj.error.main),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('تم'),
                    style: FilledButton.styleFrom(
                      backgroundColor: taj.primary.main,
                      foregroundColor: taj.primary.contrastText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportKpi extends StatelessWidget {
  const _ReportKpi({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: taj.divider),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: taj.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class PosCartLineEditSheet extends StatelessWidget {
  const PosCartLineEditSheet({
    required this.product,
    required this.initialQuantity,
    required this.initialPrice,
    required this.canChangePrice,
    required this.onSave,
    required this.onRemove, super.key,});

  final PosProduct product;
  final int initialQuantity;
  final double initialPrice;
  final bool canChangePrice;
  final void Function(int quantity, double price) onSave;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final qtyController = TextEditingController(
      text: initialQuantity.toString(),
    );
    final priceController = TextEditingController(
      text: initialPrice.toStringAsFixed(3),
    );

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        24,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            product.name,
            style: TextStyle(
              color: taj.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'الكمية',
                  style: TextStyle(color: taj.textSecondary, fontSize: 13),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (canChangePrice) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'السعر (د.ل)',
                    style: TextStyle(color: taj.textSecondary, fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixText: '${arNum(product.price)} ← ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRemove();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: taj.error.main,
              side: BorderSide(color: taj.error.main),
            ),
            child: const Text('إزالة من السلة'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final qty =
                  int.tryParse(qtyController.text.trim()) ?? initialQuantity;
              final price =
                  canChangePrice
                      ? double.tryParse(priceController.text.trim()) ??
                          initialPrice
                      : initialPrice;
              Navigator.of(context).pop();
              onSave(qty, price);
            },
            style: FilledButton.styleFrom(
              backgroundColor: taj.primary.main,
              foregroundColor: taj.primary.contrastText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class PosCustomerPickerSheet extends StatelessWidget {
  const PosCustomerPickerSheet({
    required this.selected,
    required this.customers,
    required this.onSelect, super.key,});

  final String? selected;
  final List<String> customers;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ربط عميل',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: taj.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'اختر عميلاً لهذه الفاتورة',
              textAlign: TextAlign.center,
              style: TextStyle(color: taj.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: customers.length,
                separatorBuilder:
                    (_, _) => Divider(height: 1, color: taj.divider),
                itemBuilder: (_, i) {
                  final name = customers[i];
                  final isSelected = name == selected;
                  return ListTile(
                    dense: true,
                    title: Text(
                      name,
                      style: TextStyle(
                        color: taj.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    trailing:
                        isSelected
                            ? Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: taj.success.dark,
                            )
                            : null,
                    onTap: () => onSelect(name),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSelect('');
              },
              child: Text(
                'إلغاء ربط العميل',
                style: TextStyle(color: taj.error.main, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
