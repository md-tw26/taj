import 'package:flutter/material.dart';

import '../../core/theme/taj_colors.dart';
import '../../core/responsive.dart';
import '../../core/user_role.dart';

/// Responsive login screen — username + password only.
/// Branch and role are determined automatically from the user's account.
/// Desktop: split layout (branding | form).
/// Mobile: centered card.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSignedIn,
    this.onToggleTheme,
  });

  final void Function(UserRole role, String userName) onSignedIn;
  final VoidCallback? onToggleTheme;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Determines role from username.
  UserRole _determineRole(String username) {
    final lower = username.toLowerCase().trim();
    if (lower == 'admin') return UserRole.admin;
    if (lower == 'cashier') return UserRole.cashier;
    return UserRole.merchant;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final role = _determineRole(_usernameController.text);
    widget.onSignedIn(role, _usernameController.text.trim());
  }

  /// Password-recovery flow: collect the account identifier and confirm a reset
  /// link was sent. The confirmation is deliberately account-agnostic ("if the
  /// account exists") so the screen never reveals whether a username is valid.
  Future<void> _showForgotPassword() async {
    final controller =
        TextEditingController(text: _usernameController.text.trim());
    final formKey = GlobalKey<FormState>();

    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final taj = ctx.taj;
        void submit() {
          if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
        }

        return AlertDialog(
          title: const Text('استعادة كلمة المرور'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أدخل اسم المستخدم أو البريد الإلكتروني، وسنرسل لك رابط إعادة '
                  'تعيين كلمة المرور.',
                  style: TextStyle(
                      fontSize: 13, color: taj.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => submit(),
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم أو البريد الإلكتروني',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: submit,
              child: const Text('إرسال الرابط'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'إن كان الحساب موجودًا، فقد أُرسل رابط استعادة كلمة المرور.'),
        ),
      );
    }
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
          return Stack(
            children: [
              if (isWide)
                _DesktopLayout(
                  taj: taj,
                  isDark: isDark,
                  onToggleTheme: widget.onToggleTheme,
                  child: _buildFormSection(taj),
                )
              else
                _MobileLayout(
                  taj: taj,
                  isDark: isDark,
                  onToggleTheme: widget.onToggleTheme,
                  child: _buildFormSection(taj),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormSection(TajColors taj) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              _buildHeader(taj),
              const SizedBox(height: 36),

              // ── Username ──
              _buildUsernameField(taj),
              const SizedBox(height: 16),

              // ── Password ──
              _buildPasswordField(taj),
              const SizedBox(height: 4),

              // ── Forgot password ──
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _loading ? null : _showForgotPassword,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: taj.primary.dark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Submit ──
              _buildSubmitButton(taj),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(TajColors taj) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: taj.primary.main,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            'ت',
            style: TextStyle(
              color: taj.primary.contrastText,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'تسجيل الدخول',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'أدخل اسم المستخدم وكلمة المرور للوصول',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: taj.textSecondary,
              ),
        ),
      ],
    );
  }

  // ── Username ────────────────────────────────────────────────────────────

  Widget _buildUsernameField(TajColors taj) {
    return TextFormField(
      controller: _usernameController,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: 'اسم المستخدم',
        prefixIcon: const Icon(Icons.person_outline_rounded, size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: taj.background,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
        return null;
      },
    );
  }

  // ── Password ────────────────────────────────────────────────────────────

  Widget _buildPasswordField(TajColors taj) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      style: const TextStyle(fontSize: 15),
      onFieldSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: 'كلمة المرور',
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 22),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 22,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: taj.background,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'هذا الحقل مطلوب';
        if (v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
        return null;
      },
    );
  }

  // ── Submit ──────────────────────────────────────────────────────────────

  Widget _buildSubmitButton(TajColors taj) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: _loading ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: taj.primary.main,
          foregroundColor: taj.primary.contrastText,
          disabledBackgroundColor: taj.primary.main.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: taj.primary.contrastText,
                ),
              )
            : Text(
                'دخول',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: taj.primary.contrastText,
                ),
              ),
      ),
    );
  }
}

// ── Desktop Layout ──────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.taj,
    required this.isDark,
    required this.onToggleTheme,
    required this.child,
  });

  final TajColors taj;
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: Branding panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  taj.primary.dark,
                  taj.primary.main,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Decorative circles
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
                // Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
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
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'تاج',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'نظام إدارة المبيعات والمخزون',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // Theme toggle
                Positioned(
                  top: 16,
                  left: 16,
                  child: SafeArea(
                    child: IconButton(
                      tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                      onPressed: onToggleTheme,
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: Form panel
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mobile Layout ───────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.taj,
    required this.isDark,
    required this.onToggleTheme,
    required this.child,
  });

  final TajColors taj;
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Theme toggle
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                onPressed: onToggleTheme,
                icon: Icon(
                  isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
              ),
            ),
          ),

          // Form
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

