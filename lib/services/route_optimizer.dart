import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/list_item.dart';
import '../models/store.dart';
import '../services/store_service.dart';
import '../services/product_service.dart';

/// Resultado da optimização de rota
class OptimizedRoute {
  /// Lojas ordenadas pela ordem de visita
  final List<Store> storesInOrder;

  /// Poupança total estimada em relação a comprar tudo no mesmo sítio
  final double estimatedSavings;

  /// Custo total optimizado
  final double totalCost;

  OptimizedRoute({
    required this.storesInOrder,
    required this.estimatedSavings,
    required this.totalCost,
  });
}

/// Serviço responsável por calcular a rota optimizada.
class RouteOptimizer {
  RouteOptimizer._();

  /// Calcula a rota optimizada para uma lista de items.
  ///
  /// Estratégia:
  /// 1. Para cada item, atribui-o à loja mais barata nas proximidades
  /// 2. Ordena as lojas pelo algoritmo Nearest Neighbour
  static Future<OptimizedRoute> optimize({
    required List<ListItem> items,
    required LatLng userLocation,
  }) async {
    // Busca lojas próximas
    final nearbyStores = await StoreService.getNearbyStores(userLocation);

    if (nearbyStores.isEmpty || items.isEmpty) {
      return OptimizedRoute(
        storesInOrder: [],
        estimatedSavings: 0,
        totalCost: 0,
      );
    }

    // Mapa de storeId → lista de items a comprar lá
    final Map<String, List<ListItem>> storeItems = {};

    double totalOptimizedCost = 0;
    double totalWorstCaseCost = 0;

    // Para cada item, encontra a loja mais barata
    for (final item in items) {
      final prices = ProductService.getSimulatedPrices(item.productId);

      // Filtra só os preços de lojas que estão nas proximidades
      final availablePrices = prices
          .where((p) => nearbyStores.any((s) => s.id == p.storeId))
          .toList();

      if (availablePrices.isEmpty) {
        // Se não há loja próxima com este produto, usa o preço médio
        totalOptimizedCost += item.averagePrice;
        totalWorstCaseCost += item.averagePrice;
        continue;
      }

      // Ordena por preço crescente
      availablePrices.sort((a, b) => a.price.compareTo(b.price));

      final cheapest = availablePrices.first;
      final mostExpensive = availablePrices.last;

      // Acumula custo optimizado vs pior caso
      totalOptimizedCost += cheapest.price;
      totalWorstCaseCost += mostExpensive.price;

      // Adiciona o item à loja mais barata
      storeItems.putIfAbsent(cheapest.storeId, () => []);
      storeItems[cheapest.storeId]!.add(item);
    }

    // Constrói a lista de lojas que têm items a comprar
    final storesToVisit = nearbyStores
        .where((s) => storeItems.containsKey(s.id))
        .map((s) => s.copyWith(itemsToBuy: storeItems[s.id]!))
        .toList();

    // Ordena as lojas pelo algoritmo Nearest Neighbour
    final orderedStores = _nearestNeighbour(
      stores: storesToVisit,
      startLocation: userLocation,
    );

    return OptimizedRoute(
      storesInOrder: orderedStores,
      estimatedSavings: totalWorstCaseCost - totalOptimizedCost,
      totalCost: totalOptimizedCost,
    );
  }

  /// Algoritmo Nearest Neighbour — ordena as lojas por distância
  /// começando sempre na mais próxima da posição actual.
  static List<Store> _nearestNeighbour({
    required List<Store> stores,
    required LatLng startLocation,
  }) {
    if (stores.isEmpty) return [];

    final remaining = List<Store>.from(stores);
    final ordered = <Store>[];
    LatLng currentLocation = startLocation;

    while (remaining.isNotEmpty) {
      // Encontra a loja mais próxima da posição actual
      Store nearest = remaining.first;
      double nearestDistance = _distanceBetween(
        currentLocation,
        nearest.location,
      );

      for (final store in remaining) {
        final distance = _distanceBetween(currentLocation, store.location);
        if (distance < nearestDistance) {
          nearest = store;
          nearestDistance = distance;
        }
      }

      // Move para a loja mais próxima
      ordered.add(nearest);
      currentLocation = nearest.location;
      remaining.remove(nearest);
    }

    return ordered;
  }

  /// Calcula distância em metros entre dois pontos
  static double _distanceBetween(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }
}
