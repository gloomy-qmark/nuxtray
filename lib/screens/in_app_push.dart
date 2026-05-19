import 'dart:ui';
import 'package:flutter/material.dart';

enum PushType { success, error, info }

class InAppPush {
  static OverlayEntry? _current;

  static void show(BuildContext context, {
    required String message,
    PushType type = PushType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _current?.remove();
    final entry = OverlayEntry(
      builder: (context) => _PushWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () => _current?.remove(),
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
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    Future.delayed(widget.duration + const Duration(milliseconds: 400), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (Color bg, Color fg, IconData icon) = switch (widget.type) {
      PushType.success => (cs.primary, cs.onPrimary, Icons.check_circle_rounded),
      PushType.error => (cs.error, cs.onError, Icons.error_outline_rounded),
      PushType.info => (cs.secondary, cs.onSecondary, Icons.info_outline_rounded),
    };

    return GestureDetector(
      onTap: _dismiss,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? bg.withValues(alpha: 0.7)
                          : bg.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: fg.withValues(alpha: 0.25),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: fg.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 20, color: fg),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: fg.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.close_rounded, size: 16, color: fg),
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
      ),
    );
  }
}
