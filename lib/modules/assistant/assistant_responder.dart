import 'package:flutter/material.dart';

import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_store.dart';
import '../../core/format.dart';
import 'assistant_models.dart';

/// The ready suggested questions shown as chips / an empty-state grid.
const List<SuggestedQuestion> suggestedQuestions = [
  SuggestedQuestion(id: 'sales7', text: 'كم بلغت مبيعات آخر ٧ أيام؟', icon: Icons.show_chart_rounded),
  SuggestedQuestion(id: 'top_products', text: 'ما أكثر المنتجات مبيعًا؟', icon: Icons.local_fire_department_outlined),
  SuggestedQuestion(id: 'expenses', text: 'أين تذهب مصروفاتي؟', icon: Icons.account_balance_wallet_outlined),
  SuggestedQuestion(id: 'top_customers', text: 'من هم أكبر العملاء؟', icon: Icons.groups_outlined),
  SuggestedQuestion(id: 'rev_exp', text: 'قارن الإيراد بالمصروف', icon: Icons.compare_arrows_rounded),
  SuggestedQuestion(id: 'low_stock', text: 'ما الأصناف منخفضة المخزون؟', icon: Icons.inventory_2_outlined),
];

/// Builds a canned, data-backed answer for a suggested-question [id], or a
/// helpful fallback for free text. (No network / prompt logic exists to
/// preserve — this is the module's own demo responder.)
AssistantAnswer answerFor(DemoStore s, String idOrText) {
  switch (idOrText) {
    case 'sales7':
      return _sales7(s);
    case 'top_products':
      return _topProducts(s);
    case 'expenses':
      return _expenses(s);
    case 'top_customers':
      return _topCustomers(s);
    case 'rev_exp':
      return _revExp(s);
    case 'low_stock':
      return _lowStock(s);
    default:
      return const AssistantAnswer(
        text:
            'يمكنني تحليل مبيعاتك ومصروفاتك ومخزونك وعملائك. جرّب أحد الأسئلة المقترحة بالأسفل، أو اسأل عن المبيعات أو المصروفات.',
      );
  }
}

AssistantAnswer _sales7(DemoStore s) {
  final vals = s.lastSevenDaySales;
  final total = vals.fold<double>(0, (a, b) => a + b);
  final avg = vals.isEmpty ? 0.0 : total / vals.length;
  final now = DateTime.now();
  final labels = [
    for (var i = 6; i >= 0; i--)
      () {
        final d = now.subtract(Duration(days: i));
        return '${d.month}/${d.day}';
      }()
  ];
  return AssistantAnswer(
    text:
        'بلغت مبيعات آخر ٧ أيام ${arDinar(total)} بمتوسط ${arDinar(avg)} يوميًا. مرجع الاستعلام: TAJ-AI-QUERY-20260911-000000000123456789.',
    kpis: [
      AnswerKpi(label: 'إجمالي الأسبوع', value: arDinar(total), icon: Icons.receipt_long_outlined, spark: vals),
      AnswerKpi(label: 'المتوسط اليومي', value: arDinar(avg), icon: Icons.timeline_rounded),
    ],
    chart: AnswerChart(kind: AnswerChartKind.line, labels: labels, values: vals, unit: 'د.ل'),
  );
}

AssistantAnswer _topProducts(DemoStore s) {
  final names = {for (final p in s.products) p.id: p.name};
  final qty = <String, double>{};
  final rev = <String, double>{};
  for (final sale in s.sales.where((x) =>
      x.status != DemoSaleStatus.cancelled && x.status != DemoSaleStatus.returned)) {
    for (final l in sale.lines) {
      qty[l.productId] = (qty[l.productId] ?? 0) + l.quantity;
      rev[l.productId] = (rev[l.productId] ?? 0) + l.total;
    }
  }
  final ranked = qty.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final top = ranked.take(5).toList();
  final best = top.isEmpty ? '—' : (names[top.first.key] ?? top.first.key);
  return AssistantAnswer(
    text: top.isEmpty
        ? 'لا توجد مبيعات مسجّلة بعد لتحليل الأصناف.'
        : 'الصنف «$best» هو الأكثر مبيعًا من حيث الكمية. إليك أعلى ٥ أصناف:',
    table: AnswerTable(
      columns: const ['الصنف', 'الكمية', 'الإيراد (د.ل)'],
      numeric: const [false, true, true],
      rows: [
        for (final e in top)
          [names[e.key] ?? e.key, arNum(e.value), arNum(rev[e.key] ?? 0)],
      ],
    ),
    chart: AnswerChart(
      kind: AnswerChartKind.bars,
      labels: [for (final e in top) names[e.key] ?? e.key],
      values: [for (final e in top) e.value],
      unit: 'وحدة',
    ),
  );
}

