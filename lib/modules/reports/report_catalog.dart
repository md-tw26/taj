import 'package:flutter/material.dart';

import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_store.dart';
import '../../core/format.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_report_table.dart';
import 'report_models.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Demo, clearly-labelled tax rate — the tax report notes this assumption.
const double _kSalesTaxRate = 0.04;

/// Zakat rate (2.5%).
const double _kZakatRate = 0.025;

DateTime _now() => DateTime.now();

String _fmtDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

String _branchName(DemoStore s, String id) {
  for (final b in s.branches) {
    if (b.id == id) return b.name;
  }
  return id;
}

bool _branchOk(String? entityBranch, ReportFilters f) =>
    f.branchId == null || entityBranch == f.branchId;

String _method(DemoPaymentMethod m) => switch (m) {
      DemoPaymentMethod.cash => 'نقدي',
      DemoPaymentMethod.bank => 'تحويل مصرفي',
      DemoPaymentMethod.card => 'بطاقة',
      DemoPaymentMethod.sadad => 'سداد',
      DemoPaymentMethod.credit => 'آجل',
    };

String _accountType(DemoLedgerAccountType t) => switch (t) {
      DemoLedgerAccountType.asset => 'أصول',
      DemoLedgerAccountType.liability => 'خصوم',
      DemoLedgerAccountType.equity => 'حقوق ملكية',
      DemoLedgerAccountType.revenue => 'إيرادات',
      DemoLedgerAccountType.expense => 'مصروفات',
    };

List<Color> _palette(BuildContext c) {
  final t = c.taj;
  return [
    t.primary.main,
    t.info.main,
    t.warning.main,
    t.success.main,
    t.secondary.main,
    t.error.main,
  ];
}

/// Leaf (posting) accounts — the ones balances are computed against.
List<DemoLedgerAccount> _leaves(DemoStore s) =>
    s.ledgerAccounts.where((a) => s.isLeafAccount(a.id)).toList()
      ..sort((a, b) => a.code.compareTo(b.code));

/// Net income for the current book (revenue − expenses), reused by the income
/// statement and balance sheet so the two never disagree.
double _netIncome(DemoStore s) {
  var revenue = 0.0, expense = 0.0;
  for (final a in _leaves(s)) {
    if (a.type == DemoLedgerAccountType.revenue) revenue += -s.ledgerBalance(a.id);
    if (a.type == DemoLedgerAccountType.expense) expense += s.ledgerBalance(a.id);
  }
  return revenue - expense;
}

// A number cell using the shared tabular numeral style.
Widget _n(BuildContext c, num v, {bool emphasize = false, bool tone = false}) {
  Color? color;
  if (tone) color = v < 0 ? c.taj.error.main : (v > 0 ? c.taj.success.dark : null);
  return reportCell(c, arNum(v), numeric: true, emphasize: emphasize, color: color);
}

Widget _t(BuildContext c, String s,
        {bool emphasize = false, bool muted = false, Color? color}) =>
    reportCell(c, s, emphasize: emphasize, muted: muted, color: color);

// ---------------------------------------------------------------------------
// The catalogue
// ---------------------------------------------------------------------------

/// Every report the centre offers. Order defines index order within a category.
final List<ReportDef> reportCatalog = [
  // ---- Financial ---------------------------------------------------------
  ReportDef(
    id: 'trial_balance',
    title: 'ميزان المراجعة',
    description: 'أرصدة الحسابات المدينة والدائنة والتحقق من توازنها.',
    icon: Icons.balance_outlined,
    category: ReportCategory.financial,
    build: _trialBalance,
  ),
  ReportDef(
    id: 'income_statement',
    title: 'قائمة الدخل',
    description: 'الإيرادات ناقص المصروفات وصافي ربح أو خسارة الفترة.',
    icon: Icons.trending_up_rounded,
    category: ReportCategory.financial,
    hierarchical: true,
    build: _incomeStatement,
  ),
  ReportDef(
    id: 'balance_sheet',
    title: 'الميزانية العمومية',
    description: 'الأصول والخصوم وحقوق الملكية كما هي حتى تاريخه.',
    icon: Icons.account_balance_outlined,
    category: ReportCategory.financial,
    hierarchical: true,
    build: _balanceSheet,
  ),
  ReportDef(
    id: 'cash_flow',
    title: 'التدفقات النقدية',
    description: 'حركة النقد الداخل والخارج عبر الخزائن والمصارف.',
    icon: Icons.swap_vert_rounded,
    category: ReportCategory.financial,
    hierarchical: true,
    build: _cashFlow,
  ),
  ReportDef(
    id: 'ledger',
    title: 'دفتر الأستاذ',
    description: 'حركة حساب مُختار مع الرصيد الجاري بعد كل قيد.',
    icon: Icons.receipt_long_outlined,
    category: ReportCategory.financial,
    build: _ledger,
    // Segment (account) options are injected dynamically; see reportSegmentFor.
    segment: const ReportSegment(label: 'الحساب', options: []),
  ),
  ReportDef(
    id: 'journal',
    title: 'دفتر اليومية',
    description: 'كل قيود اليومية وسطورها المدينة والدائنة.',
    icon: Icons.menu_book_outlined,
    category: ReportCategory.financial,
    build: _journal,
    segment: const ReportSegment(label: 'الحالة', options: [
      ReportSegmentOption(null, 'كل القيود'),
      ReportSegmentOption('posted', 'مُرحّلة'),
      ReportSegmentOption('draft', 'مسودة'),
      ReportSegmentOption('reversed', 'معكوسة'),
    ]),
  ),

  // ---- Tax & Zakat -------------------------------------------------------
  ReportDef(
    id: 'sales_tax',
    title: 'التقرير الضريبي',
    description: 'المبيعات الخاضعة والضريبة المستحقة حسب الفرع.',
    icon: Icons.request_quote_outlined,
    category: ReportCategory.tax,
    build: _salesTax,
  ),
  ReportDef(
    id: 'zakat',
    title: 'حساب الزكاة',
    description: 'وعاء الزكاة من الموجودات الزكوية والزكاة المستحقة.',
    icon: Icons.volunteer_activism_outlined,
    category: ReportCategory.tax,
    build: _zakat,
  ),

  // ---- HR ----------------------------------------------------------------
  ReportDef(
    id: 'payroll',
    title: 'مسير الرواتب',
    description: 'مكوّنات الراتب والاستقطاعات وصافي المستحق لكل موظف.',
    icon: Icons.payments_outlined,
    category: ReportCategory.hr,
    build: _payroll,
  ),
  ReportDef(
    id: 'employees',
    title: 'كشف الموظفين',
    description: 'بيانات الموظفين ومسمياتهم وفروعهم وتواريخ التعيين.',
    icon: Icons.badge_outlined,
    category: ReportCategory.hr,
    build: _employees,
  ),

  // ---- Operations --------------------------------------------------------
  ReportDef(
    id: 'partners',
    title: 'العملاء والموردون',
    description: 'أرصدة العملاء والموردين وحدود الائتمان.',
    icon: Icons.handshake_outlined,
    category: ReportCategory.operations,
    build: _partners,
    segment: const ReportSegment(label: 'النوع', options: [
      ReportSegmentOption(null, 'الكل'),
      ReportSegmentOption('customer', 'العملاء'),
      ReportSegmentOption('supplier', 'الموردون'),
    ]),
  ),
  ReportDef(
    id: 'expenses',
    title: 'تقرير المصروفات',
    description: 'المصروفات حسب التصنيف والفرع وطريقة الدفع.',
    icon: Icons.account_balance_wallet_outlined,
    category: ReportCategory.operations,
    build: _expenses,
    // Category options injected dynamically; see reportSegmentFor.
    segment: const ReportSegment(label: 'التصنيف', options: []),
  ),
];

