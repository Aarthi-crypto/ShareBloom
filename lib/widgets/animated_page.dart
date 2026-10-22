import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class AnimatedPage extends StatelessWidget {
  final Widget child;
  const AnimatedPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, animation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: child,
    );
  }
}