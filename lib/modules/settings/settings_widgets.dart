import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../core/theme/taj_colors.dart';
import '../../shared/widgets/taj_ui.dart';

/// A titled card grouping several [SettingRow]s, matching the app's card look.
/// The section content is a stack of these.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    required this.children,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return TajCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: taj.accentText),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleSmall),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: text.bodySmall
                                ?.copyWith(color: taj.textSecondary, height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: taj.divider),
            children[i],
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// **The setting row — the single most dangerous element in this module.**
///
/// A naïve `Row(label + long description + control)` overflows every time in
/// Arabic. The rule enforced here:
///  * the label + (freely wrapping, never clamped) description live in an
///    [Expanded], so they take the remaining width and wrap instead of pushing
///    the control off-screen;
///  * a narrow control (a [Switch]) always sits at the row's end;
///  * a *wide* control (dropdown / field — [controlIsWide]) sits at the end only
///    while the row is at least [AppBreakpoints.settingsRowStackControl] wide;
///    below that it drops to a full-width line beneath the text.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.control,
    this.controlIsWide = false,
    this.minControlWidth = 150,
    this.maxControlWidth = 320,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget control;

  /// Whether [control] is a wide control (dropdown / text field) that should
  /// drop below the text on narrow rows. Switches leave this false.
  final bool controlIsWide;
  final double minControlWidth;
  final double maxControlWidth;

  /// Dims the row's text when a parent toggle disables it (the control decides
  /// its own disabled state).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final titleColor = enabled ? taj.textPrimary : taj.textDisabled;

    final titleCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style:
                text.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: titleColor)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          // Helper text wraps freely — never clamped to one line, so its meaning
          // is never lost.
          Text(subtitle!,
              style: text.bodySmall?.copyWith(color: taj.textSecondary, height: 1.45)),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, c) {
          final stack =
              controlIsWide && c.maxWidth < AppBreakpoints.settingsRowStackControl;
          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleCol,
                const SizedBox(height: 12),
                control,
              ],
            );
          }
          return Row(
            crossAxisAlignment: controlIsWide
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.center,
            children: [
              Expanded(child: titleCol),
              const SizedBox(width: 16),
              if (controlIsWide)
                ConstrainedBox(
                  constraints: BoxConstraints(
                      minWidth: minControlWidth, maxWidth: maxControlWidth),
                  child: control,
                )
              else
                control,
            ],
          );
        },
      ),
    );
  }
}

/// A labelled block for a control that is inherently full width (a segmented
/// control, a swatch grid, a preview, a chips field): the label + freely
/// wrapping description sit above, the [child] fills the width beneath.
class SettingsBlock extends StatelessWidget {
  const SettingsBlock({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: enabled ? taj.textPrimary : taj.textDisabled)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style:
                    text.bodySmall?.copyWith(color: taj.textSecondary, height: 1.45)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Lays two logically-related fields side by side when the group is at least
/// [breakpoint] wide, and stacks them (full width) below it.
class SettingsFieldPair extends StatelessWidget {
  const SettingsFieldPair({
    super.key,
    required this.first,
    required this.second,
    this.breakpoint = AppBreakpoints.settingsFieldPairTwoCol,
    this.gap = 16,
  });

  final Widget first;
  final Widget second;
  final double breakpoint;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              SizedBox(width: gap),
              Expanded(child: second),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, SizedBox(height: gap), second],
        );
      },
    );
  }
}

