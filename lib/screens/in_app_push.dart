import 'package:flutter/material.dart';

enum PushType { success, error, info }

class InAppPush {
  static OverlayEntry? _current;

  static void _cleanup() {
    _current?.remove();
    _current = null;
  }

  static void show(BuildContext context, {
    required String message,
    PushType type = PushType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _cleanup();
    final entry = OverlayEntry(
      builder: (context) => _PushWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: _cleanup,
      ),
    );
    _current = entry;
    Overlay.of(context).insert(entry);
  }
}

class _PushWidget extends StatefulWidget {
  final String message;
  final PushType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _PushWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_PushWidget> createState() => _PushWidgetState();
}

class _PushWidgetState extends State<_PushWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    Future.delayed(widget.duration + const Duration(milliseconds: 300), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color color = switch (widget.type) {
      PushType.success => cs.primary,
      PushType.error => cs.error,
      PushType.info => cs.secondary,
    };

    return GestureDetector(
      onTap: _dismiss,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slide.value * 56),
            child: Opacity(
              opacity: 1 - (_slide.value + 1).abs().clamp(0, 1),
              child: child,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          color: color.withValues(alpha: 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              widget.message,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
