import 'package:flutter/material.dart';

import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../core/responsive.dart';
import '../../shared/widgets/taj_ui.dart';

class _Product {
  const _Product(this.id, this.name, this.category, this.price, this.icon, this.status);
  final String id;
  final String name;
  final String category;
  final double price;
  final IconData icon;
  final TajStatus status; // drives the card's tint
}

const _catalog = <_Product>[
  _Product('p1', 'عود ملكي', 'عطور', 450, Icons.spa_outlined, TajStatus.primary),
  _Product('p2', 'عطر المسك', 'عطور', 320, Icons.local_florist_outlined, TajStatus.secondary),
  _Product('p3', 'بخور فاخر', 'بخور', 180, Icons.local_fire_department_outlined, TajStatus.warning),
  _Product('p4', 'ماء الورد', 'زيوت', 60, Icons.water_drop_outlined, TajStatus.info),
  _Product('p5', 'دهن العود', 'زيوت', 700, Icons.opacity_outlined, TajStatus.primary),
  _Product('p6', 'عنبر', 'عطور', 540, Icons.diamond_outlined, TajStatus.secondary),
  _Product('p7', 'مبخرة نحاس', 'هدايا', 240, Icons.card_giftcard_outlined, TajStatus.success),
  _Product('p8', 'بخور معمول', 'بخور', 150, Icons.grain_outlined, TajStatus.warning),
  _Product('p9', 'زيت الصندل', 'زيوت', 210, Icons.eco_outlined, TajStatus.info),
  _Product('p10', 'طقم هدايا', 'هدايا', 380, Icons.redeem_outlined, TajStatus.success),
  _Product('p11', 'مسك أبيض', 'عطور', 260, Icons.brightness_5_outlined, TajStatus.secondary),
  _Product('p12', 'عود كمبودي', 'بخور', 820, Icons.forest_outlined, TajStatus.warning),
];

const _categories = ['الكل', 'عطور', 'بخور', 'زيوت', 'هدايا'];

