import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_icons.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';

/// Barre de recherche — sobre, coins discrets, effacement intégré.
class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Titel, Autor, ISBN…',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: colors.inkTertiary),
        prefixIcon:
            Icon(AppIcons.search, color: colors.inkSecondary, size: AppIcons.sizeM),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: Icon(AppIcons.close,
                      color: colors.inkSecondary, size: AppIcons.sizeS),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
        ),
        filled: true,
        fillColor: colors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l, vertical: AppSpacing.m),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.cardSmall,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.cardSmall,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardSmall,
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
      ),
    );
  }
}

/// Barre de recherche flottante — posée au-dessus du contenu avec une
/// élévation légère (écran de recherche, accueil).
class FloatingSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onTap;

  const FloatingSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Titel, Autor, ISBN…',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: AppSpacing.screen,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardSmall,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          absorbing: onTap != null,
          child: AppSearchBar(
            controller: controller,
            hint: hint,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }
}
