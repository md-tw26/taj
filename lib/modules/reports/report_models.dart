import 'package:flutter/material.dart';

import '../../core/demo/demo_store.dart';
import '../../shared/widgets/taj_report_table.dart';

/// Top-level grouping of reports shown in the index.
enum ReportCategory { financial, tax, hr, operations }

extension ReportCategoryX on ReportCategory {
  String get label => switch (this) {
        ReportCategory.financial => 'التقارير المالية',
        ReportCategory.tax => 'الضرائب والزكاة',
        ReportCategory.hr => 'الموارد البشرية',
        ReportCategory.operations => 'تقارير التشغيل',
      };
}

/// Preset reporting periods. `custom` uses [ReportFilters.customRange]; `all`
/// means the whole history (no date bound).
enum ReportPeriodPreset { all, today, week, month, quarter, year, custom }

extension ReportPeriodPresetX on ReportPeriodPreset {
  String get label => switch (this) {
        ReportPeriodPreset.all => 'كل الفترات',
        ReportPeriodPreset.today => 'اليوم',
        ReportPeriodPreset.week => 'هذا الأسبوع',
        ReportPeriodPreset.month => 'هذا الشهر',
        ReportPeriodPreset.quarter => 'هذا الربع',
        ReportPeriodPreset.year => 'هذه السنة',
        ReportPeriodPreset.custom => 'فترة مخصصة',
      };
}

/// The active filter selection shared by every report: period, branch and an
/// optional report-specific segment (status / category / account …).
@immutable
class ReportFilters {
  const ReportFilters({
    this.period = ReportPeriodPreset.all,
    this.customRange,
    this.branchId,
    this.segment,
  });

  final ReportPeriodPreset period;
  final DateTimeRange? customRange;

  /// null = all branches.
  final String? branchId;

  /// Report-specific secondary filter value (null = the segment's default/all).
  final String? segment;

  ReportFilters copyWith({
    ReportPeriodPreset? period,
    DateTimeRange? customRange,
    bool clearCustomRange = false,
    String? branchId,
    bool clearBranch = false,
    String? segment,
    bool clearSegment = false,
  }) =>
      ReportFilters(
        period: period ?? this.period,
        customRange:
            clearCustomRange ? null : (customRange ?? this.customRange),
        branchId: clearBranch ? null : (branchId ?? this.branchId),
        segment: clearSegment ? null : (segment ?? this.segment),
      );

  /// Resolve the concrete [DateTimeRange] this selection implies, or null for
  /// "all periods". Presets are computed relative to [now].
  DateTimeRange? resolveRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case ReportPeriodPreset.all:
        return null;
      case ReportPeriodPreset.today:
        return DateTimeRange(start: today, end: today);
      case ReportPeriodPreset.week:
        final start = today.subtract(Duration(days: today.weekday % 7));
        return DateTimeRange(start: start, end: today);
      case ReportPeriodPreset.month:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: today);
      case ReportPeriodPreset.quarter:
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(start: DateTime(now.year, q, 1), end: today);
      case ReportPeriodPreset.year:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: today);
      case ReportPeriodPreset.custom:
        return customRange;
    }
  }

  /// True when [d] falls inside the resolved range (inclusive of the end day),
  /// or always when there is no date bound.
  bool includes(DateTime d, DateTime now) {
    final r = resolveRange(now);
    if (r == null) return true;
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(r.start) && !day.isAfter(r.end);
  }
}

/// A report-specific secondary filter (e.g. journal status, expense category,
/// ledger account). The first option is the default ("all").
class ReportSegment {
  const ReportSegment({required this.label, required this.options});
  final String label;
  final List<ReportSegmentOption> options;
}

class ReportSegmentOption {
  const ReportSegmentOption(this.value, this.label);

  /// null = the "all" / default option.
  final String? value;
  final String label;
}

/// A single summary metric shown above/beside the table.
class ReportStat {
  const ReportStat({
    required this.label,
    required this.value,
    this.tone,
    this.icon,
    this.spark = const [],
  });
  final String label;
  final String value;

  /// Optional semantic colour (success/error/…) for the value.
  final Color? tone;
  final IconData? icon;
  final List<double> spark;
}

enum ReportChartType { bars, line, donut }

class ReportSeries {
  const ReportSeries({required this.label, required this.color, required this.values});
  final String label;
  final Color color;
  final List<double> values;
}

/// Chart data accompanying a report. The chart is always drawn inside an
/// [AspectRatio]; its legend wraps below when narrow and axis labels abbreviate
/// rather than collide (see the chart widget).
class ReportChartData {
  const ReportChartData({
    required this.type,
    required this.title,
    this.labels = const [],
    required this.series,
    this.valueFormatter,
  });
  final ReportChartType type;
  final String title;
  final List<String> labels;
  final List<ReportSeries> series;

  /// Formats an axis / segment value for display (defaults to a compact number).
  final String Function(double)? valueFormatter;
}

/// The fully-computed result of running a report against the store + filters.
class ReportResult {
  const ReportResult({
    required this.columns,
    required this.rows,
    this.totals,
    this.summary = const [],
    this.chart,
    this.note,
  });
  final List<ReportColumn> columns;
  final List<ReportRow> rows;
  final ReportRow? totals;
  final List<ReportStat> summary;
  final ReportChartData? chart;

  /// Optional footnote (e.g. the zakat basis or tax-rate assumption).
  final String? note;
}

/// Builds a report's result. Receives [context] so cells can use theme colours
/// and the numeral style; reuses the store's existing computations (never
/// re-implements or mutates report logic).
typedef ReportBuilder = ReportResult Function(
  BuildContext context,
  DemoStore store,
  ReportFilters filters,
);

/// A report in the catalogue: its identity/metadata for the index card and its
/// [build] function for the result screen.
class ReportDef {
  const ReportDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.build,
    this.segment,
    this.hierarchical = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final ReportCategory category;
  final ReportBuilder build;

  /// Optional secondary filter definition offered for this report.
  final ReportSegment? segment;

  /// Whether rows carry a depth (income statement / balance sheet) — used for
  /// nothing structural (the table always honours depth) but documents intent.
  final bool hierarchical;
}
