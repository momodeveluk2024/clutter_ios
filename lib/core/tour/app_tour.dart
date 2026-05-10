import 'package:flutter/material.dart';

import '../../theme.dart';

// ═══════════════════════════════════════════════════════════════
//  DATA MODEL
// ═══════════════════════════════════════════════════════════════

class AppTourStep {
  const AppTourStep({
    required this.key,
    required this.title,
    required this.description,
    this.icon,
  });

  /// The GlobalKey attached to the target widget.
  final GlobalKey key;

  /// Short title displayed in the tooltip.
  final String title;

  /// Explanatory text shown below the title.
  final String description;

  /// Optional icon shown beside the title.
  final IconData? icon;
}

// ═══════════════════════════════════════════════════════════════
//  CONTROLLER — starts and manages the tour overlay
// ═══════════════════════════════════════════════════════════════

class AppTourController {
  AppTourController._();

  static OverlayEntry? _entry;

  /// Show the tour overlay above the current [context].
  /// Provide a list of [steps] whose GlobalKeys are already mounted.
  static void start(BuildContext context, List<AppTourStep> steps) {
    // Filter out steps whose keys haven't been mounted yet
    final valid =
        steps.where((s) => s.key.currentContext != null).toList();
    if (valid.isEmpty) return;

    dismiss(); // remove any existing tour

    _entry = OverlayEntry(
      builder: (_) => _TourOverlay(
        steps: valid,
        onComplete: dismiss,
      ),
    );
    Overlay.of(context).insert(_entry!);
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
    if (_current < widget.steps.length - 1) {
      _anim.forward(from: 0);
      setState(() => _current++);
    } else {
      widget.onComplete();
    }
  }

  void _skip() => widget.onComplete();

  Rect? _targetRect() {
    final ctx = widget.steps[_current].key.currentContext;
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

    // Spotlight padding around the target
    const padding = 12.0;
    const radius = 16.0;

    // Where to place the tooltip: above or below the target
    final bool placeBelow;
    if (rect != null) {
      placeBelow = rect.top > screen.height * 0.5;
    } else {
      placeBelow = false;
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ── Dark backdrop with spotlight cutout ──
            Positioned.fill(
              child: GestureDetector(
                onTap: _next,
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: rect,
                    padding: padding,
                    radius: radius,
                    opacity: 0.72,
                  ),
                ),
              ),
            ),

            // ── Tooltip card ──
            if (rect != null)
              Positioned(
                left: 20,
                right: 20,
                top: placeBelow
                    ? rect.top - 16 - _tooltipHeight(context)
                    : rect.bottom + padding + 16,
                child: _TooltipCard(
                  step: step,
                  current: _current,
                  total: widget.steps.length,
                  isLast: _current == widget.steps.length - 1,
                  onNext: _next,
                  onSkip: _skip,
                  colors: c,
                ),
              ),

            // ── Pulsing ring around target ──
            if (rect != null)
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
          ],
        ),
      ),
    );
  }

  double _tooltipHeight(BuildContext context) {
    // Estimate height: title + desc + buttons + padding
    return 180;
  }
}

// ═══════════════════════════════════════════════════════════════
//  SPOTLIGHT PAINTER — dark overlay with a cutout hole
// ═══════════════════════════════════════════════════════════════

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.targetRect,
    required this.padding,
    required this.radius,
    required this.opacity,
  });

  final Rect? targetRect;
  final double padding;
  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);

    if (targetRect == null) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }

    final spotlight = RRect.fromRectAndRadius(
      targetRect!.inflate(padding),
      Radius.circular(radius),
    );

    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(spotlight)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.targetRect != targetRect || old.opacity != opacity;
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
    required this.onNext,
    required this.onSkip,
    required this.colors,
  });

  final AppTourStep step;
  final int current;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final NVColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with icon
          Row(
            children: [
              if (step.icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NV.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(step.icon, size: 20, color: NV.accent),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
              ),
              // Step counter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${current + 1}/$total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            step.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),

          // Step dots + buttons
          Row(
            children: [
              // Dot indicators
              ...List.generate(
                total,
                (i) => Container(
                  width: i == current ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: i == current
                        ? NV.accent
                        : colors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Spacer(),
              // Skip
              if (!isLast)
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textMuted,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              const SizedBox(width: 4),
              // Next / Done
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: NV.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(isLast ? 'Got it!' : 'Next'),
              ),
            ],
          ),
        ],
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
