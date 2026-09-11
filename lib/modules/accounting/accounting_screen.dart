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

/// The accounting workspace: chart of accounts, account detail, journal, the
/// double-entry editor/viewer, general ledger, trial balance, financial
/// statements, entry actions (post/reverse/approve/review) and the audit log.
///
/// Financially critical, so **numbers are shown in full, never truncated and
/// never hidden** — long figures go compact with the exact value one tap/hover
/// away, amount columns are never dropped, and every financial table scrolls
/// horizontally (with a frozen first column + sticky header) rather than
/// clipping. Fully responsive 320px→4K, portrait/landscape, RTL/LTR; all
/// thresholds are named constants on [AppBreakpoints].
class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});
  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

enum _Section { coa, journal, ledger, trial, statements, audit }

const _sectionLabels = {
  _Section.coa: 'دليل الحسابات',
  _Section.journal: 'اليومية',
  _Section.ledger: 'دفتر الأستاذ',
  _Section.trial: 'ميزان المراجعة',
  _Section.statements: 'القوائم المالية',
  _Section.audit: 'سجل التدقيق',
};

const _sectionIcons = {
  _Section.coa: Icons.account_tree_outlined,
  _Section.journal: Icons.menu_book_outlined,
  _Section.ledger: Icons.receipt_long_outlined,
  _Section.trial: Icons.balance_outlined,
  _Section.statements: Icons.insert_chart_outlined,
  _Section.audit: Icons.history_outlined,
};

/// Content-fit thresholds local to the accounting screen (not screen
/// breakpoints — those live in [AppBreakpoints]).

/// A tree row shows the account code inline before the name when its own
/// available width is at least this; below it the code drops to a second line
/// so a long code (deep account) never clips the name.
const double _coaInlineCodeMinWidth = 200;

/// Combined before/after character count past which an audit-log card offers a
/// "show more" expansion instead of clamping to two lines.
const int _auditExpandThreshold = 60;

class _AccountingScreenState extends State<AccountingScreen> {
  _Section _section = _Section.coa;

  // Chart-of-accounts state. The deep 12→…→120301010101 branch is expanded so
  // its level-6 name exercises the capped-indent layout out of the box.
  final Set<String> _expanded = {
    '1', '11', '12', '2', '3', '4', '5',
    '1203', '120301', '12030101', '1203010101',
  };
  String? _coaSelected;
  String? _coaDetailPushed; // phone: pushed detail account id

  // Journal state.
  String? _journalSelected;

  // Ledger state.
  String? _ledgerAccount;

  // Statements sub-tab.
  int _statementTab = 0;

  // Filters (shared where relevant).
  String? _statusFilter; // null | draft | posted | reversed
  String _periodFilter = 'all';

  DemoStore get _store => DemoStoreProvider.of(context);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (_, __) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final taj = context.taj;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth;
          final height = c.maxHeight;
          return PageContainer(
            maxWidth: AppBreakpoints.accountingContentMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionBar(
                  current: _section,
                  onSelect: (s) => setState(() => _section = s),
                ),
                Divider(height: 1, color: taj.divider),
                Expanded(child: _sectionBody(width, height)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionBody(double width, double height) {
    switch (_section) {
      case _Section.coa:
        return _CoaSection(
          store: _store,
          width: width,
          height: height,
          expanded: _expanded,
          selected: _coaSelected,
          detailPushed: _coaDetailPushed,
          onToggleExpand: (id) => setState(() {
            _expanded.contains(id)
                ? _expanded.remove(id)
                : _expanded.add(id);
          }),
          onSelect: (id) => setState(() {
            _coaSelected = id;
            if (width < AppBreakpoints.coaSplit) _coaDetailPushed = id;
          }),
          onBack: () => setState(() => _coaDetailPushed = null),
          onOpenEntry: (e) => _openEntryViewer(e),
        );
      case _Section.journal:
        return _JournalSection(
          store: _store,
          width: width,
          height: height,
          selected: _journalSelected,
          statusFilter: _statusFilter,
          periodFilter: _periodFilter,
          onSelect: (id) => setState(() => _journalSelected = id),
          onStatus: (v) => setState(() => _statusFilter = v),
          onPeriod: (v) => setState(() => _periodFilter = v),
          onNew: () => _openEntryEditor(),
          onOpenEntry: (e) => _openEntryViewer(e),
        );
      case _Section.ledger:
        return _LedgerSection(
          store: _store,
          width: width,
          account: _ledgerAccount,
          onAccount: (id) => setState(() => _ledgerAccount = id),
        );
      case _Section.trial:
        return _TrialBalanceSection(store: _store, width: width);
      case _Section.statements:
        return _StatementsSection(
          store: _store,
          width: width,
          tab: _statementTab,
          onTab: (i) => setState(() => _statementTab = i),
        );
      case _Section.audit:
        return _AuditSection(store: _store, width: width);
    }
  }

  Future<void> _openEntryEditor() =>
      showEntryEditorDialog(context, _store);

  Future<void> _openEntryViewer(DemoJournalEntry entry) =>
      showEntryViewerDialog(context, _store, entry.id);
}

// ===========================================================================
// Section navigation bar
// ===========================================================================

class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.current, required this.onSelect});
  final _Section current;
  final ValueChanged<_Section> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final s in _Section.values) ...[
            _SectionChip(
              label: _sectionLabels[s]!,
              icon: _sectionIcons[s]!,
              selected: s == current,
              onTap: () => onSelect(s),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Material(
      color: selected ? taj.primary.lighter : taj.paper,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? taj.primary.light : taj.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 17,
                  color: selected ? taj.primary.dark : taj.textSecondary),
              const SizedBox(width: 7),
              Text(label,
                  style: text.labelLarge?.copyWith(
                      color:
                          selected ? taj.primary.dark : taj.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Chart of accounts + detail (master-detail: 1 / 2 / 3 panes)
// ===========================================================================

class _CoaSection extends StatelessWidget {
  const _CoaSection({
    required this.store,
    required this.width,
    required this.height,
    required this.expanded,
    required this.selected,
    required this.detailPushed,
    required this.onToggleExpand,
    required this.onSelect,
    required this.onBack,
    required this.onOpenEntry,
  });
  final DemoStore store;
  final double width;
  final double height;
  final Set<String> expanded;
  final String? selected;
  final String? detailPushed;
  final ValueChanged<String> onToggleExpand;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final ValueChanged<DemoJournalEntry> onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final single = width < AppBreakpoints.coaSplit;
    final threePane = width >= AppBreakpoints.threePane && height >= AppBreakpoints.threePaneMinHeight;

    final tree = _CoaTree(
      store: store,
      expanded: expanded,
      selected: single ? null : selected,
      onToggleExpand: onToggleExpand,
      onSelect: onSelect,
    );

    if (single) {
      // Full-page tree; tapping an account "pushes" a detail page.
      if (detailPushed != null) {
        final acc = store.ledgerAccountById(detailPushed!);
        return _AccountDetail(
          store: store,
          account: acc,
          onBack: onBack,
          onOpenEntry: onOpenEntry,
          showBack: true,
        );
      }
      return tree;
    }

    final treePaneWidth = (width * 0.28)
        .clamp(AppBreakpoints.coaTreePaneMin, AppBreakpoints.coaTreePaneMax)
        .toDouble();
    final acc = selected == null ? null : store.ledgerAccountById(selected!);

    if (threePane) {
      // tree | account detail + entries | selected entry preview
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: treePaneWidth, child: tree),
          Container(width: 1, color: taj.divider),
          Expanded(
            flex: 3,
            child: _AccountDetail(
              store: store,
              account: acc,
              onBack: onBack,
              onOpenEntry: onOpenEntry,
              showBack: false,
            ),
          ),
        ],
      );
    }

    // Two panes.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: treePaneWidth, child: tree),
        Container(width: 1, color: taj.divider),
        Expanded(
          child: _AccountDetail(
            store: store,
            account: acc,
            onBack: onBack,
            onOpenEntry: onOpenEntry,
            showBack: false,
          ),
        ),
      ],
    );
  }
}

class _CoaTree extends StatelessWidget {
  const _CoaTree({
    required this.store,
    required this.expanded,
    required this.selected,
    required this.onToggleExpand,
    required this.onSelect,
  });
  final DemoStore store;
  final Set<String> expanded;
  final String? selected;
  final ValueChanged<String> onToggleExpand;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void walk(String? parentId, int depth) {
      for (final a in store.ledgerChildren(parentId)) {
        final hasChildren = !store.isLeafAccount(a.id);
        final isOpen = expanded.contains(a.id);
        rows.add(_CoaTreeRow(
          account: a,
          depth: depth,
          balance: store.ledgerBalance(a.id),
          hasChildren: hasChildren,
          expanded: isOpen,
          selected: a.id == selected,
          onToggle: () => onToggleExpand(a.id),
          onTap: () => onSelect(a.id),
        ));
        if (hasChildren && isOpen) walk(a.id, depth + 1);
      }
    }

