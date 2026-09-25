import 'package:flutter/material.dart';

import '../../core/theme/taj_colors.dart';
import '../../core/format.dart';
import 'pos_models.dart';
import 'pos_cart.dart';
import 'pos_products.dart';

// ── Wide Layout (Desktop) ────────────────────────────────────────────────────

class PosWideLayout extends StatelessWidget {
  const PosWideLayout({
    required this.products,
    required this.categories,
    required this.selectedCategory,
    required this.isSidebarCollapsed,
    required this.cart,
    required this.subtotal,
    required this.itemCount,
    required this.isGridView,
    required this.isProfessional,
    required this.canChangePrice,
    required this.heldOrders,
    required this.shiftOpen,
    required this.linkedCustomer,
    required this.isEditingLine,
    required this.searchQuery,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onToggleSidebar,
    required this.onAddToCart,
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
    required this.sessionCashTotal, super.key,});

  final List<PosProduct> products;
  final List<String> categories;
  final String selectedCategory;
  final bool isSidebarCollapsed;
  final Map<String, int> cart;
  final double subtotal;
  final int itemCount;
  final bool isGridView;
  final bool isProfessional;
  final bool canChangePrice;
  final List<PosHeldOrder> heldOrders;
  final bool shiftOpen;
  final String? linkedCustomer;
  final String? isEditingLine;
  final String searchQuery;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onToggleSidebar;
  final ValueChanged<String> onAddToCart;
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Category Sidebar (collapsible, like Odoo)
        _CategorySidebar(
          categories: categories,
          selectedCategory: selectedCategory,
          isCollapsed: isSidebarCollapsed,
          onCategoryChanged: onCategoryChanged,
          onToggleCollapse: onToggleSidebar,
        ),

        // Products (dominant area, ~56%)
        Expanded(
          flex: 5,
          child: PosProductSection(
            products: products,
            cart: cart,
            isGridView: isGridView,
            searchQuery: searchQuery,
            searchController: searchController,
            searchFocusNode: searchFocusNode,
            onSearchChanged: onSearchChanged,
            onProductTap: onAddToCart,
            canChangePrice: canChangePrice,
          ),
        ),

        // Cart / invoice (~44%, enlarged)
        Expanded(
          flex: 4,
          child: PosCartSection(
            products: products,
            lowStockCount: products.where((p) => p.stock <= 5).length,
            cart: cart,
            subtotal: subtotal,
            itemCount: itemCount,
            isProfessional: isProfessional,
            canChangePrice: canChangePrice,
            heldOrders: heldOrders,
            shiftOpen: shiftOpen,
            linkedCustomer: linkedCustomer,
            isEditingLine: isEditingLine,
            priceOverrides: priceOverrides,
            discountPercent: discountPercent,
            onDiscountChanged: onDiscountChanged,
            orderNote: orderNote,
            onOrderNoteChanged: onOrderNoteChanged,
            sessionSaleCount: sessionSaleCount,
            sessionCashTotal: sessionCashTotal,
            onRecallOrder: onRecallOrder,
            onLinkCustomer: onLinkCustomer,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            onRemove: onRemove,
            onClearCart: onClearCart,
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
            onPressShift: onPressShift,
            onEditLine: onEditLine,
          ),
        ),
      ],
    );
  }
}

// ── Category Sidebar (Odoo-style collapsible) ───────────────────────────────

class _CategorySidebar extends StatelessWidget {
  const _CategorySidebar({
    required this.categories,
    required this.selectedCategory,
    required this.isCollapsed,
    required this.onCategoryChanged,
    required this.onToggleCollapse,
  });

  final List<String> categories;
  final String selectedCategory;
  final bool isCollapsed;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 56 : 160,
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(left: BorderSide(color: taj.divider)),
      ),
      child: Column(
        children: [
          // Header with toggle
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 4 : 8,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: taj.divider)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onToggleCollapse,
                  icon: Icon(
                    isCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 20,
                  ),
                  tooltip: isCollapsed ? 'توسيع' : 'طي',
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'الفئات',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: taj.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Category list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final isSelected = cat == selectedCategory;
                final catColor = _categoryColor(cat, taj);

                return InkWell(
                  onTap: () => onCategoryChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCollapsed ? 0 : 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? catColor.lighter : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? catColor.main : Colors.transparent,
                        width: isSelected ? 2 : 0,
                      ),
                    ),
                    child:
                        isCollapsed
                            ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: catColor.main,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                            : Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: catColor.main,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? catColor.dark
                                              : taj.textPrimary,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TajSwatch _categoryColor(String category, TajColors taj) =>
      tajCategoryColor(category, taj);
}

