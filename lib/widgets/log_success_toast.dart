import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Top-of-screen success popup shown after a food/meal is logged.
/// Slides in from above, auto-dismisses after [duration], tap to dismiss.
class LogSuccessToast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? imageUrl,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    HapticFeedback.lightImpact();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _current?.remove();
    _current = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _LogSuccessOverlay(
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        duration: duration,
        onDismiss: () {
          if (entry.mounted) entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }
}

class _LogSuccessOverlay extends StatefulWidget {
  const _LogSuccessOverlay({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.duration,
    required this.onDismiss,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_LogSuccessOverlay> createState() => _LogSuccessOverlayState();
}

class _LogSuccessOverlayState extends State<_LogSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Positioned(
      top: mq.padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2F7D4A),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F7D4A).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 22,
                        color: Color(0xFF2F7D4A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: Color(0xFF111827),
                              ),
                            ),
                            if (widget.subtitle != null &&
                                widget.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
