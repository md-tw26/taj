import 'package:flutter/material.dart';

import '../../core/theme/taj_colors.dart';
import '../../core/responsive.dart';
import '../../core/format.dart';
import '../../core/user_role.dart';
import '../../shared/widgets/taj_ui.dart';

class MockProduct {
  const MockProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.icon,
    required this.status,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final IconData icon;
  final TajStatus status;
}

const _mockProducts = [
  MockProduct(id: 'p1', name: 'عود ملكي', category: 'عطور', price: 450, icon: Icons.spa_outlined, status: TajStatus.primary),
  MockProduct(id: 'p2', name: 'عطر المسك', category: 'عطور', price: 320, icon: Icons.local_florist_outlined, status: TajStatus.secondary),
  MockProduct(id: 'p3', name: 'بخور فاخر', category: 'بخور', price: 180, icon: Icons.local_fire_department_outlined, status: TajStatus.warning),
  MockProduct(id: 'p4', name: 'ماء الورد', category: 'زيوت', price: 60, icon: Icons.water_drop_outlined, status: TajStatus.info),
  MockProduct(id: 'p5', name: 'دهن العود', category: 'زيوت', price: 700, icon: Icons.opacity_outlined, status: TajStatus.primary),
  MockProduct(id: 'p6', name: 'عنبر', category: 'عطور', price: 540, icon: Icons.diamond_outlined, status: TajStatus.secondary),
  MockProduct(id: 'p7', name: 'مبخرة نحاس', category: 'هدايا', price: 240, icon: Icons.card_giftcard_outlined, status: TajStatus.success),
  MockProduct(id: 'p8', name: 'بخور معمول', category: 'بخور', price: 150, icon: Icons.grain_outlined, status: TajStatus.warning),
  MockProduct(id: 'p9', name: 'زيت الصندل', category: 'زيوت', price: 210, icon: Icons.eco_outlined, status: TajStatus.info),
  MockProduct(id: 'p10', name: 'طقم هدايا', category: 'هدايا', price: 380, icon: Icons.redeem_outlined, status: TajStatus.success),
  MockProduct(id: 'p11', name: 'مسك أبيض', category: 'عطور', price: 260, icon: Icons.brightness_5_outlined, status: TajStatus.secondary),
  MockProduct(id: 'p12', name: 'عود كمبودي', category: 'بخور', price: 820, icon: Icons.forest_outlined, status: TajStatus.warning),
];

const _categories = ['الكل', 'عطور', 'بخور', 'زيوت', 'هدايا'];

class MerchantPosScreen extends StatelessWidget {
  const MerchantPosScreen({
    super.key,
    required this.branchName,
    this.permissions = UserPermissions.merchant,
    required this.onLogout,
    required this.onToggleTheme,
  });

  final String branchName;
  final UserPermissions permissions;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Scaffold(
      backgroundColor: taj.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              branchName: branchName,
              onToggleTheme: onToggleTheme,
              onLogout: onLogout,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  // Two-pane when there's room for a comfortable catalog beside
                  // the invoice; the cart keeps a fixed width so it never
                  // stretches to absurd proportions on ultra-wide monitors.
                  if (c.maxWidth >= AppBreakpoints.splitPane) {
                    return Row(
                      children: [
                        const Expanded(child: _ProductCatalog()),
                        SizedBox(width: 380, child: _CartPanel()),
                      ],
                    );
                  }
                  // Narrow (phones / split windows): catalog fills the screen
                  // with the running total docked to the bottom.
                  return const Column(
                    children: [
                      Expanded(child: _ProductCatalog()),
                      _TotalsSection(subtotal: 0, count: 0),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopBar({
    required this.branchName,
    required this.onToggleTheme,
    required this.onLogout,
  });

  final String branchName;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      child: Row(
        children: [
          Icon(Icons.store_outlined, size: 20, color: taj.primary.main),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              branchName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: taj.textPrimary,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_outlined),
          ),
          IconButton(
            tooltip: 'الوضع الفاتح/الداكن',
            onPressed: onToggleTheme,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCatalog extends StatefulWidget {
  const _ProductCatalog();

  @override
  State<_ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<_ProductCatalog> {
  String _category = 'الكل';
  String _search = '';

  List<MockProduct> get _filtered => _mockProducts.where((p) {
        final catOk = _category == 'الكل' || p.category == _category;
        final searchOk = _search.isEmpty || p.name.contains(_search.trim());
        return catOk && searchOk;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    // Search, category chips and the grid live in a single scroll view so the
    // fixed-height chrome (search + chips) never forces a vertical overflow
    // when the catalog is squeezed into a short viewport (e.g. a phone in
    // landscape at 568×320); everything simply scrolls as one instead.
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      filled: true,
                      fillColor: taj.background,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('مسح'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = cat == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected ? taj.primary.main : taj.paper,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected ? taj.primary.main : taj.divider,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected
                            ? taj.primary.contrastText
                            : taj.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_filtered.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: TajEmptyState(
              icon: Icons.search_off_rounded,
              title: 'لا توجد منتجات',
              message: 'جرّب تصنيفًا آخر أو غيّر كلمة البحث.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisExtent: 172,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ProductCard(
                  product: _filtered[i],
                  onTap: () {},
                ),
                childCount: _filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final MockProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final swatch = taj.swatch(product.status);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: taj.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Flexible image area so the card adapts to the grid cell height
            // instead of overflowing when metrics push the content past a
            // fixed image height.
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: swatch.lighter,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  product.icon,
                  size: 36,
                  color: swatch.dark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: taj.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${arNum(product.price)} د.ل',
                    style: TextStyle(
                      color: taj.accentText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Container(
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(left: BorderSide(color: taj.divider)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 20, color: taj.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'الفاتورة',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: taj.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: taj.divider),
          // Centered empty-state that scrolls instead of overflowing when the
          // cart pane is short (e.g. a landscape phone / split window where the
          // totals section leaves little height for the placeholder).
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 64, color: taj.textDisabled),
                          const SizedBox(height: 16),
                          Text(
                            'السلة فارغة',
                            style: TextStyle(
                              color: taj.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'انقر على منتج لإضافته إلى الفاتورة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: taj.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _TotalsSection(subtotal: 0, count: 0),
        ],
      ),
    );
  }
}

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({required this.subtotal, required this.count});

  final double subtotal;
  final int count;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: taj.divider)),
      ),
      child: Column(
        children: [
          _TotalRow(label: 'المجموع الفرعي', value: arDinar(subtotal)),
          _TotalRow(label: 'الخصم', value: arDinar(0)),
          const SizedBox(height: 4),
          _TotalRow(
            label: 'الإجمالي',
            value: arDinar(subtotal),
            isTotal: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: count == 0 ? null : () {},
              style: FilledButton.styleFrom(
                backgroundColor: taj.primary.main,
                foregroundColor: taj.primary.contrastText,
                disabledBackgroundColor:
                    taj.primary.main.withValues(alpha: 0.4),
                disabledForegroundColor:
                    taj.primary.contrastText.withValues(alpha: 0.6),
              ),
              child: Text(
                count == 0
                    ? 'الدفع'
                    : 'الدفع • ${arDinar(subtotal)}',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: isTotal
                ? TextStyle(
                    color: taj.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )
                : TextStyle(
                    color: taj.textSecondary,
                    fontSize: 14,
                  ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? taj.accentText : null,
            ),
          ),
        ],
      ),
    );
  }
}
