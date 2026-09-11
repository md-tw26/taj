import 'package:flutter/material.dart';

import '../../core/demo/demo_store.dart';

/// Preset slicing periods for the analytics module. `custom` uses
/// [SmartSlicers.range]; `all` means the whole history.
enum SmartPeriod { all, week, month, quarter, year, custom }

extension SmartPeriodX on SmartPeriod {
  String get label => switch (this) {
        SmartPeriod.all => 'كل الفترات',
        SmartPeriod.week => 'هذا الأسبوع',
        SmartPeriod.month => 'هذا الشهر',
        SmartPeriod.quarter => 'هذا الربع',
        SmartPeriod.year => 'هذه السنة',
        SmartPeriod.custom => 'فترة مخصصة',
      };
}

/// The active slicing selection shared by every question: period, branch and an
/// optional per-question measure (e.g. quantity vs revenue).
@immutable
class SmartSlicers {
  const SmartSlicers({
    this.period = SmartPeriod.all,
    this.range,
    this.branchId,
    this.measure,
  });

  final SmartPeriod period;
  final DateTimeRange? range;

  /// null = all branches.
  final String? branchId;

  /// Per-question secondary slicer value (null = the measure's default).
  final String? measure;

  SmartSlicers copyWith({
    SmartPeriod? period,
    DateTimeRange? range,
    bool clearRange = false,
    String? branchId,
    bool clearBranch = false,
    String? measure,
    bool clearMeasure = false,
  }) =>
      SmartSlicers(
        period: period ?? this.period,
        range: clearRange ? null : (range ?? this.range),
        branchId: clearBranch ? null : (branchId ?? this.branchId),
        measure: clearMeasure ? null : (measure ?? this.measure),
      );

  DateTimeRange? resolveRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case SmartPeriod.all:
        return null;
      case SmartPeriod.week:
        return DateTimeRange(
            start: today.subtract(Duration(days: today.weekday % 7)), end: today);
      case SmartPeriod.month:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: today);
      case SmartPeriod.quarter:
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(start: DateTime(now.year, q, 1), end: today);
      case SmartPeriod.year:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: today);
      case SmartPeriod.custom:
        return range;
    }
  }

  bool includes(DateTime d, DateTime now) {
    final r = resolveRange(now);
    if (r == null) return true;
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(r.start) && !day.isAfter(r.end);
  }

  int get activeCount {
    var n = 0;
    if (period != SmartPeriod.all) n++;
    if (branchId != null) n++;
    if (measure != null) n++;
    return n;
  }
}

/// A per-question measure slicer (first option is the default).
class MeasureSlicer {
  const MeasureSlicer({required this.label, required this.options});
  final String label;
  final List<MeasureOption> options;
}

class MeasureOption {
  const MeasureOption(this.value, this.label);
  final String value;
  final String label;
}

// ---------------------------------------------------------------------------
// Chart data
// ---------------------------------------------------------------------------

enum SmartChartKind { bars, line, area, donut }

/// One data series aligned to a chart's [ChartSpec.labels].
class SmartSeries {
  const SmartSeries({required this.name, required this.color, required this.values});
  final String name;
  final Color color;
  final List<double> values;
}

/// A single chart's declarative spec. Rendering (aspect ratio, orientation,
/// grouping, tooltip, legend) is decided by [ResponsiveChartCard] from the
/// space available — the spec carries only data + intent.
class ChartSpec {
  const ChartSpec({
    required this.kind,
    required this.title,
    required this.labels,
    required this.series,
    this.subtitle,
    this.unit,
    this.categoryColors,
  });

  final SmartChartKind kind;
  final String title;
  final String? subtitle;

  /// Category / x-axis labels.
  final List<String> labels;

  /// One or more series. `bars`/`donut` use [series].first; `line`/`area` may
  /// draw several.
  final List<SmartSeries> series;

  /// Optional unit suffix for values (e.g. 'د.ل').
  final String? unit;

  /// Optional per-category colours (bars/donut). When null the card assigns a
  /// palette by index.
  final List<Color>? categoryColors;
}

/// A KPI headline. Mirrors the fields of the shared `KpiCard` so the screen can
/// map straight onto it.
class KpiStat {
  const KpiStat({
    required this.label,
    required this.value,
    this.delta,
    this.deltaPositive = true,
    this.icon,
    this.spark = const [],
  });
  final String label;
  final String value;
  final String? delta;
  final bool deltaPositive;
  final IconData? icon;
  final List<double> spark;
}

/// A plain-language explanatory note under the KPIs.
class InsightNote {
  const InsightNote({required this.text, this.icon = Icons.lightbulb_outline_rounded});
  final String text;
  final IconData icon;
}

/// The computed answer to a question at the current slicers.
class AnalyticsResult {
  const AnalyticsResult({
    this.kpis = const [],
    this.notes = const [],
    this.charts = const [],
  });
  final List<KpiStat> kpis;
  final List<InsightNote> notes;
  final List<ChartSpec> charts;

  bool get isEmpty => charts.every((c) => c.series.every((s) => s.values.every((v) => v == 0)));
}

typedef AnalyticsBuilder = AnalyticsResult Function(
  BuildContext context,
  DemoStore store,
  SmartSlicers slicers,
);

/// A ready analytical question shown as a card and answered visually.
class QuestionDef {
  const QuestionDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.build,
    this.measure,
  });
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final AnalyticsBuilder build;

  /// Optional per-question measure slicer.
  final MeasureSlicer? measure;
}
