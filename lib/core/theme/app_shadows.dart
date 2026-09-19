import 'package:flutter/material.dart';

/// Centralized shadows for cards, buttons, and floating navigation
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0C000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardElevated = [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> buttonGreen = [
    BoxShadow(
      color: Color(0x3D1E5E41),
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> buttonOrange = [
    BoxShadow(
      color: Color(0x4DFF5722),
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x35000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> fab = [
    BoxShadow(
      color: Color(0x44227B4E),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}
