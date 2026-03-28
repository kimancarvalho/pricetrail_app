/// Modelo que representa o resumo mensal de poupanças do utilizador.
class MonthlySummary {
  final double totalSpent;
  final double totalSaved;
  final double previousMonthSaved;
  final String month;

  MonthlySummary({
    required this.totalSpent,
    required this.totalSaved,
    required this.previousMonthSaved,
    required this.month,
  });

  /// Percentagem de poupança em relação ao mês anterior
  double get savingsGrowth {
    if (previousMonthSaved == 0) return 0;
    return ((totalSaved - previousMonthSaved) / previousMonthSaved) * 100;
  }

  /// Converte um documento Firestore num objeto MonthlySummary
  factory MonthlySummary.fromFirestore(Map<String, dynamic> data) {
    return MonthlySummary(
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      totalSaved: (data['totalSaved'] ?? 0).toDouble(),
      previousMonthSaved: (data['previousMonthSaved'] ?? 0).toDouble(),
      month: data['month'] ?? '',
    );
  }
}
