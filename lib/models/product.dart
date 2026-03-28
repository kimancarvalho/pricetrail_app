/// Modelo que representa um produto pesquisado via Open Food Facts API.
class Product {
  final String id;
  final String name;
  final String brand;
  final String imageUrl;
  final String quantity;
  final List<String> categories;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.quantity,
    required this.categories,
  });

  /// Converte a resposta da Open Food Facts API num objeto Product
  factory Product.fromOpenFoodFacts(Map<String, dynamic> json) {
    return Product(
      id: json['code'] ?? '',
      name: json['product_name'] ?? 'Unknown Product',
      brand: json['brands'] ?? 'Unknown Brand',
      imageUrl: json['image_front_url'] ?? '',
      quantity: json['quantity'] ?? '',
      categories: json['categories_tags'] != null
          ? List<String>.from(
              json['categories_tags'],
            ).map((c) => c.replaceAll('en:', '')).take(3).toList()
          : [],
    );
  }
}
