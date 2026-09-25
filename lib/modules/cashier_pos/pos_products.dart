import 'package:flutter/material.dart';

import '../../core/theme/taj_colors.dart';
import '../../core/format.dart';
import 'pos_models.dart';

class PosProductSection extends StatelessWidget {
  const PosProductSection({
    required this.products,
    required this.cart,
    required this.isGridView,
    required this.searchQuery,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onProductTap,
    this.canChangePrice = true, super.key,});

  final List<PosProduct> products;
  final Map<String, int> cart;
  final bool isGridView;
  final String searchQuery;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onProductTap;
  final bool canChangePrice;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: onSearchChanged,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو الباركود...',
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              suffixIcon:
                  searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                          searchFocusNode.requestFocus();
                        },
                      )
                      : const Icon(Icons.qr_code_scanner_rounded, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: taj.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // Product list/grid
        Expanded(
          child:
              products.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: taj.textDisabled,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات',
                          style: TextStyle(
                            color: taj.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'جرّب البحث بالاسم أو الباركود',
                          style: TextStyle(
                            color: taj.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                  : isGridView
                  ? GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          mainAxisExtent: 110,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: products.length,
                    itemBuilder:
                        (_, i) => PosProductTile(
                          product: products[i],
                          quantityInCart: cart[products[i].id] ?? 0,
                          onTap: () => onProductTap(products[i].id),
                          canChangePrice: canChangePrice,
                        ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    itemBuilder:
                        (_, i) => PosProductListTile(
                          product: products[i],
                          quantityInCart: cart[products[i].id] ?? 0,
                          onTap: () => onProductTap(products[i].id),
                          canChangePrice: canChangePrice,
                        ),
                  ),
        ),
      ],
    );
  }
}

class PosProductTile extends StatelessWidget {
  const PosProductTile({
    required this.product,
    required this.quantityInCart,
    required this.onTap,
    this.canChangePrice = true, super.key,});

  final PosProduct product;
  final int quantityInCart;
  final VoidCallback onTap;
  final bool canChangePrice;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final categoryColor = tajCategoryColor(product.category, taj);
    final inCart = quantityInCart > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: taj.paper,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: inCart ? categoryColor.main : taj.divider,
              width: inCart ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon area — subtle category-tinted surface
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: categoryColor.lighter.withValues(
                      alpha: isDark ? 0.16 : 0.55,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    posCategoryIcon(product.category),
                    size: 28,
                    color: taj.accentFor(categoryColor),
                  ),
                ),
              ),

              // Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: taj.textPrimary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (canChangePrice)
                          Expanded(
                            child: Text(
                              '${arNum(product.price)} د.ل',
                              style: TextStyle(
                                color: taj.accentText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (inCart)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.main,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$quantityInCart',
                              style: TextStyle(
                                color: categoryColor.contrastText,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PosProductListTile extends StatelessWidget {
  const PosProductListTile({
    required this.product,
    required this.quantityInCart,
    required this.onTap,
    this.canChangePrice = true, super.key,});

  final PosProduct product;
  final int quantityInCart;
  final VoidCallback onTap;
  final bool canChangePrice;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = tajCategoryColor(product.category, taj);
    final inCart = quantityInCart > 0;

    return Material(
      color: taj.paper,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: inCart ? categoryColor.main : taj.divider,
              width: inCart ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Category icon chip
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: categoryColor.lighter.withValues(
                    alpha: isDark ? 0.18 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  posCategoryIcon(product.category),
                  size: 19,
                  color: taj.accentFor(categoryColor),
                ),
              ),
              const SizedBox(width: 12),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: taj.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Price (only if the user has the sales.change_price permission)
              if (canChangePrice)
                Text(
                  '${arNum(product.price)} د.ل',
                  style: TextStyle(
                    color: taj.accentText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

              // Quantity badge
              if (inCart) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.main,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$quantityInCart',
                    style: TextStyle(
                      color: categoryColor.contrastText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
