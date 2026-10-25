

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final provider = context.read<AuthProvider>();
    final ok = await provider.login(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!mounted) return;

    if (ok) {
      context.go(RouteNames.home);
      return;
    }

    final message = provider.error ?? 'Login failed';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Same background recipe as Register
    final bgTop = isDark
        ? Color.lerp(scheme.surface, scheme.primary, 0.10)!
        : Color.lerp(scheme.surface, scheme.primary, 0.06)!;
    final bgBottom = scheme.surface;

    final cardColor = isDark
        ? Color.lerp(scheme.surface, Colors.white, 0.04)!
        : Colors.white;

    final fieldFill = isDark
        ? Color.lerp(cardColor, Colors.white, 0.06)!
        : Color.lerp(cardColor, scheme.primary, 0.04)!;

    final fieldBorder = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : scheme.primary.withValues(alpha: 0.22);
    final fieldBorderFocus = scheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Brand mark ─────────────────────
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha:isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 44,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to manage your inventory',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.60),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Form card ──────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:
                              isDark ? 0.30 : 0.06,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Email ──────────────────
                            TextFormField(
                              controller: _emailCtrl,
                              enabled: !isLoading,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              onFieldSubmitted: (_) =>
                                  _passwordFocus.requestFocus(),
                              style: TextStyle(
                                fontSize: 15,
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _fieldDecoration(
                                label: 'Email',
                                hint: 'you@example.com',
                                prefixIcon: Icons.email_outlined,
                                fill: fieldFill,
                                border: fieldBorder,
                                focusBorder: fieldBorderFocus,
                                scheme: scheme,
                              ),
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 14),

                            // ── Password ───────────────
                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              enabled: !isLoading,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              style: TextStyle(
                                fontSize: 15,
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration:
                                  _fieldDecoration(
                                    label: 'Password',
                                    hint: '••••••••',
                                    prefixIcon: Icons.lock_outline,
                                    fill: fieldFill,
                                    border: fieldBorder,
                                    focusBorder: fieldBorderFocus,
                                    scheme: scheme,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _obscure
                                          ? 'Show password'
                                          : 'Hide password',
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.55,
                                        ),
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 20),

                            // ── Login button ───────────
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.primary,
                                  foregroundColor: scheme.onPrimary,
                                  disabledBackgroundColor: scheme.primary
                                      .withValues(alpha: 0.55),
                                  disabledForegroundColor: scheme.onPrimary
                                      .withValues(alpha: 0.9),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                child: isLoading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: scheme.onPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Signing in...',
                                            style: TextStyle(
                                              color: scheme.onPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text('Sign In'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Register link ──────────────────
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text(
                    //       "Don't have an account?",
                    //       style: theme.textTheme.bodySmall?.copyWith(
                    //         color: scheme.onSurface.withValues(alpha: 0.65),
                    //       ),
                    //     ),
                    //     TextButton(
                    //       onPressed: isLoading
                    //           ? null
                    //           : () => context.go(RouteNames.register),
                    //       style: TextButton.styleFrom(
                    //         padding: const EdgeInsets.symmetric(horizontal: 8),
                    //         minimumSize: Size.zero,
                    //         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //       ),
                    //       child: Text(
                    //         'Register',
                    //         style: TextStyle(
                    //           color: scheme.primary,
                    //           fontWeight: FontWeight.w700,
                    //           fontSize: 13,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Field decoration — floating label on border (same as Register)
  // ────────────────────────────────────────────────────────────
  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    required Color fill,
    required Color border,
    required Color focusBorder,
    required ColorScheme scheme,
  }) {
    OutlineInputBorder makeBorder(Color color, {double width = 1.2}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: scheme.onSurface.withValues(alpha: 0.55),
    );
    final floatingLabelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.primary,
      letterSpacing: 0.3,
    );

    return InputDecoration(
      labelText: label,
      labelStyle: labelStyle,
      floatingLabelStyle: floatingLabelStyle,
      floatingLabelBehavior: FloatingLabelBehavior.auto,

      hintText: hint,
      hintStyle: TextStyle(
        color: scheme.onSurface.withValues(alpha: 0.35),
        fontSize: 14,
      ),

      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 4, right: 4),
        child: Icon(
          prefixIcon,
          size: 19,
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),

      filled: true,
      fillColor: fill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

      border: makeBorder(border),
      enabledBorder: makeBorder(border),
      focusedBorder: makeBorder(focusBorder, width: 1.8),
      errorBorder: makeBorder(AppColors.danger),
      focusedErrorBorder: makeBorder(AppColors.danger, width: 1.8),
      errorStyle: const TextStyle(
        color: AppColors.danger,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }
}
