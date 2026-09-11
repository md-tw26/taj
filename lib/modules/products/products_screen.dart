import 'package:flutter/material.dart';

import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_provider.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_filters.dart';
import '../../shared/widgets/taj_table.dart';
import '../../shared/widgets/taj_ui.dart';

class Product {
  const Product(
    this.id,
    this.name,
    this.barcode,
    this.category,
    this.price,
    this.cost,
    this.stock,
    this.icon,
    this.tint,
  );
  final String id;
  final String name;
  final String barcode;
  final String category;
  final double price;
  final double cost;
  final int stock;
  final IconData icon;
  final TajStatus tint;

  (String, TajStatus) get status =>
      stock == 0
          ? ('نفد', TajStatus.error)
          : stock <= 5
          ? ('منخفض', TajStatus.warning)
          : ('متوفر', TajStatus.success);
}

const _categories = ['الكل', 'عطور', 'بخور', 'زيوت', 'هدايا'];

/// Products / Items (spec 7.2): Stripe table ⇄ Notion grid, ClickUp filters,
/// instant search, and a tabbed item detail that peeks in from the side.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _grid = false;
  String _search = '';
  String _category = 'الكل';
  Product? _selected;

  List<Product> get _storeProducts =>
      DemoStoreProvider.of(context).products
          .map(
            (p) => Product(
              p.id,
              p.name,
              p.barcode,
              p.category,
              p.price,
              p.cost,
              p.stock,
              demoIcon(p.iconCode),
              TajStatus.primary,
            ),
          )
          .toList();

  List<Product> get _filtered =>
      _storeProducts.where((p) {
        final catOk = _category == 'الكل' || p.category == _category;
        final sOk =
            _search.isEmpty ||
            p.name.contains(_search.trim()) ||
            p.barcode.contains(_search.trim());
        return catOk && sOk;
      }).toList();

  void _openItem(Product p) {
    setState(() => _selected = p);
    _scaffoldKey.currentState?.openEndDrawer();
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
    final products = _storeProducts;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      endDrawer:
          _selected == null
              ? null
              : Drawer(
                width: drawerWidth(context, desired: 440),
                backgroundColor: taj.paper,
                child: _ItemDetail(
                  product: _selected!,
                  onEdit: () => _showProductForm(context, _selected),
                  onDelete: () => _deleteProduct(context, _selected!),
                ),
              ),
      body: LayoutBuilder(
        builder: (context, c) {
          final pad = pagePaddingForWidth(c.maxWidth);
          final items = _filtered;
          return PageContainer(
            child: ListView(
              padding: EdgeInsets.all(pad),
              children: [
                SectionHeading(
                  title: 'الأصناف',
                  subtitle:
                      '${products.length} صنف • ${_lowCount()} منخفض/نافد',
                  trailing: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _ViewToggle(
                        grid: _grid,
                        onChanged: (v) => setState(() => _grid = v),
                      ),
                      FilledButton.icon(
                        onPressed: () => _showProductForm(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('إضافة صنف'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _Toolbar(
                  category: _category,
                  onCategory: (v) => setState(() => _category = v),
                  onSearch: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: TajEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'لا توجد أصناف',
                      message: 'غيّر التصنيف أو كلمة البحث.',
                    ),
                  )
                else if (_grid)
                  _Grid(products: items, onTap: _openItem)
                else
                  TajCard(
                    padding: EdgeInsets.zero,
                    child: TajTable(
                      columns: const [
                        TajColumn('الصنف', flex: 5),
                        TajColumn('التصنيف', flex: 2),
                        TajColumn('السعر', flex: 2, numeric: true),
                        TajColumn('المخزون', flex: 2, numeric: true),
                        TajColumn('الحالة', flex: 2),
                      ],
                      rows: [for (final p in items) _row(context, p)],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _lowCount() => _storeProducts.where((p) => p.stock <= 5).length;

  Future<void> _showProductForm(
    BuildContext context, [
    Product? existing,
  ]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final price = TextEditingController(text: existing?.price.toString() ?? '');
    final stock = TextEditingController(
      text: existing?.stock.toString() ?? '0',
    );
    final result = await showDialog<(String, double, int)>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(existing == null ? 'إضافة صنف' : 'تعديل الصنف'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'اسم الصنف'),
                ),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سعر البيع'),
                ),
                TextField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المخزون'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final parsedPrice =
                      double.tryParse(price.text) ?? existing?.price ?? 0;
                  final parsedStock =
                      int.tryParse(stock.text) ?? existing?.stock ?? 0;
                  if (name.text.trim().isNotEmpty)
                    Navigator.pop(dialogContext, (
                      name.text.trim(),
                      parsedPrice,
                      parsedStock,
                    ));
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
    );
    name.dispose();
    price.dispose();
    stock.dispose();
    if (result == null || !mounted) return;
    final store = DemoStoreProvider.of(context);
    final source =
        existing == null
            ? DemoProduct(
              id: 'p${DateTime.now().millisecondsSinceEpoch}',
              name: result.$1,
              barcode: 'demo-${DateTime.now().millisecondsSinceEpoch}',
              category: 'عام',
              price: result.$2,
              cost: result.$2 * .7,
              stock: result.$3,
              reorderLevel: 5,
            )
            : store.products
                .firstWhere((p) => p.id == existing.id)
                .copyWith(name: result.$1, price: result.$2, stock: result.$3);
    await store.upsertProduct(source);
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ الصنف')));
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('حذف الصنف؟'),
            content: Text('سيتم حذف «${product.name}» من قائمة الأصناف.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حذف'),
              ),
            ],
          ),
    );
    if (confirmed == true && mounted) {
      await DemoStoreProvider.of(context).deleteProduct(product.id);
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  TajRowData _row(BuildContext context, Product p) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final (label, status) = p.status;
    final swatch = taj.swatch(p.tint);
    return TajRowData(
      onTap: () => _openItem(p),
      actions: [
        Icon(Icons.more_horiz_rounded, size: 18, color: taj.textSecondary),
      ],
      cells: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: swatch.lighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(p.icon, size: 20, color: swatch.dark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    p.barcode,
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
        Text(p.category, style: text.bodyMedium),
        Text(
          '${_n(p.price)} د.ل',
          style: AppThemes.numeralStyle(context, fontSize: 14),
        ),
        Text(
          _n(p.stock.toDouble()),
          style: AppThemes.numeralStyle(context, fontSize: 14),
        ),
        StatusBadge(label: label, status: status),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.category,
    required this.onCategory,
    required this.onSearch,
  });
  final String category;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: onSearch,
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو الباركود…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TajFilterBar(
          filters: [
            if (category != 'الكل')
              TajFilter(field: 'التصنيف', operator: 'هو', value: category),
          ],
          onClearAll: () => onCategory('الكل'),
          onAdd: () {},
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final selected = cat == category;
              final taj = context.taj;
              return GestureDetector(
                onTap: () => onCategory(cat),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected ? taj.primary.lighter : taj.paper,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? taj.primary.main : taj.divider,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? taj.primary.dark : taj.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.grid, required this.onChanged});
  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    Widget seg(IconData icon, bool isGrid) {
      final selected = grid == isGrid;
      return GestureDetector(
        onTap: () => onChanged(isGrid),
        child: Container(
          width: 40,
          height: 36,
          decoration: BoxDecoration(
            color: selected ? taj.paper : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected ? AppThemes.cardShadow(context) : null,
          ),
          child: Icon(
            icon,
            size: 19,
            color: selected ? taj.primary.dark : taj.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: taj.divider),
      ),
      child: Row(
        children: [
          seg(Icons.view_list_rounded, false),
          seg(Icons.grid_view_rounded, true),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.products, required this.onTap});
  final List<Product> products;
  final ValueChanged<Product> onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        final swatch = taj.swatch(p.tint);
        final (label, status) = p.status;
        return TajCard(
          padding: EdgeInsets.zero,
          onTap: () => onTap(p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: swatch.lighter),
                  alignment: Alignment.center,
                  child: Icon(p.icon, size: 44, color: swatch.dark),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${_n(p.price)} د.ل',
                          style: AppThemes.numeralStyle(
                            context,
                            fontSize: 14,
                            color: taj.accentText,
                          ),
                        ),
                        const Spacer(),
                        StatusBadge(label: label, status: status),
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
}

// ---------------------------------------------------------------------------
// Item detail (peek) with tabs
// ---------------------------------------------------------------------------

class _ItemDetail extends StatelessWidget {
  const _ItemDetail({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final swatch = taj.swatch(product.tint);
    final (label, status) = product.status;

    return DefaultTabController(
      length: 5,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: swatch.lighter,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(product.icon, size: 28, color: swatch.dark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: text.titleLarge),
                        const SizedBox(height: 4),
                        StatusBadge(label: label, status: status),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: taj.accentText,
              unselectedLabelColor: taj.textSecondary,
              indicatorColor: taj.primary.main,
              tabs: const [
                Tab(text: 'عام'),
                Tab(text: 'الأسعار'),
                Tab(text: 'المخزون'),
                Tab(text: 'الخصائص'),
                Tab(text: 'السجل'),
              ],
            ),
            Divider(height: 1, color: taj.divider),
            Expanded(
              child: TabBarView(
                children: [
                  _GeneralTab(product: product),
                  _PricesTab(product: product),
                  _StockTab(product: product),
                  const _VariantsTab(),
                  const _HistoryTab(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDelete,
                      child: const Text('حذف'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('تعديل'),
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

class _KeyVal extends StatelessWidget {
  const _KeyVal(this.label, this.value, {this.numeric = false});
  final String label;
  final String value;
  final bool numeric;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(
            label,
            style: text.bodyMedium?.copyWith(color: taj.textSecondary),
          ),
          const Spacer(),
          numeric
              ? Text(
                value,
                style: AppThemes.numeralStyle(context, fontSize: 14),
              )
              : Text(
                value,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
        ],
      ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _KeyVal('الباركود', product.barcode, numeric: true),
        Divider(height: 1, color: taj.divider),
        _KeyVal('التصنيف', product.category),
        Divider(height: 1, color: taj.divider),
        _KeyVal('سعر البيع', '${_n(product.price)} د.ل', numeric: true),
        Divider(height: 1, color: taj.divider),
        _KeyVal('التكلفة', '${_n(product.cost)} د.ل', numeric: true),
        Divider(height: 1, color: taj.divider),
        _KeyVal(
          'هامش الربح',
          '${_n(product.price - product.cost)} د.ل',
          numeric: true,
        ),
        Divider(height: 1, color: taj.divider),
        _KeyVal('المخزون الحالي', _n(product.stock.toDouble()), numeric: true),
      ],
    );
  }
}

class _PricesTab extends StatelessWidget {
  const _PricesTab({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final tiers = [
      ('تجزئة', product.price),
      ('نصف جملة', product.price * 0.9),
      ('جملة', product.price * 0.82),
    ];
    final taj = context.taj;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final (name, price) in tiers) ...[
          _KeyVal(name, '${_n(price)} د.ل', numeric: true),
          Divider(height: 1, color: taj.divider),
        ],
      ],
    );
  }
}

class _StockTab extends StatelessWidget {
  const _StockTab({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final wh = [
      ('المستودع الرئيسي', (product.stock * 0.6).round()),
      ('فرع طرابلس', (product.stock * 0.3).round()),
      (
        'فرع بنغازي',
        product.stock -
            (product.stock * 0.6).round() -
            (product.stock * 0.3).round(),
      ),
    ];
    final taj = context.taj;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final (name, qty) in wh) ...[
          _KeyVal(name, _n(qty.toDouble()), numeric: true),
          Divider(height: 1, color: taj.divider),
        ],
      ],
    );
  }
}

class _VariantsTab extends StatelessWidget {
  const _VariantsTab();
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    Widget group(String title, List<String> values) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: taj.paper,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: taj.divider),
                ),
                child: Text(v, style: text.bodyMedium),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        group('الحجم', ['30 مل', '50 مل', '100 مل']),
        group('التعبئة', ['علبة', 'زجاجة', 'طقم']),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context) {
    final moves = [
      ('2026/07/18', 'بيع', -3, 24, TajStatus.error),
      ('2026/07/16', 'شراء', 20, 27, TajStatus.success),
      ('2026/07/12', 'تسوية جرد', -1, 7, TajStatus.warning),
      ('2026/07/10', 'بيع', -5, 8, TajStatus.error),
    ];
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: moves.length,
      separatorBuilder: (_, __) => Divider(height: 16, color: taj.divider),
      itemBuilder: (_, i) {
        final (date, type, delta, balance, status) = moves[i];
        final swatch = taj.swatch(status);
        return Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: swatch.lighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                delta >= 0
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                size: 18,
                color: swatch.dark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    date,
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
            Text(
              '${delta > 0 ? '+' : ''}${_n(delta.toDouble())}',
              style: AppThemes.numeralStyle(
                context,
                fontSize: 14,
                color: swatch.dark,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '=${_n(balance.toDouble())}',
              style: AppThemes.numeralStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: taj.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Number → grouped Arabic-Indic digits.
String _n(double v) {
  final s =
      v == v.roundToDouble()
          ? v.abs().toStringAsFixed(0)
          : v.abs().toStringAsFixed(2);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('٬');
    buf.write(s[i]);
  }
  const west = '0123456789';
  const east = '0123456789';
  final out = StringBuffer();
  if (v < 0) out.write('-');
  for (final ch in buf.toString().split('')) {
    final idx = west.indexOf(ch);
    out.write(idx >= 0 ? east[idx] : ch);
  }
  return out.toString();
}
