import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_provider.dart';
import '../../core/demo/demo_store.dart';
import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_ui.dart';

/// Treasury & Banks — cash boxes and bank accounts, their daily movements
/// (deposit / withdraw / transfer / reconcile), transfers between accounts, and
/// statement reconciliation.
///
/// Financially sensitive: no figure is ever truncated (long balances go compact
/// with the exact value one tap/hover away, and every amount column is
/// horizontally reachable) and no movement or column is ever hidden to save
/// space. Fully responsive from 320px to 4K, portrait/landscape, RTL/LTR:
/// below [AppBreakpoints.treasurySplit] the page is a single scroll (row-cards
/// for movements on phones, a frozen-first-column scrolling table above that);
/// at/above it the page is a master-detail — an account list beside the
/// selected account's movements.
class TreasuryScreen extends StatefulWidget {
  const TreasuryScreen({super.key});
  @override
  State<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends State<TreasuryScreen> {
  // Filters.
  String? _typeFilter; // null = all · 'cash' · 'bank'
  String? _branchFilter; // null = all · branchId
  String _periodFilter = 'all'; // all · today · week · month

  // Master-detail selection + summary strip state.
  String? _selectedAccountId;
  bool _summaryCollapsed = false;

  // Movement table horizontal scroll: the body drives, the pinned header
  // follows (one-way sync), so the header stays put on vertical scroll while
  // the first column stays frozen during horizontal scroll.
  final ScrollController _bodyH = ScrollController();
  final ScrollController _headerH = ScrollController();

  @override
  void initState() {
    super.initState();
    _bodyH.addListener(_syncHeader);
  }

  void _syncHeader() {
    if (_headerH.hasClients && _bodyH.hasClients) {
      final max = _headerH.position.maxScrollExtent;
      final target = _bodyH.offset.clamp(0.0, max);
      if ((_headerH.offset - target).abs() > 0.5) _headerH.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _bodyH.dispose();
    _headerH.dispose();
    super.dispose();
  }

  DemoStore get _store => DemoStoreProvider.of(context);

  int get _activeFilterCount =>
      (_typeFilter != null ? 1 : 0) +
      (_branchFilter != null ? 1 : 0) +
      (_periodFilter != 'all' ? 1 : 0);

  // --- data helpers ---------------------------------------------------------

  List<DemoAccount> _visibleAccounts() => _store.accounts.where((a) {
        if (_typeFilter == 'cash' && a.type != DemoAccountType.cash) {
          return false;
        }
        if (_typeFilter == 'bank' && a.type != DemoAccountType.bank) {
          return false;
        }
        if (_branchFilter != null && a.branchId != _branchFilter) return false;
        return true;
      }).toList();

  bool _inPeriod(DateTime d) {
    final now = DateTime.now();
    switch (_periodFilter) {
      case 'today':
        return d.year == now.year && d.month == now.month && d.day == now.day;
      case 'week':
        return d.isAfter(now.subtract(const Duration(days: 7)));
      case 'month':
        return d.year == now.year && d.month == now.month;
      default:
        return true;
    }
  }

  List<DemoTreasuryMovement> _movementsFor(Set<String> accountIds) =>
      _store.treasuryMovements
          .where((m) => accountIds.contains(m.accountId) && _inPeriod(m.date))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Running book balance keyed by movement id, computed chronologically over
  /// the full (unfiltered) history so a filtered view still shows the true
  /// balance after each movement.
  Map<String, double> _runningById() {
    final map = <String, double>{};
    for (final acc in _store.accounts) {
      final ms = _store.treasuryMovements
          .where((m) => m.accountId == acc.id)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      var bal = acc.openingBalance;
      for (final m in ms) {
        bal += m.signedAmount;
        map[m.id] = bal;
      }
    }
    return map;
  }

  String _accountName(String id) =>
      _store.accounts.firstWhere((a) => a.id == id,
          orElse: () => const DemoAccount(
              id: '', name: '—', type: DemoAccountType.cash, branchId: '')).name;

  String _branchCity(String id) => _store.branches
      .firstWhere((b) => b.id == id,
          orElse: () => _store.branches.isEmpty
              ? const DemoBranch(id: '', name: '—', city: '—')
              : _store.branches.first)
      .city;

  /// City of the branch that owns [accountId] (for the movement table's branch
  /// column).
  String _cityForAccount(String accountId) {
    final acc = _store.accounts.firstWhere((a) => a.id == accountId,
        orElse: () => const DemoAccount(
            id: '', name: '', type: DemoAccountType.cash, branchId: ''));
    return _branchCity(acc.branchId);
  }

  /// Bank accounts whose book balance disagrees with the statement balance.
  List<DemoAccount> _mismatched(List<DemoAccount> scope) => scope
      .where((a) =>
          a.type == DemoAccountType.bank &&
          (_store.accountBalance(a.id) - _store.reconciledBalance(a.id)).abs() >
              0.005)
      .toList();

  // --- actions --------------------------------------------------------------

  void _select(String accountId) => setState(() => _selectedAccountId = accountId);

  Future<void> _openTransfer({String? from}) =>
      showTreasuryTransferDialog(context, _store, presetFrom: from);

  Future<void> _openMovement({String? account, bool deposit = true}) =>
      showTreasuryMovementDialog(context, _store,
          presetAccount: account, deposit: deposit);

  Future<void> _openReconcile(String accountId) =>
      showTreasuryReconcileDialog(context, _store, accountId);

  void _openAccountActions(DemoAccount account) {
    final taj = context.taj;
    final isBank = account.type == DemoAccountType.bank;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: taj.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: taj.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.south_rounded),
              title: const Text('إيداع'),
              onTap: () {
                Navigator.pop(sheet);
                _openMovement(account: account.id, deposit: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.north_rounded),
              title: const Text('سحب'),
              onTap: () {
                Navigator.pop(sheet);
                _openMovement(account: account.id, deposit: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('تحويل'),
              onTap: () {
                Navigator.pop(sheet);
                _openTransfer(from: account.id);
              },
            ),
            if (isBank)
              ListTile(
                leading: const Icon(Icons.rule_rounded),
                title: const Text('تسوية كشف الحساب'),
                onTap: () {
                  Navigator.pop(sheet);
                  _openReconcile(account.id);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet() {
    final taj = context.taj;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: taj.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheet).bottom),
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
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('الفلاتر',
                              style: Theme.of(context).textTheme.titleLarge)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _typeFilter = null;
                            _branchFilter = null;
                            _periodFilter = 'all';
                          });
                          setSheet(() {});
                        },
                        child: const Text('مسح الكل'),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: taj.divider),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _FilterControls(
                    typeFilter: _typeFilter,
                    branchFilter: _branchFilter,
                    periodFilter: _periodFilter,
                    branches: _store.branches,
                    stacked: true,
                    onType: (v) {
                      setState(() => _typeFilter = v);
                      setSheet(() {});
                    },
                    onBranch: (v) {
                      setState(() => _branchFilter = v);
                      setSheet(() {});
                    },
                    onPeriod: (v) {
                      setState(() => _periodFilter = v);
                      setSheet(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- build ----------------------------------------------------------------

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
          final capped = math.min(
              c.maxWidth, AppBreakpoints.treasuryContentMaxWidth);
          final masterDetail = c.maxWidth >= AppBreakpoints.treasurySplit;
          final short = c.maxHeight < AppBreakpoints.treasuryCondenseSummaryHeight;
          if (masterDetail) {
            return PageContainer(
              maxWidth: AppBreakpoints.treasuryContentMaxWidth,
              child: SizedBox(
                height: c.maxHeight,
                child: _buildMasterDetail(context, capped, short),
              ),
            );
          }
          return PageContainer(
            maxWidth: AppBreakpoints.treasuryContentMaxWidth,
            child: _buildSingle(context, capped, short),
          );
        },
      ),
    );
  }

