import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taj_license_core/taj_license_core.dart';

import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme/taj_colors.dart';
import '../../data/database_provider.dart';
import '../../shared/widgets/taj_ui.dart';
import 'license_service.dart';

/// Fully offline activation gate shown before the app when no valid license
/// is stored for this device.
///
/// Layout mirrors [LoginScreen]: a branding panel beside the form at
/// ≥ [AppBreakpoints.authSplit], a single scrollable column below it.
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({
    super.key,
    required this.onActivated,
    this.onToggleTheme,
  });

  /// Called once the license is stored and the gate may be re-evaluated.
  final Future<void> Function() onActivated;

  final VoidCallback? onToggleTheme;

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  String? _fingerprint;
  bool _busy = false;
  bool _success = false;
  LicenseStatus? _errorStatus;
  LicensePayload? _errorPayload;
  String? _error;
  String? _importError;

  @override
  void initState() {
    super.initState();
    _resolveFingerprint();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _resolveFingerprint() async {
    try {
      final fp = await LicenseService.deviceFingerprint();
      if (!mounted) return;
      setState(() => _fingerprint = fp);
    } catch (_) {
      if (!mounted) return;
      setState(() => _fingerprint = '—');
    }
  }

  bool get _canActivate =>
      _nameController.text.trim().isNotEmpty &&
      _codeController.text.trim().isNotEmpty;

  Future<void> _copyFingerprint() async {
    final fp = _fingerprint;
    if (fp == null || fp == '—') return;
    try {
      await Clipboard.setData(ClipboardData(text: fp));
    } catch (_) {
      // Clipboard may be unavailable; the value stays on screen either way.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تم نسخ البصمة')));
  }

  Future<void> _importFile() async {
    try {
      const group = XTypeGroup(label: 'ترخيص تاج', extensions: ['tajlic']);
      final file = await openFile(acceptedTypeGroups: const [group]);
      if (file == null) return;
      final content = await file.readAsString();
      final code = TajlicFile.decodeCode(content);
      if (!mounted) return;
      setState(() {
        _codeController.text = code;
        _importError = null;
        _error = null;
        _errorStatus = null;
        _errorPayload = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _importError = 'ملف الترخيص غير صالح');
    }
  }

  Future<void> _submit() async {
    if (_busy || _success) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _errorStatus = null;
      _errorPayload = null;
      _importError = null;
    });

    try {
      final db = DatabaseProvider.of(context);
      await LicenseService.activate(
        db: db,
        code: _codeController.text,
        customerName: _nameController.text,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _success = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await widget.onActivated();
    } on LicenseActivationException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorStatus = e.status;
        _errorPayload = e.payload;
        _error = _messageFor(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'تعذّر إتمام التفعيل — تأكد من الكود وحاول مرة أخرى.';
      });
    }
  }

  /// Exact, Arabic, non-technical mapping — raw exceptions are never shown.
  static String _messageFor(LicenseActivationException e) {
    switch (e.status) {
      case LicenseStatus.malformed:
        return 'كود الترخيص غير صالح — تأكد من نسخه كاملاً';
      case LicenseStatus.unsupportedVersion:
        return 'إصدار كود الترخيص غير مدعوم في هذه النسخة من تاج';
      case LicenseStatus.badSignature:
        return 'كود الترخيص تالِف أو تم العبث به';
      case LicenseStatus.fingerprintMismatch:
        return 'هذا الترخيص مرتبط بجهاز آخر — '
            'البصمة المطلوبة: ${e.payload?.fingerprint ?? '—'}';
      case LicenseStatus.expired:
        final exp = e.payload?.expiresAtDate.toLocal();
        return exp == null
            ? 'انتهى الترخيص'
            : 'انتهى الترخيص في ${arDate(exp)}';
      case LicenseStatus.notYetValid:
        return 'تاريخ صدور الترخيص في المستقبل';
      case LicenseStatus.valid:
        return 'تعذّر إتمام التفعيل — تأكد من الكود وحاول مرة أخرى.';
    }
  }

  String? _validateName(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'هذا الحقل مطلوب';
    if (value.length < 2) return 'اسم الزبون قصير جداً';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: taj.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.authSplit;
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _BrandPanel(
                    taj: taj,
                    isDark: isDark,
                    onToggleTheme: widget.onToggleTheme,
                    compact: false,
                  ),
                ),
                Expanded(flex: 4, child: _formPane()),
              ],
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                    onPressed: widget.onToggleTheme,
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                ),
                _BrandPanel(
                  taj: taj,
                  isDark: isDark,
                  onToggleTheme: null,
                  compact: true,
                ),
                const SizedBox(height: 20),
                _formFields(taj),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _formPane() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _formFields(context.taj),
          ),
        ),
      ),
    );
  }

  // ── Form (shared by both layouts) ────────────────────────────────────────

  Widget _formFields(TajColors taj) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _fingerprintCard(taj),
          const SizedBox(height: 16),

          // ── Customer name ──
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 15),
            onChanged: (_) => setState(() {}),
            validator: _validateName,
            decoration: InputDecoration(
              labelText: 'اسم الزبون',
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: taj.background,
            ),
          ),
          const SizedBox(height: 16),

          // ── License code ──
          TextFormField(
            controller: _codeController,
            minLines: 3,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              letterSpacing: 0.4,
              color: taj.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'كود الترخيص',
              hintText: 'TAJ1.…',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: taj.background,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الصق الكود كاملاً — يبدأ بـ TAJ1 — '
            '${normalizeLicenseCode(_codeController.text).length} حرف',
            style: text.bodySmall?.copyWith(color: taj.textSecondary),
          ),
          const SizedBox(height: 12),

          // ── Import .tajlic ──
          OutlinedButton.icon(
            onPressed: _busy || _success ? null : _importFile,
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('استيراد ملف ترخيص (.tajlic)'),
          ),
          if (_importError != null) ...[
            const SizedBox(height: 8),
            Text(
              _importError!,
              style: text.bodySmall?.copyWith(
                color: taj.error.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 16),
            _errorBox(taj),
          ],
          const SizedBox(height: 20),

          if (_success)
            _successBox(taj)
          else
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed:
                    _busy || !_canActivate ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: taj.primary.main,
                  foregroundColor: taj.primary.contrastText,
                  disabledBackgroundColor:
                      taj.primary.main.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _busy
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: taj.primary.contrastText,
                        ),
                      )
                    : Text(
                        'تفعيل النظام أوفلاين',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: taj.primary.contrastText,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Device fingerprint card ──────────────────────────────────────────────

  Widget _fingerprintCard(TajColors taj) {
    final text = Theme.of(context).textTheme;
    return TajCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: taj.primary.lighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.fingerprint_rounded,
                    size: 19, color: taj.primary.dark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('بصمة الجهاز',
                        style: text.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      'أرسل هذا الرمز إلى البائع لإصدار الترخيص',
                      style: text.bodySmall
                          ?.copyWith(color: taj.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
            decoration: BoxDecoration(
              color: taj.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: taj.divider),
            ),
            child: _fingerprint == null
                ? Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'جارٍ تحديد بصمة الجهاز…',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall
                              ?.copyWith(color: taj.textSecondary),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          _fingerprint!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'نسخ البصمة',
                        onPressed: _copyFingerprint,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                            minWidth: 40, minHeight: 40),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Error / success ──────────────────────────────────────────────────────

  Widget _errorBox(TajColors taj) {
    final text = Theme.of(context).textTheme;
    final payload = _errorPayload;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: taj.error.lighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taj.error.light),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 18, color: taj.error.dark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: text.bodyMedium?.copyWith(
                    color: taj.error.dark,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (_errorStatus == LicenseStatus.fingerprintMismatch &&
              payload != null) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final required = _FingerprintBlock(
                  label: 'بصمة الترخيص',
                  value: payload.fingerprint,
                  taj: taj,
                );
                final current = _FingerprintBlock(
                  label: 'بصمة هذا الجهاز',
                  value: _fingerprint ?? '—',
                  taj: taj,
                );
                if (c.maxWidth >= 420) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: required),
                      const SizedBox(width: 12),
                      Expanded(child: current),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    required,
                    const SizedBox(height: 10),
                    current,
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _successBox(TajColors taj) {
    final text = Theme.of(context).textTheme;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: taj.success.lighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taj.success.light),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: 20, color: taj.success.dark),
          const SizedBox(width: 10),
          Text(
            'تم التفعيل بنجاح',
            style: text.titleSmall?.copyWith(
              color: taj.success.dark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FingerprintBlock extends StatelessWidget {
  const _FingerprintBlock({
    required this.label,
    required this.value,
    required this.taj,
  });

  final String label;
  final String value;
  final TajColors taj;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: text.bodySmall?.copyWith(
                color: taj.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ── Branding panel ─────────────────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({
    required this.taj,
    required this.isDark,
    required this.onToggleTheme,
    required this.compact,
  });

  final TajColors taj;
  final bool isDark;
  final VoidCallback? onToggleTheme;

  /// `true` on narrow layouts: a light header above the form instead of the
  /// full-height gradient panel.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: taj.primary.main,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              'ت',
              style: TextStyle(
                color: taj.primary.contrastText,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تفعيل نظام تاج',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'التفعيل يتم بالكامل على هذا الجهاز دون إنترنت — '
            'الصق كود الترخيص الصادر عن البائع ليُتحقّق منه محلياً.',
            style: text.bodyMedium?.copyWith(
                color: taj.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 14),
          const _OfflineBadge(),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [taj.primary.dark, taj.primary.main],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(44),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'ت',
                      style: TextStyle(
                        color: taj.primary.dark,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'تفعيل نظام تاج',
                    style: text.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'التفعيل أوفلاين بالكامل: يُتحقّق النظام من كود الترخيص '
                    'وبصمة الجهاز محلياً، دون أي اتصال بالإنترنت.',
                    style: text.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  const _OfflineBadge(onDark: true),
                ],
              ),
            ),
          ),
          if (onToggleTheme != null)
            PositionedDirectional(
              top: 16,
              end: 16,
              child: SafeArea(
                child: IconButton(
                  tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                  onPressed: onToggleTheme,
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Offline marker — Material icon only (no emoji / network artwork).
class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.16)
            : taj.info.lighter,
        borderRadius: BorderRadius.circular(20),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 15,
            color: onDark ? Colors.white : taj.info.dark,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'تفعيل أوفلاين — دون إنترنت',
              maxLines: 2,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: onDark ? Colors.white : taj.info.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
