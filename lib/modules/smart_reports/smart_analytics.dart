import 'package:flutter/material.dart';

import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_store.dart';
import '../../core/format.dart';
import '../../core/theme/taj_colors.dart';
import 'smart_models.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

DateTime _now() => DateTime.now();

String _branchName(DemoStore s, String id) {
  for (final b in s.branches) {
    if (b.id == id) return b.name;
  }
  return id;
}

bool _branchOk(String? entityBranch, SmartSlicers f) =>
    f.branchId == null || entityBranch == f.branchId;

String _method(DemoPaymentMethod m) => switch (m) {
      DemoPaymentMethod.cash => 'نقدي',
      DemoPaymentMethod.bank => 'تحويل مصرفي',
      DemoPaymentMethod.card => 'بطاقة',
      DemoPaymentMethod.sadad => 'سداد',
      DemoPaymentMethod.credit => 'آجل',
    };

/// Sales that count toward analytics: not cancelled/returned, inside the period
/// and branch slice.
List<DemoSale> _sales(DemoStore s, SmartSlicers f, DateTime now) => s.sales
    .where((sale) =>
        sale.status != DemoSaleStatus.cancelled &&
        sale.status != DemoSaleStatus.returned &&
        _branchOk(sale.branchId, f) &&
        f.includes(sale.date, now))
    .toList();

Map<String, double> _productCost(DemoStore s) => {for (final p in s.products) p.id: p.cost};
Map<String, String> _productName(DemoStore s) => {for (final p in s.products) p.id: p.name};
Map<String, String> _productCat(DemoStore s) => {for (final p in s.products) p.id: p.category};

/// Sort a label→value map descending and split into parallel lists.
({List<String> labels, List<double> values}) _rank(Map<String, double> m) {
  final entries = m.entries.where((e) => e.value != 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return (labels: [for (final e in entries) e.key], values: [for (final e in entries) e.value]);
}

/// Day buckets: the resolved range (capped) or the last 14 days.
List<DateTime> _dayWindow(SmartSlicers f, DateTime now) {
  final r = f.resolveRange(now);
  final end = DateTime(now.year, now.month, now.day);
  var start = r?.start ?? end.subtract(const Duration(days: 13));
  start = DateTime(start.year, start.month, start.day);
  var span = end.difference(start).inDays;
  if (span < 0) span = 0;
  if (span > 30) start = end.subtract(const Duration(days: 30)); // keep legible
  final days = <DateTime>[];
  for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
    days.add(d);
  }
  return days;
}

