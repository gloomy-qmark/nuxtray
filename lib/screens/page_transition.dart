import 'package:flutter/material.dart';

Route smoothRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = Curves.easeInOutCubic;
      final tween = Tween<Offset>(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(CurveTween(curve: curve)),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
