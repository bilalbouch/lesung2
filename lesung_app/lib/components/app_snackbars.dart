import 'package:flutter/material.dart';

import '../design_system/tokens/app_icons.dart';
import '../design_system/tokens/lumina_colors.dart';

/// Snackbars unifiées — discrètes, flottantes, une icône sémantique.
class AppSnackbars {
  const AppSnackbars._();

  static void success(BuildContext context, String message) =>
      _show(context, message, AppIcons.check);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppIcons.error, isError: true);

  static void info(BuildContext context, String message) =>
      _show(context, message, null);

  static void _show(BuildContext context, String message, IconData? icon,
      {bool isError = false}) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppIcons.sizeS,
                color: isError ? colors.error : LuminaColors.success,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.surface),
              ),
            ),
          ],
        ),
      ));
  }
}
