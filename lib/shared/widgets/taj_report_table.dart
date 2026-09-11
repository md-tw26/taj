import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';

/// ---------------------------------------------------------------------------
/// TAJ report table — the one central column system every report shares
/// ---------------------------------------------------------------------------
///
/// Reports differ wildly in their column sets (trial balance, cash flow,
/// payroll, ledger …). Rather than write bespoke responsive logic per report,
/// each report describes its columns declaratively with [ReportColumn]
/// (`numeric` · `sticky` · `minWidth` · `priority` · `flex`) and its rows with
/// [ReportRow], and [TajReportTable] renders them the same way everywhere:
///
///  * the leading **sticky** column(s) are frozen and stay put while the rest
///    scroll horizontally,
///  * the **header** stays pinned while the body scrolls vertically,
///  * an optional **totals** row is pinned to the bottom, immune to the
///    vertical scroll,
///  * when the table is too narrow to show everything, **only descriptive
///    (non-numeric) columns collapse** — lowest `priority` first — while every
///    **amount column is always shown** (reached by horizontal scroll if
///    needed). No financial column is ever silently dropped.
///  * **hierarchical** rows indent their (frozen) name by
///    `min(depth * reportIndentStep, reportMaxIndent)`; the name then takes the
///    remaining width and ellipsizes.
///
/// The widget expects a **bounded height** — place it inside an `Expanded`.
/// No `FittedBox`/`Transform.scale` is used to hide overflow, and no text is
/// rendered below 12sp.
class ReportColumn {
  const ReportColumn(
    this.label, {
    this.numeric = false,
    this.sticky = false,
    this.minWidth = 140,
    this.priority = 0,
    this.flex = 0,
  });

  /// Header label.
  final String label;

  /// Amount/figure column — end-aligned, and **never collapsed** on narrow
  /// widths (financial data is never hidden, only scrolled to).
  final bool numeric;

  /// Part of the frozen leading group (typically the first descriptive column,
  /// e.g. the account/employee name). Sticky columns never collapse.
  final bool sticky;

  /// The narrowest this column is ever laid out; below the sum of visible
  /// columns' minima the table scrolls horizontally instead of crushing cells.
  final double minWidth;

  /// Collapse order for **descriptive** columns only: `0` never collapses,
  /// higher numbers drop first when the width is tight. Ignored for `numeric`
  /// and `sticky` columns (those never collapse).
  final int priority;

  /// Extra growth weight — slack width beyond the minima is shared among
  /// columns with `flex > 0` (typically the name/description). Numeric columns
  /// keep `flex: 0` so figures stay tight and aligned.
  final int flex;

  bool get _collapsible => !numeric && !sticky && priority > 0;
}

/// One row of a report. [cells] are aligned to the report's **full** column
/// list by index (cells for collapsed columns are simply skipped).
class ReportRow {
  const ReportRow({
    required this.cells,
    this.depth = 0,
    this.emphasize = false,
    this.onTap,
    this.selected = false,
  });

  /// Cell widgets, one per column in the report's column list (by index).
  final List<Widget> cells;

  /// Indentation level for hierarchical reports (0 = top level).
  final int depth;

  /// Subtotal / section / grand-total style row — tinted background, hairline.
  final bool emphasize;

  final VoidCallback? onTap;
  final bool selected;
}

/// Builds a single table cell with the shared report typography: single line,
/// ellipsized, never below 12sp, tabular figures for [numeric] cells so digit
/// columns line up. Use for the vast majority of cells; build a custom widget
/// only when a cell needs a badge/icon (wrap its text in `Expanded` so it
/// ellipsizes within the column).
Widget reportCell(
  BuildContext context,
  String text, {
  bool numeric = false,
  bool emphasize = false,
  bool muted = false,
  Color? color,
}) {
  final taj = context.taj;
  final resolved = color ?? (muted ? taj.textSecondary : taj.textPrimary);
  final weight = emphasize ? FontWeight.w800 : FontWeight.w400;
  if (numeric) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppThemes.numeralStyle(
        context,
        fontSize: 14,
        fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
        color: resolved,
      ),
    );
  }
  return Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(fontSize: 14, fontWeight: weight, color: resolved),
  );
}

class TajReportTable extends StatefulWidget {
  const TajReportTable({
    super.key,
    required this.columns,
    required this.rows,
    this.totals,
    this.emptyMessage = 'لا توجد بيانات لعرضها ضمن هذه الفترة أو الفلاتر.',
  });

  final List<ReportColumn> columns;
  final List<ReportRow> rows;