ReportDef reportById(String id) =>
    reportCatalog.firstWhere((r) => r.id == id, orElse: () => reportCatalog.first);

/// Resolve the segment for [def], filling in the dynamic option lists (ledger
/// accounts / expense categories) from the live store.
ReportSegment? reportSegmentFor(ReportDef def, DemoStore store) {
  if (def.segment == null) return null;
  switch (def.id) {
    case 'ledger':
      final opts = <ReportSegmentOption>[];
      for (final a in _leaves(store)) {
        if (store.entriesTouching(a.id).isNotEmpty) {
          opts.add(ReportSegmentOption(a.id, '${a.code} · ${a.name}'));
        }
      }
      return ReportSegment(label: 'الحساب', options: opts);
    case 'expenses':
      final cats = <String>{for (final e in store.expenses) e.category}.toList()
        ..sort();
      return ReportSegment(label: 'التصنيف', options: [
        const ReportSegmentOption(null, 'كل التصنيفات'),
        for (final c in cats) ReportSegmentOption(c, c),
      ]);
    default:
      return def.segment;
  }
}

// ---------------------------------------------------------------------------
// Financial reports
// ---------------------------------------------------------------------------

ReportResult _trialBalance(BuildContext c, DemoStore s, ReportFilters f) {
  final rows = <ReportRow>[];
  var totalD = 0.0, totalC = 0.0;
  final chartLabels = <String>[];
  final chartVals = <double>[];
  for (final a in _leaves(s)) {
    final (d, cr) = s.ledgerDebitCredit(a.id);
    if (d == 0 && cr == 0) continue;
    totalD += d;
    totalC += cr;
    rows.add(ReportRow(cells: [
      _t(c, a.name),
      _t(c, a.code, muted: true),
      _t(c, _accountType(a.type), muted: true),
      _n(c, d),
      _n(c, cr),
    ]));
    if (chartLabels.length < 6) {
      chartLabels.add(a.name);
      chartVals.add((d - cr).abs());
    }
  }
  final columns = const [
    ReportColumn('الحساب', sticky: true, minWidth: 180, flex: 3),
    ReportColumn('الرمز', minWidth: 90, priority: 2),
    ReportColumn('النوع', minWidth: 100, priority: 3),
    ReportColumn('مدين (د.ل)', numeric: true, minWidth: 130),
    ReportColumn('دائن (د.ل)', numeric: true, minWidth: 130),
  ];
  final totals = ReportRow(emphasize: true, cells: [
    _t(c, 'الإجمالي', emphasize: true),
    const SizedBox(),
    const SizedBox(),
    _n(c, totalD, emphasize: true),
    _n(c, totalC, emphasize: true),
  ]);
  final diff = totalD - totalC;
  return ReportResult(
    columns: columns,
    rows: rows,
    totals: totals,
    summary: [
      ReportStat(label: 'إجمالي المدين', value: arDinar(totalD), icon: Icons.south_east_rounded),
      ReportStat(label: 'إجمالي الدائن', value: arDinar(totalC), icon: Icons.north_east_rounded),
      ReportStat(
        label: 'الفرق',
        value: arDinar(diff),
        tone: diff.abs() < 0.005 ? c.taj.success.dark : c.taj.error.main,
        icon: diff.abs() < 0.005 ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
      ),
    ],
    chart: ReportChartData(
      type: ReportChartType.bars,
      title: 'أكبر الأرصدة',
      labels: chartLabels,
      series: [ReportSeries(label: 'الرصيد', color: _palette(c).first, values: chartVals)],
    ),
    note: diff.abs() < 0.005 ? null : 'ملاحظة: الميزان غير متوازن بفارق ${arDinar(diff)}.',
  );
}

