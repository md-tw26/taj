import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../core/theme/taj_colors.dart';

/// One active filter chip: `[field] [operator] [value] (✕)`.
class TajFilter {
  const TajFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final String operator;
  final String value;
}

/// A **ClickUp-style** filter bar: an "+ Add filter" trigger, chips combined by
/// an AND/OR toggle, plus Group-by / Sort-by affordances and a clear-all.
class TajFilterBar extends StatelessWidget {
  const TajFilterBar({
    super.key,
    this.filters = const [],
    this.conjunction = 'و',
    this.onAdd,
    this.onRemove,
    this.onClearAll,
    this.onGroupBy,
    this.onSortBy,
  });

  final List<TajFilter> filters;
  final String conjunction; // "و" (AND) / "أو" (OR)
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;
  final VoidCallback? onClearAll;
  final VoidCallback? onGroupBy;
  final VoidCallback? onSortBy;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    final filterChildren = <Widget>[
      _AddButton(onTap: onAdd),
      for (var i = 0; i < filters.length; i++) ...[
        if (i > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(conjunction,
                style: text.bodySmall?.copyWith(color: taj.textDisabled)),
          ),
        _FilterChip(filter: filters[i], onRemove: () => onRemove?.call(i)),
      ],
    ];

    final controls = <Widget>[
      _GhostButton(icon: Icons.dashboard_outlined, label: 'تجميع', onTap: onGroupBy),
      _GhostButton(icon: Icons.swap_vert_rounded, label: 'ترتيب', onTap: onSortBy),
      if (filters.isNotEmpty)
        TextButton(
          onPressed: onClearAll,
          child: Text('مسح الكل (${filters.length})'),
        ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        // On tight widths a fixed row of chips + group/sort/clear can exceed the
        // available space. Collapse everything into a single wrapping flow so it
        // reflows onto multiple lines instead of overflowing.
        if (c.maxWidth < AppBreakpoints.phone) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [...filterChildren, ...controls],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Wrap(spacing: 8, runSpacing: 8, children: filterChildren),
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < controls.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              controls[i],
            ],
          ],
        );
      },
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return _Pill(
      onTap: onTap,
      dashed: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_rounded, size: 16, color: taj.textSecondary),
          const SizedBox(width: 4),
          Text('إضافة فلتر',
              style: text.labelMedium?.copyWith(color: taj.textSecondary)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.filter, this.onRemove});
  final TajFilter filter;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return _Pill(
      // Cap the chip so a long value ellipsizes instead of exceeding the bar
      // width on small screens (Wrap children can't shrink on their own).
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(filter.field,
              style: text.labelMedium?.copyWith(color: taj.textSecondary)),
          const SizedBox(width: 5),
          Text(filter.operator,
              style: text.labelMedium?.copyWith(color: taj.textDisabled)),
          const SizedBox(width: 5),
          // Ellipsize a long value instead of pushing the chip past the bar.
          Flexible(
            child: Text(filter.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(
                    color: taj.accentText, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 15, color: taj.textSecondary),
          ),
        ],
      ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return _Pill(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: taj.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: text.labelMedium?.copyWith(color: taj.textSecondary)),
        ],
      ),
    );
  }
}

/// Shared pill container for filter-bar controls.
class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.onTap, this.dashed = false});
  final Widget child;
  final VoidCallback? onTap;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: taj.paper,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: taj.divider,
              style: dashed ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