  // Single-column families (< treasurySplit).
  Widget _buildSingle(BuildContext context, double width, bool short) {
    final pad = pagePaddingForWidth(width);
    final phone = width < AppBreakpoints.phone;
    final content = width - pad * 2;
    final accounts = _visibleAccounts();
    final ids = accounts.map((a) => a.id).toSet();
    final movements = _movementsFor(ids);
    final running = _runningById();
    final mismatched = _mismatched(accounts);
    final showHeaderActions = !phone;

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
          child: SectionHeading(
            title: 'الخزائن والبنوك',
            subtitle: 'أرصدة الحسابات وحركة اليوم',
            trailing: showHeaderActions ? _headerActions() : null,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 20, pad, 0),
          child: _BalanceCardsGrid(
            accounts: accounts,
            store: _store,
            availableWidth: content,
            onTap: _openAccountActions,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
          child: _SummaryStrip(
            movements: movements,
            condensed: short,
            collapsed: _summaryCollapsed,
            onToggle: () =>
                setState(() => _summaryCollapsed = !_summaryCollapsed),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
          child: _filterRow(phone),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 20, pad, 8),
          child: Text('الحركات اليومية',
              style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    ];

    if (mismatched.isNotEmpty) {
      slivers.add(SliverPersistentHeader(
        pinned: true,
        delegate: _PinnedBox(
          height: 92,
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
            child: _MismatchWarning(accounts: mismatched, store: _store),
          ),
        ),
      ));
    }

    if (phone) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 0, pad, 0),
          child: _MovementCards(
            movements: movements,
            store: _store,
            running: running,
          ),
        ),
      ));
    } else {
      final cols = _columns(withAccount: true);
      _addTableSlivers(slivers, cols, movements, running, pad);
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));

    final scroll = CustomScrollView(slivers: slivers);

    if (!phone) return scroll;
    // Phone: actions live in a bottom bar respecting SafeArea.
    return Column(
      children: [
        Expanded(child: scroll),
        _BottomActionBar(
          onTransfer: () => _openTransfer(),
          onMovement: () => _openMovement(),
        ),
      ],
    );
  }

  // Master-detail family (>= treasurySplit).
  Widget _buildMasterDetail(BuildContext context, double width, bool short) {
    final accounts = _visibleAccounts();
    // Resolve the selected account within the visible set.
    final selectedId = (accounts.any((a) => a.id == _selectedAccountId))
        ? _selectedAccountId!
        : (accounts.isNotEmpty ? accounts.first.id : null);
    final paneWidth =
        (width * 0.24).clamp(AppBreakpoints.treasuryAccountPaneMin,
            AppBreakpoints.treasuryAccountPaneMax);

    final running = _runningById();
    final movements =
        selectedId == null ? <DemoTreasuryMovement>[] : _movementsFor({selectedId});
    final mismatched =
        selectedId == null ? <DemoAccount>[] : _mismatched(accounts.where((a) => a.id == selectedId).toList());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: paneWidth.toDouble(),
          child: _AccountPane(
            accounts: accounts,
            store: _store,
            selectedId: selectedId,
            onSelect: _select,
            onActions: _openAccountActions,
          ),
        ),
        Container(width: 1, color: context.taj.divider),
        Expanded(
          child: selectedId == null
              ? const TajEmptyState(
                  icon: Icons.account_balance_outlined,
                  title: 'لا حسابات',
                  message: 'لا توجد حسابات مطابقة للفلاتر الحالية.')
              : _buildMovementsPane(
                  context, selectedId, movements, running, mismatched, short),
        ),
      ],
    );
  }

  Widget _buildMovementsPane(
    BuildContext context,
    String accountId,
    List<DemoTreasuryMovement> movements,
    Map<String, double> running,
    List<DemoAccount> mismatched,
    bool short,
  ) {
    const pad = 24.0;
    final account = _store.accounts.firstWhere((a) => a.id == accountId);
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(pad, pad, pad, 0),
          child: SectionHeading(
            title: account.name,
            subtitle: 'حركة الحساب والتسوية',
            trailing: _headerActions(presetAccount: accountId),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(pad, 16, pad, 0),
          child: _SummaryStrip(
            movements: movements,
            condensed: short,
            collapsed: _summaryCollapsed,
            onToggle: () =>
                setState(() => _summaryCollapsed = !_summaryCollapsed),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(pad, 16, pad, 0),
          child: _filterRow(false),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(pad, 20, pad, 8),
          child: Text('الحركات اليومية',
              style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    ];
    if (mismatched.isNotEmpty) {
      slivers.add(SliverPersistentHeader(
        pinned: true,
        delegate: _PinnedBox(
          height: 92,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(pad, 0, pad, 8),
            child: _MismatchWarning(accounts: mismatched, store: _store),
          ),
        ),
      ));
    }
    _addTableSlivers(slivers, _columns(withAccount: false), movements, running,
        pad);
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    return CustomScrollView(slivers: slivers);
  }

  // --- shared pieces --------------------------------------------------------

  Widget _headerActions({String? presetAccount}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _openMovement(account: presetAccount),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('حركة جديدة'),
        ),
        FilledButton.icon(
          onPressed: () => _openTransfer(from: presetAccount),
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('تحويل'),
        ),
      ],
    );
  }

  Widget _filterRow(bool phone) {
    if (phone) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: _FilterButton(count: _activeFilterCount, onTap: _openFilterSheet),
      );
    }
    return _FilterControls(
      typeFilter: _typeFilter,
      branchFilter: _branchFilter,
      periodFilter: _periodFilter,
      branches: _store.branches,
      stacked: false,
      onType: (v) => setState(() => _typeFilter = v),
      onBranch: (v) => setState(() => _branchFilter = v),
      onPeriod: (v) => setState(() => _periodFilter = v),
    );
  }

  List<_Col> _columns({required bool withAccount}) => [
        if (withAccount)
          const _Col('الحساب', 150, kind: _ColKind.account)
        else
          const _Col('التاريخ', 104, kind: _ColKind.date),
        if (withAccount) const _Col('التاريخ', 96, kind: _ColKind.date),
        // Wide enough that the longest movement badge ("تحويل" / "تسوية") is
        // never clipped inside its cell.
        const _Col('النوع', 116, kind: _ColKind.type),
        const _Col('المرجع', 92, kind: _ColKind.ref),
        const _Col('البيان', 160, kind: _ColKind.description),
        const _Col('الفرع', 88, kind: _ColKind.branch),
        const _Col('وارد', 128, kind: _ColKind.inflow, numeric: true),
        const _Col('منصرف', 128, kind: _ColKind.outflow, numeric: true),
        const _Col('الرصيد', 132, kind: _ColKind.running, numeric: true),
      ];

  void _addTableSlivers(
    List<Widget> slivers,
    List<_Col> cols,
    List<DemoTreasuryMovement> movements,
    Map<String, double> running,
    double pad,
  ) {
    if (movements.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 0, pad, 0),
          child: const TajEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'لا حركات',
            message: 'لا توجد حركات مطابقة للفلاتر الحالية.',
          ),
        ),
      ));
      return;
    }
    final frozen = cols.first;
    final rest = cols.sublist(1);
    final restWidth = rest.fold<double>(0, (s, c) => s + c.width);

    // Pinned header — stays put on vertical scroll; first column frozen; the
    // rest mirrors the body's horizontal scroll offset.
    slivers.add(SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedBox(
        height: 45,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: _TableHeader(
            frozen: frozen,
            rest: rest,
            restWidth: restWidth,
            controller: _headerH,
          ),
        ),
      ),
    ));
    slivers.add(SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 0),
        child: _TableBody(
          frozen: frozen,
          rest: rest,
          restWidth: restWidth,
          movements: movements,
          running: running,
          controller: _bodyH,
          accountName: _accountName,
          cityForAccount: _cityForAccount,
        ),
      ),
    ));
  }
}

