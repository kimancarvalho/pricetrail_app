import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Serviço responsável por obter a localização actual do utilizador.
class LocationService {
  LocationService._();

  /// Obtém a posição actual do utilizador.
  /// Pede permissão se ainda não foi concedida.
  static Future<LatLng?> getCurrentLocation() async {
    // Verifica se o serviço de localização está activo
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // Verifica e pede permissão
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    // Obtém a posição
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return LatLng(position.latitude, position.longitude);
  }
}
