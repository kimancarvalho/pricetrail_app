import 'package:flutter/material.dart';
import 'app_constants.dart';

/// Define o tema visual da aplicação PriceTrail.
/// Centralizar aqui permite mudar o visual da app inteira num só lugar.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppConstants.backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: AppConstants.primaryColor,
      secondary: AppConstants.primaryLight,
      error: AppConstants.errorColor,
      surface: AppConstants.surfaceColor,
    ),
    // Estilo global dos cards
    cardTheme: CardThemeData(
      elevation: AppConstants.elevationCard,
      color: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        side: const BorderSide(color: AppConstants.borderColor),
      ),
    ),
    // Estilo global dos botões primários
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.surfaceColor,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        textStyle: const TextStyle(
          fontSize: AppConstants.fontSizeBody,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    // Estilo global dos campos de texto
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.surfaceColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppConstants.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppConstants.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(
          color: AppConstants.primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppConstants.errorColor),
      ),
    ),
    // Estilo global da AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.backgroundColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppConstants.textPrimary,
        fontSize: AppConstants.fontSizeTitle,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppConstants.textPrimary),
    ),
    // Estilo global do BottomNavigationBar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppConstants.surfaceColor,
      selectedItemColor: AppConstants.primaryColor,
      unselectedItemColor: AppConstants.textSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
