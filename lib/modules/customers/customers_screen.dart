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

class _Party {
  const _Party(this.name, this.phone, this.balance, this.limit, this.last,
      {this.id = ''});
  final String id;
  final String name;
  final String phone;
  final double balance; // >0 owes us (debt), <=0 settled
  final double limit;
  final String last;
}

/// Customers & Suppliers (spec 7.8): segmented list + balance colouring + a
/// peek profile with statement and records tabs.
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _suppliersTab = false;
  String _search = '';
  _Party? _selected;

  List<_Party> get _storeList =>
      (_suppliersTab
              ? DemoStoreProvider.of(context).suppliers.map(
                (s) => _Party(s.name, s.phone, s.balance, 0, '', id: s.id),
              )
              : DemoStoreProvider.of(context).customers.map(
                (c) => _Party(
                  c.name,
                  c.phone,
                  c.balance,
                  c.creditLimit,
                  '',
                  id: c.id,
                ),
              ))
          .toList();

  List<_Party> get _list =>
      _storeList
          .where(
            (p) =>
                _search.isEmpty ||
                p.name.contains(_search.trim()) ||
                p.phone.contains(_search.trim()),
          )
          .toList();

  void _open(_Party p) {
    setState(() => _selected = p);
    _scaffoldKey.currentState?.openEndDrawer();
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
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      endDrawer:
          _selected == null
              ? null
              : Drawer(
                width: drawerWidth(context, desired: 460),
                backgroundColor: taj.paper,
                child: _PartyDetail(party: _selected!, supplier: _suppliersTab),
              ),
      body: LayoutBuilder(
        builder: (context, c) {
          final pad = pagePaddingForWidth(c.maxWidth);
          final rows = _list;
          return PageContainer(
            child: ListView(
              padding: EdgeInsets.all(pad),
              children: [
                SectionHeading(
                  title: 'العملاء والموردون',
                  subtitle: 'الأرصدة وكشوف الحسابات',
                  trailing: FilledButton.icon(
                    onPressed: () => _addCustomer(context),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: Text(_suppliersTab ? 'مورّد جديد' : 'عميل جديد'),
                  ),
                ),
                const SizedBox(height: 20),
                _Segmented(
                  suppliers: _suppliersTab,
                  onChanged: (v) => setState(() => _suppliersTab = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: const InputDecoration(
                          hintText: 'ابحث بالاسم أو الهاتف…',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const TajFilterBar(filters: []),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: TajEmptyState(
                      icon: Icons.people_outline,
                      title: 'لا نتائج',
                    ),
                  )
                else
                  TajCard(
                    padding: EdgeInsets.zero,
                    child: TajTable(
                      columns: const [
                        TajColumn('الاسم', flex: 4),
                        TajColumn('الرصيد', flex: 2, numeric: true),
                        TajColumn('سقف الائتمان', flex: 2, numeric: true),
                        TajColumn('آخر عملية', flex: 2),
                      ],
                      rows: [for (final p in rows) _row(context, p)],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addCustomer(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(_suppliersTab ? 'إضافة مورد' : 'إضافة عميل'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                ),
                TextField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'الهاتف'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  if (name.text.trim().isNotEmpty) {
                    Navigator.pop(dialogContext, (
                      name.text.trim(),
                      phone.text.trim(),
                    ));
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
    );
    name.dispose();
    phone.dispose();
    if (result == null) return;
    if (!context.mounted) return;
    final store = DemoStoreProvider.of(context);
    if (_suppliersTab) {
      await store.addSupplier(
        DemoSupplier(
          id: 's${DateTime.now().millisecondsSinceEpoch}',
          name: result.$1,
          phone: result.$2,
        ),
      );
    } else {
      await store.upsertCustomer(
        DemoCustomer(
          id: 'c${DateTime.now().millisecondsSinceEpoch}',
          name: result.$1,
          phone: result.$2,
          creditLimit: 1000,
        ),
      );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت الإضافة')));
  }

  TajRowData _row(BuildContext context, _Party p) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final owes = p.balance > 0;
    final swatch =
        p.balance == 0 ? taj.success : (owes ? taj.error : taj.success);
    return TajRowData(
      onTap: () => _open(p),
      actions: [
        Icon(Icons.more_horiz_rounded, size: 18, color: taj.textSecondary),
      ],
      cells: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: taj.primary.lighter,
              child: Text(
                p.name.characters.first,
                style: TextStyle(
                  color: taj.primary.dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    p.phone,
                    style: AppThemes.numeralStyle(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: taj.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(
          p.balance == 0 ? 'مسدّد' : arDinar(p.balance),
          style: AppThemes.numeralStyle(
            context,
            fontSize: 14,
            color: swatch.dark,
          ),
        ),
        Text(
          arDinar(p.limit),
          style: AppThemes.numeralStyle(
            context,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: taj.textSecondary,
          ),
        ),
        Text(
          p.last,
          style: AppThemes.numeralStyle(
            context,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: taj.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.suppliers, required this.onChanged});
  final bool suppliers;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    Widget seg(String label, bool isSup) {
      final selected = suppliers == isSup;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(isSup),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? taj.paper : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: selected ? AppThemes.cardShadow(context) : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? taj.primary.dark : taj.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: taj.divider),
      ),
      child: Row(children: [seg('العملاء', false), seg('الموردون', true)]),
    );
  }
}

class _PartyDetail extends StatelessWidget {
  const _PartyDetail({required this.party, required this.supplier});
  final _Party party;
  final bool supplier;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final owes = party.balance > 0;
    final swatch =
        party.balance == 0 ? taj.success : (owes ? taj.error : taj.success);

    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: taj.primary.lighter,
                    child: Text(
                      party.name.characters.first,
                      style: text.titleLarge?.copyWith(color: taj.primary.dark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(party.name, style: text.titleLarge),
                        Text(
                          party.phone,
                          style: AppThemes.numeralStyle(
                            context,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: taj.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            // Balance banner.
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: swatch.lighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    owes
                        ? Icons.trending_up_rounded
                        : Icons.check_circle_outline,
                    color: swatch.dark,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    party.balance == 0
                        ? 'الحساب مسدّد'
                        : (owes ? 'رصيد مستحق' : 'رصيد دائن'),
                    style: text.bodyMedium?.copyWith(
                      color: swatch.darker,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    party.balance == 0 ? '0 د.ل' : arDinar(party.balance),
                    style: AppThemes.numeralStyle(
                      context,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: swatch.dark,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              labelColor: taj.accentText,
              unselectedLabelColor: taj.textSecondary,
              indicatorColor: taj.primary.main,
              tabs: const [
                Tab(text: 'نظرة عامة'),
                Tab(text: 'كشف الحساب'),
                Tab(text: 'السجلّات'),
              ],
            ),
            Divider(height: 1, color: taj.divider),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(party: party, supplier: supplier),
                  _StatementTab(party: party, supplier: supplier),
                  _RecordsTab(party: party, supplier: supplier),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                      ),
                      label: const Text('تذكير بالديون'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('تحصيل'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.party, required this.supplier});
  final _Party party;
  final bool supplier;
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    Widget kv(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(k, style: text.bodyMedium?.copyWith(color: taj.textSecondary)),
          const Spacer(),
          Text(
            v,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        kv('النوع', supplier ? 'مورّد' : 'عميل'),
        Divider(height: 1, color: taj.divider),
        kv('الهاتف', party.phone),
        Divider(height: 1, color: taj.divider),
        kv('سقف الائتمان', arDinar(party.limit)),
        Divider(height: 1, color: taj.divider),
        kv('آخر عملية', party.last),
      ],
    );
  }
}

String _fmtDate(DateTime d) => '${d.year}/${d.month}/${d.day}';

class _StatementTab extends StatelessWidget {
  const _StatementTab({required this.party, required this.supplier});
  final _Party party;
  final bool supplier;
  @override
  Widget build(BuildContext context) {
    final store = DemoStoreProvider.of(context);
    // Running statement built from real documents: the customer's invoices or
    // the supplier's purchases. Collections/payments aren't modelled yet, so
    // only the documents that exist are shown — no invented transactions.
    final docs = supplier
        ? (store.purchases.where((p) => p.supplierId == party.id).toList()
          ..sort((a, b) => a.date.compareTo(b.date)))
        : (store.sales.where((s) => s.customerId == party.id).toList()
          ..sort((a, b) => a.date.compareTo(b.date)));
    var running = 0.0;
    final rows = <(String, String, double, double, double)>[];
    for (final d in docs) {
      if (d is DemoPurchase) {
        running += d.total;
        rows.add((_fmtDate(d.date), 'مشتريات #${d.id}', d.total, 0.0, running));
      } else if (d is DemoSale) {
        running += d.total;
        rows.add((_fmtDate(d.date), 'فاتورة #${d.id}', d.total, 0.0, running));
      }
    }
    final taj = context.taj;
    if (rows.isEmpty) {
      return const TajEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'لا توجد حركات',
        message: 'لم تُسجَّل أي فواتير أو مشتريات لهذا الطرف بعد.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => Divider(height: 18, color: taj.divider),
      itemBuilder: (_, i) {
        final (date, desc, debit, credit, balance) = rows[i];
        final text = Theme.of(context).textTheme;
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    desc,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    date,
                    style: AppThemes.numeralStyle(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: taj.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (debit > 0)
              Text(
                '+${arNum(debit)}',
                style: AppThemes.numeralStyle(
                  context,
                  fontSize: 14,
                  color: taj.accentFor(taj.error),
                ),
              )
            else
              Text(
                '-${arNum(credit)}',
                style: AppThemes.numeralStyle(
                  context,
                  fontSize: 14,
                  color: taj.accentFor(taj.success),
                ),
              ),
            const SizedBox(width: 14),
            Text(
              '=${arNum(balance)}',
              style: AppThemes.numeralStyle(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: taj.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecordsTab extends StatelessWidget {
  const _RecordsTab({required this.party, required this.supplier});
  final _Party party;
  final bool supplier;
  @override
  Widget build(BuildContext context) {
    final store = DemoStoreProvider.of(context);
    // Real documents only: the customer's invoices (by status) or the
    // supplier's purchases (paid / outstanding). Empty until something exists.
    final items = <(String, String, TajStatus)>[];
    if (supplier) {
      for (final p in store.purchases.where((p) => p.supplierId == party.id)) {
        items.add((
          'مشتريات #${p.id}',
          p.paid ? 'مسددة' : 'غير مسددة',
          p.paid ? TajStatus.success : TajStatus.warning,
        ));
      }
    } else {
      for (final s in store.sales.where((s) => s.customerId == party.id)) {
        final (type, status) = switch (s.status) {
          DemoSaleStatus.paid => ('مبيعات', TajStatus.success),
          DemoSaleStatus.credit => ('آجل', TajStatus.warning),
          DemoSaleStatus.pending => ('قيد التنفيذ', TajStatus.warning),
          DemoSaleStatus.cancelled => ('ملغاة', TajStatus.error),
          DemoSaleStatus.returned => ('مرتجع', TajStatus.error),
        };
        items.add(('فاتورة #${s.id}', type, status));
      }
    }
    final text = Theme.of(context).textTheme;
    if (items.isEmpty) {
      return const TajEmptyState(
        icon: Icons.history_rounded,
        title: 'لا توجد سجلّات',
        message: 'لم تُسجَّل أي عمليات لهذا الطرف بعد.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final (title, type, status) = items[i];
        return Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            StatusBadge(label: type, status: status),
          ],
        );
      },
    );
  }
}
