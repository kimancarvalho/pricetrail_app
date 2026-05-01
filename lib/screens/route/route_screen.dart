import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import '../../core/app_constants.dart';

class RouteScreen extends StatefulWidget {
  // Parâmetros para o ecrã saber que lista mostrar
  final String? listId;
  final String? listName;

  const RouteScreen({super.key, this.listId, this.listName});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  // Coordenadas do IPS em Setúbal para o mapa começar lá
  static const LatLng _ipsLocation = LatLng(38.5226, -8.8383);

  @override
  Widget build(BuildContext context) {
    // Se ainda não selecionaste uma lista na aba "Lists", mostramos um aviso
    if (widget.listId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Por favor, seleciona uma lista\n no menu "Lists" para ver a rota.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Rota: ${widget.listName}'),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _ipsLocation,
          zoom: 15,
        ),
        // Aqui é onde aparecerão os pins (marcadores) das lojas
        markers: {
          const Marker(
            markerId: MarkerId('ponto_partida'),
            position: _ipsLocation,
            infoWindow: InfoWindow(title: 'A tua localização (IPS)'),
          ),
        },
      ),
    );
  }
}