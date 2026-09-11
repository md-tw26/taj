import 'package:flutter/material.dart';

import '../../core/demo/demo_provider.dart';
import '../../core/demo/demo_store.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_report_table.dart';
import '../../shared/widgets/taj_ui.dart';
import 'report_catalog.dart';
import 'report_charts.dart';
import 'report_models.dart';

/// The Reports centre.
///
/// * Below [AppBreakpoints.reportIndexRail] it is a single pane: a responsive
///   **index** of report cards, and tapping one opens the report **result** as
///   a full page (with a back affordance).
/// * At or above it, it is a **master-detail** layout: a persistent report side
///   rail on the leading side and the selected report's result on the trailing
///   side. Resizing across the threshold folds the rail smoothly back into the
///   index page.
///
/// The whole thing is capped and centred beyond
/// [AppBreakpoints.reportContentMaxWidth] so it never stretches on 4K/ultra-wide,
/// and the rail never stretches (it is clamped to
/// [AppBreakpoints.reportRailMin]…[AppBreakpoints.reportRailMax]).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.testInitialReportId});

  /// Test hook: pre-select a report so its result is shown immediately.
  final String? testInitialReportId;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selectedId;
  ReportFilters _filters = const ReportFilters();

  @override
  void initState() {
    super.initState();
    _selectedId = widget.testInitialReportId;
  }

  DemoStore get _store => DemoStoreProvider.of(context);

  void _select(String id) => setState(() {
        _selectedId = id;
        // Segment meaning is report-specific, so reset it when switching.
        _filters = _filters.copyWith(clearSegment: true);
      });

  void _clearSelection() => setState(() => _selectedId = null);

  void _onFilters(ReportFilters f) => setState(() => _filters = f);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) => LayoutBuilder(
        builder: (context, c) {
          final rail = c.maxWidth >= AppBreakpoints.reportIndexRail;
          return PageContainer(
            maxWidth: AppBreakpoints.reportContentMaxWidth,
            child: rail ? _buildRail(context, c.maxWidth) : _buildSingle(context),
          );
        },
      ),
    );
  }

  // Master-detail: rail + result.
  Widget _buildRail(BuildContext context, double width) {
    final taj = context.taj;
    final selected = _selectedId ?? reportCatalog.first.id;
    final railW = (width * 0.24)
        .clamp(AppBreakpoints.reportRailMin, AppBreakpoints.reportRailMax)
        .toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: railW,
          child: _ReportRail(
            selectedId: selected,
            onSelect: _select,
          ),
        ),
        VerticalDivider(width: 1, color: taj.divider),
        Expanded(
          child: ReportResultView(
            key: ValueKey(selected),
            report: reportById(selected),
            store: _store,
            filters: _filters,
            onFilters: _onFilters,
          ),
        ),
      ],
    );
  }

  // Single pane: index page, or the pushed result.
  Widget _buildSingle(BuildContext context) {
    final id = _selectedId;
    if (id == null) {
      return _ReportIndexPage(onOpen: _select);
    }
    return ReportResultView(
      key: ValueKey(id),
      report: reportById(id),
      store: _store,
      filters: _filters,
      onFilters: _onFilters,
      onBack: _clearSelection,
    );
  }
}

// ===========================================================================
// Index — full page of cards (grouped by category)
// ===========================================================================

