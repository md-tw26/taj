import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/taj_colors.dart';

class PosTopBar extends StatelessWidget {
  const PosTopBar({
    required this.branchName,
    required this.userName,
    required this.isOnline,
    required this.isGridView,
    required this.isProfessional,
    required this.onToggleMode,
    required this.onToggleTheme,
    required this.onLogout,
    required this.onToggleOnline,
    required this.onToggleView,
    this.onOpenReports, super.key,});

  final String branchName;
  final String userName;
  final bool isOnline;
  final bool isGridView;
  final bool isProfessional;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;
  final VoidCallback onToggleOnline;
  final VoidCallback onToggleView;
  final VoidCallback? onOpenReports;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial =
        userName.isEmpty ? '؟' : String.fromCharCode(userName.runes.first);

    // Simple ↔ Professional segmented toggle (full, desktop/tablet form).
    final modeToggle = SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.touch_app_outlined, size: 15),
          label: Text('بسيط'),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.workspace_premium_outlined, size: 15),
          label: Text('محترف'),
        ),
      ],
      selected: {isProfessional},
      onSelectionChanged: (_) => onToggleMode(),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.almarai(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: taj.divider)),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? taj.primary.dark
                  : taj.textSecondary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? taj.primary.lighter
                  : Colors.transparent,
        ),
      ),
    );

    final viewToggle = IconButton(
      tooltip: isGridView ? 'عرض القائمة' : 'عرض الشبكة',
      onPressed: onToggleView,
      icon: Icon(
        isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
        size: 20,
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 720;

        return Container(
          height: 60,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: taj.paper,
            border: Border(bottom: BorderSide(color: taj.divider)),
          ),
          child: Row(
            children: [
              // Operator avatar + name + branch
              CircleAvatar(
                radius: 17,
                backgroundColor: taj.primary.lighter,
                child: Text(
                  initial.toUpperCase(),
                  style: TextStyle(
                    color: taj.primary.dark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: taj.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      branchName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: taj.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 26, color: taj.divider),
              const SizedBox(width: 12),

              // Online badge
              _OnlineBadge(isOnline: isOnline, onTap: onToggleOnline),

              const Spacer(),

              if (!narrow) ...[
                modeToggle,
                viewToggle,
                if (isProfessional && onOpenReports != null)
                  IconButton(
                    tooltip: 'تقارير الجلسة',
                    onPressed: onOpenReports,
                    icon: const Icon(Icons.bar_chart_rounded, size: 20),
                  ),
                IconButton(
                  tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                  onPressed: onToggleTheme,
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: 'تسجيل الخروج',
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_outlined, size: 20),
                ),
              ] else ...[
                IconButton(
                  tooltip: isProfessional ? 'الوضع المحترف' : 'الوضع البسيط',
                  onPressed: onToggleMode,
                  icon: Icon(
                    isProfessional
                        ? Icons.workspace_premium_outlined
                        : Icons.touch_app_outlined,
                    size: 20,
                    color: taj.primary.dark,
                  ),
                ),
                viewToggle,
                PopupMenuButton<String>(
                  tooltip: 'المزيد',
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (v) {
                    switch (v) {
                      case 'reports':
                        onOpenReports?.call();
                      case 'theme':
                        onToggleTheme();
                      case 'logout':
                        onLogout();
                    }
                  },
                  itemBuilder:
                      (_) => [
                        if (isProfessional && onOpenReports != null)
                          const PopupMenuItem(
                            value: 'reports',
                            child: ListTile(
                              leading: Icon(Icons.bar_chart_rounded),
                              title: Text('تقارير الجلسة'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        PopupMenuItem(
                          value: 'theme',
                          child: ListTile(
                            leading: Icon(
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                            ),
                            title: Text(
                              isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: ListTile(
                            leading: Icon(Icons.logout_outlined),
                            title: Text('تسجيل الخروج'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.isOnline, required this.onTap});
  final bool isOnline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final color = isOnline ? taj.success : taj.warning;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.lighter,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color.main,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'متصل' : 'غير متصل',
              style: TextStyle(
                color: color.dark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
