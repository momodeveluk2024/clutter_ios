import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../core/providers/auth_provider.dart';
import '../theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  int _cooldown = 0;
  Timer? _cooldownTimer;
  bool _checking = false;
  bool _resending = false;
  bool _verified = false;
  int _checkCooldown = 0;
  Timer? _checkCooldownTimer;
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  String get _userEmail =>
      firebase_auth.FirebaseAuth.instance.currentUser?.email ?? '';

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

    // If the initial verification email wasn't sent during signup
    // (e.g. due to rate-limiting or transient error), auto-send it now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (!auth.verificationEmailSent) {
        debugPrint('⚠️ Initial verification email was not sent — auto-sending now');
        _resendEmail();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _checkCooldownTimer?.cancel();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    if (_checking || _checkCooldown > 0) return;
    setState(() => _checking = true);
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      await user?.reload();
      final refreshedUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (refreshedUser?.emailVerified == true && mounted) {
        setState(() => _verified = true);
        await refreshedUser?.getIdToken(true);
        try {
          if (!mounted) return;
          await context.read<AuthProvider>().loadMe();
        } catch (_) {}
        if (mounted) context.go('/app');
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not verified yet — check your inbox and click the link first.',
              style: GoogleFonts.inter(),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error checking: $e',
              style: GoogleFonts.inter(),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _checking = false);
      // 5 second cooldown before allowing another check
      _checkCooldown = 5;
      _checkCooldownTimer?.cancel();
      _checkCooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          _checkCooldown--;
          if (_checkCooldown <= 0) t.cancel();
        });
      });
    }
  }

  Future<void> _resendEmail() async {
    if (_cooldown > 0 || _resending) return;
    setState(() => _resending = true);
    HapticFeedback.lightImpact();
    try {
      await firebase_auth.FirebaseAuth.instance.setLanguageCode('en');
      await firebase_auth.FirebaseAuth.instance.currentUser
          ?.sendEmailVerification(
        firebase_auth.ActionCodeSettings(
          url: 'https://dsds-c4ba7.firebaseapp.com',
          handleCodeInApp: false,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification email sent! Check your inbox.',
              style: GoogleFonts.inter(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: NV.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      // Start 60 second cooldown
      _cooldown = 60;
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          _cooldown--;
          if (_cooldown <= 0) t.cancel();
        });
      });
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to send email.';
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('too-many-requests') ||
            errorStr.contains('rate') ||
            errorStr.contains('blocked')) {
          errorMsg =
              'Too many requests — please wait a few minutes before trying again.';
          // Force a longer cooldown on rate limit
          _cooldown = 120;
          _cooldownTimer?.cancel();
          _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
            if (!mounted) {
              t.cancel();
              return;
            }
            setState(() {
              _cooldown--;
              if (_cooldown <= 0) t.cancel();
            });
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, style: GoogleFonts.inter()),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
    if (mounted) setState(() => _resending = false);
  }

  Future<void> _signOut() async {
    HapticFeedback.lightImpact();
    await firebase_auth.FirebaseAuth.instance.signOut();
    if (mounted) context.go('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Full screen background image (same as sign-in) ──
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

              // ── Scrollable Content ──
              Positioned.fill(
                child: ListView(
                  padding: EdgeInsets.only(top: heroH),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: c.bg.withValues(alpha: 0.90),
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
                            'Verify your',
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
                                  text: 'email',
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
                            'We\'ve sent a verification link to your email. '
                            'Open the link, then come back here and tap the button below.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: c.textMuted,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Email display field (read-only) ──
                          _ReadOnlyField(
                            label: 'Email address',
                            value: _userEmail,
                            icon: Icons.mail_outline_rounded,
                          ),
                          const SizedBox(height: 20),

                          // ── Status indicator ──
                          _StatusCard(
                            checking: _checking,
                            verified: _verified,
                          ),
                          const SizedBox(height: 24),

                          // ── I've verified button ──
                          _PrimaryGradientButton(
                            label: _checking
                                ? 'Checking…'
                                : _checkCooldown > 0
                                    ? 'Wait ${_checkCooldown}s…'
                                    : 'I\'ve verified my email',
                            loading: _checking,
                            onPressed:
                                (_checking || _checkCooldown > 0)
                                    ? null
                                    : () => _checkVerification(),
                          ),
                          const SizedBox(height: 16),

                          // ── Resend button ──
                          SizedBox(
                            height: 54,
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: (_cooldown > 0 || _resending)
                                  ? null
                                  : _resendEmail,
                              icon: _resending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh_rounded,
                                      size: 20,
                                    ),
                              label: Text(
                                _cooldown > 0
                                    ? 'Resend in ${_cooldown}s'
                                    : 'Resend verification email',
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: c.border),
                                foregroundColor: NV.accent,
                                disabledForegroundColor:
                                    c.textMuted.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Divider ──
                          Row(
                            children: [
                              Expanded(
                                child:
                                    Container(height: 1, color: c.border),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'didn\'t receive it?',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: c.textMuted,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              Expanded(
                                child:
                                    Container(height: 1, color: c.border),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Help tips ──
                          _HelpTip(
                            icon: Icons.search_rounded,
                            text: 'Check your spam or junk folder',
                            color: c,
                          ),
                          const SizedBox(height: 8),
                          _HelpTip(
                            icon: Icons.alternate_email_rounded,
                            text: 'Make sure $_userEmail is correct',
                            color: c,
                          ),
                          const SizedBox(height: 8),
                          _HelpTip(
                            icon: Icons.timer_outlined,
                            text: 'Wait a few minutes then try resending',
                            color: c,
                          ),
                          const SizedBox(height: 28),

                          // ── Sign out / back link ──
                          Center(
                            child: GestureDetector(
                              onTap: _signOut,
                              behavior: HitTestBehavior.opaque,
                              child: Text.rich(
                                TextSpan(
                                  text: 'Wrong account?  ',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: c.textMuted,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Sign out',
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

              // ── Top brand bar (same as sign-in) ──
              Positioned(
                top: media.padding.top + 14,
                left: 20,
                right: 20,
                child: Row(
                  children: [
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  READ-ONLY EMAIL FIELD
// ═══════════════════════════════════════════════════════════════

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dark ? c.border : const Color(0xFFE8EAED),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: c.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.text,
                  ),
                ),
              ),
              Icon(Icons.lock_outline_rounded, size: 16, color: c.textMuted),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STATUS CARD
// ═══════════════════════════════════════════════════════════════

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.checking, this.verified = false});
  final bool checking;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);

    if (verified) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NV.ok.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: NV.ok.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: NV.ok.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 24,
                color: NV.ok,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email verified!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Redirecting you now…',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NV.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NV.accent.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: NV.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: checking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(NV.accent),
                    ),
                  )
                : const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 22,
                    color: NV.accent,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checking ? 'Checking status…' : 'Waiting for verification',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  checking
                      ? 'Please wait while we verify'
                      : 'Tap the button below after verifying',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HELP TIP ROW
// ═══════════════════════════════════════════════════════════════

class _HelpTip extends StatelessWidget {
  const _HelpTip({
    required this.icon,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String text;
  final NVColors color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: color.textMuted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PRIMARY GRADIENT BUTTON (same as sign-in)
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
                    const Icon(Icons.verified_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}
