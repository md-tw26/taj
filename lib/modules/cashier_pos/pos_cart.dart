import 'package:flutter/material.dart';

import '../../core/theme/taj_colors.dart';
import '../../core/format.dart';
import 'payment_services_panel.dart';
import 'pos_models.dart';

// ── Cart Section ─────────────────────────────────────────────────────────────

class PosCartSection extends StatelessWidget {
  const PosCartSection({
    required this.products,
    required this.lowStockCount,
    required this.cart,
    required this.subtotal,
    required this.itemCount,
    required this.isProfessional,
    required this.canChangePrice,
    required this.heldOrders,
    required this.shiftOpen,
    required this.linkedCustomer,
    required this.isEditingLine,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onClearCart,
    required this.onPayCash,
    required this.onPayCredit,
    required this.onPayBank,
    required this.onPaySadad,
    required this.onPayNumoQr,
    required this.onPayMobicash,
    required this.onPayBankTransfer,
    required this.onPayBankTransferSadad,
    required this.onPayBankTransferMobCash,
    required this.onHoldOrder,
    required this.onSplitPayment,
    required this.onPressShift,
    required this.onEditLine,
    required this.onRecallOrder,
    required this.onLinkCustomer,
    required this.discountPercent,
    required this.onDiscountChanged,
    required this.priceOverrides,
    required this.orderNote,
    required this.onOrderNoteChanged,
    required this.sessionSaleCount,
    required this.sessionCashTotal,
    this.scrollController, super.key,});

