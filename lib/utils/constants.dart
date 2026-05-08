import 'package:flutter/material.dart';

/// App constants and theme configuration
class AppConstants {
  // App Info
  static const String appName = 'TalkNotify';
  static const String appVersion = '1.3.0';

  // Supported Apps
  static const List<String> supportedApps = [
    'WhatsApp',
    'SMS',
    'Telegram',
    'Messenger',
    'Instagram',
  ];

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF03A9F4);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
}

/// Theme Data
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppConstants.primaryColor,
    scaffoldBackgroundColor: AppConstants.lightBackground,
    colorScheme: const ColorScheme.light(
      primary: AppConstants.primaryColor,
      secondary: AppConstants.secondaryColor,
      surface: AppConstants.lightSurface,
      error: AppConstants.errorColor,
    ),
    cardTheme: CardTheme(
      color: AppConstants.lightCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppConstants.primaryColor,
    scaffoldBackgroundColor: AppConstants.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppConstants.primaryColor,
      secondary: AppConstants.secondaryColor,
      surface: AppConstants.darkSurface,
      error: AppConstants.errorColor,
    ),
    cardTheme: CardTheme(
      color: AppConstants.darkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