class _ReportIndexPage extends StatelessWidget {
  const _ReportIndexPage({required this.onOpen});
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final pad = pagePaddingForWidth(c.maxWidth);
        final cols = gridColumnsFor(
          c.maxWidth - pad * 2,
          minItemWidth: AppBreakpoints.reportCardMinWidth,
          maxColumns: 4,
        );
        final sections = <Widget>[];
        for (final cat in ReportCategory.values) {
          final items = reportCatalog.where((r) => r.category == cat).toList();
          if (items.isEmpty) continue;
          sections.add(Padding(
            padding: EdgeInsets.only(top: sections.isEmpty ? 0 : 24, bottom: 12),
            child: Text(cat.label,
                style: Theme.of(context).textTheme.titleMedium),
          ));
          sections.add(_CardGrid(items: items, columns: cols, onOpen: onOpen));
        }
        return ListView(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 8),
          children: [
            SectionHeading(
              title: 'التقارير',
              subtitle: 'اختر تقريرًا لعرض نتائجه وتصفيته وتصديره.',
            ),
            const SizedBox(height: 8),
            ...sections,
          ],
        );
      },
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.items, required this.columns, required this.onOpen});
  final List<ReportDef> items;
  final int columns;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const spacing = 16.0;
        final cellW = (c.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final r in items)
              SizedBox(
                width: cellW,
                child: _ReportCard(def: r, onTap: () => onOpen(r.id)),
              ),
          ],
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.def, required this.onTap});
  final ReportDef def;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return TajCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: taj.primary.lighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(def.icon, size: 21, color: taj.primary.dark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(def.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(def.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: taj.textSecondary, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('عرض التقرير',
                  style: text.labelMedium
                      ?.copyWith(color: taj.accentText, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_left_rounded, size: 18, color: taj.accentText),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Index — narrow rail (grouped, selectable tiles)
// ===========================================================================

class _ReportRail extends StatelessWidget {
  const _ReportRail({required this.selectedId, required this.onSelect});
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text('التقارير', style: text.titleMedium),
      ),
    ];
    for (final cat in ReportCategory.values) {
      final items = reportCatalog.where((r) => r.category == cat).toList();
      if (items.isEmpty) continue;
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text(cat.label.toUpperCase(),
            style: text.labelSmall?.copyWith(color: taj.textDisabled, letterSpacing: 0.5)),
      ));
      for (final r in items) {
        final sel = r.id == selectedId;
        children.add(_RailTile(def: r, selected: sel, onTap: () => onSelect(r.id)));
      }
    }
    return Container(
      color: taj.paper,
      child: ListView(padding: const EdgeInsets.only(bottom: 16), children: children),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({required this.def, required this.selected, required this.onTap});
  final ReportDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final fg = selected ? taj.primary.dark : taj.textPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? taj.primary.lighter : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(def.icon, size: 19, color: selected ? taj.primary.dark : taj.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(def.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                        color: fg, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Result view
// ===========================================================================

class ReportResultView extends StatefulWidget {
  const ReportResultView({
    super.key,
    required this.report,
    required this.store,
    required this.filters,
    required this.onFilters,
    this.onBack,
  });

  final ReportDef report;
  final DemoStore store;
  final ReportFilters filters;
  final ValueChanged<ReportFilters> onFilters;

  /// Present only in single-pane mode (pushed result) — shows a back button.
  final VoidCallback? onBack;

  @override
  State<ReportResultView> createState() => _ReportResultViewState();
}

enum _InsightsMode { table, insights }

class _ReportResultViewState extends State<ReportResultView> {
  _InsightsMode _mode = _InsightsMode.table;
  bool _busy = false;
  String _busyLabel = '';

  Future<void> _export(String kind) async {
    // Export has no engine yet (no PDF/Excel packages); this exercises the
    // confined generation overlay and reports that it is coming, without
    // touching print/export behaviour.
    setState(() {
      _busy = true;
      _busyLabel = 'جارٍ تجهيز $kind…';
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تصدير $kind سيتوفر قريبًا')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    // Compute the report. Guard against a builder throwing so a data problem
    // shows a generation-error state instead of a red screen.
    ReportResult? result;
    Object? error;
    try {
      result = widget.report.build(context, widget.store, widget.filters);
    } catch (e) {
      error = e;
    }

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final veryShort = h < 480; // landscape phone / very short window
        final sidePanel = w >= AppBreakpoints.reportInsightsPanel &&
            h >= AppBreakpoints.reportInsightsMinHeight;
        final hasInsights = result != null &&
            (result.chart != null || result.summary.isNotEmpty);
        final showToggle = !sidePanel && hasInsights && !veryShort;
        final showSummaryStrip = !sidePanel &&
            _mode == _InsightsMode.table &&
            hasInsights &&
            h >= AppBreakpoints.reportSummaryMinHeight;
        final pad = pagePaddingForWidth(w);

        final header = _HeaderBar(
          report: widget.report,
          filters: widget.filters,
          onBack: widget.onBack,
          veryShort: veryShort,
          exportDensity: veryShort
              ? _ExportDensity.menu
              : w >= AppBreakpoints.reportExportButtons
                  ? _ExportDensity.full
                  : w >= AppBreakpoints.reportExportIcons
                      ? _ExportDensity.icons
                      : _ExportDensity.menu,
          onExport: _export,
          showToggle: showToggle,
          mode: _mode,
          onMode: (m) => setState(() => _mode = m),
        );

        Widget content;
        if (error != null) {
          content = TajErrorState(
            message: 'تعذّر توليد التقرير. تحقق من الفلاتر ثم أعد المحاولة.',
            onRetry: () => setState(() {}),
          );
        } else {
          final r = result!;
          final table = TajReportTable(
            columns: r.columns,
            rows: r.rows,
            totals: r.totals,
          );
          if (sidePanel) {
            content = Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 4, pad, pad),
                    child: table,
                  ),
                ),
                SizedBox(
                  width: AppBreakpoints.reportInsightsPanelWidth,
                  child: _InsightsPanel(result: r, wide: true),
                ),
              ],
            );
          } else if (_mode == _InsightsMode.insights && hasInsights) {
            content = _InsightsPanel(result: r, wide: w >= AppBreakpoints.tablet);
          } else {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showSummaryStrip)
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 4, pad, 0),
                    child: _SummaryStrip(stats: r.summary),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, showSummaryStrip ? 12 : 4, pad, pad),
                    child: table,
                  ),
                ),
              ],
            );
          }
        }

        return Container(
          color: taj.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              _FiltersRegion(
                report: widget.report,
                store: widget.store,
                filters: widget.filters,
                onFilters: widget.onFilters,
                width: w,
              ),
              if (result?.note != null && !veryShort)
                _NoteBanner(text: result!.note!),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: content),
                    if (_busy)
                      Positioned.fill(
                        child: _GenerationOverlay(label: _busyLabel),
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

// ---- Header bar -----------------------------------------------------------

enum _ExportDensity { full, icons, menu }

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.report,
    required this.filters,
    required this.onBack,
    required this.veryShort,
    required this.exportDensity,
    required this.onExport,
    required this.showToggle,
    required this.mode,
    required this.onMode,
  });

  final ReportDef report;
  final ReportFilters filters;
  final VoidCallback? onBack;
  final bool veryShort;
  final _ExportDensity exportDensity;
  final ValueChanged<String> onExport;
  final bool showToggle;
  final _InsightsMode mode;
  final ValueChanged<_InsightsMode> onMode;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(report.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        if (!veryShort)
          Text('الفترة: ${periodSummary(filters)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: taj.textSecondary)),
      ],
    );

    return Container(
      padding: EdgeInsetsDirectional.only(
        start: onBack != null ? 4 : 16,
        end: 12,
        top: veryShort ? 4 : 10,
        bottom: veryShort ? 4 : 10,
      ),
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'رجوع',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_forward_rounded, size: 22),
            ),
          Expanded(child: title),
          if (showToggle) ...[
            _InsightsToggle(mode: mode, onMode: onMode, compact: veryShort),
            const SizedBox(width: 8),
          ],
          _ExportControl(density: exportDensity, onExport: onExport),
        ],
      ),
    );
  }
}

