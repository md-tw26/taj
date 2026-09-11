import 'package:flutter/material.dart';

import '../../core/demo/demo_provider.dart';
import '../../core/demo/demo_store.dart';
import '../../core/responsive.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_ui.dart';
import 'responsive_chart_card.dart';
import 'smart_analytics.dart';
import 'smart_models.dart';

/// Smart Reports & Analytics ("التقارير الذكية").
///
/// A grid of ready analytical questions; tapping one opens its **visual answer**
/// — KPI cards, a plain-language insight, and an interactive **chart board**.
/// Everything is fluid: the question grid, the KPI grid and the chart grid all
/// reflow via [gridColumnsFor], while each chart derives its own height from the
/// space available through [ResponsiveChartCard]. Content is capped/centred
/// beyond [AppBreakpoints.smartContentMaxWidth] so charts never stretch.
class SmartReportsScreen extends StatefulWidget {
  const SmartReportsScreen({super.key, this.testInitialQuestionId});

  /// Test hook: open a question's answer immediately.
  final String? testInitialQuestionId;

  @override
  State<SmartReportsScreen> createState() => _SmartReportsScreenState();
}

class _SmartReportsScreenState extends State<SmartReportsScreen> {
  String? _selectedId;
  SmartSlicers _slicers = const SmartSlicers();

  @override
  void initState() {
    super.initState();
    _selectedId = widget.testInitialQuestionId;
  }

  DemoStore get _store => DemoStoreProvider.of(context);

  void _open(String id) => setState(() {
        _selectedId = id;
        _slicers = _slicers.copyWith(clearMeasure: true);
      });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) => PageContainer(
        maxWidth: AppBreakpoints.smartContentMaxWidth,
        child: _selectedId == null
            ? _QuestionIndex(onOpen: _open)
            : _AnswerView(
                key: ValueKey(_selectedId),
                question: questionById(_selectedId!),
                store: _store,
                slicers: _slicers,
                onSlicers: (s) => setState(() => _slicers = s),
                onBack: () => setState(() => _selectedId = null),
              ),
      ),
    );
  }
}

// ===========================================================================
// Question index
// ===========================================================================

