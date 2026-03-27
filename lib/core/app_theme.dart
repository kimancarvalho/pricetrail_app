import 'package:flutter/material.dart';
import 'app_constants.dart';

/// Define os temas claro e escuro da aplicação.
/// Centralizar aqui permite mudar o visual da app inteira num só lugar.
class AppTheme {
  AppTheme._();

  // Cor principal da app — mudar aqui afeta toda a app
  static const Color _primaryColor = Color(0xFF7C3AED);
  static const Color _secondaryColor = Color(0xFFEC4899);

  /// Tema claro
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _secondaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFFAF8FF),
    cardTheme: CardThemeData(
      elevation: AppConstants.elevationCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      color: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
    ),
  );

  /// Tema escuro
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _secondaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0A1E),
    cardTheme: CardThemeData(
      elevation: AppConstants.elevationCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      color: const Color(0xFF1E1535),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey,
      backgroundColor: Color(0xFF1E1535),
      elevation: 8,
    ),
  );
}