class _InsightsToggle extends StatelessWidget {
  const _InsightsToggle({required this.mode, required this.onMode, this.compact = false});
  final _InsightsMode mode;
  final ValueChanged<_InsightsMode> onMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    Widget seg(_InsightsMode m, IconData icon, String label) {
      final sel = mode == m;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onMode(m),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? taj.paper : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: sel ? AppThemes.cardShadow(context) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: sel ? taj.primary.dark : taj.textSecondary),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? taj.primary.dark : taj.textSecondary)),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: taj.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(_InsightsMode.table, Icons.table_rows_rounded, 'جدول'),
          seg(_InsightsMode.insights, Icons.insights_rounded, 'رسم'),
        ],
      ),
    );
  }
}

class _ExportControl extends StatelessWidget {
  const _ExportControl({required this.density, required this.onExport});
  final _ExportDensity density;
  final ValueChanged<String> onExport;

  static const _kinds = [
    ('PDF', 'ملف PDF', Icons.picture_as_pdf_outlined),
    ('Excel', 'ملف Excel', Icons.table_chart_outlined),
    ('طباعة', 'طباعة', Icons.print_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    switch (density) {
      case _ExportDensity.full:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final k in _kinds) ...[
              OutlinedButton.icon(
                onPressed: () => onExport(k.$1),
                icon: Icon(k.$3, size: 18),
                label: Text(k.$1),
              ),
              const SizedBox(width: 8),
            ],
          ],
        );
      case _ExportDensity.icons:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final k in _kinds)
              IconButton(
                tooltip: k.$2,
                onPressed: () => onExport(k.$1),
                icon: Icon(k.$3, size: 20),
              ),
          ],
        );
      case _ExportDensity.menu:
        return PopupMenuButton<String>(
          tooltip: 'تصدير',
          icon: const Icon(Icons.ios_share_rounded, size: 20),
          onSelected: onExport,
          itemBuilder: (_) => [
            for (final k in _kinds)
              PopupMenuItem(
                value: k.$1,
                child: Row(children: [Icon(k.$3, size: 18), const SizedBox(width: 10), Text(k.$2)]),
              ),
          ],
        );
    }
  }
}

