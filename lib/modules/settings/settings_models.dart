import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Identity of each Settings section, in sub-navigation order.
enum SettingsSectionId { appearance, localization, invoice, discount, dayClosing, sync }

/// Metadata for a section as shown in the sub-navigation (list / sidebar).
@immutable
class SettingsSectionMeta {
  const SettingsSectionMeta(this.id, this.title, this.subtitle, this.icon);
  final SettingsSectionId id;
  final String title;
  final String subtitle;
  final IconData icon;
}

/// The sub-navigation, in order. Titles/subtitles/icons match the original
/// placeholder rows so nothing about the module's identity changes.
const List<SettingsSectionMeta> settingsSections = [
  SettingsSectionMeta(SettingsSectionId.appearance, 'المظهر',
      'الألوان، الوضع الداكن، شكل الرسوم', Icons.palette_outlined),
  SettingsSectionMeta(SettingsSectionId.localization, 'اللغة والعملة والضرائب',
      'العربية • الدينار الليبي • الضريبة', Icons.translate_rounded),
  SettingsSectionMeta(SettingsSectionId.invoice, 'الفواتير والطباعة',
      'قالب الفاتورة، الطابعة الحرارية', Icons.receipt_long_outlined),
  SettingsSectionMeta(SettingsSectionId.discount, 'سياسة الخصم',
      'النطاق، المدة، المستخدمون المخوّلون', Icons.percent_rounded),
  SettingsSectionMeta(SettingsSectionId.dayClosing, 'سياسة الإقفال اليومي',
      'وقت الإقفال، المراجعة، القفل', Icons.event_available_outlined),
  SettingsSectionMeta(SettingsSectionId.sync, 'المزامنة والنسخ الاحتياطي',
      'أوف‑لاين، آخر نسخة احتياطية', Icons.sync_rounded),
];

SettingsSectionMeta settingsSectionMeta(SettingsSectionId id) =>
    settingsSections.firstWhere((s) => s.id == id);

// ---------------------------------------------------------------------------
// Option enums
// ---------------------------------------------------------------------------

enum AppLanguage {
  arabic('العربية'),
  english('الإنجليزية');

  const AppLanguage(this.label);
  final String label;
}

enum AppCurrency {
  lyd('الدينار الليبي', 'د.ل'),
  usd('الدولار الأمريكي', r'$'),
  eur('اليورو', '€');

  const AppCurrency(this.label, this.symbol);
  final String label;
  final String symbol;
}

enum NumberStyle {
  arabicIndic('أرقام عربية ٠١٢٣'),
  western('أرقام لاتينية 0123');

  const NumberStyle(this.label);
  final String label;
}

/// Scope of a discount campaign.
enum DiscountScope {
  item('صنف محدد', Icons.inventory_2_outlined),
  group('مجموعة', Icons.category_outlined),
  category('تصنيف', Icons.sell_outlined),
  all('كل الأصناف', Icons.select_all_rounded);