class _QuestionIndex extends StatelessWidget {
  const _QuestionIndex({required this.onOpen});
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final pad = pagePaddingForWidth(c.maxWidth);
        final available = c.maxWidth - pad * 2;
        final cols = gridColumnsFor(
          available,
          minItemWidth: AppBreakpoints.smartQuestionCardMin,
          maxColumns: 4,
        );
        const spacing = 16.0;
        final cellW = (available - spacing * (cols - 1)) / cols;
        return ListView(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 8),
          children: [
            SectionHeading(
              title: 'التقارير الذكية',
              subtitle: 'اطرح سؤالًا واحصل على إجابة بصرية فورية من بياناتك.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final q in smartQuestions)
                  SizedBox(
                    width: cellW,
                    child: _QuestionCard(def: q, onTap: () => onOpen(q.id)),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.def, required this.onTap});
  final QuestionDef def;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return TajCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        // Tolerates two–three line questions; comfortably above a 44px target.
        constraints: const BoxConstraints(minHeight: 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: taj.primary.lighter,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(def.icon, size: 22, color: taj.primary.dark),
            ),
            const SizedBox(height: 12),
            Text(def.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 6),
            Text(def.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: taj.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Answer view
// ===========================================================================

class _AnswerView extends StatelessWidget {
  const _AnswerView({
    super.key,
    required this.question,
    required this.store,
    required this.slicers,
    required this.onSlicers,
    required this.onBack,
  });

  final QuestionDef question;
  final DemoStore store;
  final SmartSlicers slicers;
  final ValueChanged<SmartSlicers> onSlicers;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    AnalyticsResult? result;
    Object? error;
    try {
      result = question.build(context, store, slicers);
    } catch (e) {
      error = e;
    }

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final veryShort = h < AppBreakpoints.chartShortViewport;

        return Container(
          color: taj.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AnswerHeader(question: question, onBack: onBack, veryShort: veryShort),
              _SlicerBar(
                question: question,
                store: store,
                slicers: slicers,
                onSlicers: onSlicers,
                width: w,
              ),
              Expanded(
                child: error != null
                    ? TajErrorState(
                        message: 'تعذّر توليد التحليل. جرّب شريحة زمنية مختلفة.',
                        onRetry: () => onSlicers(slicers),
                      )
                    : _AnswerBoard(
                        result: result!,
                        loading: store.isLoading,
                        width: w,
                        short: veryShort,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnswerHeader extends StatelessWidget {
  const _AnswerHeader({required this.question, required this.onBack, required this.veryShort});
  final QuestionDef question;
  final VoidCallback onBack;
  final bool veryShort;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsetsDirectional.only(start: 4, end: 12, top: veryShort ? 2 : 8, bottom: veryShort ? 2 : 8),
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'رجوع',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_rounded, size: 22),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(question.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (!veryShort)
                  Text(question.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: taj.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Slicing chips --------------------------------------------------------

class _SlicerBar extends StatelessWidget {
  const _SlicerBar({
    required this.question,
    required this.store,
    required this.slicers,
    required this.onSlicers,
    required this.width,
  });

  final QuestionDef question;
  final DemoStore store;
  final SmartSlicers slicers;
  final ValueChanged<SmartSlicers> onSlicers;
  final double width;

  bool get _scrollRow => width < AppBreakpoints.phone;

  String _branchLabel(String? id) {
    if (id == null) return 'كل الفروع';
    for (final b in store.branches) {
      if (b.id == id) return b.name;
    }
    return id;
  }

  String _measureLabel() {
    final m = question.measure;
    if (m == null) return '';
    final v = slicers.measure ?? m.options.first.value;
    return m.options.firstWhere((o) => o.value == v, orElse: () => m.options.first).label;
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final grouped = width >= AppBreakpoints.laptop;

    final chips = <Widget>[
      _ChipButton(
        icon: Icons.event_outlined,
        label: 'الفترة',
        value: _periodLabel(slicers),
        onTap: () => _pickPeriod(context),
      ),
      _ChipButton(
        icon: Icons.store_mall_directory_outlined,
        label: 'الفرع',
        value: _branchLabel(slicers.branchId),
        onTap: () => _pickBranch(context),
      ),
      if (question.measure != null)
        _ChipButton(
          icon: Icons.tune_rounded,
          label: question.measure!.label,
          value: _measureLabel(),
          onTap: () => _pickMeasure(context),
        ),
    ];

    Widget controls;
    if (_scrollRow) {
      // Narrow: a horizontally scrollable row + a "more" sheet for advanced.
      controls = Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final ch in chips) Padding(padding: const EdgeInsets.only(left: 8), child: ch),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MoreButton(
            activeCount: slicers.activeCount,
            onTap: () => _openSheet(context),
          ),
        ],
      );
    } else {
      controls = Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (grouped)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.filter_list_rounded, size: 16, color: taj.textSecondary),
                const SizedBox(width: 4),
                Text('الشرائح:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: taj.textSecondary)),
              ]),
            ),
          ...chips,
          if (slicers.activeCount > 0)
            TextButton(
              onPressed: () => onSlicers(const SmartSlicers()),
              child: Text('مسح (${slicers.activeCount})'),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: taj.background,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      child: controls,
    );
  }

  Future<void> _pickPeriod(BuildContext context) async {
    final (picked, choice) = await _menuSheet<SmartPeriod>(
      context,
      title: 'الفترة',
      options: [
        for (final p in SmartPeriod.values)
          if (p != SmartPeriod.custom) (p, p.label),
        (SmartPeriod.custom, 'فترة مخصصة…'),
      ],
      selected: slicers.period,
    );
    if (!picked || choice == null) return;
    if (choice == SmartPeriod.custom) {
      if (!context.mounted) return;
      final r = await _pickRange(context, slicers.resolveRange(DateTime.now()));
      if (r != null) onSlicers(slicers.copyWith(period: SmartPeriod.custom, range: r));
    } else {
      onSlicers(slicers.copyWith(period: choice, clearRange: true));
    }
  }

  Future<void> _pickBranch(BuildContext context) async {
    final (picked, choice) = await _menuSheet<String?>(
      context,
      title: 'الفرع',
      options: [
        (null, 'كل الفروع'),
        for (final b in store.branches) (b.id, b.name),
      ],
      selected: slicers.branchId,
    );
    if (!picked) return;
    onSlicers(slicers.copyWith(branchId: choice, clearBranch: choice == null));
  }

  Future<void> _pickMeasure(BuildContext context) async {
    final m = question.measure!;
    final current = slicers.measure ?? m.options.first.value;
    final (picked, choice) = await _menuSheet<String>(
      context,
      title: m.label,
      options: [for (final o in m.options) (o.value, o.label)],
      selected: current,
    );
    if (!picked || choice == null) return;
    onSlicers(slicers.copyWith(measure: choice));
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MoreSlicersSheet(
        question: question,
        store: store,
        slicers: slicers,
        onApply: (s) {
          onSlicers(s);
          Navigator.of(context).maybePop();
        },
      ),
    );
  }
}

Future<DateTimeRange?> _pickRange(BuildContext context, DateTimeRange? initial) {
  final now = DateTime.now();
  final size = MediaQuery.sizeOf(context);
  final phone = size.width < AppBreakpoints.phone;
  return showDateRangePicker(
    context: context,
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 1, 12, 31),
    initialDateRange: initial,
    builder: (ctx, child) => phone
        ? child!
        : Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 560, maxHeight: size.height * 0.9),
              child: child,
            ),
          ),
  );
}