// ---- Filters region -------------------------------------------------------

class _FiltersRegion extends StatelessWidget {
  const _FiltersRegion({
    required this.report,
    required this.store,
    required this.filters,
    required this.onFilters,
    required this.width,
  });

  final ReportDef report;
  final DemoStore store;
  final ReportFilters filters;
  final ValueChanged<ReportFilters> onFilters;
  final double width;

  bool get _sheet => width < AppBreakpoints.phone;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final segment = reportSegmentFor(report, store);
    final chips = _activeChips(context, segment);

    Widget controls;
    if (_sheet) {
      controls = Row(
        children: [
          _FilterButton(
            activeCount: _activeCount,
            onTap: () => _openSheet(context, segment),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(periodSummary(filters),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: taj.textSecondary)),
          ),
        ],
      );
    } else {
      final grouped = width >= AppBreakpoints.reportFiltersGrouped;
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
                Text('الفلاتر:',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: taj.textSecondary)),
              ]),
            ),
          _periodPill(context),
          _branchPill(context),
          if (segment != null && segment.options.isNotEmpty) _segmentPill(context, segment),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: taj.background,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          controls,
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ],
      ),
    );
  }

  int get _activeCount {
    var n = 0;
    if (filters.period != ReportPeriodPreset.all) n++;
    if (filters.branchId != null) n++;
    if (filters.segment != null) n++;
    return n;
  }

  List<Widget> _activeChips(BuildContext context, ReportSegment? segment) {
    final chips = <Widget>[];
    if (filters.period != ReportPeriodPreset.all) {
      chips.add(_RemovableChip(
        label: 'الفترة',
        value: periodSummary(filters),
        onRemove: () => onFilters(filters.copyWith(
            period: ReportPeriodPreset.all, clearCustomRange: true)),
      ));
    }
    if (filters.branchId != null) {
      chips.add(_RemovableChip(
        label: 'الفرع',
        value: _branchLabel(filters.branchId),
        onRemove: () => onFilters(filters.copyWith(clearBranch: true)),
      ));
    }
    if (filters.segment != null && segment != null) {
      final opt = segment.options.firstWhere(
        (o) => o.value == filters.segment,
        orElse: () => ReportSegmentOption(filters.segment, filters.segment ?? ''),
      );
      chips.add(_RemovableChip(
        label: segment.label,
        value: opt.label,
        onRemove: () => onFilters(filters.copyWith(clearSegment: true)),
      ));
    }
    return chips;
  }

  String _branchLabel(String? id) {
    if (id == null) return 'كل الفروع';
    for (final b in store.branches) {
      if (b.id == id) return b.name;
    }
    return id;
  }

  Widget _periodPill(BuildContext context) => _FilterPill(
        icon: Icons.event_outlined,
        label: 'الفترة',
        value: periodSummary(filters),
        onTap: () => _pickPeriod(context),
      );

  Widget _branchPill(BuildContext context) => _FilterPill(
        icon: Icons.store_mall_directory_outlined,
        label: 'الفرع',
        value: _branchLabel(filters.branchId),
        onTap: () => _pickBranch(context),
      );

  Widget _segmentPill(BuildContext context, ReportSegment segment) {
    final opt = segment.options.firstWhere(
      (o) => o.value == filters.segment,
      orElse: () => segment.options.first,
    );
    return _FilterPill(
      icon: Icons.tune_rounded,
      label: segment.label,
      value: opt.label,
      onTap: () => _pickSegment(context, segment),
    );
  }

  Future<void> _pickPeriod(BuildContext context) async {
    final (picked, choice) = await _showMenu<ReportPeriodPreset>(
      context,
      title: 'الفترة',
      options: [
        for (final p in ReportPeriodPreset.values)
          if (p != ReportPeriodPreset.custom) (p, p.label),
        (ReportPeriodPreset.custom, 'فترة مخصصة…'),
      ],
      selected: filters.period,
    );
    if (!picked || choice == null) return;
    if (choice == ReportPeriodPreset.custom) {
      if (!context.mounted) return;
      final range = await _pickRange(context);
      if (range != null) {
        onFilters(filters.copyWith(period: ReportPeriodPreset.custom, customRange: range));
      }
    } else {
      onFilters(filters.copyWith(period: choice, clearCustomRange: true));
    }
  }

  Future<DateTimeRange?> _pickRange(BuildContext context) {
    final now = DateTime.now();
    final h = MediaQuery.sizeOf(context).height;
    final phone = MediaQuery.sizeOf(context).width < AppBreakpoints.phone;
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: filters.resolveRange(now),
      // Full width on a phone; a centred dialog no wider than the cap and no
      // taller than 90% of the viewport on tablet-and-up.
      builder: (ctx, child) => phone
          ? child!
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppBreakpoints.reportDateDialogMax,
                  maxHeight: h * 0.9,
                ),
                child: child,
              ),
            ),
    );
  }

  Future<void> _pickBranch(BuildContext context) async {
    final (picked, choice) = await _showMenu<String?>(
      context,
      title: 'الفرع',
      options: [
        (null, 'كل الفروع'),
        for (final b in store.branches) (b.id, b.name),
      ],
      selected: filters.branchId,
    );
    if (!picked) return;
    onFilters(filters.copyWith(branchId: choice, clearBranch: choice == null));
  }

  Future<void> _pickSegment(BuildContext context, ReportSegment segment) async {
    final (picked, choice) = await _showMenu<String?>(
      context,
      title: segment.label,
      options: [for (final o in segment.options) (o.value, o.label)],
      selected: filters.segment,
    );
    if (!picked) return;
    onFilters(filters.copyWith(segment: choice, clearSegment: choice == null));
  }

  void _openSheet(BuildContext context, ReportSegment? segment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(
        store: store,
        filters: filters,
        segment: segment,
        onApply: (f) {
          onFilters(f);
          Navigator.of(context).maybePop();
        },
      ),
    );
  }
}

