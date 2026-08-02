import 'package:flutter/material.dart';
import '../tokens/lumina_colors.dart';
import '../tokens/lumina_radius.dart';

/// Boutons Lumina — Primary, Secondary, Ghost, Icon
class LuminaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final LuminaButtonVariant variant;
  final IconData? icon;
  final bool expanded;

  const LuminaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = LuminaButtonVariant.primary,
    this.icon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );

    if (expanded) {
      child = SizedBox(width: double.infinity, child: Center(child: child));
    }

    switch (variant) {
      case LuminaButtonVariant.primary:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? LuminaColorsDark.primary : LuminaColors.primary,
            foregroundColor: LuminaColors.textInverse,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LuminaRadius.s),
            ),
          ),
          child: child,
        );
      case LuminaButtonVariant.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? LuminaColorsDark.textPrimary : LuminaColors.textPrimary,
            side: BorderSide(
              color: isDark ? LuminaColorsDark.border : LuminaColors.border,
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LuminaRadius.s),
            ),
          ),
          child: child,
        );
      case LuminaButtonVariant.ghost:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: isDark ? LuminaColorsDark.primary : LuminaColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: child,
        );
    }
  }
}

enum LuminaButtonVariant { primary, secondary, ghost }

/// IconButton Lumina
class LuminaIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;

  const LuminaIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? LuminaColorsDark.primary : LuminaColors.primary;
    final bgColor = isActive
        ? (isDark ? LuminaColorsDark.primarySubtle : LuminaColors.primarySubtle)
        : Colors.transparent;
    final iconColor = isActive
        ? activeColor
        : (isDark ? LuminaColorsDark.textSecondary : LuminaColors.textSecondary);

    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}