String _periodLabel(SmartSlicers s) {
  if (s.period == SmartPeriod.custom && s.range != null) {
    String d(DateTime x) => '${x.year}/${x.month.toString().padLeft(2, '0')}/${x.day.toString().padLeft(2, '0')}';
    return '${d(s.range!.start)} — ${d(s.range!.end)}';
  }
  return s.period.label;
}

/// Bottom-sheet single-select; returns `(picked, value)` so a null selection
/// (e.g. "all branches") is distinct from a dismiss. Pops the option index.
Future<(bool, T?)> _menuSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  required T selected,
}) async {
  final taj = context.taj;
  final idx = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (var i = 0; i < options.length; i++)
                  ListTile(
                    title: Text(options[i].$2),
                    trailing: options[i].$1 == selected
                        ? Icon(Icons.check_rounded, color: taj.primary.main)
                        : null,
                    onTap: () => Navigator.of(ctx).pop<int>(i),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  if (idx == null) return (false, null);
  return (true, options[idx].$1);
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.icon, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          constraints: const BoxConstraints(maxWidth: 240),
          decoration: BoxDecoration(
            color: taj.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: taj.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: taj.textSecondary),
              const SizedBox(width: 6),
              Text('$label: ', style: text.labelMedium?.copyWith(color: taj.textSecondary)),
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium?.copyWith(color: taj.textPrimary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 16, color: taj.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.activeCount, required this.onTap});
  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: taj.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: taj.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 16, color: taj.textSecondary),
              const SizedBox(width: 6),
              Text('شرائح', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (activeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: taj.primary.main, borderRadius: BorderRadius.circular(9)),
                  child: Text('$activeCount',
                      style: TextStyle(color: taj.primary.contrastText, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreSlicersSheet extends StatefulWidget {
  const _MoreSlicersSheet({
    required this.question,
    required this.store,
    required this.slicers,
    required this.onApply,
  });
  final QuestionDef question;
  final DemoStore store;
  final SmartSlicers slicers;
  final ValueChanged<SmartSlicers> onApply;

  @override
  State<_MoreSlicersSheet> createState() => _MoreSlicersSheetState();
}

class _MoreSlicersSheetState extends State<_MoreSlicersSheet> {
  late SmartSlicers _s = widget.slicers;

  String _branchLabel(String? id) {
    if (id == null) return 'كل الفروع';
    for (final b in widget.store.branches) {
      if (b.id == id) return b.name;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final h = MediaQuery.sizeOf(context).height;
    final m = widget.question.measure;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h * 0.9),
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('الشرائح', style: text.titleMedium),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _SheetRow(label: 'الفترة', value: _periodLabel(_s), onTap: _pickPeriod),
                    _SheetRow(label: 'الفرع', value: _branchLabel(_s.branchId), onTap: _pickBranch),
                    if (m != null)
                      _SheetRow(
                        label: m.label,
                        value: m.options
                            .firstWhere((o) => o.value == (_s.measure ?? m.options.first.value),
                                orElse: () => m.options.first)
                            .label,
                        onTap: _pickMeasure,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _s = const SmartSlicers()),
                      child: const Text('إعادة تعيين'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => widget.onApply(_s),
                      child: const Text('تطبيق'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPeriod() async {
    final (picked, choice) = await _menuSheet<SmartPeriod>(
      context,
      title: 'الفترة',
      options: [
        for (final p in SmartPeriod.values)
          if (p != SmartPeriod.custom) (p, p.label),
        (SmartPeriod.custom, 'فترة مخصصة…'),
      ],
      selected: _s.period,
    );
    if (!picked || choice == null) return;
    if (choice == SmartPeriod.custom) {
      if (!mounted) return;
      final r = await _pickRange(context, _s.resolveRange(DateTime.now()));
      if (r != null) setState(() => _s = _s.copyWith(period: SmartPeriod.custom, range: r));
    } else {
      setState(() => _s = _s.copyWith(period: choice, clearRange: true));
    }
  }

  Future<void> _pickBranch() async {
    final (picked, choice) = await _menuSheet<String?>(
      context,
      title: 'الفرع',
      options: [
        (null, 'كل الفروع'),
        for (final b in widget.store.branches) (b.id, b.name),
      ],
      selected: _s.branchId,
    );
    if (!picked) return;
    setState(() => _s = _s.copyWith(branchId: choice, clearBranch: choice == null));
  }

  Future<void> _pickMeasure() async {
    final m = widget.question.measure!;
    final (picked, choice) = await _menuSheet<String>(
      context,
      title: m.label,
      options: [for (final o in m.options) (o.value, o.label)],
      selected: _s.measure ?? m.options.first.value,
    );
    if (!picked || choice == null) return;
    setState(() => _s = _s.copyWith(measure: choice));
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: text.labelMedium?.copyWith(color: taj.textSecondary)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: taj.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: taj.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.expand_more_rounded, size: 18, color: taj.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Answer board ---------------------------------------------------------

class _AnswerBoard extends StatelessWidget {
  const _AnswerBoard({
    required this.result,
    required this.loading,
    required this.width,
    required this.short,
  });

  final AnalyticsResult result;
  final bool loading;
  final double width;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final pad = pagePaddingForWidth(width);
    final available = width - pad * 2;

    // KPI grid.
    final kpiCols = gridColumnsFor(available, minItemWidth: AppBreakpoints.smartKpiCardMin, maxColumns: 4);

    // Chart grid: as many columns as fit, but never fewer than the charts need,
    // and each cell capped so a lone chart can't stretch on a wide board.
    const spacing = 16.0;
    final fitCols = gridColumnsFor(available, minItemWidth: AppBreakpoints.smartChartCardMin, maxColumns: 4);
    final chartCols = result.charts.isEmpty ? 1 : fitCols.clamp(1, result.charts.length);
    var chartCellW = (available - spacing * (chartCols - 1)) / chartCols;
    if (chartCellW > AppBreakpoints.smartChartCardMax) chartCellW = AppBreakpoints.smartChartCardMax;
    // On a short viewport, force full-width charts and cap their height.
    final chartMaxHeight = short ? MediaQuery.sizeOf(context).height * 0.7 : null;

    return ListView(
      padding: EdgeInsets.all(pad),
      children: [
        if (result.kpis.isNotEmpty)
          _Grid(
            spacing: spacing,
            cellWidth: (available - spacing * (kpiCols - 1)) / kpiCols,
            children: [
              for (final k in result.kpis)
                KpiCard(
                  label: k.label,
                  value: k.value,
                  delta: k.delta,
                  deltaPositive: k.deltaPositive,
                  icon: k.icon,
                  spark: k.spark,
                ),
            ],
          ),
        if (result.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final n in result.notes) _NoteCard(note: n),
        ],
        const SizedBox(height: 16),
        _Grid(
          spacing: spacing,
          cellWidth: chartCellW,
          alignment: WrapAlignment.center,
          children: [
            for (final spec in result.charts)
              ResponsiveChartCard(
                spec: spec,
                loading: loading,
                legendBeside: short,
                maxHeight: chartMaxHeight,
              ),
          ],
        ),
      ],
    );
  }
}

/// A simple responsive grid: fixed-width cells that wrap.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.children,
    required this.cellWidth,
    this.spacing = 16,
    this.alignment = WrapAlignment.start,
  });
  final List<Widget> children;
  final double cellWidth;
  final double spacing;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: alignment,
      children: [for (final ch in children) SizedBox(width: cellWidth, child: ch)],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final InsightNote note;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: taj.info.lighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(note.icon, size: 18, color: taj.info.dark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(note.text,
                style: text.bodyMedium?.copyWith(color: taj.info.dark, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
