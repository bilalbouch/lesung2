import 'package:flutter/material.dart';

/// Élévations Lumina
class LuminaShadows {
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> level4 = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 48,
      offset: Offset(0, 16),
    ),
  ];

  // Sombre : ombres plus subtiles
  static const List<BoxShadow> darkLevel1 = [
    BoxShadow(
      color: Color(0x07000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> darkLevel2 = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> darkLevel3 = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> darkLevel4 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 48,
      offset: Offset(0, 16),
    ),
  ];
}
