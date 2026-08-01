import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';

/// Bottom sheet unifiée — coins [AppRadius.sheet], poignée intégrée,
/// barrière teintée par les tokens.
class AppBottomSheet {
  const AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isScrollControlled = true,
  }) {
    final colors = AppColors.of(context);
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      barrierColor: colors.scrim,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.s,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
          ),
          child: child,
        ),
      ),
    );
  }

  /// En-tête standard d'une bottom sheet (titre serif + sous-titre).
  static Widget header(BuildContext context,
      {required String title, String? subtitle}) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: textTheme.titleLarge),
        if (subtitle != null) ...[
          AppSpacing.gapXs,
          Text(subtitle, style: textTheme.bodySmall),
        ],
        AppSpacing.gapL,
      ],
    );
  }
}
