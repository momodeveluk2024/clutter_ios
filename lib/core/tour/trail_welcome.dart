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
/// This screen previews the headline features added in the latest
/// release: AI scan (meal photo), barcode scan, kcal & macro tracking,
/// AI chat assistant, and personalized vitamin coverage.
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
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);
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
      color: Colors.black.withValues(alpha: 0.55),
      child: FadeTransition(
        opacity: _fade,
        child: Center(
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                media.padding.top + 16,
                20,
                media.padding.bottom + 16,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Mascot greeting ──
                      const Mascot(mood: MascotMood.waving, size: 130),
                      const SizedBox(height: 6),
                      Text(
                        "Hey, I'm Sprout!",
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: c.text,
                          letterSpacing: -0.6,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Want a quick tour of what's new?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: c.textMuted,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Feature highlights ──
                      _FeatureRow(
                        icon: Icons.donut_large_rounded,
                        title: 'Daily kcal & macros',
                        description:
                            'Personalized energy + protein, carbs, fat, fiber.',
                        color: NV.accent,
                      ),
                      _FeatureRow(
                        icon: Icons.center_focus_strong_rounded,
                        title: 'AI meal scan',
                        description:
                            'Snap your plate — Sprout estimates what is on it.',
                        color: const Color(0xFF8A6010),
                      ),
                      _FeatureRow(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Barcode scan',
                        description: 'Packaged foods log in under a second.',
                        color: const Color(0xFF3A6B88),
                      ),
                      _FeatureRow(
                        icon: Icons.auto_awesome_rounded,
                        title: 'AI nutrition chat',
                        description: 'Ask anything about a food — instant answers.',
                        color: const Color(0xFF6B4A8A),
                      ),
                      _FeatureRow(
                        icon: Icons.spa_outlined,
                        title: 'Vitamin coverage',
                        description:
                            'See which micros your meals cover today, in real time.',
                        color: const Color(0xFF1F5C36),
                      ),

                      const SizedBox(height: 20),

                      // ── Actions ──
                      NVPrimaryButton(
                        label: 'Start the tour',
                        trailingIcon: Icons.arrow_forward_rounded,
                        accent: true,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.onStart();
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton(
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
                    ],
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
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
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: c.textMuted,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
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
