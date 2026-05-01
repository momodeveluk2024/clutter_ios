import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    try {
      await context.read<AuthProvider>().login(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) context.go('/app');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final auth = context.watch<AuthProvider>();
    final media = MediaQuery.of(context);
    final heroH = media.size.height * 0.30;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: c.bg,
        body: FadeTransition(
          opacity: _entryAnim,
          child: Form(
            key: _formKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Full screen background image ──
                Image.asset(
                  'assets/branding/auth_hero.png',
                  fit: BoxFit.cover,
                  cacheWidth: 600,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
                // Soft gradient overlay
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                ),
                // ── Scrollable Form ──
                Positioned.fill(
                  child: ListView(
                    padding: EdgeInsets.only(top: heroH),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: c.bg.withValues(alpha: 0.70), // Transparent glass effect
                            ),
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Headline ──
                            Text(
                              'Welcome',
                              style: GoogleFonts.inter(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.9,
                                height: 1.1,
                                color: c.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.9,
                                  height: 1.1,
                                  color: c.text,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'back',
                                    style: GoogleFonts.instrumentSerif(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 34,
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                      color: NV.accent,
                                    ),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to keep tracking your nutrition and daily targets.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: c.textMuted,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Fields ──
                            _AuthField(
                              controller: _email,
                              label: 'Email address',
                              hint: 'you@example.com',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) return 'Email is required';
                                if (!t.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _AuthField(
                              controller: _password,
                              label: 'Password',
                              hint: 'Enter your password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _hidePassword,
                              suffix: _FieldToggle(
                                hidden: _hidePassword,
                                onTap: () => setState(
                                    () => _hidePassword = !_hidePassword),
                              ),
                              validator: (v) {
                                if ((v ?? '').isEmpty) return 'Password is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => context.go('/forgot-password'),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: NV.accent,
                                  textStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── CTA ──
                            _PrimaryGradientButton(
                              label:
                                  auth.isLoading ? 'Signing in…' : 'Sign in',
                              loading: auth.isLoading,
                              onPressed: auth.isLoading ? null : _submit,
                            ),
                            const SizedBox(height: 24),

                            // ── Divider ──
                            _OrDivider(),
                            const SizedBox(height: 20),

                            // ── Social login ──
                            Row(
                              children: const [
                                Expanded(
                                  child: _SocialButton(
                                    provider: 'apple',
                                    label: 'Apple',
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _SocialButton(
                                    provider: 'google',
                                    label: 'Google',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // ── Sign up link ──
                            Center(
                              child: GestureDetector(
                                onTap: () => context.go('/sign-up'),
                                behavior: HitTestBehavior.opaque,
                                child: Text.rich(
                                  TextSpan(
                                    text: 'New to Nutrimate?  ',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: c.textMuted,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Create an account',
                                        style: GoogleFonts.inter(
                                          color: NV.accent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: media.padding.bottom + 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                  ),
                ),

                // ── Top Brand Bar ──
                Positioned(
                  top: media.padding.top + 14,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      _GlassCircleButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => context.go('/'),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            padding: const EdgeInsets.all(3),
                            child: Image.asset(
                              'assets/branding/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nutrimate',
                            style: GoogleFonts.fraunces(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Form ──
                Positioned.fill(
                  child: ListView(
                    padding: EdgeInsets.only(top: heroH),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: c.bg.withValues(alpha: 0.90), // Transparent glass effect
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Headline ──
                        Text(
                          'Welcome',
                          style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.9,
                            height: 1.1,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.9,
                              height: 1.1,
                              color: c.text,
                            ),
                            children: [
                              TextSpan(
                                text: 'back',
                                style: GoogleFonts.instrumentSerif(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 34,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                  color: NV.accent,
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to keep tracking your nutrition and daily targets.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: c.textMuted,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Fields ──
                        _AuthField(
                          controller: _email,
                          label: 'Email address',
                          hint: 'you@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return 'Email is required';
                            if (!t.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _AuthField(
                          controller: _password,
                          label: 'Password',
                          hint: 'Enter your password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _hidePassword,
                          suffix: _FieldToggle(
                            hidden: _hidePassword,
                            onTap: () => setState(
                                () => _hidePassword = !_hidePassword),
                          ),
                          validator: (v) {
                            if ((v ?? '').isEmpty) return 'Password is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => context.go('/forgot-password'),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: const Size(0, 32),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: NV.accent,
                              textStyle: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── CTA ──
                        _PrimaryGradientButton(
                          label:
                              auth.isLoading ? 'Signing in…' : 'Sign in',
                          loading: auth.isLoading,
                          onPressed: auth.isLoading ? null : _submit,
                        ),
                        const SizedBox(height: 24),

                        // ── Divider ──
                        _OrDivider(),
                        const SizedBox(height: 20),

                        // ── Social login ──
                        Row(
                          children: const [
                            Expanded(
                              child: _SocialButton(
                                provider: 'apple',
                                label: 'Apple',
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _SocialButton(
                                provider: 'google',
                                label: 'Google',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Sign up link ──
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/sign-up'),
                            behavior: HitTestBehavior.opaque,
                            child: Text.rich(
                              TextSpan(
                                text: 'New to Nutrimate?  ',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: c.textMuted,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Create an account',
                                    style: GoogleFonts.inter(
                                      color: NV.accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: media.padding.bottom + 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}


// ═══════════════════════════════════════════════════════════════
//  GLASS CIRCLE BUTTON
// ═══════════════════════════════════════════════════════════════

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  AUTH INPUT FIELD
// ═══════════════════════════════════════════════════════════════

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = dark ? c.surfaceMuted : const Color(0xFFF8F9FA);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.text,
              letterSpacing: 0.05,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: c.text,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: c.textMuted.withValues(alpha: 0.50),
              fontWeight: FontWeight.w400,
              fontSize: 14.5,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 10),
              child: Icon(icon, size: 19, color: c.textMuted),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffix,
            filled: true,
            fillColor: fieldBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: dark ? c.border : const Color(0xFFE8EAED),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: NV.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: NV.err),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: NV.err, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldToggle extends StatelessWidget {
  const _FieldToggle({required this.hidden, required this.onTap});
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 19,
          color: c.textMuted,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PRIMARY GRADIENT BUTTON
// ═══════════════════════════════════════════════════════════════

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    required this.label,
    this.loading = false,
    this.onPressed,
  });
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [NV.accent, Color(0xFF3A9A5C)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: NV.accent.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  OR DIVIDER
// ═══════════════════════════════════════════════════════════════

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: c.textMuted,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: c.border)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SOCIAL BUTTON
// ═══════════════════════════════════════════════════════════════

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.provider, required this.label});
  final String provider;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final icon =
        provider == 'apple' ? Icons.apple : Icons.g_mobiledata_rounded;
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: c.surface,
          side: BorderSide(color: c.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: c.text,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: provider == 'google' ? 26 : 22, color: c.text),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
