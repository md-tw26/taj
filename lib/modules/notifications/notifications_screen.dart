import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_ui.dart';

// ---------------------------------------------------------------------------
// Notifications (الإشعارات)
// ---------------------------------------------------------------------------
//
// The module lives in two places that share ONE state source (_hub):
//   • NotificationsScreen — the full notification centre (nav id `inbox`).
//       < inboxSplit → full-width list; tapping pushes a detail page.
//       ≥ inboxSplit → two panes (list + detail), capped + centred at
//       inboxContentMaxWidth.
//   • NotificationBell — the top-bar bell + count badge.
//       phone width → opens the full page · short viewport → bottom sheet ·
//       otherwise → an anchored popover clamped inside the window.
//
// Presentation-only: it seeds its own richer model (the shared DemoStore
// notification model has no type/priority) and manages read-state locally —
// it never changes notification sources, logic or navigation targets.

// ===========================================================================
// Model + shared state hub
// ===========================================================================
enum _NType { inventory, sales, finance, approval, system }

enum _NPrio { high, normal }

enum _ReadFilter { all, unread, read }

enum _GroupMode { time, type, prio }

class _Notif {
  _Notif({
    required this.id,
    required this.type,
    required this.prio,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });
  final String id;
  final _NType type;
  final _NPrio prio;
  final String title;
  final String body;
  final DateTime time;
  bool read;
}

typedef _TypeMeta = ({IconData icon, TajStatus tint, String label});

_TypeMeta _typeMeta(_NType t) => switch (t) {
      _NType.inventory => (
          icon: Icons.inventory_2_outlined,
          tint: TajStatus.warning,
          label: 'المخزون'
        ),
      _NType.sales => (
          icon: Icons.point_of_sale_outlined,
          tint: TajStatus.success,
          label: 'المبيعات'
        ),
      _NType.finance => (
          icon: Icons.account_balance_outlined,
          tint: TajStatus.info,
          label: 'المالية'
        ),
      _NType.approval => (
          icon: Icons.verified_outlined,
          tint: TajStatus.primary,
          label: 'موافقات'
        ),
      _NType.system => (
          icon: Icons.settings_suggest_outlined,
          tint: TajStatus.secondary,
          label: 'النظام'
        ),
    };

/// Shared, in-memory notification state. Both the bell and the centre listen to
/// it, so marking read anywhere updates everywhere. Seeded with demo data.
class _NotifHub extends ChangeNotifier {
  final List<_Notif> items = _seed();

  int get unread => items.where((n) => !n.read).length;

  void markRead(String id) {
    for (final n in items) {
      if (n.id == id && !n.read) {
        n.read = true;
        notifyListeners();
        return;
      }
    }
  }

  void toggleRead(String id) {
    for (final n in items) {
      if (n.id == id) {
        n.read = !n.read;
        notifyListeners();
        return;
      }
    }
  }