ReportResult _incomeStatement(BuildContext c, DemoStore s, ReportFilters f) {
  final rows = <ReportRow>[];
  final columns = const [
    ReportColumn('البيان', sticky: true, minWidth: 200, flex: 3),
    ReportColumn('المبلغ (د.ل)', numeric: true, minWidth: 150),
  ];
  var totalRev = 0.0, totalExp = 0.0;

  rows.add(ReportRow(emphasize: true, cells: [_t(c, 'الإيرادات', emphasize: true), const SizedBox()]));
  for (final a in _leaves(s)) {
    if (a.type != DemoLedgerAccountType.revenue) continue;
    final amt = -s.ledgerBalance(a.id);
    if (amt == 0) continue;
    totalRev += amt;
    rows.add(ReportRow(depth: 1, cells: [_t(c, a.name), _n(c, amt)]));
  }
  rows.add(ReportRow(emphasize: true, cells: [_t(c, 'إجمالي الإيرادات', emphasize: true), _n(c, totalRev, emphasize: true)]));

  rows.add(ReportRow(emphasize: true, cells: [_t(c, 'المصروفات', emphasize: true), const SizedBox()]));
  for (final a in _leaves(s)) {
    if (a.type != DemoLedgerAccountType.expense) continue;
    final amt = s.ledgerBalance(a.id);
    if (amt == 0) continue;
    totalExp += amt;
    rows.add(ReportRow(depth: 1, cells: [_t(c, a.name), _n(c, amt)]));
  }
  rows.add(ReportRow(emphasize: true, cells: [_t(c, 'إجمالي المصروفات', emphasize: true), _n(c, totalExp, emphasize: true)]));

  final net = totalRev - totalExp;
  rows.add(ReportRow(emphasize: true, cells: [
    _t(c, net >= 0 ? 'صافي الربح' : 'صافي الخسارة', emphasize: true),
    _n(c, net, emphasize: true, tone: true),
  ]));

  return ReportResult(
    columns: columns,
    rows: rows,
    summary: [
      ReportStat(label: 'الإيرادات', value: arDinar(totalRev), tone: c.taj.success.dark),
      ReportStat(label: 'المصروفات', value: arDinar(totalExp), tone: c.taj.error.main),
      ReportStat(
        label: net >= 0 ? 'صافي الربح' : 'صافي الخسارة',
        value: arDinar(net),
        tone: net >= 0 ? c.taj.success.dark : c.taj.error.main,
      ),
    ],
    chart: ReportChartData(
      type: ReportChartType.bars,
      title: 'الإيرادات مقابل المصروفات',
      labels: const ['الإيرادات', 'المصروفات', 'الصافي'],
      series: [
        ReportSeries(label: 'المبلغ', color: _palette(c).first, values: [totalRev, totalExp, net]),
      ],
    ),
  );
}

ReportResult _balanceSheet(BuildContext c, DemoStore s, ReportFilters f) {
  final rows = <ReportRow>[];
  final columns = const [
    ReportColumn('البيان', sticky: true, minWidth: 200, flex: 3),
    ReportColumn('المبلغ (د.ل)', numeric: true, minWidth: 150),
  ];

  double section(DemoLedgerAccountType type, bool creditNormal, String header) {
    rows.add(ReportRow(emphasize: true, cells: [_t(c, header, emphasize: true), const SizedBox()]));
    var total = 0.0;
    for (final a in _leaves(s)) {
      if (a.type != type) continue;
      final amt = creditNormal ? -s.ledgerBalance(a.id) : s.ledgerBalance(a.id);
      if (amt == 0) continue;
      total += amt;
      rows.add(ReportRow(depth: 1, cells: [_t(c, a.name), _n(c, amt)]));
    }
    return total;
  }

  final assets = section(DemoLedgerAccountType.asset, false, 'الأصول');
  rows.add(ReportRow(emphasize: true, cells: [_t(c, 'إجمالي الأصول', emphasize: true), _n(c, assets, emphasize: true)]));

  final liabilities = section(DemoLedgerAccountType.liability, true, 'الخصوم');
  rows.add(ReportRow(emphasize: true, cells: [_t(c, 'إجمالي الخصوم', emphasize: true), _n(c, liabilities, emphasize: true)]));

  var equity = section(DemoLedgerAccountType.equity, true, 'حقوق الملكية');
  final profit = _netIncome(s);
  rows.add(ReportRow(depth: 1, cells: [_t(c, 'أرباح الفترة'), _n(c, profit, tone: true)]));
  equity += profit;
  rows.add(ReportRow(emphasize: true, cells: [_t(c, 'إجمالي حقوق الملكية', emphasize: true), _n(c, equity, emphasize: true)]));

  final liabPlusEquity = liabilities + equity;
  final totals = ReportRow(emphasize: true, cells: [
    _t(c, 'إجمالي الخصوم وحقوق الملكية', emphasize: true),
    _n(c, liabPlusEquity, emphasize: true),
  ]);

  final balanced = (assets - liabPlusEquity).abs() < 0.005;
  return ReportResult(
    columns: columns,
    rows: rows,
    totals: totals,
    summary: [
      ReportStat(label: 'إجمالي الأصول', value: arDinar(assets)),
      ReportStat(label: 'الخصوم وحقوق الملكية', value: arDinar(liabPlusEquity)),
      ReportStat(
        label: 'التوازن',
        value: balanced ? 'متوازنة' : 'غير متوازنة',
        tone: balanced ? c.taj.success.dark : c.taj.error.main,
        icon: balanced ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
      ),
    ],
    chart: ReportChartData(
      type: ReportChartType.donut,
      title: 'هيكل المركز المالي',
      labels: const ['الأصول', 'الخصوم', 'حقوق الملكية'],
      series: [
        ReportSeries(label: 'القيمة', color: _palette(c).first, values: [assets, liabilities, equity]),
      ],
    ),
  );
}

