import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Mood drives Sprout's expression and gesture.
enum MascotMood {
  curious,
  happy,
  thinking,
  cheering,
  waving,
  sleeping,
  sparkle,
}

/// Sprout — Nutrimate's tiny leaf companion.
///
/// Drawn with CustomPainter so we ship zero new assets. Idle animation:
/// gentle bob + blink + breathing scale. Mood drives eyes/mouth/gesture.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.mood = MascotMood.curious,
    this.size = 120,
    this.compact = false,
  });

  final MascotMood mood;
  final double size;

  /// When true, omits the soft halo + sparkles for tight layouts.
  final bool compact;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _blink;
  late final AnimationController _moodSwitch;
  MascotMood _from = MascotMood.curious;
  MascotMood _to = MascotMood.curious;

  @override
  void initState() {
    super.initState();
    _from = widget.mood;
    _to = widget.mood;
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _moodSwitch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: 1,
    );
    _scheduleBlink();
  }

  @override
  void didUpdateWidget(covariant Mascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _from = oldWidget.mood;
      _to = widget.mood;
      _moodSwitch.forward(from: 0);
    }
  }

  void _scheduleBlink() {
    Future.delayed(Duration(milliseconds: 1800 + (_idle.hashCode % 1500)), () {
      if (!mounted) return;
      _blink.forward(from: 0).then((_) {
        if (!mounted) return;
        _blink.reverse().then((_) => _scheduleBlink());
      });
    });
  }

  @override
  void dispose() {
    _idle.dispose();
    _blink.dispose();
    _moodSwitch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _blink, _moodSwitch]),
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_idle.value);
        final bob = math.sin(t * math.pi * 2) * 3.0;
        final breathe = 1.0 + math.sin(t * math.pi) * 0.015;
        final blink = _blink.value;
        final morph = Curves.easeOutCubic.transform(_moodSwitch.value);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Transform.translate(
            offset: Offset(0, bob),
            child: Transform.scale(
              scale: breathe,
              child: CustomPaint(
                painter: _SproutPainter(
                  fromMood: _from,
                  toMood: _to,
                  morph: morph,
                  blink: blink,
                  showHalo: !widget.compact,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SproutPainter extends CustomPainter {
  _SproutPainter({
    required this.fromMood,
    required this.toMood,
    required this.morph,
    required this.blink,
    required this.showHalo,
  });

  final MascotMood fromMood;
  final MascotMood toMood;
  final double morph;
  final double blink;
  final bool showHalo;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + h * 0.04;
    final bodyR = w * 0.34;

    if (showHalo) {
      final halo = Paint()
        ..color = NV.accent.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(Offset(cx, cy + 4), bodyR * 1.35, halo);
    }

    // ── Tiny leaf on top ──
    _paintLeaf(canvas, Offset(cx, cy - bodyR * 1.05), w * 0.12);

    // ── Body shadow under sprout ──
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + bodyR * 0.95),
        width: bodyR * 1.7,
        height: bodyR * 0.32,
      ),
      shadow,
    );

    // ── Body — pill / egg shape ──
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: bodyR * 2.05,
      height: bodyR * 2.20,
    );
    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _lighten(NV.accent, 0.18),
          NV.accent,
        ],
      ).createShader(bodyRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(bodyR)),
      body,
    );

    // Subtle inner highlight
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
      Offset(cx - bodyR * 0.45, cy - bodyR * 0.55),
      bodyR * 0.45,
      highlight,
    );

    // ── Cheeks (warm) ──
    final cheek = Paint()..color = const Color(0xFFFF8F8F).withValues(alpha: 0.55);
    canvas.drawCircle(Offset(cx - bodyR * 0.55, cy + bodyR * 0.15), bodyR * 0.13, cheek);
    canvas.drawCircle(Offset(cx + bodyR * 0.55, cy + bodyR * 0.15), bodyR * 0.13, cheek);

    // ── Face (interpolated from→to) ──
    final fromExpr = _expressionFor(fromMood);
    final toExpr = _expressionFor(toMood);
    final expr = _ExprPose.lerp(fromExpr, toExpr, morph);

    _paintEyes(canvas, Offset(cx, cy), bodyR, expr, blink);
    _paintMouth(canvas, Offset(cx, cy), bodyR, expr);

    // ── Gesture (arms / sparkles) ──
    _paintGesture(canvas, Offset(cx, cy), bodyR, expr);
  }

  void _paintLeaf(Canvas canvas, Offset top, double s) {
    final leafPath = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(top.dx + s, top.dy - s * 0.2, top.dx + s * 0.05, top.dy - s * 1.4)
      ..quadraticBezierTo(top.dx - s * 0.6, top.dy - s * 0.4, top.dx, top.dy);
    final leafPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_lighten(NV.accent, 0.25), NV.accentDeep],
      ).createShader(Rect.fromPoints(
        Offset(top.dx - s, top.dy - s * 1.4),
        Offset(top.dx + s, top.dy),
      ));
    canvas.drawPath(leafPath, leafPaint);
    // Stem
    final stem = Paint()
      ..color = NV.accentDeep
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(top, Offset(top.dx, top.dy - s * 0.55), stem);
  }

  void _paintEyes(Canvas canvas, Offset center, double r, _ExprPose e, double blinkVal) {
    final eyeY = center.dy - r * 0.1;
    final eyeDx = r * 0.32;
    final eyeR = r * 0.10 * (1 - blinkVal * 0.85);

    final paint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF111111);

    // Eye whites
    if (e.eyesClosed > 0.5) {
      // Closed (smiling): draw arcs
      final p = Paint()
        ..color = const Color(0xFF111111)
        ..strokeWidth = r * 0.07
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      _arcSmile(canvas, Offset(center.dx - eyeDx, eyeY), r * 0.14, p);
      _arcSmile(canvas, Offset(center.dx + eyeDx, eyeY), r * 0.14, p);
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx - eyeDx, eyeY), width: r * 0.30, height: eyeR * 2.4),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx + eyeDx, eyeY), width: r * 0.30, height: eyeR * 2.4),
        paint,
      );
      // Pupils with optional offset (look direction)
      canvas.drawCircle(
        Offset(center.dx - eyeDx + e.pupilDx * r * 0.06, eyeY + e.pupilDy * r * 0.06),
        eyeR * 0.7,
        pupilPaint,
      );
      canvas.drawCircle(
        Offset(center.dx + eyeDx + e.pupilDx * r * 0.06, eyeY + e.pupilDy * r * 0.06),
        eyeR * 0.7,
        pupilPaint,
      );
      // Highlight dots
      final hi = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(center.dx - eyeDx + r * 0.03, eyeY - r * 0.03),
        eyeR * 0.22,
        hi,
      );
      canvas.drawCircle(
        Offset(center.dx + eyeDx + r * 0.03, eyeY - r * 0.03),
        eyeR * 0.22,
        hi,
      );
    }
  }

  void _arcSmile(Canvas canvas, Offset c, double r, Paint p) {
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(rect, math.pi * 1.05, math.pi * 0.9, false, p);
  }

  void _paintMouth(Canvas canvas, Offset center, double r, _ExprPose e) {
    final mouthY = center.dy + r * 0.32;
    final paint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;

    final width = r * 0.45 * (0.8 + e.mouthOpen * 0.6);
    final curve = e.mouthCurve; // 1 = smile, -1 = sad

    final left = Offset(center.dx - width / 2, mouthY);
    final right = Offset(center.dx + width / 2, mouthY);
    final cp = Offset(center.dx, mouthY + curve * r * 0.16);

    final path = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(cp.dx, cp.dy, right.dx, right.dy);

    if (e.mouthOpen > 0.4) {
      // Filled little O for cheering / wow
      final fill = Paint()..color = const Color(0xFF1A1A1A);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, mouthY + r * 0.05), width: r * 0.22, height: r * 0.18 * e.mouthOpen),
        fill,
      );
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void _paintGesture(Canvas canvas, Offset center, double r, _ExprPose e) {
    if (e.sparkles > 0.1) {
      final sp = Paint()
        ..color = NV.accent.withValues(alpha: e.sparkles)
        ..style = PaintingStyle.fill;
      _sparkle(canvas, Offset(center.dx + r * 1.05, center.dy - r * 0.6), r * 0.10, sp);
      _sparkle(canvas, Offset(center.dx - r * 1.10, center.dy - r * 0.2), r * 0.07, sp);
      _sparkle(canvas, Offset(center.dx + r * 0.85, center.dy + r * 0.7), r * 0.06, sp);
    }
    if (e.wave > 0.1) {
      // Tiny waving paw on the right
      final paw = Paint()..color = _lighten(NV.accent, 0.12);
      final px = center.dx + r * 0.95;
      final py = center.dy - r * 0.05;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(e.wave * 0.5);
      canvas.drawCircle(Offset.zero, r * 0.18, paw);
      canvas.restore();
    }
    if (e.thumbsUp > 0.1) {
      final paw = Paint()..color = _lighten(NV.accent, 0.10);
      final px = center.dx - r * 0.95;
      final py = center.dy + r * 0.05;
      canvas.drawCircle(Offset(px, py), r * 0.18, paw);
      // "thumb"
      final thumb = Paint()
        ..color = _lighten(NV.accent, 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(px, py - r * 0.08),
        Offset(px, py - r * 0.24),
        thumb,
      );
    }
    if (e.zzz > 0.1) {
      final p = TextPainter(
        text: TextSpan(
          text: 'z z',
          style: TextStyle(
            color: NV.accent.withValues(alpha: e.zzz),
            fontSize: r * 0.22,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(canvas, Offset(center.dx + r * 0.9, center.dy - r * 0.85));
    }
  }

  void _sparkle(Canvas canvas, Offset c, double s, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 0.25, c.dy - s * 0.25)
      ..lineTo(c.dx + s, c.dy)
      ..lineTo(c.dx + s * 0.25, c.dy + s * 0.25)
      ..lineTo(c.dx, c.dy + s)
      ..lineTo(c.dx - s * 0.25, c.dy + s * 0.25)
      ..lineTo(c.dx - s, c.dy)
      ..lineTo(c.dx - s * 0.25, c.dy - s * 0.25)
      ..close();
    canvas.drawPath(path, p);
  }

  _ExprPose _expressionFor(MascotMood m) {
    switch (m) {
      case MascotMood.curious:
        return const _ExprPose(mouthCurve: 0.6, pupilDx: 0.6, pupilDy: -0.2);
      case MascotMood.happy:
        return const _ExprPose(mouthCurve: 1.0, eyesClosed: 1, sparkles: 0.4);
      case MascotMood.thinking:
        return const _ExprPose(mouthCurve: 0.2, pupilDx: -0.6, pupilDy: -0.6);
      case MascotMood.cheering:
        return const _ExprPose(mouthCurve: 1.0, mouthOpen: 0.8, sparkles: 1.0, thumbsUp: 1.0);
      case MascotMood.waving:
        return const _ExprPose(mouthCurve: 0.8, wave: 1.0, sparkles: 0.3);
      case MascotMood.sleeping:
        return const _ExprPose(mouthCurve: 0.3, eyesClosed: 1, zzz: 0.9);
      case MascotMood.sparkle:
        return const _ExprPose(mouthCurve: 0.7, sparkles: 1.0);
    }
  }

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final lit = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lit.toColor();
  }

  @override
  bool shouldRepaint(covariant _SproutPainter old) =>
      old.morph != morph ||
      old.blink != blink ||
      old.fromMood != fromMood ||
      old.toMood != toMood;
}

