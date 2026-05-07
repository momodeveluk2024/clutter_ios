import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Brand-themed loading indicator. Three macro pills (P / C / F) orbit a
/// soft hub while pulsing in turn. Used everywhere a `CircularProgressIndicator`
/// would have lived.
///
/// Sizes:
///   * `NVLoader()`               — 56 px, suitable for inline placeholders.
///   * `NVLoader(size: 28)`       — for in-button or list-tile use.
///   * `NVLoader.overlay(...)`    — full-screen scrim wrapper, see below.
class NVLoader extends StatefulWidget {
  const NVLoader({
    super.key,
    this.size = 56,
    this.label,
  });

  /// Outer diameter in logical pixels.
  final double size;

  /// Optional caption shown beneath the loader. Null = no label.
  final String? label;

  @override
  State<NVLoader> createState() => _NVLoaderState();
}

class _NVLoaderState extends State<NVLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  // Macro codes used for the orbiting pills. Order matters — they're spaced
  // 120° apart starting from the top.
  static const _macros = ['Protein', 'Carbs', 'Fat'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = _ctrl.value;
              return CustomPaint(
                painter: _OrbitPainter(
                  progress: t,
                  hubColor: c.surface,
                  hubBorder: c.border,
                  pillColors: _macros
                      .map((code) => vitaminColors[code]!.fill)
                      .toList(),
                  pillLabels: const ['P', 'C', 'F'],
                ),
              );
            },
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 10),
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.progress,
    required this.hubColor,
    required this.hubBorder,
    required this.pillColors,
    required this.pillLabels,
  });

  final double progress; // 0 → 1
  final Color hubColor;
  final Color hubBorder;
  final List<Color> pillColors;
  final List<String> pillLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final orbitRadius = radius * 0.78;
    final pillRadius = radius * 0.22;
    final hubRadius = radius * 0.34;

    // Soft hub.
    final hubPaint = Paint()..color = hubColor;
    canvas.drawCircle(center, hubRadius, hubPaint);
    final hubBorderPaint = Paint()
      ..color = hubBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, hubRadius, hubBorderPaint);

    // Each pill rotates around the hub. The third pill is offset 120° from
    // the second, etc. We also pulse each pill in turn — the "active" one
    // grows ~15% larger to give the orbit a heartbeat.
    final baseAngle = progress * 2 * math.pi;
    for (var i = 0; i < pillColors.length; i++) {
      final theta = baseAngle + (i * 2 * math.pi / pillColors.length);
      final pos = Offset(
        center.dx + orbitRadius * math.cos(theta - math.pi / 2),
        center.dy + orbitRadius * math.sin(theta - math.pi / 2),
      );

      // "Active pill" detection: pulse the one closest to the top (12 o'clock).
      final phase = ((progress + i / pillColors.length) % 1.0);
      final pulse = 1.0 + 0.18 * math.sin(phase * 2 * math.pi);
      final r = pillRadius * pulse;

      final pillPaint = Paint()..color = pillColors[i];
      canvas.drawCircle(pos, r, pillPaint);

      // Letter label inside the pill.
      final textPainter = TextPainter(
        text: TextSpan(
          text: pillLabels[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: r * 1.05,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) =>
      old.progress != progress ||
      old.hubColor != hubColor ||
      old.hubBorder != hubBorder;
}

/// Full-screen scrim with a centered [NVLoader]. Wrap any screen body with
/// `NVLoadingOverlay(isLoading: ..., child: ...)` to guard async actions
/// without blocking the rest of the app shell.
class NVLoadingOverlay extends StatelessWidget {
  const NVLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.label,
  });

  final bool isLoading;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black.withValues(alpha: 0.32),
                alignment: Alignment.center,
                child: Material(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 22,
                    ),
                    child: NVLoader(label: label ?? 'Working on it…'),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One-shot dialog. Use when a screen can't easily wrap itself in
/// `NVLoadingOverlay` (e.g. inside button callbacks). Always pair with
/// `hideNVLoading(context)` in `try { ... } finally { ... }`.
Future<void> showNVLoading(BuildContext context, {String? label}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (_) => Center(
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: NVLoader(label: label ?? 'Working on it…'),
        ),
      ),
    ),
  );
}

void hideNVLoading(BuildContext context) {
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
