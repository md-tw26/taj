import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import 'report_models.dart';

/// Renders a [ReportChartData] as a bar / line / donut chart. The chart is
/// always given a **bounded height** via [AspectRatio] (chosen by the caller
/// from the size class), its legend wraps below it when the width is narrow,
/// and category names live in the legend rather than being crammed under bars —
/// so axis labels never collide or overflow. All-zero or empty data degrades to
/// a calm placeholder instead of dividing by zero.
class ReportChart extends StatelessWidget {
  const ReportChart({super.key, required this.data, required this.aspect});

  final ReportChartData data;
  final double aspect;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final values = data.series.isEmpty ? const <double>[] : data.series.first.values;
    final hasData = values.any((v) => v != 0);
    final palette = _palette(context);
    String fmt(double v) => (data.valueFormatter ?? arNumCompact)(v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: aspect,
          child: !hasData
              ? _Placeholder()
              : CustomPaint(
                  painter: switch (data.type) {
                    ReportChartType.donut =>
                      _DonutPainter(values: values, colors: palette, holeColor: taj.paper),
                    ReportChartType.line => _LinePainter(
                        values: values,
                        color: data.series.first.color,
                        grid: taj.divider,
                        label: (v) => fmt(v),
                        labelColor: taj.textSecondary,
                      ),
                    ReportChartType.bars => _BarsPainter(
                        values: values,
                        colors: palette,
                        grid: taj.divider,
                        label: (v) => fmt(v),
                        labelColor: taj.textSecondary,
                      ),
                  },
                ),
        ),
        if (hasData) ...[
          const SizedBox(height: 12),
          _Legend(
            type: data.type,
            labels: data.labels,
            values: values,
            colors: palette,
            format: fmt,
            singleColor: data.type == ReportChartType.line ? data.series.first.color : null,
            seriesLabel: data.series.isEmpty ? '' : data.series.first.label,
          ),
        ],
      ],
    );
  }
}

List<Color> _palette(BuildContext c) {
  final t = c.taj;
  return [
    t.primary.main,
    t.info.main,
    t.warning.main,
    t.success.main,
    t.secondary.main,
    t.error.main,
    t.primary.light,
    t.info.dark,
  ];
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taj.divider),
      ),
      child: Center(
        child: Text('لا توجد بيانات كافية للرسم',
            style: TextStyle(color: taj.textDisabled, fontSize: 12)),
      ),
    );
  }
}

/// Colour-dot / label / value chips that wrap below the chart.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.type,
    required this.labels,
    required this.values,
    required this.colors,
    required this.format,
    required this.seriesLabel,
    this.singleColor,
  });

  final ReportChartType type;
  final List<String> labels;
  final List<double> values;
  final List<Color> colors;
  final String Function(double) format;
  final String seriesLabel;
  final Color? singleColor;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    // A line chart labels its single series with start→end, not per point.
    if (type == ReportChartType.line) {
      final start = values.isEmpty ? 0.0 : values.first;
      final end = values.isEmpty ? 0.0 : values.last;
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _chip(context, singleColor ?? taj.primary.main, seriesLabel,
              '${format(start)} ← ${format(end)}'),
        ],
      );
    }
    final total = values.fold<double>(0, (s, v) => s + v.abs());
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (var i = 0; i < values.length; i++)
          _chip(
            context,
            colors[i % colors.length],
            i < labels.length ? labels[i] : '',
            type == ReportChartType.donut && total > 0
                ? '${format(values[i])} · ${((values[i].abs() / total) * 100).round()}%'
                : format(values[i]),
          ),
      ],
    );
  }

  Widget _chip(BuildContext context, Color color, String label, String value) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: taj.textSecondary)),
          ),
          const SizedBox(width: 6),
          Text(value,
              style: AppThemes.numeralStyle(context,
                  fontSize: 12, fontWeight: FontWeight.w700, color: taj.textPrimary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

TextPainter _tp(String s, Color color, {double size = 12}) => TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.colors,
    required this.grid,
    required this.label,
    required this.labelColor,
  });
  final List<double> values;
  final List<Color> colors;
  final Color grid;
  final String Function(double) label;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const topPad = 18.0; // room for value labels above bars
    const bottomPad = 4.0;
    final maxV = values.fold<double>(0, (m, v) => math.max(m, v));
    final minV = values.fold<double>(0, (m, v) => math.min(m, v));
    final hasNeg = minV < 0;
    final span = (maxV - math.min(0, minV));
    final safeSpan = span == 0 ? 1 : span;
    final chartH = size.height - topPad - bottomPad;
    // Baseline (value 0) position.
    final zeroY = topPad + (maxV / safeSpan) * chartH;

    // Zero baseline.
    canvas.drawLine(
      Offset(0, hasNeg ? zeroY : size.height - bottomPad),
      Offset(size.width, hasNeg ? zeroY : size.height - bottomPad),
      Paint()..color = grid..strokeWidth = 1,
    );

    final n = values.length;
    final gap = n > 8 ? 4.0 : 10.0;
    final barW = math.max(2.0, (size.width - gap * (n + 1)) / n);
    for (var i = 0; i < n; i++) {
      final left = gap + i * (barW + gap);
      final v = values[i];
      final barTop = hasNeg
          ? (v >= 0 ? zeroY - (v / safeSpan) * chartH : zeroY)
          : size.height - bottomPad - (v / safeSpan) * chartH;
      final barBottom = hasNeg
          ? (v >= 0 ? zeroY : zeroY + (v.abs() / safeSpan) * chartH)
          : size.height - bottomPad;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, math.min(barTop, barBottom), left + barW, math.max(barTop, barBottom)),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = colors[i % colors.length]);

      // Value label above (or below for negatives) — only if the bar is wide
      // enough to carry a ≥12sp label without colliding with neighbours.
      if (barW >= 40) {
        final tp = _tp(label(v), labelColor, size: 12);
        final lx = (left + barW / 2 - tp.width / 2).clamp(0.0, size.width - tp.width);
        final ly = v >= 0
            ? math.min(barTop, barBottom) - tp.height - 2
            : math.max(barTop, barBottom) + 2;
        if (ly >= 0 && ly + tp.height <= size.height) tp.paint(canvas, Offset(lx, ly));
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.values != values;
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.color,
    required this.grid,
    required this.label,
    required this.labelColor,
  });
  final List<double> values;
  final Color color;
  final Color grid;
  final String Function(double) label;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const pad = 6.0;
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final chartH = size.height - pad * 2;
    final dx = size.width / (values.length - 1);
    Offset pt(int i) =>
        Offset(i * dx, pad + chartH - ((values[i] - minV) / range) * chartH);

    // Faint gridlines at top/bottom.
    for (final y in [pad, pad + chartH]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          Paint()..color = grid..strokeWidth = 1);
    }

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    // Area under the line.
    final fill = Path.from(path)
      ..lineTo(size.width, size.height - pad)
      ..lineTo(0, size.height - pad)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(pt(i), 2.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors, required this.holeColor});
  final List<double> values;
  final List<Color> colors;
  final Color holeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (s, v) => s + v.abs());
    if (total <= 0) return;
    final side = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = side / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i].abs() / total) * 2 * math.pi;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()..color = colors[i % colors.length],
      );
      start += sweep;
    }
    // Punch the hole.
    canvas.drawCircle(center, radius * 0.58, Paint()..color = holeColor);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.values != values;
}
