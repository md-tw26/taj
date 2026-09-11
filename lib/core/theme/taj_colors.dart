import 'package:flutter/material.dart';

/// A Minimals-style colour swatch: five tints + a contrast text colour.
///
/// Badges use `lighter` as background and `dark` as text of the same hue.
@immutable
class TajSwatch {
  const TajSwatch({
    required this.lighter,
    required this.light,
    required this.main,
    required this.dark,
    required this.darker,
    required this.contrastText,
  });

  final Color lighter;
  final Color light;
  final Color main;
  final Color dark;
  final Color darker;
  final Color contrastText;

  static TajSwatch lerp(TajSwatch a, TajSwatch b, double t) => TajSwatch(
        lighter: Color.lerp(a.lighter, b.lighter, t)!,
        light: Color.lerp(a.light, b.light, t)!,
        main: Color.lerp(a.main, b.main, t)!,
        dark: Color.lerp(a.dark, b.dark, t)!,
        darker: Color.lerp(a.darker, b.darker, t)!,
        contrastText: Color.lerp(a.contrastText, b.contrastText, t)!,
      );
}

/// The Minimals grey scale (identical in light and dark).
abstract final class TajGrey {
  static const g100 = Color(0xFFF9FAFB);
  static const g200 = Color(0xFFF4F6F8);
  static const g300 = Color(0xFFDFE3E8);
  static const g400 = Color(0xFFC4CDD5);
  static const g500 = Color(0xFF919EAB);
  static const g600 = Color(0xFF637381);
  static const g700 = Color(0xFF454F5B);
  static const g800 = Color(0xFF212B36);
  static const g900 = Color(0xFF161C24);
}

/// TAJ design tokens — the **Minimals** foundation.
///
/// Colour policy (see TAJ-Development-Fix-Plan.md §Phase 2):
///   • primary  — the approved brand blue (#2065D1). Used for the main action
///     button, the logo accent and active navigation only.
///   • neutral   — a single dark grey for all equal-priority buttons (e.g. the
///     six POS payment buttons). Differentiation is by icon only.
///   • success / warning / error / info — exactly four functional colours for
///     financial meaning or system status only.
///
/// Read anywhere via `context.taj`; never hardcode a colour on a screen.
@immutable
class TajColors extends ThemeExtension<TajColors> {
  const TajColors({
    required this.primary,
    required this.neutral,
    required this.secondary,
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.divider,
    required this.background,
    required this.paper,
    required this.hover,
    this.brightness = Brightness.light,
  });

  // Semantic swatches (Minimals — same hues across modes).
  final TajSwatch primary;
  final TajSwatch neutral;
  final TajSwatch secondary;
  final TajSwatch info;
  final TajSwatch success;
  final TajSwatch warning;
  final TajSwatch error;

  // Mode-dependent neutrals.
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color divider;
  final Color background; // page background
  final Color paper; // card / surface
  final Color hover; // subtle row / item hover

  /// Which colour mode this token set belongs to — drives [accentFor].
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  /// Legible accent for text/icons sitting **directly on a neutral surface**
  /// (paper / background). A swatch's `dark` shade reads well on light
  /// surfaces but vanishes on dark ones, so resolve per brightness:
  /// light mode → the swatch's dark shade; dark mode → its light shade
  /// (error uses its saturated main because its `light` is a muted grey).
  Color accentFor(TajSwatch s) =>
      isDark ? (s == error ? s.main : s.light) : s.dark;

  /// Convenience accent for the primary brand colour.
  Color get accentText => accentFor(primary);

  // ---- Minimals swatch definitions (shared by light + dark) ----
  static const _primary = TajSwatch(
    lighter: Color(0xFFC8FAD6), light: Color(0xFF5BE49B), main: Color(0xFF00A76F),
    dark: Color(0xFF007867), darker: Color(0xFF004B50), contrastText: Colors.white);
  static const _secondary = TajSwatch(
    lighter: Color(0xFFEFD6FF), light: Color(0xFFC684FF), main: Color(0xFF8E33FF),
    dark: Color(0xFF5119B7), darker: Color(0xFF27097A), contrastText: Colors.white);
  static const _info = TajSwatch(
    lighter: Color(0xFFCAFDF5), light: Color(0xFF61F3F3), main: Color(0xFF00B8D9),
    dark: Color(0xFF006C9C), darker: Color(0xFF003768), contrastText: Colors.white);
  static const _success = TajSwatch(
    lighter: Color(0xFFD3FCD2), light: Color(0xFF77ED8B), main: Color(0xFF22C55E),
    dark: Color(0xFF118D57), darker: Color(0xFF065E49), contrastText: Colors.white);
  static const _warning = TajSwatch(
    lighter: Color(0xFFFFF5CC), light: Color(0xFFFFD666), main: Color(0xFFFFAB00),
    dark: Color(0xFFB76E00), darker: Color(0xFF7A4100), contrastText: Color(0xFF1C252E));
  static const _error = TajSwatch(
    lighter: Color(0xFFFFE9D5), light: Color(0xFFB0BEC5), main: Color(0xFFFF5630),
    dark: Color(0xFFB71D18), darker: Color(0xFF7A0916), contrastText: Colors.white);

