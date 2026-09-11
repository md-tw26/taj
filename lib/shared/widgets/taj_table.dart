import 'package:flutter/material.dart';

import '../../core/theme/taj_colors.dart';

/// A column definition for [TajTable].
class TajColumn {
  const TajColumn(this.label, {this.flex = 1, this.numeric = false});

  final String label;
  final int flex;

  /// Numeric columns are end-aligned (with tabular figures at the cell level).
  final bool numeric;
}

/// One row's data: cell widgets aligned to [TajTable.columns], an optional tap
/// target, and optional trailing actions revealed on hover.
class TajRowData {
  const TajRowData({required this.cells, this.onTap, this.actions});

  final List<Widget> cells;
  final VoidCallback? onTap;
  final List<Widget>? actions;
}

/// A **Stripe-style** data table: small grey headers, comfortable rows, sticky
/// hairline dividers, row hover, and trailing per-row actions.
///
/// Columns share the available width via their [TajColumn.flex]. On viewports
/// too narrow to show every column comfortably (phones), the table keeps a
/// sensible minimum width and scrolls horizontally instead of crushing cells
/// until badges and figures overflow — readability over cramming.
class TajTable extends StatelessWidget {
  const TajTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 620,
  });

  final List<TajColumn> columns;
  final List<TajRowData> rows;

  /// Below this width the table becomes horizontally scrollable.
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final hasActions = rows.any((r) => r.actions != null);

    final table = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              for (final c in columns)
                Expanded(
                  flex: c.flex,
                  child: Align(
                    alignment: c.numeric
                        ? AlignmentDirectional.centerEnd
                        : AlignmentDirectional.centerStart,
                    child: Text(
                      c.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: taj.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (hasActions) const SizedBox(width: 48),
            ],
          ),
        ),
        Divider(height: 1, color: taj.divider),
        for (final r in rows)
          _TableRow(columns: columns, row: r, hasActions: hasActions),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= minWidth) return table;
        // Give the table its minimum comfortable width and let the user scroll
        // it sideways rather than overflow the cell contents.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: table),
        );
      },
    );
  }
}

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.columns,
    required this.row,
    required this.hasActions,
  });

  final List<TajColumn> columns;
  final TajRowData row;
  final bool hasActions;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final cells = widget.row.cells;

    return MouseRegion(
      cursor: widget.row.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.row.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hover ? taj.hover : Colors.transparent,
            border: Border(bottom: BorderSide(color: taj.divider)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              for (var i = 0; i < widget.columns.length; i++)
                Expanded(
                  flex: widget.columns[i].flex,
                  child: Align(
                    alignment: widget.columns[i].numeric
                        ? AlignmentDirectional.centerEnd
                        : AlignmentDirectional.centerStart,
                    child: i < cells.length ? cells[i] : const SizedBox(),
                  ),
                ),
              if (widget.hasActions)
                SizedBox(
                  width: 48,
                  child: AnimatedOpacity(
                    opacity: _hover ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: widget.row.actions ?? const [],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