// ── Narrow Layout (Mobile) ───────────────────────────────────────────────────

class PosNarrowLayout extends StatelessWidget {
  const PosNarrowLayout({
    required this.products,
    required this.categories,
    required this.selectedCategory,
    required this.cart,
    required this.subtotal,
    required this.itemCount,
    required this.isGridView,
    required this.isProfessional,
    required this.canChangePrice,
    required this.heldOrders,
    required this.shiftOpen,
    required this.linkedCustomer,
    required this.isEditingLine,
    required this.searchQuery,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onAddToCart,
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
    required this.sessionCashTotal, super.key,});

  final List<PosProduct> products;
  final List<String> categories;
  final String selectedCategory;
  final Map<String, int> cart;
  final double subtotal;
  final int itemCount;
  final bool isGridView;
  final bool isProfessional;
  final bool canChangePrice;
  final List<PosHeldOrder> heldOrders;
  final bool shiftOpen;
  final String? linkedCustomer;
  final String? isEditingLine;
  final String searchQuery;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onAddToCart;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category chips (horizontal scroll)
        _CategoryChips(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategoryChanged: onCategoryChanged,
        ),

        // Products
        Expanded(
          child: PosProductSection(
            products: products,
            cart: cart,
            isGridView: isGridView,
            searchQuery: searchQuery,
            searchController: searchController,
            searchFocusNode: searchFocusNode,
            onSearchChanged: onSearchChanged,
            onProductTap: onAddToCart,
            canChangePrice: canChangePrice,
          ),
        ),
        if (cart.isNotEmpty)
          _MobileCartBar(
            itemCount: itemCount,
            subtotal: subtotal,
            onTap: () => _showCartSheet(context),
          ),
      ],
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (ctx, controller) => PosCartSection(
                  products: products,
                  lowStockCount: products.where((p) => p.stock <= 5).length,
                  cart: cart,
                  subtotal: subtotal,
                  itemCount: itemCount,
                  isProfessional: isProfessional,
                  canChangePrice: canChangePrice,
                  heldOrders: heldOrders,
                  shiftOpen: shiftOpen,
                  linkedCustomer: linkedCustomer,
                  isEditingLine: isEditingLine,
                  priceOverrides: priceOverrides,
                  discountPercent: discountPercent,
                  onDiscountChanged: onDiscountChanged,
                  orderNote: orderNote,
                  onOrderNoteChanged: onOrderNoteChanged,
                  sessionSaleCount: sessionSaleCount,
                  sessionCashTotal: sessionCashTotal,
                  onRecallOrder: onRecallOrder,
                  onLinkCustomer: onLinkCustomer,
                  onIncrement: onIncrement,
                  onDecrement: onDecrement,
                  onRemove: onRemove,
                  onClearCart: onClearCart,
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
                  onPressShift: onPressShift,
                  onEditLine: onEditLine,
                  scrollController: controller,
                ),
          ),
    );
  }
}

// ── Mobile Cart Bar (Bottom bar on narrow screens) ─────────────────────────

class _MobileCartBar extends StatelessWidget {
  const _MobileCartBar({
    required this.itemCount,
    required this.subtotal,
    required this.onTap,
  });

  final int itemCount;
  final double subtotal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: taj.primary.main,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  '$itemCount منتج',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  arDinar(subtotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category Chips (Mobile horizontal) ──────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat == selectedCategory;
          final catColor = _categoryColor(cat, taj);

          return GestureDetector(
            onTap: () => onCategoryChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? catColor.main : taj.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? catColor.main : taj.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSelected) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: catColor.main,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat,
                    style: TextStyle(
                      color:
                          isSelected ? catColor.contrastText : taj.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  TajSwatch _categoryColor(String category, TajColors taj) =>
      tajCategoryColor(category, taj);
}
