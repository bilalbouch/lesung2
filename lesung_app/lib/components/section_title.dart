import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';

/// Titre de section — hiérarchie visuelle forte : serif, discret,
/// avec action optionnelle (« Tout voir ») tertiaire.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: AppSpacing.section,
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: textTheme.titleLarge, maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Text(
                  actionLabel!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
