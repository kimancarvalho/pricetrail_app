/// Representa o preço de um produto numa loja específica.
class StorePrice {
  final String storeId;
  final String storeName;
  final double price;
  final bool isPromotion;
  final bool isStoreBrand;

  StorePrice({
    required this.storeId,
    required this.storeName,
    required this.price,
    required this.isPromotion,
    required this.isStoreBrand,
  });

  factory StorePrice.fromFirestore(Map<String, dynamic> data) {
    return StorePrice(
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      isPromotion: data['isPromotion'] ?? false,
      isStoreBrand: data['isStoreBrand'] ?? false,
    );
  }
}
