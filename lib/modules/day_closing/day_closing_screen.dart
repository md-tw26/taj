import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_provider.dart';
import '../../core/demo/demo_store.dart';
import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_ui.dart';

/// Operating Day & Day Closing (اليوم التشغيلي والإقفال اليومي).
///
/// The operating day stays open until it is closed **manually** from the final
/// step. Closing runs through a seven-step wizard: aggregate sales → expenses →
/// returns → cash variance → stock variance → deficit/surplus → final daily
/// report. The order of these steps, the aggregation and the variance
/// computation are the module's *closing logic* and are deliberately kept in one
/// presentation-independent region ([_compute]) so the responsive layout can
/// change freely around them without ever altering what a close means.
///
/// Responsiveness is keyed off *available* width/height (a [LayoutBuilder]'s
/// constraints), never the device, so it holds for phones, resized desktop
/// windows, split panes and — the common case here — cashier hardware in short
/// landscape (1366×768, 1280×720). The single hardest component, a horizontal
/// [Stepper] with seven labels, is never shrunk to fit: below
/// [AppBreakpoints.stepperHorizontal] the wizard switches to a *vertical* form
/// (one step + "الخطوة X من ٧" progress bar) instead. Step content always
/// scrolls under a pinned Back/Next bar that stays above the keyboard.
class DayClosingScreen extends StatefulWidget {
  const DayClosingScreen({super.key});

  @override
  State<DayClosingScreen> createState() => _DayClosingScreenState();
}

/// The seven wizard steps, in their fixed order. Reordering these would change
/// the closing procedure, so the enum order is the single source of truth.
enum _CloseStep { sales, expenses, returns, cash, stock, deficit, report }

extension _CloseStepMeta on _CloseStep {
  String get title => switch (this) {
        _CloseStep.sales => 'المبيعات',
        _CloseStep.expenses => 'المصروفات',
        _CloseStep.returns => 'المرتجعات',
        _CloseStep.cash => 'فرق الصندوق',
        _CloseStep.stock => 'فرق المخزون',
        _CloseStep.deficit => 'العجز والفائض',
        _CloseStep.report => 'التقرير اليومي',
      };

  IconData get icon => switch (this) {
        _CloseStep.sales => Icons.point_of_sale_rounded,
        _CloseStep.expenses => Icons.payments_rounded,
        _CloseStep.returns => Icons.assignment_return_rounded,
        _CloseStep.cash => Icons.account_balance_wallet_rounded,
        _CloseStep.stock => Icons.inventory_2_rounded,
        _CloseStep.deficit => Icons.balance_rounded,
        _CloseStep.report => Icons.description_rounded,
      };
}

/// Cash denominations counted at close (Libyan dinar), each with its demo
/// default count. Insertion order is descending so the count sheet reads
/// top-to-bottom from the largest note.
const Map<int, int> _kDenoms = {50: 10, 20: 25, 10: 30, 5: 20, 1: 45};

class _DayClosingScreenState extends State<DayClosingScreen> {
  int _step = 0;
  bool _dayClosed = false;
  bool _acknowledgedVariance = false;

  /// When the operating day opened — shown in the banner. Fixed for the session
  /// so it survives rebuilds (and therefore rotations/resizes).
  late final DateTime _openedAt;

  /// Opening cash float placed in the drawer at the start of the day.
  static const double _openingFloat = 500;

  // Entered values live in controllers held by the State, so a rotation or a
  // window resize (which only rebuilds via LayoutBuilder) never loses them.
  final Map<int, TextEditingController> _cashCtl = {};
  final Map<String, TextEditingController> _stockCtl = {};
  bool _controllersReady = false;

