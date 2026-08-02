import 'package:flutter/material.dart';

/// Skeleton loader avec effet shimmer.
/// Usage: remplacer le contenu pendant le chargement.
class LuminaSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const LuminaSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  @override
  State<LuminaSkeleton> createState() => _LuminaSkeletonState();
}

class _LuminaSkeletonState extends State<LuminaSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A211E) : const Color(0xFFF5F2ED);
    final highlightColor = isDark ? const Color(0xFF242C28) : const Color(0xFFFFFFFF);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _controller.value * 2, 0),
              end: Alignment(0 + _controller.value * 2, 0),
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
          ),
        );
      },
    );
  }
}

/// Card skeleton pour les livres
class LuminaBookSkeleton extends StatelessWidget {
  const LuminaBookSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LuminaSkeleton(height: 180, radius: 16),
        SizedBox(height: 12),
        LuminaSkeleton(height: 16, width: 120),
        SizedBox(height: 8),
        LuminaSkeleton(height: 12, width: 80),
      ],
    );
  }
}