    walk(null, 0);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: rows,
    );
  }
}

class _CoaTreeRow extends StatelessWidget {
  const _CoaTreeRow({
    required this.account,
    required this.depth,
    required this.balance,
    required this.hasChildren,
    required this.expanded,
    required this.selected,
    required this.onToggle,
    required this.onTap,
  });
  final DemoLedgerAccount account;
  final int depth;
  final double balance;
  final bool hasChildren;
  final bool expanded;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    // Cap the indent so a level-6 name is never pushed off-screen.
    final indent = math.min(depth * 16.0, 64.0);

    final nameText = Text(
      account.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.bodyMedium?.copyWith(
          fontWeight: hasChildren ? FontWeight.w700 : FontWeight.w500),
    );

    return Material(
      color: selected ? taj.primary.lighter : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
              start: 8 + indent, end: 10, top: 8, bottom: 8),
          child: Row(
            children: [
              // Expand / collapse toggle (or a spacer for leaves).
              SizedBox(
                width: 26,
                child: hasChildren
                    ? InkWell(
                        onTap: onToggle,
                        borderRadius: BorderRadius.circular(6),
                        child: Icon(
                            expanded
                                ? Icons.expand_more_rounded
                                : Icons.chevron_left_rounded,
                            size: 20,
                            color: taj.textSecondary),
                      )
                    : const SizedBox.shrink(),
              ),
              // Code + name. When the available width is tight (deep level in a
              // narrow pane, or a phone) the code drops onto a second line and
              // is allowed to abbreviate (full code in its tooltip); otherwise
              // it sits inline. Either way the name ellipsizes and the code is
              // never simply clipped off-screen.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, cc) {
                    final inline = cc.maxWidth >= _coaInlineCodeMinWidth;
                    if (inline) {
                      return Row(
                        children: [
                          Flexible(child: _CodeChip(account.code)),
                          const SizedBox(width: 8),
                          Expanded(child: nameText),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        nameText,
                        const SizedBox(height: 2),
                        Row(
                          children: [Flexible(child: _CodeChip(account.code))],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Balance is always visible.
              _Money(
                value: balance,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                maxChars: 12,
                color: balance < 0 ? taj.accentFor(taj.error) : taj.textPrimary,
                showSign: balance < 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip(this.code);
  final String code;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    // The Text ellipsizes only when a bounded (Flexible/Expanded) parent forces
    // it to — the full code is always in the tooltip, so a very long code is
    // abbreviated in tight panes but never lost. In roomy contexts it shows in
    // full at its intrinsic width.
    return Tooltip(
      message: code,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: taj.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: taj.divider),
        ),
        child: Text(code,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.numeralStyle(context,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: taj.textSecondary)),
      ),
    );
  }
}

class _AccountDetail extends StatelessWidget {
  const _AccountDetail({
    required this.store,
    required this.account,
    required this.onBack,
    required this.onOpenEntry,
    required this.showBack,
  });
  final DemoStore store;
  final DemoLedgerAccount? account;
  final VoidCallback onBack;
  final ValueChanged<DemoJournalEntry> onOpenEntry;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    if (account == null) {
      return const TajEmptyState(
        icon: Icons.account_tree_outlined,
        title: 'اختر حسابًا',
        message: 'اختر حسابًا من الدليل لعرض تفاصيله وحركته.',
      );
    }
    final a = account!;
    final (debit, credit) = store.ledgerDebitCredit(a.id);
    final balance = debit - credit;
    final entries = store.entriesTouching(a.id).reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              if (showBack)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    tooltip: 'رجوع',
                  ),
                ),
              _CodeChip(a.code),
              const SizedBox(width: 10),
              Expanded(
                child: Text(a.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium),
              ),
              const SizedBox(width: 8),
              _AccountTypeChip(a.type),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _Kv(label: 'إجمالي مدين', value: debit, swatch: taj.success),
              _Kv(label: 'إجمالي دائن', value: credit, swatch: taj.info),
              _Kv(
                  label: 'الرصيد',
                  value: balance,
                  swatch: balance < 0 ? taj.error : taj.primary,
                  showSign: true),
            ],
          ),
        ),
        Divider(height: 1, color: taj.divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('الحركة (${entries.length})', style: text.titleSmall),
        ),
        Expanded(
          child: entries.isEmpty
              ? const TajEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'لا حركة',
                  message: 'لا توجد قيود مُرحّلة على هذا الحساب.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    final line =
                        e.lines.firstWhere((l) => l.accountId == a.id);
                    return _AccountMovementCard(
                      entry: e,
                      line: line,
                      onTap: () => onOpenEntry(e),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv(
      {required this.label,
      required this.value,
      required this.swatch,
      this.showSign = false});
  final String label;
  final double value;
  final TajSwatch swatch;
  final bool showSign;
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
        _Money(
            value: value,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            maxLines: 2,
            showSign: showSign,
            color: taj.accentFor(swatch)),
      ],
    );
  }
}

class _AccountMovementCard extends StatelessWidget {
  const _AccountMovementCard(
      {required this.entry, required this.line, required this.onTap});
  final DemoJournalEntry entry;
  final DemoJournalLine line;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final isDebit = line.debit > 0;
    return TajCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(entry.number,
                        style: AppThemes.numeralStyle(context,
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    _EntryStatusBadge(entry: entry),
                  ],
                ),
                const SizedBox(height: 4),
                Text(entry.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: taj.textSecondary)),
                const SizedBox(height: 4),
                Text(_fmtDate(entry.date),
                    style: AppThemes.numeralStyle(context,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: taj.textDisabled)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isDebit ? 'مدين' : 'دائن',
                  style: text.bodySmall?.copyWith(
                      color: isDebit
                          ? taj.accentFor(taj.success)
                          : taj.accentFor(taj.info))),
              const SizedBox(height: 2),
              _Money(
                value: isDebit ? line.debit : line.credit,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDebit
                    ? taj.accentFor(taj.success)
                    : taj.accentFor(taj.info),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Journal (entry list + three-pane preview)
// ===========================================================================

class _JournalSection extends StatelessWidget {
  const _JournalSection({
    required this.store,
    required this.width,
    required this.height,
    required this.selected,
    required this.statusFilter,
    required this.periodFilter,
    required this.onSelect,
    required this.onStatus,
    required this.onPeriod,
    required this.onNew,
    required this.onOpenEntry,
  });
  final DemoStore store;
  final double width;
  final double height;
  final String? selected;
  final String? statusFilter;
  final String periodFilter;
  final ValueChanged<String> onSelect;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String> onPeriod;
  final VoidCallback onNew;
  final ValueChanged<DemoJournalEntry> onOpenEntry;

  List<DemoJournalEntry> _filtered() {
    final now = DateTime.now();
    bool inPeriod(DateTime d) {
      switch (periodFilter) {
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

    return store.journalEntries.where((e) {
      if (statusFilter == 'draft' && e.status != DemoEntryStatus.draft) {
        return false;
      }
      if (statusFilter == 'posted' && e.status != DemoEntryStatus.posted) {
        return false;
      }
      if (statusFilter == 'reversed' && e.status != DemoEntryStatus.reversed) {
        return false;
      }
      return inPeriod(e.date);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final entries = _filtered();
    final threePane = width >= AppBreakpoints.threePane && height >= AppBreakpoints.threePaneMinHeight;

    final list = _JournalList(
      store: store,
      entries: entries,
      width: width,
      selected: threePane ? selected : null,
      statusFilter: statusFilter,
      periodFilter: periodFilter,
      onStatus: onStatus,
      onPeriod: onPeriod,
      onNew: onNew,
      onOpenEntry: threePane ? (e) => onSelect(e.id) : onOpenEntry,
    );

    if (!threePane) return list;

    final sel = selected == null
        ? null
        : entries.where((e) => e.id == selected).isNotEmpty
            ? entries.firstWhere((e) => e.id == selected)
            : null;
    // Three panes: (filters+list) | entry preview. The tree lives in the COA
    // section; here the "three panes" collapse to list + preview which is the
    // useful split for the journal.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: list),
        Container(width: 1, color: taj.divider),
        Expanded(
          flex: 2,
          child: sel == null
              ? const TajEmptyState(
                  icon: Icons.description_outlined,
                  title: 'اختر قيدًا',
                  message: 'اختر قيدًا من القائمة لمعاينته.')
              : _EntryPreview(store: store, entry: sel),
        ),
      ],
    );
  }
}

class _JournalList extends StatelessWidget {
  const _JournalList({
    required this.store,
    required this.entries,
    required this.width,
    required this.selected,
    required this.statusFilter,
    required this.periodFilter,
    required this.onStatus,
    required this.onPeriod,
    required this.onNew,
    required this.onOpenEntry,
  });
  final DemoStore store;
  final List<DemoJournalEntry> entries;
  final double width;
  final String? selected;
  final String? statusFilter;
  final String periodFilter;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String> onPeriod;
  final VoidCallback onNew;
  final ValueChanged<DemoJournalEntry> onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final phone = width < AppBreakpoints.phone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'اليومية',
          subtitle: 'قائمة القيود',
          primary: _PrimaryAction(
            icon: Icons.add_rounded,
            label: 'قيد جديد',
            onTap: onNew,
          ),
          actions: [
            _ActionSpec(Icons.print_outlined, 'طباعة', () {}),
            _ActionSpec(Icons.download_outlined, 'تصدير', () {}),
          ],
          width: width,
          filters: _JournalFilters(
            statusFilter: statusFilter,
            periodFilter: periodFilter,
            onStatus: onStatus,
            onPeriod: onPeriod,
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const TajEmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'لا قيود',
                  message: 'لا توجد قيود مطابقة للفلاتر الحالية.')
              : phone
                  ? _JournalCards(
                      store: store,
                      entries: entries,
                      onOpenEntry: onOpenEntry)
                  : _JournalTable(
                      store: store,
                      entries: entries,
                      selected: selected,
                      onOpenEntry: onOpenEntry),
        ),
      ],
    );
  }
}

