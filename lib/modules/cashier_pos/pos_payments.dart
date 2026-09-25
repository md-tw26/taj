import 'package:flutter/material.dart';

import '../../core/theme/taj_colors.dart';
import '../../core/format.dart';
import 'pos_models.dart';

class PosPaymentDialog extends StatefulWidget {
  const PosPaymentDialog({
    required this.subtotal,
    required this.itemCount,
    required this.method,
    required this.onConfirm,
    this.isProfessional = false,
    this.onSplit, super.key,});

  final double subtotal;
  final int itemCount;
  final PaymentMethod method;
  final VoidCallback onConfirm;
  final bool isProfessional;
  final VoidCallback? onSplit;

  @override
  State<PosPaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PosPaymentDialog> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.subtotal.toStringAsFixed(3);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final methodName = switch (widget.method) {
      PaymentMethod.cash => 'نقدي',
      PaymentMethod.credit => 'بيع آجل',
      PaymentMethod.bank => 'تحويل مصرفي',
      PaymentMethod.sadad => 'سداد',
      PaymentMethod.numoQr => 'NUMO QR',
      PaymentMethod.mobicash => 'MobiCash',
      PaymentMethod.bankTransfer => 'تحويل الى حساب',
      PaymentMethod.bankTransferSadad => 'تحويل عبر سداد',
      PaymentMethod.bankTransferMobCash => 'تحويل عبر MobiCash',
    };

    return AlertDialog(
      title: Text(methodName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: taj.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('الإجمالي', style: TextStyle(color: taj.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  arDinar(widget.subtotal),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: taj.accentText,
                  ),
                ),
                Text(
                  '${widget.itemCount} منتج',
                  style: TextStyle(color: taj.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),

          if (widget.method == PaymentMethod.cash) ...[
            const SizedBox(height: 16),
            Text(
              'المبلغ المدفوع',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: 'د.ل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],

          if (widget.method == PaymentMethod.credit) ...[
            const SizedBox(height: 16),
            Text('اسم العميل', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'أدخل اسم العميل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],

          if (widget.method == PaymentMethod.bank) ...[
            const SizedBox(height: 16),
            Text('رقم المرجع', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'رقم عملية التحويل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (widget.isProfessional && widget.onSplit != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSplit!();
            },
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
            label: const Text('تقسيم'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        SizedBox(
          width: 140,
          child: FilledButton.icon(
            onPressed: widget.onConfirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('تأكيد'),
          ),
        ),
      ],
    );
  }
}

class PosSplitPaymentSheet extends StatefulWidget {
  const PosSplitPaymentSheet({required this.subtotal, required this.onConfirm, super.key,});

  final double subtotal;
  final void Function(PaymentMethod method, List<double> amounts) onConfirm;

  @override
  State<PosSplitPaymentSheet> createState() => _SplitPaymentSheetState();
}

class _SplitPaymentSheetState extends State<PosSplitPaymentSheet> {
  final List<PaymentMethod> _methods = [
    PaymentMethod.cash,
    PaymentMethod.bank,
    PaymentMethod.sadad,
    PaymentMethod.numoQr,
  ];
  final Map<PaymentMethod, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final m in _methods) {
      _controllers[m] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalEntered {
    return _methods.fold(0, (sum, m) {
      final v = double.tryParse(_controllers[m]!.text) ?? 0;
      return sum + v;
    });
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final remaining = widget.subtotal - _totalEntered;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        16,
        20,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تقسيم الدفع — ${arDinar(widget.subtotal)}',
            style: TextStyle(
              color: taj.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final m in _methods) ...[
            Row(
              children: [
                Icon(_methodIcon(m), size: 18, color: taj.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _methodLabel(m),
                    style: TextStyle(color: taj.textPrimary, fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _controllers[m],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: taj.divider)),
            ),
            child: Column(
              children: [
                Text(
                  'الباقي: ${arDinar(remaining)}',
                  style: TextStyle(
                    color:
                        remaining < 0
                            ? taj.accentFor(taj.success)
                            : taj.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final amounts =
                  _methods
                      .map((m) => double.tryParse(_controllers[m]!.text) ?? 0)
                      .toList();
              widget.onConfirm(_methods.first, amounts);
            },
            style: FilledButton.styleFrom(
              backgroundColor: taj.primary.main,
              foregroundColor: taj.primary.contrastText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('تأكيد التقسيم'),
          ),
        ],
      ),
    );
  }

  IconData _methodIcon(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => Icons.money_outlined,
    PaymentMethod.credit => Icons.credit_card_outlined,
    PaymentMethod.bank => Icons.account_balance_outlined,
    PaymentMethod.sadad => Icons.phone_android_rounded,
    _ => Icons.payment_outlined,
  };

  String _methodLabel(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => 'نقدي',
    PaymentMethod.bank => 'تحويل مصرفي',
    PaymentMethod.sadad => 'سداد',
    PaymentMethod.numoQr => 'NUMO QR',
    _ => 'آخرى',
  };
}
