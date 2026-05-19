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
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    Future.delayed(widget.duration + const Duration(milliseconds: 250), () {
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
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          alignment: Alignment.center,
          child: ScaleTransition(
            scale: _scale,
            child: GestureDetector(
              onTap: () {},
              child: Card(
                color: cs.surfaceContainerHigh,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        switch (widget.type) {
                          PushType.success => Icons.check_circle,
                          PushType.error => Icons.error,
                          PushType.info => Icons.info,
                        },
                        size: 48,
                        color: color,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
