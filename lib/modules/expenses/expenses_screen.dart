import 'package:flutter/material.dart';

import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_provider.dart';
import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_filters.dart';
import '../../shared/widgets/taj_table.dart';
import '../../shared/widgets/taj_ui.dart';

class _Category {
  const _Category(this.name, this.icon);
  final String name;
  final IconData icon;
}

const _categories = <_Category>[
  _Category('إيجار', Icons.home_work_outlined),
  _Category('كهرباء', Icons.bolt_outlined),
  _Category('ماء', Icons.water_drop_outlined),
  _Category('إنترنت', Icons.wifi_rounded),
  _Category('صيانة', Icons.build_outlined),
  _Category('نقل', Icons.local_shipping_outlined),
  _Category('ضيافة', Icons.local_cafe_outlined),
  _Category('قرطاسية', Icons.edit_note_outlined),
  _Category('تسويق', Icons.campaign_outlined),
  _Category('بنكية', Icons.account_balance_outlined),
  _Category('مرتبات', Icons.payments_outlined),
  _Category('مكافآت', Icons.military_tech_outlined),
  _Category('سلف', Icons.request_quote_outlined),
  _Category('مسحوبات', Icons.account_balance_wallet_outlined),
];

/// The icon that represents a category name in the log, falling back to a
/// generic receipt glyph for any category not in the ready list.
IconData _iconFor(String category) {
  for (final c in _categories) {
    if (c.name == category) return c.icon;
  }
  return Icons.receipt_long_outlined;
}

class _Expense {
  const _Expense(
    this.category,
    this.amount,
    this.date,
    this.branch,
    this.method,
  );
  final String category;
  final double amount;
  final String date;
  final String branch;
  final String method;
}

