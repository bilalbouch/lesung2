import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_icons.dart';
import '../design_system/tokens/app_motion.dart';

/// Bouton favori avec micro-interaction : l'icône « bat » brièvement
/// lors de l'activation (scale 1 -> 1.2 -> 1 en 200 ms maximum).
class FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback? onToggle;
  final double size;

  const FavoriteButton({
    super.key,
    required this.isFavorite,
    this.onToggle,
    this.size = AppIcons.sizeL,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return IconButton(
      onPressed: onToggle,
      iconSize: size,
      icon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: isFavorite ? 1 : 1),
        duration: AppDurations.normal,
        builder: (context, _, __) => AnimatedSwitcher(
          duration: AppDurations.fast,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: Icon(
            isFavorite ? AppIcons.favoriteFilled : AppIcons.favorite,
            key: ValueKey(isFavorite),
            color: isFavorite ? colors.accent : colors.inkSecondary,
          ),
        ),
      ),
    );
  }
}