  final List<PosProduct> products;
  final int lowStockCount;
  final Map<String, int> cart;
  final double subtotal;
  final int itemCount;
  final bool isProfessional;
  final bool canChangePrice;
  final List<PosHeldOrder> heldOrders;
  final bool shiftOpen;
  final String? linkedCustomer;
  final String? isEditingLine;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearCart;
  final VoidCallback onPayCash;
  final VoidCallback onPayCredit;
  final VoidCallback onPayBank;
  final VoidCallback onPaySadad;
  final VoidCallback onPayNumoQr;
  final VoidCallback onPayMobicash;
  final VoidCallback onPayBankTransfer;
  final VoidCallback onPayBankTransferSadad;
  final VoidCallback onPayBankTransferMobCash;
  final VoidCallback onHoldOrder;
  final VoidCallback onSplitPayment;
  final VoidCallback onPressShift;
  final ValueChanged<String> onEditLine;
  final ValueChanged<PosHeldOrder> onRecallOrder;
  final VoidCallback onLinkCustomer;
  final double discountPercent;
  final ValueChanged<double> onDiscountChanged;
  final Map<String, double> priceOverrides;
  final String orderNote;
  final ValueChanged<String> onOrderNoteChanged;
  final int sessionSaleCount;
  final double sessionCashTotal;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Cap the totals/footer so it scrolls internally on short windows
        // instead of crushing the cart items area to zero (overflow fix).
        final maxFooterHeight = constraints.maxHeight * 0.52;
        return Container(
          decoration: BoxDecoration(
            color: taj.paper,
            border: Border(left: BorderSide(color: taj.divider)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: taj.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الفاتورة',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: taj.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Trailing tools scale down on very tight widths instead of
                    // overflowing — the professional header carries several tools.
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Professional: low-stock indicator (one chip) ──
                              if (isProfessional && lowStockCount > 0) ...[
                                Tooltip(
                                  message: 'مخزون منخفض: $lowStockCount صنف',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: taj.warning.lighter,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_rounded,
                                          size: 13,
                                          color: taj.warning.dark,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$lowStockCount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: taj.warning.dark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],

                              // ── Professional: Customer link ──
                              if (isProfessional)
                                TextButton.icon(
                                  onPressed: onLinkCustomer,
                                  icon: Icon(
                                    linkedCustomer == null
                                        ? Icons.person_add_alt_1_rounded
                                        : Icons.person_rounded,
                                    size: 16,
                                    color:
                                        linkedCustomer == null
                                            ? taj.textSecondary
                                            : taj.primary.main,
                                  ),
                                  label: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 120,
                                    ),
                                    child: Text(
                                      linkedCustomer ?? 'ربط عميل',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            linkedCustomer == null
                                                ? taj.textSecondary
                                                : taj.primary.main,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                              // ── Professional: Shift toggle ──
                              if (isProfessional)
                                IconButton(
                                  tooltip:
                                      shiftOpen
                                          ? 'إغلاق الوردية'
                                          : 'فتح الوردية',
                                  onPressed: onPressShift,
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    shiftOpen
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_clock_rounded,
                                    size: 20,
                                    color:
                                        shiftOpen
                                            ? taj.accentFor(taj.success)
                                            : taj.textSecondary,
                                  ),
                                ),

                              if (cart.isNotEmpty) ...[
                                Text(
                                  '$itemCount منتج',
                                  style: TextStyle(
                                    color: taj.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: onClearCart,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                  ),
                                  label: const Text('مسح'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: taj.error.main,
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: taj.divider),

              // Cart items
              Expanded(
                child:
                    cart.isEmpty
                        ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 44,
                                  color: taj.textDisabled,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'سلة فارغة',
                                  style: TextStyle(
                                    color: taj.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'اضغط على منتج لإضافته',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: taj.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: cart.length,
                          itemBuilder: (_, i) {
                            final entry = cart.entries.elementAt(i);
                            final product = products.firstWhere(
                              (p) => p.id == entry.key,
                            );
                            return _CartItem(
                              product: product,
                              quantity: entry.value,
                              canChangePrice: canChangePrice,
                              isEditing: isEditingLine == entry.key,
                              unitPrice: priceOverrides[entry.key],
                              onIncrement: () => onIncrement(entry.key),
                              onDecrement: () => onDecrement(entry.key),
                              onRemove: () => onRemove(entry.key),
                              onEditLine: isProfessional ? onEditLine : null,
                            );
                          },
                        ),
              ),

              // Professional: Held orders quick-preview
              if (isProfessional && heldOrders.isNotEmpty)
                PosHeldOrdersBar(
                  heldOrders: heldOrders,
                  onRecallOrder: onRecallOrder,
                ),

              // Totals + Payment buttons (scrolls internally on short windows)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxFooterHeight),
                child: SingleChildScrollView(
                  child: _CartTotals(
                    subtotal: subtotal,
                    itemCount: itemCount,
                    isProfessional: isProfessional,
                    discountPercent: discountPercent,
                    onDiscountChanged: onDiscountChanged,
                    orderNote: orderNote,
                    onOrderNoteChanged: onOrderNoteChanged,
                    sessionSaleCount: sessionSaleCount,
                    sessionCashTotal: sessionCashTotal,
                    onPayCash: onPayCash,
                    onPayCredit: onPayCredit,
                    onPayBank: onPayBank,
                    onPaySadad: onPaySadad,
                    onPayNumoQr: onPayNumoQr,
                    onPayMobicash: onPayMobicash,
                    onPayBankTransfer: onPayBankTransfer,
                    onPayBankTransferSadad: onPayBankTransferSadad,
                    onPayBankTransferMobCash: onPayBankTransferMobCash,
                    onHoldOrder: onHoldOrder,
                    onSplitPayment: onSplitPayment,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Cart Item ────────────────────────────────────────────────────────────────

class _CartItem extends StatelessWidget {
  const _CartItem({
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.canChangePrice = true,
    this.isEditing = false,
    this.onEditLine,
    this.unitPrice,
  });

  final PosProduct product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final bool canChangePrice;
  final bool isEditing;
  final ValueChanged<String>? onEditLine;
  final double? unitPrice;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final effectiveUnit = unitPrice ?? product.price;
    final isOverridden = unitPrice != null && unitPrice != product.price;
    final lineTotal = effectiveUnit * quantity;

    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: 12,
        end: 12,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        children: [
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: taj.textPrimary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onEditLine != null)
                      GestureDetector(
                        onTap: () => onEditLine!(product.id),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: taj.textSecondary,
                        ),
                      ),
                  ],
                ),
                Text(
                  canChangePrice
                      ? '${arNum(effectiveUnit)} د.ل × $quantity'
                      : '× $quantity',
                  style: TextStyle(
                    color: isOverridden ? taj.primary.main : taj.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          _QuantityCounter(
            quantity: quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
          const SizedBox(width: 8),

          // Line total + remove
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                arDinar(lineTotal),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: taj.textPrimary,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: taj.error.main,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quantity Counter ─────────────────────────────────────────────────────────

class _QuantityCounter extends StatelessWidget {
  const _QuantityCounter({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Container(
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: taj.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove_rounded, onTap: onDecrement),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: taj.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          _QtyBtn(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: 16, color: taj.textSecondary),
      ),
    );
  }
}

// ── Cart Totals ──────────────────────────────────────────────────────────────

class _CartTotals extends StatelessWidget {
  const _CartTotals({
    required this.subtotal,
    required this.itemCount,
    required this.isProfessional,
    required this.discountPercent,
    required this.onDiscountChanged,
    required this.orderNote,
    required this.onOrderNoteChanged,
    required this.sessionSaleCount,
    required this.sessionCashTotal,
    required this.onPayCash,
    required this.onPayCredit,
    required this.onPayBank,
    required this.onPaySadad,
    required this.onPayNumoQr,
    required this.onPayMobicash,
    required this.onPayBankTransfer,
    required this.onPayBankTransferSadad,
    required this.onPayBankTransferMobCash,
    required this.onHoldOrder,
    required this.onSplitPayment,
  });

  final double subtotal;
  final int itemCount;
  final bool isProfessional;
  final double discountPercent;
  final ValueChanged<double> onDiscountChanged;
  final String orderNote;
  final ValueChanged<String> onOrderNoteChanged;
  final int sessionSaleCount;
  final double sessionCashTotal;
  final VoidCallback onPayCash;
  final VoidCallback onPayCredit;
  final VoidCallback onPayBank;
  final VoidCallback onPaySadad;
  final VoidCallback onPayNumoQr;
  final VoidCallback onPayMobicash;
  final VoidCallback onPayBankTransfer;
  final VoidCallback onPayBankTransferSadad;
  final VoidCallback onPayBankTransferMobCash;
  final VoidCallback onHoldOrder;
  final VoidCallback onSplitPayment;

  double get _discountedTotal =>
      subtotal * (1 - discountPercent.clamp(0, 100) / 100);

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final hasDiscount = discountPercent > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: taj.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Professional: Session summary (Z-report mini) ──
          if (isProfessional) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: taj.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: taj.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SessionStat(
                      icon: Icons.receipt_long_rounded,
                      label: 'مبيعات الجلسة',
                      value: '$sessionSaleCount',
                      valueColor: taj.textPrimary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: taj.divider,
                  ),
                  Expanded(
                    child: _SessionStat(
                      icon: Icons.payments_rounded,
                      label: 'نقد اليوم',
                      value: arDinar(sessionCashTotal),
                      valueColor: taj.accentFor(taj.success),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Subtotal (+ discount row)
          _TotalRow(label: 'المجموع', value: arDinar(subtotal)),
          if (hasDiscount) ...[
            _TotalRow(
              label: 'خصم ${arNum(discountPercent.round())}%',
              value: '- ${arDinar(subtotal - _discountedTotal)}',
              valueColor: taj.error.main,
            ),
          ],
          const SizedBox(height: 12),

          // ── Primary: one-tap cash sale — shows the amount being charged ──
          _PrimaryChargeButton(
            amount: _discountedTotal,
            enabled: itemCount != 0,
            onPressed: onPayCash,
          ),
          const SizedBox(height: 10),

          // ── Professional: quick-action toolbar (discount / note / hold / split) ──
          if (isProfessional) ...[
            Row(
              children: [
                Expanded(
                  child: _ProActionTile(
                    icon: Icons.percent_rounded,
                    label:
                        hasDiscount
                            ? '${arNum(discountPercent.round())}%'
                            : 'خصم',
                    active: hasDiscount,
                    activeSwatch: taj.success,
                    onTap:
                        itemCount == 0 ? null : () => _promptDiscount(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProActionTile(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'ملاحظة',
                    active: orderNote.isNotEmpty,
                    activeSwatch: taj.primary,
                    onTap: () => _promptNote(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProActionTile(
                    icon: Icons.pause_circle_outline_rounded,
                    label: 'حفظ',
                    active: false,
                    activeSwatch: taj.primary,
                    onTap: itemCount == 0 ? null : onHoldOrder,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProActionTile(
                    icon: Icons.call_split_rounded,
                    label: 'تقسيم',
                    active: false,
                    activeSwatch: taj.primary,
                    onTap: itemCount == 0 ? null : onSplitPayment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Other payment methods — neutral soft buttons, grouped for scanning ──
          Row(
            children: [
              Expanded(
                child: _PayButton(
                  label: 'آجل',
                  icon: Icons.credit_card_outlined,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayCredit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PayButton(
                  label: 'مصرفي',
                  icon: Icons.account_balance_outlined,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayBank,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PayButton(
                  label: 'سداد',
                  icon: Icons.phone_android_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPaySadad,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PayButton(
                  label: 'NUMO QR',
                  icon: Icons.qr_code_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayNumoQr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _PaySectionLabel(label: 'تحويلات ومحافظ'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PayButton(
                  label: 'MobiCash',
                  icon: Icons.account_balance_wallet_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayMobicash,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PayButton(
                  label: 'تحويل حساب',
                  icon: Icons.account_balance_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayBankTransfer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PayButton(
                  label: 'تحويل سداد',
                  icon: Icons.send_to_mobile_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayBankTransferSadad,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PayButton(
                  label: 'تحويل MobiCash',
                  icon: Icons.phone_android_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayBankTransferMobCash,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // More payment services link
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaymentServicesPanel(),
                  ),
                );
              },
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text(
                'عرض جميع خدمات الدفع الإلكترونية',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promptDiscount(BuildContext context) async {
    final controller = TextEditingController(
      text: discountPercent > 0 ? discountPercent.round().toString() : '',
    );
    final value = await showDialog<double>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('خصم على الفاتورة'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'نسبة الخصم %',
                border: OutlineInputBorder(),
                hintText: 'مثال: 10',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(
                      ctx,
                      double.tryParse(controller.text) ?? 0,
                    ),
                child: const Text('تطبيق'),
              ),
            ],
          ),
    );
    if (value != null) onDiscountChanged(value.clamp(0, 100).toDouble());
  }

  Future<void> _promptNote(BuildContext context) async {
    final controller = TextEditingController(text: orderNote);
    final value = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('ملاحظة الطلب'),
            content: TextField(
              controller: controller,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'تُطبع في إيصال الفاتورة',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, ''),
                child: const Text('مسح'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('حفظ'),
              ),
            ],
          ),
    );
    if (value != null) onOrderNoteChanged(value);
  }
}

/// The big primary tender button. A full-width success bar that also shows the
/// amount being charged on the trailing side — the single most-used control on
/// the till, sized for fast, confident taps (spec §7.5 "huge pay buttons").
class _PrimaryChargeButton extends StatelessWidget {
  const _PrimaryChargeButton({
    required this.amount,
    required this.enabled,
    required this.onPressed,
  });

  final double amount;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: taj.success.main,
          foregroundColor: taj.success.contrastText,
          disabledBackgroundColor: taj.success.main.withValues(alpha: 0.35),
          disabledForegroundColor: taj.success.contrastText.withValues(
            alpha: 0.6,
          ),
          padding: const EdgeInsetsDirectional.only(start: 18, end: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.payments_rounded, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'بيع نقداً',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              arDinar(amount),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// An equal-priority tender button — a neutral **soft** button (Minimals) with a
/// leading icon chip and label. Neutral grey by policy; methods are told apart
/// by their icon only (see [TajColors.neutralSwatch]).
class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final TajSwatch color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final enabled = onPressed != null;
    final iconColor = enabled ? taj.accentFor(color) : taj.textDisabled;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: taj.paper,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          hoverColor: taj.hover,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: taj.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: taj.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: iconColor),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: enabled ? taj.textPrimary : taj.textDisabled,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A thin captioned divider that groups the alternate tenders (wallets /
/// transfers) so the till operator can scan them apart from the common methods.
class _PaySectionLabel extends StatelessWidget {
  const _PaySectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: taj.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(height: 1, color: taj.divider)),
      ],
    );
  }
}

/// A compact session KPI cell (label stacked over value) used by the
/// professional Z-report mini strip. Both label and value ellipsize so the pair
/// of cells stays inside a phone-width cart sheet.
class _SessionStat extends StatelessWidget {
  const _SessionStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Row(
      children: [
        Icon(icon, size: 15, color: taj.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: taj.textSecondary),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A compact professional-mode action tile (discount / note / hold / split).
/// Sits in a single 4-up toolbar and lights up with a semantic accent when its
/// feature is active (e.g. a discount is applied or a note is attached).
class _ProActionTile extends StatelessWidget {
  const _ProActionTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeSwatch,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final TajSwatch activeSwatch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final enabled = onTap != null;
    final fg =
        !enabled
            ? taj.textDisabled
            : (active ? taj.accentFor(activeSwatch) : taj.textPrimary);
    final tint = activeSwatch.main.withValues(alpha: taj.isDark ? 0.20 : 0.10);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: taj.paper,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: taj.hover,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: active ? tint : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? activeSwatch.main : taj.divider,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: fg),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Row(
      children: [
        Text(label, style: TextStyle(color: taj.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: valueColor ?? taj.accentText,
          ),
        ),
      ],
    );
  }
}

// ── Held Orders Bar ──────────────────────────────────────────────────────────

class PosHeldOrdersBar extends StatelessWidget {
  const PosHeldOrdersBar({required this.heldOrders, required this.onRecallOrder, super.key,});
  final List<PosHeldOrder> heldOrders;
  final ValueChanged<PosHeldOrder> onRecallOrder;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: taj.background,
        border: Border(
          top: BorderSide(color: taj.divider),
          bottom: BorderSide(color: taj.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${heldOrders.length} طلب موقوف',
            style: TextStyle(
              color: taj.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final order in heldOrders)
                InkWell(
                  onTap: () => onRecallOrder(order),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: taj.neutral.lighter,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: taj.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restore_rounded,
                          size: 12,
                          color: taj.neutral.dark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.name,
                          style: TextStyle(
                            color: taj.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${order.itemCount} × ${arDinar(order.subtotal)}',
                          style: TextStyle(
                            color: taj.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
