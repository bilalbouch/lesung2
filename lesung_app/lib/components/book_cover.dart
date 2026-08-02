import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../design_system/tokens/lumina_radius.dart';


/// Couverture de livre — l'ÉLÉMENT PRINCIPAL du design.
///
/// Image réseau avec cache ; en l'absence d'URL ou d'image, un
/// monogramme élégant sur fond teinté prend le relais (jamais de
/// rectangle gris générique).
class BookCover extends StatelessWidget {
  final String? coverUrl;
  final String title;
  final double width;

  /// Ratio couverture classique 2:3.
  static const double aspectRatio = 2 / 3;

  const BookCover({
    super.key,
    required this.title,
    this.coverUrl,
    this.width = 120,
    this.heroTag,
  });

  final String? heroTag;

  double get height => width / aspectRatio;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(LuminaRadius.l);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
        color: colors.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: coverUrl != null && coverUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: coverUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _Monogram(title: title),
              errorWidget: (_, __, ___) => _Monogram(title: title),
            )
          : _Monogram(title: title),
    );
  }
}

class _Monogram extends StatelessWidget {
  final String title;

  const _Monogram({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = title
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