// ===========================================================================
// Balance cards
// ===========================================================================

class _BalanceCardsGrid extends StatelessWidget {
  const _BalanceCardsGrid({
    required this.accounts,
    required this.store,
    required this.availableWidth,
    required this.onTap,
  });
  final List<DemoAccount> accounts;
  final DemoStore store;
  final double availableWidth;
  final ValueChanged<DemoAccount> onTap;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const TajEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'لا حسابات',
        message: 'لا توجد حسابات مطابقة للفلاتر الحالية.',
      );
    }
    const gap = 14.0;
    final w = availableWidth.isFinite && availableWidth > 0
        ? availableWidth
        : MediaQuery.sizeOf(context).width;
    // 1 column on a narrow phone, 2 once past treasuryTwoBalanceCols, then the
    // adaptive grid takes over up to 4.
    int columns;
    if (w < AppBreakpoints.treasuryTwoBalanceCols) {
      columns = 1;
    } else {
      columns = gridColumnsFor(w,
          minItemWidth: AppBreakpoints.treasuryBalanceCardMin,
          spacing: gap,
          maxColumns: 4);
    }
    final itemWidth = (w - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final a in accounts)
          SizedBox(
            width: itemWidth,
            child: _BalanceCard(account: a, store: store, onTap: () => onTap(a)),
          ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.account,
    required this.store,
    required this.onTap,
  });
  final DemoAccount account;
  final DemoStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final balance = store.accountBalance(account.id);
    final isBank = account.type == DemoAccountType.bank;
    final mismatch =
        isBank ? balance - store.reconciledBalance(account.id) : 0.0;
    final swatch = isBank ? taj.info : taj.success;
    final subtitle = isBank
        ? [account.bankName, account.accountNo].whereType<String>().join(' · ')
        : 'صندوق نقدي';

    return TajCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: swatch.lighter,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                    isBank
                        ? Icons.account_balance_outlined
                        : Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: swatch.dark),
              ),
              const SizedBox(width: 10),
              // Name may be long; it flexes and ellipsizes, the badge stays
              // beside it and never has a fixed width.
              Expanded(
                child: Text(account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _AccountTypeBadge(account.type),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // The balance: compact past a length threshold, up to two lines, and
          // the exact value is always in the tooltip — never truncated.
          _Amount(
            value: balance,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            maxLines: 2,
            color: taj.textPrimary,
          ),
          const SizedBox(height: 6),
          Text(subtitle.isEmpty ? 'صندوق نقدي' : subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: taj.textSecondary)),
          if (mismatch.abs() > 0.005) ...[
            const SizedBox(height: 10),
            _MismatchChip(diff: mismatch),
          ],
        ],
      ),
    );
  }
}