String _dayLabel(DateTime d) => '${d.month}/${d.day}';
String _monthLabel(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// The question catalogue
// ---------------------------------------------------------------------------

final List<QuestionDef> smartQuestions = [
  QuestionDef(
    id: 'money_flow',
    title: 'أين تذهب الأموال؟',
    subtitle: 'توزيع المصروفات حسب التصنيف والفرع',
    icon: Icons.account_balance_wallet_outlined,
    build: _moneyFlow,
  ),
  QuestionDef(
    id: 'profitable_products',
    title: 'ما أكثر المنتجات ربحية؟',
    subtitle: 'صافي الربح لكل صنف',
    icon: Icons.trending_up_rounded,
    measure: const MeasureSlicer(label: 'المقياس', options: [
      MeasureOption('profit', 'الربح'),
      MeasureOption('revenue', 'الإيراد'),
      MeasureOption('qty', 'الكمية'),
    ]),
    build: _profitableProducts,
  ),
  QuestionDef(
    id: 'sales_trend',
    title: 'كيف تتطور المبيعات؟',
    subtitle: 'حركة المبيعات اليومية',
    icon: Icons.show_chart_rounded,
    build: _salesTrend,
  ),
  QuestionDef(
    id: 'top_customers',
    title: 'من هم أفضل العملاء؟',
    subtitle: 'أعلى العملاء إنفاقًا',
    icon: Icons.groups_outlined,
    build: _topCustomers,
  ),
  QuestionDef(
    id: 'branch_performance',
    title: 'كيف تؤدي الفروع؟',
    subtitle: 'المبيعات وحصة كل فرع',
    icon: Icons.store_mall_directory_outlined,
    build: _branchPerformance,
  ),
  QuestionDef(
    id: 'payment_mix',
    title: 'كيف يدفع العملاء؟',
    subtitle: 'توزيع المبيعات حسب طريقة الدفع',
    icon: Icons.payment_rounded,
    build: _paymentMix,
  ),
  QuestionDef(
    id: 'best_sellers',
    title: 'ما الأصناف الأكثر مبيعًا؟',
    subtitle: 'الكمية المباعة والإيراد حسب التصنيف',
    icon: Icons.local_fire_department_outlined,
    measure: const MeasureSlicer(label: 'المقياس', options: [
      MeasureOption('qty', 'الكمية'),
      MeasureOption('revenue', 'الإيراد'),
    ]),
    build: _bestSellers,
  ),
  QuestionDef(
    id: 'revenue_vs_expense',
    title: 'الإيراد مقابل المصروف؟',
    subtitle: 'المقارنة الشهرية للإيرادات والمصروفات',
    icon: Icons.compare_arrows_rounded,
    build: _revenueVsExpense,
  ),
];

QuestionDef questionById(String id) =>
    smartQuestions.firstWhere((q) => q.id == id, orElse: () => smartQuestions.first);

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

AnalyticsResult _moneyFlow(BuildContext c, DemoStore s, SmartSlicers f) {
  final now = _now();
  final list = s.expenses
      .where((e) => _branchOk(e.branchId, f) && f.includes(e.date, now))
      .toList();
  final byCat = <String, double>{};
  final byBranch = <String, double>{};
  for (final e in list) {
    byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
    byBranch[_branchName(s, e.branchId)] = (byBranch[_branchName(s, e.branchId)] ?? 0) + e.amount;
  }
  final total = list.fold<double>(0, (s2, e) => s2 + e.amount);
  final catRank = _rank(byCat);
  final topCat = catRank.labels.isEmpty ? '—' : catRank.labels.first;
  final topShare = total == 0 || catRank.values.isEmpty ? 0 : (catRank.values.first / total * 100).round();

  return AnalyticsResult(
    kpis: [
      KpiStat(label: 'إجمالي المصروفات', value: arDinar(total), icon: Icons.payments_outlined),
      KpiStat(label: 'أعلى تصنيف', value: topCat, icon: Icons.category_outlined),
      KpiStat(label: 'عدد الحركات', value: arNum(list.length), icon: Icons.tag_rounded),
    ],
    notes: [
      InsightNote(text: total == 0
          ? 'لا توجد مصروفات ضمن الفترة المختارة.'
          : 'يستحوذ تصنيف «$topCat» على $topShare٪ من إجمالي الإنفاق خلال الفترة.'),
    ],
    charts: [
      ChartSpec(
        kind: SmartChartKind.donut,
        title: 'المصروفات حسب التصنيف',
        labels: catRank.labels,
        series: [SmartSeries(name: 'المصروفات', color: c.taj.primary.main, values: catRank.values)],
        unit: 'د.ل',
      ),
      ChartSpec(
        kind: SmartChartKind.bars,
        title: 'المصروفات حسب الفرع',
        labels: _rank(byBranch).labels,
        series: [SmartSeries(name: 'المصروفات', color: c.taj.info.main, values: _rank(byBranch).values)],
        unit: 'د.ل',
      ),
    ],
  );
}

AnalyticsResult _profitableProducts(BuildContext c, DemoStore s, SmartSlicers f) {
  final now = _now();
  final costs = _productCost(s);
  final names = _productName(s);
  final measure = f.measure ?? 'profit';
  final metric = <String, double>{}; // productId → value
  for (final sale in _sales(s, f, now)) {
    for (final l in sale.lines) {
      final v = switch (measure) {
        'revenue' => l.total,
        'qty' => l.quantity.toDouble(),
        _ => (l.unitPrice - (costs[l.productId] ?? 0)) * l.quantity, // profit
      };
      metric[l.productId] = (metric[l.productId] ?? 0) + v;
    }
  }
  final labelled = <String, double>{
    for (final e in metric.entries) (names[e.key] ?? e.key): e.value,
  };
  final ranked = _rank(labelled);
  final total = ranked.values.fold<double>(0, (a, b) => a + b);
  final unit = measure == 'qty' ? 'وحدة' : 'د.ل';
  final best = ranked.labels.isEmpty ? '—' : ranked.labels.first;
  final measureLabel = switch (measure) { 'revenue' => 'الإيراد', 'qty' => 'الكمية', _ => 'الربح' };

  return AnalyticsResult(
    kpis: [
      KpiStat(label: 'إجمالي $measureLabel', value: measure == 'qty' ? '${arNum(total)} وحدة' : arDinar(total)),
      KpiStat(label: 'الأعلى', value: best, icon: Icons.emoji_events_outlined),
      KpiStat(label: 'عدد الأصناف', value: arNum(ranked.labels.length), icon: Icons.inventory_2_outlined),
    ],
    notes: [
      InsightNote(text: ranked.labels.isEmpty
          ? 'لا توجد مبيعات لاحتساب $measureLabel ضمن الفترة.'
          : 'الصنف «$best» هو الأعلى من حيث $measureLabel خلال الفترة المختارة.'),
    ],
    charts: [
      ChartSpec(
        kind: SmartChartKind.bars,
        title: '$measureLabel حسب الصنف',
        labels: ranked.labels,
        series: [SmartSeries(name: measureLabel, color: c.taj.primary.main, values: ranked.values)],
        unit: unit,
      ),
    ],
  );
}

AnalyticsResult _salesTrend(BuildContext c, DemoStore s, SmartSlicers f) {
  final now = _now();
  final days = _dayWindow(f, now);
  final sales = _sales(s, f, now);
  final values = <double>[];
  for (final d in days) {
    values.add(sales
        .where((x) => x.date.year == d.year && x.date.month == d.month && x.date.day == d.day)
        .fold<double>(0, (a, b) => a + b.total));
  }
  final total = values.fold<double>(0, (a, b) => a + b);
  final avg = values.isEmpty ? 0.0 : total / values.length;
  var bestI = 0;
  for (var i = 1; i < values.length; i++) {
    if (values[i] > values[bestI]) bestI = i;
  }
  final bestDay = values.isEmpty ? '—' : _dayLabel(days[bestI]);

  return AnalyticsResult(
    kpis: [
      KpiStat(label: 'إجمالي المبيعات', value: arDinar(total), icon: Icons.receipt_long_outlined, spark: values),
      KpiStat(label: 'المتوسط اليومي', value: arDinar(avg)),
      KpiStat(label: 'أفضل يوم', value: bestDay, icon: Icons.event_available_outlined),
    ],
    notes: [
      InsightNote(text: total == 0
          ? 'لا توجد مبيعات ضمن الفترة المختارة.'
          : 'بلغ متوسط المبيعات اليومية ${arDinar(avg)} خلال ${arNum(days.length)} يوم.'),
    ],
    charts: [
      ChartSpec(
        kind: SmartChartKind.area,
        title: 'المبيعات اليومية',
        labels: [for (final d in days) _dayLabel(d)],
        series: [SmartSeries(name: 'المبيعات', color: c.taj.primary.main, values: values)],
        unit: 'د.ل',
      ),
    ],
  );
}

AnalyticsResult _topCustomers(BuildContext c, DemoStore s, SmartSlicers f) {
  final now = _now();
  final byCustomer = <String, double>{};
  for (final sale in _sales(s, f, now)) {
    final id = sale.customerId;
    if (id == null) continue;
    final name = s.customers.firstWhere((x) => x.id == id,
        orElse: () => const DemoCustomer(id: '', name: 'عميل نقدي', phone: '', creditLimit: 0)).name;
    byCustomer[name] = (byCustomer[name] ?? 0) + sale.total;
  }
  final ranked = _rank(byCustomer);
  final receivable = s.customers.fold<double>(0, (a, b) => a + b.balance);
  final best = ranked.labels.isEmpty ? '—' : ranked.labels.first;

  return AnalyticsResult(
    kpis: [
      KpiStat(label: 'عملاء لهم مبيعات', value: arNum(ranked.labels.length), icon: Icons.groups_outlined),
      KpiStat(label: 'أعلى عميل', value: best, icon: Icons.star_border_rounded),
      KpiStat(label: 'إجمالي الذمم', value: arDinar(receivable)),
    ],
    notes: [
      InsightNote(text: ranked.labels.isEmpty
          ? 'لا توجد مبيعات مرتبطة بعملاء ضمن الفترة.'
          : 'العميل «$best» هو الأعلى إنفاقًا خلال الفترة المختارة.'),
    ],
    charts: [
      ChartSpec(
        kind: SmartChartKind.bars,
        title: 'المبيعات حسب العميل',
        labels: ranked.labels,
        series: [SmartSeries(name: 'المبيعات', color: c.taj.primary.main, values: ranked.values)],
        unit: 'د.ل',
      ),
    ],
  );
}

AnalyticsResult _branchPerformance(BuildContext c, DemoStore s, SmartSlicers f) {
  final now = _now();
  final byBranch = <String, double>{};
  // Branch slice is intentionally ignored here — the point is to compare
  // branches; only the period applies.
  for (final sale in s.sales.where((x) =>
      x.status != DemoSaleStatus.cancelled &&
      x.status != DemoSaleStatus.returned &&
      f.includes(x.date, now))) {
    byBranch[_branchName(s, sale.branchId)] = (byBranch[_branchName(s, sale.branchId)] ?? 0) + sale.total;
  }
  final ranked = _rank(byBranch);
  final total = ranked.values.fold<double>(0, (a, b) => a + b);
  final best = ranked.labels.isEmpty ? '—' : ranked.labels.first;

  return AnalyticsResult(
    kpis: [
      KpiStat(label: 'إجمالي المبيعات', value: arDinar(total)),
      KpiStat(label: 'أفضل فرع', value: best, icon: Icons.emoji_events_outlined),
      KpiStat(label: 'عدد الفروع', value: arNum(ranked.labels.length), icon: Icons.store_outlined),
    ],
    notes: [
      InsightNote(text: ranked.labels.isEmpty
          ? 'لا توجد مبيعات ضمن الفترة المختارة.'
          : 'الفرع «$best» هو الأعلى مبيعًا خلال الفترة.'),
    ],
    charts: [
      ChartSpec(
        kind: SmartChartKind.bars,
        title: 'المبيعات حسب الفرع',
        labels: ranked.labels,
        series: [SmartSeries(name: 'المبيعات', color: c.taj.primary.main, values: ranked.values)],
        unit: 'د.ل',
      ),
      ChartSpec(
        kind: SmartChartKind.donut,
        title: 'حصة كل فرع',
        labels: ranked.labels,
        series: [SmartSeries(name: 'الحصة', color: c.taj.info.main, values: ranked.values)],
        unit: 'د.ل',
      ),
    ],
  );
}

AnalyticsResult _paymentMix(BuildContext c, DemoStore s, SmartSlicers f) {
  final now = _now();
  final byMethod = <String, double>{};
  for (final sale in _sales(s, f, now)) {
    byMethod[_method(sale.paymentMethod)] = (byMethod[_method(sale.paymentMethod)] ?? 0) + sale.total;
  }
  final ranked = _rank(byMethod);
  final total = ranked.values.fold<double>(0, (a, b) => a + b);
  final dominant = ranked.labels.isEmpty ? '—' : ranked.labels.first;
  final domShare = total == 0 || ranked.values.isEmpty ? 0 : (ranked.values.first / total * 100).round();

  return AnalyticsResult(
    kpis: [
      KpiStat(label: 'إجمالي المبيعات', value: arDinar(total)),
      KpiStat(label: 'الطريقة الأكثر', value: dominant, icon: Icons.payment_rounded),
      KpiStat(label: 'حصتها', value: '$domShare٪'),
    ],
    notes: [
      InsightNote(text: ranked.labels.isEmpty
          ? 'لا توجد مبيعات ضمن الفترة المختارة.'
          : 'تمثّل طريقة «$dominant» $domShare٪ من قيمة المبيعات خلال الفترة.'),
    ],
    charts: [
      ChartSpec(
        kind: SmartChartKind.donut,
        title: 'المبيعات حسب طريقة الدفع',
        labels: ranked.labels,
        series: [SmartSeries(name: 'المبيعات', color: c.taj.primary.main, values: ranked.values)],
        unit: 'د.ل',
      ),
    ],
  );
}

AnalyticsResult _bestSellers(BuildContext c, DemoStore s, SmartSlicers f) {
  final now = _now();
  final names = _productName(s);
  final cats = _productCat(s);
  final measure = f.measure ?? 'qty';
  final byProduct = <String, double>{};
  final revByCat = <String, double>{};
  for (final sale in _sales(s, f, now)) {
    for (final l in sale.lines) {
      final v = measure == 'revenue' ? l.total : l.quantity.toDouble();
      byProduct[names[l.productId] ?? l.productId] = (byProduct[names[l.productId] ?? l.productId] ?? 0) + v;
      final cat = cats[l.productId] ?? 'أخرى';
      revByCat[cat] = (revByCat[cat] ?? 0) + l.total;
    }
  }
  final ranked = _rank(byProduct);
  final unit = measure == 'revenue' ? 'د.ل' : 'وحدة';
  final measureLabel = measure == 'revenue' ? 'الإيراد' : 'الكمية';
  final best = ranked.labels.isEmpty ? '—' : ranked.labels.first;
  final totalUnits = _sales(s, f, now)
      .fold<double>(0, (a, sale) => a + sale.lines.fold<double>(0, (b, l) => b + l.quantity));

  return AnalyticsResult(
    kpis: [
      KpiStat(label: 'الوحدات المباعة', value: '${arNum(totalUnits)} وحدة', icon: Icons.shopping_bag_outlined),
      KpiStat(label: 'الأكثر مبيعًا', value: best, icon: Icons.local_fire_department_outlined),
      KpiStat(label: 'عدد الأصناف', value: arNum(ranked.labels.length)),
    ],
    notes: [
      InsightNote(text: ranked.labels.isEmpty
          ? 'لا توجد مبيعات ضمن الفترة المختارة.'
          : 'الصنف «$best» هو الأعلى حسب $measureLabel خلال الفترة.'),
    ],
    charts: [
      ChartSpec(
        kind: SmartChartKind.bars,
        title: '$measureLabel حسب الصنف',
        labels: ranked.labels,
        series: [SmartSeries(name: measureLabel, color: c.taj.primary.main, values: ranked.values)],
        unit: unit,
      ),
      ChartSpec(
        kind: SmartChartKind.donut,
        title: 'الإيراد حسب التصنيف',
        labels: _rank(revByCat).labels,
        series: [SmartSeries(name: 'الإيراد', color: c.taj.info.main, values: _rank(revByCat).values)],
        unit: 'د.ل',
      ),
    ],
  );
}

AnalyticsResult _revenueVsExpense(BuildContext c, DemoStore s, SmartSlicers f) {
  final now = _now();
  // Last 6 months (honours branch; period range narrows the window if set).
  final months = <DateTime>[];
  final r = f.resolveRange(now);
  if (r != null) {
    var m = DateTime(r.start.year, r.start.month);
    final endM = DateTime(r.end.year, r.end.month);
    while (!m.isAfter(endM) && months.length < 12) {
      months.add(m);
      m = DateTime(m.year, m.month + 1);
    }
    if (months.isEmpty) months.add(DateTime(now.year, now.month));
  } else {
    for (var i = 5; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i));
    }
  }
  double revIn(DateTime m) => s.sales
      .where((x) =>
          x.status != DemoSaleStatus.cancelled &&
          x.status != DemoSaleStatus.returned &&
          _branchOk(x.branchId, f) &&
          x.date.year == m.year &&
          x.date.month == m.month)
      .fold<double>(0, (a, b) => a + b.total);
  double expIn(DateTime m) => s.expenses
      .where((e) => _branchOk(e.branchId, f) && e.date.year == m.year && e.date.month == m.month)
      .fold<double>(0, (a, b) => a + b.amount);

  final revenue = [for (final m in months) revIn(m)];
  final expense = [for (final m in months) expIn(m)];
  final totalRev = revenue.fold<double>(0, (a, b) => a + b);
  final totalExp = expense.fold<double>(0, (a, b) => a + b);
  final net = totalRev - totalExp;

  return AnalyticsResult(
    kpis: [
      KpiStat(label: 'الإيرادات', value: arDinar(totalRev), icon: Icons.south_west_rounded, spark: revenue),
      KpiStat(label: 'المصروفات', value: arDinar(totalExp), icon: Icons.north_east_rounded, spark: expense),
      KpiStat(
        label: net >= 0 ? 'صافي الربح' : 'صافي الخسارة',
        value: arDinar(net),
        icon: net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
      ),
    ],
    notes: [
      InsightNote(text: net >= 0
          ? 'الإيرادات تفوق المصروفات بمقدار ${arDinar(net)} خلال الفترة.'
          : 'المصروفات تفوق الإيرادات بمقدار ${arDinar(net.abs())} خلال الفترة.'),
    ],
    charts: [
      ChartSpec(
        kind: SmartChartKind.line,
        title: 'الإيراد مقابل المصروف',
        labels: [for (final m in months) _monthLabel(m)],
        series: [
          SmartSeries(name: 'الإيراد', color: c.taj.success.main, values: revenue),
          SmartSeries(name: 'المصروف', color: c.taj.error.main, values: expense),
        ],
        unit: 'د.ل',
      ),
    ],
  );
}
