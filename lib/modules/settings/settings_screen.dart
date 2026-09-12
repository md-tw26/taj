import 'package:flutter/material.dart';

import '../../core/chart_style.dart';
import '../../core/responsive.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_ui.dart';
import 'settings_models.dart';
import 'settings_sections.dart';

/// Settings (spec 7.18) — a Linear-style **sub-navigation + content** module.
///
/// Layout keys off the *available* width (never the device):
///  * **< [AppBreakpoints.settingsSplit] (820):** the section list is a full page
///    and tapping a section pushes its page with a back affordance. The save bar
///    is pinned to the screen bottom (respecting `SafeArea`).
///  * **≥ 820:** a persistent sub-navigation sidebar (clamped, never stretched)
///    sits beside the content; the content column caps at
///    [AppBreakpoints.settingsContentMax] (~880) and centres, with the save bar
///    inside the content area.
///  * **> 1920:** the whole page caps at [AppBreakpoints.settingsContentMaxWidth]
///    and centres.
///
/// The **Appearance** section (primary colour / dark mode / chart style) applies
/// *live* through the app's own callbacks and is intentionally never part of the
/// draft — its logic and system effects are untouched. The other five sections
/// edit an in-memory [SettingsDraft]; "unsaved changes" is `draft != saved`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.currentPrimary,
    required this.onPrimaryChanged,
    required this.onToggleTheme,
    required this.chartStyle,
    required this.onChartStyleChanged,
    this.testInitialSection,
  });

  final TajSwatch currentPrimary;
  final ValueChanged<TajSwatch> onPrimaryChanged;
  final VoidCallback onToggleTheme;
  final ChartStyle chartStyle;
  final ValueChanged<ChartStyle> onChartStyleChanged;

  /// Test hook: open straight into a section (as if it had been tapped).
  final SettingsSectionId? testInitialSection;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsSectionId _selected = SettingsSectionId.appearance;

  /// Whether a section has been navigated into. On narrow widths this drives the
  /// list ↔ section-page switch; on wide widths the content is always shown, so
  /// resizing wide→narrow while inside a section keeps that section open.
  bool _inSection = false;

  SettingsDraft _saved = const SettingsDraft();
  SettingsDraft _draft = const SettingsDraft();

  bool get _dirty => _draft != _saved;

  @override
  void initState() {
    super.initState();
    if (widget.testInitialSection != null) {
      _selected = widget.testInitialSection!;
      _inSection = true;
    }
  }

  void _openSection(SettingsSectionId id) =>
      setState(() {
        _selected = id;
        _inSection = true;
      });

  void _backToList() => setState(() => _inSection = false);

  void _onDraft(SettingsDraft d) => setState(() => _draft = d);

  void _save() {
    setState(() => _saved = _draft);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات')));
  }

  void _discard() => setState(() => _draft = _saved);

  bool _rtl(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= AppBreakpoints.settingsSplit;
        return PageContainer(
          maxWidth: AppBreakpoints.settingsContentMaxWidth,
          child: wide ? _buildWide(context, c.maxWidth) : _buildNarrow(context),
        );
      },
    );
  }

  SettingsSectionContent _content(SettingsSectionId id) => SettingsSectionContent(
        key: ValueKey(id),
        id: id,
        draft: _draft,
        onDraft: _onDraft,
        currentPrimary: widget.currentPrimary,
        onPrimaryChanged: widget.onPrimaryChanged,
        onToggleTheme: widget.onToggleTheme,
        chartStyle: widget.chartStyle,
        onChartStyleChanged: widget.onChartStyleChanged,
      );

  // -------------------------------------------------------------------------
  // Wide: sidebar + content
  // -------------------------------------------------------------------------

  Widget _buildWide(BuildContext context, double width) {
    final taj = context.taj;
    final railW = width < AppBreakpoints.laptop
        ? (width * 0.26).clamp(
            AppBreakpoints.settingsSidebarMin, AppBreakpoints.settingsSidebarMid)
        : (width * 0.18).clamp(
            AppBreakpoints.settingsSidebarMid, AppBreakpoints.settingsSidebarMax);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: railW.toDouble(),
          child: _Sidebar(selected: _selected, onSelect: _openSection),
        ),
        VerticalDivider(width: 1, color: taj.divider),
        Expanded(child: _wideContentPane(context)),
      ],
    );
  }

  Widget _wideContentPane(BuildContext context) {
    final meta = settingsSectionMeta(_selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppBreakpoints.settingsContentMax),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  _ContentHeader(meta: meta),
                  const SizedBox(height: 20),
                  _content(_selected),
                ],
              ),
            ),
          ),
        ),
        if (_dirty)
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppBreakpoints.settingsContentMax),
              child: _SaveBar(onSave: _save, onDiscard: _discard, inContent: true),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Narrow: list → pushed section page
  // -------------------------------------------------------------------------

  Widget _buildNarrow(BuildContext context) =>
      _inSection ? _narrowSectionPage(context) : _narrowListPage(context);

  Widget _narrowListPage(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final pad = pagePaddingForWidth(c.maxWidth);
        final short = c.maxHeight < AppBreakpoints.shortHeight;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 16),
                children: [
                  SectionHeading(
                    title: 'الإعدادات',
                    subtitle: short
                        ? null
                        : 'المظهر، اللغة، الفواتير، الصلاحيات والمزامنة',
                  ),
                  const SizedBox(height: 16),
                  for (final s in settingsSections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NavCard(
                        meta: s,
                        rtl: _rtl(context),
                        onTap: () => _openSection(s.id),
                      ),
                    ),
                ],
              ),
            ),
            if (_dirty)
              SafeArea(
                top: false,
                child: _SaveBar(onSave: _save, onDiscard: _discard),
              ),
          ],
        );
      },
    );
  }

  Widget _narrowSectionPage(BuildContext context) {
    final meta = settingsSectionMeta(_selected);
    return LayoutBuilder(
      builder: (context, c) {
        final pad = pagePaddingForWidth(c.maxWidth);
        final short = c.maxHeight < AppBreakpoints.shortHeight;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTopBar(
              meta: meta,
              rtl: _rtl(context),
              condensed: short,
              onBack: _backToList,
            ),
            Divider(height: 1, color: context.taj.divider),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 24),
                children: [_content(_selected)],
              ),
            ),
            if (_dirty)
              SafeArea(
                top: false,
                child: _SaveBar(onSave: _save, onDiscard: _discard),
              ),
          ],
        );
      },
    );
  }
}

