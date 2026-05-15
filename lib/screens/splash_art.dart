import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashArtScreen extends StatefulWidget {
  const SplashArtScreen({super.key});

  @override
  State<SplashArtScreen> createState() => _SplashArtScreenState();
}

class _SplashArtScreenState extends State<SplashArtScreen>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _leaves;
  Timer? _advance;
  bool _navigated = false;

  late final Animation<double> _doorOpen;
  late final Animation<double> _logoFade;
  late final Animation<double> _title;
  late final Animation<double> _tagline;

  static final _leafSeeds = List<_LeafSeed>.unmodifiable([
    _LeafSeed(xStart: 0.15, xDrift: 0.10, size: 28, phase: 0.00, speed: 0.8, rotate: -0.6),
    _LeafSeed(xStart: 0.35, xDrift: -0.05, size: 24, phase: 0.30, speed: 1.1, rotate: 0.8),
    _LeafSeed(xStart: 0.60, xDrift: 0.08, size: 32, phase: 0.50, speed: 0.7, rotate: -1.2),
    _LeafSeed(xStart: 0.85, xDrift: -0.06, size: 26, phase: 0.70, speed: 1.0, rotate: 0.4),
    _LeafSeed(xStart: 0.95, xDrift: -0.04, size: 20, phase: 0.90, speed: 1.3, rotate: -0.9),
  ]);

  @override
  void initState() {
    super.initState();
    // Reduce duration slightly and use single ticker if possible to reduce lag.
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _leaves = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 0.0 to 0.3: Black doors open from middle to sides
    _doorOpen = _curve(0.00, 0.30, Curves.easeInOutCubic);
    
    // 0.3 to 0.5: Logo fades in and translates up slightly
    _logoFade = _curve(0.30, 0.50, Curves.easeOut);
    
    // 0.4 to 0.65: Title fades in
    _title    = _curve(0.40, 0.65, Curves.easeOutCubic);
    
    // 0.6 to 0.85: Tagline fades in
    _tagline  = _curve(0.60, 0.85, Curves.easeOutCubic);

    _master.forward();
    _advance = Timer(const Duration(milliseconds: 4000), _goNext);
  }

  Animation<double> _curve(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: _master,
        curve: Interval(begin, end, curve: curve),
      );

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go('/welcome');
  }

  @override
  void dispose() {
    _advance?.cancel();
    _master.dispose();
    _leaves.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Underlying color for the doors
      body: GestureDetector(
        onTap: _goNext,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _master,
          builder: (context, _) {
            final doorVal = _doorOpen.value;
            // When doorVal == 0.0, the doors are fully closed (width = screen width/2).
            // When doorVal == 1.0, the doors are fully open (width = 0).
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. The actual Splash Content (White Background + Waves + Leaves + Logo)
                Container(
                  color: Colors.white,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Bottom waves - wrap in RepaintBoundary to reduce lag
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size(MediaQuery.of(context).size.width, 250),
                            painter: _WavesPainter(),
                          ),
                        ),
                      ),

                      // Drifting leaves
                      LayoutBuilder(
                        builder: (context, c) => AnimatedBuilder(
                          animation: _leaves,
                          builder: (context, _) => Stack(
                            children: [
                              for (final seed in _leafSeeds) _buildLeaf(seed, c),
                            ],
                          ),
                        ),
                      ),

                      // Centered content
                      SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 160,
                                height: 120,
                                child: Opacity(
                                  opacity: _logoFade.value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - _logoFade.value)),
                                    child: Image.asset(
                                      'assets/branding/logo.png',
                                      filterQuality: FilterQuality.high,
                                      errorBuilder: (c, e, s) => Image.asset(
                                        'assets/video/splash.png',
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Opacity(
                                opacity: _title.value,
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - _title.value)),
                                  child: Text(
                                    'N U T R I M A T E',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Opacity(
                                opacity: _tagline.value,
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - _tagline.value)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(width: 40, height: 1, color: Colors.grey.shade400),
                                      const SizedBox(width: 12),
                                      Text(
                                        'NOURISH TOGETHER, THRIVE TOGETHER',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(width: 40, height: 1, color: Colors.grey.shade400),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Black Doors overlay
                if (doorVal < 1.0) ...[
                  // Left door
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: MediaQuery.of(context).size.width / 2 * (1 - doorVal),
                    child: Container(color: Colors.black),
                  ),
                  // Right door
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: MediaQuery.of(context).size.width / 2 * (1 - doorVal),
                    child: Container(color: Colors.black),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaf(_LeafSeed seed, BoxConstraints c) {
    final t = (_leaves.value * seed.speed + seed.phase) % 1.0;
    final dy = -0.2 + t * 1.4;
    final dx = seed.xStart + seed.xDrift * math.sin(t * math.pi * 2);

    final double opacity;
    if (t < 0.1) {
      opacity = (t / 0.1);
    } else if (t > 0.8) {
      opacity = ((1 - t) / 0.2).clamp(0.0, 1.0);
    } else {
      opacity = 1.0;
    }

    final rotation = seed.rotate * (t - 0.5) * 4;
    return Positioned(
      left: dx * c.maxWidth - seed.size / 2,
      top: dy * c.maxHeight - seed.size / 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: rotation,
          child: Icon(Icons.energy_savings_leaf, size: seed.size, color: const Color(0xFF90C254).withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Bottom wave 1 (Light gray)
    paint.color = const Color(0xFFF0F2F5);
    final path1 = Path()
      ..moveTo(0, h * 0.6)
      ..quadraticBezierTo(w * 0.25, h * 0.3, w * 0.6, h * 0.5)
      ..quadraticBezierTo(w * 0.85, h * 0.65, w, h * 0.4)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path1, paint);

    // Bottom wave 2 (Subtle blue/green tint)
    paint.color = const Color(0xFFE2EBE5).withValues(alpha: 0.6);
    final path2 = Path()
      ..moveTo(0, h * 0.8)
      ..quadraticBezierTo(w * 0.3, h * 0.5, w * 0.7, h * 0.8)
      ..quadraticBezierTo(w * 0.9, h * 0.95, w, h * 0.7)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LeafSeed {
  const _LeafSeed({
    required this.xStart,
    required this.xDrift,
    required this.size,
    required this.phase,
    required this.speed,
    required this.rotate,
  });
  final double xStart;
  final double xDrift;
  final double size;
  final double phase;
  final double speed;
  final double rotate;
}
