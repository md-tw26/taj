import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_table.dart';
import '../../shared/widgets/taj_ui.dart';

/// ---------------------------------------------------------------------------
/// Users & Permissions (المستخدمون والصلاحيات)
/// ---------------------------------------------------------------------------
///
/// A self-contained admin console: a **Users** tab, a **Roles & Permissions**
/// tab (whose centrepiece is the permission matrix), and an **Audit log** tab.
///
/// Responsive policy — *available space, not device type* (every decision keys
/// off a `LayoutBuilder`'s constraints):
///   • The permission matrix is a 2D grid (permissions × roles). Below
///     [AppBreakpoints.permissionMatrixMin] it is **replaced**, not squeezed, by
///     a role selector + grouped [ExpansionTile] toggle lists that edit one role
///     at a time — same capability, phone-shaped structure.
///   • At/above it the true matrix renders with a **frozen permission-name
///     column** and a **sticky role header**, synchronized bidirectionally
///     (header follows horizontal scroll, first column follows vertical).
///
/// This screen is presentation-only: it never touches [UserRole]/[UserPermissions]
/// enforcement, RBAC or default roles — its grants are an editable admin view.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  // ---- Editable state (demo — RBAC/enforcement untouched) -------------------
  final List<_MgUser> _users = List.of(_seedUsers);
  late Map<String, Set<String>> _grants = _cloneGrants(_seedGrants);
  late Map<String, Set<String>> _saved = _cloneGrants(_seedGrants);
  final List<_Audit> _audit = List.of(_seedAudit);

  // Matrix mid-width: which role columns are visible (default first four).
  late final Set<String> _visibleRoleIds = {
    for (final r in _roles.take(4)) r.id,
  };

  // Alternate (narrow) editor: which single role is being edited.
  String _selectedRoleId = _roles.firstWhere((r) => !r.locked).id;

  // Users tab.
  final _searchCtrl = TextEditingController();
  String _userQuery = '';
  String? _roleFilter; // role id
  bool? _statusFilter; // true=active, false=disabled, null=all
  String? _selectedUserId; // master-detail selection

  // Audit tab.
  String? _auditActionFilter;

  @override
  void initState() {
    super.initState();
    _selectedUserId = _users.isNotEmpty ? _users.first.id : null;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---- Grant helpers --------------------------------------------------------
  static Map<String, Set<String>> _cloneGrants(Map<String, Set<String>> g) =>
      {for (final e in g.entries) e.key: {...e.value}};

  bool get _dirty {
    for (final e in _grants.entries) {
      final s = _saved[e.key];
      if (s == null || s.length != e.value.length || !s.containsAll(e.value)) {
        return true;
      }
    }
    return _grants.length != _saved.length;
  }

  int _groupEnabledCount(String roleId, _PermGroup g) =>
      g.perms.where((p) => _grants[roleId]?.contains(p.id) ?? false).length;

  Future<void> _setGrant(String roleId, _Perm perm, bool value) async {
    final role = _roleById(roleId);
    if (role.locked) return; // inherited / locked — never editable
    if (value && perm.sensitive) {
      final ok = await _confirmSensitive(perm);
      if (!mounted || !ok) return;
    }
    setState(() {
      final set = _grants.putIfAbsent(roleId, () => <String>{});
      if (value) {
        set.add(perm.id);
      } else {
        set.remove(perm.id);
      }
    });
  }

  void _saveGrants() {
    setState(() {
      _saved = _cloneGrants(_grants);
      _audit.insert(
        0,
        _Audit(
          id: 'a${DateTime.now().millisecondsSinceEpoch}',
          actor: 'أنت',
          action: 'حفظ الصلاحيات',
          target: 'الأدوار والصلاحيات',
          time: DateTime.now(),
          before: '—',
          after: 'تم اعتماد تغييرات الصلاحيات',
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الصلاحيات')),
    );
  }

  void _discardGrants() => setState(() => _grants = _cloneGrants(_saved));

  _Role _roleById(String id) =>
      _roles.firstWhere((r) => r.id == id, orElse: () => _roles.first);

  // ==========================================================================
  // Build
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final condense = c.maxHeight < AppBreakpoints.usersCondenseHeaderHeight;
        return Column(
          children: [
            _headerBar(w, condense),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _usersTab(),
                  _permissionsTab(),
                  _auditTab(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _headerBar(double w, bool condense) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final pad = pagePaddingForWidth(w);
    return Container(
      decoration: BoxDecoration(
        color: taj.background,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      padding: EdgeInsets.fromLTRB(pad, condense ? 8 : 14, pad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!condense) ...[
            Text('المستخدمون والصلاحيات', style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'إدارة الحسابات والأدوار والصلاحيات وسجل التدقيق',
              style: text.bodyMedium?.copyWith(color: taj.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
          ] else ...[
            Text('المستخدمون والصلاحيات', style: text.titleLarge),
            const SizedBox(height: 6),
          ],
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: taj.textPrimary,
            unselectedLabelColor: taj.textSecondary,
            indicatorColor: taj.primary.main,
            indicatorWeight: 2.5,
            dividerColor: Colors.transparent,
            labelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: text.titleSmall,
            tabs: const [
              Tab(text: 'المستخدمون'),
              Tab(text: 'الأدوار والصلاحيات'),
              Tab(text: 'سجل التدقيق'),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1 — Users
  // ==========================================================================
  Widget _usersTab() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final pad = pagePaddingForWidth(w);
        return PageContainer(
          maxWidth: AppBreakpoints.usersContentMaxWidth,
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _usersToolbar(w, c.maxHeight),
                const SizedBox(height: 12),
                Expanded(child: _usersBody(w)),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_MgUser> get _filteredUsers {
    final q = _userQuery.trim();
    return _users.where((u) {
      if (q.isNotEmpty &&
          !u.name.contains(q) &&
          !u.username.contains(q)) {
        return false;
      }
      if (_roleFilter != null && u.roleId != _roleFilter) return false;
      if (_statusFilter != null && u.active != _statusFilter) return false;
      return true;
    }).toList();
  }

  Widget _usersToolbar(double w, double h) {
    final taj = context.taj;
    final narrow = w < AppBreakpoints.usersTableCards; // <600
    // On a short viewport (landscape phone) filters collapse into a sheet so the
    // table keeps enough height — same reclaim the spec asks for the selector.
    final short = h < AppBreakpoints.usersCondenseSelectorHeight;
    final showChips = !narrow && !short;
    final activeFilters =
        (_roleFilter != null ? 1 : 0) + (_statusFilter != null ? 1 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _userQuery = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    hintText: 'ابحث بالاسم أو اسم الدخول…',
                    suffixIcon: _userQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _userQuery = '');
                            },
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!narrow)
              FilledButton.icon(
                onPressed: () => _openUserDialog(),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('مستخدم جديد'),
              )
            else
              IconButton.filled(
                onPressed: () => _openUserDialog(),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                tooltip: 'مستخدم جديد',
              ),
          ],
        ),
        if (showChips) ...[
          const SizedBox(height: 10),
          _usersFilterChips(),
        ] else ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openUsersFilterSheet,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(
              activeFilters == 0
                  ? 'تصفية'
                  : 'تصفية (${arNum(activeFilters)})',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: activeFilters == 0 ? taj.textSecondary : taj.primary.main,
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ],
    );
  }

  Widget _usersFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChoice(
          label: 'كل الأدوار',
          selected: _roleFilter == null,
          onTap: () => setState(() => _roleFilter = null),
        ),
        for (final r in _roles)
          _FilterChoice(
            label: r.name,
            selected: _roleFilter == r.id,
            onTap: () => setState(() => _roleFilter = r.id),
          ),
        const _ChipDivider(),
        _FilterChoice(
          label: 'نشط',
          selected: _statusFilter == true,
          onTap: () => setState(
            () => _statusFilter = _statusFilter == true ? null : true,
          ),
        ),
        _FilterChoice(
          label: 'معطّل',
          selected: _statusFilter == false,
          onTap: () => setState(
            () => _statusFilter = _statusFilter == false ? null : false,
          ),
        ),
      ],
    );
  }

  Future<void> _openUsersFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.taj.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final taj = ctx.taj;
            final text = Theme.of(ctx).textTheme;
            void refresh(VoidCallback fn) {
              setLocal(fn);
              setState(fn);
            }

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: size.height * 0.9),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(height: 16),
                      Text('تصفية المستخدمين', style: text.titleLarge),
                      const SizedBox(height: 16),
                      Text('الدور',
                          style: text.titleSmall
                              ?.copyWith(color: taj.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChoice(
                            label: 'الكل',
                            selected: _roleFilter == null,
                            onTap: () =>
                                refresh(() => _roleFilter = null),
                          ),
                          for (final r in _roles)
                            _FilterChoice(
                              label: r.name,
                              selected: _roleFilter == r.id,
                              onTap: () =>
                                  refresh(() => _roleFilter = r.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('الحالة',
                          style: text.titleSmall
                              ?.copyWith(color: taj.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChoice(
                            label: 'الكل',
                            selected: _statusFilter == null,
                            onTap: () =>
                                refresh(() => _statusFilter = null),
                          ),
                          _FilterChoice(
                            label: 'نشط',
                            selected: _statusFilter == true,
                            onTap: () =>
                                refresh(() => _statusFilter = true),
                          ),
                          _FilterChoice(
                            label: 'معطّل',
                            selected: _statusFilter == false,
                            onTap: () =>
                                refresh(() => _statusFilter = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('تم'),
                      ),
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

  Widget _usersBody(double w) {
    final users = _filteredUsers;
    if (users.isEmpty) {
      return const TajEmptyState(
        icon: Icons.person_search_rounded,
        title: 'لا يوجد مستخدمون',
        message: 'لا مستخدمين مطابقين للبحث أو التصفية الحالية.',
      );
    }
    if (w < AppBreakpoints.usersTableCards) {
      return _usersCards(users);
    }
    if (w < AppBreakpoints.usersFullTable) {
      return _usersStickyTable(users);
    }
    if (w < AppBreakpoints.usersMasterDetail) {
      return SingleChildScrollView(child: _usersFullTable(users));
    }
    return _usersMasterDetail(users, w);
  }

  // <600 — cards.
  Widget _usersCards(List<_MgUser> users) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final u = users[i];
        final taj = context.taj;
        final text = Theme.of(context).textTheme;
        return TajCard(
          padding: const EdgeInsets.all(14),
          onTap: () => _openUserDetailSheet(u),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _UserAvatar(name: u.name, active: u.active),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name,
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('@${u.username}',
                            style: text.bodySmall
                                ?.copyWith(color: taj.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(u.active),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _RolePill(role: _roleById(u.roleId)),
                  const SizedBox(width: 8),
                  Icon(Icons.store_mall_directory_outlined,
                      size: 14, color: taj.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(u.branch,
                        style: text.bodySmall
                            ?.copyWith(color: taj.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 600–1024 — frozen name column + sticky header, horizontal scroll.
  Widget _usersStickyTable(List<_MgUser> users) {
    final text = Theme.of(context).textTheme;
    Widget head(String s) => Text(s,
        style: text.bodySmall
            ?.copyWith(color: context.taj.textSecondary, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis);
    return _PinnedGrid(
      frozenWidth: 190,
      frozenHeader: head('المستخدم'),
      cols: [
        _GridCol(width: 130, header: head('الدور')),
        _GridCol(width: 120, header: head('الفرع')),
        _GridCol(width: 150, header: head('آخر نشاط')),
        _GridCol(width: 110, header: head('الحالة')),
      ],
      rows: [
        for (final u in users)
          _GridRow(
            height: 62,
            onTap: () => _openUserDetailSheet(u),
            frozen: _userFrozenCell(u),
            cells: [
              _RolePill(role: _roleById(u.roleId)),
              Text(u.branch,
                  style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(_fmtDateTime(u.lastActive),
                  style: AppThemes.numeralStyle(context, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              _statusBadge(u.active),
            ],
          ),
      ],
    );
  }

  Widget _userFrozenCell(_MgUser u) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        _UserAvatar(name: u.name, active: u.active, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(u.name,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('@${u.username}',
                  style: text.bodySmall
                      ?.copyWith(color: context.taj.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  // 1024–1440 — full table.
  Widget _usersFullTable(List<_MgUser> users) {
    final text = Theme.of(context).textTheme;
    return TajTable(
      columns: const [
        TajColumn('المستخدم', flex: 3),
        TajColumn('الدور', flex: 2),
        TajColumn('الفرع', flex: 2),
        TajColumn('آخر نشاط', flex: 2),
        TajColumn('الحالة', flex: 2),
      ],
      rows: [
        for (final u in users)
          TajRowData(
            onTap: () => _openUserDetailSheet(u),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'تعديل',
                onPressed: () => _openUserDialog(existing: u),
              ),
            ],
            cells: [
              _userFrozenCell(u),
              _RolePill(role: _roleById(u.roleId)),
              Text(u.branch, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(_fmtDateTime(u.lastActive),
                  style: AppThemes.numeralStyle(context, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _statusBadge(u.active),
              ),
            ],
          ),
      ],
    ).withText(text);
  }

  // >1440 — master-detail.
  Widget _usersMasterDetail(List<_MgUser> users, double w) {
    final taj = context.taj;
    final paneW = (w * 0.3).clamp(
      AppBreakpoints.usersListPaneMin,
      AppBreakpoints.usersListPaneMax,
    );
    final selected = users.firstWhere(
      (u) => u.id == _selectedUserId,
      orElse: () => users.first,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: paneW.toDouble(),
          child: Container(
            decoration: BoxDecoration(
              color: taj.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: taj.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: users.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: taj.divider),
              itemBuilder: (_, i) {
                final u = users[i];
                return _UserListTile(
                  user: u,
                  role: _roleById(u.roleId),
                  selected: u.id == selected.id,
                  onTap: () => setState(() => _selectedUserId = u.id),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _userDetailPane(selected)),
      ],
    );
  }

  Widget _userDetailPane(_MgUser u) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final role = _roleById(u.roleId);
    final granted = _grants[role.id] ?? const <String>{};
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TajCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _UserAvatar(name: u.name, active: u.active, size: 56),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name,
                              style: text.headlineSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('@${u.username}',
                              style: text.bodyMedium
                                  ?.copyWith(color: taj.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _statusBadge(u.active),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _detailField('الدور', role.name),
                    _detailField('الفرع', u.branch),
                    _detailField('آخر نشاط', _fmtDateTime(u.lastActive),
                        numeral: true),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _openUserDialog(existing: u),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('تعديل'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _toggleUserActive(u),
                      icon: Icon(
                        u.active
                            ? Icons.block_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                      label: Text(u.active ? 'تعطيل' : 'تفعيل'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TajCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 18, color: taj.primary.main),
                    const SizedBox(width: 8),
                    Text('الصلاحيات الفعّالة (حسب الدور)',
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'مشتقّة من دور «${role.name}». عدّلها من تبويب الأدوار والصلاحيات.',
                  style: text.bodySmall?.copyWith(color: taj.textSecondary),
                ),
                const SizedBox(height: 14),
                for (final g in _permGroups)
                  if (g.perms.any((p) => granted.contains(p.id)))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(g.icon,
                                  size: 15, color: taj.textSecondary),
                              const SizedBox(width: 6),
                              Text(g.name,
                                  style: text.bodySmall?.copyWith(
                                      color: taj.textSecondary,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final p in g.perms)
                                if (granted.contains(p.id))
                                  _PermChip(perm: p),
                            ],
                          ),
                        ],
                      ),
                    ),
                if (granted.isEmpty)
                  Text('لا صلاحيات ممنوحة لهذا الدور.',
                      style:
                          text.bodyMedium?.copyWith(color: taj.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _detailField(String label, String value, {bool numeral = false}) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: text.bodySmall?.copyWith(color: taj.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: numeral
                ? AppThemes.numeralStyle(context, fontSize: 15)
                : text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _toggleUserActive(_MgUser u) {
    setState(() {
      final i = _users.indexWhere((e) => e.id == u.id);
      if (i >= 0) _users[i] = u.copyWith(active: !u.active);
      _audit.insert(
        0,
        _Audit(
          id: 'a${DateTime.now().millisecondsSinceEpoch}',
          actor: 'أنت',
          action: u.active ? 'تعطيل مستخدم' : 'تفعيل مستخدم',
          target: 'المستخدم: ${u.name}',
          time: DateTime.now(),
          before: '{"active": ${u.active}}',
          after: '{"active": ${!u.active}}',
        ),
      );
    });
  }

  Future<void> _openUserDetailSheet(_MgUser u) async {
    final role = _roleById(u.roleId);
    final granted = _grants[role.id] ?? const <String>{};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.taj.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        final taj = ctx.taj;
        final text = Theme.of(ctx).textTheme;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: size.height * 0.9),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _UserAvatar(name: u.name, active: u.active, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.name,
                                style: text.titleLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            Text('@${u.username}',
                                style: text.bodyMedium
                                    ?.copyWith(color: taj.textSecondary)),
                          ],
                        ),
                      ),
                      _statusBadge(u.active),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 24,
                    runSpacing: 14,
                    children: [
                      _detailField('الدور', role.name),
                      _detailField('الفرع', u.branch),
                      _detailField('آخر نشاط', _fmtDateTime(u.lastActive),
                          numeral: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('الصلاحيات الفعّالة',
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final g in _permGroups)
                        for (final p in g.perms)
                          if (granted.contains(p.id)) _PermChip(perm: p),
                      if (granted.isEmpty)
                        Text('لا صلاحيات.',
                            style: text.bodyMedium
                                ?.copyWith(color: taj.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _openUserDialog(existing: u);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('تعديل'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _toggleUserActive(u);
                          },
                          icon: Icon(
                            u.active
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                          label: Text(u.active ? 'تعطيل' : 'تفعيل'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- Add / edit user dialog ----------------------------------------------
  Future<void> _openUserDialog({_MgUser? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final userCtrl = TextEditingController(text: existing?.username ?? '');
    var roleId = existing?.roleId ?? _roles.firstWhere((r) => !r.locked).id;
    var branch = existing?.branch ?? _branches.first;
    var active = existing?.active ?? true;

    // Dialog width caps per size class (≤560 tablet · ≤640 laptop · ≤720 wide;
    // full-width on a phone, handled inside _cappedDialog).
    final sw = MediaQuery.sizeOf(context).width;
    final maxW = sw < AppBreakpoints.tablet
        ? AppBreakpoints.userDialogNarrow
        : sw < AppBreakpoints.laptop
            ? AppBreakpoints.userDialogMid
            : AppBreakpoints.userDialogMax;
    final saved = await _cappedDialog<bool>(
      context,
      title: existing == null ? 'مستخدم جديد' : 'تعديل المستخدم',
      maxWidth: maxW,
      body: (ctx, setLocal) {
        final text = Theme.of(ctx).textTheme;
        final taj = ctx.taj;
        return LayoutBuilder(
          builder: (ctx, c) {
            final twoCol = c.maxWidth >= AppBreakpoints.userFormTwoColumn;
            final nameField = _LabeledField(
              label: 'الاسم الكامل',
              child: TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'مثال: سالم أبوبكر'),
              ),
            );
            final userField = _LabeledField(
              label: 'اسم الدخول',
              child: TextField(
                controller: userCtrl,
                decoration: const InputDecoration(hintText: 'username'),
              ),
            );
            final roleField = _LabeledField(
              label: 'الدور',
              child: DropdownButtonFormField<String>(
                value: roleId,
                isExpanded: true,
                items: [
                  for (final r in _roles)
                    DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) => setLocal(() => roleId = v ?? roleId),
              ),
            );
            final branchField = _LabeledField(
              label: 'الفرع',
              child: DropdownButtonFormField<String>(
                value: branch,
                isExpanded: true,
                items: [
                  for (final b in _branches)
                    DropdownMenuItem(value: b, child: Text(b)),
                ],
                onChanged: (v) => setLocal(() => branch = v ?? branch),
              ),
            );
            Widget pair(Widget a, Widget b) => twoCol
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: a),
                      const SizedBox(width: 14),
                      Expanded(child: b),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [a, const SizedBox(height: 14), b],
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                pair(nameField, userField),
                const SizedBox(height: 14),
                pair(roleField, branchField),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  onChanged: (v) => setLocal(() => active = v),
                  title: Text('الحساب نشط', style: text.bodyLarge),
                  subtitle: Text(
                    'يمكن للمستخدم تسجيل الدخول عند التفعيل.',
                    style: text.bodySmall?.copyWith(color: taj.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: taj.info.lighter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: ctx.taj.accentFor(taj.info)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الصلاحيات المبدئية تُشتقّ من الدور المختار، ويمكن تعديلها لاحقًا من تبويب الأدوار والصلاحيات.',
                          style: text.bodySmall
                              ?.copyWith(color: ctx.taj.accentFor(taj.info)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
      footer: (ctx, setLocal) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );

    final name = nameCtrl.text.trim();
    final username =
        userCtrl.text.trim().isEmpty ? 'user' : userCtrl.text.trim();
    nameCtrl.dispose();
    userCtrl.dispose();
    if (saved != true || name.isEmpty || !mounted) return;

    setState(() {
      if (existing == null) {
        final u = _MgUser(
          id: 'u${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          username: username,
          roleId: roleId,
          branch: branch,
          active: active,
          lastActive: DateTime.now(),
        );
        _users.insert(0, u);
        _selectedUserId = u.id;
        _audit.insert(
          0,
          _Audit(
            id: 'a${DateTime.now().millisecondsSinceEpoch}',
            actor: 'أنت',
            action: 'إضافة مستخدم',
            target: 'المستخدم: $name',
            time: DateTime.now(),
            before: '—',
            after:
                '{"name":"$name","role":"${_roleById(roleId).name}","branch":"$branch","active":$active}',
          ),
        );
      } else {
        final i = _users.indexWhere((e) => e.id == existing.id);
        if (i >= 0) {
          _users[i] = existing.copyWith(
            name: name,
            username: username,
            roleId: roleId,
            branch: branch,
            active: active,
          );
        }
        _audit.insert(
          0,
          _Audit(
            id: 'a${DateTime.now().millisecondsSinceEpoch}',
            actor: 'أنت',
            action: 'تعديل مستخدم',
            target: 'المستخدم: $name',
            time: DateTime.now(),
            before:
                '{"role":"${_roleById(existing.roleId).name}","active":${existing.active}}',
            after:
                '{"role":"${_roleById(roleId).name}","active":$active}',
          ),
        );
      }
    });
  }

  // ==========================================================================
  // TAB 2 — Roles & Permissions
  // ==========================================================================
  Widget _permissionsTab() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final useMatrix = w >= AppBreakpoints.permissionMatrixMin;
        return Column(
          children: [
            Expanded(
              child: useMatrix ? _matrixView(w) : _groupedView(w, h),
            ),
            if (_dirty) _saveBar(),
          ],
        );
      },
    );
  }

  Widget _saveBar() {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Material(
      color: taj.paper,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  size: 20, color: taj.accentFor(taj.warning)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('تغييرات غير محفوظة',
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _discardGrants,
                child: const Text('تجاهل'),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: _saveGrants,
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // >=900 — the matrix.
  Widget _matrixView(double w) {
    final pad = pagePaddingForWidth(w);
    final showAll = w >= AppBreakpoints.permissionMatrixFull;
    final visibleRoles = showAll
        ? _roles
        : _roles.where((r) => _visibleRoleIds.contains(r.id)).toList();
    return PageContainer(
      maxWidth: AppBreakpoints.usersContentMaxWidth,
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 12, pad, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sensitiveBanner(),
            const SizedBox(height: 10),
            if (!showAll) ...[
              _rolesVisibilityControl(),
              const SizedBox(height: 10),
            ],
            Expanded(child: _buildMatrix(visibleRoles, w)),
          ],
        ),
      ),
    );
  }

  Widget _rolesVisibilityControl() {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.view_column_outlined, size: 16, color: taj.textSecondary),
            const SizedBox(width: 6),
            Text('الأدوار المعروضة',
                style: text.bodySmall
                    ?.copyWith(color: taj.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in _roles)
              FilterChip(
                label: Text(r.name),
                selected: _visibleRoleIds.contains(r.id),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _visibleRoleIds.add(r.id);
                    } else if (_visibleRoleIds.length > 1) {
                      _visibleRoleIds.remove(r.id);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatrix(List<_Role> roles, double w) {
    final text = Theme.of(context).textTheme;
    final taj = context.taj;
    return LayoutBuilder(
      builder: (context, c) {
        final nameW = (c.maxWidth * 0.26).clamp(
          AppBreakpoints.permNameColMin,
          AppBreakpoints.permNameColMax,
        );
        final rows = <_GridRow>[];
        for (final g in _permGroups) {
          // Group section row.
          rows.add(
            _GridRow(
              height: 44,
              background: taj.background,
              frozen: Row(
                children: [
                  Icon(g.icon, size: 16, color: taj.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(g.name,
                        style: text.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              cells: [
                for (final r in roles)
                  Text(
                    '${arNum(_groupEnabledCount(r.id, g))}/${arNum(g.perms.length)}',
                    style: text.bodySmall?.copyWith(color: taj.textSecondary),
                  ),
              ],
            ),
          );
          // Permission rows.
          for (final p in g.perms) {
            rows.add(
              _GridRow(
                height: 66,
                frozen: _permNameCell(p),
                cells: [
                  for (final r in roles) _checkCell(r, p),
                ],
              ),
            );
          }
        }
        return _PinnedGrid(
          frozenWidth: nameW.toDouble(),
          headerHeight: 52,
          frozenHeader: Text('الصلاحية',
              style: text.bodySmall?.copyWith(
                  color: taj.textSecondary, fontWeight: FontWeight.w700)),
          cols: [
            for (final r in roles)
              _GridCol(
                width: AppBreakpoints.permRoleColWidth,
                alignment: AlignmentDirectional.center,
                header: _roleHeader(r),
              ),
          ],
          rows: rows,
        );
      },
    );
  }

  Widget _roleHeader(_Role r) {
    final text = Theme.of(context).textTheme;
    final taj = context.taj;
    return Tooltip(
      message: '${r.name} — ${r.description}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(r.name,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
          if (r.locked)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.lock_outline_rounded,
                  size: 12, color: taj.textDisabled),
            ),
        ],
      ),
    );
  }

  Widget _permNameCell(_Perm p) {
    final text = Theme.of(context).textTheme;
    final taj = context.taj;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(p.name,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            if (p.sensitive)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Tooltip(
                  message: 'صلاحية حسّاسة',
                  child: Icon(Icons.shield_outlined,
                      size: 14, color: taj.accentFor(taj.warning)),
                ),
              ),
          ],
        ),
        if (p.description.isNotEmpty)
          Text(p.description,
              style: text.bodySmall?.copyWith(color: taj.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _checkCell(_Role role, _Perm perm) {
    final on = _grants[role.id]?.contains(perm.id) ?? false;
    return _CheckTarget(
      value: on,
      locked: role.locked,
      onTap: role.locked ? null : () => _setGrant(role.id, perm, !on),
    );
  }

  // <900 — grouped alternate structure.
  Widget _groupedView(double w, double h) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final pad = pagePaddingForWidth(w);
    final condensed = h < AppBreakpoints.usersCondenseSelectorHeight;
    final role = _roleById(_selectedRoleId);
    return PageContainer(
      maxWidth: AppBreakpoints.permissionMatrixMin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sensitiveBanner(),
                const SizedBox(height: 12),
                if (condensed)
                  _condensedRoleSelector()
                else
                  _roleSelectorChips(),
                const SizedBox(height: 8),
                if (role.locked)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: taj.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: taj.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 16, color: taj.textDisabled),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'دور «${role.name}» يملك وصولًا كاملًا موروثًا ولا يمكن تعديل صلاحياته.',
                            style: text.bodySmall
                                ?.copyWith(color: taj.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: const Key('perm-groups-list'),
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 16),
              children: [
                for (final g in _permGroups) _groupExpansion(g, role),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleSelectorChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final r in _roles)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(r.name),
                selected: _selectedRoleId == r.id,
                onSelected: (_) => setState(() => _selectedRoleId = r.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _condensedRoleSelector() {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Text('الدور:',
            style:
                text.bodyMedium?.copyWith(color: taj.textSecondary)),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedRoleId,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (final r in _roles)
                DropdownMenuItem(value: r.id, child: Text(r.name)),
            ],
            onChanged: (v) =>
                setState(() => _selectedRoleId = v ?? _selectedRoleId),
          ),
        ),
      ],
    );
  }

  Widget _groupExpansion(_PermGroup g, _Role role) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final count = _groupEnabledCount(role.id, g);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: taj.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: g == _permGroups.first,
          leading: Icon(g.icon, color: taj.primary.main),
          title: Text(g.name,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(
            '${arNum(count)} من ${arNum(g.perms.length)} مفعّلة',
            style: text.bodySmall?.copyWith(color: taj.textSecondary),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
          children: [
            for (final p in g.perms) _permSwitchRow(role, p),
          ],
        ),
      ),
    );
  }

  Widget _permSwitchRow(_Role role, _Perm p) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final on = _grants[role.id]?.contains(p.id) ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(p.name,
                          style: text.bodyLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (p.sensitive) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'صلاحية حسّاسة',
                        child: Icon(Icons.shield_outlined,
                            size: 15, color: taj.accentFor(taj.warning)),
                      ),
                    ],
                  ],
                ),
                if (p.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(p.description,
                        style: text.bodySmall
                            ?.copyWith(color: taj.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: on,
            onChanged:
                role.locked ? null : (v) => _setGrant(role.id, p, v),
          ),
        ],
      ),
    );
  }

  // ---- Sensitive-permission warning ----------------------------------------
  Widget _sensitiveBanner() {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final accent = taj.accentFor(taj.warning);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: taj.warning.lighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'الصلاحيات المُعلّمة بدرع حسّاسة (تعديل الأسعار، الخصومات، الاسترداد، الإغلاق اليومي، ترحيل القيود…). امنحها بحذر — يُطلب تأكيد عند تفعيلها.',
              style: text.bodySmall?.copyWith(color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmSensitive(_Perm p) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final taj = ctx.taj;
        final text = Theme.of(ctx).textTheme;
        return AlertDialog(
          backgroundColor: taj.paper,
          title: Row(
            children: [
              Icon(Icons.shield_outlined,
                  color: taj.accentFor(taj.warning), size: 22),
              const SizedBox(width: 10),
              const Expanded(child: Text('صلاحية حسّاسة')),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              'أنت على وشك منح صلاحية «${p.name}». هذه صلاحية حسّاسة قد تؤثر على '
              'الأموال أو البيانات. هل تريد المتابعة؟',
              style: text.bodyMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('منح الصلاحية'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // ==========================================================================
  // TAB 3 — Audit log
  // ==========================================================================
  Widget _auditTab() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final pad = pagePaddingForWidth(w);
        return PageContainer(
          maxWidth: AppBreakpoints.usersContentMaxWidth,
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _auditToolbar(w, c.maxHeight),
                const SizedBox(height: 12),
                Expanded(child: _auditBody(w)),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_Audit> get _filteredAudit => _auditActionFilter == null
      ? _audit
      : _audit.where((a) => a.action == _auditActionFilter).toList();

  Widget _auditToolbar(double w, double h) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final short = h < AppBreakpoints.usersCondenseSelectorHeight;
    final grouped = w >= AppBreakpoints.permissionMatrixFull; // >=1440
    final actions = <String>{for (final a in _audit) a.action}.toList();
    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChoice(
          label: 'كل الأحداث',
          selected: _auditActionFilter == null,
          onTap: () => setState(() => _auditActionFilter = null),
        ),
        for (final a in actions)
          _FilterChoice(
            label: a,
            selected: _auditActionFilter == a,
            onTap: () => setState(() => _auditActionFilter = a),
          ),
      ],
    );
    if (w < AppBreakpoints.usersTableCards || short) {
      // <600 or short viewport — a filter button opening a sheet keeps room.
      final active = _auditActionFilter != null;
      return OutlinedButton.icon(
        onPressed: _openAuditFilterSheet,
        icon: const Icon(Icons.tune_rounded, size: 18),
        label: Text(active ? 'تصفية: ${_auditActionFilter!}' : 'تصفية الأحداث'),
        style: OutlinedButton.styleFrom(
          foregroundColor: active ? taj.primary.main : taj.textSecondary,
          minimumSize: const Size.fromHeight(44),
        ),
      );
    }
    if (!grouped) return chips;
    // >=1440 — grouped, labelled cluster.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('نوع الحدث:',
              style: text.bodyMedium?.copyWith(
                  color: taj.textSecondary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        Expanded(child: chips),
      ],
    );
  }

  Future<void> _openAuditFilterSheet() async {
    final actions = <String>{for (final a in _audit) a.action}.toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.taj.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        final taj = ctx.taj;
        final text = Theme.of(ctx).textTheme;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: size.height * 0.9),
            child: StatefulBuilder(
              builder: (ctx, setLocal) {
                void pick(String? v) {
                  setLocal(() {});
                  setState(() => _auditActionFilter = v);
                  Navigator.of(ctx).pop();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(height: 16),
                      Text('تصفية الأحداث', style: text.titleLarge),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('كل الأحداث'),
                        trailing: _auditActionFilter == null
                            ? Icon(Icons.check_rounded,
                                color: taj.primary.main)
                            : null,
                        onTap: () => pick(null),
                      ),
                      for (final a in actions)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(a),
                          trailing: _auditActionFilter == a
                              ? Icon(Icons.check_rounded,
                                  color: taj.primary.main)
                              : null,
                          onTap: () => pick(a),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _auditBody(double w) {
    final entries = _filteredAudit;
    if (entries.isEmpty) {
      return const TajEmptyState(
        icon: Icons.history_rounded,
        title: 'لا سجلّات',
        message: 'لا أحداث مطابقة للتصفية الحالية.',
      );
    }
    if (w < AppBreakpoints.usersTableCards) {
      return _auditCards(entries);
    }
    return _auditTable(entries);
  }

  Widget _auditCards(List<_Audit> entries) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final a = entries[i];
        return TajCard(
          padding: const EdgeInsets.all(14),
          onTap: () => _openAuditDetail(a),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _UserAvatar(name: a.actor, active: true, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.action,
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(a.actor,
                            style: text.bodySmall
                                ?.copyWith(color: taj.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_fmtDateTime(a.time),
                      style: AppThemes.numeralStyle(context, fontSize: 12)
                          .copyWith(color: taj.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              Text(a.target,
                  style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.chevron_left_rounded,
                      size: 16, color: taj.textSecondary),
                  Expanded(
                    child: Text('التفاصيل (قبل / بعد)',
                        style: text.bodySmall
                            ?.copyWith(color: taj.textSecondary)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _auditTable(List<_Audit> entries) {
    final text = Theme.of(context).textTheme;
    final taj = context.taj;
    Widget head(String s) => Text(s,
        style: text.bodySmall
            ?.copyWith(color: taj.textSecondary, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis);
    Widget clamp2(String s) => Text(s,
        style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis);
    return _PinnedGrid(
      frozenWidth: 150,
      frozenHeader: head('الوقت'),
      cols: [
        _GridCol(width: 130, header: head('المستخدم')),
        _GridCol(width: 150, header: head('الحدث')),
        _GridCol(width: 170, header: head('العنصر')),
        _GridCol(width: 200, header: head('قبل')),
        _GridCol(width: 200, header: head('بعد')),
      ],
      rows: [
        for (final a in entries)
          _GridRow(
            height: 66,
            onTap: () => _openAuditDetail(a),
            frozen: Text(_fmtDateTime(a.time),
                style: AppThemes.numeralStyle(context, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            cells: [
              Text(a.actor,
                  style: text.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(a.action,
                  style: text.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(a.target,
                  style: text.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              clamp2(a.before),
              clamp2(a.after),
            ],
          ),
      ],
    );
  }

  Future<void> _openAuditDetail(_Audit a) async {
    await _cappedDialog<void>(
      context,
      title: a.action,
      maxWidth: AppBreakpoints.userDialogNarrow,
      body: (ctx, setLocal) {
        final taj = ctx.taj;
        final text = Theme.of(ctx).textTheme;
        Widget block(String label, String value, TajStatus tint) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label,
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ctx.taj.swatch(tint).lighter,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(value,
                      style: text.bodyMedium
                          ?.copyWith(color: ctx.taj.accentFor(ctx.taj.swatch(tint)))),
                ),
              ],
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _detailField('المستخدم', a.actor),
                _detailField('العنصر', a.target),
                _detailField('الوقت', _fmtDateTime(a.time), numeral: true),
              ],
            ),
            const SizedBox(height: 20),
            block('قبل', a.before, TajStatus.error),
            const SizedBox(height: 14),
            block('بعد', a.after, TajStatus.success),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'سجل التدقيق للقراءة فقط ولا يمكن تعديله.',
                style: text.bodySmall?.copyWith(color: taj.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---- Shared bits ----------------------------------------------------------
  Widget _statusBadge(bool active) => StatusBadge(
        label: active ? 'نشط' : 'معطّل',
        status: active ? TajStatus.success : TajStatus.error,
      );
}

// ===========================================================================
// Reusable: a capped, height-limited, keyboard-safe dialog with sticky footer.
// ===========================================================================
Future<T?> _cappedDialog<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext, StateSetter) body,
  Widget Function(BuildContext, StateSetter)? footer,
  double maxWidth = 640,
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
          final maxH = (size.height - insets) * 0.9;
          return Dialog(
            insetPadding:
                EdgeInsets.symmetric(horizontal: phone ? 8 : 24, vertical: 24),
            backgroundColor: taj.paper,
            child: Padding(
              padding: EdgeInsets.only(bottom: insets),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: dialogW, maxHeight: maxH),
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
                                style: Theme.of(ctx).textTheme.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
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

// ===========================================================================
// Reusable: a pinned grid — frozen first column + sticky header, synchronized
// bidirectional scrolling. The frozen column sits *inside* the single vertical
// scroll (so it follows vertical scroll) but *outside* the horizontal scroll
// (so it stays put); the sticky header sits above the vertical scroll and is
// driven horizontally by the body's controller (header follows horizontal
// scroll). Directional widgets keep it correct in both RTL and LTR.
// ===========================================================================
class _GridCol {
  const _GridCol({
    required this.width,
    required this.header,
    this.alignment = AlignmentDirectional.centerStart,
  });
  final double width;
  final Widget header;
  final AlignmentGeometry alignment;
}

class _GridRow {
  const _GridRow({
    required this.frozen,
    required this.cells,
    required this.height,
    this.onTap,
    this.background,
  });
  final Widget frozen;
  final List<Widget> cells;
  final double height;
  final VoidCallback? onTap;
  final Color? background;
}

class _PinnedGrid extends StatefulWidget {
  const _PinnedGrid({
    required this.frozenWidth,
    required this.frozenHeader,
    required this.cols,
    required this.rows,
    this.headerHeight = 48,
  });

  final double frozenWidth;
  final Widget frozenHeader;
  final List<_GridCol> cols;
  final List<_GridRow> rows;
  final double headerHeight;

  @override
  State<_PinnedGrid> createState() => _PinnedGridState();
}

class _PinnedGridState extends State<_PinnedGrid> {
  final _bodyH = ScrollController();
  final _headerH = ScrollController();

  @override
  void initState() {
    super.initState();
    _bodyH.addListener(_sync);
  }

  // Body (horizontal) drives the header — header follows horizontal scroll.
  void _sync() {
    if (!_bodyH.hasClients || !_headerH.hasClients) return;
    final target = _bodyH.offset.clamp(0.0, _headerH.position.maxScrollExtent);
    if ((_headerH.offset - target).abs() > 0.5) _headerH.jumpTo(target);
  }

  @override
  void dispose() {
    _bodyH.dispose();
    _headerH.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final restWidth = widget.cols.fold<double>(0, (s, c) => s + c.width);
    final frozenW = widget.frozenWidth;

    Widget headerCell(_GridCol col) => SizedBox(
          width: col.width,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            child: Align(alignment: col.alignment, child: col.header),
          ),
        );

    final header = Container(
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      height: widget.headerHeight,
      child: Row(
        children: [
          SizedBox(
            width: frozenW,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: widget.frozenHeader,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _headerH,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: restWidth,
                child: Row(children: [for (final c in widget.cols) headerCell(c)]),
              ),
            ),
          ),
        ],
      ),
    );

    Widget frozenCell(_GridRow r) => GestureDetector(
          onTap: r.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: frozenW,
            height: r.height,
            decoration: BoxDecoration(
              color: r.background,
              border: Border(bottom: BorderSide(color: taj.divider)),
            ),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
            alignment: AlignmentDirectional.centerStart,
            child: r.frozen,
          ),
        );

    Widget restRow(_GridRow r) => GestureDetector(
          onTap: r.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: r.height,
            decoration: BoxDecoration(
              color: r.background,
              border: Border(bottom: BorderSide(color: taj.divider)),
            ),
            child: Row(
              children: [
                for (var i = 0; i < widget.cols.length; i++)
                  SizedBox(
                    width: widget.cols[i].width,
                    height: r.height,
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.symmetric(horizontal: 8),
                      child: Align(
                        alignment: widget.cols[i].alignment,
                        child: i < r.cells.length
                            ? r.cells[i]
                            : const SizedBox.shrink(),
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
          Column(children: [for (final r in widget.rows) frozenCell(r)]),
          Expanded(
            child: SingleChildScrollView(
              controller: _bodyH,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: restWidth,
                child: Column(
                  children: [for (final r in widget.rows) restRow(r)],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: taj.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: taj.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [header, Expanded(child: body)]),
    );
  }
}

// ===========================================================================
// Small widgets
// ===========================================================================

/// A ≥44px checkbox tap target that keeps a distinct *icon* per state — checked
/// (filled check-box), unchecked (empty box) and locked/inherited (lock) — so
/// state is never conveyed by colour alone, and never blows out the cell width.
class _CheckTarget extends StatelessWidget {
  const _CheckTarget({required this.value, this.locked = false, this.onTap});
  final bool value;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final IconData icon;
    final Color color;
    if (locked) {
      icon = Icons.lock_rounded;
      color = taj.textDisabled;
    } else if (value) {
      icon = Icons.check_box_rounded;
      color = taj.primary.main;
    } else {
      icon = Icons.check_box_outline_blank_rounded;
      color = taj.textDisabled;
    }
    return Tooltip(
      message: locked
          ? 'موروثة — لا يمكن تعطيلها'
          : (value ? 'ممنوحة' : 'غير ممنوحة'),
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 24, color: color),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, required this.active, this.size = 40});
  final String name;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final swatch = active ? taj.primary : taj.neutral;
    final initial = name.trim().isEmpty ? '؟' : name.trim().characters.first;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: swatch.lighter, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(
          color: taj.accentFor(swatch),
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});
  final _Role role;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: taj.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (role.locked) ...[
            Icon(Icons.lock_outline_rounded, size: 12, color: taj.textSecondary),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(role.name,
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _PermChip extends StatelessWidget {
  const _PermChip({required this.perm});
  final _Perm perm;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final sensitive = perm.sensitive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: sensitive ? taj.warning.lighter : taj.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: sensitive ? taj.warning.light : taj.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sensitive) ...[
            Icon(Icons.shield_outlined,
                size: 12, color: taj.accentFor(taj.warning)),
            const SizedBox(width: 4),
          ],
          Text(perm.name,
              style: text.bodySmall?.copyWith(
                color: sensitive
                    ? taj.accentFor(taj.warning)
                    : taj.textSecondary,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  const _UserListTile({
    required this.user,
    required this.role,
    required this.selected,
    required this.onTap,
  });
  final _MgUser user;
  final _Role role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? taj.primary.lighter : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _UserAvatar(name: user.name, active: user.active, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style:
                          text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('${role.name} · ${user.branch}',
                      style: text.bodySmall
                          ?.copyWith(color: taj.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: user.active ? taj.success.main : taj.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: text.bodySmall?.copyWith(
                color: taj.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ChipDivider extends StatelessWidget {
  const _ChipDivider();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 28,
        child: VerticalDivider(width: 12, color: context.taj.divider),
      );
}

/// Applies a text theme wrapper (no-op passthrough kept for readability).
extension _TableTextX on TajTable {
  Widget withText(TextTheme _) => this;
}

// ===========================================================================
// Local presentation models + demo seed data (module-scoped; RBAC untouched).
// ===========================================================================
class _Role {
  const _Role(this.id, this.name, this.description, {this.locked = false});
  final String id;
  final String name;
  final String description;

  /// A locked role's grants are inherited and cannot be edited (e.g. system
  /// admin always has full access) — rendered with a lock marker, not colour.
  final bool locked;
}

class _Perm {
  const _Perm(this.id, this.name, this.description, {this.sensitive = false});
  final String id;
  final String name;
  final String description;
  final bool sensitive;
}

class _PermGroup {
  const _PermGroup(this.name, this.icon, this.perms);
  final String name;
  final IconData icon;
  final List<_Perm> perms;
}

class _MgUser {
  const _MgUser({
    required this.id,
    required this.name,
    required this.username,
    required this.roleId,
    required this.branch,
    required this.active,
    required this.lastActive,
  });
  final String id;
  final String name;
  final String username;
  final String roleId;
  final String branch;
  final bool active;
  final DateTime lastActive;

  _MgUser copyWith({
    String? name,
    String? username,
    String? roleId,
    String? branch,
    bool? active,
    DateTime? lastActive,
  }) =>
      _MgUser(
        id: id,
        name: name ?? this.name,
        username: username ?? this.username,
        roleId: roleId ?? this.roleId,
        branch: branch ?? this.branch,
        active: active ?? this.active,
        lastActive: lastActive ?? this.lastActive,
      );
}

class _Audit {
  const _Audit({
    required this.id,
    required this.actor,
    required this.action,
    required this.target,
    required this.time,
    required this.before,
    required this.after,
  });
  final String id;
  final String actor;
  final String action;
  final String target;
  final DateTime time;
  final String before;
  final String after;
}

const _branches = ['الرئيسي', 'طرابلس', 'بنغازي', 'مصراتة'];

const _roles = <_Role>[
  _Role('admin', 'مدير النظام', 'وصول كامل', locked: true),
  _Role('owner', 'صاحب المتجر', 'إدارة المتجر'),
  _Role('supervisor', 'مشرف', 'إشراف على الورديات'),
  _Role('accountant', 'محاسب', 'المالية والقيود'),
  _Role('inventory', 'أمين المخزن', 'المخزون والجرد'),
  _Role('cashier', 'كاشير', 'نقطة البيع فقط'),
];

const _permGroups = <_PermGroup>[
  _PermGroup('المبيعات', Icons.receipt_long_outlined, [
    _Perm('sales_create', 'إنشاء فاتورة بيع', 'تسجيل عملية بيع جديدة'),
    _Perm('sales_edit_price', 'تعديل السعر', 'تغيير سعر بند يدويًا',
        sensitive: true),
    _Perm('sales_discount', 'تطبيق خصم يدوي', 'منح خصم على الفاتورة',
        sensitive: true),
    _Perm('sales_refund', 'استرداد / مرتجع', 'إرجاع الأموال للعميل',
        sensitive: true),
  ]),
  _PermGroup('نقطة البيع', Icons.storefront_outlined, [
    _Perm('pos_open', 'فتح نقطة البيع', 'بدء وردية وفتح الصندوق'),
    _Perm('pos_execute', 'تنفيذ عملية بيع', 'إتمام الدفع والبيع'),
    _Perm('pos_discount', 'خصم في نقطة البيع', 'خصم سريع أثناء البيع',
        sensitive: true),
    _Perm('pos_void', 'إلغاء عملية', 'إبطال فاتورة قبل الدفع', sensitive: true),
    _Perm('pos_return', 'إرجاع صنف', 'إرجاع صنف في نقطة البيع', sensitive: true),
    _Perm('pos_hold', 'تعليق الطلب', 'حفظ الطلب مؤقتًا'),
    _Perm('pos_print', 'طباعة الإيصال', 'إعادة طباعة إيصال البيع'),
    _Perm('pos_review_closing', 'مراجعة الإغلاق اليومي',
        'اعتماد إغلاق وردية الصندوق',
        sensitive: true),
  ]),
  _PermGroup('المخزون', Icons.inventory_2_outlined, [
    _Perm('inv_view', 'عرض المخزون', 'الاطلاع على الأرصدة'),
    _Perm('inv_adjust', 'تسوية المخزون', 'تعديل الكميات بعد الجرد',
        sensitive: true),
    _Perm('inv_transfer', 'تحويل بين الفروع', 'نقل بضاعة بين المستودعات'),
    _Perm('inv_count', 'جرد المخزون', 'تنفيذ جلسة جرد'),
  ]),
  _PermGroup('المحاسبة', Icons.account_balance_outlined, [
    _Perm('acc_view', 'عرض القيود', 'الاطلاع على دفتر اليومية'),
    _Perm('acc_post', 'ترحيل قيد', 'اعتماد قيد محاسبي', sensitive: true),
    _Perm('acc_reverse', 'عكس قيد', 'إلغاء قيد مُرحَّل', sensitive: true),
    _Perm('acc_reports', 'التقارير المالية', 'عرض القوائم المالية'),
  ]),
  _PermGroup('الرواتب', Icons.payments_outlined, [
    _Perm('pay_view', 'عرض الرواتب', 'الاطلاع على كشوف الرواتب'),
    _Perm('pay_process', 'صرف الرواتب', 'اعتماد وصرف الرواتب', sensitive: true),
    _Perm('pay_advance', 'صرف سلفة', 'منح سلفة لموظف'),
  ]),
  _PermGroup('الإعدادات', Icons.settings_outlined, [
    _Perm('set_users', 'إدارة المستخدمين', 'إضافة وتعطيل المستخدمين',
        sensitive: true),
    _Perm('set_roles', 'تعديل الأدوار والصلاحيات', 'تغيير صلاحيات الأدوار',
        sensitive: true),
    _Perm('set_branches', 'إدارة الفروع', 'إضافة وتعديل الفروع'),
    _Perm('set_system', 'إعدادات النظام', 'تكوين النظام العام',
        sensitive: true),
  ]),
];

Set<String> get _allPermIds =>
    {for (final g in _permGroups) for (final p in g.perms) p.id};

final Map<String, Set<String>> _seedGrants = {
  // Admin — full access, inherited/locked.
  'admin': {..._allPermIds},
  // Owner — everything except raw system config.
  'owner': {..._allPermIds}..remove('set_system'),
  'supervisor': {
    'sales_create', 'sales_discount', 'sales_refund',
    'pos_open', 'pos_execute', 'pos_discount', 'pos_void', 'pos_return',
    'pos_hold', 'pos_print', 'pos_review_closing',
    'inv_view', 'inv_transfer', 'inv_count',
    'acc_view', 'pay_view',
  },
  'accountant': {
    'acc_view', 'acc_post', 'acc_reverse', 'acc_reports',
    'pay_view', 'inv_view',
  },
  'inventory': {
    'inv_view', 'inv_adjust', 'inv_transfer', 'inv_count',
  },
  // Cashier — mirrors the enforced RBAC: no price edit / discount / refund /
  // reports. POS basics only.
  'cashier': {
    'sales_create', 'pos_open', 'pos_execute', 'pos_hold', 'pos_print',
    'inv_view',
  },
};

final List<_MgUser> _seedUsers = [
  _MgUser(
    id: 'u1',
    name: 'عبدالله القذافي',
    username: 'abdullah',
    roleId: 'admin',
    branch: 'الرئيسي',
    active: true,
    lastActive: DateTime(2026, 9, 11, 9, 12),
  ),
  _MgUser(
    id: 'u2',
    name: 'فاطمة الزائدي',
    username: 'fatima',
    roleId: 'owner',
    branch: 'طرابلس',
    active: true,
    lastActive: DateTime(2026, 9, 11, 8, 40),
  ),
  _MgUser(
    id: 'u3',
    name: 'محمد الترهوني',
    username: 'mohammed',
    roleId: 'supervisor',
    branch: 'طرابلس',
    active: true,
    lastActive: DateTime(2026, 9, 10, 21, 5),
  ),
  _MgUser(
    id: 'u4',
    name: 'سارة بن نور',
    username: 'sara',
    roleId: 'accountant',
    branch: 'الرئيسي',
    active: true,
    lastActive: DateTime(2026, 9, 11, 7, 55),
  ),
  _MgUser(
    id: 'u5',
    name: 'خالد مخلوف',
    username: 'khaled',
    roleId: 'inventory',
    branch: 'بنغازي',
    active: true,
    lastActive: DateTime(2026, 9, 9, 16, 30),
  ),
  _MgUser(
    id: 'u6',
    name: 'نادية عبد السلام',
    username: 'nadia',
    roleId: 'cashier',
    branch: 'بنغازي',
    active: true,
    lastActive: DateTime(2026, 9, 11, 10, 2),
  ),
  _MgUser(
    id: 'u7',
    name: 'علي الطرابلسي',
    username: 'ali',
    roleId: 'cashier',
    branch: 'مصراتة',
    active: false,
    lastActive: DateTime(2026, 8, 28, 14, 18),
  ),
];

final List<_Audit> _seedAudit = [
  _Audit(
    id: 'a1',
    actor: 'عبدالله القذافي',
    action: 'تعديل صلاحية',
    target: 'الدور: كاشير',
    time: DateTime(2026, 9, 11, 9, 15),
    before: '{"pos_discount": false}',
    after: '{"pos_discount": true}',
  ),
  _Audit(
    id: 'a2',
    actor: 'عبدالله القذافي',
    action: 'إضافة مستخدم',
    target: 'المستخدم: نادية عبد السلام',
    time: DateTime(2026, 9, 10, 12, 3),
    before: '—',
    after:
        '{"name":"نادية عبد السلام","role":"كاشير","branch":"بنغازي","active":true}',
  ),
  _Audit(
    id: 'a3',
    actor: 'فاطمة الزائدي',
    action: 'تعطيل مستخدم',
    target: 'المستخدم: علي الطرابلسي',
    time: DateTime(2026, 8, 28, 14, 20),
    before: '{"active": true}',
    after: '{"active": false}',
  ),
  _Audit(
    id: 'a4',
    actor: 'سارة بن نور',
    action: 'تسجيل دخول',
    target: 'جلسة',
    time: DateTime(2026, 9, 11, 7, 55),
    before: '—',
    after: '{"ip":"10.0.0.14","device":"Windows"}',
  ),
  _Audit(
    id: 'a5',
    actor: 'عبدالله القذافي',
    action: 'تعديل صلاحية',
    target: 'الدور: مشرف',
    time: DateTime(2026, 9, 9, 18, 42),
    before: '{"acc_post": true}',
    after: '{"acc_post": false}',
  ),
  _Audit(
    id: 'a6',
    actor: 'محمد الترهوني',
    action: 'تسجيل دخول',
    target: 'جلسة',
    time: DateTime(2026, 9, 10, 21, 4),
    before: '—',
    after: '{"ip":"10.0.0.31","device":"Android"}',
  ),
];

String _two(int v) => v < 10 ? '0$v' : '$v';
String _fmtDateTime(DateTime d) =>
    '${d.year}/${_two(d.month)}/${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
