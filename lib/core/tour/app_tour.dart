import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';
import '../../widgets/mascot.dart';

// ═══════════════════════════════════════════════════════════════
//  DATA MODEL
// ═══════════════════════════════════════════════════════════════

class AppTourStep {
  const AppTourStep({
    required this.key,
    required this.title,
    required this.description,
    this.icon,
    this.mood = MascotMood.curious,
  });

  /// The GlobalKey attached to the target widget. May be null when the
  /// step is a centered "intro" card with no spotlight target.
  final GlobalKey? key;

  /// Short title displayed in the tooltip.
  final String title;

  /// Explanatory text shown below the title.
  final String description;

  /// Optional icon shown beside the title.
  final IconData? icon;

  /// Sprout's mood for this step.
  final MascotMood mood;
}

// ═══════════════════════════════════════════════════════════════
//  CONTROLLER — starts and manages the tour overlay
// ═══════════════════════════════════════════════════════════════

class AppTourController {
  AppTourController._();

  static OverlayEntry? _entry;

  /// Show the tour overlay above the current [context].
  /// Steps without a `key` show as centered intro cards.
  /// Steps with a `key` show as spotlight tooltips on the target.
  static void start(BuildContext context, List<AppTourStep> steps) {
    final valid = steps
        .where((s) => s.key == null || s.key!.currentContext != null)
        .toList();
    if (valid.isEmpty) return;

    dismiss();

    _entry = OverlayEntry(
      builder: (_) => _TourOverlay(
        steps: valid,
        onComplete: dismiss,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  /// Dismiss any active tour.
  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

// ═══════════════════════════════════════════════════════════════
//  OVERLAY WIDGET — the actual tour UI
// ═══════════════════════════════════════════════════════════════

class _TourOverlay extends StatefulWidget {
  const _TourOverlay({required this.steps, required this.onComplete});

  final List<AppTourStep> steps;
  final VoidCallback onComplete;

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  late AnimationController _anim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_current < widget.steps.length - 1) {
      _anim.forward(from: 0);
      setState(() => _current++);
    } else {
      widget.onComplete();
    }
  }

  void _prev() {
    if (_current == 0) return;
    HapticFeedback.selectionClick();
    _anim.forward(from: 0);
    setState(() => _current--);
  }

  void _skip() {
    HapticFeedback.selectionClick();
    widget.onComplete();
  }

  Rect? _targetRect() {
    final key = widget.steps[_current].key;
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_current];
    final rect = _targetRect();
    final screen = MediaQuery.of(context).size;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);

    const padding = 12.0;
    const radius = 16.0;

    final bool placeBelow = rect != null && rect.top > screen.height * 0.5;

    final hasTarget = rect != null;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ── Invisible full-screen tap target — tap anywhere to advance.
            // No dim backdrop: the user can still see the underlying UI, so
            // they're never stuck on a black screen if the tooltip card
            // fails to render for any reason.
            Positioned.fill(
              child: GestureDetector(
                onTap: _next,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),

            // ── Always-visible escape hatch (top-right X) ──
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: Material(
                color: NV.accent,
                shape: const CircleBorder(),
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.4),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _skip,
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // ── "Tap anywhere to continue" hint pinned to the bottom.
            // Without the dim backdrop the user might not realize the screen
            // is in tour mode — this makes the interaction discoverable.
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 12,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tap anywhere to continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Pulsing ring around target ──
            if (hasTarget)
              Positioned(
                left: rect.left - padding,
                top: rect.top - padding,
                child: IgnorePointer(
                  child: _PulsingRing(
                    width: rect.width + padding * 2,
                    height: rect.height + padding * 2,
                    radius: radius,
                  ),
                ),
              ),

            // ── Tooltip / intro card ──
            if (hasTarget)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: 16,
                right: 16,
                top: placeBelow
                    ? (rect.top - 16 - 220).clamp(
                        MediaQuery.paddingOf(context).top + 12, double.infinity)
                    : rect.bottom + padding + 16,
                child: _TooltipCard(
                  step: step,
                  current: _current,
                  total: widget.steps.length,
                  isLast: _current == widget.steps.length - 1,
                  isFirst: _current == 0,
                  onNext: _next,
                  onPrev: _prev,
                  onSkip: _skip,
                  colors: c,
                ),
              )
            else
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _TooltipCard(
                            step: step,
                            current: _current,
                            total: widget.steps.length,
                            isLast: _current == widget.steps.length - 1,
                            isFirst: _current == 0,
                            onNext: _next,
                            onPrev: _prev,
                            onSkip: _skip,
                            colors: c,
                            centered: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TOOLTIP CARD
// ═══════════════════════════════════════════════════════════════

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.step,
    required this.current,
    required this.total,
    required this.isLast,
    required this.isFirst,
    required this.onNext,
    required this.onPrev,
    required this.onSkip,
    required this.colors,
    this.centered = false,
  });

  final AppTourStep step;
  final int current;
  final int total;
  final bool isLast;
  final bool isFirst;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onSkip;
  final NVColors colors;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Stop taps on the card from triggering the backdrop.
      onTap: () {},
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: Container(
          key: ValueKey(current),
          padding: EdgeInsets.fromLTRB(
            centered ? 22 : 18,
            centered ? 22 : 16,
            centered ? 22 : 18,
            14,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(centered ? 26 : 22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 40,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: centered
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (centered) ...[
                // ── Hero intro-card layout ────────────────────
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        NV.accent.withValues(alpha: 0.16),
                        NV.accentSoft.withValues(alpha: 0.30),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Mascot(mood: step.mood, size: 118, compact: true),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (step.icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: NV.accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(step.icon, size: 14, color: NV.accent),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceMuted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${current + 1} / $total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colors.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                    letterSpacing: -0.4,
                    height: 1.16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                // ── Compact spotlight-tooltip layout ──────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Mascot(mood: step.mood, size: 56, compact: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (step.icon != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: NV.accentSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    step.icon,
                                    size: 14,
                                    color: NV.accent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${current + 1} / $total',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textMuted,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                              letterSpacing: -0.3,
                              height: 1.18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (current + 1) / total,
                  minHeight: 5,
                  backgroundColor: colors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(NV.accent),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  if (!isFirst)
                    TextButton.icon(
                      onPressed: onPrev,
                      icon: Icon(Icons.chevron_left, size: 18, color: colors.textMuted),
                      label: Text(
                        'Back',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  const Spacer(),
                  if (!isLast)
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Skip tour'),
                    ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: NV.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isLast ? "I'm ready" : 'Next'),
                        const SizedBox(width: 6),
                        Icon(
                          isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PULSING RING — subtle animated border around the target
// ═══════════════════════════════════════════════════════════════

class _PulsingRing extends StatefulWidget {
  const _PulsingRing({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) {
        final scale = 1.0 + _pulse.value * 0.06;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(
                color: NV.accent.withValues(
                  alpha: 0.5 + _pulse.value * 0.3,
                ),
                width: 2.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
