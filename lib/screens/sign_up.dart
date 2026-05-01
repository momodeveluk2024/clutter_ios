import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../theme.dart';

// ═══════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _hidePassword = true;

  late final AnimationController _anim;
  late final Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryAnim = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOutCubic,
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    try {
      await context.read<AuthProvider>().signup(
        displayName: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome. Let us tailor things to you.')),
      );
      context.go('/profile-setup');
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
    final heroH = media.size.height * 0.24;
    final hasPassword = _password.text.isNotEmpty;

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
                              'Create your',
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
                                    text: 'account',
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
                              'Join Nutrimate and get personalized daily targets based on your body and goals.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: c.textMuted,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Fields ──
                            _AuthField(
                              controller: _name,
                              label: 'Full name',
                              hint: 'Jane Doe',
                              icon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) {
                                if ((v?.trim() ?? '').isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
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
                              hint: 'Create a password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _hidePassword,
                              suffix: _FieldToggle(
                                hidden: _hidePassword,
                                onTap: () => setState(
                                    () => _hidePassword = !_hidePassword),
                              ),
                              validator: (v) {
                                final t = v ?? '';
                                if (t.isEmpty) return 'Password is required';
                                if (t.length < 8) {
                                  return 'Must be at least 8 characters';
                                }
                                return null;
                              },
                            ),

                            // Password strength
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: hasPassword
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                          top: 12, left: 4, right: 4),
                                      child: _PasswordStrength(
                                          password: _password.text),
                                    )
                                  : const SizedBox(width: double.infinity),
                            ),
                            const SizedBox(height: 28),

                            // ── CTA ──
                            _PrimaryGradientButton(
                              label: auth.isLoading
                                  ? 'Creating account…'
                                  : 'Sign up',
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

                            // ── Sign in link ──
                            Center(
                              child: GestureDetector(
                                onTap: () => context.go('/sign-in'),
                                behavior: HitTestBehavior.opaque,
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Already have an account?  ',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: c.textMuted,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign in',
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
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'By signing up, you agree to our\nTerms of Service and Privacy Policy.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: c.textMuted,
                                  height: 1.55,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED WIDGETS
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

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: c.text,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: c.textMuted.withValues(alpha: 0.6)),
            filled: true,
            fillColor: c.surface,
            prefixIcon: Icon(icon, size: 20, color: c.textMuted),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: NV.accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
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
    return IconButton(
      icon: Icon(
        hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: NVColors.of(context).textMuted,
      ),
      onPressed: onTap,
      splashRadius: 20,
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    var strength = 0.0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp('[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp('[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*]'))) strength += 0.25;

    return Row(
      children: List.generate(4, (i) {
        final filled = i < (strength * 4).round();
        Color color = NVColors.of(context).border;
        if (filled) {
          if (strength > 0.75) {
            color = NV.ok;
          } else if (strength > 0.4) {
            color = NV.warn;
          } else {
            color = NV.err;
          }
        }
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 3 ? 0 : 4),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: onPressed == null
            ? null
            : const LinearGradient(
                colors: [NV.accent, Color(0xFF3A9A5C)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: onPressed == null ? NVColors.of(context).surface : null,
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: NV.accent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(26),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: onPressed == null
                          ? NVColors.of(context).textMuted
                          : Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

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
            'OR',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.textMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: c.border)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.provider, required this.label});
  final String provider;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final isApple = provider == 'apple';
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isApple ? Icons.apple : Icons.g_mobiledata,
                size: isApple ? 22 : 32,
                color: c.text,
              ),
              if (isApple) const SizedBox(width: 8) else const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