/// A field-styled single-select built on [PopupMenuButton] so its menu is always
/// kept within the window by the framework (it can never escape a screen edge),
/// with a ≥44px tap target.
class SettingsSelectField<T> extends StatelessWidget {
  const SettingsSelectField({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.iconOf,
    this.enabled = true,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final IconData Function(T)? iconOf;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final fg = enabled ? taj.textPrimary : taj.textDisabled;
    return PopupMenuButton<T>(
      enabled: enabled && onChanged != null,
      initialValue: value,
      tooltip: '',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 360),
      onSelected: (v) => onChanged?.call(v),
      itemBuilder: (context) => [
        for (final it in items)
          PopupMenuItem<T>(
            value: it,
            child: Row(
              children: [
                if (iconOf != null) ...[
                  Icon(iconOf!(it), size: 18, color: taj.textSecondary),
                  const SizedBox(width: 10),
                ],
                Expanded(child: Text(labelOf(it), overflow: TextOverflow.ellipsis)),
                if (it == value)
                  Icon(Icons.check_rounded, size: 18, color: taj.primary.main),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
        decoration: BoxDecoration(
          color: enabled ? taj.background : taj.hover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: taj.divider),
        ),
        child: Row(
          children: [
            if (iconOf != null) ...[
              Icon(iconOf!(value), size: 18, color: taj.textSecondary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(labelOf(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(color: fg)),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: taj.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// A wrapping segmented control — a [Wrap] of selectable pills that reflows
/// instead of overflowing. Each pill honours the ≥44px tap target.
class SettingsSegmented<T> extends StatelessWidget {
  const SettingsSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.iconOf,
    this.enabled = true,
  });

  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final IconData Function(T)? iconOf;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          _SegPill(
            label: labelOf(o),
            icon: iconOf?.call(o),
            selected: o == value,
            enabled: enabled && onChanged != null,
            onTap: () => onChanged?.call(o),
            taj: taj,
          ),
      ],
    );
  }
}

class _SegPill extends StatelessWidget {
  const _SegPill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.taj,
    this.icon,
  });
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final TajColors taj;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = !enabled
        ? taj.textDisabled
        : selected
            ? taj.primary.dark
            : taj.textSecondary;
    return Material(
      color: selected ? taj.primary.lighter : taj.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? taj.primary.main : taj.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labelled, keyboard-aware text field. On focus it scrolls itself into view
/// above the keyboard (`Scrollable.ensureVisible`), so a field near the bottom
/// of a long section is never hidden behind the on-screen keyboard.
class SettingsTextField extends StatefulWidget {
  const SettingsTextField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  State<SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      // Defer so the keyboard inset is applied before we scroll.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          alignment: 0.1,
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void didUpdateWidget(SettingsTextField old) {
    super.didUpdateWidget(old);
    // Keep the field in sync when the draft is reset (Discard) from outside.
    if (widget.initialValue != old.initialValue &&
        widget.initialValue != _controller.text &&
        !_focus.hasFocus) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final taj = context.taj;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: text.labelMedium?.copyWith(color: taj.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(hintText: widget.hint),
        ),
      ],
    );
  }
}

/// A field-styled date picker button (tap → screen-bounded [showDatePicker]).
class SettingsDateField extends StatelessWidget {
  const SettingsDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  static String _fmt(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelMedium?.copyWith(color: taj.textSecondary)),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: enabled
                ? () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: value ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 3),
                    );
                    if (picked != null) onChanged(picked);
                  }
                : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsetsDirectional.only(start: 14, end: 12),
              decoration: BoxDecoration(
                color: enabled ? taj.background : taj.hover,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: taj.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value == null ? 'اختر التاريخ' : _fmt(value!),
                      style: text.bodyMedium?.copyWith(
                          color: value == null || !enabled
                              ? taj.textDisabled
                              : taj.textPrimary),
                    ),
                  ),
                  Icon(Icons.calendar_today_rounded,
                      size: 17, color: taj.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A field showing the selected values as chips in a [Wrap] (with a `+N` chip
/// when there are more than [displayCap]) plus an "add / edit" affordance that
/// opens a screen-appropriate multi-select picker. The [Wrap] reflows, so the
/// chips can never overflow their row.
class SettingsChipsField extends StatelessWidget {
  const SettingsChipsField({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
    required this.pickerTitle,
    this.emptyLabel = 'لا يوجد تحديد',
    this.enabled = true,
    this.displayCap = 6,
  });

  final Set<String> selected;
  final List<String> options;
  final ValueChanged<Set<String>> onChanged;
  final String pickerTitle;
  final String emptyLabel;
  final bool enabled;
  final int displayCap;

  Future<void> _openPicker(BuildContext context) async {
    final result = await pickMultiSelect(
      context,
      title: pickerTitle,
      options: options,
      selected: selected,
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    final shown = selected.take(displayCap).toList();
    final overflow = selected.length - shown.length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (selected.isEmpty)
          Text(emptyLabel,
              style: text.bodySmall?.copyWith(color: taj.textDisabled)),
        for (final s in shown)
          Chip(
            label: Text(s),
            backgroundColor: taj.primary.lighter,
            side: BorderSide(color: taj.primary.light),
            labelStyle: TextStyle(
                color: taj.primary.dark, fontSize: 13, fontWeight: FontWeight.w600),
            onDeleted: enabled ? () => onChanged({...selected}..remove(s)) : null,
            deleteIconColor: taj.primary.dark,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        if (overflow > 0)
          ActionChip(
            label: Text('+$overflow'),
            onPressed: enabled ? () => _openPicker(context) : null,
          ),
        ActionChip(
          avatar: Icon(Icons.add_rounded, size: 18, color: taj.accentText),
          label: const Text('تعديل التحديد'),
          onPressed: enabled ? () => _openPicker(context) : null,
        ),
      ],
    );
  }
}

/// Opens a multi-select picker for [options] and returns the new selection, or
/// null if cancelled. Below [AppBreakpoints.settingsMultiSelectSheet] it is a
/// full-width modal bottom sheet; at or above it, a centred dialog. Both share
/// one scrollable checkbox body with a bounded height, so neither can escape the
/// window or force a fixed height.
Future<Set<String>?> pickMultiSelect(
  BuildContext context, {
  required String title,
  required List<String> options,
  required Set<String> selected,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < AppBreakpoints.settingsMultiSelectSheet) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.8,
        child: _MultiSelectBody(
            title: title, options: options, initial: selected),
      ),
    );
  }
  return showDialog<Set<String>>(
    context: context,
    builder: (ctx) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
        ),
        child: _MultiSelectBody(
            title: title, options: options, initial: selected),
      ),
    ),
  );
}