class _MismatchChip extends StatelessWidget {
  const _MismatchChip({required this.diff});
  final double diff;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: taj.warning.lighter,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.report_gmailerrorred_rounded,
              size: 14, color: taj.warning.dark),
          const SizedBox(width: 5),
          Flexible(
            child: Tooltip(
              message: 'الفرق مع كشف الحساب: ${arDinar(diff)}',
              child: Text(
                'فرق تسوية ${arDinarFit(diff.abs(), maxChars: 12)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppThemes.numeralStyle(context,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: taj.warning.dark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Summary strip (in / out / net) — condenses on short viewports.
// ===========================================================================

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.movements,
    required this.condensed,
    required this.collapsed,
    required this.onToggle,
  });
  final List<DemoTreasuryMovement> movements;
  final bool condensed;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    var inflow = 0.0, outflow = 0.0;
    for (final m in movements) {
      if (m.isInflow) {
        inflow += m.amount;
      } else {
        outflow += m.amount;
      }
    }
    final net = inflow - outflow;

    // Condensed (short height): a single compact line that can collapse away,
    // so the strip never eats more than ~30% of a 720p screen.
    if (condensed) {
      return TajCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.summarize_outlined,
                    size: 16, color: taj.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('ملخص الحركة',
                      style: text.labelLarge, maxLines: 1),
                ),
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                        collapsed
                            ? Icons.expand_more_rounded
                            : Icons.expand_less_rounded,
                        size: 18,
                        color: taj.textSecondary),
                  ),
                ),
              ],
            ),
            if (!collapsed) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _MiniStat(label: 'وارد', value: inflow, swatch: taj.success),
                  _MiniStat(label: 'منصرف', value: outflow, swatch: taj.error),
                  _MiniStat(
                      label: 'الصافي',
                      value: net,
                      swatch: net < 0 ? taj.error : taj.primary),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // Roomy: three tiles that reflow (Wrap) so they never overflow.
    return LayoutBuilder(
      builder: (context, c) {
        final tiles = [
          _SummaryTile(
              label: 'إجمالي الوارد',
              value: inflow,
              icon: Icons.south_rounded,
              swatch: taj.success),
          _SummaryTile(
              label: 'إجمالي المنصرف',
              value: outflow,
              icon: Icons.north_rounded,
              swatch: taj.error),
          _SummaryTile(
              label: 'الصافي',
              value: net,
              icon: Icons.account_balance_wallet_outlined,
              swatch: net < 0 ? taj.error : taj.primary),
        ];
        final cols = c.maxWidth >= 560 ? 3 : (c.maxWidth >= 360 ? 3 : 1);
        const gap = 12.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.swatch});
  final String label;
  final double value;
  final TajSwatch swatch;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: taj.textSecondary)),
        _Amount(
            value: value,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: taj.accentFor(swatch)),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.swatch,
  });
  final String label;
  final double value;
  final IconData icon;
  final TajSwatch swatch;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return TajCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: swatch.lighter,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: swatch.dark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: taj.textSecondary)),
                const SizedBox(height: 4),
                _Amount(
                    value: value,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    maxLines: 2,
                    color: taj.textPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Mismatch warning
// ===========================================================================

class _MismatchWarning extends StatelessWidget {
  const _MismatchWarning({required this.accounts, required this.store});
  final List<DemoAccount> accounts;
  final DemoStore store;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final total = accounts.fold<double>(
        0,
        (s, a) =>
            s + (store.accountBalance(a.id) - store.reconciledBalance(a.id)));
    final names = accounts.map((a) => a.name).join('، ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: taj.warning.lighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taj.warning.light),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: taj.warning.dark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'فروق تسوية بمقدار ${arDinarFit(total.abs(), maxChars: 14)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: taj.warning.dark),
                ),
                Text(
                  'حسابات بحاجة إلى تسوية: $names',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: taj.warning.dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Movement table (frozen first column + horizontal scroll + sticky header)
// ===========================================================================

enum _ColKind { account, date, type, ref, description, branch, inflow, outflow, running }

class _Col {
  const _Col(this.label, this.width, {required this.kind, this.numeric = false});
  final String label;
  final double width;
  final _ColKind kind;
  final bool numeric;
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.frozen,
    required this.rest,
    required this.restWidth,
    required this.controller,
  });
  final _Col frozen;
  final List<_Col> rest;
  final double restWidth;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    Widget cell(_Col c) => Align(
          alignment: c.numeric
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Text(c.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: taj.textSecondary, fontWeight: FontWeight.w600)),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: frozen.width,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: cell(frozen),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: restWidth,
                  child: Row(
                    children: [
                      for (final c in rest)
                        SizedBox(
                          width: c.width,
                          child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(end: 12),
                            child: cell(c),
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
    );
  }
}

class _TableBody extends StatelessWidget {
  const _TableBody({
    required this.frozen,
    required this.rest,
    required this.restWidth,
    required this.movements,
    required this.running,
    required this.controller,
    required this.accountName,
    required this.cityForAccount,
  });
  final _Col frozen;
  final List<_Col> rest;
  final double restWidth;
  final List<DemoTreasuryMovement> movements;
  final Map<String, double> running;
  final ScrollController controller;
  final String Function(String) accountName;
  final String Function(String) cityForAccount;

  static const double _rowHeight = 54;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frozen first column.
        SizedBox(
          width: frozen.width,
          child: Column(
            children: [
              for (final m in movements)
                _FrozenCell(
                  height: _rowHeight,
                  child: _cellFor(context, frozen, m),
                ),
            ],
          ),
        ),
        // Horizontally scrollable remainder.
        Expanded(
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: restWidth,
              child: Column(
                children: [
                  for (final m in movements)
                    Container(
                      height: _rowHeight,
                      decoration: BoxDecoration(
                        border:
                            Border(bottom: BorderSide(color: taj.divider)),
                      ),
                      child: Row(
                        children: [
                          for (final c in rest)
                            SizedBox(
                              width: c.width,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    end: 12),
                                child: _cellFor(context, c, m),
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
    );
  }

  Widget _cellFor(BuildContext context, _Col c, DemoTreasuryMovement m) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    switch (c.kind) {
      case _ColKind.account:
        return Row(
          children: [
            _Dot(color: m.isInflow ? taj.success.main : taj.error.main),
            const SizedBox(width: 6),
            Expanded(
              child: Text(accountName(m.accountId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      case _ColKind.date:
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(_fmtDate(m.date),
              maxLines: 1,
              style: AppThemes.numeralStyle(context,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: taj.textSecondary)),
        );
      case _ColKind.type:
        return Align(
            alignment: AlignmentDirectional.centerStart,
            child: _TypeBadge(m.type));
      case _ColKind.ref:
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(m.reference.isEmpty ? '—' : m.reference,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemes.numeralStyle(context,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: taj.textSecondary)),
        );
      case _ColKind.description:
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(m.description.isEmpty ? '—' : m.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall),
        );
      case _ColKind.branch:
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(cityForAccount(m.accountId),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: taj.textSecondary)),
        );
      case _ColKind.inflow:
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: m.isInflow
              ? _Amount(
                  value: m.amount,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  maxChars: 12,
                  color: taj.accentFor(taj.success))
              : Text('—', style: text.bodySmall),
        );
      case _ColKind.outflow:
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: !m.isInflow
              ? _Amount(
                  value: m.amount,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  maxChars: 12,
                  color: taj.accentFor(taj.error))
              : Text('—', style: text.bodySmall),
        );
      case _ColKind.running:
        final bal = running[m.id] ?? 0;
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _Amount(
              value: bal,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              showSign: bal < 0,
              maxChars: 12,
              color: bal < 0 ? taj.accentFor(taj.error) : taj.textPrimary),
        );
    }
  }

}

class _FrozenCell extends StatelessWidget {
  const _FrozenCell({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.taj.divider)),
      ),
      padding: const EdgeInsetsDirectional.only(end: 12),
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
  }
}

