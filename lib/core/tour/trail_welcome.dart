import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme.dart';
import '../../widgets.dart';
import '../../widgets/mascot.dart';

/// Trail (trial) welcome — shown once after onboarding finishes.
///
/// Two paths:
///   • [onStart]   — user wants the guided spotlight tour
///   • [onSkip]    — user dismisses; we mark the tour completed
///
/// Previews the headline features added in the latest release:
/// personalized kcal & macros, AI meal scan, barcode scan,
/// AI nutrition chat, and live vitamin coverage.
class TrailWelcomeOverlay {
  TrailWelcomeOverlay._();

  static OverlayEntry? _entry;
  static bool get isShowing => _entry != null;

  static void show(
    BuildContext context, {
    required VoidCallback onStart,
    required VoidCallback onSkip,
  }) {
    dismiss();
    _entry = OverlayEntry(
      builder: (_) => _TrailWelcomeScreen(
        onStart: () {
          dismiss();
          onStart();
        },
        onSkip: () {
          dismiss();
          onSkip();
        },
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _TrailFeature {
  const _TrailFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

final List<_TrailFeature> _features = [
  _TrailFeature(
    icon: Icons.donut_large_rounded,
    title: 'Personalized kcal & macros',
    description:
        'Targets tuned from your BMR, TDEE and activity. Protein, carbs, fat and fiber tracked live as you log.',
    color: NV.accent,
  ),
  const _TrailFeature(
    icon: Icons.center_focus_strong_rounded,
    title: 'AI meal photo scan',
    description:
        'Snap your plate. Sprout identifies the foods, estimates portions, and fills in kcal + micros in seconds.',
    color: Color(0xFFB07A1A),
  ),
  const _TrailFeature(
    icon: Icons.qr_code_scanner_rounded,
    title: 'Lightning barcode scan',
    description:
        'Point at any package — we pull nutrition from Open Food Facts + USDA. Works on millions of products.',
    color: Color(0xFF3A6B88),
  ),
  const _TrailFeature(
    icon: Icons.auto_awesome_rounded,
    title: 'AI nutrition chat',
    description:
        '“How much iron is in this?” “Build me a 30g-protein lunch.” Ask anything — answers grounded in real data.',
    color: Color(0xFF6B4A8A),
  ),
  const _TrailFeature(
    icon: Icons.spa_outlined,
    title: 'Live vitamin coverage',
    description:
        'See exactly which vitamins and minerals your day is missing — and which foods would close the gap.',
    color: Color(0xFF1F5C36),
  ),
];

class _TrailWelcomeScreen extends StatefulWidget {
  const _TrailWelcomeScreen({required this.onStart, required this.onSkip});
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  State<_TrailWelcomeScreen> createState() => _TrailWelcomeScreenState();
}

class _TrailWelcomeScreenState extends State<_TrailWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    // Duration must cover the longest staggered delay plus its 320 ms fade
    // window, otherwise late entries (Start/Skip buttons) never reach
    // full opacity — that made the CTA look disabled.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final media = MediaQuery.of(context);
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      child: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              media.padding.top + 14,
              18,
              media.padding.bottom + 14,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AnimatedBuilder(
                animation: _fade,
                builder: (_, child) {
                  final v = _fade.value;
                  return Transform.translate(
                    offset: Offset(0, (1 - v) * 24),
                    child: Transform.scale(scale: 0.96 + 0.04 * v, child: child),
                  );
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.36),
                        blurRadius: 48,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeroHeader(),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int i = 0; i < _features.length; i++)
                                  _StaggeredEntry(
                                    delay: 220 + i * 90,
                                    parent: _ctrl,
                                    child: _FeatureRow(
                                      icon: _features[i].icon,
                                      title: _features[i].title,
                                      description: _features[i].description,
                                      color: _features[i].color,
                                    ),
                                  ),
                                const SizedBox(height: 14),
                                _StaggeredEntry(
                                  delay: 220 + _features.length * 90 + 40,
                                  parent: _ctrl,
                                  child: NVPrimaryButton(
                                    label: 'Start the tour',
                                    trailingIcon: Icons.arrow_forward_rounded,
                                    accent: true,
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      widget.onStart();
                                    },
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _StaggeredEntry(
                                  delay: 220 + _features.length * 90 + 90,
                                  parent: _ctrl,
                                  child: TextButton(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      widget.onSkip();
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: c.textMuted,
                                      textStyle: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: const Text('Skip for now'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HERO HEADER — gradient backdrop + mascot + headline
// ═══════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NV.accent.withValues(alpha: 0.16),
            NV.accentSoft.withValues(alpha: 0.30),
            c.surface,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: NV.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'WHAT\'S NEW',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: NV.accentDeep,
                letterSpacing: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Mascot(mood: MascotMood.waving, size: 118),
          const SizedBox(height: 4),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: c.text,
                letterSpacing: -0.6,
                height: 1.12,
              ),
              children: [
                const TextSpan(text: "Hey, I'm "),
                TextSpan(
                  text: 'Sprout',
                  style: GoogleFonts.instrumentSerif(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    fontSize: 30,
                    color: NV.accent,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Want a 60-second tour of what's new in Nutrimate?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: c.textMuted,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FEATURE ROW
// ═══════════════════════════════════════════════════════════════

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: c.textMuted,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
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
//  STAGGERED ENTRY — fade + slide based on a parent controller
// ═══════════════════════════════════════════════════════════════

class _StaggeredEntry extends StatelessWidget {
  const _StaggeredEntry({
    required this.delay,
    required this.parent,
    required this.child,
  });
  final int delay;
  final AnimationController parent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: parent,
      builder: (_, c) {
        final totalMs = parent.duration!.inMilliseconds;
        final localT = (((parent.value * totalMs) - delay) / 320).clamp(
          0.0,
          1.0,
        );
        final eased = Curves.easeOutCubic.transform(localT);
        // Block hits on barely-visible entries so users can't accidentally
        // fire the action behind a control that hasn't faded in yet.
        return IgnorePointer(
          ignoring: eased < 0.5,
          child: Opacity(
            opacity: eased,
            child: Transform.translate(
              offset: Offset(0, (1 - eased) * 14),
              child: c,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
