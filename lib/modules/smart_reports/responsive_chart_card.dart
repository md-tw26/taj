import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_ui.dart';
import 'smart_models.dart';

/// The one shared chart wrapper for the analytics module.
///
/// A chart needs a concrete size, but everything around it is fluid — so this
/// card, and only this card, decides the responsive geometry from the space
/// actually available to it (its own `LayoutBuilder` width/height):
///
///  * **aspect ratio** by width (4/3 narrow → 3/2 → 16/9 wide) — the plot height
///    is derived from the width, never fixed, never in an unbounded column;
///  * a **minimum plot height**: below it the plot would be distorted, so the
///    card shows a **numeric summary** at that same height instead (the grid
///    never jumps between a chart and its fallback, nor between empty and data);
///  * **loading** and **not-enough-data** states rendered at the same height;
///  * a **legend** that always wraps with a "+N" overflow and can move *beside*
///    the plot on a short viewport to save vertical space.
///
/// Long category names, too-many categories, RTL mirroring, and tooltip
/// clamping are handled by the interactive plot below — never per chart.
class ResponsiveChartCard extends StatelessWidget {
  const ResponsiveChartCard({
    super.key,
    required this.spec,
    this.loading = false,
    this.maxHeight,
    this.legendBeside = false,
  });

  final ChartSpec spec;
  final bool loading;

  /// Optional cap on the plot height (short viewports / landscape phone).
  final double? maxHeight;

  /// Place the legend beside the plot instead of below it (saves height).
  final bool legendBeside;

