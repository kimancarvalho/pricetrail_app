import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../settings/app_constants.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/route_optimizer.dart';

class RouteScreen extends StatefulWidget {
  final String? listId;
  final String? listName;
  final int itemCount;

  const RouteScreen({
    super.key,
    this.listId,
    this.listName,
    this.itemCount = 0,
  });

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  GoogleMapController? _mapController;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  OptimizedRoute? _optimizedRoute;
  bool _isLoading = true;
  String? _errorMessage;

  // Índice da loja actualmente seleccionada no bottom sheet
  int _selectedStoreIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.listId != null) _calculateRoute();
  }

  /// Carrega os items, a localização e calcula a rota optimizada
  Future<void> _calculateRoute() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Obtém localização real
    final userLocation = await LocationService.getCurrentLocation();
    if (userLocation == null) {
      setState(() {
        _errorMessage = 'Não foi possível obter a tua localização.';
        _isLoading = false;
      });
      return;
    }

    // Busca os items da lista no Firestore
    final items = await DatabaseService.getListItemsOnce(
      userId: _userId,
      listId: widget.listId!,
    );

    if (items.isEmpty) {
      setState(() {
        _errorMessage = 'A lista está vazia.';
        _isLoading = false;
      });
      return;
    }

    // Calcula a rota optimizada
    final route = await RouteOptimizer.optimize(
      items: items,
      userLocation: userLocation,
    );

    setState(() {
      _optimizedRoute = route;
      _isLoading = false;
    });

    // Centra o mapa na localização do utilizador
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLocation, 14));
  }

  /// Constrói os marcadores utilizador + lojas da rota
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final stores = _optimizedRoute?.storesInOrder ?? [];

    // Marcadores das lojas com número de ordem
    for (int i = 0; i < stores.length; i++) {
      final store = stores[i];
      markers.add(
        Marker(
          markerId: MarkerId(store.id),
          position: store.location,
          infoWindow: InfoWindow(
            title: '${i + 1}. ${store.name}',
            snippet:
                '${store.itemsToBuy.length} itens • €${store.totalCost.toStringAsFixed(2)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == _selectedStoreIndex
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueOrange,
          ),
          onTap: () => setState(() => _selectedStoreIndex = i),
        ),
      );
    }

    return markers;
  }

  /// Constrói a polyline da rota entre lojas
  Set<Polyline> _buildPolylines() {
    if (_optimizedRoute == null) return {};

    final stores = _optimizedRoute!.storesInOrder;
    if (stores.isEmpty) return {};

    // Pontos da rota — começamos do utilizador
    // Por agora ligamos os pontos directamente (sem directions API)
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        color: AppConstants.primaryColor,
        width: 4,
        points: stores.map((s) => s.location).toList(),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.listId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Seleciona uma lista\npara ver a rota.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Rota: ${widget.listName}'),
        actions: [
          // Botão de recalcular
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calculateRoute,
            tooltip: 'Recalcular rota',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(38.5226, -8.8383),
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _optimizedRoute != null ? _buildMarkers() : {},
            polylines: _optimizedRoute != null ? _buildPolylines() : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Loading
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Erro
          if (_errorMessage != null && !_isLoading)
            Center(
              child: Container(
                margin: const EdgeInsets.all(AppConstants.spacingL),
                padding: const EdgeInsets.all(AppConstants.spacingL),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppConstants.errorColor,
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: AppConstants.spacingM),
                    ElevatedButton(
                      onPressed: _calculateRoute,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom sheet com resultado da rota
          if (_optimizedRoute != null && !_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildRouteBottomSheet(),
            ),
        ],
      ),
    );
  }

  /// Bottom sheet com resumo da rota e lojas a visitar
  Widget _buildRouteBottomSheet() {
    final route = _optimizedRoute!;

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusM),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppConstants.borderColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Resumo — poupança estimada
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${route.storesInOrder.length} lojas a visitar',
                    style: const TextStyle(
                      fontSize: AppConstants.fontSizeBody,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  Text(
                    'Total: €${route.totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: AppConstants.fontSizeSmall,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
              // Badge de poupança
              if (route.estimatedSavings > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: AppConstants.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                  child: Text(
                    'Poupa €${route.estimatedSavings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppConstants.surfaceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: AppConstants.fontSizeSmall,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingM),
          const Divider(color: AppConstants.borderColor),
          const SizedBox(height: AppConstants.spacingS),

          // Lista de lojas em ordem de visita
          ...route.storesInOrder.asMap().entries.map((entry) {
            final index = entry.key;
            final store = entry.value;
            final isSelected = index == _selectedStoreIndex;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedStoreIndex = index);
                // Centra o mapa na loja seleccionada
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(store.location, 16),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryLight
                      : AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    // Número de ordem
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppConstants.primaryColor
                            : AppConstants.borderColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isSelected
                                ? AppConstants.surfaceColor
                                : AppConstants.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: AppConstants.fontSizeSmall,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: AppConstants.fontSizeBody,
                              color: isSelected
                                  ? AppConstants.primaryColor
                                  : AppConstants.textPrimary,
                            ),
                          ),
                          Text(
                            '${store.itemsToBuy.length} itens • ${store.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: AppConstants.fontSizeSmall,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '€${store.totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