// ===========================================================================
// Movement cards (phone)
// ===========================================================================

class _MovementCards extends StatelessWidget {
  const _MovementCards({
    required this.movements,
    required this.store,
    required this.running,
  });
  final List<DemoTreasuryMovement> movements;
  final DemoStore store;
  final Map<String, double> running;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return const TajEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'لا حركات',
        message: 'لا توجد حركات مطابقة للفلاتر الحالية.',
      );
    }
    return Column(
      children: [
        for (final m in movements) ...[
          _MovementCard(movement: m, store: store, running: running[m.id] ?? 0),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MovementCard extends StatelessWidget {
  const _MovementCard(
      {required this.movement, required this.store, required this.running});
  final DemoTreasuryMovement movement;
  final DemoStore store;
  final double running;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final inflow = movement.isInflow;
    final swatch = inflow ? taj.success : taj.error;
    final accountName = store.accounts
        .firstWhere((a) => a.id == movement.accountId,
            orElse: () => const DemoAccount(
                id: '', name: '—', type: DemoAccountType.cash, branchId: ''))
        .name;
    return TajCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: swatch.lighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(movement.type),
                    size: 20, color: swatch.dark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(accountName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    _TypeBadge(movement.type),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Amount keeps three independent signals: sign, colour and the
              // type icon above — never colour alone. Never truncated.
              _Amount(
                value: movement.amount,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                maxLines: 2,
                leadingSign: inflow ? '+' : '−',
                color: taj.accentFor(swatch),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(_fmtDate(movement.date),
                  style: AppThemes.numeralStyle(context,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: taj.textSecondary)),
              if (movement.reference.isNotEmpty)
                Text(movement.reference,
                    style: AppThemes.numeralStyle(context,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: taj.textDisabled)),
              if (movement.description.isNotEmpty)
                Text(movement.description,
                    style: text.bodySmall?.copyWith(color: taj.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: taj.divider),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('الرصيد الجاري',
                  style: text.bodySmall?.copyWith(color: taj.textSecondary)),
              const Spacer(),
              _Amount(
                value: running,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                showSign: running < 0,
                color:
                    running < 0 ? taj.accentFor(taj.error) : taj.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Account pane (master-detail)
// ===========================================================================

class _AccountPane extends StatelessWidget {
  const _AccountPane({
    required this.accounts,
    required this.store,
    required this.selectedId,
    required this.onSelect,
    required this.onActions,
  });
  final List<DemoAccount> accounts;
  final DemoStore store;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<DemoAccount> onActions;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text('الحسابات', style: text.titleMedium),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final a = accounts[i];
              final selected = a.id == selectedId;
              final balance = store.accountBalance(a.id);
              final isBank = a.type == DemoAccountType.bank;
              final mismatch = isBank
                  ? (balance - store.reconciledBalance(a.id)).abs() > 0.005
                  : false;
              return Material(
                color: selected ? taj.primary.lighter : taj.paper,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onSelect(a.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected ? taj.primary.light : taj.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(a.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                            ),
                            if (mismatch)
                              Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(start: 4),
                                child: Icon(Icons.warning_amber_rounded,
                                    size: 15, color: taj.warning.dark),
                              ),
                            InkWell(
                              onTap: () => onActions(a),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(Icons.more_vert_rounded,
                                    size: 18, color: taj.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _Amount(
                            value: balance,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            maxLines: 2,
                            color: taj.textPrimary),
                        const SizedBox(height: 4),
                        _AccountTypeBadge(a.type),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Filters
// ===========================================================================

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
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: taj.primary.main,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text('$count',
                  textAlign: TextAlign.center,
                  style: AppThemes.numeralStyle(context,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: taj.primary.contrastText)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterControls extends StatelessWidget {
  const _FilterControls({
    required this.typeFilter,
    required this.branchFilter,
    required this.periodFilter,
    required this.branches,
    required this.stacked,
    required this.onType,
    required this.onBranch,
    required this.onPeriod,
  });
  final String? typeFilter;
  final String? branchFilter;
  final String periodFilter;
  final List<DemoBranch> branches;
  final bool stacked;
  final ValueChanged<String?> onType;
  final ValueChanged<String?> onBranch;
  final ValueChanged<String> onPeriod;

  @override
  Widget build(BuildContext context) {
    final typePill = _FilterPill<String?>(
      icon: Icons.category_outlined,
      value: typeFilter,
      options: const [
        (null, 'كل الأنواع'),
        ('cash', 'النقدية'),
        ('bank', 'البنوك'),
      ],
      onSelected: onType,
      fullWidth: stacked,
    );
    final branchPill = _FilterPill<String?>(
      icon: Icons.store_outlined,
      value: branchFilter,
      options: [
        const (null, 'كل الفروع'),
        for (final b in branches) (b.id, b.city),
      ],
      onSelected: onBranch,
      fullWidth: stacked,
    );
    final periodPill = _FilterPill<String>(
      icon: Icons.calendar_today_outlined,
      value: periodFilter,
      options: const [
        ('all', 'كل الفترات'),
        ('today', 'اليوم'),
        ('week', 'آخر 7 أيام'),
        ('month', 'هذا الشهر'),
      ],
      onSelected: onPeriod,
      fullWidth: stacked,
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          typePill,
          const SizedBox(height: 12),
          branchPill,
          const SizedBox(height: 12),
          periodPill,
        ],
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: [typePill, branchPill, periodPill]);
  }
}

class _FilterPill<T> extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.value,
    required this.options,
    required this.onSelected,
    this.fullWidth = false,
  });
  final IconData icon;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final current =
        options.firstWhere((o) => o.$1 == value, orElse: () => options.first).$2;
    final pill = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: taj.divider),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: taj.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(current,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(color: taj.textPrimary)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down_rounded, size: 18, color: taj.textSecondary),
        ],
      ),
    );
    return PopupMenuButton<T>(
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem<T>(value: o.$1, child: Text(o.$2)),
      ],
      child: pill,
    );
  }
}

// ===========================================================================
// Shared small widgets
// ===========================================================================

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.onTransfer, required this.onMovement});
  final VoidCallback onTransfer;
  final VoidCallback onMovement;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(top: BorderSide(color: taj.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMovement,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('حركة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onTransfer,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('تحويل'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeBadge extends StatelessWidget {
  const _AccountTypeBadge(this.type);
  final DemoAccountType type;
  @override
  Widget build(BuildContext context) {
    final isBank = type == DemoAccountType.bank;
    return StatusBadge(
      label: isBank ? 'بنك' : 'نقد',
      status: isBank ? TajStatus.info : TajStatus.success,
      icon: isBank
          ? Icons.account_balance_outlined
          : Icons.account_balance_wallet_outlined,
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.type);
  final DemoMovementType type;
  @override
  Widget build(BuildContext context) {
    final (label, status, icon) = switch (type) {
      DemoMovementType.deposit => ('إيداع', TajStatus.success, Icons.south_rounded),
      DemoMovementType.withdraw => ('سحب', TajStatus.error, Icons.north_rounded),
      DemoMovementType.transfer =>
        ('تحويل', TajStatus.info, Icons.swap_horiz_rounded),
      DemoMovementType.reconcile =>
        ('تسوية', TajStatus.secondary, Icons.rule_rounded),
    };
    return StatusBadge(label: label, status: status, icon: icon);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// A monetary amount: tabular figures, compact past a length threshold, the
/// exact value always in a tooltip, and never truncated (single line in dense
/// contexts, up to [maxLines] in cards).
class _Amount extends StatelessWidget {
  const _Amount({
    required this.value,
    required this.fontSize,
    this.fontWeight = FontWeight.w600,
    this.color,
    this.maxLines = 1,
    this.showSign = false,
    this.leadingSign,
    this.maxChars = 16,
  });
  final double value;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final int maxLines;
  final bool showSign;
  final String? leadingSign;

  /// Length threshold past which the figure is shown compactly (the exact value
  /// stays in the tooltip). Dense table cells pass a smaller value.
  final int maxChars;

  @override
  Widget build(BuildContext context) {
    final display = arDinarFit(value.abs(), maxChars: maxChars);
    final sign = leadingSign ?? (showSign && value < 0 ? '−' : '');
    return Tooltip(
      message: arDinar(value),
      child: Text(
        '$sign$display',
        maxLines: maxLines,
        softWrap: maxLines > 1,
        overflow: maxLines > 1 ? TextOverflow.clip : TextOverflow.ellipsis,
        style: AppThemes.numeralStyle(context,
            fontSize: fontSize, fontWeight: fontWeight, color: color),
      ),
    );
  }
}

class _PinnedBox extends SliverPersistentHeaderDelegate {
  _PinnedBox({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: ColoredBox(color: context.taj.background, child: child),
    );
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(covariant _PinnedBox old) =>
      old.height != height || old.child != child;
}

String _fmtDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

IconData _typeIcon(DemoMovementType t) => switch (t) {
      DemoMovementType.deposit => Icons.south_rounded,
      DemoMovementType.withdraw => Icons.north_rounded,
      DemoMovementType.transfer => Icons.swap_horiz_rounded,
      DemoMovementType.reconcile => Icons.rule_rounded,
    };

// ===========================================================================
// Dialogs
// ===========================================================================

/// Shell for a treasury dialog: capped width per size class, height 90% of the
/// viewport, content in an internal scroll view (never a fixed-height dialog),
/// and keyboard-safe.
Future<T?> _treasuryDialog<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext, StateSetter) body,
  required List<Widget> Function(BuildContext) actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      final w = size.width;
      final phone = w < AppBreakpoints.phone;
      final cap = w < AppBreakpoints.phone
          ? w
          : w < AppBreakpoints.tablet
              ? AppBreakpoints.treasuryDialogNarrow
              : w < AppBreakpoints.laptop
                  ? AppBreakpoints.treasuryDialogMid
                  : AppBreakpoints.treasuryDialogMax;
      final dialogW = phone ? w : math.min(cap, w - 48);
      final taj = ctx.taj;
      return StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: phone ? 12 : 24, vertical: 24),
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
                          child: Text(title,
                              style: Theme.of(ctx).textTheme.titleLarge)),
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
                    padding: EdgeInsets.fromLTRB(
                        20, 16, 20, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
                    child: body(ctx, setLocal),
                  ),
                ),
                Divider(height: 1, color: taj.divider),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions(ctx),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showTreasuryTransferDialog(
    BuildContext context, DemoStore store, {String? presetFrom}) async {
  if (store.accounts.length < 2) return;
  String from = presetFrom ?? store.accounts.first.id;
  String to = store.accounts.firstWhere((a) => a.id != from).id;
  final amountCtrl = TextEditingController();
  final refCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  await _treasuryDialog<void>(
    context,
    title: 'تحويل بين الحسابات',
    body: (ctx, setLocal) {
      final taj = ctx.taj;
      final isRtl = Directionality.of(ctx) == TextDirection.rtl;
      final wide = MediaQuery.sizeOf(ctx).width >= AppBreakpoints.phone;
      final fromField = _LabeledField(
        label: 'من حساب',
        child: _AccountDropdown(
          accounts: store.accounts,
          value: from,
          onChanged: (v) => setLocal(() => from = v),
        ),
      );
      final toField = _LabeledField(
        label: 'إلى حساب',
        child: _AccountDropdown(
          accounts: store.accounts,
          value: to,
          onChanged: (v) => setLocal(() => to = v),
        ),
      );
      final arrow = Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Icon(
          // Directional: points from the "from" field to the "to" field, so it
          // mirrors in RTL; stacked layouts point downward.
          wide
              ? (isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded)
              : Icons.arrow_downward_rounded,
          color: taj.textSecondary,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fromField),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: arrow),
                Expanded(child: toField),
              ],
            )
          else ...[
            fromField,
            Center(child: arrow),
            toField,
          ],
          const SizedBox(height: 16),
          _LabeledField(
            label: 'المبلغ',
            child: TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppThemes.numeralStyle(ctx, fontSize: 16),
              decoration: const InputDecoration(hintText: '0', suffixText: 'د.ل'),
            ),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'المرجع (اختياري)',
            child: TextField(
              controller: refCtrl,
              decoration: const InputDecoration(hintText: 'رقم السند'),
            ),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'البيان (اختياري)',
            child: TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'وصف الحركة…'),
            ),
          ),
        ],
      );
    },
    actions: (ctx) => [
      TextButton(
          onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: () async {
          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
          final messenger = ScaffoldMessenger.of(ctx);
          final navigator = Navigator.of(ctx);
          final success = ctx.taj.success.dark;
          try {
            await store.transferBetweenAccounts(
              fromAccountId: from,
              toAccountId: to,
              amount: amount,
              reference: refCtrl.text.trim(),
              description: noteCtrl.text.trim(),
            );
          } on StateError catch (e) {
            messenger.showSnackBar(SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(e.message)));
            return;
          }
          navigator.pop();
          messenger.showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: success,
            content: const Text('تم تنفيذ التحويل'),
          ));
        },
        child: const Text('تحويل'),
      ),
    ],
  );

  amountCtrl.dispose();
  refCtrl.dispose();
  noteCtrl.dispose();
}