  static double aspectFor(double width) {
    if (width < AppBreakpoints.chartAspectTall) return AppBreakpoints.chartAspectPhone;
    if (width < AppBreakpoints.chartAspectWide) return AppBreakpoints.chartAspectMid;
    return AppBreakpoints.chartAspectWideR;
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return TajCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          final cardW = c.maxWidth;
          final palette = _palette(context);

          final primary = spec.series.isEmpty ? const <double>[] : spec.series.first.values;
          final noData = spec.series.isEmpty ||
              spec.series.every((s) => s.values.every((v) => v == 0)) ||
              (spec.labels.isEmpty && spec.kind != SmartChartKind.line);

          // Long Arabic names or a narrow card → horizontal bars (full names on
          // the leading side rather than squeezed vertical labels).
          final longNames = spec.labels.any((l) => l.length > 10);
          final horizontalBars =
              spec.kind == SmartChartKind.bars && (longNames || cardW < 420);

          // Grouping + plot height are decided here (single source of truth),
          // so the plot and its legend always agree on the categories/colours.
          var catLabels = spec.labels;
          var catValues = primary;
          double plotH;
          var numericFallback = false;

          switch (spec.kind) {
            case SmartChartKind.bars when horizontalBars:
              final g = _topN(spec.labels, primary, AppBreakpoints.chartMaxCategories);
              catLabels = g.labels;
              catValues = g.values;
              final rowH = maxHeight != null
                  ? (maxHeight! / math.max(1, catValues.length)).clamp(26.0, 40.0)
                  : 34.0;
              plotH = math.max(90.0, catValues.length * rowH);
            case SmartChartKind.bars:
              // Adaptive: fit as many bars as the width allows at the min slot,
              // group the tail into "أخرى" rather than squeezing.
              final cap = math.max(3, (cardW / AppBreakpoints.chartBarMinSlot).floor());
              final g = _topN(spec.labels, primary, cap);
              catLabels = g.labels;
              catValues = g.values;
              plotH = _plotForAspect(cardW);
              if (plotH < AppBreakpoints.chartMinHeight) {
                numericFallback = true;
                plotH = AppBreakpoints.chartMinHeight;
              }
            case SmartChartKind.donut:
              final g = _topN(spec.labels, primary, AppBreakpoints.chartMaxCategories);
              catLabels = g.labels;
              catValues = g.values;
              plotH = _plotForAspect(cardW);
              if (plotH < AppBreakpoints.chartMinHeight) {
                numericFallback = true;
                plotH = AppBreakpoints.chartMinHeight;
              }
            case SmartChartKind.line:
            case SmartChartKind.area:
              plotH = _plotForAspect(cardW);
              if (plotH < AppBreakpoints.chartMinHeight) {
                numericFallback = true;
                plotH = AppBreakpoints.chartMinHeight;
              }
          }

          final header = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(spec.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (spec.subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(spec.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: taj.textSecondary)),
                ),
            ],
          );

          Widget plot;
          if (loading) {
            plot = SizedBox(height: plotH, child: SkeletonBox(height: plotH, radius: 12));
          } else if (noData) {
            plot = _NotEnoughData(height: plotH);
          } else if (numericFallback) {
            plot = _NumericSummary(spec: spec, height: plotH, palette: palette);
          } else {
            plot = SizedBox(
              height: plotH,
              child: _InteractiveChart(
                spec: spec,
                catLabels: catLabels,
                catValues: catValues,
                horizontalBars: horizontalBars,
                palette: palette,
                rtl: rtl,
              ),
            );
          }

          final legendItems =
              (loading || noData) ? const <_LegendItem>[] : _legendItems(context, palette, catLabels, catValues);
          final legend =
              legendItems.isEmpty ? const SizedBox.shrink() : _Legend(items: legendItems, beside: legendBeside);

          final body = legendBeside && legendItems.isNotEmpty
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: plot),
                    const SizedBox(width: 12),
                    SizedBox(width: 120, child: legend),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    plot,
                    if (legendItems.isNotEmpty) ...[const SizedBox(height: 10), legend],
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [header, const SizedBox(height: 12), body],
          );
        },
      ),
    );
  }

  double _plotForAspect(double cardW) {
    var h = cardW / aspectFor(cardW);
    if (maxHeight != null) h = math.min(h, maxHeight!);
    return h;
  }

  List<_LegendItem> _legendItems(
      BuildContext context, List<Color> palette, List<String> catLabels, List<double> catValues) {
    // line/area → one entry per series; bars/donut → one per (grouped) category.
    if (spec.kind == SmartChartKind.line || spec.kind == SmartChartKind.area) {
      if (spec.series.length < 2) return const [];
      return [for (final s in spec.series) _LegendItem(color: s.color, label: s.name)];
    }
    return [
      for (var i = 0; i < catLabels.length; i++)
        _LegendItem(
          color: palette[i % palette.length],
          label: catLabels[i],
          value: i < catValues.length ? _fmt(catValues[i], spec.unit) : null,
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

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

String _fmt(double v, String? unit) =>
    unit == null ? arNumCompact(v) : '${arNumCompact(v)} $unit';

String _fmtExact(double v, String? unit) =>
    unit == null ? arNum(v) : '${arNum(v)} $unit';

String _truncate(String s, int maxChars) =>
    s.length <= maxChars ? s : '${s.substring(0, math.max(1, maxChars - 1))}…';

/// Collapse categories beyond [max] into a trailing "أخرى" bucket — a
/// presentation change only, the source data is untouched.
({List<String> labels, List<double> values}) _topN(
    List<String> labels, List<double> values, int max) {
  if (labels.length <= max) return (labels: labels, values: values);
  final idx = [for (var i = 0; i < values.length; i++) i]
    ..sort((a, b) => values[b].compareTo(values[a]));
  final keep = idx.take(max - 1).toList();
  final outLabels = <String>[for (final i in keep) labels[i]];
  final outValues = <double>[for (final i in keep) values[i]];
  var rest = 0.0;
  for (final i in idx.skip(max - 1)) {
    rest += values[i];
  }
  outLabels.add('أخرى');
  outValues.add(rest);
  return (labels: outLabels, values: outValues);
}

// ---------------------------------------------------------------------------
// State placeholders (kept at the plot height so the grid never jumps)
// ---------------------------------------------------------------------------

class _NotEnoughData extends StatelessWidget {
  const _NotEnoughData({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: taj.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: taj.divider),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bubble_chart_outlined, size: 26, color: taj.textDisabled),
              const SizedBox(height: 8),
              Text('لا توجد بيانات كافية',
                  style: TextStyle(color: taj.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// When the plot would be too short to be legible, show the headline number(s)
/// instead of a distorted chart, at the same height.
class _NumericSummary extends StatelessWidget {
  const _NumericSummary({required this.spec, required this.height, required this.palette});
  final ChartSpec spec;
  final double height;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final values = spec.series.isEmpty ? const <double>[] : spec.series.first.values;
    final total = values.fold<double>(0, (s, v) => s + v);
    // Top category (bars/donut) or series total (line).
    String headline;
    String caption;
    if (spec.kind == SmartChartKind.line || spec.kind == SmartChartKind.area) {
      headline = _fmt(total, spec.unit);
      caption = 'الإجمالي';
    } else {
      var maxI = 0;
      for (var i = 1; i < values.length; i++) {
        if (values[i] > values[maxI]) maxI = i;
      }
      headline = values.isEmpty ? '—' : _fmt(values[maxI], spec.unit);
      caption = values.isEmpty || maxI >= spec.labels.length ? 'الأعلى' : spec.labels[maxI];
    }
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: taj.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: taj.divider),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.numeralStyle(context,
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: taj.textSecondary, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend — always a Wrap with a max line count and a "+N" overflow chip.
// ---------------------------------------------------------------------------

class _LegendItem {
  const _LegendItem({required this.color, required this.label, this.value});
  final Color color;
  final String label;
  final String? value;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items, required this.beside});
  final List<_LegendItem> items;
  final bool beside;

  @override
  Widget build(BuildContext context) {
    // Beside the chart (short viewport): a vertical, scrollable strip.
    if (beside) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final it in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _chip(context, it),
              ),
          ],
        ),
      );
    }
    // Below the chart: wrap to at most N lines, then a "+N" chip. We cap the
    // number of visible items conservatively (≈3 per line) so the legend can
    // never push the chart out of its card.
    final maxVisible = AppBreakpoints.chartLegendMaxLines * 3;
    final visible = items.take(maxVisible).toList();
    final hidden = items.length - visible.length;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final it in visible) _chip(context, it),
        if (hidden > 0) _more(context, hidden),
      ],
    );
  }

  Widget _chip(BuildContext context, _LegendItem it) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: it.color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(it.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: taj.textSecondary)),
          ),
          if (it.value != null) ...[
            const SizedBox(width: 6),
            Text(it.value!,
                style: AppThemes.numeralStyle(context,
                    fontSize: 12, fontWeight: FontWeight.w700, color: taj.textPrimary)),
          ],
        ],
      ),
    );
  }

  Widget _more(BuildContext context, int n) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: taj.divider),
      ),
      child: Text('+$n',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: taj.textSecondary)),
    );
  }
}