ReportResult _cashFlow(BuildContext c, DemoStore s, ReportFilters f) {
  final now = _now();
  final accounts = s.accounts.where((a) => _branchOk(a.branchId, f)).toList();
  final accountIds = accounts.map((a) => a.id).toSet();
  final opening = accounts.fold<double>(0, (sum, a) => sum + a.openingBalance);

  final moves = s.treasuryMovements
      .where((m) => accountIds.contains(m.accountId) && f.includes(m.date, now))
      .toList();

  double sumWhere(bool Function(DemoTreasuryMovement) test) =>
      moves.where(test).fold<double>(0, (sum, m) => sum + m.amount);

  final deposits = sumWhere((m) => m.isInflow && m.type == DemoMovementType.deposit);
  final transfersIn = sumWhere((m) => m.isInflow && m.type == DemoMovementType.transfer);
  final reconIn = sumWhere((m) => m.isInflow && m.type == DemoMovementType.reconcile);
  final withdrawals = sumWhere((m) => !m.isInflow && m.type == DemoMovementType.withdraw);
  final transfersOut = sumWhere((m) => !m.isInflow && m.type == DemoMovementType.transfer);
  final reconOut = sumWhere((m) => !m.isInflow && m.type == DemoMovementType.reconcile);
  final inflow = deposits + transfersIn + reconIn;
  final outflow = withdrawals + transfersOut + reconOut;
  final net = inflow - outflow;
  final closing = opening + net;

  final columns = const [
    ReportColumn('البيان', sticky: true, minWidth: 220, flex: 3),
    ReportColumn('المبلغ (د.ل)', numeric: true, minWidth: 150),
  ];
  final rows = <ReportRow>[
    ReportRow(cells: [_t(c, 'النقدية في بداية المدة'), _n(c, opening)]),
    ReportRow(emphasize: true, cells: [_t(c, 'التدفقات الداخلة', emphasize: true), const SizedBox()]),
    if (deposits != 0) ReportRow(depth: 1, cells: [_t(c, 'إيداعات نقدية'), _n(c, deposits)]),
    if (transfersIn != 0) ReportRow(depth: 1, cells: [_t(c, 'تحويلات واردة'), _n(c, transfersIn)]),
    if (reconIn != 0) ReportRow(depth: 1, cells: [_t(c, 'تسويات دائنة'), _n(c, reconIn)]),
    ReportRow(emphasize: true, cells: [_t(c, 'إجمالي الداخل', emphasize: true), _n(c, inflow, emphasize: true)]),
    ReportRow(emphasize: true, cells: [_t(c, 'التدفقات الخارجة', emphasize: true), const SizedBox()]),
    if (withdrawals != 0) ReportRow(depth: 1, cells: [_t(c, 'سحوبات ومدفوعات'), _n(c, -withdrawals, tone: true)]),
    if (transfersOut != 0) ReportRow(depth: 1, cells: [_t(c, 'تحويلات صادرة'), _n(c, -transfersOut, tone: true)]),
    if (reconOut != 0) ReportRow(depth: 1, cells: [_t(c, 'تسويات مدينة'), _n(c, -reconOut, tone: true)]),
    ReportRow(emphasize: true, cells: [_t(c, 'إجمالي الخارج', emphasize: true), _n(c, -outflow, emphasize: true, tone: true)]),
    ReportRow(emphasize: true, cells: [_t(c, 'صافي التدفق النقدي', emphasize: true), _n(c, net, emphasize: true, tone: true)]),
  ];
  final totals = ReportRow(emphasize: true, cells: [
    _t(c, 'النقدية في نهاية المدة', emphasize: true),
    _n(c, closing, emphasize: true),
  ]);

  return ReportResult(
    columns: columns,
    rows: rows,
    totals: totals,
    summary: [
      ReportStat(label: 'التدفقات الداخلة', value: arDinar(inflow), tone: c.taj.success.dark, icon: Icons.south_west_rounded),
      ReportStat(label: 'التدفقات الخارجة', value: arDinar(outflow), tone: c.taj.error.main, icon: Icons.north_east_rounded),
      ReportStat(label: 'صافي التدفق', value: arDinar(net), tone: net >= 0 ? c.taj.success.dark : c.taj.error.main),
    ],
    chart: ReportChartData(
      type: ReportChartType.bars,
      title: 'الداخل مقابل الخارج',
      labels: const ['الداخل', 'الخارج', 'الصافي'],
      series: [ReportSeries(label: 'المبلغ', color: _palette(c).first, values: [inflow, outflow, net])],
    ),
  );
}

