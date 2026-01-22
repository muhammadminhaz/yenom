import 'package:flutter/material.dart';

class AppConstants {
  // Golden Ratio
  static const double goldenRatio = 1.61803398875;

  // Spacing based on Golden Ratio
  static const double spaceUnit = 8.0;
  static const double spaceXS = spaceUnit / goldenRatio; // ~5.0
  static const double spaceS = spaceUnit; // 8.0
  static const double spaceM = spaceUnit * goldenRatio; // ~13.0
  static const double spaceL = spaceM * goldenRatio; // ~21.0
  static const double spaceXL = spaceL * goldenRatio; // ~34.0
  static const double spaceXXL = spaceXL * goldenRatio; // ~55.0
  static const double spaceXXXL = spaceXXL * goldenRatio; // ~89.0

  // Border Radius based on Golden Ratio
  static const double radiusS = spaceM;
  static const double radiusM = spaceL;
  static const double radiusL = spaceXL;

  // Typography Hierarchy (Scale based on Golden Ratio)
  static const double fontXS = 10.0;
  static const double fontS = 12.0;
  static const double fontM = 14.0;
  static const double fontL = fontM * 1.2; // 16.8
  static const double fontXL = fontL * 1.2; // 20.16
  static const double fontXXL = fontXL * 1.2; // 24.19
  static const double fontXXXL = fontXXL * 1.2; // 29.0
}

class AppColors {
  // Primary Green
  static const Color primaryGreen = Color(0xFF2ECC71);
  static const Color primaryGreenDark = Color(0xFF27AE60);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFE0E5EC);
  static const Color lightShadow = Colors.white;
  static const Color darkShadow = Color(0xFFA3B1C6);
  static const Color lightTextPrimary = Color(0xFF444444);
  static const Color lightTextSecondary = Color(0xFF777777);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF2D3436);
  static const Color darkShadowLight = Color(0xFF3C4447);
  static const Color darkShadowDark = Color(0xFF1E2324);
  static const Color darkTextPrimary = Color(0xFFF1F2F6);
  static const Color darkTextSecondary = Color(0xFFA4B0BE);
  
  // Transaction Types
  static const Color expenseRed = Color(0xFFE74C3C);
  static const Color incomeGreen = primaryGreen;
}