  @override
  void initState() {
    super.initState();
    // A stable "opened at" a few hours ago for the demo banner.
    final now = DateTime.now();
    _openedAt = DateTime(now.year, now.month, now.day, 8, 30);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersReady) return;
    // Store is available here (InheritedWidget), unlike in initState.
    for (final e in _kDenoms.entries) {
      _cashCtl[e.key] = TextEditingController(text: '${e.value}');
    }
    final products = _store.products;
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      // Pre-fill counted = system stock, with two deliberate demo discrepancies
      // on the first products so a variance (and its "needs review" path) is
      // visible without any manual entry.
      var counted = p.stock;
      if (i == 0) counted = p.stock - 1;
      if (i == 1) counted = p.stock + 2;
      _stockCtl[p.id] = TextEditingController(text: '$counted');
    }
    _controllersReady = true;
  }

  @override
  void dispose() {
    for (final c in _cashCtl.values) {
      c.dispose();
    }
    for (final c in _stockCtl.values) {
      c.dispose();
    }
    super.dispose();
  }

  DemoStore get _store => DemoStoreProvider.of(context);

  // ===========================================================================
  // Closing logic (aggregation + variance) — presentation-independent.
  // Nothing below this line depends on the screen size; the layout consumes the
  // figures it produces. Do not fold layout concerns into these methods.
  // ===========================================================================

  int _cashCount(int denom) => int.tryParse(_cashCtl[denom]?.text.trim() ?? '') ?? 0;

  int _stockCount(String id, int fallback) {
    final t = _stockCtl[id]?.text.trim() ?? '';
    if (t.isEmpty) return 0;
    return int.tryParse(t) ?? fallback;
  }

  _DayFigures _compute() {
    final store = _store;

    double cashSales = 0, elecSales = 0, creditSales = 0;
    double returnsTotal = 0, cashReturns = 0;
    var orderCount = 0, returnsCount = 0;
    final byMethod = <DemoPaymentMethod, double>{};

    for (final s in store.sales) {
      if (s.status == DemoSaleStatus.cancelled) continue;
      if (s.status == DemoSaleStatus.returned) {
        returnsTotal += s.total;
        returnsCount++;
        if (s.paymentMethod == DemoPaymentMethod.cash) cashReturns += s.total;
        continue;
      }
      orderCount++;
      byMethod[s.paymentMethod] = (byMethod[s.paymentMethod] ?? 0) + s.total;
      if (s.status == DemoSaleStatus.credit) {
        creditSales += s.total;
      } else if (s.paymentMethod == DemoPaymentMethod.cash) {
        cashSales += s.total;
      } else {
        elecSales += s.total;
      }
    }
    final grossSales = cashSales + elecSales + creditSales;

    double expensesTotal = 0, cashExpenses = 0;
    final byCategory = <String, double>{};
    for (final e in store.expenses) {
      expensesTotal += e.amount;
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
      if (e.method == DemoPaymentMethod.cash) cashExpenses += e.amount;
    }

    final expectedCash = _openingFloat + cashSales - cashExpenses - cashReturns;
    final countedCash = _kDenoms.keys
        .fold<double>(0, (sum, d) => sum + d * _cashCount(d));
    final cashVariance = countedCash - expectedCash;

    final stock = <_StockVar>[];
    double stockVarianceValue = 0;
    for (final p in store.products) {
      final counted = _stockCount(p.id, p.stock);
      final v = _StockVar(
        id: p.id,
        name: p.name,
        expected: p.stock,
        counted: counted,
        cost: p.cost,
      );
      stockVarianceValue += v.varianceValue;
      stock.add(v);
    }

    return _DayFigures(
      grossSales: grossSales,
      cashSales: cashSales,
      elecSales: elecSales,
      creditSales: creditSales,
      salesByMethod: byMethod,
      orderCount: orderCount,
      returnsTotal: returnsTotal,
      returnsCount: returnsCount,
      expensesTotal: expensesTotal,
      cashExpenses: cashExpenses,
      expensesByCategory: byCategory,
      openingFloat: _openingFloat,
      expectedCash: expectedCash,
      countedCash: countedCash,
      cashVariance: cashVariance,
      stock: stock,
      stockVarianceValue: stockVarianceValue,
    );
  }

  // ===========================================================================
  // Navigation
  // ===========================================================================

  void _go(int index) {
    FocusScope.of(context).unfocus();
    setState(() => _step = index.clamp(0, _CloseStep.values.length - 1));
  }

  void _next() {
    if (_step < _CloseStep.values.length - 1) _go(_step + 1);
  }

  void _back() {
    if (_step > 0) _go(_step - 1);
  }

  Future<void> _confirmClose(_DayFigures f) async {
    final ok = await _showCloseConfirmDialog(context, f);
    if (ok == true && mounted) {
      setState(() => _dayClosed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إقفال اليوم بنجاح')),
      );
    }
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (_, __) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final f = _compute();
          final showPanel = w >= AppBreakpoints.closingSidePanel &&
              h >= AppBreakpoints.closingSidePanelMinHeight;

          final wizard = _WizardColumn(
            step: _step,
            dayClosed: _dayClosed,
            openedAt: _openedAt,
            figures: f,
            cashControllers: _cashCtl,
            stockControllers: _stockCtl,
            acknowledged: _acknowledgedVariance,
            showTotalsInline: !showPanel,
            onAcknowledge: (v) => setState(() => _acknowledgedVariance = v),
            onSelectStep: _go,
            onNext: _next,
            onBack: _back,
            onClose: () => _confirmClose(f),
            onSaveDraft: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم حفظ المسودة')),
            ),
            onSkip: _next,
            onChanged: () => setState(() {}),
            onPrint: () => _showPrintPreviewDialog(context, f, _openedAt),
          );

          if (showPanel) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.closingContentMax +
                      24 +
                      AppBreakpoints.closingSidePanelWidth,
                ),
                child: SizedBox(
                  height: h,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: wizard),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: AppBreakpoints.closingSidePanelWidth,
                        child: _DayTotalsPanel(figures: f, openedAt: _openedAt),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppBreakpoints.closingContentMax),
              child: SizedBox(height: h, child: wizard),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Figures
// =============================================================================

class _DayFigures {
  const _DayFigures({
    required this.grossSales,
    required this.cashSales,
    required this.elecSales,
    required this.creditSales,
    required this.salesByMethod,
    required this.orderCount,
    required this.returnsTotal,
    required this.returnsCount,
    required this.expensesTotal,
    required this.cashExpenses,
    required this.expensesByCategory,
    required this.openingFloat,
    required this.expectedCash,
    required this.countedCash,
    required this.cashVariance,
    required this.stock,
    required this.stockVarianceValue,
  });

  final double grossSales;
  final double cashSales;
  final double elecSales;
  final double creditSales;
  final Map<DemoPaymentMethod, double> salesByMethod;
  final int orderCount;
  final double returnsTotal;
  final int returnsCount;
  final double expensesTotal;
  final double cashExpenses;
  final Map<String, double> expensesByCategory;
  final double openingFloat;
  final double expectedCash;
  final double countedCash;
  final double cashVariance;
  final List<_StockVar> stock;
  final double stockVarianceValue;

  /// Net of the cash and stock variances — positive is a surplus (فائض),
  /// negative a deficit (عجز).
  double get netDeficitSurplus => cashVariance + stockVarianceValue;

  /// Stock rows whose count differs from the system figure.
  List<_StockVar> get stockDiffs =>
      stock.where((s) => s.varianceQty != 0).toList();

  /// Whether any variance is material enough to require an explicit review
  /// before the day can be closed.
  bool get needsReview =>
      cashVariance.abs() > 1 || stockVarianceValue.abs() > 1;
}

class _StockVar {
  const _StockVar({
    required this.id,
    required this.name,
    required this.expected,
    required this.counted,
    required this.cost,
  });
  final String id;
  final String name;
  final int expected;
  final int counted;
  final double cost;

  int get varianceQty => counted - expected;
  double get varianceValue => varianceQty * cost;
}

// =============================================================================
// Wizard column: banner + stepper + scrollable step + pinned bottom bar
// =============================================================================

class _WizardColumn extends StatelessWidget {
  const _WizardColumn({
    required this.step,
    required this.dayClosed,
    required this.openedAt,
    required this.figures,
    required this.cashControllers,
    required this.stockControllers,
    required this.acknowledged,
    required this.showTotalsInline,
    required this.onAcknowledge,
    required this.onSelectStep,
    required this.onNext,
    required this.onBack,
    required this.onClose,
    required this.onSaveDraft,
    required this.onSkip,
    required this.onChanged,
    required this.onPrint,
  });

