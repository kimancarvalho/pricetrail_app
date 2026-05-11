import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/store.dart';

/// Serviço responsável por encontrar supermercados reais
/// nas proximidades do utilizador via Google Places API.
class StoreService {
  StoreService._();

  /// IDs das lojas que mapeamos para os nossos preços simulados.
  /// Usamos o nome da loja para identificar a cadeia.
  static const Map<String, String> _chainToId = {
    'continente': 'continente',
    'pingo doce': 'pingodoce',
    'lidl': 'lidl',
    'aldi': 'aldi',
    'intermarché': 'intermarche',
    'intermarch': 'intermarche',
    'mercadona': 'mercadona',
    'minipreço': 'minipreco',
    'minipreco': 'minipreco',
  };

  /// Devolve o storeId reconhecido pelo nome da loja.
  /// Se não reconhecer, devolve null.
  static String? _resolveStoreId(String storeName) {
    final lower = storeName.toLowerCase();
    for (final entry in _chainToId.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Busca supermercados reais nas proximidades via Google Places API.
  /// Filtra apenas as cadeias que têm preços simulados.
  static Future<List<Store>> getNearbyStores(
    LatLng userLocation, {
    double radiusMeters = 5000,
  }) async {
    final apiKey = 'AIzaSyDo8KSEiHtBhlotlnlVL9LmyurSdeg8eDA';

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${userLocation.latitude},${userLocation.longitude}'
      '&radius=$radiusMeters'
      '&type=supermarket'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        print('Places API error: ${response.statusCode}');
        return _getFallbackStores(userLocation);
      }

      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>? ?? [];

      final stores = <Store>[];

      for (final place in results) {
        final name = place['name'] as String? ?? '';
        final storeId = _resolveStoreId(name);

        // Ignora lojas que não reconhecemos
        if (storeId == null) continue;

        final lat = place['geometry']['location']['lat'] as double;
        final lng = place['geometry']['location']['lng'] as double;
        final location = LatLng(lat, lng);

        final distanceMeters = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          lat,
          lng,
        );

        stores.add(
          Store(
            id: storeId,
            name: name,
            location: location,
            distanceKm: distanceMeters / 1000,
          ),
        );
      }

      // Remove duplicados da mesma cadeia — fica só a mais próxima
      final seen = <String>{};
      final unique = stores.where((s) => seen.add(s.id)).toList();

      // Ordena por distância
      unique.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      print('Places API: ${unique.length} lojas reconhecidas');
      for (final s in unique) {
        print('  ${s.id} — ${s.name} — ${s.distanceKm.toStringAsFixed(1)} km');
      }

      // Se não encontrou nenhuma loja reconhecida usa fallback
      if (unique.isEmpty) return _getFallbackStores(userLocation);

      return unique;
    } catch (e) {
      print('Places API exception: $e');
      return _getFallbackStores(userLocation);
    }
  }

  /// Lojas de fallback centradas na localização do utilizador
  /// usadas quando a Places API falha ou não encontra lojas reconhecidas.
  static List<Store> _getFallbackStores(LatLng userLocation) {
    print('A usar lojas de fallback centradas na localização actual');

    // Gera lojas em volta da localização actual com offsets pequenos
    return [
      Store(
        id: 'continente',
        name: 'Continente (simulado)',
        location: LatLng(
          userLocation.latitude + 0.008,
          userLocation.longitude - 0.012,
        ),
        distanceKm: 1.2,
      ),
      Store(
        id: 'pingodoce',
        name: 'Pingo Doce (simulado)',
        location: LatLng(
          userLocation.latitude - 0.005,
          userLocation.longitude + 0.007,
        ),
        distanceKm: 0.8,
      ),
      Store(
        id: 'lidl',
        name: 'Lidl (simulado)',
        location: LatLng(
          userLocation.latitude + 0.003,
          userLocation.longitude + 0.015,
        ),
        distanceKm: 1.5,
      ),
      Store(
        id: 'aldi',
        name: 'Aldi (simulado)',
        location: LatLng(
          userLocation.latitude - 0.010,
          userLocation.longitude - 0.008,
        ),
        distanceKm: 1.1,
      ),
    ];
  }
}