ReportResult _ledger(BuildContext c, DemoStore s, ReportFilters f) {
  final now = _now();
  // Resolve the account: explicit segment, else the first leaf with activity.
  String? accountId = f.segment;
  if (accountId == null || s.ledgerAccountById(accountId) == null) {
    for (final a in _leaves(s)) {
      if (s.entriesTouching(a.id).isNotEmpty) {
        accountId = a.id;
        break;
      }
    }
  }
  final columns = const [
    ReportColumn('التاريخ', sticky: true, minWidth: 120, flex: 1),
    ReportColumn('القيد', minWidth: 90, priority: 1),
    ReportColumn('البيان', minWidth: 200, priority: 2, flex: 2),
    ReportColumn('مدين (د.ل)', numeric: true, minWidth: 120),
    ReportColumn('دائن (د.ل)', numeric: true, minWidth: 120),
    ReportColumn('الرصيد (د.ل)', numeric: true, minWidth: 130),
  ];
  if (accountId == null) {
    return ReportResult(columns: columns, rows: const []);
  }
  final account = s.ledgerAccountById(accountId)!;
  final entries = s
      .entriesTouching(accountId)
      .where((e) => f.includes(e.date, now) && _branchOk(e.branchId, f))
      .toList();

  final rows = <ReportRow>[];
  var running = account.openingBalance;
  var totalD = 0.0, totalC = 0.0;
  final balances = <double>[];
  rows.add(ReportRow(cells: [
    _t(c, _fmtDate(now), muted: true),
    _t(c, '—', muted: true),
    _t(c, 'رصيد افتتاحي', muted: true),
    _n(c, 0),
    _n(c, 0),
    _n(c, running),
  ]));
  for (final e in entries) {
    var d = 0.0, cr = 0.0;
    final descParts = <String>[];
    for (final l in e.lines) {
      if (l.accountId == accountId) {
        d += l.debit;
        cr += l.credit;
        if (l.description.isNotEmpty) descParts.add(l.description);
      }
    }
    running += d - cr;
    totalD += d;
    totalC += cr;
    balances.add(running);
    rows.add(ReportRow(cells: [
      _t(c, _fmtDate(e.date)),
      _t(c, e.number, muted: true),
      _t(c, descParts.isEmpty ? e.description : descParts.join(' · ')),
      _n(c, d),
      _n(c, cr),
      _n(c, running),
    ]));
  }
  final totals = ReportRow(emphasize: true, cells: [
    _t(c, 'الإجمالي', emphasize: true),
    const SizedBox(),
    const SizedBox(),
    _n(c, totalD, emphasize: true),
    _n(c, totalC, emphasize: true),
    _n(c, running, emphasize: true),
  ]);

  return ReportResult(
    columns: columns,
    rows: rows,
    totals: totals,
    summary: [
      ReportStat(label: 'الحساب', value: '${account.code} · ${account.name}'),
      ReportStat(label: 'إجمالي الحركة المدينة', value: arDinar(totalD)),
      ReportStat(label: 'الرصيد الختامي', value: arDinar(running), tone: running >= 0 ? null : c.taj.error.main),
    ],
    chart: balances.length < 2
        ? null
        : ReportChartData(
            type: ReportChartType.line,
            title: 'تطوّر الرصيد',
            labels: [for (final e in entries) e.number],
            series: [ReportSeries(label: 'الرصيد', color: _palette(c).first, values: balances)],
          ),
  );
}

