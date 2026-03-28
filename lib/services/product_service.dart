import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/store_price.dart';

/// Serviço responsável por pesquisar produtos via Open Food Facts API
/// e simular preços por loja via dados locais.
class ProductService {
  ProductService._();

  static const String _baseUrl = 'https://world.openfoodfacts.org';

  /// Pesquisa produtos por nome ou código de barras
  static Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      '$_baseUrl/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}'
      '&search_simple=1&action=process&json=1&page_size=20'
      '&fields=code,product_name,brands,image_front_url,quantity,categories_tags',
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': 'PriceTrail/1.0'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final products = data['products'] as List<dynamic>? ?? [];

      // Filtra produtos sem nome para não mostrar resultados vazios
      return products
          .map((p) => Product.fromOpenFoodFacts(p))
          .where((p) => p.name.isNotEmpty && p.name != 'Unknown Product')
          .toList();
    } else {
      throw Exception('Error searching products: ${response.statusCode}');
    }
  }

  /// Simula preços por loja para um produto
  /// Em produção real estes dados viriam do Firestore
  static List<StorePrice> getSimulatedPrices(String productId) {
    // Gera preços simulados mas realistas baseados no ID do produto
    final basePrice = (productId.hashCode.abs() % 500) / 100 + 0.50;

    return [
      StorePrice(
        storeId: 'continente',
        storeName: 'Continente',
        price: double.parse((basePrice * 1.05).toStringAsFixed(2)),
        isPromotion: false,
        isStoreBrand: false,
      ),
      StorePrice(
        storeId: 'pingodoce',
        storeName: 'Pingo Doce',
        price: double.parse((basePrice * 0.98).toStringAsFixed(2)),
        isPromotion: true,
        isStoreBrand: false,
      ),
      StorePrice(
        storeId: 'lidl',
        storeName: 'Lidl',
        price: double.parse((basePrice * 0.85).toStringAsFixed(2)),
        isPromotion: false,
        isStoreBrand: true,
      ),
      StorePrice(
        storeId: 'aldi',
        storeName: 'Aldi',
        price: double.parse((basePrice * 0.88).toStringAsFixed(2)),
        isPromotion: false,
        isStoreBrand: true,
      ),
    ];
  }
}