  const DiscountScope(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum PaperSize {
  a4('A4', Icons.description_outlined),
  thermal('حراري 80mm', Icons.receipt_outlined);

  const PaperSize(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum BackupFrequency {
  daily('يومي'),
  weekly('أسبوعي'),
  monthly('شهري');

  const BackupFrequency(this.label);
  final String label;
}

// ---------------------------------------------------------------------------
// Demo option data (prototype — in-memory only)
// ---------------------------------------------------------------------------

const List<String> kDemoDiscountItems = [
  'عود ملكي', 'بخور فاخر', 'دهن عود', 'مسك أبيض',
  'عنبر', 'ماء ورد', 'زعفران', 'صندل', 'مبخرة نحاسية', 'عطر شرقي',
];

const List<String> kDemoBranches = [
  'الفرع الرئيسي', 'فرع طرابلس', 'فرع بنغازي', 'فرع مصراتة',
];

const List<String> kDemoUsers = [
  'أحمد علي', 'سالم محمد', 'فاطمة إبراهيم', 'خالد يوسف', 'ليلى حسن',
];

const List<String> kDemoPrinters = [
  'الطابعة الحرارية 80mm', 'طابعة A4 - المكتب', 'طابعة الكاشير 58mm',
];

/// One row of the backup-history demo table.
@immutable
class BackupRecord {
  const BackupRecord(this.date, this.size, this.ok);
  final String date;
  final String size;
  final bool ok;
}

const List<BackupRecord> kDemoBackupHistory = [
  BackupRecord('2026/09/12 03:00', '48٫2 MB', true),
  BackupRecord('2026/09/11 03:00', '47٫9 MB', true),
  BackupRecord('2026/09/10 03:00', '47٫1 MB', true),
  BackupRecord('2026/09/09 03:00', '—', false),
  BackupRecord('2026/09/08 03:00', '46٫8 MB', true),
];

// ---------------------------------------------------------------------------
// Editable settings draft
// ---------------------------------------------------------------------------

/// The whole editable settings state for the form sections (everything except
/// Appearance, whose primary colour / dark mode / chart style apply *live* via
/// the app's own callbacks and are deliberately never part of this draft).
///
/// This is a prototype, so the draft lives only in memory: [SettingsScreen]
/// keeps a `_saved` snapshot and a working `_draft`; "unsaved changes" is simply
/// `draft != saved`, and Save/Discard commit or restore the snapshot. No real
/// persistence or system effect is touched.
@immutable
class SettingsDraft {
  const SettingsDraft({
    // Localization
    this.language = AppLanguage.arabic,
    this.currency = AppCurrency.lyd,
    this.taxRate = 0,
    this.taxInclusive = false,
    this.numberStyle = NumberStyle.western,
    // Invoice & print
    this.storeName = 'مؤسسة التاج للعود والعطور',
    this.invoiceHeader = 'فاتورة ضريبية مبسطة',
    this.invoiceFooter = 'شكراً لتسوقكم — لا يُسترجع العطر بعد فتح العبوة',
    this.showLogo = true,
    this.paperSize = PaperSize.thermal,
    this.printCopies = 1,
    this.printer = 'الطابعة الحرارية 80mm',
    // Discount policy
    this.discountEnabled = true,
    this.discountScope = DiscountScope.category,
    this.discountTargets = const <String>{'عود ملكي', 'بخور فاخر'},
    this.discountStart,
    this.discountEnd,
    this.discountBranches = const <String>{'الفرع الرئيسي'},
    this.discountUsers = const <String>{'أحمد علي'},
    this.discountAutoOff = true,
    this.maxDiscountPct = 15,
    // Day-closing policy
    this.closingTime = const TimeOfDay(hour: 23, minute: 0),
    this.requireReview = true,
    this.autoClose = false,
    this.lockAfterClose = true,
    this.graceMinutes = 30,
    this.notifyOnClose = true,
    // Sync & backup
    this.offlineMode = true,
    this.autoBackup = true,
    this.backupFrequency = BackupFrequency.daily,
  });

  // Localization
  final AppLanguage language;
  final AppCurrency currency;
  final double taxRate;
  final bool taxInclusive;
  final NumberStyle numberStyle;

  // Invoice & print
  final String storeName;
  final String invoiceHeader;
  final String invoiceFooter;
  final bool showLogo;
  final PaperSize paperSize;
  final int printCopies;
  final String printer;

  // Discount policy
  final bool discountEnabled;
  final DiscountScope discountScope;
  final Set<String> discountTargets;
  final DateTime? discountStart;
  final DateTime? discountEnd;
  final Set<String> discountBranches;
  final Set<String> discountUsers;
  final bool discountAutoOff;
  final double maxDiscountPct;

  // Day-closing policy
  final TimeOfDay closingTime;
  final bool requireReview;
  final bool autoClose;
  final bool lockAfterClose;
  final int graceMinutes;
  final bool notifyOnClose;

  // Sync & backup
  final bool offlineMode;
  final bool autoBackup;
  final BackupFrequency backupFrequency;

  SettingsDraft copyWith({
    AppLanguage? language,
    AppCurrency? currency,
    double? taxRate,
    bool? taxInclusive,
    NumberStyle? numberStyle,
    String? storeName,
    String? invoiceHeader,
    String? invoiceFooter,
    bool? showLogo,
    PaperSize? paperSize,
    int? printCopies,
    String? printer,
    bool? discountEnabled,
    DiscountScope? discountScope,
    Set<String>? discountTargets,
    DateTime? discountStart,
    DateTime? discountEnd,
    bool clearDiscountStart = false,
    bool clearDiscountEnd = false,
    Set<String>? discountBranches,
    Set<String>? discountUsers,
    bool? discountAutoOff,
    double? maxDiscountPct,
    TimeOfDay? closingTime,
    bool? requireReview,
    bool? autoClose,
    bool? lockAfterClose,
    int? graceMinutes,
    bool? notifyOnClose,
    bool? offlineMode,
    bool? autoBackup,
    BackupFrequency? backupFrequency,
  }) {
    return SettingsDraft(
      language: language ?? this.language,
      currency: currency ?? this.currency,
      taxRate: taxRate ?? this.taxRate,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      numberStyle: numberStyle ?? this.numberStyle,
      storeName: storeName ?? this.storeName,
      invoiceHeader: invoiceHeader ?? this.invoiceHeader,
      invoiceFooter: invoiceFooter ?? this.invoiceFooter,
      showLogo: showLogo ?? this.showLogo,
      paperSize: paperSize ?? this.paperSize,
      printCopies: printCopies ?? this.printCopies,
      printer: printer ?? this.printer,
      discountEnabled: discountEnabled ?? this.discountEnabled,
      discountScope: discountScope ?? this.discountScope,
      discountTargets: discountTargets ?? this.discountTargets,
      discountStart:
          clearDiscountStart ? null : (discountStart ?? this.discountStart),
      discountEnd: clearDiscountEnd ? null : (discountEnd ?? this.discountEnd),
      discountBranches: discountBranches ?? this.discountBranches,
      discountUsers: discountUsers ?? this.discountUsers,
      discountAutoOff: discountAutoOff ?? this.discountAutoOff,
      maxDiscountPct: maxDiscountPct ?? this.maxDiscountPct,
      closingTime: closingTime ?? this.closingTime,
      requireReview: requireReview ?? this.requireReview,
      autoClose: autoClose ?? this.autoClose,
      lockAfterClose: lockAfterClose ?? this.lockAfterClose,
      graceMinutes: graceMinutes ?? this.graceMinutes,
      notifyOnClose: notifyOnClose ?? this.notifyOnClose,
      offlineMode: offlineMode ?? this.offlineMode,
      autoBackup: autoBackup ?? this.autoBackup,
      backupFrequency: backupFrequency ?? this.backupFrequency,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsDraft &&
        other.language == language &&
        other.currency == currency &&
        other.taxRate == taxRate &&
        other.taxInclusive == taxInclusive &&
        other.numberStyle == numberStyle &&
        other.storeName == storeName &&
        other.invoiceHeader == invoiceHeader &&
        other.invoiceFooter == invoiceFooter &&
        other.showLogo == showLogo &&
        other.paperSize == paperSize &&
        other.printCopies == printCopies &&
        other.printer == printer &&
        other.discountEnabled == discountEnabled &&
        other.discountScope == discountScope &&
        setEquals(other.discountTargets, discountTargets) &&
        other.discountStart == discountStart &&
        other.discountEnd == discountEnd &&
        setEquals(other.discountBranches, discountBranches) &&
        setEquals(other.discountUsers, discountUsers) &&
        other.discountAutoOff == discountAutoOff &&
        other.maxDiscountPct == maxDiscountPct &&
        other.closingTime == closingTime &&
        other.requireReview == requireReview &&
        other.autoClose == autoClose &&
        other.lockAfterClose == lockAfterClose &&
        other.graceMinutes == graceMinutes &&
        other.notifyOnClose == notifyOnClose &&
        other.offlineMode == offlineMode &&
        other.autoBackup == autoBackup &&
        other.backupFrequency == backupFrequency;
  }

  // Sets are intentionally represented by their length only in the hash (equal
  // drafts still hash equal — set *contents* are compared in `==`). This keeps
  // the hash cheap while honouring the equals/hashCode contract.
  @override
  int get hashCode => Object.hashAll([
        language, currency, taxRate, taxInclusive, numberStyle,
        storeName, invoiceHeader, invoiceFooter, showLogo, paperSize,
        printCopies, printer,
        discountEnabled, discountScope, discountTargets.length,
        discountStart, discountEnd,
        discountBranches.length, discountUsers.length, discountAutoOff,
        maxDiscountPct,
        closingTime, requireReview, autoClose, lockAfterClose, graceMinutes,
        notifyOnClose,
        offlineMode, autoBackup, backupFrequency,
      ]);
}
