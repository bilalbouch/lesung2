import 'package:flutter/material.dart';

/// Widget qui anime l'entrée d'un item de liste avec stagger.
/// Usage: wrap chaque item dans une liste avec index.
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final delay = baseDelay * index;
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        final isReady = snapshot.connectionState == ConnectionState.done;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: isReady ? 1.0 : 0.0),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 12),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