  void markAllRead() {
    var changed = false;
    for (final n in items) {
      if (!n.read) {
        n.read = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}

final _NotifHub _hub = _NotifHub();

List<_Notif> _seed() {
  final now = DateTime.now();
  DateTime ago({int d = 0, int h = 0, int m = 0}) =>
      now.subtract(Duration(days: d, hours: h, minutes: m));
  return [
    _Notif(
      id: 'n1',
      type: _NType.inventory,
      prio: _NPrio.high,
      title: 'مخزون منخفض: عود ملكي',
      body:
          'صنف «عود ملكي» وصل إلى 3 وحدات في فرع طرابلس الرئيسي، أقل من حد إعادة الطلب (5). يُنصح بإصدار أمر شراء.',
      time: ago(m: 3),
    ),
    _Notif(
      id: 'n2',
      type: _NType.approval,
      prio: _NPrio.high,
      title: 'طلب خصم بانتظار الموافقة',
      body:
          'طلب الكاشير نادية عبد السلام خصمًا يدويًا بنسبة 15% على الفاتورة #ش٢٣٠ ويتجاوز حدّ صلاحيتها.',
      time: ago(m: 21),
    ),
    _Notif(
      id: 'n3',
      type: _NType.sales,
      prio: _NPrio.normal,
      title: 'تم إغلاق وردية الصباح',
      body: 'أُغلقت وردية الصباح في فرع بنغازي بإجمالي مبيعات 4,820 د.ل.',
      time: ago(h: 2),
    ),
    _Notif(
      id: 'n4',
      type: _NType.finance,
      prio: _NPrio.normal,
      title: 'قيد محاسبي بانتظار الترحيل',
      body: 'قيد مصروفات الإيجار لشهر سبتمبر في حالة مسودة ولم يُرحَّل بعد.',
      time: ago(h: 5),
    ),
    _Notif(
      id: 'n5',
      type: _NType.system,
      prio: _NPrio.normal,
      title: 'اكتملت المزامنة',
      body: 'تمت مزامنة بيانات الفروع الثلاثة بنجاح.',
      time: ago(h: 8),
      read: true,
    ),
    _Notif(
      id: 'n6',
      type: _NType.sales,
      prio: _NPrio.normal,
      title: 'فاتورة آجلة مستحقة',
      body:
          'فاتورة العميل محمد الترهوني #ش١٩٨ بقيمة 1,250 د.ل تستحق السداد خلال يومين.',
      time: ago(d: 1, h: 1),
    ),
    _Notif(
      id: 'n7',
      type: _NType.inventory,
      prio: _NPrio.normal,
      title: 'انتهت تسوية الجرد',
      body: 'اعتُمدت تسوية جرد مستودع مصراتة مع فروقات طفيفة بقيمة 70 د.ل.',
      time: ago(d: 1, h: 4),
      read: true,
    ),
    _Notif(
      id: 'n8',
      type: _NType.approval,
      prio: _NPrio.normal,
      title: 'طلب استرداد مرتجع',
      body: 'طلب مرتجع لصنفين على الفاتورة #ش١٧٧ بانتظار موافقة المشرف.',
      time: ago(d: 1, h: 6),
    ),
    _Notif(
      id: 'n9',
      type: _NType.finance,
      prio: _NPrio.high,
      title: 'تجاوز سقف المصروفات',
      body:
          'تجاوزت مصروفات التشغيل لفرع طرابلس سقف الميزانية الشهري بنسبة 8% قبل نهاية الشهر.',
      time: ago(d: 3, h: 2),
    ),
    _Notif(
      id: 'n10',
      type: _NType.system,
      prio: _NPrio.normal,
      title: 'تحديث متوفّر',
      body: 'يتوفّر تحديث جديد للنظام يتضمّن تحسينات على التقارير الذكية.',
      time: ago(d: 4),
      read: true,
    ),
    _Notif(
      id: 'n11',
      type: _NType.sales,
      prio: _NPrio.normal,
      title: 'هدف المبيعات اليومي تحقق',
      body: 'بلغ فرع بنغازي هدف المبيعات اليومي قبل الساعة الخامسة مساءً.',
      time: ago(d: 5, h: 3),
      read: true,
    ),
    _Notif(
      id: 'n12',
      type: _NType.inventory,
      prio: _NPrio.normal,
      title: 'وصول شحنة موردين',
      body: 'سُجّلت فاتورة شراء جديدة من مؤسسة العطور وتم تحديث المخزون.',
      time: ago(d: 6, h: 2),
      read: true,
    ),
  ];
}

// ===========================================================================
// Notification centre
// ===========================================================================
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _ReadFilter _readFilter = _ReadFilter.all;
  _NType? _typeFilter; // null = all types
  _GroupMode _group = _GroupMode.time;
  String? _selectedId;

  List<_Notif> get _filtered {
    final items = _hub.items.where((n) {
      if (_readFilter == _ReadFilter.unread && n.read) return false;
      if (_readFilter == _ReadFilter.read && !n.read) return false;
      if (_typeFilter != null && n.type != _typeFilter) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  /// Flatten the filtered notifications into a header/tile row list so the
  /// ListView.builder renders them with no fixed-height assumptions.
  List<Object> _rows(List<_Notif> items) {
    final rows = <Object>[];
    if (_group == _GroupMode.time) {
      const order = ['اليوم', 'الأمس', 'هذا الأسبوع', 'أقدم'];
      final buckets = <String, List<_Notif>>{};
      for (final n in items) {
        buckets.putIfAbsent(_timeBucket(n.time), () => []).add(n);
      }
      for (final key in order) {
        final list = buckets[key];
        if (list != null && list.isNotEmpty) {
          rows.add(_Header(key, list.length));
          rows.addAll(list);
        }
      }
    } else if (_group == _GroupMode.type) {
      for (final t in _NType.values) {
        final list = items.where((n) => n.type == t).toList();
        if (list.isNotEmpty) {
          rows.add(_Header(_typeMeta(t).label, list.length));
          rows.addAll(list);
        }
      }
    } else {
      for (final entry in [
        ('عاجل', _NPrio.high),
        ('عادي', _NPrio.normal),
      ]) {
        final list = items.where((n) => n.prio == entry.$2).toList();
        if (list.isNotEmpty) {
          rows.add(_Header(entry.$1, list.length));
          rows.addAll(list);
        }
      }
    }
    return rows;
  }

  void _openDetail(_Notif n, {required bool twoPane}) {
    _hub.markRead(n.id);
    if (twoPane) {
      setState(() => _selectedId = n.id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _NotifDetailPage(id: n.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hub,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final twoPane = w >= AppBreakpoints.inboxSplit;
            return PageContainer(
              maxWidth: AppBreakpoints.inboxContentMaxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(w, twoPane),
                  Expanded(
                    child: twoPane ? _twoPane(w) : _listOnly(w, twoPane: false),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---- Header + filters -----------------------------------------------------
  Widget _header(double w, bool twoPane) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final pad = pagePaddingForWidth(w);
    final narrow = w < AppBreakpoints.phone;
    final unread = _hub.unread;

    final titleRow = Row(
      children: [
        Icon(Icons.notifications_none_rounded, color: taj.primary.main),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'الإشعارات',
            style: text.headlineSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (unread > 0) ...[
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: taj.primary.lighter,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${arNum(unread)} غير مقروء',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                  color: taj.accentText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        const Spacer(),
        if (narrow)
          // Mark-all + advanced filters collapse into an overflow menu.
          PopupMenuButton<String>(
            tooltip: 'المزيد',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              if (v == 'all') _hub.markAllRead();
              if (v == 'filter') _openAdvancedFilters();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'all',
                enabled: unread > 0,
                child: const Text('تحديد الكل كمقروء'),
              ),
              const PopupMenuItem(value: 'filter', child: Text('تصفية متقدّمة')),
            ],
          )
        else
          TextButton.icon(
            onPressed: unread > 0 ? _hub.markAllRead : null,
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('تحديد الكل كمقروء'),
          ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: taj.background,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      padding: EdgeInsets.fromLTRB(pad, 14, pad, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleRow,
          const SizedBox(height: 12),
          _filters(w),
        ],
      ),
    );
  }

  Widget _filters(double w) {
    final persistent = w >= AppBreakpoints.inboxSplit; // >=820
    final medium = w >= AppBreakpoints.phone; // 600-820 → wrap
    final readChips = [
      _choice('الكل', _readFilter == _ReadFilter.all,
          () => setState(() => _readFilter = _ReadFilter.all)),
      _choice('غير مقروء', _readFilter == _ReadFilter.unread,
          () => setState(() => _readFilter = _ReadFilter.unread)),
      _choice('مقروء', _readFilter == _ReadFilter.read,
          () => setState(() => _readFilter = _ReadFilter.read)),
    ];
    final typeChips = [
      _choice('كل الأنواع', _typeFilter == null,
          () => setState(() => _typeFilter = null)),
      for (final t in _NType.values)
        _choice(_typeMeta(t).label, _typeFilter == t,
            () => setState(() => _typeFilter = t)),
    ];

    if (!medium) {
      // <600 — one horizontally scrollable chip row (read + type); grouping
      // lives in the advanced bottom sheet.
      return SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final c in [...readChips, const _ChipGap(), ...typeChips])
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: c,
              ),
          ],
        ),
      );
    }

    final groupChips = _groupChips();
    if (!persistent) {
      // 600-820 — a wrap of all chips.
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [...readChips, ...typeChips, const _ChipGap(), ...groupChips],
      );
    }
    // >=820 — persistent, labelled filter bar.
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    Widget labelled(String label, List<Widget> chips) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label:',
                style: text.bodySmall?.copyWith(
                    color: taj.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            ...[
              for (final c in chips)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: c,
                ),
            ],
          ],
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          labelled('الحالة', readChips),
          _vsep(),
          labelled('النوع', typeChips),
          _vsep(),
          labelled('التجميع', groupChips),
        ],
      ),
    );
  }