  final int step;
  final bool dayClosed;
  final DateTime openedAt;
  final _DayFigures figures;
  final Map<int, TextEditingController> cashControllers;
  final Map<String, TextEditingController> stockControllers;
  final bool acknowledged;
  final bool showTotalsInline;
  final ValueChanged<bool> onAcknowledge;
  final ValueChanged<int> onSelectStep;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final VoidCallback onSaveDraft;
  final VoidCallback onSkip;
  final VoidCallback onChanged;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final short = h < AppBreakpoints.closingCondenseHeight;
        final pad = pagePaddingForWidth(w);
        final current = _CloseStep.values[step];
        final isReport = current == _CloseStep.report;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
              child: _OpenDayBanner(
                openedAt: openedAt,
                closed: dayClosed,
                condensed: short,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, short ? 8 : 14, pad, short ? 8 : 12),
              child: _StepperHeader(
                width: w,
                step: step,
                condensed: short,
                onSelect: onSelectStep,
              ),
            ),
            Divider(height: 1, color: context.taj.divider),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('day-closing-scroll'),
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 20),
                child: _StepBody(
                  step: current,
                  width: w - pad * 2,
                  figures: figures,
                  dayClosed: dayClosed,
                  acknowledged: acknowledged,
                  showTotalsInline: showTotalsInline,
                  cashControllers: cashControllers,
                  stockControllers: stockControllers,
                  onAcknowledge: onAcknowledge,
                  onChanged: onChanged,
                  onPrint: onPrint,
                ),
              ),
            ),
            _BottomBar(
              width: w,
              isReport: isReport,
              isFirst: step == 0,
              dayClosed: dayClosed,
              canClose: !figures.needsReview || acknowledged,
              onBack: onBack,
              onNext: onNext,
              onClose: onClose,
              onSaveDraft: onSaveDraft,
              onSkip: onSkip,
              onPrint: onPrint,
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Open-day banner
// =============================================================================

class _OpenDayBanner extends StatelessWidget {
  const _OpenDayBanner({
    required this.openedAt,
    required this.closed,
    required this.condensed,
  });
  final DateTime openedAt;
  final bool closed;
  final bool condensed;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final swatch = closed ? taj.success : taj.info;
    final accent = taj.accentFor(swatch);
    final when = _fmtDateTime(openedAt);

    // Wrap (not Row) so a long label + date + badge reflow onto a second line on
    // narrow widths instead of overflowing. The banner stays a slim strip so it
    // never eats more than ~15% of a short screen.
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 14, vertical: condensed ? 8 : 12),
      decoration: BoxDecoration(
        color: swatch.lighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: swatch.light.withValues(alpha: 0.5)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 6,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(closed ? Icons.check_circle_rounded : Icons.today_rounded,
                  size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                closed ? 'تم إقفال اليوم' : 'اليوم التشغيلي مفتوح',
                style: text.titleSmall?.copyWith(color: accent),
              ),
            ],
          ),
          Text(
            closed ? 'أُقفل بعد المراجعة' : 'مفتوح منذ $when',
            style: text.bodySmall?.copyWith(color: taj.textSecondary),
          ),
          if (!condensed)
            StatusBadge(
              label: closed ? 'مقفل' : 'نشط',
              status: closed ? TajStatus.success : TajStatus.info,
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Stepper header — the key responsive component
// =============================================================================

class _StepperHeader extends StatelessWidget {
  const _StepperHeader({
    required this.width,
    required this.step,
    required this.condensed,
    required this.onSelect,
  });

  final double width;
  final int step;
  final bool condensed;
  final ValueChanged<int> onSelect;

  static const _count = 7;

  @override
  Widget build(BuildContext context) {
    // Below stepperHorizontal a seven-label horizontal stepper cannot fit
    // without shrinking the font below the floor, so switch to a vertical form:
    // one step + a "الخطوة X من ٧" label and a progress bar.
    if (width < AppBreakpoints.stepperHorizontal) {
      return _vertical(context);
    }
    final showAllTitles = width >= AppBreakpoints.stepperFullLabels;
    return _horizontal(context, showAllTitles: showAllTitles);
  }

  Widget _vertical(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final current = _CloseStep.values[step];
    return Column(
      key: const Key('stepper-vertical'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: taj.primary.lighter,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(current.icon, size: 19, color: taj.primary.dark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                current.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'الخطوة ${step + 1} من $_count',
              style: text.bodySmall?.copyWith(color: taj.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (step + 1) / _count,
            minHeight: 6,
            backgroundColor: taj.divider,
            valueColor: AlwaysStoppedAnimation(taj.primary.main),
          ),
        ),
      ],
    );
  }

  Widget _horizontal(BuildContext context, {required bool showAllTitles}) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    final nodes = <Widget>[];
    for (var i = 0; i < _count; i++) {
      if (i > 0) {
        final done = i <= step;
        nodes.add(Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 2),
            color: done ? taj.primary.main : taj.divider,
          ),
        ));
      }
      nodes.add(_StepNode(
        index: i,
        step: step,
        title: showAllTitles ? _CloseStep.values[i].title : null,
        onTap: () => onSelect(i),
      ));
    }

    return Column(
      key: const Key('stepper-horizontal'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: nodes),
        // Condensed band (700–1024): only the current step's title, centred,
        // rather than seven crammed labels.
        if (!showAllTitles) ...[
          const SizedBox(height: 8),
          Text(
            'الخطوة ${step + 1} من $_count · ${_CloseStep.values[step].title}',
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(color: taj.primary.dark),
          ),
        ],
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.step,
    required this.title,
    required this.onTap,
  });
  final int index;
  final int step;
  final String? title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final done = index < step;
    final current = index == step;
    final circleColor = done || current ? taj.primary.main : taj.paper;
    final borderColor = done || current ? taj.primary.main : taj.divider;
    final fg = done || current ? taj.primary.contrastText : taj.textSecondary;

    final circle = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: done
          ? Icon(Icons.check_rounded, size: 17, color: fg)
          : Text(
              '${index + 1}',
              style: AppThemes.numeralStyle(context,
                  fontSize: 13, fontWeight: FontWeight.w700, color: fg),
            ),
    );

    final node = title == null
        ? circle
        : SizedBox(
            width: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                circle,
                const SizedBox(height: 6),
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: current ? taj.primary.dark : taj.textSecondary,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: node,
      ),
    );
  }
}