class _ExprPose {
  const _ExprPose({
    this.mouthCurve = 0.5,
    this.mouthOpen = 0,
    this.eyesClosed = 0,
    this.pupilDx = 0,
    this.pupilDy = 0,
    this.sparkles = 0,
    this.wave = 0,
    this.thumbsUp = 0,
    this.zzz = 0,
  });

  final double mouthCurve;
  final double mouthOpen;
  final double eyesClosed;
  final double pupilDx;
  final double pupilDy;
  final double sparkles;
  final double wave;
  final double thumbsUp;
  final double zzz;

  static _ExprPose lerp(_ExprPose a, _ExprPose b, double t) {
    double L(double x, double y) => x + (y - x) * t;
    return _ExprPose(
      mouthCurve: L(a.mouthCurve, b.mouthCurve),
      mouthOpen: L(a.mouthOpen, b.mouthOpen),
      eyesClosed: L(a.eyesClosed, b.eyesClosed),
      pupilDx: L(a.pupilDx, b.pupilDx),
      pupilDy: L(a.pupilDy, b.pupilDy),
      sparkles: L(a.sparkles, b.sparkles),
      wave: L(a.wave, b.wave),
      thumbsUp: L(a.thumbsUp, b.thumbsUp),
      zzz: L(a.zzz, b.zzz),
    );
  }
}
