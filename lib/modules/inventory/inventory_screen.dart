import 'package:flutter/material.dart';

import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_provider.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_filters.dart';
import '../../shared/widgets/taj_table.dart';
import '../../shared/widgets/taj_ui.dart';

class _Item {
  const _Item(
    this.name,
    this.price,
    this.book,
    this.seeded,
    this.icon, [
    this.id = '',
  ]);
  final String id;
  final String name;
  final double price;
  final int book; // system / book quantity
  final int seeded; // pre-counted actual (demo)
  final IconData icon;
}

const _items = <_Item>[
  _Item('عود ملكي', 450, 24, 22, Icons.spa_outlined),
  _Item('عطر المسك', 320, 3, 3, Icons.local_florist_outlined),
  _Item('بخور فاخر', 180, 57, 60, Icons.local_fire_department_outlined),
  _Item('دهن العود', 700, 12, 11, Icons.opacity_outlined),
  _Item('عنبر', 540, 2, 2, Icons.diamond_outlined),
  _Item('مبخرة نحاس', 240, 18, 20, Icons.card_giftcard_outlined),
  _Item('زيت الصندل', 210, 5, 5, Icons.eco_outlined),
];

enum _Phase { scan, compare }

/// Inventory & Stocktake (spec 7.3): scan-count with a live counter, then a
/// book-vs-actual compare with a smart suggestion and one-tap adjustment.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  _Phase _phase = _Phase.scan;
  final _scanCtrl = TextEditingController();
  bool _initialized = false;
  Map<String, int> _counted = {};

  List<_Item> get _storeItems =>
      DemoStoreProvider.of(context).products
          .map(
            (p) => _Item(
              p.name,
              p.price,
              p.stock,
              p.stock,
              demoIcon(p.iconCode),
              p.id,
            ),
          )
          .toList();

  List<_Item> get _activeItems => _storeItems.isEmpty ? _items : _storeItems;

  int get _totalCounted => _counted.values.fold(0, (s, v) => s + v);
  int get _distinct => _counted.values.where((v) => v > 0).length;

  int _diff(_Item i) => (_counted[i.name] ?? i.book) - i.book;
  int get _deficit =>
      _activeItems.fold(0, (s, i) => s + (_diff(i) < 0 ? -_diff(i) : 0));
  int get _surplus =>
      _activeItems.fold(0, (s, i) => s + (_diff(i) > 0 ? _diff(i) : 0));
  double get _netValue =>
      _activeItems.fold(0, (s, i) => s + _diff(i) * i.price);
  bool get _hasDiff => _activeItems.any((i) => _diff(i) != 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _counted = {for (final i in _activeItems) i.name: i.seeded};
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  void _scan(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final match = _activeItems.where((i) => i.name.contains(q));
    if (match.isNotEmpty) {
      setState(
        () => _counted[match.first.name] = _counted[match.first.name]! + 1,
      );
    }
    _scanCtrl.clear();
  }

  void _bump(String name, int delta) => setState(() {
    final v = (_counted[name]! + delta).clamp(0, 9999);
    _counted[name] = v;
  });

  Future<void> _approve() async {
    final store = DemoStoreProvider.of(context);
    for (final item in _activeItems) {
      final delta = _diff(item);
      if (delta != 0 && item.id.isNotEmpty)
        await store.adjustStock(item.id, delta);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.taj.success.dark,
        content: const Text('تم اعتماد التسوية وتحديث المخزون'),
      ),
    );
    setState(() {
      for (final i in _activeItems) {
        _counted[i.name] = i.book;
      }
      _phase = _Phase.scan;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final pad = pagePaddingForWidth(c.maxWidth);
        return PageContainer(
          child: ListView(
            padding: EdgeInsets.all(pad),
            children: [
              SectionHeading(
                title: 'جرد المخزون',
                subtitle:
                    _phase == _Phase.scan
                        ? 'جلسة جرد — المستودع الرئيسي'
                        : 'مقارنة الفعلي بالدفتري',
                trailing:
                    _phase == _Phase.compare
                        ? OutlinedButton.icon(
                          onPressed: () => setState(() => _phase = _Phase.scan),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: const Text('رجوع للجرد'),
                        )
                        : null,
              ),
              const SizedBox(height: 20),
              if (_phase == _Phase.scan)
                ..._scanView(context)
              else
                ..._compareView(context),
            ],
          ),
        );
      },
    );
  }

  // ---- Scan phase ----
  List<Widget> _scanView(BuildContext context) {
    final taj = context.taj;
    return [
      const TajFilterBar(
        filters: [
          TajFilter(field: 'المستودع', operator: 'هو', value: 'الرئيسي'),
          TajFilter(field: 'الفرع', operator: 'هو', value: 'طرابلس'),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: KpiCard(
              label: 'إجمالي الممسوح',
              value: _n(_totalCounted.toDouble()),
              icon: Icons.qr_code_scanner_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: KpiCard(
              label: 'أصناف مميّزة',
              value: _n(_distinct.toDouble()),
              icon: Icons.category_outlined,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TajCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.barcode_reader, size: 20, color: taj.accentText),
                const SizedBox(width: 8),
                Text(
                  'مسح باركود',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _scanCtrl,
              onSubmitted: _scan,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'امسح أو اكتب اسم الصنف ثم Enter…',
                prefixIcon: const Icon(Icons.qr_code_2_rounded),
                suffixIcon: IconButton(
                  onPressed: () => _scan(_scanCtrl.text),
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      TajCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < _activeItems.length; i++) ...[
              if (i > 0) Divider(height: 1, color: taj.divider),
              _CountRow(
                item: _activeItems[i],
                count: _counted[_activeItems[i].name]!,
                onAdd: () => _bump(_activeItems[i].name, 1),
                onDec: () => _bump(_activeItems[i].name, -1),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: () => setState(() => _phase = _Phase.compare),
          icon: const Icon(Icons.compare_arrows_rounded),
          label: const Text('إنهاء الجرد والمقارنة'),
        ),
      ),
    ];
  }

  // ---- Compare phase ----
  List<Widget> _compareView(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    if (!_hasDiff) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 40),
          child: TajEmptyState(
            icon: Icons.verified_outlined,
            title: 'لا توجد فروقات',
            message: 'الجرد الفعلي مطابق للمخزون الدفتري تمامًا.',
          ),
        ),
      ];
    }

    return [
      // Smart suggestion (info).
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: taj.info.lighter,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: taj.info.dark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اقتراح ذكي',
                    style: text.titleSmall?.copyWith(color: taj.info.darker),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الفروقات قد تعود إلى مبيعات غير مُسجّلة أو تلف. راجع البنود ثم اعتمد التسوية بضغطة واحدة.',
                    style: text.bodyMedium?.copyWith(
                      color: taj.info.darker,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _MiniStat(
              label: 'عجز',
              value: _n(_deficit.toDouble()),
              status: TajStatus.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniStat(
              label: 'زيادة',
              value: _n(_surplus.toDouble()),
              status: TajStatus.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniStat(
              label: 'صافي القيمة',
              value: '${_n(_netValue)} د.ل',
              status: _netValue < 0 ? TajStatus.error : TajStatus.success,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TajCard(
        padding: EdgeInsets.zero,
        child: TajTable(
          columns: const [
            TajColumn('الصنف', flex: 4),
            TajColumn('الدفتري', flex: 2, numeric: true),
            TajColumn('الفعلي', flex: 2, numeric: true),
            TajColumn('الفرق', flex: 2, numeric: true),
            TajColumn('القيمة', flex: 3, numeric: true),
          ],
          rows: [
            for (final i in _activeItems)
              if (_diff(i) != 0) _compareRow(context, i),
          ],
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: () => _approve(),
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('اعتماد التسوية'),
        ),
      ),
    ];
  }

  TajRowData _compareRow(BuildContext context, _Item i) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final d = _diff(i);
    final status = d < 0 ? TajStatus.error : TajStatus.info;
    final swatch = taj.swatch(status);
    return TajRowData(
      cells: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: taj.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(i.icon, size: 18, color: taj.textSecondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                i.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        Text(
          _n(i.book.toDouble()),
          style: AppThemes.numeralStyle(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: taj.textSecondary,
          ),
        ),
        Text(
          _n((_counted[i.name] ?? i.book).toDouble()),
          style: AppThemes.numeralStyle(context, fontSize: 14),
        ),
        Text(
          '${d > 0 ? '+' : ''}${_n(d.toDouble())}',
          style: AppThemes.numeralStyle(
            context,
            fontSize: 14,
            color: swatch.dark,
          ),
        ),
        Text(
          '${_n(d * i.price)} د.ل',
          style: AppThemes.numeralStyle(
            context,
            fontSize: 13,
            color: swatch.dark,
          ),
        ),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.item,
    required this.count,
    required this.onAdd,
    required this.onDec,
  });
  final _Item item;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    Widget btn(IconData icon, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 18, color: taj.accentText),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: taj.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 20, color: taj.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'الدفتري ${_n(item.book.toDouble())}',
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
          Container(
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
                  width: 28,
                  child: Text(
                    _n(count.toDouble()),
                    textAlign: TextAlign.center,
                    style: AppThemes.numeralStyle(context, fontSize: 14),
                  ),
                ),
                btn(Icons.add_rounded, onAdd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.status,
  });
  final String label;
  final String value;
  final TajStatus status;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final swatch = taj.swatch(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: taj.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: taj.textSecondary),
          ),
          const SizedBox(height: 6),
          // Scale the value down rather than overflow when three of these stats
          // share a narrow row on small phones.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: AppThemes.numeralStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: swatch.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
