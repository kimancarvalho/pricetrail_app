import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'list_item.dart';

/// Representa uma loja com localização e items a comprar.
class Store {
  final String id;
  final String name;
  final LatLng location;
  final double distanceKm;

  /// Items da lista que serão comprados nesta loja
  final List<ListItem> itemsToBuy;

  /// Custo total dos items nesta loja
  double get totalCost =>
      itemsToBuy.fold(0, (sum, item) => sum + item.averagePrice);

  Store({
    required this.id,
    required this.name,
    required this.location,
    required this.distanceKm,
    this.itemsToBuy = const [],
  });

  /// Cria uma cópia com items actualizados
  Store copyWith({List<ListItem>? itemsToBuy}) {
    return Store(
      id: id,
      name: name,
      location: location,
      distanceKm: distanceKm,
      itemsToBuy: itemsToBuy ?? this.itemsToBuy,
    );
  }
}
