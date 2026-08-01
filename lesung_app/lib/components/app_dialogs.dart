import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import 'action_button.dart';

/// Dialogues unifiés — titre serif, actions alignées à droite,
/// transition discrète ≤ 200 ms.
class AppDialogs {
  const AppDialogs._();

  /// Dialogue de confirmation. Retourne true si confirmé.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Bestätigen',
    String cancelLabel = 'Abbrechen',
    bool destructive = false,
  }) async {
    final colors = AppColors.of(context);
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: colors.scrim,
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, __) => AlertDialog(
        title: Text(title),
        content: Text(message,
            style: Theme.of(context).textTheme.bodyLarge),
        actions: [
          ActionButton(
            label: cancelLabel,
            variant: ActionButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ActionButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppMotion.standard),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(parent: animation, curve: AppMotion.enter)),
          child: child,
        ),
      ),
    );
    return result ?? false;
  }

  /// Dialogue avec champ texte (nouvelle collection, renommer...).
  /// Retourne le texte saisi ou null si annulé.
  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    String hint = '',
    String initialValue = '',
    String confirmLabel = 'Speichern',
  }) async {
    final colors = AppColors.of(context);
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      barrierColor: colors.scrim,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          ActionButton(
            label: 'Abbrechen',
            variant: ActionButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
          ActionButton(
            label: confirmLabel,
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return null;
    return result;
  }
}
