import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa uma lista de compras do utilizador.
class ShoppingList {
  final String id;
  final String name;
  final int itemCount;
  final double estimatedTotal;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  ShoppingList({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.estimatedTotal,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
  });

  /// Converte um documento Firestore num objeto ShoppingList
  factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingList(
      id: doc.id,
      name: data['name'] ?? '',
      itemCount: data['itemCount'] ?? 0,
      estimatedTotal: (data['estimatedTotal'] ?? 0).toDouble(),
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converte um objeto ShoppingList para Map — para guardar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'itemCount': itemCount,
      'estimatedTotal': estimatedTotal,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }
}
