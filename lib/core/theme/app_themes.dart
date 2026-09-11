import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'taj_colors.dart';

/// Central theme factory for TAJ — the **Minimals** visual base.
///
/// Type: **Almarai** is the single official Taj typeface — every string AND
/// every numeral (Arabic-Indic ٠١٢٣ and Latin 0123) renders in it, so the UI
/// reads as one consistent whole. Almarai ships 300/400/700/800 only; requested
/// 500/600 snap to the nearest real weight (500→400, 600→700) — never a fake
/// synthesized bold. Tabular figures keep columns of numbers aligned.
class AppThemes {
  const AppThemes._();

  static ThemeData light({TajSwatch? primary}) =>
      _build(Brightness.light, _apply(TajColors.light, primary));
  static ThemeData dark({TajSwatch? primary}) =>
      _build(Brightness.dark, _apply(TajColors.dark, primary));

  /// Override the primary swatch (admin-selected accent) on a base palette.
  static TajColors _apply(TajColors base, TajSwatch? primary) =>
      primary == null ? base : base.copyWith(primary: primary);

  static ThemeData _build(Brightness brightness, TajColors taj) {
    final isDark = brightness == Brightness.dark;

    // Foreground colours are brightness-aware: the same role resolves to a
    // dark grey on light surfaces and a light grey on dark surfaces, so icon
    // buttons, secondary text and disabled states stay legible in both modes.
    // (The old code pinned onSurfaceVariant to `neutral.dark` — #212B36 —
    // which made every Material 3 IconButton invisible on dark surfaces.)
    final iconColor = isDark ? TajGrey.g400 : TajGrey.g600;
    final iconDisabled = isDark ? TajGrey.g700 : TajGrey.g400;

    final scheme = ColorScheme.fromSeed(
      seedColor: taj.primary.main,
      brightness: brightness,
    ).copyWith(
      primary: taj.primary.main,
      onPrimary: taj.primary.contrastText,
      secondary: taj.neutral.main,
      onSecondary: taj.neutral.contrastText,
      surface: taj.paper,
      onSurface: taj.textPrimary,
      onSurfaceVariant: taj.textSecondary,
      error: taj.error.main,
      onError: taj.error.contrastText,
      outline: taj.divider,
      outlineVariant: taj.divider,
      surfaceContainerHighest: taj.neutral.main.withValues(alpha: 0.12),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: taj.background,
      textTheme: _textTheme(taj.textPrimary),
      extensions: [taj],
      dividerTheme: DividerThemeData(color: taj.divider, thickness: 1, space: 1),
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        elevation: 0,
        color: taj.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: taj.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: taj.textPrimary,
        iconTheme: IconThemeData(color: iconColor),
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: IconThemeData(color: iconColor),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: iconColor,
          disabledForegroundColor: iconDisabled,
          hoverColor: (isDark ? Colors.white : TajGrey.g800).withValues(alpha: 0.06),
          highlightColor: (isDark ? Colors.white : TajGrey.g800).withValues(alpha: 0.10),
          focusColor: (isDark ? Colors.white : TajGrey.g800).withValues(alpha: 0.10),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return taj.primary.main;
          return isDark ? TajGrey.g400 : TajGrey.g500;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return taj.primary.main.withValues(alpha: 0.45);
          }
          return isDark ? TajGrey.g700 : TajGrey.g300;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: taj.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: taj.primary.lighter,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? taj.primary.main
                : iconColor,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? taj.primary.dark
                : taj.textSecondary,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: taj.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.almarai(
            fontSize: 18, fontWeight: FontWeight.w700, color: taj.textPrimary),
        contentTextStyle: GoogleFonts.almarai(
            fontSize: 14, color: taj.textPrimary, height: 1.6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: taj.paper,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        modalBarrierColor: Colors.black.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: taj.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.almarai(
            fontSize: 14, color: taj.textPrimary, height: 1.4),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: iconColor,
        textColor: taj.textPrimary,
        subtitleTextStyle:
            TextStyle(color: taj.textSecondary, fontSize: 13, height: 1.4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? TajGrey.g800 : TajGrey.g900,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? TajGrey.g900 : TajGrey.g100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: taj.textDisabled),
        iconColor: iconColor,
        prefixIconColor: iconColor,
        suffixIconColor: iconColor,
        border: _inputBorder(taj.divider),
        enabledBorder: _inputBorder(taj.divider),
        focusedBorder: _inputBorder(taj.primary.main, width: 1.5),
        errorBorder: _inputBorder(taj.error.main),
        focusedErrorBorder: _inputBorder(taj.error.main, width: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle()),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle().copyWith(
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle().copyWith(
          side: WidgetStatePropertyAll(BorderSide(color: taj.divider)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.almarai(
              fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? TajGrey.g800 : TajGrey.g200,
        shape: const StadiumBorder(),
        side: BorderSide(color: taj.divider),
        labelStyle: TextStyle(color: taj.textPrimary, fontSize: 13),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: TajGrey.g800,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  static ButtonStyle _buttonStyle() => FilledButton.styleFrom(
        textStyle: GoogleFonts.almarai(fontWeight: FontWeight.w600, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );

  /// The Almarai type scale (h1 40/800 … caption 12/400, buttons 14–15/600,
  /// no ALL-CAPS). Almarai covers Arabic + Latin, so one family serves the whole
  /// theme; 500/600 requests resolve to the nearest real weight (400/700).
  static TextTheme _textTheme(Color color) {
    final base = ThemeData(brightness: Brightness.light).textTheme
        .apply(bodyColor: color, displayColor: color);
    final t = GoogleFonts.almaraiTextTheme(base);

    TextStyle s(TextStyle? base, double size, FontWeight w, [double h = 1.5]) =>
        (base ?? const TextStyle())
            .copyWith(fontSize: size, fontWeight: w, height: h, color: color);

    return t.copyWith(
      displayLarge: s(t.displayLarge, 40, FontWeight.w800, 1.25), // h1
      displayMedium: s(t.displayMedium, 32, FontWeight.w800, 1.33), // h2
      displaySmall: s(t.displaySmall, 24, FontWeight.w700), // h3
      headlineMedium: s(t.headlineMedium, 24, FontWeight.w700), // h3
      headlineSmall: s(t.headlineSmall, 20, FontWeight.w700), // h4
      titleLarge: s(t.titleLarge, 18, FontWeight.w700), // h5
      titleMedium: s(t.titleMedium, 16, FontWeight.w600), // subtitle1
      titleSmall: s(t.titleSmall, 14, FontWeight.w600), // subtitle2
      bodyLarge: s(t.bodyLarge, 16, FontWeight.w400),
      bodyMedium: s(t.bodyMedium, 14, FontWeight.w400),
      bodySmall: s(t.bodySmall, 12, FontWeight.w400), // caption
      labelLarge: s(t.labelLarge, 14, FontWeight.w600, 1.7), // button/nav
      labelMedium: s(t.labelMedium, 13, FontWeight.w600),
      labelSmall: s(t.labelSmall, 12, FontWeight.w600),
    );
  }

  /// Numeral style — money and metrics. Uses **Almarai** like the rest of the UI
  /// (both ٠١٢٣ and 0123) so numbers never look detached from the Arabic text
  /// beside them, with tabular figures so digit columns stay aligned.
  static TextStyle numeralStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return GoogleFonts.almarai(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Soft, low-contrast Minimals card shadow (grey-500 based).
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const [
        BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12)),
      ];
    }
    const grey = Color(0xFF919EAB);
    return [
      BoxShadow(color: grey.withValues(alpha: 0.20), blurRadius: 2),
      BoxShadow(
        color: grey.withValues(alpha: 0.12),
        blurRadius: 24,
        spreadRadius: -4,
        offset: const Offset(0, 12),
      ),
    ];
  }
}