Future<void> showTreasuryMovementDialog(
  BuildContext context,
  DemoStore store, {
  String? presetAccount,
  bool deposit = true,
}) async {
  if (store.accounts.isEmpty) return;
  String account = presetAccount ?? store.accounts.first.id;
  bool isDeposit = deposit;
  final amountCtrl = TextEditingController();
  final refCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  await _treasuryDialog<void>(
    context,
    title: 'حركة جديدة',
    body: (ctx, setLocal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledField(
            label: 'نوع الحركة',
            child: Row(
              children: [
                Expanded(
                  child: _ChoicePill(
                    label: 'إيداع',
                    icon: Icons.south_rounded,
                    selected: isDeposit,
                    status: TajStatus.success,
                    onTap: () => setLocal(() => isDeposit = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChoicePill(
                    label: 'سحب',
                    icon: Icons.north_rounded,
                    selected: !isDeposit,
                    status: TajStatus.error,
                    onTap: () => setLocal(() => isDeposit = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'الحساب',
            child: _AccountDropdown(
              accounts: store.accounts,
              value: account,
              onChanged: (v) => setLocal(() => account = v),
            ),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'المبلغ',
            child: TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppThemes.numeralStyle(ctx, fontSize: 16),
              decoration: const InputDecoration(hintText: '0', suffixText: 'د.ل'),
            ),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'المرجع (اختياري)',
            child: TextField(
              controller: refCtrl,
              decoration: const InputDecoration(hintText: 'رقم السند'),
            ),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'البيان (اختياري)',
            child: TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'وصف الحركة…'),
            ),
          ),
        ],
      );
    },
    actions: (ctx) => [
      TextButton(
          onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: () async {
          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
          final messenger = ScaffoldMessenger.of(ctx);
          final navigator = Navigator.of(ctx);
          final success = ctx.taj.success.dark;
          if (amount <= 0) {
            messenger.showSnackBar(const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('المبلغ غير صالح')));
            return;
          }
          await store.addTreasuryMovement(DemoTreasuryMovement(
            id: 'MOV-${DateTime.now().microsecondsSinceEpoch}',
            accountId: account,
            type: isDeposit
                ? DemoMovementType.deposit
                : DemoMovementType.withdraw,
            amount: amount,
            date: DateTime.now(),
            isInflow: isDeposit,
            reference: refCtrl.text.trim(),
            description: noteCtrl.text.trim(),
          ));
          navigator.pop();
          messenger.showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: success,
            content: const Text('تم حفظ الحركة'),
          ));
        },
        child: const Text('حفظ'),
      ),
    ],
  );

  amountCtrl.dispose();
  refCtrl.dispose();
  noteCtrl.dispose();
}