// ===========================================================================
// Sub-navigation pieces
// ===========================================================================

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});
  final SettingsSectionId selected;
  final ValueChanged<SettingsSectionId> onSelect;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, bottom: 16),
          child: Text('الإعدادات', style: text.titleLarge),
        ),
        for (final s in settingsSections)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _SidebarItem(
              meta: s,
              selected: s.id == selected,
              onTap: () => onSelect(s.id),
            ),
          ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem(
      {required this.meta, required this.selected, required this.onTap});
  final SettingsSectionMeta meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final fg = selected ? taj.primary.dark : taj.textPrimary;
    return Material(
      color: selected ? taj.primary.lighter : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(meta.icon,
                  size: 20, color: selected ? taj.primary.dark : taj.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(meta.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.meta, required this.rtl, required this.onTap});
  final SettingsSectionMeta meta;
  final bool rtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return TajCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: taj.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: taj.divider)),
            child: Icon(meta.icon, size: 20, color: taj.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meta.title,
                    style:
                        text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(meta.subtitle,
                    style: text.bodySmall?.copyWith(color: taj.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: taj.textDisabled),
        ],
      ),
    );
  }
}

class _SectionTopBar extends StatelessWidget {
  const _SectionTopBar({
    required this.meta,
    required this.rtl,
    required this.condensed,
    required this.onBack,
  });
  final SettingsSectionMeta meta;
  final bool rtl;
  final bool condensed;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'رجوع',
            icon: Icon(rtl
                ? Icons.arrow_forward_rounded
                : Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meta.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium),
                if (!condensed)
                  Text(meta.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          text.bodySmall?.copyWith(color: taj.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  const _ContentHeader({required this.meta});
  final SettingsSectionMeta meta;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: taj.primary.lighter,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(meta.icon, size: 22, color: taj.primary.dark),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meta.title, style: text.headlineSmall),
              const SizedBox(height: 2),
              Text(meta.subtitle,
                  style: text.bodyMedium?.copyWith(color: taj.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Save bar
// ===========================================================================

/// The unsaved-changes bar. Pinned to the bottom of the content area (or the
/// screen on narrow widths). It is a sibling above the scroll view — never a
/// floating overlay — so it can never cover the last setting. On narrow widths
/// it lays out on two lines so the message and both actions always fit.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.onSave,
    required this.onDiscard,
    this.inContent = false,
  });
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final bool inContent;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;

    final message = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline_rounded, size: 18, color: taj.warning.dark),
        const SizedBox(width: 8),
        Flexible(
          child: Text('لديك تغييرات غير محفوظة',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );

    final discardBtn = OutlinedButton(
      onPressed: onDiscard,
      child: const Text('تجاهل'),
    );
    final saveBtn = FilledButton.icon(
      onPressed: onSave,
      icon: const Icon(Icons.check_rounded, size: 18),
      label: const Text('حفظ التغييرات'),
    );

    return Container(
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(top: BorderSide(color: taj.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (context, c) {
            final tight = c.maxWidth < 440;
            if (tight) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: AlignmentDirectional.centerStart, child: message),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: discardBtn),
                      const SizedBox(width: 10),
                      Expanded(child: saveBtn),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: message),
                const SizedBox(width: 12),
                discardBtn,
                const SizedBox(width: 10),
                saveBtn,
              ],
            );
          },
        ),
      ),
    );
  }
}