/// Popup selector rendered as a small bottom-sheet menu. Returns
/// `(picked, value)` — `picked` is false when the sheet was dismissed, which is
/// distinct from picking an option whose value is null (e.g. "all branches").
/// It pops the chosen option's **index** (never the value) so a null value is
/// never confused with a dismiss.
Future<(bool, T?)> _showMenu<T>(
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

// ---- Small filter widgets -------------------------------------------------

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
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
          constraints: const BoxConstraints(maxWidth: 260),
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
              Text('$label: ',
                  style: text.labelMedium?.copyWith(color: taj.textSecondary)),
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium
                        ?.copyWith(color: taj.textPrimary, fontWeight: FontWeight.w700)),
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

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.value, required this.onRemove});
  final String label;
  final String value;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      height: 30,
      padding: const EdgeInsetsDirectional.only(start: 10, end: 6),
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: taj.primary.lighter,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: text.labelSmall?.copyWith(color: taj.primary.dark)),
          Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall
                    ?.copyWith(color: taj.primary.dark, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 15, color: taj.primary.dark),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});
  final int activeCount;
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
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: taj.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: taj.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_rounded, size: 18, color: taj.textSecondary),
              const SizedBox(width: 8),
              Text('تصفية',
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              if (activeCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: taj.primary.main,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text('$activeCount',
                      style: TextStyle(
                          color: taj.primary.contrastText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for the phone filter layout: period / branch / segment stacked
/// full-width, with apply / reset. Height is bounded so a short screen scrolls.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.store,
    required this.filters,
    required this.segment,
    required this.onApply,
  });
  final DemoStore store;
  final ReportFilters filters;
  final ReportSegment? segment;
  final ValueChanged<ReportFilters> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ReportFilters _f = widget.filters;

  String _branchLabel(String? id) {
    if (id == null) return 'كل الفروع';
    for (final b in widget.store.branches) {
      if (b.id == id) return b.name;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h * 0.9),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تصفية التقرير', style: text.titleMedium),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _SheetRow(
                      label: 'الفترة',
                      value: periodSummary(_f),
                      onTap: _pickPeriod,
                    ),
                    _SheetRow(
                      label: 'الفرع',
                      value: _branchLabel(_f.branchId),
                      onTap: _pickBranch,
                    ),
                    if (widget.segment != null && widget.segment!.options.isNotEmpty)
                      _SheetRow(
                        label: widget.segment!.label,
                        value: widget.segment!.options
                            .firstWhere((o) => o.value == _f.segment,
                                orElse: () => widget.segment!.options.first)
                            .label,
                        onTap: _pickSegment,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _f = const ReportFilters()),
                      child: const Text('إعادة تعيين'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => widget.onApply(_f),
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
    final (picked, choice) = await _showMenu<ReportPeriodPreset>(
      context,
      title: 'الفترة',
      options: [
        for (final p in ReportPeriodPreset.values)
          if (p != ReportPeriodPreset.custom) (p, p.label),
        (ReportPeriodPreset.custom, 'فترة مخصصة…'),
      ],
      selected: _f.period,
    );
    if (!picked || choice == null) return;
    if (choice == ReportPeriodPreset.custom) {
      if (!mounted) return;
      final now = DateTime.now();
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 1, 12, 31),
        initialDateRange: _f.resolveRange(now),
      );
      if (range != null) {
        setState(() => _f = _f.copyWith(period: ReportPeriodPreset.custom, customRange: range));
      }
    } else {
      setState(() => _f = _f.copyWith(period: choice, clearCustomRange: true));
    }
  }

  Future<void> _pickBranch() async {
    final (picked, choice) = await _showMenu<String?>(
      context,
      title: 'الفرع',
      options: [
        (null, 'كل الفروع'),
        for (final b in widget.store.branches) (b.id, b.name),
      ],
      selected: _f.branchId,
    );
    if (!picked) return;
    setState(() => _f = _f.copyWith(branchId: choice, clearBranch: choice == null));
  }

  Future<void> _pickSegment() async {
    final seg = widget.segment!;
    final (picked, choice) = await _showMenu<String?>(
      context,
      title: seg.label,
      options: [for (final o in seg.options) (o.value, o.label)],
      selected: _f.segment,
    );
    if (!picked) return;
    setState(() => _f = _f.copyWith(segment: choice, clearSegment: choice == null));
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

// ---- Summary + insights ---------------------------------------------------

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.stats});
  final List<ReportStat> stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [for (final s in stats) _StatTile(stat: s, expand: false)],
    );
  }
}

