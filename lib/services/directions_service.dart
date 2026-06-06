import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Serviço responsável por calcular rotas reais entre pontos
/// usando a Google Routes API.
class DirectionsService {
  DirectionsService._();

  /// Calcula os pontos de uma rota real entre vários waypoints.
  /// Devolve uma lista de coordenadas que seguem estradas reais.
  static Future<List<LatLng>> getRoutePoints({
    required LatLng origin,
    required List<LatLng> waypoints,
  }) async {
    if (waypoints.isEmpty) return [];

    final apiKey = 'AIzaSyDo8KSEiHtBhlotlnlVL9LmyurSdeg8eDA';

    // O destino é o último waypoint
    // Os intermediários são os restantes
    final destination = waypoints.last;
    final intermediates = waypoints.length > 1
        ? waypoints.sublist(0, waypoints.length - 1)
        : <LatLng>[];

    final body = jsonEncode({
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          },
        },
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          },
        },
      },
      // Waypoints intermédios lojas a visitar pelo caminho
      if (intermediates.isNotEmpty)
        'intermediates': intermediates
            .map(
              (point) => {
                'location': {
                  'latLng': {
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                  },
                },
              },
            )
            .toList(),
      'travelMode': 'DRIVE',
      'routingPreference': 'TRAFFIC_AWARE',
    });

    try {
      final response = await http
          .post(
            Uri.parse(
              'https://routes.googleapis.com/directions/v2:computeRoutes',
            ),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': apiKey,
              // Campos que queremos na resposta
              'X-Goog-FieldMask':
                  'routes.polyline.encodedPolyline,routes.duration,routes.distanceMeters',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('Routes API error: ${response.statusCode} — ${response.body}');
        return [];
      }

      final data = jsonDecode(response.body);
      final routes = data['routes'] as List<dynamic>?;

      if (routes == null || routes.isEmpty) return [];

      // Descodifica a polyline encodada
      final encodedPolyline =
          routes[0]['polyline']['encodedPolyline'] as String;
      return _decodePolyline(encodedPolyline);
    } catch (e) {
      print('Routes API exception: $e');
      return [];
    }
  }

  /// Descodifica uma polyline encodada no formato Google
  /// em lista de coordenadas LatLng.
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;

      // Descodifica latitude
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      shift = 0;
      result = 0;

      // Descodifica longitude
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      lng += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
