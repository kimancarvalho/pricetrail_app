/// Constantes globais da aplicação ScentExplorer.
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

  // --- Tamanhos de fonte ---
  static const double fontSizeSmall = 12.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeTitle = 18.0;
  static const double fontSizeHeading = 28.0;

  // --- Raios de bordas ---
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;

  // --- Elevações ---
  static const double elevationCard = 3.0;

  // --- Proporções relativas ---
  /// Altura da imagem do card em relação à altura do ecrã
  static const double cardImageHeightRatio = 0.16;

  // --- Pesquisa ---
  /// Tempo de espera em ms antes de disparar a pesquisa após o utilizador parar de escrever
  static const int searchDebounceMs = 500;

  ///Identidade Visual (Cores)
  static const String primaryColor = '#10B981'; //verde poupança
  static const String backgroundColor = '#F9FAFB'; //cinza claro
  static const String textColor = '#111827'; //preto suave
  static const String errorColor = '#EF4444'; //Vermelho
  static const String cautionColor = '#F59E0B'; //Amarelo
}