// ---------------------------------------------------------------------------
// Interactive chart — hit-tests for a tooltip clamped inside the plot bounds.
// ---------------------------------------------------------------------------

class _InteractiveChart extends StatefulWidget {
  const _InteractiveChart({
    required this.spec,
    required this.catLabels,
    required this.catValues,
    required this.horizontalBars,
    required this.palette,
    required this.rtl,
  });
  final ChartSpec spec;

  /// Already-grouped categories/values (bars/donut). Line/area ignore these and
  /// use [ChartSpec.series] directly.
  final List<String> catLabels;
  final List<double> catValues;
  final bool horizontalBars;
  final List<Color> palette;
  final bool rtl;

  @override
  State<_InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<_InteractiveChart> {
  int? _active;
  Offset _pointer = Offset.zero;

  @override
  void didUpdateWidget(covariant _InteractiveChart old) {
    super.didUpdateWidget(old);
    // Never cache a stale selection across a rebuild/resize.
    _active = null;
  }

  void _hit(Offset local, Size size) {
    final spec = widget.spec;
    final values = widget.catValues;
    int? idx;
    if (spec.kind == SmartChartKind.donut) {
      final center = Offset(size.width / 2, size.height / 2);
      final v = local - center;
      if (v.distance <= math.min(size.width, size.height) / 2) {
        final a = math.atan2(v.dy, v.dx);
        var ang = a + math.pi / 2; // painter starts at -pi/2
        if (widget.rtl) ang = 2 * math.pi - ang;
        ang %= 2 * math.pi;
        if (ang < 0) ang += 2 * math.pi;
        final total = values.fold<double>(0, (s, x) => s + x.abs());
        if (total > 0) {
          var acc = 0.0;
          for (var i = 0; i < values.length; i++) {
            final sweep = (values[i].abs() / total) * 2 * math.pi;
            if (ang >= acc && ang < acc + sweep) {
              idx = i;
              break;
            }
            acc += sweep;
          }
        }
      }
    } else if (spec.kind == SmartChartKind.bars && widget.horizontalBars) {
      final n = values.length;
      if (n > 0) idx = (local.dy / (size.height / n)).floor().clamp(0, n - 1);
    } else if (spec.kind == SmartChartKind.bars) {
      final n = values.length;
      if (n > 0) {
        final x = widget.rtl ? size.width - local.dx : local.dx;
        idx = (x / (size.width / n)).floor().clamp(0, n - 1);
      }
    } else {
      final n = spec.series.isEmpty ? 0 : spec.series.first.values.length;
      if (n > 1) {
        final x = widget.rtl ? size.width - local.dx : local.dx;
        idx = (x / (size.width / (n - 1))).round().clamp(0, n - 1);
      }
    }
    if (idx != _active || _pointer != local) {
      setState(() {
        _active = idx;
        _pointer = local;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final spec = widget.spec;
        final painter = switch (spec.kind) {
          SmartChartKind.donut => _DonutPainter(
              values: widget.catValues, palette: widget.palette, hole: taj.paper, rtl: widget.rtl, active: _active),
          SmartChartKind.line || SmartChartKind.area => _LinePainter(
              series: spec.series,
              n: spec.labels.length,
              labels: spec.labels,
              area: spec.kind == SmartChartKind.area,
              grid: taj.divider,
              labelColor: taj.textSecondary,
              unit: spec.unit,
              rtl: widget.rtl,
              active: _active),
          SmartChartKind.bars => widget.horizontalBars
              ? _HBarsPainter(
                  labels: widget.catLabels,
                  values: widget.catValues,
                  palette: widget.palette,
                  labelColor: taj.textSecondary,
                  unit: spec.unit,
                  rtl: widget.rtl,
                  active: _active)
              : _VBarsPainter(
                  labels: widget.catLabels,
                  values: widget.catValues,
                  palette: widget.palette,
                  grid: taj.divider,
                  labelColor: taj.textSecondary,
                  unit: spec.unit,
                  rtl: widget.rtl,
                  active: _active),
        };

        final chart = MouseRegion(
          onHover: (e) => _hit(e.localPosition, size),
          onExit: (_) => setState(() => _active = null),
          child: GestureDetector(
            onTapDown: (d) => _hit(d.localPosition, size),
            onPanUpdate: (d) => _hit(d.localPosition, size),
            child: CustomPaint(size: Size.infinite, painter: painter),
          ),
        );

        final tooltip = _active == null ? null : _tooltip(context, size);
        return Stack(children: [Positioned.fill(child: chart), if (tooltip != null) tooltip]);
      },
    );
  }

  Widget _tooltip(BuildContext context, Size size) {
    final taj = context.taj;
    final spec = widget.spec;
    final i = _active!;
    String label;
    String value;
    if (spec.kind == SmartChartKind.line || spec.kind == SmartChartKind.area) {
      label = i < spec.labels.length ? spec.labels[i] : '';
      final parts = <String>[
        for (final s in spec.series)
          if (i < s.values.length) '${s.name}: ${_fmtExact(s.values[i], spec.unit)}',
      ];
      value = parts.join('\n');
    } else {
      label = i < widget.catLabels.length ? widget.catLabels[i] : '';
      value = i < widget.catValues.length ? _fmtExact(widget.catValues[i], spec.unit) : '';
    }

    // Clamp the tooltip fully inside the plot using its max box, so it never
    // spills past the left/right edge (verified at 320px and the RTL edge).
    const ttW = 180.0;
    const ttH = 52.0;
    final left =
        (_pointer.dx - ttW / 2).clamp(0.0, math.max(0.0, size.width - ttW)).toDouble();
    final top =
        (_pointer.dy - ttH - 10).clamp(0.0, math.max(0.0, size.height - ttH)).toDouble();

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ttW),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: taj.isDark ? taj.paper : const Color(0xF21C252E),
              borderRadius: BorderRadius.circular(8),
              boxShadow: AppThemes.cardShadow(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                Text(value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

TextPainter _tp(String s, Color color, {double size = 12, FontWeight w = FontWeight.w600}) =>
    TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: w,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.rtl,
      maxLines: 1,
      ellipsis: '…',
    );

class _VBarsPainter extends CustomPainter {
  _VBarsPainter({
    required this.labels,
    required this.values,
    required this.palette,
    required this.grid,
    required this.labelColor,
    required this.unit,
    required this.rtl,
    required this.active,
  });
  final List<String> labels;
  final List<double> values;
  final List<Color> palette;
  final Color grid;
  final Color labelColor;
  final String? unit;
  final bool rtl;
  final int? active;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const labelBand = 20.0; // room for the category label under each bar
    const topBand = 16.0; // room for the value label above a bar
    final maxV = values.fold<double>(0, (m, v) => math.max(m, v));
    final safeMax = maxV <= 0 ? 1.0 : maxV;
    final chartH = size.height - labelBand - topBand;
    final n = values.length;
    final slot = size.width / n;
    final barW = math.min(slot * 0.62, 46.0);

    canvas.drawLine(Offset(0, topBand + chartH), Offset(size.width, topBand + chartH),
        Paint()..color = grid..strokeWidth = 1);

    for (var i = 0; i < n; i++) {
      final slotLeft = rtl ? size.width - (i + 1) * slot : i * slot;
      final cx = slotLeft + slot / 2;
      final h = (values[i] / safeMax) * chartH;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, topBand + chartH - h, barW, h),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      final color = palette[i % palette.length];
      canvas.drawRRect(rect, Paint()..color = active == null || active == i ? color : color.withValues(alpha: 0.4));

      // Value label above the active bar (or all bars when wide enough).
      if (active == i || (active == null && barW >= 28)) {
        final tp = _tp(_fmt(values[i]), labelColor, size: 12)..layout();
        final lx = (cx - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(canvas, Offset(lx, topBand + chartH - h - tp.height - 2));
      }

      // Category label under the bar, truncated to the slot width.
      final maxChars = (slot / 8).floor();
      if (maxChars >= 2) {
        final tp = _tp(_truncate(labels[i], maxChars), labelColor, size: 12)
          ..layout(maxWidth: slot - 2);
        final lx = (cx - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(canvas, Offset(lx, size.height - labelBand + 3));
      }
    }
  }

  String _fmt(double v) => unit == null ? arNumCompact(v) : '${arNumCompact(v)} $unit';

  @override
  bool shouldRepaint(_VBarsPainter old) =>
      old.values != values || old.active != active || old.rtl != rtl;
}

class _HBarsPainter extends CustomPainter {
  _HBarsPainter({
    required this.labels,
    required this.values,
    required this.palette,
    required this.labelColor,
    required this.unit,
    required this.rtl,
    required this.active,
  });
  final List<String> labels;
  final List<double> values;
  final List<Color> palette;
  final Color labelColor;
  final String? unit;
  final bool rtl;
  final int? active;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.fold<double>(0, (m, v) => math.max(m, v));
    final safeMax = maxV <= 0 ? 1.0 : maxV;
    final n = values.length;
    final rowH = size.height / n;
    // Reserve a leading band for the (long) category name.
    final labelW = math.min(size.width * 0.42, 150.0);
    final trackLeft = rtl ? 0.0 : labelW;
    final trackW = size.width - labelW;
    final barH = math.min(rowH * 0.6, 26.0);

    for (var i = 0; i < n; i++) {
      final cy = i * rowH + rowH / 2;
      final w = (values[i] / safeMax) * trackW;
      final color = palette[i % palette.length];
      final paint = Paint()
        ..color = active == null || active == i ? color : color.withValues(alpha: 0.4);
      final left = rtl ? size.width - w : trackLeft;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, cy - barH / 2, w, barH),
        topRight: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
        topLeft: const Radius.circular(4),
        bottomLeft: const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);

      // Category name in the leading band, truncated to fit.
      final labelChars = (labelW / 8).floor();
      final lp = _tp(_truncate(labels[i], labelChars), labelColor, size: 12)
        ..layout(maxWidth: labelW - 6);
      final lx = rtl ? size.width - lp.width : 0.0;
      lp.paint(canvas, Offset(lx, cy - lp.height / 2));

      // Value at the bar end.
      final vp = _tp(_fmt(values[i]), labelColor, size: 12)..layout();
      final vx = rtl
          ? (size.width - w - vp.width - 4).clamp(0.0, size.width - vp.width)
          : (trackLeft + w + 4).clamp(0.0, size.width - vp.width);
      vp.paint(canvas, Offset(vx, cy - vp.height / 2));
    }
  }

  String _fmt(double v) => unit == null ? arNumCompact(v) : '${arNumCompact(v)} $unit';

  @override
  bool shouldRepaint(_HBarsPainter old) =>
      old.values != values || old.active != active || old.rtl != rtl;
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.series,
    required this.n,
    required this.labels,
    required this.area,
    required this.grid,
    required this.labelColor,
    required this.unit,
    required this.rtl,
    required this.active,
  });
  final List<SmartSeries> series;
  final int n;
  final List<String> labels;
  final bool area;
  final Color grid;
  final Color labelColor;
  final String? unit;
  final bool rtl;
  final int? active;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final count = series.first.values.length;
    if (count < 2) return;
    const labelBand = 18.0;
    final chartH = size.height - labelBand;
    var maxV = 0.0;
    for (final s in series) {
      for (final v in s.values) {
        maxV = math.max(maxV, v);
      }
    }
    final safeMax = maxV <= 0 ? 1.0 : maxV;
    double xAt(int i) {
      final t = i / (count - 1);
      return rtl ? size.width * (1 - t) : size.width * t;
    }

    double yAt(double v) => chartH - (v / safeMax) * chartH;

    // Baseline + a mid gridline.
    for (final y in [0.0, chartH]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          Paint()..color = grid..strokeWidth = 1);
    }

    for (final s in series) {
      final path = Path()..moveTo(xAt(0), yAt(s.values[0]));
      for (var i = 1; i < count; i++) {
        path.lineTo(xAt(i), yAt(s.values[i]));
      }
      if (area) {
        final fill = Path.from(path)
          ..lineTo(xAt(count - 1), chartH)
          ..lineTo(xAt(0), chartH)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [s.color.withValues(alpha: 0.22), s.color.withValues(alpha: 0)],
            ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      for (var i = 0; i < count; i++) {
        canvas.drawCircle(Offset(xAt(i), yAt(s.values[i])), active == i ? 4 : 2.5,
            Paint()..color = s.color);
      }
    }

    // Active vertical guide.
    if (active != null && active! >= 0 && active! < count) {
      canvas.drawLine(Offset(xAt(active!), 0), Offset(xAt(active!), chartH),
          Paint()..color = grid..strokeWidth = 1);
    }

    // Sparse x labels: first, middle, last (avoids collisions).
    final ticks = count <= 3 ? [for (var i = 0; i < count; i++) i] : [0, count ~/ 2, count - 1];
    for (final i in ticks) {
      if (i >= labels.length) continue;
      final tp = _tp(_truncate(labels[i], 8), labelColor, size: 12)..layout();
      final lx = (xAt(i) - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(lx, chartH + 3));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.series != series || old.active != active || old.rtl != rtl;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.palette,
    required this.hole,
    required this.rtl,
    required this.active,
  });
  final List<double> values;
  final List<Color> palette;
  final Color hole;
  final bool rtl;
  final int? active;

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
      final sweepMag = (values[i].abs() / total) * 2 * math.pi;
      final sweep = rtl ? -sweepMag : sweepMag;
      final color = palette[i % palette.length];
      final r = active == i ? radius : radius - 0;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start,
        sweep,
        true,
        Paint()..color = active == null || active == i ? color : color.withValues(alpha: 0.4),
      );
      start += sweep;
    }
    canvas.drawCircle(center, radius * 0.58, Paint()..color = hole);
    // Center total.
    final tp = _tp(arNumCompact(total), _contrast(hole), size: 14, w: FontWeight.w800)..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    // silence unused rect warning by referencing it once.
    assert(rect.width >= 0);
  }

  Color _contrast(Color bg) {
    final b = bg.computeLuminance();
    return b > 0.5 ? const Color(0xFF212B36) : Colors.white;
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values != values || old.active != active || old.rtl != rtl;
}
