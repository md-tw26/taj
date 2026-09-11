import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import 'assistant_models.dart';

/// A compact chart for an answer bubble / side panel. Its height is derived
/// from the available width via [AspectRatio] (never fixed, never unbounded);
/// below [AppBreakpoints.chatChartMinHeight] it degrades to a numeric summary.
/// A wrapping legend sits below and never widens the container.
class AnswerChartView extends StatelessWidget {
  const AnswerChartView({super.key, required this.chart, this.maxHeight});
  final AnswerChart chart;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final palette = _palette(context);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final aspect = w < 320
            ? AppBreakpoints.chartAspectPhone
            : (w < 460 ? AppBreakpoints.chartAspectMid : AppBreakpoints.chartAspectWideR);
        var plotH = w / aspect;
        if (maxHeight != null) plotH = math.min(plotH, maxHeight!);

        if (!chart.hasData) {
          return _box(context, plotH, child: _empty(context));
        }
        if (plotH < AppBreakpoints.chatChartMinHeight) {
          return _box(context, math.max(plotH, 72), child: _numeric(context));
        }

        final painter = switch (chart.kind) {
          AnswerChartKind.donut => _DonutPainter(values: chart.values, palette: palette, hole: context.taj.paper),
          AnswerChartKind.line => _LinePainter(values: chart.values, color: palette.first, grid: context.taj.divider, rtl: rtl),
          AnswerChartKind.bars => _BarsPainter(values: chart.values, palette: palette, grid: context.taj.divider, rtl: rtl),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: plotH, child: CustomPaint(size: Size.infinite, painter: painter)),
            const SizedBox(height: 8),
            _Legend(labels: chart.labels, values: chart.values, palette: palette, unit: chart.unit),
          ],
        );
      },
    );
  }

  Widget _box(BuildContext context, double h, {required Widget child}) => SizedBox(
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.taj.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.taj.divider),
          ),
          child: Center(child: child),
        ),
      );

  Widget _empty(BuildContext context) => Text('لا توجد بيانات كافية',
      style: TextStyle(color: context.taj.textDisabled, fontSize: 12));

  Widget _numeric(BuildContext context) {
    var maxI = 0;
    for (var i = 1; i < chart.values.length; i++) {
      if (chart.values[i] > chart.values[maxI]) maxI = i;
    }
    final label = chart.values.isEmpty || maxI >= chart.labels.length ? '' : chart.labels[maxI];
    final val = chart.values.isEmpty ? '—' : arNumCompact(chart.values[maxI]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$val${chart.unit == null ? '' : ' ${chart.unit}'}',
            style: AppThemes.numeralStyle(context, fontSize: 18, fontWeight: FontWeight.w800)),
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.taj.textSecondary, fontSize: 12)),
          ),
      ],
    );
  }
}

List<Color> _palette(BuildContext c) {
  final t = c.taj;
  return [t.primary.main, t.info.main, t.warning.main, t.success.main, t.secondary.main, t.error.main, t.primary.light, t.info.dark];
}

class _Legend extends StatelessWidget {
  const _Legend({required this.labels, required this.values, required this.palette, this.unit});
  final List<String> labels;
  final List<double> values;
  final List<Color> palette;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    const maxVisible = 6;
    final n = math.min(labels.length, maxVisible);
    final hidden = labels.length - n;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (var i = 0; i < n; i++)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: palette[i % palette.length], borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 6),
                Flexible(child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: taj.textSecondary))),
                const SizedBox(width: 6),
                Text(unit == null ? arNumCompact(values[i]) : '${arNumCompact(values[i])} $unit',
                    style: AppThemes.numeralStyle(context, fontSize: 12, fontWeight: FontWeight.w700, color: taj.textPrimary)),
              ],
            ),
          ),
        if (hidden > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: taj.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: taj.divider)),
            child: Text('+$hidden', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: taj.textSecondary)),
          ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.values, required this.palette, required this.grid, required this.rtl});
  final List<double> values;
  final List<Color> palette;
  final Color grid;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.fold<double>(0, (m, v) => math.max(m, v));
    final safeMax = maxV <= 0 ? 1.0 : maxV;
    final n = values.length;
    final slot = size.width / n;
    final barW = math.min(slot * 0.6, 44.0);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), Paint()..color = grid..strokeWidth = 1);
    for (var i = 0; i < n; i++) {
      final slotLeft = rtl ? size.width - (i + 1) * slot : i * slot;
      final cx = slotLeft + slot / 2;
      final h = (values[i] / safeMax) * (size.height - 4);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, size.height - h, barW, h),
        topLeft: const Radius.circular(4), topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = palette[i % palette.length]);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.values != values || old.rtl != rtl;
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.values, required this.color, required this.grid, required this.rtl});
  final List<double> values;
  final Color color;
  final Color grid;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    double xAt(int i) {
      final t = i / (values.length - 1);
      return rtl ? size.width * (1 - t) : size.width * t;
    }
    double yAt(double v) => size.height - ((v - minV) / range) * (size.height - 4) - 2;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), Paint()..color = grid..strokeWidth = 1);
    final path = Path()..moveTo(xAt(0), yAt(values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(xAt(i), yAt(values[i]));
    }
    final fill = Path.from(path)
      ..lineTo(xAt(values.length - 1), size.height)
      ..lineTo(xAt(0), size.height)
      ..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)]).createShader(Offset.zero & size));
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(Offset(xAt(i), yAt(values[i])), 2.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values || old.rtl != rtl;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.palette, required this.hole});
  final List<double> values;
  final List<Color> palette;
  final Color hole;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (s, v) => s + v.abs());
    if (total <= 0) return;
    final side = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = side / 2 - 2;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i].abs() / total) * 2 * math.pi;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, true, Paint()..color = palette[i % palette.length]);
      start += sweep;
    }
    canvas.drawCircle(center, radius * 0.58, Paint()..color = hole);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.values != values;
}
