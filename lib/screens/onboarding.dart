import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pc = PageController();
  int _index = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static const _steps = <_Step>[
    _Step(
      titleStart: 'Know what you\nare ',
      titleAccent: 'eating.',
      body:
          'See the full vitamin and mineral breakdown for real foods, down to the micro-gram.',
      asset: 'assets/onboarding/slide_1.png',
      iconData: Icons.restaurant_menu_rounded,
    ),
    _Step(
      titleStart: 'Scan it.\nLog it. ',
      titleAccent: 'Fast.',
      body:
          'Instantly log your packaged foods using our lightning-fast barcode scanner.',
      asset: 'assets/onboarding/slide_2.png',
      iconData: Icons.document_scanner_rounded,
    ),
    _Step(
      titleStart: 'Describe your\nmeal to ',
      titleAccent: 'AI.',
      body:
          'Just tell our AI assistant what you ate. We automatically calculate your exact nutrients.',
      asset: 'assets/onboarding/slide_3.png',
      iconData: Icons.auto_awesome_rounded,
    ),
    _Step(
      titleStart: 'Targets ',
      titleAccent: 'tailored',
      titleEnd: '\nto your body.',
      body:
          'A daily coverage score shows what your body is missing — and what to eat to fix it.',
      asset: 'assets/onboarding/slide_4.png',
      iconData: Icons.insights_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pc.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _steps.length - 1;

  void _next() {
    HapticFeedback.selectionClick();
    if (_isLast) {
      context.go('/sign-up');
      return;
    }
    _pc.nextPage(duration: NVMotion.base, curve: NVMotion.emphasized);
  }

  void _skip() {
    HapticFeedback.selectionClick();
    context.go('/sign-up');
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    final bottomHeight = screenH * 0.58; // Height for the bottom text card

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: c.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: Stack(
            children: [
              // ── Full screen background image area ──
              Positioned.fill(
                child: PageView.builder(
                  controller: _pc,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: _steps.length,
                  itemBuilder: (context, i) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _steps[i].asset,
                          fit: BoxFit.cover,
                          cacheWidth: 600,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, _, _) => const SizedBox(),
                        ),
                        // Soft dark gradient at top and bottom for readability
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.1),
                              ],
                              stops: const [0.0, 0.15, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Top bar: Brand + Skip ──
              Positioned(
                top: media.padding.top + 14,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    _PillButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _PillButton(
                      onTap: _skip,
                      child: Text(
                        _isLast ? 'Sign in' : 'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom content card ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.bg.withValues(
                      alpha: 0.90,
                    ), // Semi-transparent glass without BackdropFilter
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      28,
                      32,
                      28,
                      20 + media.padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Feature icon badge ──
                        AnimatedSwitcher(
                          duration: NVMotion.base,
                          child: _FeatureBadge(
                            key: ValueKey('badge_$_index'),
                            icon: _steps[_index].iconData,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Title ──
                        AnimatedSwitcher(
                          duration: NVMotion.base,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: _StepTitle(
                            key: ValueKey('title_$_index'),
                            step: _steps[_index],
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Body ──
                        AnimatedSwitcher(
                          duration: NVMotion.base,
                          child: Text(
                            _steps[_index].body,
                            key: ValueKey('body_$_index'),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.55,
                              color: c.textMuted,
                            ),
                          ),
                        ),
                        const Spacer(),

                        // ── Bottom controls ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _DotIndicator(count: _steps.length, index: _index),
                            const Spacer(),
                            _ContinueButton(
                              label: _isLast ? 'Get started' : 'Continue',
                              onPressed: _next,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
//  DATA MODEL
// ═══════════════════════════════════════════════════════════════

class _Step {
  final String titleStart;
  final String titleAccent;
  final String? titleEnd;
  final String body;
  final String asset;
  final IconData iconData;

  const _Step({
    required this.titleStart,
    required this.titleAccent,
    this.titleEnd,
    required this.body,
    required this.asset,
    required this.iconData,
  });
}

// ═══════════════════════════════════════════════════════════════
//  TITLE WIDGET
// ═══════════════════════════════════════════════════════════════

class _StepTitle extends StatelessWidget {
  const _StepTitle({super.key, required this.step, required this.color});
  final _Step step;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.12,
          color: color,
        ),
        children: [
          TextSpan(text: step.titleStart),
          TextSpan(
            text: step.titleAccent,
            style: GoogleFonts.instrumentSerif(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              fontSize: 34,
              letterSpacing: -0.6,
              height: 1.12,
              color: NV.accent,
            ),
          ),
          if (step.titleEnd != null) TextSpan(text: step.titleEnd),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FEATURE ICON BADGE
// ═══════════════════════════════════════════════════════════════

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({super.key, required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: NV.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NV.accent.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, color: NV.accent, size: 22),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PILL BUTTON — lightweight, no blur
// ═══════════════════════════════════════════════════════════════

class _PillButton extends StatelessWidget {
  const _PillButton({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DOT INDICATOR
// ═══════════════════════════════════════════════════════════════

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: NVMotion.base,
            curve: NVMotion.emphasized,
            margin: const EdgeInsets.only(right: 6),
            width: i == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? NV.accent : NV.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CONTINUE BUTTON
// ═══════════════════════════════════════════════════════════════

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 210),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(150, 54),
          backgroundColor: NV.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.fromLTRB(24, 0, 18, 0),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