ReportResult _journal(BuildContext c, DemoStore s, ReportFilters f) {
  final now = _now();
  final columns = const [
    ReportColumn('التاريخ', sticky: true, minWidth: 120, flex: 1),
    ReportColumn('القيد', minWidth: 90, priority: 1),
    ReportColumn('الحساب', minWidth: 150, priority: 0, flex: 1),
    ReportColumn('البيان', minWidth: 180, priority: 2, flex: 2),
    ReportColumn('مدين (د.ل)', numeric: true, minWidth: 120),
    ReportColumn('دائن (د.ل)', numeric: true, minWidth: 120),
  ];
  final entries = s.journalEntries.where((e) {
    if (!f.includes(e.date, now) || !_branchOk(e.branchId, f)) return false;
    if (f.segment != null && e.status.name != f.segment) return false;
    return true;
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final rows = <ReportRow>[];
  var totalD = 0.0, totalC = 0.0;
  for (final e in entries) {
    for (var i = 0; i < e.lines.length; i++) {
      final l = e.lines[i];
      totalD += l.debit;
      totalC += l.credit;
      final acc = s.ledgerAccountById(l.accountId);
      rows.add(ReportRow(cells: [
        _t(c, i == 0 ? _fmtDate(e.date) : ''),
        _t(c, i == 0 ? e.number : '', muted: true),
        _t(c, acc?.name ?? l.accountId),
        _t(c, l.description.isEmpty ? e.description : l.description, muted: true),
        _n(c, l.debit),
        _n(c, l.credit),
      ]));
    }
  }
  final totals = ReportRow(emphasize: true, cells: [
    _t(c, 'الإجمالي', emphasize: true),
    const SizedBox(),
    const SizedBox(),
    const SizedBox(),
    _n(c, totalD, emphasize: true),
    _n(c, totalC, emphasize: true),
  ]);

  return ReportResult(
    columns: columns,
    rows: rows,
    totals: totals,
    summary: [
      ReportStat(label: 'عدد القيود', value: arNum(entries.length)),
      ReportStat(label: 'إجمالي المدين', value: arDinar(totalD)),
      ReportStat(label: 'إجمالي الدائن', value: arDinar(totalC)),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tax & Zakat
// ---------------------------------------------------------------------------

ReportResult _salesTax(BuildContext c, DemoStore s, ReportFilters f) {
  final now = _now();
  final columns = const [
    ReportColumn('الفرع', sticky: true, minWidth: 180, flex: 3),
    ReportColumn('المبيعات الخاضعة (د.ل)', numeric: true, minWidth: 170),
    ReportColumn('النسبة', numeric: true, minWidth: 90),
    ReportColumn('الضريبة المستحقة (د.ل)', numeric: true, minWidth: 170),
  ];
  final rows = <ReportRow>[];
  var totalTaxable = 0.0, totalTax = 0.0;
  final chartLabels = <String>[];
  final chartVals = <double>[];
  for (final b in s.branches) {
    if (!_branchOk(b.id, f)) continue;
    final taxable = s.sales
        .where((sale) =>
            sale.branchId == b.id &&
            sale.status != DemoSaleStatus.cancelled &&
            sale.status != DemoSaleStatus.returned &&
            f.includes(sale.date, now))
        .fold<double>(0, (sum, sale) => sum + sale.total);
    if (taxable == 0) continue;
    final tax = taxable * _kSalesTaxRate;
    totalTaxable += taxable;
    totalTax += tax;
    chartLabels.add(b.name);
    chartVals.add(tax);
    rows.add(ReportRow(cells: [
      _t(c, b.name),
      _n(c, taxable),
      reportCell(c, '${(_kSalesTaxRate * 100).round()}%', numeric: true, muted: true),
      _n(c, tax),
    ]));
  }
  final totals = ReportRow(emphasize: true, cells: [
    _t(c, 'الإجمالي', emphasize: true),
    _n(c, totalTaxable, emphasize: true),
    const SizedBox(),
    _n(c, totalTax, emphasize: true),
  ]);
  return ReportResult(
    columns: columns,
    rows: rows,
    totals: totals,
    summary: [
      ReportStat(label: 'المبيعات الخاضعة', value: arDinar(totalTaxable)),
      ReportStat(label: 'الضريبة المستحقة', value: arDinar(totalTax), tone: c.taj.warning.dark),
    ],
    chart: ReportChartData(
      type: ReportChartType.bars,
      title: 'الضريبة حسب الفرع',
      labels: chartLabels,
      series: [ReportSeries(label: 'الضريبة', color: _palette(c)[2], values: chartVals)],
    ),
    note: 'احتُسبت الضريبة بنسبة توضيحية ${(_kSalesTaxRate * 100).round()}% على صافي المبيعات (بيانات تجريبية).',
  );
}

ReportResult _zakat(BuildContext c, DemoStore s, ReportFilters f) {
  double bal(String id) => s.ledgerAccountById(id) == null ? 0 : s.ledgerBalance(id);
  final cash = bal('1101');
  final banks = bal('1102');
  final receivables = bal('1103');
  final inventory = bal('1104');
  final payables = -bal('2101');
  final taxDue = -bal('2102');

  final zakatableAssets = cash + banks + receivables + inventory;
  final deductions = payables + taxDue;
  final base = zakatableAssets - deductions;
  final zakat = base > 0 ? base * _kZakatRate : 0.0;

  final columns = const [
    ReportColumn('البند', sticky: true, minWidth: 220, flex: 3),
    ReportColumn('المبلغ (د.ل)', numeric: true, minWidth: 150),
  ];
  final rows = <ReportRow>[
    ReportRow(cells: [_t(c, 'النقدية بالصناديق'), _n(c, cash)]),
    ReportRow(cells: [_t(c, 'الأرصدة المصرفية'), _n(c, banks)]),
    ReportRow(cells: [_t(c, 'ذمم العملاء'), _n(c, receivables)]),
    ReportRow(cells: [_t(c, 'المخزون'), _n(c, inventory)]),
    ReportRow(emphasize: true, cells: [_t(c, 'الموجودات الزكوية', emphasize: true), _n(c, zakatableAssets, emphasize: true)]),
    ReportRow(depth: 1, cells: [_t(c, 'ناقص: ذمم الموردين'), _n(c, -payables, tone: true)]),
    ReportRow(depth: 1, cells: [_t(c, 'ناقص: التزامات ضريبية'), _n(c, -taxDue, tone: true)]),
    ReportRow(emphasize: true, cells: [_t(c, 'وعاء الزكاة', emphasize: true), _n(c, base, emphasize: true)]),
  ];
  final totals = ReportRow(emphasize: true, cells: [
    _t(c, 'الزكاة المستحقة (٢٫٥٪)', emphasize: true),
    _n(c, zakat, emphasize: true, tone: false),
  ]);

  return ReportResult(
    columns: columns,
    rows: rows,
    totals: totals,
    summary: [
      ReportStat(label: 'وعاء الزكاة', value: arDinar(base)),
      ReportStat(label: 'الزكاة المستحقة', value: arDinar(zakat), tone: c.taj.primary.dark),
    ],
    chart: ReportChartData(
      type: ReportChartType.donut,
      title: 'مكوّنات الموجودات الزكوية',
      labels: const ['النقدية', 'المصارف', 'الذمم', 'المخزون'],
      series: [ReportSeries(label: 'القيمة', color: _palette(c).first, values: [cash, banks, receivables, inventory])],
    ),
    note: 'وعاء الزكاة = الموجودات الزكوية − الالتزامات المتداولة، والزكاة ٢٫٥٪ منه.',
  );
}

// ---------------------------------------------------------------------------
// HR
// ---------------------------------------------------------------------------

ReportResult _payroll(BuildContext c, DemoStore s, ReportFilters f) {
  final columns = const [
    ReportColumn('الموظف', sticky: true, minWidth: 170, flex: 2),
    ReportColumn('المسمى', minWidth: 120, priority: 1),
    ReportColumn('الأساسي (د.ل)', numeric: true, minWidth: 120),
    ReportColumn('البدلات (د.ل)', numeric: true, minWidth: 110),
    ReportColumn('المكافآت (د.ل)', numeric: true, minWidth: 110),
    ReportColumn('العمولات (د.ل)', numeric: true, minWidth: 110),
    ReportColumn('الإضافي (د.ل)', numeric: true, minWidth: 110),
    ReportColumn('الإجمالي (د.ل)', numeric: true, minWidth: 130),
    ReportColumn('الاستقطاعات (د.ل)', numeric: true, minWidth: 130),
    ReportColumn('الصافي (د.ل)', numeric: true, minWidth: 130),
  ];
  final emps = s.employees.where((e) => _branchOk(e.branchId, f)).toList();
  final rows = <ReportRow>[];
  var tBase = 0.0, tAllow = 0.0, tBonus = 0.0, tComm = 0.0, tOt = 0.0, tGross = 0.0, tDed = 0.0, tNet = 0.0;
  final chartLabels = <String>[];
  final chartVals = <double>[];
  for (final e in emps) {
    final ded = s.employeeDeductionsTotal(e.id);
    final net = s.employeeNet(e.id);
    tBase += e.baseSalary;
    tAllow += e.allowances;
    tBonus += e.bonuses;
    tComm += e.commissions;
    tOt += e.overtime;
    tGross += e.grossEarnings;
    tDed += ded;
    tNet += net;
    if (chartLabels.length < 6) {
      chartLabels.add(e.name);
      chartVals.add(net);
    }
    rows.add(ReportRow(cells: [
      _t(c, e.name),
      _t(c, e.title, muted: true),
      _n(c, e.baseSalary),
      _n(c, e.allowances),
      _n(c, e.bonuses),
      _n(c, e.commissions),
      _n(c, e.overtime),
      _n(c, e.grossEarnings),
      _n(c, ded),
      _n(c, net, emphasize: true),
    ]));
  }
  final totals = ReportRow(emphasize: true, cells: [
    _t(c, 'الإجمالي (${arNum(emps.length)})', emphasize: true),
    const SizedBox(),
    _n(c, tBase, emphasize: true),
    _n(c, tAllow, emphasize: true),
    _n(c, tBonus, emphasize: true),
    _n(c, tComm, emphasize: true),
    _n(c, tOt, emphasize: true),
    _n(c, tGross, emphasize: true),
    _n(c, tDed, emphasize: true),
    _n(c, tNet, emphasize: true),
  ]);
  return ReportResult(
    columns: columns,
    rows: rows,
    totals: totals,
    summary: [
      ReportStat(label: 'عدد الموظفين', value: arNum(emps.length), icon: Icons.groups_outlined),
      ReportStat(label: 'إجمالي الرواتب', value: arDinar(tGross)),
      ReportStat(label: 'صافي المستحق', value: arDinar(tNet), tone: c.taj.primary.dark),
    ],
    chart: ReportChartData(
      type: ReportChartType.bars,
      title: 'صافي الرواتب حسب الموظف',
      labels: chartLabels,
      series: [ReportSeries(label: 'الصافي', color: _palette(c).first, values: chartVals)],
    ),
  );
}

ReportResult _employees(BuildContext c, DemoStore s, ReportFilters f) {
  final columns = const [
    ReportColumn('الموظف', sticky: true, minWidth: 170, flex: 2),
    ReportColumn('المسمى', minWidth: 120, priority: 1),
    ReportColumn('الفرع', minWidth: 140, priority: 2),
    ReportColumn('الهاتف', minWidth: 120, priority: 3),
    ReportColumn('تاريخ التعيين', minWidth: 120, priority: 2),
    ReportColumn('الحالة', minWidth: 90, priority: 1),
    ReportColumn('الأساسي (د.ل)', numeric: true, minWidth: 120),
  ];
  final emps = s.employees.where((e) => _branchOk(e.branchId, f)).toList();
  var totalBase = 0.0;
  var active = 0;
  final rows = <ReportRow>[];
  for (final e in emps) {
    totalBase += e.baseSalary;
    if (e.active) active++;
    rows.add(ReportRow(cells: [
      _t(c, e.name),
      _t(c, e.title, muted: true),
      _t(c, _branchName(s, e.branchId), muted: true),
      _t(c, e.phone, muted: true),
      _t(c, _fmtDate(e.hireDate), muted: true),
      _t(c, e.active ? 'نشط' : 'موقوف', color: e.active ? c.taj.success.dark : c.taj.textDisabled),
      _n(c, e.baseSalary),
    ]));
  }
  final totals = ReportRow(emphasize: true, cells: [
    _t(c, 'الإجمالي (${arNum(emps.length)})', emphasize: true),
    const SizedBox(), const SizedBox(), const SizedBox(), const SizedBox(), const SizedBox(),
    _n(c, totalBase, emphasize: true),
  ]);
  // Employees per branch for the chart.
  final byBranch = <String, double>{};
  for (final e in emps) {
    byBranch[e.branchId] = (byBranch[e.branchId] ?? 0) + 1;
  }
  return ReportResult(
    columns: columns,
    rows: rows,
    totals: totals,
    summary: [
      ReportStat(label: 'عدد الموظفين', value: arNum(emps.length)),
      ReportStat(label: 'النشطون', value: arNum(active), tone: c.taj.success.dark),
      ReportStat(label: 'إجمالي الرواتب الأساسية', value: arDinar(totalBase)),
    ],
    chart: ReportChartData(
      type: ReportChartType.donut,
      title: 'التوزيع حسب الفرع',
      labels: [for (final k in byBranch.keys) _branchName(s, k)],
      series: [ReportSeries(label: 'الموظفون', color: _palette(c).first, values: byBranch.values.toList())],
    ),
  );
}

// ---------------------------------------------------------------------------
// Operations
// ---------------------------------------------------------------------------

ReportResult _partners(BuildContext c, DemoStore s, ReportFilters f) {
  final columns = const [
    ReportColumn('الاسم', sticky: true, minWidth: 180, flex: 2),
    ReportColumn('النوع', minWidth: 90, priority: 0),
    ReportColumn('الهاتف', minWidth: 130, priority: 3),
    ReportColumn('حد الائتمان (د.ل)', numeric: true, minWidth: 150),
    ReportColumn('الرصيد (د.ل)', numeric: true, minWidth: 130),
  ];
  final rows = <ReportRow>[];
  var receivable = 0.0, payable = 0.0;
  var custCount = 0, suppCount = 0;
  final showCust = f.segment == null || f.segment == 'customer';
  final showSupp = f.segment == null || f.segment == 'supplier';
  if (showCust) {
    for (final cust in s.customers) {
      custCount++;
      receivable += cust.balance;
      rows.add(ReportRow(cells: [
        _t(c, cust.name),
        _t(c, 'عميل', color: c.taj.info.dark),
        _t(c, cust.phone, muted: true),
        _n(c, cust.creditLimit),
        _n(c, cust.balance, tone: true),
      ]));
    }
  }
  if (showSupp) {
    for (final sup in s.suppliers) {
      suppCount++;
      payable += sup.balance;
      rows.add(ReportRow(cells: [
        _t(c, sup.name),
        _t(c, 'مورد', color: c.taj.warning.dark),
        _t(c, sup.phone, muted: true),
        _t(c, '—', muted: true),
        _n(c, sup.balance),
      ]));
    }
  }
  final totals = ReportRow(emphasize: true, cells: [
    _t(c, 'الإجمالي', emphasize: true),
    const SizedBox(),
    const SizedBox(),
    const SizedBox(),
    _n(c, receivable + payable, emphasize: true),
  ]);
  return ReportResult(
    columns: columns,
    rows: rows,
    totals: totals,
    summary: [
      ReportStat(label: 'العملاء', value: arNum(custCount)),
      ReportStat(label: 'الموردون', value: arNum(suppCount)),
      ReportStat(label: 'مستحق من العملاء', value: arDinar(receivable), tone: c.taj.info.dark),
      ReportStat(label: 'مستحق للموردين', value: arDinar(payable), tone: c.taj.warning.dark),
    ],
    chart: ReportChartData(
      type: ReportChartType.donut,
      title: 'الذمم',
      labels: const ['مستحق من العملاء', 'مستحق للموردين'],
      series: [
        ReportSeries(label: 'القيمة', color: _palette(c)[1], values: [receivable, payable]),
      ],
    ),
  );
}

ReportResult _expenses(BuildContext c, DemoStore s, ReportFilters f) {
  final now = _now();
  final columns = const [
    ReportColumn('التاريخ', sticky: true, minWidth: 120, flex: 1),
    ReportColumn('التصنيف', minWidth: 130, priority: 0, flex: 1),
    ReportColumn('الفرع', minWidth: 140, priority: 2),
    ReportColumn('طريقة الدفع', minWidth: 120, priority: 1),
    ReportColumn('المبلغ (د.ل)', numeric: true, minWidth: 130),
  ];
  final list = s.expenses.where((e) {
    if (!f.includes(e.date, now) || !_branchOk(e.branchId, f)) return false;
    if (f.segment != null && e.category != f.segment) return false;
    return true;
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final rows = <ReportRow>[];
  var total = 0.0;
  final byCat = <String, double>{};
  for (final e in list) {
    total += e.amount;
    byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
    rows.add(ReportRow(cells: [
      _t(c, _fmtDate(e.date)),
      _t(c, e.category),
      _t(c, _branchName(s, e.branchId), muted: true),
      _t(c, _method(e.method), muted: true),
      _n(c, e.amount),
    ]));
  }
  final totals = ReportRow(emphasize: true, cells: [
    _t(c, 'الإجمالي (${arNum(list.length)})', emphasize: true),
    const SizedBox(),
    const SizedBox(),
    const SizedBox(),
    _n(c, total, emphasize: true),
  ]);
  final topCat = byCat.entries.isEmpty
      ? '—'
      : (byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  return ReportResult(
    columns: columns,
    rows: rows,
    totals: totals,
    summary: [
      ReportStat(label: 'إجمالي المصروفات', value: arDinar(total)),
      ReportStat(label: 'عدد الحركات', value: arNum(list.length)),
      ReportStat(label: 'أعلى تصنيف', value: topCat),
    ],
    chart: byCat.isEmpty
        ? null
        : ReportChartData(
            type: ReportChartType.donut,
            title: 'المصروفات حسب التصنيف',
            labels: byCat.keys.toList(),
            series: [ReportSeries(label: 'المبلغ', color: _palette(c).first, values: byCat.values.toList())],
          ),
  );
}
