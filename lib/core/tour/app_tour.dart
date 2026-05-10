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

  /// Show the tour dialog.
  static void start(BuildContext context, List<AppTourStep> steps) {
    if (steps.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TourDialog(steps: steps),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DIALOG WIDGET — the actual tour UI
// ═══════════════════════════════════════════════════════════════

class _TourDialog extends StatefulWidget {
  const _TourDialog({required this.steps});

  final List<AppTourStep> steps;

  @override
  State<_TourDialog> createState() => _TourDialogState();
}

class _TourDialogState extends State<_TourDialog> {
  int _current = 0;

  void _next() {
    if (_current < widget.steps.length - 1) {
      setState(() => _current++);
    } else {
      Navigator.pop(context);
    }
  }

  void _skip() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_current];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: _TooltipCard(
        step: step,
        current: _current,
        total: widget.steps.length,
        isLast: _current == widget.steps.length - 1,
        onNext: _next,
        onSkip: _skip,
        colors: c,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 12),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: NV.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(step.icon, size: 24, color: NV.accent),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
              ),
              // Step counter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
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
          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

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
                      fontSize: 14,
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
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
