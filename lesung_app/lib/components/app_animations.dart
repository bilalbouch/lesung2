import 'package:flutter/material.dart';

import '../design_system/tokens/app_motion.dart';

/// Animations utilitaires — discrètes, ≤ 200 ms, jamais décoratives.
class AppAnimations {
  const AppAnimations._();

  /// Fondu d'apparition (changement d'état d'un contenu).
  static Widget fadeIn({required Widget child, Key? key}) =>
      TweenAnimationBuilder<double>(
        key: key,
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.fast,
        curve: AppMotion.standard,
        builder: (context, value, child) => Opacity(opacity: value, child: child),
        child: child,
      );

  /// Apparition en glissement vertical léger (listes, sections).
  static Widget slideUp({required Widget child, Key? key}) =>
      TweenAnimationBuilder<Offset>(
        key: key,
        tween: Tween(begin: const Offset(0, 0.04), end: Offset.zero),
        duration: AppDurations.normal,
        curve: AppMotion.enter,
        builder: (context, value, child) => FractionalTranslation(
          translation: value,
          child: child,
        ),
        child: child,
      );

  /// Transition d'état standard (remplace un contenu par un autre).
  static Widget crossFade({required Widget child}) => AnimatedSwitcher(
        duration: AppDurations.fast,
        switchInCurve: AppMotion.standard,
        switchOutCurve: AppMotion.exit,
        child: child,
      );

  /// Micro-interaction de pression : scale 0.97 au contact.
  static Widget pressScale({
    required Widget child,
    required VoidCallback? onTap,
    BorderRadius? borderRadius,
  }) =>
      _PressScale(onTap: onTap, borderRadius: borderRadius, child: child);
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const _PressScale({required this.child, this.onTap, this.borderRadius});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppDurations.instant,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}
