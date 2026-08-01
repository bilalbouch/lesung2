import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';

/// Bouton d'action — trois variantes, une seule source de style.
enum ActionButtonVariant { primary, secondary, ghost }

class ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ActionButtonVariant variant;
  final bool expanded;

  const ActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = ActionButtonVariant.primary,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(fontWeight: FontWeight.w600);

    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          AppSpacing.hGapS,
        ],
        Flexible(child: Text(label, style: textStyle, maxLines: 1,
            overflow: TextOverflow.ellipsis)),
      ],
    );

    return switch (variant) {
      ActionButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.onAccent,
            disabledBackgroundColor: colors.accentSubtle,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.m),
            shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.button),
          ),
          child: child,
        ),
      ActionButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.ink,
            side: BorderSide(color: colors.divider),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.m),
            shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.button),
          ),
          child: child,
        ),
      ActionButtonVariant.ghost => TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.accent,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l, vertical: AppSpacing.m),
          ),
          child: child,
        ),
    };
  }
}