// =============================================================================
// Bottom navigation bar (pinned, keyboard-aware, SafeArea)
// =============================================================================

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.width,
    required this.isReport,
    required this.isFirst,
    required this.dayClosed,
    required this.canClose,
    required this.onBack,
    required this.onNext,
    required this.onClose,
    required this.onSaveDraft,
    required this.onSkip,
    required this.onPrint,
  });

  final double width;
  final bool isReport;
  final bool isFirst;
  final bool dayClosed;
  final bool canClose;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onClose;
  final VoidCallback onSaveDraft;
  final VoidCallback onSkip;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forwardIcon =
        rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded;
    final backIcon =
        rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;
    final narrow = width < AppBreakpoints.phone;
    final pad = pagePaddingForWidth(width);

    final back = OutlinedButton.icon(
      onPressed: isFirst ? null : onBack,
      icon: Icon(backIcon, size: 18),
      label: const Text('رجوع'),
    );

    // The primary action. On the report step it becomes "إغلاق اليوم" (Close
    // day) — which is never hidden in an overflow menu — or, once closed, a
    // Print button.
    final Widget primary;
    if (isReport) {
      if (dayClosed) {
        primary = FilledButton.icon(
          key: const Key('print-button'),
          onPressed: onPrint,
          icon: const Icon(Icons.print_rounded, size: 18),
          label: const Text('طباعة'),
        );
      } else {
        primary = FilledButton.icon(
          key: const Key('close-day-button'),
          onPressed: canClose ? onClose : null,
          icon: const Icon(Icons.lock_rounded, size: 18),
          label: const Text('إغلاق اليوم'),
        );
      }
    } else {
      primary = FilledButton.icon(
        key: const Key('next-button'),
        onPressed: onNext,
        icon: Icon(forwardIcon, size: 18),
        label: const Text('التالي'),
      );
    }

    // Secondary actions: draft + skip. On phones they collapse into an overflow
    // menu so the primary (incl. "Close day") always stays visible; wider bars
    // show them inline.
    final overflow = PopupMenuButton<String>(
      tooltip: 'إجراءات',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (v) {
        if (v == 'draft') onSaveDraft();
        if (v == 'skip') onSkip();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'draft', child: Text('حفظ مسودة')),
        if (!isReport) const PopupMenuItem(value: 'skip', child: Text('تخطي الخطوة')),
      ],
    );

    final Widget row;
    if (narrow) {
      row = Row(
        children: [
          Expanded(child: back),
          const SizedBox(width: 8),
          if (!dayClosed) overflow,
          const SizedBox(width: 8),
          Expanded(child: primary),
        ],
      );
    } else {
      row = Row(
        children: [
          back,
          const Spacer(),
          if (!dayClosed) ...[
            TextButton(onPressed: onSaveDraft, child: const Text('حفظ مسودة')),
            if (!isReport)
              TextButton(onPressed: onSkip, child: const Text('تخطي')),
            const SizedBox(width: 8),
          ],
          primary,
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: taj.background,
        border: Border(top: BorderSide(color: taj.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 10, pad, 10),
          child: row,
        ),
      ),
    );
  }
}

// =============================================================================
// Step body
// =============================================================================

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.step,
    required this.width,
    required this.figures,
    required this.dayClosed,
    required this.acknowledged,
    required this.showTotalsInline,
    required this.cashControllers,
    required this.stockControllers,
    required this.onAcknowledge,
    required this.onChanged,
    required this.onPrint,
  });

  final _CloseStep step;
  final double width;
  final _DayFigures figures;
  final bool dayClosed;
  final bool acknowledged;
  final bool showTotalsInline;
  final Map<int, TextEditingController> cashControllers;
  final Map<String, TextEditingController> stockControllers;
  final ValueChanged<bool> onAcknowledge;
  final VoidCallback onChanged;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTotalsInline && step != _CloseStep.report) ...[
          _InlineTotalsStrip(figures: figures, width: width),
          const SizedBox(height: 16),
        ],
        ...switch (step) {
          _CloseStep.sales => _salesStep(context),
          _CloseStep.expenses => _expensesStep(context),
          _CloseStep.returns => _returnsStep(context),
          _CloseStep.cash => _cashStep(context),
          _CloseStep.stock => _stockStep(context),
          _CloseStep.deficit => _deficitStep(context),
          _CloseStep.report => _reportStep(context),
        },
      ],
    );
  }

  int _summaryCols(double w) {
    if (w < AppBreakpoints.stepperHorizontal) return 1; // < 700
    if (w < AppBreakpoints.tablet) return 2; // 700–1024
    if (w < AppBreakpoints.laptop) return 3; // 1024–1440
    return 4; // ≥ 1440
  }

  // ---- Steps ----

  List<Widget> _salesStep(BuildContext context) {
    final f = figures;
    return [
      _StepIntro(
        step: _CloseStep.sales,
        subtitle: 'إجمالي مبيعات اليوم موزّعة حسب طريقة الدفع.',
      ),
      const SizedBox(height: 16),
      _StatCardGrid(
        width: width,
        cols: _summaryCols(width),
        cards: [
          _Stat('إجمالي المبيعات', arDinar(f.grossSales),
              icon: Icons.point_of_sale_rounded),
          _Stat('عدد الفواتير', arNum(f.orderCount),
              icon: Icons.receipt_long_rounded),
          _Stat('مبيعات نقدية', arDinar(f.cashSales),
              icon: Icons.payments_rounded),
          _Stat('مبيعات آجلة', arDinar(f.creditSales),
              icon: Icons.schedule_rounded),
        ],
      ),
      const SizedBox(height: 16),
      _MiniBreakdown(
        title: 'حسب طريقة الدفع',
        rows: [
          for (final e in f.salesByMethod.entries)
            (_methodLabel(e.key), arDinar(e.value)),
        ],
      ),
    ];
  }

  List<Widget> _expensesStep(BuildContext context) {
    final f = figures;
    return [
      _StepIntro(
        step: _CloseStep.expenses,
        subtitle: 'مصروفات اليوم — النقدية منها تؤثر على رصيد الصندوق.',
      ),
      const SizedBox(height: 16),
      _StatCardGrid(
        width: width,
        cols: _summaryCols(width),
        cards: [
          _Stat('إجمالي المصروفات', arDinar(f.expensesTotal),
              icon: Icons.payments_rounded),
          _Stat('مصروفات نقدية', arDinar(f.cashExpenses),
              icon: Icons.account_balance_wallet_rounded),
          _Stat('عدد البنود', arNum(f.expensesByCategory.length),
              icon: Icons.list_alt_rounded),
        ],
      ),
      const SizedBox(height: 16),
      _MiniBreakdown(
        title: 'حسب البند',
        rows: [
          for (final e in f.expensesByCategory.entries)
            (e.key, arDinar(e.value)),
        ],
      ),
    ];
  }

  List<Widget> _returnsStep(BuildContext context) {
    final f = figures;
    return [
      _StepIntro(
        step: _CloseStep.returns,
        subtitle: 'المرتجعات تُخصم من صافي المبيعات ومن الصندوق إن كانت نقدية.',
      ),
      const SizedBox(height: 16),
      _StatCardGrid(
        width: width,
        cols: _summaryCols(width),
        cards: [
          _Stat('إجمالي المرتجعات', arDinar(f.returnsTotal),
              icon: Icons.assignment_return_rounded,
              valueStatus: f.returnsTotal > 0 ? TajStatus.warning : null),
          _Stat('عدد المرتجعات', arNum(f.returnsCount),
              icon: Icons.replay_rounded),
          _Stat('صافي المبيعات', arDinar(f.grossSales - f.returnsTotal),
              icon: Icons.trending_up_rounded),
        ],
      ),
    ];
  }

  List<Widget> _cashStep(BuildContext context) {
    return [
      _StepIntro(
        step: _CloseStep.cash,
        subtitle: 'عُدّ النقد الفعلي في الصندوق وقارنه بالمتوقّع.',
      ),
      const SizedBox(height: 16),
      _CashCountCard(
        controllers: cashControllers,
        figures: figures,
        width: width,
        cols: _summaryCols(width),
        onChanged: onChanged,
      ),
    ];
  }

  List<Widget> _stockStep(BuildContext context) {
    return [
      _StepIntro(
        step: _CloseStep.stock,
        subtitle: 'أدخل الكمية المجرودة لكل صنف؛ يُحسب الفرق تلقائيًا.',
      ),
      const SizedBox(height: 12),
      _StockVarianceView(
        rows: figures.stock,
        width: width,
        controllers: stockControllers,
        onChanged: onChanged,
      ),
      const SizedBox(height: 12),
      _TotalVarianceStrip(
        label: 'قيمة فرق المخزون',
        value: figures.stockVarianceValue,
      ),
    ];
  }

  List<Widget> _deficitStep(BuildContext context) {
    final f = figures;
    return [
      _StepIntro(
        step: _CloseStep.deficit,
        subtitle: 'صافي العجز أو الفائض بعد فروق الصندوق والمخزون.',
      ),
      const SizedBox(height: 16),
      _StatCardGrid(
        width: width,
        cols: _summaryCols(width),
        cards: [
          _Stat.variance('فرق الصندوق', f.cashVariance),
          _Stat.variance('قيمة فرق المخزون', f.stockVarianceValue),
          _Stat.variance('الصافي (عجز/فائض)', f.netDeficitSurplus,
              emphasize: true),
        ],
      ),
      if (f.needsReview) ...[
        const SizedBox(height: 16),
        const _ReviewWarning(),
      ],
    ];
  }

  List<Widget> _reportStep(BuildContext context) {
    final f = figures;
    return [
      _StepIntro(
        step: _CloseStep.report,
        subtitle: dayClosed
            ? 'تم إقفال اليوم — يمكنك طباعة التقرير.'
            : 'راجِع ملخّص اليوم ثم أقفِل اليوم.',
      ),
      const SizedBox(height: 16),
      _DailyReportCard(figures: f, onPrint: onPrint),
      if (!dayClosed && f.needsReview) ...[
        const SizedBox(height: 16),
        const _ReviewWarning(),
        const SizedBox(height: 8),
        _AcknowledgeTile(value: acknowledged, onChanged: onAcknowledge),
      ],
      if (dayClosed) ...[
        const SizedBox(height: 16),
        _ClosedBanner(),
      ],
    ];
  }
}

