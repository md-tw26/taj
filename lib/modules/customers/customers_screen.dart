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
  const _Party(this.name, this.phone, this.balance, this.limit, this.last);
  final String name;
  final String phone;
  final double balance; // >0 owes us (debt), <=0 settled
  final double limit;
  final String last;
}

const _customers = <_Party>[
  _Party('سالم المبروك', '0912345678', 450, 2000, '2026/07/20'),
  _Party('نور الهدى', '0923456789', 1200, 1500, '2026/07/20'),
  _Party('خالد عمر', '0934567890', 0, 1000, '2026/07/19'),
  _Party('ليان أحمد', '0945678901', -320, 1000, '2026/07/18'),
  _Party('يوسف علي', '0956789012', 670, 3000, '2026/07/17'),
];

const _suppliers = <_Party>[
  _Party('مؤسسة العطور', '0911122334', 5400, 20000, '2026/07/15'),
  _Party('مستودع البخور', '0922233445', 0, 10000, '2026/07/14'),
  _Party('شركة الزيوت', '0933344556', 2100, 15000, '2026/07/12'),
];

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
              ? DemoStoreProvider.of(
                context,
              ).suppliers.map((s) => _Party(s.name, s.phone, s.balance, 0, ''))
              : DemoStoreProvider.of(context).customers.map(
                (c) => _Party(c.name, c.phone, c.balance, c.creditLimit, ''),
              ))
          .toList();

  List<_Party> get _list =>
      (_storeList.isEmpty
              ? (_suppliersTab ? _suppliers : _customers)
              : _storeList)
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
                  if (name.text.trim().isNotEmpty)
                    Navigator.pop(dialogContext, (
                      name.text.trim(),
                      phone.text.trim(),
                    ));
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
    );
    name.dispose();
    phone.dispose();
    if (result == null || !mounted) return;
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
    if (mounted)
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
                  const _StatementTab(),
                  const _RecordsTab(),
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

class _StatementTab extends StatelessWidget {
  const _StatementTab();
  @override
  Widget build(BuildContext context) {
    final rows = [
      ('2026/07/20', 'فاتورة #1048', 450.0, 0.0, 450.0),
      ('2026/07/16', 'تحصيل نقدي', 0.0, 300.0, 0.0),
      ('2026/07/10', 'فاتورة #1030', 300.0, 0.0, 300.0),
    ];
    final taj = context.taj;
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
  const _RecordsTab();
  @override
  Widget build(BuildContext context) {
    final items = [
      ('فاتورة #1048', 'مبيعات', TajStatus.success),
      ('تحصيل نقدي', 'سداد', TajStatus.info),
      ('مرتجع #1045', 'مرتجع', TajStatus.warning),
    ];
    final text = Theme.of(context).textTheme;
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
