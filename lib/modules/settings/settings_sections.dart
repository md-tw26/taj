import 'package:flutter/material.dart';

import '../../core/chart_style.dart';
import '../../core/responsive.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_ui.dart';
import 'settings_models.dart';
import 'settings_previews.dart';
import 'settings_widgets.dart';

/// Builds the content of one settings section. Appearance edits apply *live* via
/// the app's own callbacks (they are intentionally never part of the draft); the
/// other five sections read/write the [draft] via [onDraft].
class SettingsSectionContent extends StatelessWidget {
  const SettingsSectionContent({
    super.key,
    required this.id,
    required this.draft,
    required this.onDraft,
    required this.currentPrimary,
    required this.onPrimaryChanged,
    required this.onToggleTheme,
    required this.chartStyle,
    required this.onChartStyleChanged,
  });

  final SettingsSectionId id;
  final SettingsDraft draft;
  final ValueChanged<SettingsDraft> onDraft;

  // Live appearance hooks (unchanged behaviour).
  final TajSwatch currentPrimary;
  final ValueChanged<TajSwatch> onPrimaryChanged;
  final VoidCallback onToggleTheme;
  final ChartStyle chartStyle;
  final ValueChanged<ChartStyle> onChartStyleChanged;

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case SettingsSectionId.appearance:
        return _AppearanceSection(
          currentPrimary: currentPrimary,
          onPrimaryChanged: onPrimaryChanged,
          onToggleTheme: onToggleTheme,
          chartStyle: chartStyle,
          onChartStyleChanged: onChartStyleChanged,
        );
      case SettingsSectionId.localization:
        return _LocalizationSection(draft: draft, onDraft: onDraft);
      case SettingsSectionId.invoice:
        return _InvoiceSection(draft: draft, onDraft: onDraft);
      case SettingsSectionId.discount:
        return _DiscountSection(draft: draft, onDraft: onDraft);
      case SettingsSectionId.dayClosing:
        return _DayClosingSection(draft: draft, onDraft: onDraft);
      case SettingsSectionId.sync:
        return _SyncSection(draft: draft, onDraft: onDraft);
    }
  }
}

/// Vertical spacing between the groups inside a section.
const double _gap = 16;