/// Expenses (spec 7.7): ready-category cards + expense log + new-expense form.
///
/// Fully responsive from 320px to 4K, portrait and landscape, RTL and LTR:
/// below [AppBreakpoints.expenseSidePanel] the entry form opens in a slide-in
/// drawer and the log becomes readable row-cards on phones; at or above it the
/// page becomes a persistent master-detail layout (log on the leading side, a
/// fixed-width form panel on the trailing side). All thresholds are named
/// constants on [AppBreakpoints]; nothing about the design or the accounting /
/// employee links changes.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _formCategory = 'إيجار';

  // Static prototype filter, kept as state so the phone "filter" button can
  // surface an active-count badge and a bottom sheet reflecting it.
  final List<TajFilter> _filters = const [
    TajFilter(field: 'الفترة', operator: 'هي', value: 'يوليو'),
  ];

  List<_Expense> get _storeExpenses {
    final store = DemoStoreProvider.of(context);
    return store.expenses.map((e) {
      final matches = store.branches.where((b) => b.id == e.branchId).toList();
      return _Expense(
        e.category,
        e.amount,
        '${e.date.year}/${e.date.month.toString().padLeft(2, '0')}/${e.date.day.toString().padLeft(2, '0')}',
        matches.isEmpty ? 'طرابلس' : matches.first.city,
        e.method.name == 'cash' ? 'نقدي' : 'تحويل',
      );
    }).toList();
  }

  /// Drawer-mode "open the form for [category]" — used when the layout is
  /// narrower than the persistent side panel.
  void _openForm(String category) {
    setState(() => _formCategory = category);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  /// Side-panel-mode "focus the form on [category]" — the panel is already
  /// visible, so this only swaps the selected category.
  void _selectForm(String category) {
    setState(() => _formCategory = category);
  }

  void _openFilterSheet() {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: taj.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            // Lift the sheet above the keyboard should a future filter add an
            // input field; harmless (zero) while filters are static.
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: taj.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(child: Text('الفلاتر', style: text.titleLarge)),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: taj.divider),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TajFilterBar(filters: _filters),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DemoStoreProvider.of(context),
      builder: (_, __) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final taj = context.taj;
    final expenses = _storeExpenses;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      // The drawer is only ever opened below the side-panel threshold; at wider
      // widths the form lives inline as a persistent panel instead.
      endDrawer: Drawer(
        // Wide enough that the form's short fields pair into two columns from
        // the tablet range up; on phones drawerWidth still caps at 92% of the
        // viewport, keeping the fields single-column and full-width.
        width: drawerWidth(context, desired: 520),
        backgroundColor: taj.paper,
        child: _ExpenseForm(category: _formCategory),
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final sidePanel = c.maxWidth >= AppBreakpoints.expenseSidePanel;
          final pad = pagePaddingForWidth(c.maxWidth);
          // PageContainer caps the inner width, so pane calculations must key
          // off the capped width — not the raw viewport — past the cap.
          final capped = c.maxWidth < AppBreakpoints.expenseContentMaxWidth
              ? c.maxWidth
              : AppBreakpoints.expenseContentMaxWidth;

          if (sidePanel) {
            // Master-detail: log/grid pane + persistent entry-form panel. Cap
            // and center on ultra-wide so the panes never stretch infinitely.
            return PageContainer(
              maxWidth: AppBreakpoints.expenseContentMaxWidth,
              child: SizedBox(
                height: c.maxHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.all(pad),
                        children: _mainChildren(
                          context,
                          expenses,
                          onPick: _selectForm,
                          // Filters are always inline at these widths.
                          contentWidth: capped -
                              AppBreakpoints.expenseFormPanelWidth -
                              24 -
                              pad * 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: AppBreakpoints.expenseFormPanelWidth,
                      child: _SidePanelFrame(
                        child: _ExpenseForm(
                          category: _formCategory,
                          embedded: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Single scroll column; the form opens in the end drawer.
          return PageContainer(
            maxWidth: AppBreakpoints.expenseContentMaxWidth,
            child: ListView(
              padding: EdgeInsets.all(pad),
              children: _mainChildren(
                context,
                expenses,
                onPick: _openForm,
                contentWidth: capped - pad * 2,
                headerAction: FilledButton.icon(
                  onPressed: () => _openForm('إيجار'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('مصروف جديد'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The log/grid pane content, shared by both the single-column layout and the
  /// master-detail main pane. [contentWidth] is the width actually available to
  /// this pane so section-level layout decisions key off real space.
  List<Widget> _mainChildren(
    BuildContext context,
    List<_Expense> expenses, {
    required ValueChanged<String> onPick,
    required double contentWidth,
    Widget? headerAction,
  }) {
    final text = Theme.of(context).textTheme;
    final phone = contentWidth < AppBreakpoints.phone;
    return [
      SectionHeading(
        title: 'المصروفات',
        subtitle: 'بنود جاهزة وسجلّ المصروفات',
        trailing: headerAction,
      ),
      const SizedBox(height: 20),
      Text('البنود', style: text.titleMedium),
      const SizedBox(height: 12),
      _CategoryGrid(onTap: onPick, availableWidth: contentWidth),
      const SizedBox(height: 24),
      // Log heading; on phone the filter collapses to a button next to it.
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text('سجلّ المصروفات', style: text.titleMedium)),
          if (phone)
            _FilterButton(count: _filters.length, onTap: _openFilterSheet),
        ],
      ),
      const SizedBox(height: 12),
      if (!phone) ...[
        TajFilterBar(filters: _filters),
        const SizedBox(height: 12),
      ],
      if (phone)
        _ExpenseLogCards(expenses: expenses)
      else
        TajCard(
          padding: EdgeInsets.zero,
          child: TajTable(
            columns: const [
              TajColumn('البند', flex: 3),
              // Amounts are financial and must never be clipped: a wider share
              // keeps even six-figure dinar values fully visible at the table's
              // minimum width, above which TajTable scrolls horizontally.
              TajColumn('المبلغ', flex: 3, numeric: true),
              TajColumn('التاريخ', flex: 2),
              TajColumn('الفرع', flex: 2),
              TajColumn('طريقة الدفع', flex: 2),
            ],
            rows: [
              for (final e in expenses)
                TajRowData(
                  onTap: () {},
                  cells: [
                    Text(
                      e.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      arDinar(e.amount),
                      maxLines: 1,
                      softWrap: false,
                      style: AppThemes.numeralStyle(context, fontSize: 14),
                    ),
                    Text(
                      e.date,
                      style: AppThemes.numeralStyle(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: context.taj.textSecondary,
                      ),
                    ),
                    Text(
                      e.branch,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium,
                    ),
                    StatusBadge(label: e.method, status: TajStatus.info),
                  ],
                ),
            ],
          ),
        ),
    ];
  }
}

/// A compact "filter" trigger with an active-count badge, shown in place of the
/// inline filter bar on phone widths.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.tune_rounded, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('فلترة'),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: taj.primary.main,
                borderRadius: BorderRadius.circular(9),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: AppThemes.numeralStyle(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: taj.primary.contrastText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ready-category cards. Reflows via [gridColumnsFor] on the real available
/// width (never a hardcoded column count) and lets each card size to its
/// content so a long two-line Arabic name is never clipped and never overflows,
/// including in landscape and at large text scales.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onTap, required this.availableWidth});
  final ValueChanged<String> onTap;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    const gap = 14.0;
    final width = availableWidth.isFinite && availableWidth > 0
        ? availableWidth
        : MediaQuery.sizeOf(context).width;
    final columns = gridColumnsFor(
      width,
      minItemWidth: AppBreakpoints.expenseCategoryMinWidth,
      spacing: gap,
      maxColumns: 6,
    );
    final itemWidth = (width - gap * (columns - 1)) / columns;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final cat in _categories)
          SizedBox(
            width: itemWidth,
            child: TajCard(
              padding: const EdgeInsets.all(14),
              onTap: () => onTap(cat.name),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: taj.primary.lighter,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(cat.icon, size: 18, color: taj.primary.dark),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cat.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The expense log rendered as readable cards for phone widths — the amount is
/// never truncated and the font is never shrunk to force a table to fit.
class _ExpenseLogCards extends StatelessWidget {
  const _ExpenseLogCards({required this.expenses});
  final List<_Expense> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const TajEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'لا مصروفات بعد',
        message: 'أضف أول مصروف من زر «مصروف جديد».',
      );
    }
    return Column(
      children: [
        for (final e in expenses) ...[
          _ExpenseRowCard(expense: e),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ExpenseRowCard extends StatelessWidget {
  const _ExpenseRowCard({required this.expense});
  final _Expense expense;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return TajCard(
      onTap: () {},
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: taj.primary.lighter,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(expense.category),
                size: 20, color: taj.primary.dark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  expense.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      expense.date,
                      style: AppThemes.numeralStyle(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: taj.textSecondary,
                      ),
                    ),
                    Text('•',
                        style:
                            text.bodySmall?.copyWith(color: taj.textDisabled)),
                    Text(
                      expense.branch,
                      style: text.bodySmall
                          ?.copyWith(color: taj.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amounts are financial — never ellipsized.
              Text(
                arDinar(expense.amount),
                maxLines: 1,
                softWrap: false,
                style: AppThemes.numeralStyle(
                  context,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              StatusBadge(label: expense.method, status: TajStatus.info),
            ],
          ),
        ],
      ),
    );
  }
}

/// A bordered frame for the persistent entry-form panel so it reads as a
/// distinct surface next to the log, matching the drawer's paper look.
class _SidePanelFrame extends StatelessWidget {
  const _SidePanelFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: taj.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm({required this.category, this.embedded = false});
  final String category;

  /// When embedded as a persistent side panel there is no drawer to pop: the
  /// header shows no close button and saving keeps the panel open.
  final bool embedded;

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  late String _category = widget.category;
  String _branch = 'طرابلس';
  String _method = 'نقدي';
  String? _employeeId;
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();
  final _notesFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountFocus.addListener(() => _ensureVisible(_amountFocus));
    _notesFocus.addListener(() => _ensureVisible(_notesFocus));
  }

  /// Keep the focused field visible above the keyboard.
  void _ensureVisible(FocusNode node) {
    if (!node.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = node.context;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ExpenseForm old) {
    super.didUpdateWidget(old);
    if (old.category != widget.category) _category = widget.category;
  }

  Future<void> _save() async {
    final taj = context.taj;
    // Capture everything that needs the context *before* the await so nothing
    // reaches across the async gap.
    final messenger = ScaffoldMessenger.of(context);
    final store = DemoStoreProvider.of(context);
    final successColor = taj.success.dark;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > 0) {
      final branch = store.branches.first;
      await store.addExpense(
        DemoExpense(
          id: 'EXP-${store.expenses.length + 1}',
          category: _category,
          amount: amount,
          date: DateTime.now(),
          branchId: branch.id,
          method:
              _method == 'نقدي' ? DemoPaymentMethod.cash : DemoPaymentMethod.bank,
          // Salaries link the expense to the chosen employee's payroll profile
          // (defaulting to the first employee when none was explicitly picked).
          employeeId: _category == 'مرتبات'
              ? (_employeeId ??
                  (store.employees.isNotEmpty ? store.employees.first.id : null))
              : null,
        ),
      );
    }
    if (!mounted) return;
    if (widget.embedded) {
      // Persistent panel: keep it open, just reset the amount for the next entry.
      _amountController.clear();
    } else {
      Navigator.of(context).maybePop();
    }
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: successColor,
        content: const Text('تم حفظ المصروف'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    // Lift the whole form (scroll area + pinned save bar) above the keyboard,
    // and respect the safe-area inset on notched / gesture-nav devices.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(child: Text('مصروف جديد', style: text.titleLarge)),
                  if (!widget.embedded)
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),
            Divider(height: 1, color: taj.divider),
            Expanded(
              child: LayoutBuilder(
                builder: (context, fc) {
                  final twoCol =
                      fc.maxWidth >= AppBreakpoints.expenseFormTwoColumn;
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: _fields(context, twoCol: twoCol),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('حفظ المصروف'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fields(BuildContext context, {required bool twoCol}) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final isSalary = _category == 'مرتبات';

    final categoryField = _fieldBlock(
      'البند',
      DropdownButtonFormField<String>(
        value: _category,
        isExpanded: true,
        items: [
          for (final c in _categories)
            DropdownMenuItem(value: c.name, child: Text(c.name)),
        ],
        onChanged: (v) => setState(() => _category = v ?? _category),
      ),
    );

    final amountField = _fieldBlock(
      'المبلغ',
      TextField(
        controller: _amountController,
        focusNode: _amountFocus,
        keyboardType: TextInputType.number,
        // Financial digits use tabular figures so columns line up.
        style: AppThemes.numeralStyle(context, fontSize: 16),
        decoration: const InputDecoration(hintText: '0', suffixText: 'د.ل'),
      ),
    );

    final branchField = _fieldBlock(
      'الفرع',
      DropdownButtonFormField<String>(
        value: _branch,
        isExpanded: true,
        items: const [
          DropdownMenuItem(value: 'طرابلس', child: Text('طرابلس')),
          DropdownMenuItem(value: 'بنغازي', child: Text('بنغازي')),
        ],
        onChanged: (v) => setState(() => _branch = v ?? _branch),
      ),
    );

    final methodField = _fieldBlock(
      'طريقة الدفع',
      DropdownButtonFormField<String>(
        value: _method,
        isExpanded: true,
        items: const [
          DropdownMenuItem(value: 'نقدي', child: Text('نقدي')),
          DropdownMenuItem(value: 'بطاقة', child: Text('بطاقة')),
          DropdownMenuItem(value: 'تحويل', child: Text('تحويل بنكي')),
        ],
        onChanged: (v) => setState(() => _method = v ?? _method),
      ),
    );

    return [
      // Category + amount pair up when there is room; the amount column is
      // guaranteed wider than the minimum by the two-column threshold.
      _pair(categoryField, amountField, twoCol: twoCol),
      if (isSalary) ...[
        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            final employees = DemoStoreProvider.of(context).employees;
            final value = (_employeeId != null &&
                    employees.any((e) => e.id == _employeeId))
                ? _employeeId
                : (employees.isNotEmpty ? employees.first.id : null);
            return _fieldBlock(
              'الموظف',
              DropdownButtonFormField<String>(
                value: value,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                items: [
                  for (final e in employees)
                    DropdownMenuItem(
                      value: e.id,
                      child: Text('${e.name} — ${e.title}',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _employeeId = v),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.link_rounded, size: 14, color: taj.accentFor(taj.info)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'سيُربط هذا المصروف بملف الموظف تلقائيًا.',
                style: text.bodySmall?.copyWith(color: taj.accentFor(taj.info)),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      _pair(branchField, methodField, twoCol: twoCol),
      const SizedBox(height: 16),
      _fieldBlock(
        'ملاحظات',
        TextField(
          focusNode: _notesFocus,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'اختياري…'),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: const Text('إرفاق صورة الإيصال'),
        ),
      ),
    ];
  }

  /// Lay two short fields side by side when [twoCol], else stack them. The gap
  /// matches the vertical rhythm so the reflow between the two is seamless.
  Widget _pair(Widget a, Widget b, {required bool twoCol}) {
    if (twoCol) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 14),
          Expanded(child: b),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [a, const SizedBox(height: 16), b],
    );
  }

  Widget _fieldBlock(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          field,
        ],
      );
}
