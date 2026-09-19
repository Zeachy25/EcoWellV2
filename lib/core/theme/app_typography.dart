import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized typography definitions for EcoWell
class AppTypography {
  AppTypography._();

  static const TextStyle brandHeader = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: 'serif',
    color: AppColors.forestDark,
    letterSpacing: 0.2,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textGreenTitle,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: 'serif',
    color: AppColors.forestDark,
    letterSpacing: 0.1,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static const TextStyle weatherTemp = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w300,
    fontFamily: 'serif',
    color: Colors.white,
    letterSpacing: -1.0,
  );

  static const TextStyle quietScoreHero = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    fontFamily: 'serif',
    color: AppColors.forestDark,
    letterSpacing: -0.5,
  );
}
