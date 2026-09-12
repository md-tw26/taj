import 'package:flutter/material.dart';

import '../../core/chart_style.dart';
import '../../core/responsive.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_ui.dart';
import 'settings_models.dart';

/// Bounds a preview miniature: centred, width clamped to
/// [AppBreakpoints.settingsPreviewMin]…[settingsPreviewMax], with a fixed
/// [aspect] so it can never force the page height. The child is a fixed-size
/// mock scaled down by a [FittedBox] — the *only* place a fixed scale is allowed
/// (a miniature of the real UI), per the module rules.
class PreviewFrame extends StatelessWidget {
  const PreviewFrame({
    super.key,
    required this.aspect,
    required this.child,
    required this.mockSize,
  });

  final double aspect;
  final Widget child;
  final Size mockSize;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppBreakpoints.settingsPreviewMin,
          maxWidth: AppBreakpoints.settingsPreviewMax,
        ),
        child: AspectRatio(
          aspectRatio: aspect,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: mockSize.width,
              height: mockSize.height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A live miniature of the app UI reflecting the selected primary colour, the
/// current brightness, and the chosen chart style.
class ThemePreviewMini extends StatelessWidget {
  const ThemePreviewMini({
    super.key,
    required this.primary,
    required this.chartStyle,
  });

  final TajSwatch primary;
  final ChartStyle chartStyle;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    const mock = Size(320, 200);
    return PreviewFrame(
      aspect: AppBreakpoints.settingsThemePreviewAspect,
      mockSize: mock,
      child: Container(
        decoration: BoxDecoration(
          color: taj.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: taj.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Top bar
            Container(
              height: 34,
              color: taj.paper,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                        color: primary.main,
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 70, height: 8, color: taj.divider),
                  const Spacer(),
                  CircleAvatar(radius: 8, backgroundColor: primary.lighter),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sidebar
                  Container(
                    width: 56,
                    color: taj.paper,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Column(
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: i == 0 ? primary.lighter : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _MiniKpi(primary: primary, taj: taj),
                              const SizedBox(width: 8),
                              _MiniKpi(primary: primary, taj: taj, filled: true),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: taj.paper,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: taj.divider),
                              ),
                              child: Sparkline(
                                values: const [12, 18, 14, 22, 19, 26, 24, 30],
                                color: primary.main,
                                style: chartStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({required this.primary, required this.taj, this.filled = false});
  final TajSwatch primary;
  final TajColors taj;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: filled ? primary.main : taj.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: filled ? primary.main : taj.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 34,
                height: 6,
                color: (filled ? Colors.white : taj.divider).withValues(alpha: 0.7)),
            const SizedBox(height: 6),
            Container(
                width: 22,
                height: 8,
                color: filled ? Colors.white : primary.main),
          ],
        ),
      ),
    );
  }
}

/// A miniature of the printed invoice / receipt, at an A4 or thermal aspect
/// ratio. Illustrative only — it never affects the real print output.
class InvoicePreviewMini extends StatelessWidget {
  const InvoicePreviewMini({super.key, required this.draft});
  final SettingsDraft draft;

  @override
  Widget build(BuildContext context) {
    final thermal = draft.paperSize == PaperSize.thermal;
    final aspect = thermal
        ? AppBreakpoints.settingsReceiptAspect
        : AppBreakpoints.settingsA4Aspect;
    final mock = thermal ? const Size(220, 440) : const Size(300, 424);
    return PreviewFrame(
      aspect: aspect,
      mockSize: mock,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDFE3E8)),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        // .merge (not a bare DefaultTextStyle) so the miniature inherits Almarai
        // from the theme and only layers size/colour — never the system font.
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Color(0xFF212B36), fontSize: 11, height: 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (draft.showLogo)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.storefront_outlined,
                      size: 22, color: Color(0xFF637381)),
                ),
              if (draft.showLogo) const SizedBox(height: 8),
              Text(draft.storeName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF212B36))),
              const SizedBox(height: 2),
              Text(draft.invoiceHeader,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF637381))),
              const SizedBox(height: 10),
              const _DashLine(),
              const SizedBox(height: 8),
              for (final (n, p) in const [
                ('عود ملكي × ٢', '٣٠٠'),
                ('بخور فاخر', '١٢٠'),
                ('ماء ورد', '٤٥'),
              ]) ...[
                Row(
                  children: [
                    Expanded(child: Text(n, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(p),
                  ],
                ),
                const SizedBox(height: 5),
              ],
              const SizedBox(height: 3),
              const _DashLine(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text('الإجمالي',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  Text('${draft.currency.symbol} ٤٦٥',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
              if (draft.taxRate > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                        child: Text('الضريبة (${_fmtPct(draft.taxRate)}٪)',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF637381)))),
                    Text(_fmtPct(draft.taxRate * 4.65),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF637381))),
                  ],
                ),
              ],
              const Spacer(),
              const _DashLine(),
              const SizedBox(height: 6),
              Text(draft.invoiceFooter,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF637381))),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtPct(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _DashLine extends StatelessWidget {
  const _DashLine();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          const dash = 4.0, gap = 3.0;
          final count = (c.maxWidth / (dash + gap)).floor().clamp(0, 200);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(width: dash, height: 1, color: const Color(0xFFC4CDD5)),
            ),
          );
        },
      );
}
