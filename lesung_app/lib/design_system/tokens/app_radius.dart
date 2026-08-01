import 'package:flutter/material.dart';

/// Tokens de rayon — coins discrets, jamais exagérés.
class AppRadius {
  const AppRadius._();

  static const double s = 6;
  static const double m = 10;
  static const double l = 14;
  static const double xl = 20;
  static const double full = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(l));
  static const BorderRadius cardSmall = BorderRadius.all(Radius.circular(m));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(xl));
  static const BorderRadius button = BorderRadius.all(Radius.circular(m));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(full));
  static const BorderRadius cover = BorderRadius.all(Radius.circular(s));
}
