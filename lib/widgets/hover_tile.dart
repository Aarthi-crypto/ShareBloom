import 'package:flutter/material.dart';

class HoverTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool active;

  const HoverTile({
    super.key,
    required this.child,
    required this.onTap,
    required this.active,
  });

  @override
  State<HoverTile> createState() => _HoverTileState();
}

class _HoverTileState extends State<HoverTile> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.active
        ? Colors.lightBlue.withOpacity(0.12)
        : Colors.black.withOpacity(0.04);

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: hover
                ? Colors.lightBlue.withOpacity(0.14)
                : bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}