  List<Widget> _groupChips() => [
        _choice('حسب الوقت', _group == _GroupMode.time,
            () => setState(() => _group = _GroupMode.time)),
        _choice('حسب النوع', _group == _GroupMode.type,
            () => setState(() => _group = _GroupMode.type)),
        _choice('حسب الأولوية', _group == _GroupMode.prio,
            () => setState(() => _group = _GroupMode.prio)),
      ];

  Widget _vsep() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          height: 24,
          child: VerticalDivider(width: 1, color: context.taj.divider),
        ),
      );

  Widget _choice(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );

  Future<void> _openAdvancedFilters() async {
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
        return StatefulBuilder(
          builder: (ctx, setLocal) {
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
                      Text('تصفية متقدّمة', style: text.titleLarge),
                      const SizedBox(height: 16),
                      Text('الحالة',
                          style: text.titleSmall
                              ?.copyWith(color: taj.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _choice('الكل', _readFilter == _ReadFilter.all,
                            () => refresh(() => _readFilter = _ReadFilter.all)),
                        _choice(
                            'غير مقروء',
                            _readFilter == _ReadFilter.unread,
                            () => refresh(
                                () => _readFilter = _ReadFilter.unread)),
                        _choice('مقروء', _readFilter == _ReadFilter.read,
                            () => refresh(() => _readFilter = _ReadFilter.read)),
                      ]),
                      const SizedBox(height: 16),
                      Text('النوع',
                          style: text.titleSmall
                              ?.copyWith(color: taj.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _choice('كل الأنواع', _typeFilter == null,
                            () => refresh(() => _typeFilter = null)),
                        for (final t in _NType.values)
                          _choice(_typeMeta(t).label, _typeFilter == t,
                              () => refresh(() => _typeFilter = t)),
                      ]),
                      const SizedBox(height: 16),
                      Text('التجميع',
                          style: text.titleSmall
                              ?.copyWith(color: taj.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _choice('حسب الوقت', _group == _GroupMode.time,
                            () => refresh(() => _group = _GroupMode.time)),
                        _choice('حسب النوع', _group == _GroupMode.type,
                            () => refresh(() => _group = _GroupMode.type)),
                        _choice('حسب الأولوية', _group == _GroupMode.prio,
                            () => refresh(() => _group = _GroupMode.prio)),
                      ]),
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

  // ---- Bodies ---------------------------------------------------------------
  Widget _listOnly(double w, {required bool twoPane}) {
    final items = _filtered;
    if (items.isEmpty) return const _EmptyInbox();
    final rows = _rows(items);
    final phone = w < AppBreakpoints.phone;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        if (row is _Header) return _groupHeader(row);
        final n = row as _Notif;
        final tile = _NotifTile(
          notif: n,
          selected: twoPane && n.id == _selectedId,
          onTap: () => _openDetail(n, twoPane: twoPane),
        );
        if (!phone) return tile;
        // Phone: horizontal swipe marks read (mirrors via Directionality) and
        // snaps back — it never removes the row, so it can't fight scrolling.
        return Dismissible(
          key: ValueKey('dismiss-${n.id}'),
          direction:
              n.read ? DismissDirection.none : DismissDirection.horizontal,
          background: _swipeBg(AlignmentDirectional.centerStart),
          secondaryBackground: _swipeBg(AlignmentDirectional.centerEnd),
          confirmDismiss: (_) async {
            _hub.markRead(n.id);
            return false;
          },
          child: tile,
        );
      },
    );
  }

  Widget _twoPane(double w) {
    final taj = context.taj;
    final effective = math.min(w, AppBreakpoints.inboxContentMaxWidth);
    final listW = (effective * 0.34).clamp(
      AppBreakpoints.inboxListPaneMin,
      AppBreakpoints.inboxListPaneMax,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: listW.toDouble(), child: _listOnly(w, twoPane: true)),
        VerticalDivider(width: 1, color: taj.divider),
        Expanded(
          child: _selectedId == null
              ? const _EmptyDetail()
              : _NotifDetail(id: _selectedId!),
        ),
      ],
    );
  }

  Widget _swipeBg(AlignmentGeometry align) {
    final taj = context.taj;
    return Container(
      color: taj.success.lighter,
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all_rounded,
              size: 18, color: taj.accentFor(taj.success)),
          const SizedBox(width: 6),
          Text('تحديد كمقروء',
              style: TextStyle(
                color: taj.accentFor(taj.success),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              )),
        ],
      ),
    );
  }

  Widget _groupHeader(_Header h) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(h.label,
              style: text.bodySmall?.copyWith(
                  color: taj.textSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('(${arNum(h.count)})',
              style: text.bodySmall?.copyWith(color: taj.textDisabled)),
        ],
      ),
    );
  }
}

