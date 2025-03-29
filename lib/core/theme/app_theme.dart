import 'package:elctricity_info/core/theme/app_text.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
        primary: Color.fromARGB(255, 84, 92, 248),
        secondary: Color.fromARGB(255, 201, 155, 16)),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      titleTextStyle: AppTextStyles.headline3.copyWith(color: Colors.black),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: AppTextStyles.bodyText,
      hintStyle: AppTextStyles.smallHeadline,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
    ),
    textTheme: TextTheme(
      headlineLarge: AppTextStyles.headline3,
      headlineMedium: AppTextStyles.headline3,
      headlineSmall: AppTextStyles.headline3,
      titleLarge: AppTextStyles.largeHeadline,
      titleMedium: AppTextStyles.smallBodyText,
      titleSmall: AppTextStyles.smallBodyText,
      bodyLarge: AppTextStyles.mediumTitle,
      bodyMedium: AppTextStyles.bodyText,
      bodySmall: AppTextStyles.smallBodyText,
      labelLarge: AppTextStyles.mediumHeadline,
      labelMedium: AppTextStyles.mediumTitle,
      labelSmall: AppTextStyles.bodyText,
    ),
  );
}