AssistantAnswer _expenses(DemoStore s) {
  final byCat = <String, double>{};
  for (final e in s.expenses) {
    byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
  }
  final total = byCat.values.fold<double>(0, (a, b) => a + b);
  final ranked = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final topCat = ranked.isEmpty ? '—' : ranked.first.key;
  final share = total == 0 || ranked.isEmpty ? 0 : (ranked.first.value / total * 100).round();
  return AssistantAnswer(
    text: total == 0
        ? 'لا توجد مصروفات مسجّلة بعد.'
        : 'إجمالي مصروفاتك ${arDinar(total)}، وأعلى تصنيف هو «$topCat» بنسبة $share٪.',
    kpis: [
      AnswerKpi(label: 'إجمالي المصروفات', value: arDinar(total), icon: Icons.payments_outlined),
      AnswerKpi(label: 'أعلى تصنيف', value: topCat, icon: Icons.category_outlined),
    ],
    chart: AnswerChart(
      kind: AnswerChartKind.donut,
      labels: [for (final e in ranked) e.key],
      values: [for (final e in ranked) e.value],
      unit: 'د.ل',
    ),
  );
}

AssistantAnswer _topCustomers(DemoStore s) {
  final ranked = [...s.customers]..sort((a, b) => b.balance.compareTo(a.balance));
  final top = ranked.take(5).toList();
  final receivable = s.customers.fold<double>(0, (a, b) => a + b.balance);
  return AssistantAnswer(
    text: 'إجمالي ذمم العملاء ${arDinar(receivable)}. أعلى العملاء رصيدًا:',
    table: AnswerTable(
      columns: const ['العميل', 'الهاتف', 'الرصيد (د.ل)'],
      numeric: const [false, false, true],
      rows: [
        for (final c in top) [c.name, c.phone, arNum(c.balance)],
      ],
    ),
  );
}

AssistantAnswer _revExp(DemoStore s) {
  final revenue = s.salesTotal;
  final expense = s.expenses.fold<double>(0, (a, b) => a + b.amount);
  final net = revenue - expense;
  return AssistantAnswer(
    text: net >= 0
        ? 'إيراداتك ${arDinar(revenue)} تفوق مصروفاتك ${arDinar(expense)} بصافي ربح ${arDinar(net)}.'
        : 'مصروفاتك ${arDinar(expense)} تفوق إيراداتك ${arDinar(revenue)} بصافي خسارة ${arDinar(net.abs())}.',
    kpis: [
      AnswerKpi(label: 'الإيرادات', value: arDinar(revenue), icon: Icons.south_west_rounded),
      AnswerKpi(label: 'المصروفات', value: arDinar(expense), icon: Icons.north_east_rounded),
      AnswerKpi(label: net >= 0 ? 'صافي الربح' : 'صافي الخسارة', value: arDinar(net), icon: Icons.savings_outlined),
    ],
    chart: AnswerChart(
      kind: AnswerChartKind.bars,
      labels: const ['الإيراد', 'المصروف'],
      values: [revenue, expense],
      unit: 'د.ل',
    ),
  );
}

AssistantAnswer _lowStock(DemoStore s) {
  final low = s.products.where((p) => p.stock <= p.reorderLevel).toList()
    ..sort((a, b) => a.stock.compareTo(b.stock));
  return AssistantAnswer(
    text: low.isEmpty
        ? 'كل الأصناف ضمن مستويات المخزون الآمنة.'
        : 'يوجد ${arNum(low.length)} صنفًا عند أو تحت حد إعادة الطلب:',
    table: AnswerTable(
      columns: const ['الصنف', 'المخزون', 'حد الطلب'],
      numeric: const [false, true, true],
      rows: [
        for (final p in low) [p.name, arNum(p.stock), arNum(p.reorderLevel)],
      ],
    ),
  );
}
