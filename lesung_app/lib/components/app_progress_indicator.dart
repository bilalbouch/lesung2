import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_radius.dart';

/// Indicateurs de progression — discrets, accent uniquement.
class AppProgressIndicator extends StatelessWidget {
  /// 0..1, ou null pour indéterminé.
  final double? value;
  final double height;

  const AppProgressIndicator({super.key, this.value, this.height = 3});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: colors.surfaceAlt,
        valueColor: AlwaysStoppedAnimation(colors.accent),
      ),
    );
  }
}

/// Petite roue de chargement centrée.
class AppLoadingSpinner extends StatelessWidget {
  const AppLoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}
