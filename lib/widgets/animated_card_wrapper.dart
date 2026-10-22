import 'package:flutter/material.dart';

class AnimatedCardWrapper extends StatefulWidget {
  final Widget child;
  final bool keepAlive;

  const AnimatedCardWrapper({
    super.key,
    required this.child,
    this.keepAlive = false,
  });

  @override
  State<AnimatedCardWrapper> createState() => _AnimatedCardWrapperState();
}

class _AnimatedCardWrapperState extends State<AnimatedCardWrapper> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, hover ? -3 : 0),
        child: widget.child,
      ),
    );
  }
}