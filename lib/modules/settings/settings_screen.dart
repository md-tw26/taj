import 'package:flutter/material.dart';

import '../../core/chart_style.dart';
import '../../core/responsive.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_ui.dart';

/// Settings (spec 7.18). The Appearance section lets the system admin pick the
/// app's primary colour from the Minimals palette (default: info / سماوي) and
/// toggle dark mode, with a live preview.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.currentPrimary,
    required this.onPrimaryChanged,
    required this.onToggleTheme,
    required this.chartStyle,
    required this.onChartStyleChanged,
  });

  final TajSwatch currentPrimary;
  final ValueChanged<TajSwatch> onPrimaryChanged;
  final VoidCallback onToggleTheme;
  final ChartStyle chartStyle;
  final ValueChanged<ChartStyle> onChartStyleChanged;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, c) {
        final pad = pagePaddingForWidth(c.maxWidth);
        return PageContainer(
          child: ListView(
          padding: EdgeInsets.all(pad),
          children: [
            const SectionHeading(
              title: 'الإعدادات',
              subtitle: 'المظهر، اللغة، الفواتير، الصلاحيات والمزامنة',
            ),
            const SizedBox(height: 20),

            // ---- Appearance ----
            _SettingsSection(
              icon: Icons.palette_outlined,
              title: 'المظهر',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اللون الأساسي', style: text.titleSmall),
                  const SizedBox(height: 4),
                  Text('يختار مدير النظام لون العلامة الذي يريحه — من ألوان Minimals.',
                      style: text.bodySmall?.copyWith(color: taj.textSecondary)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final (name, swatch) in TajColors.palette)
                        _ColorSwatchDot(
                          name: name,
                          swatch: swatch,
                          selected: swatch.main == currentPrimary.main,
                          onTap: () => onPrimaryChanged(swatch),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(height: 1, color: taj.divider),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isDark,
                    onChanged: (_) => onToggleTheme(),
                    title: Text('الوضع الداكن', style: text.bodyLarge),
                    subtitle: Text('تبديل بين الفاتح والداكن',
                        style: text.bodySmall?.copyWith(color: taj.textSecondary)),
                    secondary: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: taj.accentText),
                  ),
                  const SizedBox(height: 20),
                  Divider(height: 1, color: taj.divider),
                  const SizedBox(height: 16),
                  Text('شكل الرسم البياني', style: text.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                      'نمط عرض الرسوم البيانية في لوحة التحكم — مساحة أو خط أو أعمدة.',
                      style: text.bodySmall?.copyWith(color: taj.textSecondary)),
                  const SizedBox(height: 12),
                  _ChartStyleSelector(
                    selected: chartStyle,
                    onSelect: onChartStyleChanged,
                  ),
                  const SizedBox(height: 16),
                  _Preview(chartStyle: chartStyle),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- Other setting groups (placeholders) ----
            _SettingsRow(icon: Icons.translate_rounded, title: 'اللغة والعملة والضرائب', subtitle: 'العربية • الدينار الليبي • الضريبة'),
            _SettingsRow(icon: Icons.receipt_outlined, title: 'شكل الفواتير والطباعة', subtitle: 'قالب الفاتورة، الطابعة الحرارية'),
            _SettingsRow(icon: Icons.percent_rounded, title: 'سياسة الخصم', subtitle: 'النطاق، المدة، المستخدمون المخوّلون'),
            _SettingsRow(icon: Icons.event_available_outlined, title: 'سياسة الإقفال اليومي', subtitle: 'وقت الإقفال، المراجعة'),
            _SettingsRow(icon: Icons.sync_rounded, title: 'المزامنة والنسخ الاحتياطي', subtitle: 'أوف‑لاين، آخر نسخة احتياطية'),
          ],
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return TajCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: taj.primary.lighter, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: taj.primary.dark),
              ),
              const SizedBox(width: 12),
              Text(title, style: text.titleMedium),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _ColorSwatchDot extends StatelessWidget {
  const _ColorSwatchDot({
    required this.name,
    required this.swatch,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final TajSwatch swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: swatch.main,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? swatch.dark : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: swatch.main.withValues(alpha: selected ? 0.5 : 0.25),
                    blurRadius: selected ? 12 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: swatch.contrastText, size: 22)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(name,
                style: text.labelSmall?.copyWith(
                    color: selected ? taj.textPrimary : taj.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ChartStyleSelector extends StatelessWidget {
  const _ChartStyleSelector({required this.selected, required this.onSelect});
  final ChartStyle selected;
  final ValueChanged<ChartStyle> onSelect;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Row(
      children: [
        for (final s in ChartStyle.values) ...[
          if (s != ChartStyle.values.first) const SizedBox(width: 10),
          Expanded(
            child: _Tile(
              style: s,
              selected: s == selected,
              taj: taj,
              onTap: () => onSelect(s),
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.style,
    required this.selected,
    required this.taj,
    required this.onTap,
  });
  final ChartStyle style;
  final bool selected;
  final TajColors taj;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? taj.primary.dark : taj.textSecondary;
    return Material(
      color: selected ? taj.primary.lighter : taj.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? taj.primary.main : taj.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon, size: 22, color: fg),
              const SizedBox(height: 6),
              Text(style.label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.chartStyle});
  final ChartStyle chartStyle;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taj.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('معاينة حيّة', style: text.labelMedium?.copyWith(color: taj.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(onPressed: () {}, child: const Text('زر أساسي')),
              OutlinedButton(onPressed: () {}, child: const Text('ثانوي')),
              const StatusBadge(label: 'نشط', status: TajStatus.primary),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 68,
            child: Sparkline(
              values: const [14, 20, 17, 26, 22, 30, 27],
              color: taj.primary.main,
              style: chartStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TajCard(
        onTap: () {},
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: taj.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: taj.divider)),
              child: Icon(icon, size: 20, color: taj.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: text.bodySmall?.copyWith(color: taj.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: taj.textDisabled),
          ],
        ),
      ),
    );
  }
}