/// Point of Sale (spec 7.5): touch-first catalog + a gold-standard cart.
/// Price is display-only (locked); the register is optimised for speed.
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final Map<String, int> _qty = {};
  String _category = 'الكل';
  String _search = '';

  List<_Product> get _filtered => _catalog.where((p) {
        final catOk = _category == 'الكل' || p.category == _category;
        final searchOk = _search.isEmpty || p.name.contains(_search.trim());
        return catOk && searchOk;
      }).toList();

  double get _subtotal =>
      _qty.entries.fold(0, (s, e) => s + _byId(e.key).price * e.value);
  int get _count => _qty.values.fold(0, (s, v) => s + v);

  _Product _byId(String id) => _catalog.firstWhere((p) => p.id == id);

  void _add(String id) => setState(() => _qty[id] = (_qty[id] ?? 0) + 1);
  void _dec(String id) => setState(() {
        final n = (_qty[id] ?? 0) - 1;
        if (n <= 0) {
          _qty.remove(id);
        } else {
          _qty[id] = n;
        }
      });
  void _clear() => setState(_qty.clear);

  void _pay() {
    if (_count == 0) return;
    showDialog(
      context: context,
      builder: (_) => _PaymentSuccessDialog(total: _subtotal, items: _count),
    ).then((_) => _clear());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= AppBreakpoints.splitPane;
        final catalog = _Catalog(
          products: _filtered,
          qty: _qty,
          category: _category,
          onCategory: (v) => setState(() => _category = v),
          onSearch: (v) => setState(() => _search = v),
          onAdd: _add,
        );

        if (wide) {
          return Row(
            children: [
              Expanded(child: catalog),
              SizedBox(
                width: 360,
                child: _CartPanel(
                  qty: _qty,
                  byId: _byId,
                  subtotal: _subtotal,
                  count: _count,
                  onAdd: _add,
                  onDec: _dec,
                  onClear: _clear,
                  onPay: _pay,
                ),
              ),
            ],
          );
        }

        // Phone: catalog + a checkout bar that opens the cart sheet.
        return Scaffold(
          body: catalog,
          bottomNavigationBar: _CheckoutBar(
            count: _count,
            total: _subtotal,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => FractionallySizedBox(
                heightFactor: 0.85,
                child: _CartPanel(
                  qty: _qty,
                  byId: _byId,
                  subtotal: _subtotal,
                  count: _count,
                  onAdd: _add,
                  onDec: _dec,
                  onClear: _clear,
                  onPay: () {
                    Navigator.of(context).pop();
                    _pay();
                  },
                  sheet: true,
                ),
              ),
            ).then((_) => setState(() {})),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Catalog
// ---------------------------------------------------------------------------

class _Catalog extends StatelessWidget {
  const _Catalog({
    required this.products,
    required this.qty,
    required this.category,
    required this.onCategory,
    required this.onSearch,
    required this.onAdd,
  });

  final List<_Product> products;
  final Map<String, int> qty;
  final String category;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onSearch,
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن منتج…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('مسح'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final selected = cat == category;
              return GestureDetector(
                onTap: () => onCategory(cat),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected ? taj.primary.main : taj.paper,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: selected ? taj.primary.main : taj.divider),
                  ),
                  child: Text(cat,
                      style: TextStyle(
                        color: selected
                            ? taj.primary.contrastText
                            : taj.textSecondary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? const TajEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'لا توجد منتجات',
                  message: 'جرّب تصنيفًا آخر أو غيّر كلمة البحث.')
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisExtent: 176,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => _ProductCard(
                    product: products[i],
                    qty: qty[products[i].id] ?? 0,
                    onAdd: () => onAdd(products[i].id),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.qty, required this.onAdd});
  final _Product product;
  final int qty;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final swatch = taj.swatch(product.status);
    final text = Theme.of(context).textTheme;

    return TajCard(
      padding: EdgeInsets.zero,
      onTap: onAdd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(color: swatch.lighter),
                  alignment: Alignment.center,
                  child: Icon(product.icon, size: 40, color: swatch.dark),
                ),
                if (qty > 0)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: taj.primary.main, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      alignment: Alignment.center,
                      child: Text('$qty',
                          style: TextStyle(
                              color: taj.primary.contrastText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${_fmt(product.price)} د.ل',
                    style: AppThemes.numeralStyle(context,
                        fontSize: 14, color: taj.accentText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart
// ---------------------------------------------------------------------------

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.qty,
    required this.byId,
    required this.subtotal,
    required this.count,
    required this.onAdd,
    required this.onDec,
    required this.onClear,
    required this.onPay,
    this.sheet = false,
  });

  final Map<String, int> qty;
  final _Product Function(String) byId;
  final double subtotal;
  final int count;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onDec;
  final VoidCallback onClear;
  final VoidCallback onPay;
  final bool sheet;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final ids = qty.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: sheet
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : null,
        border: sheet
            ? null
            : Border(right: BorderSide(color: taj.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (sheet)
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: taj.divider, borderRadius: BorderRadius.circular(2)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 20, color: taj.textSecondary),
                  const SizedBox(width: 8),
                  Text('الفاتورة', style: text.titleMedium),
                  const Spacer(),
                  if (count > 0)
                    TextButton(onPressed: onClear, child: const Text('إفراغ')),
                ],
              ),
            ),
            Divider(height: 1, color: taj.divider),
            Expanded(
              child: ids.isEmpty
                  ? const TajEmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'السلة فارغة',
                      message: 'اختر منتجًا لبدء الفاتورة.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: ids.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final p = byId(ids[i]);
                        final q = qty[p.id]!;
                        return _CartLine(
                          product: p,
                          qty: q,
                          onAdd: () => onAdd(p.id),
                          onDec: () => onDec(p.id),
                        );
                      },
                    ),
            ),
            _Totals(subtotal: subtotal),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton(
                  onPressed: count == 0 ? null : onPay,
                  child: Text(
                    count == 0
                        ? 'الدفع'
                        : 'الدفع • ${_fmt(subtotal)} د.ل',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onDec,
  });
  final _Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final swatch = taj.swatch(product.status);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: swatch.lighter,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(product.icon, size: 20, color: swatch.dark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text('${_fmt(product.price)} د.ل',
                  style: AppThemes.numeralStyle(context,
                      fontSize: 12, fontWeight: FontWeight.w400, color: taj.textSecondary)),
            ],
          ),
        ),
        _QtyStepper(qty: qty, onAdd: onAdd, onDec: onDec),
      ],
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.qty, required this.onAdd, required this.onDec});
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    Widget btn(IconData icon, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: taj.accentText),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: taj.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove_rounded, onDec),
          SizedBox(
            width: 24,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: AppThemes.numeralStyle(context, fontSize: 14)),
          ),
          btn(Icons.add_rounded, onAdd),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.subtotal});
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    Widget row(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Text(label,
                  style: strong
                      ? text.titleMedium
                      : text.bodyMedium?.copyWith(color: taj.textSecondary)),
              const Spacer(),
              Text('$value د.ل',
                  style: AppThemes.numeralStyle(context,
                      fontSize: strong ? 20 : 14,
                      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                      color: strong ? taj.accentText : null)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: taj.divider)),
      ),
      child: Column(
        children: [
          row('المجموع الفرعي', _fmt(subtotal)),
          row('الخصم', _fmt(0)),
          const SizedBox(height: 4),
          row('الإجمالي', _fmt(subtotal), strong: true),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.count, required this.total, required this.onTap});
  final int count;
  final double total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final onPrimary = taj.primary.contrastText;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: count == 0 ? null : onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: onPrimary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$count',
                      style: TextStyle(
                          color: onPrimary, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Text('عرض الفاتورة • ${_fmt(total)} د.ل',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                if (count == 0)
                  const SizedBox.shrink()
                else
                  Icon(Icons.keyboard_arrow_up_rounded, color: onPrimary.withValues(alpha: 0.9)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentSuccessDialog extends StatelessWidget {
  const _PaymentSuccessDialog({required this.total, required this.items});
  final double total;
  final int items;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: taj.success.lighter, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, size: 40, color: taj.success.dark),
            ),
            const SizedBox(height: 16),
            Text('تم الدفع بنجاح', style: text.titleLarge),
            const SizedBox(height: 6),
            Text('$items عناصر • ${_fmt(total)} د.ل',
                style: AppThemes.numeralStyle(context, fontSize: 15, color: taj.textSecondary)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('طباعة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('فاتورة جديدة'),
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

String _fmt(double v) {
  // Group thousands with Arabic thousands separator; drop trailing .0
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('٬');
    buf.write(s[i]);
  }
  // Map Latin digits to Arabic-Indic for a native look.
  const west = '0123456789';
  const east = '٠١٢٣٤٥٦٧٨٩';
  final out = StringBuffer();
  for (final ch in buf.toString().split('')) {
    final idx = west.indexOf(ch);
    out.write(idx >= 0 ? east[idx] : ch);
  }
  return out.toString();
}