Future<void> showTreasuryReconcileDialog(
    BuildContext context, DemoStore store, String accountId) async {
  await _treasuryDialog<void>(
    context,
    title: 'تسوية كشف الحساب',
    body: (ctx, setLocal) {
      final account = store.accounts.firstWhere((a) => a.id == accountId);
      final movements = store.treasuryMovements
          .where((m) => m.accountId == accountId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final book = store.accountBalance(accountId);
      final statement = store.reconciledBalance(accountId);
      final diff = book - statement;
      final wide = MediaQuery.sizeOf(ctx).width >= AppBreakpoints.tablet;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(account.name,
              style: Theme.of(ctx).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _ReconTotal(label: 'رصيد الدفاتر', value: book),
              _ReconTotal(label: 'رصيد الكشف', value: statement),
              _ReconTotal(
                  label: 'الفرق',
                  value: diff,
                  warn: diff.abs() > 0.005),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: ctx.taj.divider),
          const SizedBox(height: 12),
          if (wide)
            _ReconTwoColumns(
              movements: movements,
              onToggle: (id, v) async {
                await store.setMovementReconciled(id, v);
                setLocal(() {});
              },
            )
          else
            _ReconCardList(
              movements: movements,
              onToggle: (id, v) async {
                await store.setMovementReconciled(id, v);
                setLocal(() {});
              },
            ),
        ],
      );
    },
    actions: (ctx) => [
      FilledButton(
          onPressed: () => Navigator.of(ctx).pop(), child: const Text('تم')),
    ],
  );
}