class _Header {
  const _Header(this.label, this.count);
  final String label;
  final int count;
}

// ===========================================================================
// Notification row
// ===========================================================================
class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.notif,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });
  final _Notif notif;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final meta = _typeMeta(notif.type);
    final swatch = taj.swatch(meta.tint);
    final unread = !notif.read;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints:
            BoxConstraints(minHeight: AppBreakpoints.notifRowMinHeight),
        decoration: BoxDecoration(
          color: selected
              ? taj.primary.lighter
              : (unread ? taj.hover : Colors.transparent),
          border: Border(bottom: BorderSide(color: taj.divider)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon — intrinsic width. High-priority carries a small flag
            // marker (shape, not colour-only).
            _TypeAvatar(icon: meta.icon, swatch: swatch, high: notif.prio == _NPrio.high),
            const SizedBox(width: 12),
            // Text column — flexes; title + time share a row, time never wraps.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge?.copyWith(
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relTime(notif.time),
                        softWrap: false,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: text.bodySmall?.copyWith(color: taj.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.body,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: taj.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Unread dot — intrinsic; trailing placement mirrors in RTL.
            SizedBox(
              width: 10,
              child: Align(
                alignment: AlignmentDirectional.topCenter,
                child: unread
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: taj.primary.main,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeAvatar extends StatelessWidget {
  const _TypeAvatar({
    required this.icon,
    required this.swatch,
    this.high = false,
    this.size = 40,
  });
  final IconData icon;
  final TajSwatch swatch;
  final bool high;
  final double size;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: swatch.lighter,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: size * 0.5, color: taj.accentFor(swatch)),
          ),
          if (high)
            PositionedDirectional(
              end: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: taj.paper,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.priority_high_rounded,
                    size: 12, color: taj.accentFor(taj.error)),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Detail
// ===========================================================================
class _NotifDetail extends StatelessWidget {
  const _NotifDetail({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hub,
      builder: (context, _) {
        _Notif? n;
        for (final e in _hub.items) {
          if (e.id == id) {
            n = e;
            break;
          }
        }
        if (n == null) return const _EmptyDetail();
        final notif = n;
        final taj = context.taj;
        final text = Theme.of(context).textTheme;
        final meta = _typeMeta(notif.type);
        final swatch = taj.swatch(meta.tint);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeAvatar(
                      icon: meta.icon,
                      swatch: swatch,
                      high: notif.prio == _NPrio.high,
                      size: 52),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusBadge(label: meta.label, status: meta.tint),
                            if (notif.prio == _NPrio.high)
                              StatusBadge(
                                  label: 'عاجل',
                                  status: TajStatus.error,
                                  icon: Icons.priority_high_rounded),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(notif.title, style: text.headlineSmall),
                        const SizedBox(height: 4),
                        Text(_fullDateTime(notif.time),
                            style: AppThemes.numeralStyle(context, fontSize: 13)
                                .copyWith(color: taj.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(notif.body, style: text.bodyLarge?.copyWith(height: 1.6)),
              const SizedBox(height: 24),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _hub.toggleRead(notif.id),
                    icon: Icon(
                      notif.read
                          ? Icons.mark_email_unread_outlined
                          : Icons.done_all_rounded,
                      size: 18,
                    ),
                    label: Text(
                        notif.read ? 'تعليم كغير مقروء' : 'تحديد كمقروء'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-page detail (single-pane / pushed from the phone list).
class _NotifDetailPage extends StatelessWidget {
  const _NotifDetailPage({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Scaffold(
      backgroundColor: taj.background,
      appBar: AppBar(
        title: const Text('الإشعار'),
        backgroundColor: taj.background,
        elevation: 0,
      ),
      body: SafeArea(child: _NotifDetail(id: id)),
    );
  }
}

// ===========================================================================
// Empty states
// ===========================================================================
class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();
  @override
  Widget build(BuildContext context) {
    // Centred with a minimum height but still scrollable so it never overflows
    // a very short viewport (e.g. 430px tall landscape phone).
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: TajEmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'لا إشعارات',
                message: 'لا توجد إشعارات مطابقة للتصفية الحالية.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drafts_outlined, size: 40, color: taj.textDisabled),
          const SizedBox(height: 12),
          Text('اختر إشعارًا لعرض تفاصيله',
              style: text.bodyMedium?.copyWith(color: taj.textSecondary)),
        ],
      ),
    );
  }
}

// ===========================================================================
// Top-bar bell + badge + popover / sheet launcher
// ===========================================================================
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, required this.onOpenFull});

  /// Opens the full notification page (used on phone widths).
  final VoidCallback onOpenFull;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final GlobalKey _anchorKey = GlobalKey();

  void _open() {
    final size = MediaQuery.sizeOf(context);
    if (size.width < AppBreakpoints.phone) {
      widget.onOpenFull();
      return;
    }
    if (size.height < AppBreakpoints.notifPopoverMinHeight) {
      _openSheet();
      return;
    }
    _openPopover();
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return AnimatedBuilder(
      animation: _hub,
      builder: (context, _) {
        final count = _hub.unread;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              key: _anchorKey,
              tooltip: 'الإشعارات',
              onPressed: _open,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            if (count > 0)
              PositionedDirectional(
                end: 4,
                top: 4,
                child: IgnorePointer(
                  child: _CountBadge(count: count, border: taj.background),
                ),
              ),
          ],
        );
      },
    );
  }

  // ---- Anchored popover (clamped inside the window) -------------------------
  void _openPopover() {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final topLeft = box.localToGlobal(Offset.zero);
    final anchor = topLeft & box.size;
    final size = MediaQuery.sizeOf(context);

    final rawW = size.width < AppBreakpoints.inboxSplit
        ? AppBreakpoints.notifPanelMin
        : AppBreakpoints.notifPanelMax;
    final panelW = math.min(rawW, size.width - 16);
    final maxH = size.height * AppBreakpoints.notifPopoverMaxHeightFactor;
    // Clamp horizontally so the panel can never escape either edge (RTL/LTR).
    final left =
        (anchor.right - panelW).clamp(8.0, size.width - panelW - 8.0);
    final top = math.min(anchor.bottom + 6, size.height - 160);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'الإشعارات',
      barrierColor: Colors.black.withValues(alpha: 0.12),
      transitionDuration: const Duration(milliseconds: 130),
      pageBuilder: (ctx, a1, a2) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: panelW,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: _PopoverPanel(
                  onViewAll: () {
                    Navigator.of(ctx).pop();
                    widget.onOpenFull();
                  },
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  void _openSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.taj.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: size.height * 0.9),
            child: _PopoverPanel(
              sheet: true,
              onViewAll: () {
                Navigator.of(ctx).pop();
                widget.onOpenFull();
              },
            ),
          ),
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.border});
  final int count;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final label =
        count > AppBreakpoints.notifBadgeMax ? '${arNum(AppBreakpoints.notifBadgeMax)}+' : arNum(count);
    return Container(
      constraints: const BoxConstraints(minWidth: 18, maxWidth: 34, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: taj.error.main,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: TextStyle(
          color: taj.error.contrastText,
          fontSize: 12,
          height: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// The shared popover / bottom-sheet content: a header, a scrollable recent
/// list and a pinned "view all" footer. Height is bounded by the caller.
class _PopoverPanel extends StatelessWidget {
  const _PopoverPanel({required this.onViewAll, this.sheet = false});
  final VoidCallback onViewAll;
  final bool sheet;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: _hub,
      builder: (context, _) {
        final items = List<_Notif>.of(_hub.items)
          ..sort((a, b) => b.time.compareTo(a.time));
        final unread = _hub.unread;
        final body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sheet)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(
                    color: taj.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('الإشعارات',
                        style:
                            text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (unread > 0)
                    TextButton(
                      onPressed: _hub.markAllRead,
                      child: const Text('تحديد الكل'),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: taj.divider),
            Flexible(
              child: items.isEmpty
                  ? const _EmptyInbox()
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final n = items[i];
                        return _NotifTile(
                          notif: n,
                          compact: true,
                          onTap: () => _hub.markRead(n.id),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: taj.divider),
            InkWell(
              onTap: onViewAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('عرض كل الإشعارات',
                        style: text.bodyMedium?.copyWith(
                            color: taj.accentText, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_left_rounded,
                        size: 18, color: taj.accentText),
                  ],
                ),
              ),
            ),
          ],
        );
        if (sheet) return body;
        return Material(
          key: const Key('notif-popover'),
          color: taj.paper,
          elevation: 12,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: body,
        );
      },
    );
  }
}

// ===========================================================================
// Small shared bits
// ===========================================================================
class _ChipGap extends StatelessWidget {
  const _ChipGap();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 28,
        child: VerticalDivider(width: 12, color: context.taj.divider),
      );
}

// ===========================================================================
// Helpers
// ===========================================================================
String _timeBucket(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(t.year, t.month, t.day);
  final diff = today.difference(d).inDays;
  if (diff <= 0) return 'اليوم';
  if (diff == 1) return 'الأمس';
  if (diff <= 7) return 'هذا الأسبوع';
  return 'أقدم';
}

String _relTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'قبل ${arNum(diff.inMinutes)} د';
  if (diff.inHours < 24) return 'قبل ${arNum(diff.inHours)} س';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 7) return 'قبل ${arNum(diff.inDays)} ي';
  return '${arNum(t.day)}/${arNum(t.month)}';
}

String _fullDateTime(DateTime t) {
  String two(int v) => v < 10 ? '0$v' : '$v';
  return '${t.year}/${two(t.month)}/${two(t.day)} — ${two(t.hour)}:${two(t.minute)}';
}
