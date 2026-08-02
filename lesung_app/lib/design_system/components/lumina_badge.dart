import 'package:flutter/material.dart';
import '../tokens/lumina_colors.dart';
import '../tokens/lumina_radius.dart';

/// Badge / Tag Lumina
class LuminaBadge extends StatelessWidget {
  final String label;
  final LuminaBadgeColor color;
  final bool isPill;

  const LuminaBadge({
    super.key,
    required this.label,
    this.color = LuminaBadgeColor.primary,
    this.isPill = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    switch (color) {
      case LuminaBadgeColor.primary:
        bg = isDark ? LuminaColorsDark.primarySubtle : LuminaColors.primarySubtle;
        fg = isDark ? LuminaColorsDark.primary : LuminaColors.primary;
      case LuminaBadgeColor.accent:
        bg = isDark ? LuminaColorsDark.accentSubtle : LuminaColors.accentSubtle;
        fg = isDark ? LuminaColorsDark.accent : LuminaColors.accent;
      case LuminaBadgeColor.secondary:
        bg = isDark ? LuminaColorsDark.secondarySubtle : LuminaColors.secondarySubtle;
        fg = isDark ? LuminaColorsDark.secondary : LuminaColors.secondary;
      case LuminaBadgeColor.success:
        bg = isDark ? const Color(0xFF1A3D2E) : const Color(0xFFE8F5EE);
        fg = isDark ? LuminaColorsDark.success : LuminaColors.success;
      case LuminaBadgeColor.error:
        bg = isDark ? const Color(0xFF3D1A1A) : const Color(0xFFFDEDED);
        fg = isDark ? LuminaColorsDark.error : LuminaColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isPill ? LuminaRadius.full : LuminaRadius.xs),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

enum LuminaBadgeColor { primary, accent, secondary, success, error }