// ===========================================================================
// Appearance
// ===========================================================================

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'اللون والوضع',
          icon: Icons.palette_outlined,
          children: [
            SettingsBlock(
              title: 'اللون الأساسي',
              subtitle:
                  'يختار مدير النظام لون العلامة الذي يريحه — من ألوان Minimals.',
              child: LayoutBuilder(
                builder: (context, c) {
                  final cols = gridColumnsFor(c.maxWidth,
                      minItemWidth: AppBreakpoints.settingsSwatchMin, spacing: 14);
                  const spacing = 14.0;
                  final itemW = (c.maxWidth - spacing * (cols - 1)) / cols;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: 14,
                    children: [
                      for (final (name, swatch) in TajColors.palette)
                        SizedBox(
                          width: itemW,
                          child: _SwatchTile(
                            name: name,
                            swatch: swatch,
                            selected: swatch.main == currentPrimary.main,
                            onTap: () => onPrimaryChanged(swatch),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            SettingRow(
              title: 'الوضع الداكن',
              subtitle: 'تبديل بين الفاتح والداكن',
              control: Switch(value: isDark, onChanged: (_) => onToggleTheme()),
            ),
          ],
        ),
        const SizedBox(height: _gap),
        SettingsGroup(
          title: 'الرسوم البيانية',
          icon: Icons.insights_outlined,
          children: [
            SettingsBlock(
              title: 'شكل الرسم البياني',
              subtitle:
                  'نمط عرض الرسوم البيانية في لوحة التحكم — مساحة أو خط أو أعمدة.',
              child: SettingsSegmented<ChartStyle>(
                value: chartStyle,
                options: ChartStyle.values,
                labelOf: (s) => s.label,
                iconOf: (s) => s.icon,
                onChanged: onChartStyleChanged,
              ),
            ),
            SettingsBlock(
              title: 'معاينة حيّة',
              subtitle: 'انعكاس فوري للون والوضع وشكل الرسم على واجهة مصغّرة.',
              child: ThemePreviewMini(
                  primary: currentPrimary, chartStyle: chartStyle),
            ),
          ],
        ),
      ],
    );
  }
}

class _SwatchTile extends StatelessWidget {
  const _SwatchTile({
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
              height: 46,
              decoration: BoxDecoration(
                color: swatch.main,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? swatch.dark : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: swatch.main.withValues(alpha: selected ? 0.45 : 0.22),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                    color: selected ? taj.textPrimary : taj.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Localization (language / currency / tax)
// ===========================================================================

class _LocalizationSection extends StatelessWidget {
  const _LocalizationSection({required this.draft, required this.onDraft});
  final SettingsDraft draft;
  final ValueChanged<SettingsDraft> onDraft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'اللغة والأرقام',
          icon: Icons.translate_rounded,
          children: [
            SettingRow(
              title: 'اللغة',
              subtitle: 'لغة الواجهة الأساسية للنظام.',
              controlIsWide: true,
              control: SettingsSelectField<AppLanguage>(
                value: draft.language,
                items: AppLanguage.values,
                labelOf: (l) => l.label,
                onChanged: (v) => onDraft(draft.copyWith(language: v)),
              ),
            ),
            SettingRow(
              title: 'نمط الأرقام',
              subtitle: 'عرض الأرقام بالأرقام العربية أو اللاتينية.',
              controlIsWide: true,
              control: SettingsSelectField<NumberStyle>(
                value: draft.numberStyle,
                items: NumberStyle.values,
                labelOf: (n) => n.label,
                onChanged: (v) => onDraft(draft.copyWith(numberStyle: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: _gap),
        SettingsGroup(
          title: 'العملة والضريبة',
          icon: Icons.payments_outlined,
          children: [
            SettingRow(
              title: 'العملة',
              subtitle: 'عملة الأسعار والفواتير في كل النظام.',
              controlIsWide: true,
              control: SettingsSelectField<AppCurrency>(
                value: draft.currency,
                items: AppCurrency.values,
                labelOf: (c) => '${c.label} (${c.symbol})',
                onChanged: (v) => onDraft(draft.copyWith(currency: v)),
              ),
            ),
            SettingRow(
              title: 'نسبة الضريبة',
              subtitle: 'تُطبّق على الفواتير الخاضعة للضريبة.',
              control: SettingsStepper(
                value: draft.taxRate.round(),
                min: 0,
                max: 30,
                suffix: '٪',
                onChanged: (v) =>
                    onDraft(draft.copyWith(taxRate: v.toDouble())),
              ),
            ),
            SettingRow(
              title: 'السعر شامل الضريبة',
              subtitle: 'عند التفعيل تُحتسب الضريبة ضمن السعر المعروض.',
              control: Switch(
                value: draft.taxInclusive,
                onChanged: (v) => onDraft(draft.copyWith(taxInclusive: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// Invoice & print
// ===========================================================================

class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({required this.draft, required this.onDraft});
  final SettingsDraft draft;
  final ValueChanged<SettingsDraft> onDraft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'محتوى الفاتورة',
          icon: Icons.receipt_long_outlined,
          children: [
            SettingsBlock(
              title: 'اسم المتجر',
              child: SettingsTextField(
                label: 'يظهر أعلى كل فاتورة',
                initialValue: draft.storeName,
                onChanged: (v) => onDraft(draft.copyWith(storeName: v)),
              ),
            ),
            SettingsBlock(
              title: 'ترويسة الفاتورة',
              child: SettingsTextField(
                label: 'سطر أسفل اسم المتجر',
                initialValue: draft.invoiceHeader,
                onChanged: (v) => onDraft(draft.copyWith(invoiceHeader: v)),
              ),
            ),
            SettingsBlock(
              title: 'نص التذييل',
              child: SettingsTextField(
                label: 'رسالة أسفل الفاتورة',
                initialValue: draft.invoiceFooter,
                maxLines: 3,
                onChanged: (v) => onDraft(draft.copyWith(invoiceFooter: v)),
              ),
            ),
            SettingRow(
              title: 'إظهار الشعار',
              subtitle: 'طباعة شعار المتجر أعلى الفاتورة.',
              control: Switch(
                value: draft.showLogo,
                onChanged: (v) => onDraft(draft.copyWith(showLogo: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: _gap),
        SettingsGroup(
          title: 'الطباعة',
          icon: Icons.print_outlined,
          children: [
            SettingsBlock(
              title: 'حجم الورق',
              subtitle: 'A4 للمكتب أو حراري 80mm للكاشير.',
              child: SettingsSegmented<PaperSize>(
                value: draft.paperSize,
                options: PaperSize.values,
                labelOf: (p) => p.label,
                iconOf: (p) => p.icon,
                onChanged: (v) => onDraft(draft.copyWith(paperSize: v)),
              ),
            ),
            SettingRow(
              title: 'الطابعة',
              subtitle: 'الطابعة الافتراضية للفواتير.',
              controlIsWide: true,
              control: SettingsSelectField<String>(
                value: draft.printer,
                items: kDemoPrinters,
                labelOf: (p) => p,
                onChanged: (v) => onDraft(draft.copyWith(printer: v)),
              ),
            ),
            SettingRow(
              title: 'عدد النسخ',
              subtitle: 'كم نسخة تُطبع لكل فاتورة.',
              control: SettingsStepper(
                value: draft.printCopies,
                min: 1,
                max: 5,
                onChanged: (v) => onDraft(draft.copyWith(printCopies: v)),
              ),
            ),
            SettingsBlock(
              title: 'معاينة الطباعة',
              subtitle: 'معاينة توضيحية فقط — لا تؤثر على المخرجات الفعلية.',
              child: InvoicePreviewMini(draft: draft),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// Discount policy — the most complex form
// ===========================================================================

class _DiscountSection extends StatelessWidget {
  const _DiscountSection({required this.draft, required this.onDraft});
  final SettingsDraft draft;
  final ValueChanged<SettingsDraft> onDraft;

  @override
  Widget build(BuildContext context) {
    final on = draft.discountEnabled;
    final needsTargets = draft.discountScope != DiscountScope.all;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'تفعيل الخصم',
          icon: Icons.percent_rounded,
          children: [
            SettingRow(
              title: 'تفعيل سياسة الخصم',
              subtitle: 'عند الإيقاف تُعطّل كل خيارات الخصم أدناه.',
              control: Switch(
                value: on,
                onChanged: (v) => onDraft(draft.copyWith(discountEnabled: v)),
              ),
            ),
            SettingRow(
              title: 'الحد الأقصى للخصم',
              subtitle: 'أعلى نسبة خصم مسموح بها في العملية الواحدة.',
              enabled: on,
              control: SettingsStepper(
                value: draft.maxDiscountPct.round(),
                min: 0,
                max: 100,
                step: 5,
                suffix: '٪',
                enabled: on,
                onChanged: (v) =>
                    onDraft(draft.copyWith(maxDiscountPct: v.toDouble())),
              ),
            ),
          ],
        ),
        const SizedBox(height: _gap),
        SettingsGroup(
          title: 'النطاق',
          icon: Icons.filter_alt_outlined,
          children: [
            SettingsBlock(
              title: 'نطاق الخصم',
              subtitle: 'على صنف محدد أو مجموعة أو تصنيف أو كل الأصناف.',
              enabled: on,
              child: SettingsSegmented<DiscountScope>(
                value: draft.discountScope,
                options: DiscountScope.values,
                labelOf: (s) => s.label,
                iconOf: (s) => s.icon,
                enabled: on,
                onChanged: (v) => onDraft(draft.copyWith(discountScope: v)),
              ),
            ),
            if (needsTargets)
              SettingsBlock(
                title: 'الأصناف المشمولة',
                subtitle: 'اختر الأصناف أو التصنيفات المشمولة بالخصم.',
                enabled: on,
                child: SettingsChipsField(
                  selected: draft.discountTargets,
                  options: kDemoDiscountItems,
                  pickerTitle: 'اختيار الأصناف',
                  enabled: on,
                  onChanged: (s) => onDraft(draft.copyWith(discountTargets: s)),
                ),
              ),
          ],
        ),
        const SizedBox(height: _gap),
        SettingsGroup(
          title: 'المدة',
          icon: Icons.date_range_outlined,
          children: [
            SettingsBlock(
              title: 'مدة الخصم',
              subtitle: 'تاريخ البداية والنهاية لسريان الخصم.',
              enabled: on,
              child: SettingsFieldPair(
                breakpoint: AppBreakpoints.settingsDatePairTwoCol,
                first: SettingsDateField(
                  label: 'من',
                  value: draft.discountStart,
                  enabled: on,
                  onChanged: (d) => onDraft(draft.copyWith(discountStart: d)),
                ),
                second: SettingsDateField(
                  label: 'إلى',
                  value: draft.discountEnd,
                  enabled: on,
                  onChanged: (d) => onDraft(draft.copyWith(discountEnd: d)),
                ),
              ),
            ),
            SettingRow(
              title: 'إيقاف تلقائي عند الانتهاء',
              subtitle: 'يُعطّل الخصم تلقائياً بعد تاريخ النهاية.',
              enabled: on,
              control: Switch(
                value: draft.discountAutoOff,
                onChanged:
                    on ? (v) => onDraft(draft.copyWith(discountAutoOff: v)) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: _gap),
        SettingsGroup(
          title: 'الفروع والصلاحية',
          icon: Icons.groups_outlined,
          children: [
            SettingsBlock(
              title: 'الفروع المشمولة',
              subtitle: 'الفروع التي يسري فيها الخصم.',
              enabled: on,
              child: SettingsChipsField(
                selected: draft.discountBranches,
                options: kDemoBranches,
                pickerTitle: 'اختيار الفروع',
                enabled: on,
                onChanged: (s) => onDraft(draft.copyWith(discountBranches: s)),
              ),
            ),
            SettingsBlock(
              title: 'المستخدمون المخوّلون',
              subtitle: 'من يحق لهم تطبيق هذا الخصم.',
              enabled: on,
              child: SettingsChipsField(
                selected: draft.discountUsers,
                options: kDemoUsers,
                pickerTitle: 'اختيار المستخدمين',
                enabled: on,
                onChanged: (s) => onDraft(draft.copyWith(discountUsers: s)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// Day-closing policy
// ===========================================================================

class _DayClosingSection extends StatelessWidget {
  const _DayClosingSection({required this.draft, required this.onDraft});
  final SettingsDraft draft;
  final ValueChanged<SettingsDraft> onDraft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'توقيت الإقفال',
          icon: Icons.schedule_outlined,
          children: [
            SettingRow(
              title: 'وقت الإقفال اليومي',
              subtitle: 'الوقت المقترح لإقفال يوم العمل.',
              controlIsWide: true,
              minControlWidth: 120,
              maxControlWidth: 180,
              control: _TimeField(
                value: draft.closingTime,
                onChanged: (t) => onDraft(draft.copyWith(closingTime: t)),
              ),
            ),
            SettingRow(
              title: 'الإقفال التلقائي',
              subtitle: 'إقفال اليوم آلياً عند حلول وقت الإقفال.',
              control: Switch(
                value: draft.autoClose,
                onChanged: (v) => onDraft(draft.copyWith(autoClose: v)),
              ),
            ),
            SettingRow(
              title: 'مهلة السماح',
              subtitle: 'دقائق مسموحة بعد وقت الإقفال قبل التنبيه.',
              control: SettingsStepper(
                value: draft.graceMinutes,
                min: 0,
                max: 120,
                step: 5,
                suffix: 'دقيقة',
                onChanged: (v) => onDraft(draft.copyWith(graceMinutes: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: _gap),
        SettingsGroup(
          title: 'المراجعة والقفل',
          icon: Icons.verified_user_outlined,
          children: [
            SettingRow(
              title: 'إلزام المراجعة قبل الإقفال',
              subtitle: 'يتطلب مراجعة الفروقات قبل اعتماد الإقفال.',
              control: Switch(
                value: draft.requireReview,
                onChanged: (v) => onDraft(draft.copyWith(requireReview: v)),
              ),
            ),
            SettingRow(
              title: 'قفل اليوم بعد الإقفال',
              subtitle: 'منع أي تعديل على عمليات يوم مُقفل.',
              control: Switch(
                value: draft.lockAfterClose,
                onChanged: (v) => onDraft(draft.copyWith(lockAfterClose: v)),
              ),
            ),
            SettingRow(
              title: 'تنبيه عند الإقفال',
              subtitle: 'إرسال إشعار للمشرف عند إقفال اليوم.',
              control: Switch(
                value: draft.notifyOnClose,
                onChanged: (v) => onDraft(draft.copyWith(notifyOnClose: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.value, required this.onChanged});
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final label =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final picked =
              await showTimePicker(context: context, initialTime: value);
          if (picked != null) onChanged(picked);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsetsDirectional.only(start: 14, end: 12),
          decoration: BoxDecoration(
            color: taj.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: taj.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: AppThemes.numeralStyle(context,
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Icon(Icons.access_time_rounded, size: 17, color: taj.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Sync & backup
// ===========================================================================

class _SyncSection extends StatelessWidget {
  const _SyncSection({required this.draft, required this.onDraft});
  final SettingsDraft draft;
  final ValueChanged<SettingsDraft> onDraft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'المزامنة',
          icon: Icons.sync_rounded,
          children: [
            SettingRow(
              title: 'وضع عدم الاتصال',
              subtitle: 'العمل أوف‑لاين والمزامنة عند عودة الاتصال.',
              control: Switch(
                value: draft.offlineMode,
                onChanged: (v) => onDraft(draft.copyWith(offlineMode: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: _gap),
        SettingsGroup(
          title: 'النسخ الاحتياطي',
          icon: Icons.backup_outlined,
          children: [
            SettingRow(
              title: 'النسخ الاحتياطي التلقائي',
              subtitle: 'إنشاء نسخة احتياطية دورية تلقائياً.',
              control: Switch(
                value: draft.autoBackup,
                onChanged: (v) => onDraft(draft.copyWith(autoBackup: v)),
              ),
            ),
            SettingRow(
              title: 'تكرار النسخ',
              subtitle: 'كل كم يتم إنشاء نسخة احتياطية.',
              controlIsWide: true,
              enabled: draft.autoBackup,
              control: SettingsSelectField<BackupFrequency>(
                value: draft.backupFrequency,
                items: BackupFrequency.values,
                labelOf: (f) => f.label,
                enabled: draft.autoBackup,
                onChanged: (v) => onDraft(draft.copyWith(backupFrequency: v)),
              ),
            ),
            SettingsBlock(
              title: 'آخر نسخة احتياطية',
              subtitle: 'أُنشئت في ٢٠٢٦/٠٩/١٢ الساعة ٠٣:٠٠ — بحجم ٤٨٫٢ MB.',
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('نسخ احتياطي الآن'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _gap),
        SettingsGroup(
          title: 'سجل النسخ الاحتياطي',
          icon: Icons.history_rounded,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _BackupHistoryTable(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Backup-history demo table. Below [AppBreakpoints.settingsBackupTableMin] it
/// scrolls horizontally rather than crushing its columns; the header stays put.
class _BackupHistoryTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    Widget cell(String s, {int flex = 1, TextAlign align = TextAlign.start, bool head = false}) =>
        Expanded(
          flex: flex,
          child: Text(
            s,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: head
                ? text.labelMedium?.copyWith(color: taj.textSecondary)
                : text.bodyMedium,
          ),
        );

    return LayoutBuilder(
      builder: (context, c) {
        final tableWidth =
            c.maxWidth < AppBreakpoints.settingsBackupTableMin
                ? AppBreakpoints.settingsBackupTableMin
                : c.maxWidth;
        final table = SizedBox(
          width: tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    cell('التاريخ', flex: 3, head: true),
                    cell('الحجم', flex: 2, align: TextAlign.center, head: true),
                    cell('الحالة', flex: 2, align: TextAlign.end, head: true),
                  ],
                ),
              ),
              Divider(height: 1, color: taj.divider),
              for (final r in kDemoBackupHistory) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      cell(r.date, flex: 3),
                      cell(r.size, flex: 2, align: TextAlign.center),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: StatusBadge(
                            label: r.ok ? 'ناجحة' : 'فشلت',
                            status: r.ok ? TajStatus.success : TajStatus.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (r != kDemoBackupHistory.last)
                  Divider(height: 1, color: taj.divider),
              ],
            ],
          ),
        );

        if (tableWidth <= c.maxWidth) return table;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: table,
        );
      },
    );
  }
}
