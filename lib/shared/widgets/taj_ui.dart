import 'package:flutter/material.dart';

import '../../core/chart_style.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';

/// A clean **Notion-style** card: paper surface, hairline border, soft shadow,
/// generous padding. Lifts slightly on hover when [onTap] is set.
class TajCard extends StatefulWidget {
  const TajCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.topStrip,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Optional thin colour strip across the top edge (Notion category accent).
  final Color? topStrip;
  final double radius;

  @override
  State<TajCard> createState() => _TajCardState();
}

class _TajCardState extends State<TajCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final interactive = widget.onTap != null;

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: _hover && interactive ? taj.textDisabled : taj.divider,
        ),
        boxShadow: _hover && interactive ? AppThemes.cardShadow(context) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.topStrip != null)
              Container(height: 4, color: widget.topStrip),
            Padding(padding: widget.padding, child: widget.child),
          ],
        ),
      ),
    );

    if (!interactive) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}

/// A pill status badge — background is the hue's `lighter`, text its `dark`.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.status,
    this.icon,
  });

  final String label;
  final TajStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final s = context.taj.swatch(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon == null ? 10 : 8, vertical: 5),
      decoration: BoxDecoration(
        color: s.lighter,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: s.dark),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: s.dark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A page/section heading with optional subtitle and trailing action.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: text.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!,
              style: text.bodyMedium?.copyWith(color: taj.textSecondary)),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        // When space is tight the title + trailing actions can't share a row
        // without truncating the heading or overflowing the actions. Below the
        // phone breakpoint we stack the actions under the title instead.
        final stack = trailing != null && c.maxWidth < AppBreakpoints.phone;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: trailing!,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            if (trailing != null) ...[const SizedBox(width: 16), trailing!],
          ],
        );
      },
    );
  }
}

/// A KPI card: label, big tabular value, coloured delta chip and a sparkline.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaPositive = true,
    this.icon,
    this.spark = const [],
    this.onTap,
  });

  final String label;
  final String value;
  final String? delta;
  final bool deltaPositive;
  final IconData? icon;
  final List<double> spark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final deltaSwatch = deltaPositive ? taj.success : taj.error;

    return TajCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: taj.primary.lighter,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: taj.primary.dark),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(label,
                    style: text.bodyMedium?.copyWith(color: taj.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: AppThemes.numeralStyle(context, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (delta != null)
                _DeltaChip(text: delta!, swatch: deltaSwatch, up: deltaPositive),
              const SizedBox(width: 8),
              // Sparkline caps at 84px and right-aligns on wide cards, but is
              // free to shrink so a narrow KPI tile never overflows this row.
              if (spark.length > 1)
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 84, maxHeight: 30),
                      child: Sparkline(values: spark, color: taj.primary.main),
                    ),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.text, required this.swatch, required this.up});
  final String text;
  final TajSwatch swatch;
  final bool up;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: swatch.lighter,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 13, color: swatch.dark),
          const SizedBox(width: 2),
          Text(text,
              style: AppThemes.numeralStyle(context,
                  fontSize: 12, fontWeight: FontWeight.w700, color: swatch.dark)),
        ],
      ),
    );
  }
}

/// A minimal trend chart used inside KPI cards and the dashboard. Renders as a
/// filled **area**, a bare **line**, or **bars** per [style] (default: area).
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.style = ChartStyle.area,
  });
  final List<double> values;
  final Color color;
  final ChartStyle style;

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: Size.infinite, painter: _SparkPainter(values, color, style));
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.style);
  final List<double> values;
  final Color color;
  final ChartStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    // Bars: proportional to the max, drawn up from the baseline.
    if (style == ChartStyle.bars) {
      final n = values.length;
      const gap = 3.0;
      final barW = ((size.width - gap * (n - 1)) / n).clamp(1.0, size.width);
      final safeMax = maxV == 0 ? 1 : maxV;
      final paint = Paint()..color = color.withValues(alpha: 0.85);
      for (var i = 0; i < n; i++) {
        final h = (values[i] / safeMax) * size.height;
        final left = i * (barW + gap);
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(left, size.height - h, barW, h),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        );
        canvas.drawRRect(rect, paint);
      }
      return;
    }

    final dx = size.width / (values.length - 1);
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(i * dx, size.height - ((values[i] - minV) / range) * size.height),
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final cx = (pts[i].dx + pts[i + 1].dx) / 2;
      path.cubicTo(cx, pts[i].dy, cx, pts[i + 1].dy, pts[i + 1].dx, pts[i + 1].dy);
    }

    // Area fill only in area mode; the line stroke is shared with line mode.
    if (style == ChartStyle.area) {
      final fill = Path.from(path)
        ..lineTo(pts.last.dx, size.height)
        ..lineTo(pts.first.dx, size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.24), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color || old.style != style;
}

/// Designed empty state: icon, title, message and an optional primary action.
class TajEmptyState extends StatelessWidget {
  const TajEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: taj.background,
                shape: BoxShape.circle,
                border: Border.all(color: taj.divider),
              ),
              child: Icon(icon, size: 32, color: taj.textDisabled),
            ),
            const SizedBox(height: 16),
            Text(title, style: text.titleMedium),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: taj.textSecondary)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Clear error state with an optional retry.
class TajErrorState extends StatelessWidget {
  const TajErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: taj.error.main),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: taj.textPrimary)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A pulsing grey skeleton block for loading states.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });
  final double width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? TajGrey.g700
        : TajGrey.g200;
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