  /// Brand blue — **the approved primary** (TAJ-Development-Fix-Plan.md §Phase 2).
  static const blueSwatch = TajSwatch(
    lighter: Color(0xFFD1E9FC), light: Color(0xFF76B0F1), main: Color(0xFF2065D1),
    dark: Color(0xFF103996), darker: Color(0xFF061B64), contrastText: Colors.white);

  /// Cobalt accent — alternative primary option.
  static const cobaltSwatch = TajSwatch(
    lighter: Color(0xFFCCE0FF), light: Color(0xFF6597F2), main: Color(0xFF0C68E9),
    dark: Color(0xFF063EA3), darker: Color(0xFF02205C), contrastText: Colors.white);

  /// Single dark-grey neutral for all equal-priority buttons.
  /// Differentiation is by icon only (TAJ-Development-Fix-Plan.md §Phase 3.2).
  static const neutralSwatch = TajSwatch(
    lighter: TajGrey.g200, light: TajGrey.g400, main: TajGrey.g700,
    dark: TajGrey.g800, darker: TajGrey.g900, contrastText: Colors.white);

  // Public Minimals swatches (selectable as the app's primary).
  static const primarySwatch = blueSwatch; // default brand primary per spec
  static const emeraldSwatch = _primary;
  static const purpleSwatch = _secondary;
  static const infoSwatch = _info;
  static const successSwatch = _success;
  static const warningSwatch = _warning;
  static const errorSwatch = _error;

  /// The palette offered to the admin in Settings (name → swatch).
  /// Default primary is **blue** (أزرق) per TAJ-Development-Fix-Plan §Phase 2.
  static const List<(String, TajSwatch)> palette = [
    ('أزرق', blueSwatch),
    ('سماوي', _info),
    ('زمردي', _primary),
    ('بنفسجي', _secondary),
    ('كوبالت', cobaltSwatch),
    ('أخضر', _success),
    ('كهرماني', _warning),
    ('أحمر', _error),
  ];

  static const TajColors light = TajColors(
    primary: blueSwatch,
    neutral: neutralSwatch,
    secondary: _secondary, info: _info,
    success: _success, warning: _warning, error: _error,
    textPrimary: TajGrey.g800, // #212B36
    textSecondary: TajGrey.g600, // #637381
    textDisabled: TajGrey.g500, // #919EAB
    divider: TajGrey.g300, // #DFE3E8
    background: TajGrey.g100, // #F9FAFB page
    paper: Colors.white,
    hover: TajGrey.g100,
    brightness: Brightness.light,
  );

  static const TajColors dark = TajColors(
    primary: blueSwatch,
    neutral: neutralSwatch,
    secondary: _secondary, info: _info,
    success: _success, warning: _warning, error: _error,
    textPrimary: Colors.white,
    textSecondary: TajGrey.g500, // #919EAB
    textDisabled: TajGrey.g600,
    divider: Color(0x33919EAB), // grey-500 @20%
    background: TajGrey.g900, // #161C24
    paper: TajGrey.g800, // #212B36
    hover: Color(0x14919EAB), // grey-500 @8%
    brightness: Brightness.dark,
  );

  /// Resolve a semantic swatch by role — handy for status-driven UI.
  TajSwatch swatch(TajStatus status) => switch (status) {
        TajStatus.primary => primary,
        TajStatus.secondary => secondary,
        TajStatus.info => info,
        TajStatus.success => success,
        TajStatus.warning => warning,
        TajStatus.error => error,
      };

  @override
  TajColors copyWith({
    TajSwatch? primary,
    TajSwatch? neutral,
    TajSwatch? secondary,
    TajSwatch? info,
    TajSwatch? success,
    TajSwatch? warning,
    TajSwatch? error,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? divider,
    Color? background,
    Color? paper,
    Color? hover,
  }) {
    return TajColors(
      primary: primary ?? this.primary,
      neutral: neutral ?? this.neutral,
      secondary: secondary ?? this.secondary,
      info: info ?? this.info,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      divider: divider ?? this.divider,
      background: background ?? this.background,
      paper: paper ?? this.paper,
      hover: hover ?? this.hover,
      brightness: brightness,
    );
  }

  @override
  TajColors lerp(ThemeExtension<TajColors>? other, double t) {
    if (other is! TajColors) return this;
    return TajColors(
      primary: TajSwatch.lerp(primary, other.primary, t),
      neutral: TajSwatch.lerp(neutral, other.neutral, t),
      secondary: TajSwatch.lerp(secondary, other.secondary, t),
      info: TajSwatch.lerp(info, other.info, t),
      success: TajSwatch.lerp(success, other.success, t),
      warning: TajSwatch.lerp(warning, other.warning, t),
      error: TajSwatch.lerp(error, other.error, t),
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      background: Color.lerp(background, other.background, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      brightness: brightness,
    );
  }
}

/// Semantic status used across badges, chips and KPI deltas.
enum TajStatus { primary, secondary, info, success, warning, error }

/// `context.taj` — the ergonomic accessor for [TajColors] tokens.
extension TajColorsX on BuildContext {
  TajColors get taj =>
      Theme.of(this).extension<TajColors>() ?? TajColors.light;
}