class _MultiSelectBody extends StatefulWidget {
  const _MultiSelectBody(
      {required this.title, required this.options, required this.initial});
  final String title;
  final List<String> options;
  final Set<String> initial;

  @override
  State<_MultiSelectBody> createState() => _MultiSelectBodyState();
}

class _MultiSelectBodyState extends State<_MultiSelectBody> {
  late final Set<String> _sel = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
          child: Row(
            children: [
              Expanded(child: Text(widget.title, style: text.titleMedium)),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'إغلاق',
              ),
            ],
          ),
        ),
        Divider(height: 1, color: taj.divider),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              for (final o in widget.options)
                CheckboxListTile(
                  value: _sel.contains(o),
                  onChanged: (v) => setState(() {
                    if (v ?? false) {
                      _sel.add(o);
                    } else {
                      _sel.remove(o);
                    }
                  }),
                  title: Text(o),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: false,
                ),
            ],
          ),
        ),
        Divider(height: 1, color: taj.divider),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_sel),
                    child: Text('تم (${_sel.length})'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A small integer stepper (− value +) with a ≥44px target, for print copies /
/// grace minutes.
class SettingsStepper extends StatelessWidget {
  const SettingsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.suffix,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String? suffix;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final text = Theme.of(context).textTheme;
    Widget btn(IconData icon, VoidCallback? onTap) => IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        );
    return Container(
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: taj.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove_rounded,
              enabled && value > min ? () => onChanged(value - step) : null),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: Text(
              suffix == null ? '$value' : '$value $suffix',
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          btn(Icons.add_rounded,
              enabled && value < max ? () => onChanged(value + step) : null),
        ],
      ),
    );
  }
}