class _JournalFilters extends StatelessWidget {
  const _JournalFilters({
    required this.statusFilter,
    required this.periodFilter,
    required this.onStatus,
    required this.onPeriod,
  });
  final String? statusFilter;
  final String periodFilter;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String> onPeriod;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterPill<String?>(
          icon: Icons.flag_outlined,
          value: statusFilter,
          options: const [
            (null, 'كل الحالات'),
            ('draft', 'مسودة'),
            ('posted', 'مُرحّل'),
            ('reversed', 'معكوس'),
          ],
          onSelected: onStatus,
        ),
        _FilterPill<String>(
          icon: Icons.calendar_today_outlined,
          value: periodFilter,
          options: const [
            ('all', 'كل الفترات'),
            ('today', 'اليوم'),
            ('week', 'آخر 7 أيام'),
            ('month', 'هذا الشهر'),
          ],
          onSelected: onPeriod,
        ),
      ],
    );
  }
}

class _JournalCards extends StatelessWidget {
  const _JournalCards(
      {required this.store, required this.entries, required this.onOpenEntry});
  final DemoStore store;
  final List<DemoJournalEntry> entries;
  final ValueChanged<DemoJournalEntry> onOpenEntry;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = entries[i];
        return TajCard(
          onTap: () => onOpenEntry(e),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(e.number,
                      style: AppThemes.numeralStyle(context,
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  _EntryStatusBadge(entry: e),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(_fmtDate(e.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppThemes.numeralStyle(context,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: taj.textSecondary)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(e.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium),
              const SizedBox(height: 8),
              Divider(height: 1, color: taj.divider),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MiniAmount(
                      label: 'مدين', value: e.totalDebit, swatch: taj.success),
                  _MiniAmount(
                      label: 'دائن', value: e.totalCredit, swatch: taj.info),
                  if (!e.isBalanced) _DiffBadge(diff: e.difference),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniAmount extends StatelessWidget {
  const _MiniAmount(
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
        _Money(
            value: value,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: taj.accentFor(swatch)),
      ],
    );
  }
}

class _JournalTable extends StatelessWidget {
  const _JournalTable({
    required this.store,
    required this.entries,
    required this.selected,
    required this.onOpenEntry,
  });
  final DemoStore store;
  final List<DemoJournalEntry> entries;
  final String? selected;
  final ValueChanged<DemoJournalEntry> onOpenEntry;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: _FinTable(
        frozenCol: const _FinCol('رقم القيد', 116),
        restCols: const [
          _FinCol('التاريخ', 104),
          _FinCol('البيان', 220),
          _FinCol('الحالة', 108),
          _FinCol('مدين', 132, numeric: true),
          _FinCol('دائن', 132, numeric: true),
        ],
        rows: [
          for (final e in entries)
            _FinRow(
              onTap: () => onOpenEntry(e),
              selected: e.id == selected,
              frozen: Text(e.number,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.numeralStyle(context,
                      fontSize: 13, fontWeight: FontWeight.w700)),
              cells: [
                Text(_fmtDate(e.date),
                    style: AppThemes.numeralStyle(context,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: taj.textSecondary)),
                Text(e.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall),
                _EntryStatusBadge(entry: e),
                _Money(
                    value: e.totalDebit,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    maxChars: 12,
                    color: taj.accentFor(taj.success)),
                _Money(
                    value: e.totalCredit,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    maxChars: 12,
                    color: taj.accentFor(taj.info)),
              ],
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// General ledger
// ===========================================================================

class _LedgerSection extends StatelessWidget {
  const _LedgerSection(
      {required this.store, required this.width, required this.account, required this.onAccount});
  final DemoStore store;
  final double width;
  final String? account;
  final ValueChanged<String> onAccount;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final leaves = store.ledgerAccounts.where((a) => store.isLeafAccount(a.id)).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    final accId = (account != null && leaves.any((a) => a.id == account))
        ? account!
        : (leaves.isNotEmpty ? leaves.first.id : null);
    if (accId == null) {
      return const TajEmptyState(
          icon: Icons.receipt_long_outlined, title: 'لا حسابات');
    }
    final acc = store.ledgerAccountById(accId)!;
    final entries = store.entriesTouching(accId);
    // Build rows with a running balance.
    var running = 0.0;
    final rows = <_FinRow>[];
    for (final e in entries) {
      for (final l in e.lines.where((l) => l.accountId == accId)) {
        running += l.debit - l.credit;
        rows.add(_FinRow(
          frozen: Text(e.number,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemes.numeralStyle(context,
                  fontSize: 13, fontWeight: FontWeight.w700)),
          cells: [
            Text(_fmtDate(e.date),
                style: AppThemes.numeralStyle(context,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: taj.textSecondary)),
            Text(l.description.isEmpty ? e.description : l.description,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall),
            l.debit > 0
                ? _Money(
                    value: l.debit,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    maxChars: 12,
                    color: taj.accentFor(taj.success))
                : const _Dash(),
            l.credit > 0
                ? _Money(
                    value: l.credit,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    maxChars: 12,
                    color: taj.accentFor(taj.info))
                : const _Dash(),
            _Money(
                value: running,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                maxChars: 12,
                showSign: running < 0,
                color: running < 0 ? taj.accentFor(taj.error) : taj.textPrimary),
          ],
        ));
      }
    }
    final (td, tc) = store.ledgerDebitCredit(accId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('دفتر الأستاذ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium),
              ),
              const SizedBox(width: 8),
              _AccountPickerButton(
                store: store,
                selectedId: accId,
                onPick: onAccount,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              _CodeChip(acc.code),
              const SizedBox(width: 8),
              Expanded(
                child: Text(acc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: rows.isEmpty
                ? const TajEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'لا حركة',
                    message: 'لا توجد قيود على هذا الحساب.')
                : _FinTable(
                    frozenCol: const _FinCol('رقم القيد', 116),
                    restCols: const [
                      _FinCol('التاريخ', 104),
                      _FinCol('البيان', 200),
                      _FinCol('مدين', 128, numeric: true),
                      _FinCol('دائن', 128, numeric: true),
                      _FinCol('الرصيد الجاري', 140, numeric: true),
                    ],
                    rows: rows,
                    totals: _FinRow(
                      emphasize: true,
                      frozen: Text('الإجمالي',
                          style: text.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      cells: [
                        const SizedBox.shrink(),
                        const SizedBox.shrink(),
                        _Money(
                            value: td,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            maxChars: 12,
                            color: taj.accentFor(taj.success)),
                        _Money(
                            value: tc,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            maxChars: 12,
                            color: taj.accentFor(taj.info)),
                        _Money(
                            value: td - tc,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            maxChars: 12,
                            showSign: (td - tc) < 0,
                            color: (td - tc) < 0
                                ? taj.accentFor(taj.error)
                                : taj.textPrimary),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Trial balance
// ===========================================================================

class _TrialBalanceSection extends StatelessWidget {
  const _TrialBalanceSection({required this.store, required this.width});
  final DemoStore store;
  final double width;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final leaves = store.ledgerAccounts.where((a) => store.isLeafAccount(a.id)).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    var totalDebit = 0.0, totalCredit = 0.0;
    final rows = <_FinRow>[];
    for (final a in leaves) {
      final (d, c) = store.ledgerDebitCredit(a.id);
      if (d == 0 && c == 0) continue;
      final bal = d - c;
      final debitBal = bal > 0 ? bal : 0.0;
      final creditBal = bal < 0 ? -bal : 0.0;
      totalDebit += debitBal;
      totalCredit += creditBal;
      rows.add(_FinRow(
        frozen: Row(
          children: [
            _CodeChip(a.code),
            const SizedBox(width: 8),
            Expanded(
              child: Text(a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium),
            ),
          ],
        ),
        cells: [
          debitBal > 0
              ? _Money(
                  value: debitBal,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  maxChars: 12,
                  color: taj.accentFor(taj.success))
              : const _Dash(),
          creditBal > 0
              ? _Money(
                  value: creditBal,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  maxChars: 12,
                  color: taj.accentFor(taj.info))
              : const _Dash(),
        ],
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('ميزان المراجعة',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium),
              ),
              const SizedBox(width: 8),
              _MiniIconButton(icon: Icons.print_outlined, onTap: () {}),
              const SizedBox(width: 8),
              _MiniIconButton(icon: Icons.download_outlined, onTap: () {}),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _FinTable(
              frozenCol: const _FinCol('الحساب', 220),
              restCols: const [
                _FinCol('مدين', 150, numeric: true),
                _FinCol('دائن', 150, numeric: true),
              ],
              rows: rows,
              totals: _FinRow(
                emphasize: true,
                frozen: Text('الإجمالي',
                    style:
                        text.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                cells: [
                  _Money(
                      value: totalDebit,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      maxChars: 12,
                      color: taj.accentFor(taj.success)),
                  _Money(
                      value: totalCredit,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      maxChars: 12,
                      color: taj.accentFor(taj.info)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Financial statements
// ===========================================================================

class _StatementsSection extends StatelessWidget {
  const _StatementsSection(
      {required this.store,
      required this.width,
      required this.tab,
      required this.onTab});
  final DemoStore store;
  final double width;
  final int tab;
  final ValueChanged<int> onTab;

  double _typeTotal(DemoLedgerAccountType t) {
    var sum = 0.0;
    for (final a in store.ledgerAccounts.where((a) => a.parentId == null)) {
      if (a.type == t) sum += store.ledgerBalance(a.id);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const tabs = ['قائمة الدخل', 'المركز المالي', 'التدفقات النقدية', 'الأرباح والخسائر'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('القوائم المالية', style: text.titleMedium),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                _SubTab(label: tabs[i], selected: i == tab, onTap: () => onTab(i)),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _statement(context),
          ),
        ),
      ],
    );
  }

  Widget _statement(BuildContext context) {
    switch (tab) {
      case 0:
        return _incomeStatement(context);
      case 1:
        return _balanceSheet(context);
      case 2:
        return _cashFlow(context);
      default:
        return _profitAndLoss(context);
    }
  }

  Widget _incomeStatement(BuildContext context) {
    final revenue = _typeTotal(DemoLedgerAccountType.revenue).abs();
    final expenses = _typeTotal(DemoLedgerAccountType.expense).abs();
    final net = revenue - expenses;
    return _StatementList(rows: [
      _StmtRow('الإيرادات', null, header: true),
      ..._leafRows(context, DemoLedgerAccountType.revenue),
      _StmtRow('إجمالي الإيرادات', revenue, total: true),
      _StmtRow('المصروفات', null, header: true),
      ..._leafRows(context, DemoLedgerAccountType.expense),
      _StmtRow('إجمالي المصروفات', expenses, total: true),
      _StmtRow('صافي الربح', net, grand: true),
    ]);
  }

  Widget _balanceSheet(BuildContext context) {
    final assets = _typeTotal(DemoLedgerAccountType.asset);
    final liabilities = _typeTotal(DemoLedgerAccountType.liability).abs();
    final equity = _typeTotal(DemoLedgerAccountType.equity).abs();
    final revenue = _typeTotal(DemoLedgerAccountType.revenue).abs();
    final expenses = _typeTotal(DemoLedgerAccountType.expense).abs();
    final netIncome = revenue - expenses;
    return _StatementList(rows: [
      _StmtRow('الأصول', null, header: true),
      ..._leafRows(context, DemoLedgerAccountType.asset),
      _StmtRow('إجمالي الأصول', assets, total: true),
      _StmtRow('الخصوم', null, header: true),
      ..._leafRows(context, DemoLedgerAccountType.liability),
      _StmtRow('إجمالي الخصوم', liabilities, total: true),
      _StmtRow('حقوق الملكية', null, header: true),
      ..._leafRows(context, DemoLedgerAccountType.equity),
      _StmtRow('صافي ربح الفترة', netIncome),
      _StmtRow('إجمالي حقوق الملكية', equity + netIncome, total: true),
      _StmtRow('إجمالي الخصوم وحقوق الملكية', liabilities + equity + netIncome,
          grand: true),
    ]);
  }

  Widget _cashFlow(BuildContext context) {
    // Simplified: net change in cash/bank leaf accounts, categorised by the
    // counterparty account type on the other lines of each entry.
    final cashIds = store.ledgerAccounts
        .where((a) =>
            store.isLeafAccount(a.id) &&
            (a.code == '1101' || a.code.startsWith('1102')))
        .map((a) => a.id)
        .toSet();
    var operating = 0.0, investing = 0.0, financing = 0.0;
    for (final e in store.journalEntries) {
      if (e.status == DemoEntryStatus.draft) continue;
      final cashDelta = e.lines
          .where((l) => cashIds.contains(l.accountId))
          .fold<double>(0, (s, l) => s + (l.debit - l.credit));
      if (cashDelta == 0) continue;
      // Dominant non-cash line type.
      DemoLedgerAccountType? t;
      for (final l in e.lines.where((l) => !cashIds.contains(l.accountId))) {
        t = store.ledgerAccountById(l.accountId)?.type;
        break;
      }
      switch (t) {
        case DemoLedgerAccountType.revenue:
        case DemoLedgerAccountType.expense:
          operating += cashDelta;
        case DemoLedgerAccountType.asset:
          investing += cashDelta;
        case DemoLedgerAccountType.liability:
        case DemoLedgerAccountType.equity:
          financing += cashDelta;
        case null:
          operating += cashDelta;
      }
    }
    final net = operating + investing + financing;
    return _StatementList(rows: [
      _StmtRow('التدفقات من الأنشطة التشغيلية', operating,
          showSign: operating < 0),
      _StmtRow('التدفقات من الأنشطة الاستثمارية', investing,
          showSign: investing < 0),
      _StmtRow('التدفقات من الأنشطة التمويلية', financing,
          showSign: financing < 0),
      _StmtRow('صافي التغير في النقدية', net, grand: true, showSign: net < 0),
    ]);
  }

  Widget _profitAndLoss(BuildContext context) {
    final revenue = _typeTotal(DemoLedgerAccountType.revenue).abs();
    final expenses = _typeTotal(DemoLedgerAccountType.expense).abs();
    final net = revenue - expenses;
    final margin = revenue == 0 ? 0.0 : (net / revenue * 100);
    return _StatementList(rows: [
      _StmtRow('إجمالي الإيرادات', revenue, total: true),
      _StmtRow('إجمالي المصروفات', expenses, total: true, showSign: false),
      _StmtRow('صافي الربح', net, grand: true, showSign: net < 0),
      _StmtRow('هامش الربح', null,
          trailingText: '${margin.toStringAsFixed(1)}٪'),
    ]);
  }

  List<_StmtRow> _leafRows(BuildContext context, DemoLedgerAccountType t) {
    final rows = <_StmtRow>[];
    void walk(String? parentId, int depth) {
      for (final a in store.ledgerChildren(parentId)) {
        if (a.type != t) continue;
        final leaf = store.isLeafAccount(a.id);
        if (leaf) {
          final bal = store.ledgerBalance(a.id).abs();
          if (bal != 0) rows.add(_StmtRow(a.name, bal, depth: depth, code: a.code));
        } else {
          walk(a.id, depth + 1);
        }
      }
    }

    for (final root in store.ledgerAccounts.where((a) => a.parentId == null && a.type == t)) {
      walk(root.id, 1);
    }
    return rows;
  }
}

class _StmtRow {
  const _StmtRow(
    this.label,
    this.value, {
    this.depth = 0,
    this.header = false,
    this.total = false,
    this.grand = false,
    this.code,
    this.showSign = false,
    this.trailingText,
  });
  final String label;
  final double? value;
  final int depth;
  final bool header;
  final bool total;
  final bool grand;
  final String? code;
  final bool showSign;
  final String? trailingText;
}

class _StatementList extends StatelessWidget {
  const _StatementList({required this.rows});
  final List<_StmtRow> rows;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    // A bounded card-like container (fills the Expanded parent) so the scroll
    // view has a bounded height — TajCard's min-height Column would leave the
    // ListView unbounded and throw.
    return Container(
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: taj.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: rows.length,
        separatorBuilder: (_, i) => rows[i].grand || rows[i].total
            ? Divider(height: 1, color: taj.divider)
            : const SizedBox.shrink(),
        itemBuilder: (_, i) {
          final r = rows[i];
          final indent = math.min(r.depth * 16.0, 48.0);
          final weight = r.grand
              ? FontWeight.w800
              : (r.header || r.total ? FontWeight.w700 : FontWeight.w400);
          return Container(
            color: r.grand ? taj.primary.lighter : Colors.transparent,
            padding: EdgeInsetsDirectional.only(
                start: 16 + indent, end: 16, top: 10, bottom: 10),
            child: Row(
              children: [
                if (r.code != null) ...[
                  _CodeChip(r.code!),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(r.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(fontWeight: weight)),
                ),
                const SizedBox(width: 8),
                if (r.trailingText != null)
                  Text(r.trailingText!,
                      style: AppThemes.numeralStyle(context,
                          fontSize: 14, fontWeight: FontWeight.w800))
                else if (r.value != null)
                  _Money(
                    value: r.value!,
                    fontSize: r.grand ? 15 : 13.5,
                    fontWeight: weight,
                    maxChars: 13,
                    showSign: r.showSign,
                    color: r.grand ? taj.primary.dark : taj.textPrimary,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubTab extends StatelessWidget {
  const _SubTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: selected ? taj.primary.main : Colors.transparent,
                width: 2),
          ),
        ),
        child: Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? taj.primary.dark : taj.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}

// ===========================================================================
// Audit log
// ===========================================================================

class _AuditSection extends StatelessWidget {
  const _AuditSection({required this.store, required this.width});
  final DemoStore store;
  final double width;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final phone = width < AppBreakpoints.phone;
    final log = store.accountingAudit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('سجل التدقيق', style: text.titleMedium),
        ),
        Expanded(
          child: log.isEmpty
              ? const TajEmptyState(
                  icon: Icons.history_outlined, title: 'لا سجل')
              : phone
                  ? ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: log.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _AuditCard(entry: log[i]),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _FinTable(
                        frozenCol: const _FinCol('القيد', 110),
                        restCols: const [
                          _FinCol('التاريخ والوقت', 150),
                          _FinCol('المستخدم', 130),
                          _FinCol('الإجراء', 110),
                          _FinCol('قبل', 200),
                          _FinCol('بعد', 240),
                        ],
                        rows: [
                          for (final a in log)
                            _FinRow(
                              frozen: Text(a.entryNumber,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppThemes.numeralStyle(context,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              cells: [
                                Text(_fmtDateTime(a.date),
                                    style: AppThemes.numeralStyle(context,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: taj.textSecondary)),
                                Text(a.user,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodySmall),
                                _AuditActionBadge(action: a.action),
                                Text(a.before,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodySmall
                                        ?.copyWith(color: taj.textSecondary)),
                                Text(a.after,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodySmall),
                              ],
                            ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class _AuditCard extends StatefulWidget {
  const _AuditCard({required this.entry});
  final DemoAccountingAudit entry;
  @override
  State<_AuditCard> createState() => _AuditCardState();
}

class _AuditCardState extends State<_AuditCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final a = widget.entry;
    return TajCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(a.entryNumber,
                  style: AppThemes.numeralStyle(context,
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              _AuditActionBadge(action: a.action),
              const Spacer(),
              Flexible(
                child: Text(_fmtDateTime(a.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemes.numeralStyle(context,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: taj.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('المستخدم: ${a.user}',
              style: text.bodySmall?.copyWith(color: taj.textSecondary)),
          const SizedBox(height: 6),
          Text('قبل: ${a.before}',
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: text.bodySmall),
          const SizedBox(height: 2),
          Text('بعد: ${a.after}',
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: text.bodySmall),
          if ((a.before.length + a.after.length) > _auditExpandThreshold)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text(_expanded ? 'إخفاء' : 'عرض المزيد'),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuditActionBadge extends StatelessWidget {
  const _AuditActionBadge({required this.action});
  final String action;
  @override
  Widget build(BuildContext context) {
    final status = switch (action) {
      'ترحيل' => TajStatus.success,
      'اعتماد' => TajStatus.primary,
      'عكس' => TajStatus.error,
      'مراجعة' => TajStatus.info,
      'إنشاء' => TajStatus.secondary,
      _ => TajStatus.info,
    };
    return StatusBadge(label: action, status: status);
  }
}

// ===========================================================================
// Reusable: money, financial table, badges, filters, actions
// ===========================================================================

/// A monetary figure: tabular Almarai digits, compact past a length threshold,
/// the exact value always in a tooltip, and never truncated (single line in
/// dense contexts, up to [maxLines] in cards).
class _Money extends StatelessWidget {
  const _Money({
    required this.value,
    required this.fontSize,
    this.fontWeight = FontWeight.w600,
    this.color,
    this.maxLines = 1,
    this.showSign = false,
    this.maxChars = 16,
  });
  final double value;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final int maxLines;
  final bool showSign;
  final int maxChars;

  @override
  Widget build(BuildContext context) {
    final display = arDinarFit(value.abs(), maxChars: maxChars);
    final sign = showSign && value < 0 ? '−' : '';
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

class _Dash extends StatelessWidget {
  const _Dash();
  @override
  Widget build(BuildContext context) => Text('—',
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: context.taj.textDisabled));
}

class _FinCol {
  const _FinCol(this.label, this.width, {this.numeric = false});
  final String label;
  final double width;
  final bool numeric;
}

class _FinRow {
  const _FinRow({
    required this.frozen,
    required this.cells,
    this.onTap,
    this.selected = false,
    this.emphasize = false,
  });
  final Widget frozen;
  final List<Widget> cells;
  final VoidCallback? onTap;
  final bool selected;
  final bool emphasize;
}

/// A financial table with a **frozen first column**, a **sticky header** (stays
/// put on vertical scroll), horizontal scroll for the remaining columns when
/// they don't fit, and an optional **pinned totals row** at the bottom. Expects
/// a bounded height (place inside an `Expanded`). Amount columns are never
/// hidden; only the horizontal scroll ever hides them off-screen, always
/// reachable.
class _FinTable extends StatefulWidget {
  const _FinTable({
    required this.frozenCol,
    required this.restCols,
    required this.rows,
    this.totals,
  });
  final _FinCol frozenCol;
  final List<_FinCol> restCols;
  final List<_FinRow> rows;
  final _FinRow? totals;

  @override
  State<_FinTable> createState() => _FinTableState();
}

class _FinTableState extends State<_FinTable> {
  static const double _rowHeight = 54;
  static const double _headerHeight = 44;
  final _bodyH = ScrollController();
  final _headerH = ScrollController();
  final _totalsH = ScrollController();

  @override
  void initState() {
    super.initState();
    _bodyH.addListener(_sync);
  }

  void _sync() {
    if (!_bodyH.hasClients) return;
    for (final c in [_headerH, _totalsH]) {
      if (c.hasClients) {
        final target = _bodyH.offset.clamp(0.0, c.position.maxScrollExtent);
        if ((c.offset - target).abs() > 0.5) c.jumpTo(target);
      }
    }
  }

  @override
  void dispose() {
    _bodyH.dispose();
    _headerH.dispose();
    _totalsH.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final rawRest = widget.restCols.fold<double>(0, (s, c) => s + c.width);
    final frozenW = widget.frozenCol.width;

    return LayoutBuilder(
      builder: (context, c) {
        final viewport = c.maxWidth - frozenW;
        // Distribute any slack to the first rest column so wide screens fill
        // without a trailing gap; when content overflows, it scrolls.
        final slack = math.max(0.0, viewport - rawRest);
        final effWidths = [
          for (var i = 0; i < widget.restCols.length; i++)
            widget.restCols[i].width + (i == 0 ? slack : 0),
        ];
        final restWidth = rawRest + slack;

        Widget headerCell(_FinCol col) => Align(
              alignment: col.numeric
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Text(col.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                      color: taj.textSecondary, fontWeight: FontWeight.w600)),
            );

        Widget restRow(List<Widget> cells) => Row(
              children: [
                for (var i = 0; i < widget.restCols.length; i++)
                  SizedBox(
                    width: effWidths[i],
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 12),
                      child: Align(
                        alignment: widget.restCols[i].numeric
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: i < cells.length ? cells[i] : const SizedBox(),
                      ),
                    ),
                  ),
              ],
            );

        final header = DecoratedBox(
          decoration: BoxDecoration(
            color: taj.paper,
            border: Border(bottom: BorderSide(color: taj.divider)),
          ),
          child: SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                SizedBox(
                  width: frozenW,
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: 12, end: 12),
                    child: headerCell(widget.frozenCol),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerH,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: restWidth,
                      child: Row(
                        children: [
                          for (var i = 0; i < widget.restCols.length; i++)
                            SizedBox(
                              width: effWidths[i],
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    end: 12),
                                child: headerCell(widget.restCols[i]),
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

        final body = SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Frozen column.
              SizedBox(
                width: frozenW,
                child: Column(
                  children: [
                    for (final r in widget.rows)
                      _rowContainer(
                        context,
                        height: _rowHeight,
                        selected: r.selected,
                        onTap: r.onTap,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                              start: 12, end: 12),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: r.frozen,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _bodyH,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: restWidth,
                    child: Column(
                      children: [
                        for (final r in widget.rows)
                          _rowContainer(
                            context,
                            height: _rowHeight,
                            selected: r.selected,
                            onTap: r.onTap,
                            child: restRow(r.cells),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        Widget? totals;
        if (widget.totals != null) {
          final t = widget.totals!;
          totals = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(height: 1, color: taj.divider),
              Container(
                color: taj.background,
                child: SizedBox(
                  height: _rowHeight,
                  child: Row(
                    children: [
                      SizedBox(
                        width: frozenW,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                              start: 12, end: 12),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: t.frozen,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _totalsH,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: SizedBox(
                            width: restWidth,
                            child: restRow(t.cells),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: taj.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: taj.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              header,
              Expanded(child: body),
              if (totals != null) totals,
            ],
          ),
        );
      },
    );
  }

  Widget _rowContainer(
    BuildContext context, {
    required double height,
    required Widget child,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    final taj = context.taj;
    // No horizontal padding here: the frozen column and the rest row are each
    // sized to exact widths (frozenW / restWidth), so any extra padding would
    // shrink their available width and overflow. Cell insets live in the cells.
    final row = Container(
      height: height,
      decoration: BoxDecoration(
        color: selected ? taj.primary.lighter : Colors.transparent,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
    if (onTap == null) return row;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }
}

// ---------------------------------------------------------------------------
// Badges & chips
// ---------------------------------------------------------------------------

class _EntryStatusBadge extends StatelessWidget {
  const _EntryStatusBadge({required this.entry});
  final DemoJournalEntry entry;
  @override
  Widget build(BuildContext context) {
    final (label, status) = switch (entry.status) {
      DemoEntryStatus.draft => ('مسودة', TajStatus.warning),
      DemoEntryStatus.posted => ('مُرحّل', TajStatus.success),
      DemoEntryStatus.reversed => ('معكوس', TajStatus.error),
    };
    return StatusBadge(label: label, status: status);
  }
}

class _AccountTypeChip extends StatelessWidget {
  const _AccountTypeChip(this.type);
  final DemoLedgerAccountType type;
  @override
  Widget build(BuildContext context) {
    final (label, status) = switch (type) {
      DemoLedgerAccountType.asset => ('أصول', TajStatus.info),
      DemoLedgerAccountType.liability => ('خصوم', TajStatus.warning),
      DemoLedgerAccountType.equity => ('حقوق ملكية', TajStatus.secondary),
      DemoLedgerAccountType.revenue => ('إيرادات', TajStatus.success),
      DemoLedgerAccountType.expense => ('مصروفات', TajStatus.error),
    };
    return StatusBadge(label: label, status: status);
  }
}

class _DiffBadge extends StatelessWidget {
  const _DiffBadge({required this.diff});
  final double diff;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: taj.error.lighter,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 14, color: taj.error.dark),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Tooltip(
              message: 'الفرق: ${arDinar(diff)}',
              child: Text('فرق ${arDinarFit(diff.abs(), maxChars: 12)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.numeralStyle(context,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: taj.error.dark)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header with responsive actions (overflow menu below 720)
// ---------------------------------------------------------------------------

class _ActionSpec {
  const _ActionSpec(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _PrimaryAction {
  const _PrimaryAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.actions,
    required this.width,
    required this.filters,
  });
  final String title;
  final String subtitle;
  final _PrimaryAction primary;
  final List<_ActionSpec> actions;
  final double width;
  final Widget filters;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    // Below 720 the secondary actions collapse into an overflow menu; only the
    // primary action stays visible.
    final collapse = width < AppBreakpoints.entryEditorTable;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: text.titleMedium),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall
                            ?.copyWith(color: taj.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (collapse) ...[
                if (actions.isNotEmpty)
                  PopupMenuButton<int>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (i) => actions[i].onTap(),
                    itemBuilder: (_) => [
                      for (var i = 0; i < actions.length; i++)
                        PopupMenuItem<int>(
                          value: i,
                          child: Row(
                            children: [
                              Icon(actions[i].icon, size: 18),
                              const SizedBox(width: 10),
                              Text(actions[i].label),
                            ],
                          ),
                        ),
                    ],
                  ),
                FilledButton.icon(
                  onPressed: primary.onTap,
                  icon: Icon(primary.icon, size: 18),
                  label: Text(primary.label),
                ),
              ] else ...[
                for (final a in actions) ...[
                  OutlinedButton.icon(
                    onPressed: a.onTap,
                    icon: Icon(a.icon, size: 18),
                    label: Text(a.label),
                  ),
                  const SizedBox(width: 8),
                ],
                FilledButton.icon(
                  onPressed: primary.onTap,
                  icon: Icon(primary.icon, size: 18),
                  label: Text(primary.label),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          filters,
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: taj.textSecondary),
      style: IconButton.styleFrom(
        side: BorderSide(color: taj.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter pill + account picker
// ---------------------------------------------------------------------------

class _FilterPill<T> extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.value,
    required this.options,
    required this.onSelected,
  });
  final IconData icon;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final current =
        options.firstWhere((o) => o.$1 == value, orElse: () => options.first).$2;
    return PopupMenuButton<T>(
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem<T>(value: o.$1, child: Text(o.$2)),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: taj.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: taj.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
            Icon(Icons.arrow_drop_down_rounded,
                size: 18, color: taj.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AccountPickerButton extends StatelessWidget {
  const _AccountPickerButton(
      {required this.store, required this.selectedId, required this.onPick});
  final DemoStore store;
  final String selectedId;
  final ValueChanged<String> onPick;
  @override
  Widget build(BuildContext context) {
    final acc = store.ledgerAccountById(selectedId);
    return OutlinedButton.icon(
      onPressed: () async {
        final id = await pickLedgerAccount(context, store);
        if (id != null) onPick(id);
      },
      icon: const Icon(Icons.search_rounded, size: 18),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 130),
        child: Text(acc?.name ?? 'اختر حسابًا',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

String _fmtDateTime(DateTime d) =>
    '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

// ===========================================================================
// Dialog shell + account picker
// ===========================================================================

/// A capped, height-limited, keyboard-safe dialog with an optional sticky
/// [footer] that rides above the keyboard. Width caps at [maxWidth] (≤720),
/// height at 90% of the space above the keyboard, and the body scrolls.
Future<T?> _acctDialog<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext, StateSetter) body,
  Widget Function(BuildContext, StateSetter)? footer,
  double maxWidth = 720,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      final phone = size.width < AppBreakpoints.phone;
      final dialogW = phone ? size.width : math.min(maxWidth, size.width - 48);
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final taj = ctx.taj;
          final insets = MediaQuery.viewInsetsOf(ctx).bottom;
          final maxH = (size.height - insets) * 0.92;
          return Dialog(
            insetPadding:
                EdgeInsets.symmetric(horizontal: phone ? 8 : 24, vertical: 24),
            backgroundColor: taj.paper,
            child: Padding(
              padding: EdgeInsets.only(bottom: insets),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: dialogW, maxHeight: maxH),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(20, 14, 8, 8),
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
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: body(ctx, setLocal),
                      ),
                    ),
                    if (footer != null) ...[
                      Divider(height: 1, color: taj.divider),
                      footer(ctx, setLocal),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Picks a posting (leaf) account. Full-width search sheet on phone; a capped
/// (≤480) search dialog on wider screens that never escapes the window.
Future<String?> pickLedgerAccount(BuildContext context, DemoStore store) {
  final leaves = store.ledgerAccounts
      .where((a) => store.isLeafAccount(a.id))
      .toList()
    ..sort((a, b) => a.code.compareTo(b.code));
  final phone = MediaQuery.sizeOf(context).width < AppBreakpoints.phone;

  Widget listBody(
      BuildContext ctx, String query, ValueChanged<String> onQuery) {
    final taj = ctx.taj;
    final text = Theme.of(ctx).textTheme;
    final filtered = leaves
        .where((a) => query.isEmpty || a.name.contains(query) || a.code.contains(query))
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            autofocus: !phone,
            onChanged: onQuery,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'ابحث بالاسم أو الرمز…',
            ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final a = filtered[i];
              return ListTile(
                leading: _CodeChip(a.code),
                title: Text(a.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_accountTypeLabel(a.type),
                    style: text.bodySmall?.copyWith(color: taj.textSecondary)),
                onTap: () => Navigator.of(ctx).pop(a.id),
              );
            },
          ),
        ),
      ],
    );
  }

  if (phone) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.taj.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        var query = '';
        return StatefulBuilder(
          builder: (ctx, setSheet) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.85,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ctx.taj.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: listBody(ctx, query, (q) => setSheet(() => query = q)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      var query = '';
      final size = MediaQuery.sizeOf(ctx);
      return StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: ctx.taj.paper,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: 480, maxHeight: size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                    child: listBody(ctx, query, (q) => setDlg(() => query = q))),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String _accountTypeLabel(DemoLedgerAccountType t) => switch (t) {
      DemoLedgerAccountType.asset => 'أصول',
      DemoLedgerAccountType.liability => 'خصوم',
      DemoLedgerAccountType.equity => 'حقوق ملكية',
      DemoLedgerAccountType.revenue => 'إيرادات',
      DemoLedgerAccountType.expense => 'مصروفات',
    };

// ===========================================================================
// Entry editor (new draft) — line cards/table + sticky totals bar
// ===========================================================================

class _EditLine {
  _EditLine();
  String? accountId;
  final debit = TextEditingController();
  final credit = TextEditingController();
  final desc = TextEditingController();
  void dispose() {
    debit.dispose();
    credit.dispose();
    desc.dispose();
  }
}

Future<void> showEntryEditorDialog(BuildContext context, DemoStore store) async {
  final lines = <_EditLine>[_EditLine(), _EditLine()];
  final descCtrl = TextEditingController();
  final refCtrl = TextEditingController();

  double totalDebit() =>
      lines.fold(0, (s, l) => s + (double.tryParse(l.debit.text.trim()) ?? 0));
  double totalCredit() =>
      lines.fold(0, (s, l) => s + (double.tryParse(l.credit.text.trim()) ?? 0));

  await _acctDialog<void>(
    context,
    title: 'قيد جديد — ${store.nextEntryNumber}',
    body: (ctx, setLocal) {
      final table = MediaQuery.sizeOf(ctx).width >= AppBreakpoints.entryEditorTable;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledField(
            label: 'البيان (شرح بالعربية المبسّطة)',
            child: TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'وصف القيد…'),
            ),
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'المرجع (اختياري)',
            child: TextField(
              controller: refCtrl,
              decoration: const InputDecoration(hintText: 'رقم المستند'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('سطور القيد',
                  style: Theme.of(ctx).textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setLocal(() => lines.add(_EditLine())),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('سطر'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (table)
            _EditLinesTable(
              store: store,
              lines: lines,
              onChanged: () => setLocal(() {}),
              onRemove: (l) => setLocal(() {
                if (lines.length > 1) {
                  lines.remove(l);
                  l.dispose();
                }
              }),
            )
          else
            _EditLinesCards(
              store: store,
              lines: lines,
              onChanged: () => setLocal(() {}),
              onRemove: (l) => setLocal(() {
                if (lines.length > 1) {
                  lines.remove(l);
                  l.dispose();
                }
              }),
            ),
        ],
      );
    },
    footer: (ctx, setLocal) {
      final td = totalDebit();
      final tc = totalCredit();
      final diff = td - tc;
      final balanced = diff.abs() < 0.005;
      final hasLines =
          lines.any((l) => l.accountId != null && (l.debit.text.isNotEmpty || l.credit.text.isNotEmpty));
      return _EntryTotalsBar(
        totalDebit: td,
        totalCredit: tc,
        difference: diff,
        primaryLabel: 'ترحيل',
        primaryEnabled: balanced && hasLines,
        onSaveDraft: () async {
          final messenger = ScaffoldMessenger.of(ctx);
          final navigator = Navigator.of(ctx);
          await store.addJournalEntry(_buildEntry(store, lines, descCtrl.text,
              refCtrl.text, DemoEntryStatus.draft));
          navigator.pop();
          messenger.showSnackBar(const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('تم حفظ المسودة')));
        },
        onPrimary: balanced && hasLines
            ? () async {
                final messenger = ScaffoldMessenger.of(ctx);
                final navigator = Navigator.of(ctx);
                final success = ctx.taj.success.dark;
                await store.addJournalEntry(_buildEntry(store, lines,
                    descCtrl.text, refCtrl.text, DemoEntryStatus.posted));
                navigator.pop();
                messenger.showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: success,
                    content: const Text('تم ترحيل القيد')));
              }
            : null,
      );
    },
  );

  for (final l in lines) {
    l.dispose();
  }
  descCtrl.dispose();
  refCtrl.dispose();
}

DemoJournalEntry _buildEntry(DemoStore store, List<_EditLine> lines,
    String desc, String ref, DemoEntryStatus status) {
  final number = store.nextEntryNumber;
  return DemoJournalEntry(
    id: number,
    number: number,
    date: DateTime.now(),
    description: desc.trim(),
    status: status,
    createdBy: 'المستخدم الحالي',
    reference: ref.trim(),
    lines: [
      for (final l in lines)
        if (l.accountId != null &&
            ((double.tryParse(l.debit.text.trim()) ?? 0) > 0 ||
                (double.tryParse(l.credit.text.trim()) ?? 0) > 0))
          DemoJournalLine(
            accountId: l.accountId!,
            debit: double.tryParse(l.debit.text.trim()) ?? 0,
            credit: double.tryParse(l.credit.text.trim()) ?? 0,
            description: l.desc.text.trim(),
          ),
    ],
  );
}

class _EditLinesTable extends StatelessWidget {
  const _EditLinesTable({
    required this.store,
    required this.lines,
    required this.onChanged,
    required this.onRemove,
  });
  final DemoStore store;
  final List<_EditLine> lines;
  final VoidCallback onChanged;
  final ValueChanged<_EditLine> onRemove;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    Widget head(String s, {bool numeric = false}) => Align(
          alignment: numeric
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Text(s,
              style: text.bodySmall?.copyWith(
                  color: taj.textSecondary, fontWeight: FontWeight.w600)),
        );
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 4, child: head('الحساب')),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: head('البيان')),
            const SizedBox(width: 8),
            SizedBox(width: 140, child: head('مدين', numeric: true)),
            const SizedBox(width: 8),
            SizedBox(width: 140, child: head('دائن', numeric: true)),
            const SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 8),
        for (final l in lines) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: _AccountField(
                    store: store, line: l, onChanged: onChanged),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: l.desc,
                  decoration: const InputDecoration(
                      isDense: true, hintText: 'بيان السطر'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                child: _AmountField(controller: l.debit, onChanged: onChanged),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                child: _AmountField(controller: l.credit, onChanged: onChanged),
              ),
              SizedBox(
                width: 40,
                child: IconButton(
                  onPressed: () => onRemove(l),
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 20, color: taj.error.main),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EditLinesCards extends StatelessWidget {
  const _EditLinesCards({
    required this.store,
    required this.lines,
    required this.onChanged,
    required this.onRemove,
  });
  final DemoStore store;
  final List<_EditLine> lines;
  final VoidCallback onChanged;
  final ValueChanged<_EditLine> onRemove;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Column(
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: taj.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: taj.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('سطر ${i + 1}',
                        style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    InkWell(
                      onTap: () => onRemove(lines[i]),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 20, color: taj.error.main),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _AccountField(store: store, line: lines[i], onChanged: onChanged),
                const SizedBox(height: 8),
                TextField(
                  controller: lines[i].desc,
                  decoration: const InputDecoration(
                      isDense: true, hintText: 'بيان السطر'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _AmountField(
                          controller: lines[i].debit,
                          onChanged: onChanged,
                          label: 'مدين'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AmountField(
                          controller: lines[i].credit,
                          onChanged: onChanged,
                          label: 'دائن'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AccountField extends StatelessWidget {
  const _AccountField(
      {required this.store, required this.line, required this.onChanged});
  final DemoStore store;
  final _EditLine line;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final acc =
        line.accountId == null ? null : store.ledgerAccountById(line.accountId!);
    return InkWell(
      onTap: () async {
        final id = await pickLedgerAccount(context, store);
        if (id != null) {
          line.accountId = id;
          onChanged();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: taj.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.account_tree_outlined, size: 18, color: taj.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                acc == null ? 'اختر حسابًا' : '${acc.code} — ${acc.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: acc == null ? taj.textDisabled : taj.textPrimary),
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 18, color: taj.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField(
      {required this.controller, required this.onChanged, this.label});
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? label;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.end,
      onChanged: (_) => onChanged(),
      style: AppThemes.numeralStyle(context, fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: '0',
      ),
    );
  }
}

class _EntryTotalsBar extends StatelessWidget {
  const _EntryTotalsBar({
    required this.totalDebit,
    required this.totalCredit,
    required this.difference,
    required this.primaryLabel,
    required this.primaryEnabled,
    required this.onSaveDraft,
    required this.onPrimary,
  });
  final double totalDebit;
  final double totalCredit;
  final double difference;
  final String primaryLabel;
  final bool primaryEnabled;
  final VoidCallback onSaveDraft;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final balanced = difference.abs() < 0.005;
    return Container(
      color: taj.paper,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Totals — the most important element; always visible above the
          // keyboard, wraps rather than overflowing on tight widths.
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TotalChip(label: 'مدين', value: totalDebit, swatch: taj.success),
              _TotalChip(label: 'دائن', value: totalCredit, swatch: taj.info),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: balanced ? taj.success.lighter : taj.error.lighter,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        balanced
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        size: 16,
                        color: balanced ? taj.success.dark : taj.error.dark),
                    const SizedBox(width: 6),
                    Text(
                      balanced ? 'متوازن' : 'فرق ${arDinarFit(difference.abs(), maxChars: 12)}',
                      style: AppThemes.numeralStyle(context,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: balanced ? taj.success.dark : taj.error.dark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSaveDraft,
                    child: const Text('حفظ كمسودة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onPrimary,
                    child: Text(primaryLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip(
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
                .bodyMedium
                ?.copyWith(color: taj.textSecondary)),
        _Money(
            value: value,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: taj.accentFor(swatch)),
      ],
    );
  }
}

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

// ===========================================================================
// Entry viewer (read-only) + actions, and inline preview
// ===========================================================================

Future<void> showEntryViewerDialog(
    BuildContext context, DemoStore store, String entryId) async {
  await _acctDialog<void>(
    context,
    title: 'تفاصيل القيد',
    body: (ctx, setLocal) {
      final entry = store.journalEntries.firstWhere((e) => e.id == entryId);
      return _EntryBody(store: store, entry: entry);
    },
    footer: (ctx, setLocal) {
      final entry = store.journalEntries.firstWhere((e) => e.id == entryId);
      return _EntryActionsBar(
        store: store,
        entry: entry,
        onChanged: () => setLocal(() {}),
      );
    },
  );
}

class _EntryPreview extends StatelessWidget {
  const _EntryPreview({required this.store, required this.entry});
  final DemoStore store;
  final DemoJournalEntry entry;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _EntryBody(store: store, entry: entry),
          ),
        ),
        Divider(height: 1, color: taj.divider),
        _EntryActionsBar(store: store, entry: entry, onChanged: () {}),
      ],
    );
  }
}

class _EntryBody extends StatelessWidget {
  const _EntryBody({required this.store, required this.entry});
  final DemoStore store;
  final DemoJournalEntry entry;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(entry.number,
                style: AppThemes.numeralStyle(context,
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            _EntryStatusBadge(entry: entry),
            const Spacer(),
            Flexible(
              child: Text(_fmtDate(entry.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.numeralStyle(context,
                      fontSize: 13, color: taj.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(entry.description, style: text.bodyMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (entry.reference.isNotEmpty)
              _tag(context, Icons.tag_rounded, entry.reference),
            if (entry.createdBy.isNotEmpty)
              _tag(context, Icons.person_outline_rounded, entry.createdBy),
            if (entry.reviewed) _tag(context, Icons.fact_check_outlined, 'مُراجَع'),
            if (entry.approved) _tag(context, Icons.verified_outlined, 'معتمد'),
            if (entry.reversalOfId != null)
              _tag(context, Icons.undo_rounded, 'عكس ${entry.reversalOfId}'),
          ],
        ),
        const SizedBox(height: 12),
        // Lines table — account · description · debit · credit, with totals.
        _EntryLinesTable(store: store, entry: entry),
        if (entry.attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('المرفقات', style: text.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in entry.attachments)
                Chip(
                  avatar: const Icon(Icons.attach_file_rounded, size: 16),
                  label: Text(a),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _tag(BuildContext context, IconData icon, String label) {
    final taj = context.taj;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: taj.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: taj.textSecondary)),
      ],
    );
  }
}

class _EntryLinesTable extends StatelessWidget {
  const _EntryLinesTable({required this.store, required this.entry});
  final DemoStore store;
  final DemoJournalEntry entry;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    // A simple internally-scrollable table: account (flexible) never truncates
    // amounts; debit/credit fixed ~120 with horizontal scroll on tight widths.
    Widget cellHead(String s, {bool numeric = false}) => Align(
          alignment: numeric
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Text(s,
              style: text.bodySmall?.copyWith(
                  color: taj.textSecondary, fontWeight: FontWeight.w600)),
        );
    return LayoutBuilder(
      builder: (context, c) {
        const debitW = 124.0, creditW = 124.0, gap = 12.0;
        final accMin = 180.0;
        final natural = accMin + debitW + creditW + gap * 2;
        final needScroll = c.maxWidth < natural;
        final accW = needScroll ? accMin : c.maxWidth - debitW - creditW - gap * 2;
        final table = SizedBox(
          width: needScroll ? natural : c.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: accW, child: cellHead('الحساب / البيان')),
                    const SizedBox(width: gap),
                    SizedBox(
                        width: debitW, child: cellHead('مدين', numeric: true)),
                    const SizedBox(width: gap),
                    SizedBox(
                        width: creditW, child: cellHead('دائن', numeric: true)),
                  ],
                ),
              ),
              Divider(height: 1, color: taj.divider),
              for (final l in entry.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: accW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              store.ledgerAccountById(l.accountId)?.name ??
                                  l.accountId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (l.description.isNotEmpty)
                              Text(l.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall
                                      ?.copyWith(color: taj.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: debitW,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: l.debit > 0
                              ? _Money(
                                  value: l.debit,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  maxChars: 12,
                                  color: taj.accentFor(taj.success))
                              : const _Dash(),
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: creditW,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: l.credit > 0
                              ? _Money(
                                  value: l.credit,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  maxChars: 12,
                                  color: taj.accentFor(taj.info))
                              : const _Dash(),
                        ),
                      ),
                    ],
                  ),
                ),
              Divider(height: 1, color: taj.divider),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: accW,
                      child: Text('الإجمالي',
                          style: text.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: debitW,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _Money(
                            value: entry.totalDebit,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            maxChars: 12,
                            color: taj.accentFor(taj.success)),
                      ),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: creditW,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _Money(
                            value: entry.totalCredit,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            maxChars: 12,
                            color: taj.accentFor(taj.info)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        if (!needScroll) return table;
        return SingleChildScrollView(
            scrollDirection: Axis.horizontal, child: table);
      },
    );
  }
}

class _EntryActionsBar extends StatelessWidget {
  const _EntryActionsBar(
      {required this.store, required this.entry, required this.onChanged});
  final DemoStore store;
  final DemoJournalEntry entry;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionSpec>[];
    if (!entry.reviewed) {
      actions.add(_ActionSpec(Icons.fact_check_outlined, 'مراجعة', () async {
        await store.reviewEntry(entry.id);
        onChanged();
      }));
    }
    if (!entry.approved) {
      actions.add(_ActionSpec(Icons.verified_outlined, 'اعتماد', () async {
        final ok = await _confirm(context, store, entry, 'اعتماد القيد');
        if (ok) {
          await store.approveEntry(entry.id);
          onChanged();
        }
      }));
    }
    if (entry.status == DemoEntryStatus.posted) {
      actions.add(_ActionSpec(Icons.undo_rounded, 'عكس القيد', () async {
        final messenger = ScaffoldMessenger.of(context);
        final ok = await _confirm(context, store, entry, 'عكس القيد');
        if (ok) {
          await store.reverseEntry(entry.id);
          onChanged();
          messenger.showSnackBar(const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('تم عكس القيد')));
        }
      }));
    }
    actions.add(_ActionSpec(Icons.print_outlined, 'طباعة', () {}));

    // Primary action: post a draft (if balanced), else the first available.
    _PrimaryAction? primary;
    if (entry.status == DemoEntryStatus.draft) {
      primary = _PrimaryAction(
        icon: Icons.publish_outlined,
        label: 'ترحيل',
        onTap: entry.isBalanced
            ? () async {
                final messenger = ScaffoldMessenger.of(context);
                await store.postEntry(entry.id);
                onChanged();
                messenger.showSnackBar(const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('تم ترحيل القيد')));
              }
            : () {},
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (!entry.isBalanced && entry.status == DemoEntryStatus.draft)
              Expanded(child: _DiffBadge(diff: entry.difference))
            else
              const Spacer(),
            const SizedBox(width: 8),
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (i) => actions[i].onTap(),
              itemBuilder: (_) => [
                for (var i = 0; i < actions.length; i++)
                  PopupMenuItem<int>(
                    value: i,
                    child: Row(
                      children: [
                        Icon(actions[i].icon, size: 18),
                        const SizedBox(width: 10),
                        Text(actions[i].label),
                      ],
                    ),
                  ),
              ],
            ),
            if (primary != null) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: primary.onTap,
                icon: Icon(primary.icon, size: 18),
                label: Text(primary.label),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, DemoStore store,
      DemoJournalEntry entry, String title) async {
    final result = await _acctDialog<bool>(
      context,
      title: title,
      maxWidth: 560,
      body: (ctx, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('هل أنت متأكد من $title رقم ${entry.number}؟',
              style: Theme.of(ctx).textTheme.bodyLarge),
          const SizedBox(height: 12),
          _EntryLinesTable(store: store, entry: entry),
        ],
      ),
      footer: (ctx, setLocal) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('إلغاء')),
              const SizedBox(width: 8),
              FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('تأكيد')),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}
