import 'package:flutter/material.dart';

/// Constantes globais da aplicação PriceTrail.
/// Centralizar aqui evita números mágicos espalhados pelo código
/// e facilita alterações futuras num único lugar.
class AppConstants {
  AppConstants._(); // impede instanciação — é uma classe utilitária

  // --- Espaçamentos base ---
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 32.0;

  // --- Tamanhos de fonte ---
  static const double fontSizeSmall = 12.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeTitle = 18.0;
  static const double fontSizeHeading = 24.0;
  static const double fontSizeDisplay = 32.0;

  // --- Raios de bordas ---
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;

  // --- Elevações ---
  static const double elevationCard = 2.0;
  static const double elevationModal = 8.0;

  // --- Identidade Visual (Cores) ---
  // Usar Color em vez de String para compatibilidade direta com Flutter
  static const Color primaryColor = Color(0xFF10B981); // verde poupança
  static const Color primaryLight = Color.fromRGBO(
    209,
    250,
    229,
    1,
  ); // verde claro (chips, badges)
  static const Color backgroundColor = Color(
    0xFFF9FAFB,
  ); // cinza claro de fundo
  static const Color surfaceColor = Color(
    0xFFFFFFFF,
  ); // branco — cards e modais
  static const Color textPrimary = Color(0xFF111827); // preto suave — títulos
  static const Color textSecondary = Color(0xFF6B7280); // cinza — subtítulos
  static const Color errorColor = Color(0xFFEF4444); // vermelho — erros
  static const Color cautionColor = Color(0xFFF59E0B); // amarelo — avisos
  static const Color borderColor = Color(0xFFE5E7EB); // cinza claro — bordas

  // --- Pesquisa ---
  /// Tempo de espera em ms antes de disparar a pesquisa
  /// após o utilizador parar de escrever (debounce)
  static const int searchDebounceMs = 500;

  // --- Navegação ---
  /// Índices dos tabs do BottomNavigationBar
  static const int tabLists = 0;
  static const int tabExplore = 1;
  static const int tabRoute = 2;
  static const int tabProfile = 3;

  // --- Paginação ---
  /// Número de itens carregados por página nas listas
  static const int pageSize = 20;

  // --- Animações ---
  static const int animationFastMs = 150;
  static const int animationNormalMs = 300;
  static const int animationSlowMs = 500;

  // --- Assets ---
  static const String logoPath = 'assets/images/PriceTrail_Logo1024.png';
  static const String iconPath = 'assets/images/icons/PriceTrail_Icon.png';

  // --- Transporte ---
  static const String transportWalk = 'walk';
  static const String transportPublic = 'public';
  static const String transportCar = 'car';

  /// Opções de transporte para o seletor do registo
  static const List<Map<String, String>> transportOptions = [
    {'value': 'walk', 'label': 'Walk', 'icon': '🚶'},
    {'value': 'public', 'label': 'Transit', 'icon': '🚌'},
    {'value': 'car', 'label': 'Car', 'icon': '🚗'},
  ];

  // --- Filtros do Explore ---
  static const String filterAll = 'all';
  static const String filterPromotion = 'promotion';
  static const String filterStoreBrand = 'store_brand';

  static const List<Map<String, String>> filterOptions = [
    {'value': 'all', 'label': 'All'},
    {'value': 'promotion', 'label': 'Promotion'},
    {'value': 'store_brand', 'label': 'Store brand'},
  ];
}