class _ReconTotal extends StatelessWidget {
  const _ReconTotal(
      {required this.label, required this.value, this.warn = false});
  final String label;
  final double value;
  final bool warn;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: taj.textSecondary)),
        const SizedBox(height: 2),
        _Amount(
          value: value,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          maxLines: 2,
          showSign: value < 0,
          color: warn ? taj.warning.dark : taj.textPrimary,
        ),
      ],
    );
  }
}

class _ReconTwoColumns extends StatelessWidget {
  const _ReconTwoColumns({required this.movements, required this.onToggle});
  final List<DemoTreasuryMovement> movements;
  final void Function(String id, bool value) onToggle;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('الدفاتر', style: text.labelLarge),
              const SizedBox(height: 8),
              for (final m in movements)
                _ReconRow(movement: m, onToggle: onToggle),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('كشف الحساب', style: text.labelLarge),
              const SizedBox(height: 8),
              for (final m in movements.where((m) => m.reconciled))
                _ReconRow(movement: m, onToggle: onToggle, statementSide: true),
              if (!movements.any((m) => m.reconciled))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('لا حركات مطابَقة بعد',
                      style: text.bodySmall
                          ?.copyWith(color: context.taj.textDisabled)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReconCardList extends StatelessWidget {
  const _ReconCardList({required this.movements, required this.onToggle});
  final List<DemoTreasuryMovement> movements;
  final void Function(String id, bool value) onToggle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in movements) ...[
          _ReconRow(movement: m, onToggle: onToggle, card: true),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ReconRow extends StatelessWidget {
  const _ReconRow({
    required this.movement,
    required this.onToggle,
    this.statementSide = false,
    this.card = false,
  });
  final DemoTreasuryMovement movement;
  final void Function(String id, bool value) onToggle;
  final bool statementSide;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final matched = movement.reconciled;
    final content = Row(
      children: [
        Icon(
          matched ? Icons.check_circle_rounded : Icons.pending_outlined,
          size: 18,
          color: matched ? taj.success.main : taj.warning.dark,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                movement.description.isEmpty
                    ? _fmtDate(movement.date)
                    : movement.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(_fmtDate(movement.date),
                  style: AppThemes.numeralStyle(context,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: taj.textDisabled)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _Amount(
          value: movement.amount,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          leadingSign: movement.isInflow ? '+' : '−',
          color: taj.accentFor(movement.isInflow ? taj.success : taj.error),
        ),
        if (!statementSide) ...[
          const SizedBox(width: 4),
          Switch(
            value: matched,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => onToggle(movement.id, v),
          ),
        ],
      ],
    );
    if (!card) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: content);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: taj.divider),
      ),
      child: content,
    );
  }
}

// --- shared form widgets ----------------------------------------------------

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        child,
      ],
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.accounts,
    required this.value,
    required this.onChanged,
  });
  final List<DemoAccount> accounts;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: [
        for (final a in accounts)
          DropdownMenuItem(
            value: a.id,
            child: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.status,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final TajStatus status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final swatch = taj.swatch(status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? swatch.lighter : taj.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? swatch.main : taj.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? swatch.dark : taj.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? swatch.dark : taj.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
