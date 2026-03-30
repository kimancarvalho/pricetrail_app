import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/store_price.dart';
import '../core/app_constants.dart';

/// Serviço responsável por pesquisar produtos via Open Food Facts API
/// e simular preços por loja via dados locais.
class ProductService {
  ProductService._();

  static const String _baseUrl = 'https://world.openfoodfacts.org';

  /// Lista de produtos mock para usar quando a API está indisponível
  static final List<Map<String, dynamic>> _mockProducts = [
    {
      'code': 'mock_001',
      'product_name': 'Fresh Vine Tomatoes',
      'brands': 'Nature\'s Best',
      'image_front_url': '',
      'quantity': '500g',
      'categories_tags': ['en:vegetables', 'en:fresh-produce'],
    },
    {
      'code': 'mock_002',
      'product_name': 'Whole Milk',
      'brands': 'Mimosa',
      'image_front_url': '',
      'quantity': '1L',
      'categories_tags': ['en:dairy', 'en:milk'],
    },
    {
      'code': 'mock_003',
      'product_name': 'Tomato Ketchup',
      'brands': 'Heinz',
      'image_front_url': '',
      'quantity': '570g',
      'categories_tags': ['en:condiments', 'en:sauces'],
    },
    {
      'code': 'mock_004',
      'product_name': 'Greek Yogurt',
      'brands': 'Activia',
      'image_front_url': '',
      'quantity': '400g',
      'categories_tags': ['en:dairy', 'en:yogurt'],
    },
    {
      'code': 'mock_005',
      'product_name': 'Sourdough Bread',
      'brands': 'Bimbo',
      'image_front_url': '',
      'quantity': '400g',
      'categories_tags': ['en:bakery', 'en:bread'],
    },
    {
      'code': 'mock_006',
      'product_name': 'Orange Juice',
      'brands': 'Compal',
      'image_front_url': '',
      'quantity': '1L',
      'categories_tags': ['en:beverages', 'en:juices'],
    },
    {
      'code': 'mock_007',
      'product_name': 'Pasta Spaghetti',
      'brands': 'Milaneza',
      'image_front_url': '',
      'quantity': '500g',
      'categories_tags': ['en:pasta', 'en:grains'],
    },
    {
      'code': 'mock_008',
      'product_name': 'Chicken Breast',
      'brands': 'Continente',
      'image_front_url': '',
      'quantity': '1kg',
      'categories_tags': ['en:meat', 'en:poultry'],
    },
  ];

  /// Filtra os produtos mock pela query do utilizador
  static List<Product> _searchMock(String query) {
    final q = query.toLowerCase();
    final filtered = _mockProducts
        .where(
          (p) =>
              p['product_name'].toString().toLowerCase().contains(q) ||
              p['brands'].toString().toLowerCase().contains(q) ||
              (p['categories_tags'] as List).any(
                (c) => c.toString().toLowerCase().contains(q),
              ),
        )
        .toList();

    // Se não há correspondência devolve todos os mock
    final results = filtered.isEmpty ? _mockProducts : filtered;
    return results.map((p) => Product.fromOpenFoodFacts(p)).toList();
  }

  /// Pesquisa produtos — tenta a API primeiro, usa mock se falhar
  static Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      '$_baseUrl/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}'
      '&search_simple=1&action=process&json=1&page_size=${AppConstants.pageSize}'
      '&fields=code,product_name,brands,image_front_url,quantity,categories_tags',
    );

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': 'PriceTrail/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['products'] as List<dynamic>? ?? [];
        final result = products
            .map((p) => Product.fromOpenFoodFacts(p))
            .where((p) => p.name.isNotEmpty && p.name != 'Unknown Product')
            .toList();

        // Se a API devolveu resultados usa-os
        if (result.isNotEmpty) return result;
      }

      // API falhou ou sem resultados — usa mock filtrado pela query
      return _searchMock(query);
    } catch (e) {
      // Qualquer erro de rede — usa mock
      return _searchMock(query);
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