  /// Optional grand-totals row, pinned to the bottom and immune to scroll.
  final ReportRow? totals;

  final String emptyMessage;

  @override
  State<TajReportTable> createState() => _TajReportTableState();
}

class _TajReportTableState extends State<TajReportTable> {
  static const double _rowHeight = 52;
  static const double _headerHeight = 44;
  static const double _emptyMinHeight = 180;

  final _bodyH = ScrollController();
  final _headerH = ScrollController();
  final _totalsH = ScrollController();

  @override
  void initState() {
    super.initState();
    _bodyH.addListener(_sync);
  }

  void _sync() {
    if (!_bodyH.hasClients) return;
    for (final c in [_headerH, _totalsH]) {
      if (c.hasClients) {
        final target = _bodyH.offset.clamp(0.0, c.position.maxScrollExtent);
        if ((c.offset - target).abs() > 0.5) c.jumpTo(target);
      }
    }
  }

  @override
  void dispose() {
    _bodyH.dispose();
    _headerH.dispose();
    _totalsH.dispose();
    super.dispose();
  }

  /// Decide which columns are visible at [available] width. Sticky and numeric
  /// columns (plus priority-0 descriptive ones) are always kept; collapsible
  /// descriptive columns are added back — lowest `priority` first — only while
  /// they still fit, so amounts are never dropped and the name never collapses.
  List<int> _visibleIndices(double available) {
    final cols = widget.columns;
    final mandatory = <int>[];
    final optional = <int>[];
    for (var i = 0; i < cols.length; i++) {
      if (cols[i]._collapsible) {
        optional.add(i);
      } else {
        mandatory.add(i);
      }
    }
    // Lowest-priority (most important) collapsible columns come back first.
    optional.sort((a, b) {
      final byPriority = cols[a].priority.compareTo(cols[b].priority);
      return byPriority != 0 ? byPriority : a.compareTo(b);
    });

    var used = mandatory.fold<double>(0, (s, i) => s + cols[i].minWidth);
    final kept = {...mandatory};
    for (final i in optional) {
      final next = used + cols[i].minWidth;
      if (next <= available) {
        kept.add(i);
        used = next;
      }
    }
    final result = [for (var i = 0; i < cols.length; i++) if (kept.contains(i)) i];
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, c) {
        final cols = widget.columns;
        final visible = _visibleIndices(c.maxWidth);

        // Split the visible columns into the frozen leading run of sticky
        // columns and the (horizontally scrollable) rest.
        final frozen = <int>[];
        final rest = <int>[];
        var stillFrozen = true;
        for (final i in visible) {
          if (stillFrozen && cols[i].sticky) {
            frozen.add(i);
          } else {
            stillFrozen = false;
            rest.add(i);
          }
        }
        // Guarantee at least one frozen column so the name stays put.
        if (frozen.isEmpty && rest.isNotEmpty) {
          frozen.add(rest.removeAt(0));
        }

        // Column widths: start from the minima, then share any slack among
        // flex columns (falling back to descriptive columns, then all).
        final width = <int, double>{
          for (final i in visible) i: cols[i].minWidth,
        };
        final sumMin = visible.fold<double>(0, (s, i) => s + cols[i].minWidth);
        final slack = math.max(0.0, c.maxWidth - sumMin);
        if (slack > 0) {
          var flexTotal = visible.fold<int>(0, (s, i) => s + cols[i].flex);
          List<int> targets;
          if (flexTotal > 0) {
            targets = [for (final i in visible) if (cols[i].flex > 0) i];
          } else {
            targets = [for (final i in visible) if (!cols[i].numeric) i];
            if (targets.isEmpty) targets = visible;
            flexTotal = targets.length; // equal share
          }
          for (final i in targets) {
            final share = cols[i].flex > 0
                ? slack * cols[i].flex / flexTotal
                : slack / flexTotal;
            width[i] = width[i]! + share;
          }
        }

        var frozenWidth = frozen.fold<double>(0, (s, i) => s + width[i]!);
        // Never let the frozen group starve the scrollable rest of the pane: on
        // an extremely narrow width, shrink the first frozen (name) column so
        // the rest region keeps room to exist (and scroll) instead of forcing a
        // negative-width Expanded.
        if (rest.isNotEmpty && frozenWidth > c.maxWidth - 56 && frozen.isNotEmpty) {
          final target = math.max(0.0, c.maxWidth - 56);
          final excess = frozenWidth - target;
          final first = frozen.first;
          width[first] = math.max(60.0, width[first]! - excess);
          frozenWidth = frozen.fold<double>(0, (s, i) => s + width[i]!);
        }
        final restWidth = rest.fold<double>(0, (s, i) => s + width[i]!);

        // A run of cells sized to their columns. The leading gutter and any
        // hierarchical indent live *inside* the first cell's box, so the row's
        // total width equals the sum of the column widths exactly (no overflow).
        Widget runCells({
          required List<int> indices,
          required Widget Function(int i) build,
          double leadingGutter = 0,
          double indent = 0,
        }) {
          return Row(
            children: [
              for (var k = 0; k < indices.length; k++)
                SizedBox(
                  width: width[indices[k]]!,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: k == 0 ? leadingGutter + indent : 0,
                      end: 12,
                    ),
                    child: Align(
                      alignment: cols[indices[k]].numeric
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: build(indices[k]),
                    ),
                  ),
                ),
            ],
          );
        }

        Widget headerContent(int i) => Text(
              cols[i].label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(
                color: taj.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            );

        Widget rowContent(ReportRow r, int i) =>
            i < r.cells.length ? r.cells[i] : const SizedBox();

        double indentFor(ReportRow r) => math.min(
            r.depth * AppBreakpoints.reportIndentStep,
            AppBreakpoints.reportMaxIndent);

        // ---- Header (pinned) ----
        final header = DecoratedBox(
          decoration: BoxDecoration(
            color: taj.paper,
            border: Border(bottom: BorderSide(color: taj.divider)),
          ),
          child: SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                SizedBox(
                  width: frozenWidth,
                  child: runCells(
                    indices: frozen,
                    build: headerContent,
                    leadingGutter: 16,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerH,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: restWidth,
                      child: runCells(indices: rest, build: headerContent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // ---- Body ----
        Widget body;
        if (widget.rows.isEmpty) {
          body = _EmptyBody(message: widget.emptyMessage, minHeight: _emptyMinHeight);
        } else {
          body = SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Frozen leading column(s) — vertical scroll only.
                SizedBox(
                  width: frozenWidth,
                  child: Column(
                    children: [
                      for (final r in widget.rows)
                        _RowShell(
                          height: _rowHeight,
                          selected: r.selected,
                          emphasize: r.emphasize,
                          onTap: r.onTap,
                          child: runCells(
                            indices: frozen,
                            build: (i) => rowContent(r, i),
                            leadingGutter: 16,
                            indent: indentFor(r),
                          ),
                        ),
                    ],
                  ),
                ),
                // Scrollable rest.
                Expanded(
                  child: SingleChildScrollView(
                    controller: _bodyH,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: restWidth,
                      child: Column(
                        children: [
                          for (final r in widget.rows)
                            _RowShell(
                              height: _rowHeight,
                              selected: r.selected,
                              emphasize: r.emphasize,
                              onTap: r.onTap,
                              child: runCells(
                                indices: rest,
                                build: (i) => rowContent(r, i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // ---- Totals (pinned) ----
        Widget? totals;
        final t = widget.totals;
        if (t != null) {
          totals = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(height: 1, color: taj.divider),
              Container(
                color: taj.background,
                height: _rowHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: frozenWidth,
                      child: runCells(
                        indices: frozen,
                        build: (i) => rowContent(t, i),
                        leadingGutter: 16,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _totalsH,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: restWidth,
                          child: runCells(indices: rest, build: (i) => rowContent(t, i)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: taj.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: taj.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              header,
              Expanded(child: body),
              if (totals != null) totals,
            ],
          ),
        );
      },
    );
  }
}

/// One body row: fixed height, hover, selection tint, and an emphasize tint for
/// subtotal / total rows. Never grows — cells ellipsize so row height is
/// predictable and the pinned totals math stays exact.
class _RowShell extends StatefulWidget {
  const _RowShell({
    required this.height,
    required this.child,
    this.selected = false,
    this.emphasize = false,
    this.onTap,
  });

  final double height;
  final Widget child;
  final bool selected;
  final bool emphasize;
  final VoidCallback? onTap;

  @override
  State<_RowShell> createState() => _RowShellState();
}

class _RowShellState extends State<_RowShell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final bg = widget.selected
        ? taj.primary.lighter
        : _hover && widget.onTap != null
            ? taj.hover
            : widget.emphasize
                ? taj.background
                : Colors.transparent;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bg,
            border: Border(bottom: BorderSide(color: taj.divider)),
          ),
          alignment: AlignmentDirectional.centerStart,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Empty-body placeholder that keeps a minimum height so the table never
/// collapses on a short screen and a large icon can't overflow it.
class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.message, required this.minHeight});
  final String message;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 30, color: taj.textDisabled),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: taj.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
