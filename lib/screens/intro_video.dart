import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../widgets/nv_loader.dart';

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/branding/welcome.mp4');
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller
        ..setLooping(false)
        // Muted so browser autoplay policies don't block playback on web,
        // and so the intro doesn't blare audio if the user opens the app
        // in a quiet space. Native targets can be unmuted later if needed.
        ..setVolume(0)
        ..play();
      _controller.addListener(_onTick);
    }).catchError((Object _) {
      if (!mounted) return;
      _goNext();
    });
  }

  void _onTick() {
    if (!mounted || _navigated) return;
    final v = _controller.value;
    if (v.hasError) {
      _goNext();
      return;
    }
    if (v.duration > Duration.zero &&
        v.position >= v.duration - const Duration(milliseconds: 80)) {
      _goNext();
    }
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go('/welcome');
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    // Immediately stop playback, but detach and delay the actual hardware
    // decoder teardown. On some Android devices (especially Xiaomi/MIUI),
    // destroying the MediaCodec simultaneously during a heavy Flutter route
    // transition causes massive GPU contention and an ANR (Signal 3).
    _controller.pause();
    final c = _controller;
    Future.delayed(const Duration(seconds: 3), () => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _goNext,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              const Center(
                child: NVLoader(label: 'Loading…'),
              ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton(
                    onPressed: _goNext,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Skip'),
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