// =============================================================================
// Shared step pieces
// =============================================================================

class _StepIntro extends StatelessWidget {
  const _StepIntro({required this.step, required this.subtitle});
  final _CloseStep step;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: taj.primary.lighter,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(step.icon, size: 21, color: taj.primary.dark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: text.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: text.bodySmall?.copyWith(color: taj.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Adaptive stat-card grid. Column count is supplied by the caller (explicit
/// per-band counts), and each card takes an equal share of the width via a
/// [Wrap] so a short row never overflows.
class _StatCardGrid extends StatelessWidget {
  const _StatCardGrid({
    required this.width,
    required this.cols,
    required this.cards,
  });
  final double width;
  final int cols;
  final List<_Stat> cards;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    final columns = math.max(1, cols);
    final itemW = columns == 1
        ? width
        : (width - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final c in cards)
          SizedBox(width: itemW.clamp(0, width), child: _StatCardView(stat: c)),
      ],
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value,
      {this.icon, this.valueStatus, this.caption});

  /// A variance stat: the value is formatted with a sign + colour + icon so it
  /// never relies on colour alone, and long negative figures stay tabular.
  factory _Stat.variance(String label, double v, {bool emphasize = false}) {
    final status = v < -0.005
        ? TajStatus.error
        : v > 0.005
            ? TajStatus.success
            : null;
    final sign = v > 0.005 ? '+' : '';
    return _Stat(
      label,
      '$sign${arDinar(v)}',
      icon: v < -0.005
          ? Icons.south_east_rounded
          : v > 0.005
              ? Icons.north_east_rounded
              : Icons.remove_rounded,
      valueStatus: status,
      caption: emphasize
          ? (v < -0.005 ? 'عجز' : v > 0.005 ? 'فائض' : 'مطابق')
          : null,
    );
  }

  final String label;
  final String value;
  final IconData? icon;
  final TajStatus? valueStatus;
  final String? caption;
}

class _StatCardView extends StatelessWidget {
  const _StatCardView({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final valueColor =
        stat.valueStatus == null ? taj.textPrimary : taj.accentFor(taj.swatch(stat.valueStatus!));

    return TajCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (stat.icon != null) ...[
                Icon(stat.icon, size: 16, color: taj.textSecondary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(stat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        text.bodySmall?.copyWith(color: taj.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.numeralStyle(context,
                fontSize: 20, fontWeight: FontWeight.w800, color: valueColor),
          ),
          if (stat.caption != null) ...[
            const SizedBox(height: 4),
            Text(stat.caption!,
                style: text.labelSmall?.copyWith(color: valueColor)),
          ],
        ],
      ),
    );
  }
}

/// A small label→value list inside a card (payment methods, expense categories).
class _MiniBreakdown extends StatelessWidget {
  const _MiniBreakdown({required this.title, required this.rows});
  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    if (rows.isEmpty) {
      return TajCard(
        child: Text('لا بيانات',
            style: text.bodyMedium?.copyWith(color: taj.textSecondary)),
      );
    }
    return TajCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(title, style: text.titleSmall),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: taj.divider),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                      child: Text(rows[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium)),
                  const SizedBox(width: 12),
                  Text(rows[i].$2,
                      style: AppThemes.numeralStyle(context,
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A compact totals strip shown at the top of each step when there is no
/// persistent side panel (i.e. below [AppBreakpoints.closingSidePanel]).
class _InlineTotalsStrip extends StatelessWidget {
  const _InlineTotalsStrip({required this.figures, required this.width});
  final _DayFigures figures;
  final double width;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final items = <(String, String)>[
      ('صافي المبيعات', arDinarFit(figures.grossSales - figures.returnsTotal)),
      ('المصروفات', arDinarFit(figures.expensesTotal)),
      ('عجز/فائض', arDinarFit(figures.netDeficitSurplus)),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taj.divider),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          for (final it in items) _MiniTotal(label: it.$1, value: it.$2),
        ],
      ),
    );
  }
}

class _MiniTotal extends StatelessWidget {
  const _MiniTotal({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelSmall?.copyWith(color: taj.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: AppThemes.numeralStyle(context,
                fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// =============================================================================
// Cash count
// =============================================================================

class _CashCountCard extends StatelessWidget {
  const _CashCountCard({
    required this.controllers,
    required this.figures,
    required this.width,
    required this.cols,
    required this.onChanged,
  });
  final Map<int, TextEditingController> controllers;
  final _DayFigures figures;
  final double width;
  final int cols;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TajCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('الفئة',
                            style: text.bodySmall
                                ?.copyWith(color: taj.textSecondary))),
                    SizedBox(
                        width: 96,
                        child: Text('العدد',
                            textAlign: TextAlign.center,
                            style: text.bodySmall
                                ?.copyWith(color: taj.textSecondary))),
                    SizedBox(
                        width: 110,
                        child: Text('الإجمالي',
                            textAlign: TextAlign.end,
                            style: text.bodySmall
                                ?.copyWith(color: taj.textSecondary))),
                  ],
                ),
              ),
              for (final d in _kDenoms.keys) ...[
                Divider(height: 1, color: taj.divider),
                _DenomRow(
                  denom: d,
                  controller: controllers[d]!,
                  onChanged: onChanged,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StatCardGrid(
          width: width,
          cols: cols,
          cards: [
            _Stat('النقد المتوقّع', arDinar(figures.expectedCash),
                icon: Icons.calculate_rounded),
            _Stat('النقد المعدود', arDinar(figures.countedCash),
                icon: Icons.account_balance_wallet_rounded),
            _Stat.variance('الفرق', figures.cashVariance),
          ],
        ),
      ],
    );
  }
}

class _DenomRow extends StatelessWidget {
  const _DenomRow({
    required this.denom,
    required this.controller,
    required this.onChanged,
  });
  final int denom;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final count = int.tryParse(controller.text.trim()) ?? 0;
    final lineTotal = (count * denom).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text('${arNum(denom)} د.ل',
                style: AppThemes.numeralStyle(context,
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 96,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(arDinar(lineTotal),
                textAlign: TextAlign.end,
                style: AppThemes.numeralStyle(context,
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Stock variance — cards (<700) or frozen-column table (≥700)
// =============================================================================

class _StockVarianceView extends StatelessWidget {
  const _StockVarianceView({
    required this.rows,
    required this.width,
    required this.controllers,
    required this.onChanged,
  });
  final List<_StockVar> rows;
  final double width;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const TajCard(child: Text('لا أصناف'));
    }
    if (width < AppBreakpoints.varianceCards) {
      return Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StockVarCard(
                row: r,
                controller: controllers[r.id]!,
                onChanged: onChanged,
              ),
            ),
        ],
      );
    }
    return _FrozenStockTable(
      rows: rows,
      width: width,
      controllers: controllers,
      onChanged: onChanged,
    );
  }
}

class _StockVarCard extends StatelessWidget {
  const _StockVarCard({
    required this.row,
    required this.controller,
    required this.onChanged,
  });
  final _StockVar row;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return TajCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(row.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              _kv(context, 'المتوقّع', arNum(row.expected)),
              const SizedBox(width: 12),
              SizedBox(
                width: 88,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الفعلي',
                        style: text.labelSmall
                            ?.copyWith(color: taj.textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      onChanged: (_) => onChanged(),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _VarianceChip(qty: row.varianceQty, value: row.varianceValue),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: text.labelSmall?.copyWith(color: taj.textSecondary)),
        const SizedBox(height: 4),
        Text(v,
            style: AppThemes.numeralStyle(context,
                fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// A table with a **frozen first column** (item name) and a horizontally
/// scrollable numeric block (expected · actual · variance). The header is
/// sticky (kept above the vertical scroll) and the body is height-capped so a
/// long stock list scrolls internally rather than pushing the pinned Back/Next
/// bar off-screen. The body's horizontal scroll drives the header's (one-way
/// sync), so the frozen column never moves sideways and the header never moves
/// vertically.
class _FrozenStockTable extends StatefulWidget {
  const _FrozenStockTable({
    required this.rows,
    required this.width,
    required this.controllers,
    required this.onChanged,
  });
  final List<_StockVar> rows;
  final double width;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onChanged;

  @override
  State<_FrozenStockTable> createState() => _FrozenStockTableState();
}

class _FrozenStockTableState extends State<_FrozenStockTable> {
  final ScrollController _hHead = ScrollController();
  final ScrollController _hBody = ScrollController();
  static const double _rowH = 56;
  static const double _headH = 42;

  @override
  void initState() {
    super.initState();
    _hBody.addListener(_sync);
  }

  void _sync() {
    if (_hHead.hasClients && _hBody.hasClients) {
      final max = _hHead.position.maxScrollExtent;
      final target = _hBody.offset.clamp(0.0, max);
      if ((_hHead.offset - target).abs() > 0.5) _hHead.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _hHead.dispose();
    _hBody.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final nameW = (widget.width * 0.34).clamp(120.0, 220.0);
    final numericAvail = widget.width - nameW;
    final numericW = math.max(AppBreakpoints.varianceNumericMin, numericAvail);
    final bodyH = math.min(
      AppBreakpoints.varianceTableMaxHeight,
      widget.rows.length * _rowH + 2,
    );

    return Container(
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: taj.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sticky header.
          SizedBox(
            height: _headH,
            child: Row(
              children: [
                SizedBox(
                  width: nameW,
                  child: _headCell('الصنف', start: true),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _hHead,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: numericW,
                      child: Row(
                        children: [
                          Expanded(child: _headCell('المتوقّع')),
                          Expanded(child: _headCell('الفعلي')),
                          Expanded(child: _headCell('الفرق')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: taj.divider),
          // Height-capped body with internal vertical scroll.
          SizedBox(
            height: bodyH,
            child: SingleChildScrollView(
              key: const Key('variance-table-body'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Frozen name column.
                  SizedBox(
                    width: nameW,
                    child: Column(
                      children: [
                        for (final r in widget.rows)
                          Container(
                            height: _rowH,
                            alignment: AlignmentDirectional.centerStart,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: taj.divider)),
                            ),
                            child: Text(r.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                      ],
                    ),
                  ),
                  // Scrollable numeric block.
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _hBody,
                      child: SizedBox(
                        width: numericW,
                        child: Column(
                          children: [
                            for (final r in widget.rows)
                              SizedBox(
                                height: _rowH,
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: _numCell(context,
                                            arNum(r.expected))),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6),
                                        child: TextField(
                                          controller:
                                              widget.controllers[r.id]!,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
                                          onChanged: (_) =>
                                              widget.onChanged(),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional.centerEnd,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          child: _VarianceText(
                                              value: r.varianceValue),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headCell(String label, {bool start = false}) {
    final taj = context.taj;
    return Container(
      alignment: start
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: taj.textSecondary, fontWeight: FontWeight.w600)),
    );
  }

  Widget _numCell(BuildContext context, String v) => Center(
        child: Text(v,
            style: AppThemes.numeralStyle(context,
                fontSize: 14, fontWeight: FontWeight.w600)),
      );
}

// =============================================================================
// Variance display primitives (sign + colour + icon — never colour alone)
// =============================================================================

class _VarianceText extends StatelessWidget {
  const _VarianceText({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final (status, icon, sign) = _varianceStyle(value);
    final color =
        status == null ? taj.textSecondary : taj.accentFor(taj.swatch(status));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '$sign${arDinar(value)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.numeralStyle(context,
                fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}

class _VarianceChip extends StatelessWidget {
  const _VarianceChip({required this.qty, required this.value});
  final int qty;
  final double value;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final (status, icon, sign) = _varianceStyle(value);
    final swatch = status == null ? taj.neutral : taj.swatch(status);
    final color = status == null ? taj.textSecondary : taj.accentFor(swatch);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: swatch.lighter,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$sign${arNum(qty)} · $sign${arDinar(value)}',
            style: AppThemes.numeralStyle(context,
                fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _TotalVarianceStrip extends StatelessWidget {
  const _TotalVarianceStrip({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taj.divider),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.titleSmall)),
          const SizedBox(width: 12),
          _VarianceText(value: value),
        ],
      ),
    );
  }
}

(TajStatus?, IconData, String) _varianceStyle(double v) {
  if (v < -0.005) return (TajStatus.error, Icons.south_east_rounded, '');
  if (v > 0.005) return (TajStatus.success, Icons.north_east_rounded, '+');
  return (null, Icons.remove_rounded, '');
}

// =============================================================================
// Review warning + acknowledge + closed banners
// =============================================================================

class _ReviewWarning extends StatelessWidget {
  const _ReviewWarning();
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final accent = taj.accentFor(taj.warning);
    return Container(
      key: const Key('review-warning'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: taj.warning.lighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taj.warning.light.withValues(alpha: 0.6)),
      ),
      // Wrap so a long warning never pushes the buttons off-screen.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'توجد فروقات تحتاج إلى مراجعة قبل الإقفال. تحقّق من فرق الصندوق '
              'وفروق المخزون، ثم أكّد المراجعة لتفعيل زر الإقفال.',
              style: text.bodySmall?.copyWith(color: accent, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcknowledgeTile extends StatelessWidget {
  const _AcknowledgeTile({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
            ),
            Expanded(
              child: Text('راجعتُ الفروقات وأوافق على الإقفال',
                  style: text.bodyMedium?.copyWith(color: taj.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final accent = taj.accentFor(taj.success);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: taj.success.lighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text('تم إقفال اليوم بنجاح. لا يمكن تعديل عمليات اليوم بعد الإقفال.',
                style: text.bodyMedium?.copyWith(color: accent, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Daily report card + side totals panel
// =============================================================================

class _DailyReportCard extends StatelessWidget {
  const _DailyReportCard({required this.figures, required this.onPrint});
  final _DayFigures figures;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final f = figures;
    final lines = _reportLines(f);
    return TajCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('التقرير اليومي', style: text.titleMedium)),
              OutlinedButton.icon(
                onPressed: onPrint,
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('طباعة'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final l in lines) _ReportLine(line: l),
          Divider(height: 20, color: taj.divider),
          _ReportLine(
            line: _RLine('الصافي (عجز/فائض)', f.netDeficitSurplus,
                variance: true, bold: true),
          ),
        ],
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.line});
  final _RLine line;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(line.label,
                style: line.bold ? text.titleSmall : text.bodyMedium),
          ),
          const SizedBox(width: 12),
          if (line.variance)
            _VarianceText(value: line.value)
          else
            Text(arDinar(line.value),
                style: AppThemes.numeralStyle(context,
                    fontSize: line.bold ? 16 : 14,
                    fontWeight: line.bold ? FontWeight.w800 : FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RLine {
  const _RLine(this.label, this.value,
      {this.variance = false, this.bold = false});
  final String label;
  final double value;
  final bool variance;
  final bool bold;
}

List<_RLine> _reportLines(_DayFigures f) => [
      _RLine('إجمالي المبيعات', f.grossSales),
      _RLine('المرتجعات', -f.returnsTotal),
      _RLine('المصروفات', -f.expensesTotal),
      _RLine('فرق الصندوق', f.cashVariance, variance: true),
      _RLine('قيمة فرق المخزون', f.stockVarianceValue, variance: true),
    ];

class _DayTotalsPanel extends StatelessWidget {
  const _DayTotalsPanel({required this.figures, required this.openedAt});
  final _DayFigures figures;
  final DateTime openedAt;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final f = figures;
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: taj.divider)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(4, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إجماليات اليوم', style: text.titleMedium),
            const SizedBox(height: 4),
            Text('مفتوح منذ ${_fmtDateTime(openedAt)}',
                style: text.bodySmall?.copyWith(color: taj.textSecondary)),
            const SizedBox(height: 16),
            _panelRow(context, 'إجمالي المبيعات', arDinar(f.grossSales)),
            _panelRow(context, 'المرتجعات', arDinar(f.returnsTotal)),
            _panelRow(context, 'المصروفات', arDinar(f.expensesTotal)),
            _panelRow(context, 'النقد المتوقّع', arDinar(f.expectedCash)),
            _panelRow(context, 'النقد المعدود', arDinar(f.countedCash)),
            Divider(height: 24, color: taj.divider),
            _panelVarRow(context, 'فرق الصندوق', f.cashVariance),
            _panelVarRow(context, 'فرق المخزون', f.stockVarianceValue),
            const SizedBox(height: 6),
            _panelVarRow(context, 'الصافي', f.netDeficitSurplus, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _panelRow(BuildContext context, String k, String v) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
              child: Text(k,
                  style:
                      text.bodyMedium?.copyWith(color: taj.textSecondary))),
          const SizedBox(width: 8),
          Text(v,
              style: AppThemes.numeralStyle(context,
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _panelVarRow(BuildContext context, String k, double v,
      {bool bold = false}) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
              child: Text(k,
                  style: bold ? text.titleSmall : text.bodyMedium)),
          const SizedBox(width: 8),
          _VarianceText(value: v),
        ],
      ),
    );
  }
}

// =============================================================================
// Dialogs: close confirmation + print preview
// =============================================================================

Future<bool?> _showCloseConfirmDialog(BuildContext context, _DayFigures f) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      final w = size.width;
      final phone = w < AppBreakpoints.phone;
      final dialogW = phone
          ? w
          : math.min(AppBreakpoints.closingDialogMax, w - 48);
      final taj = ctx.taj;
      final text = Theme.of(ctx).textTheme;
      return Dialog(
        insetPadding:
            EdgeInsets.symmetric(horizontal: phone ? 12 : 24, vertical: 24),
        backgroundColor: taj.paper,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogW,
            maxHeight: size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('تأكيد إقفال اليوم',
                            style: text.titleLarge)),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: taj.divider),
              // Long summary in an internal scroll.
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20, 16, 20, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'بعد الإقفال لا يمكن تعديل عمليات اليوم. راجِع الملخّص:',
                        style: text.bodyMedium
                            ?.copyWith(color: taj.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      for (final l in _reportLines(f)) _ReportLine(line: l),
                      Divider(height: 20, color: taj.divider),
                      _ReportLine(
                        line: _RLine('الصافي (عجز/فائض)', f.netDeficitSurplus,
                            variance: true, bold: true),
                      ),
                      if (f.needsReview) ...[
                        const SizedBox(height: 12),
                        const _ReviewWarning(),
                      ],
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: taj.divider),
              // Confirm button always visible, outside the scroll area.
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        key: const Key('confirm-close-button'),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        icon: const Icon(Icons.lock_rounded, size: 18),
                        label: const Text('تأكيد الإقفال'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showPrintPreviewDialog(
    BuildContext context, _DayFigures f, DateTime openedAt) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      final w = size.width;
      final phone = w < AppBreakpoints.phone;
      final dialogW = phone ? w : math.min(560.0, w - 48);
      final taj = ctx.taj;
      final text = Theme.of(ctx).textTheme;
      return Dialog(
        insetPadding:
            EdgeInsets.symmetric(horizontal: phone ? 12 : 24, vertical: 24),
        backgroundColor: taj.paper,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogW,
            maxHeight: size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('معاينة الطباعة', style: text.titleLarge)),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: taj.divider),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  // The printed output is a fixed-width thermal receipt; it does
                  // not reflow with the screen. On a narrow screen it scrolls
                  // horizontally rather than shrinking.
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Center(
                      child: _ReceiptPreview(figures: f, openedAt: openedAt),
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: taj.divider),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('إغلاق'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('أُرسل التقرير إلى الطابعة')),
                          );
                        },
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('طباعة'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// A fixed-width thermal-receipt rendering of the daily report. Its width is
/// pinned to [AppBreakpoints.closingReportPrintWidth] so it always represents
/// the physical print output regardless of screen size.
class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.figures, required this.openedAt});
  final _DayFigures figures;
  final DateTime openedAt;

  @override
  Widget build(BuildContext context) {
    final f = figures;
    // Force a light, paper-like surface with dark text — a print always looks
    // the same regardless of the app's light/dark theme.
    const paper = Color(0xFFFFFFFF);
    const ink = Color(0xFF161C24);
    TextStyle mono(double s, [FontWeight w = FontWeight.w400]) =>
        AppThemes.numeralStyle(context,
            fontSize: s, fontWeight: w, color: ink);

    Widget line(String k, double v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(k, style: mono(12))),
              Text(arDinar(v), style: mono(12, FontWeight.w700)),
            ],
          ),
        );

    return Container(
      width: AppBreakpoints.closingReportPrintWidth,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDFE3E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Text('شركة تاج', style: mono(16, FontWeight.w800))),
          const SizedBox(height: 2),
          Center(child: Text('التقرير اليومي', style: mono(12))),
          const SizedBox(height: 2),
          Center(
              child: Text('يوم ${_fmtDate(openedAt)}',
                  style: mono(11).copyWith(color: const Color(0xFF637381)))),
          const _DashedLine(),
          line('إجمالي المبيعات', f.grossSales),
          line('المرتجعات', -f.returnsTotal),
          line('المصروفات', -f.expensesTotal),
          const _DashedLine(),
          line('النقد المتوقّع', f.expectedCash),
          line('النقد المعدود', f.countedCash),
          line('فرق الصندوق', f.cashVariance),
          line('قيمة فرق المخزون', f.stockVarianceValue),
          const _DashedLine(),
          Row(
            children: [
              Expanded(
                  child: Text('الصافي (عجز/فائض)', style: mono(13, FontWeight.w800))),
              Text(arDinar(f.netDeficitSurplus),
                  style: mono(13, FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Center(child: Text('شكرًا', style: mono(11))),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '- - - - - - - - - - - - - - - - - - - - - -',
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(color: Color(0xFF919EAB), fontSize: 11),
        ),
      );
}

// =============================================================================
// Small helpers
// =============================================================================

String _methodLabel(DemoPaymentMethod m) => switch (m) {
      DemoPaymentMethod.cash => 'نقدًا',
      DemoPaymentMethod.bank => 'تحويل بنكي',
      DemoPaymentMethod.card => 'بطاقة',
      DemoPaymentMethod.sadad => 'سداد',
      DemoPaymentMethod.credit => 'آجل',
    };

String _fmtDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

String _fmtDateTime(DateTime d) =>
    '${_fmtDate(d)} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