class _InsightsPanel extends StatelessWidget {
  const _InsightsPanel({required this.result, required this.wide});
  final ReportResult result;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final aspect = wide
        ? AppBreakpoints.reportChartAspectWide
        : AppBreakpoints.reportChartAspectPhone;
    return Container(
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: taj.divider)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in result.summary)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StatTile(stat: s, expand: true),
            ),
          if (result.chart != null) ...[
            const SizedBox(height: 6),
            ReportChart(data: result.chart!, aspect: aspect),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat, required this.expand});
  final ReportStat stat;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final tile = Container(
      width: expand ? double.infinity : null,
      constraints: expand ? null : const BoxConstraints(minWidth: 120, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taj.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (stat.icon != null) ...[
                Icon(stat.icon, size: 15, color: taj.textSecondary),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(stat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: taj.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(stat.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemes.numeralStyle(context,
                  fontSize: 17, fontWeight: FontWeight.w800, color: stat.tone ?? taj.textPrimary)),
        ],
      ),
    );
    return tile;
  }
}

class _NoteBanner extends StatelessWidget {
  const _NoteBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: taj.info.lighter,
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: taj.info.dark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: taj.info.dark, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _GenerationOverlay extends StatelessWidget {
  const _GenerationOverlay({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      color: taj.background.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 14),
          Text(label,
              style: TextStyle(color: taj.textPrimary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ---- Shared: period summary text -----------------------------------------

String periodSummary(ReportFilters f) {
  if (f.period == ReportPeriodPreset.custom && f.customRange != null) {
    final r = f.customRange!;
    String d(DateTime x) =>
        '${x.year}/${x.month.toString().padLeft(2, '0')}/${x.day.toString().padLeft(2, '0')}';
    return '${d(r.start)} — ${d(r.end)}';
  }
  return f.period.label;
}
