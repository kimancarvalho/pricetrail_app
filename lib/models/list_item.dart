import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa um produto adicionado a uma lista de compras.
class ListItem {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final double averagePrice;
  final bool isChecked;

  ListItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.averagePrice,
    required this.isChecked,
  });

  factory ListItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListItem(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImageUrl: data['productImageUrl'] ?? '',
      averagePrice: (data['averagePrice'] ?? 0).toDouble(),
      isChecked: data['isChecked'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'averagePrice': averagePrice,
      'isChecked': isChecked,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }
}
