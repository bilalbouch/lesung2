import 'package:flutter/material.dart';

/// Widget qui ajoute un effet de pression (scale + opacity) au tap.
/// Usage: wrapper autour des boutons, cartes, list tiles.
class AnimatedPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const AnimatedPress({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedPress> createState() => _AnimatedPressState();
}

class _AnimatedPressState extends State<AnimatedPress> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.8 : 1.0,
          duration: widget.duration,
          child: widget.child,
        ),
      ),
    );
  }
}
