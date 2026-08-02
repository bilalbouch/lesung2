import 'package:flutter/material.dart';
import '../tokens/lumina_colors.dart';
import '../tokens/lumina_radius.dart';

/// Champ de recherche Lumina
class LuminaSearchInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  const LuminaSearchInput({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? LuminaColorsDark.surface : LuminaColors.surface,
        hintText: hint ?? 'Rechercher...',
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDark ? LuminaColorsDark.textTertiary : LuminaColors.textTertiary,
            ),
        prefixIcon: Icon(
          Icons.search,
          size: 20,
          color: isDark ? LuminaColorsDark.textTertiary : LuminaColors.textTertiary,
        ),
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.s),
          borderSide: BorderSide(
            color: isDark ? LuminaColorsDark.border : LuminaColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.s),
          borderSide: BorderSide(
            color: isDark ? LuminaColorsDark.border : LuminaColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.s),
          borderSide: BorderSide(
            color: isDark ? LuminaColorsDark.primary : LuminaColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
