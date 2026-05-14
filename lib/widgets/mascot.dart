import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Mood drives the mascot's playback speed/segment.
///
/// The mascot is now a Lottie AI-chatbot animation living in
/// `assets/lottie/ai_chatbot.json`. Different moods map to playback
/// tweaks (faster while cheering, slower while sleeping, etc.) so
/// the call sites keep feeling responsive without us needing to
/// ship separate animations per mood.
enum MascotMood {
  curious,
  happy,
  thinking,
  cheering,
  waving,
  sleeping,
  sparkle,
}

class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.mood = MascotMood.curious,
    this.size = 120,
    this.compact = false,
  });

  final MascotMood mood;
  final double size;

  /// Kept for source-compat with the previous custom-painter Mascot.
  /// No longer used — the Lottie animation has its own halo.
  final bool compact;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  double get _speed {
    switch (widget.mood) {
      case MascotMood.cheering:
      case MascotMood.sparkle:
        return 1.35;
      case MascotMood.waving:
      case MascotMood.happy:
        return 1.15;
      case MascotMood.curious:
        return 1.0;
      case MascotMood.thinking:
        return 0.75;
      case MascotMood.sleeping:
        return 0.45;
    }
  }

  @override
  void didUpdateWidget(covariant Mascot old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _applySpeed();
    }
  }

  void _applySpeed() {
    final ctrl = _controller;
    if (ctrl == null) return;
    // Restart the repeating loop at the new speed so the change feels live.
    final duration = ctrl.duration;
    if (duration == null) return;
    final scaled = Duration(
      milliseconds: (duration.inMilliseconds / _speed.clamp(0.1, 4.0)).round(),
    );
    if (scaled.inMilliseconds <= 0) return;
    ctrl.stop();
    ctrl.duration = scaled;
    ctrl.repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.asset(
        'assets/lottie/ai_chatbot.json',
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
        onLoaded: (composition) {
          _controller?.dispose();
          final base = composition.duration;
          final scaled = Duration(
            milliseconds: (base.inMilliseconds / _speed.clamp(0.1, 4.0))
                .round()
                .clamp(80, 60000),
          );
          _controller =
              AnimationController(vsync: this, duration: scaled)..repeat();
        },
        controller: _controller,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
