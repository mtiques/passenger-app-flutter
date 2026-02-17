import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_providers.dart';
import '../widgets/driver_info_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();

  // Ubicación inicial por defecto (Jerez de la Frontera)
  static const LatLng _defaultLocation = LatLng(36.6866, -6.1368);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permissions are permanently denied');
        return;
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _currentPosition = position);

      // Mover cámara a ubicación actual
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );

      debugPrint('✅ Location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
    }
  }

  Set<Marker> _buildMarkers(Trip? trip) {
    final markers = <Marker>{};

    // Marcador de ubicación actual
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
        ),
      );
    }

    // Marcadores del viaje
    if (trip != null) {
      // Origen
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(trip.origin.latitude, trip.origin.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Origen',
            snippet: trip.origin.address ?? 'Punto de partida',
          ),
        ),
      );

      // Destino
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position:
              LatLng(trip.destination.latitude, trip.destination.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: 'Destino',
            snippet: trip.destination.address ?? 'Punto de llegada',
          ),
        ),
      );

      // Conductor (si está asignado)
      if (trip.driver?.currentLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: LatLng(
              trip.driver!.currentLocation!.latitude,
              trip.driver!.currentLocation!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: trip.driver!.name,
              snippet: 'Tu conductor',
            ),
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(Trip? trip) {
    if (trip == null) return {};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(trip.origin.latitude, trip.origin.longitude),
          LatLng(trip.destination.latitude, trip.destination.longitude),
        ],
        color: Colors.blue,
        width: 5,
        patterns: [
          PatternItem.dash(20),
          PatternItem.gap(10),
        ],
      ),
    };
  }

  // Centrar el mapa para mostrar origen y destino
  void _fitBounds(Trip trip) {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        trip.origin.latitude < trip.destination.latitude
            ? trip.origin.latitude
            : trip.destination.latitude,
        trip.origin.longitude < trip.destination.longitude
            ? trip.origin.longitude
            : trip.destination.longitude,
      ),
      northeast: LatLng(
        trip.origin.latitude > trip.destination.latitude
            ? trip.origin.latitude
            : trip.destination.latitude,
        trip.origin.longitude > trip.destination.longitude
            ? trip.origin.longitude
            : trip.destination.longitude,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripNotifierProvider);

    // Centrar mapa cuando hay viaje
    tripState.whenData((trip) {
      if (trip != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _fitBounds(trip);
        });
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ Google Maps Real
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude)
                  : _defaultLocation,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _buildMarkers(tripState.value),
            polylines: _buildPolylines(tripState.value),
            padding: const EdgeInsets.only(bottom: 350, top: 100),
          ),

          // 🔘 Botón de centrar ubicación
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // 📍 Bottom Sheet
          _buildBottomSheet(tripState),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(AsyncValue<Trip?> tripState) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: tripState.when(
            data: (trip) {
              if (trip == null) {
                return _buildLocationInputSheet(scrollController);
              }
              return _buildTripContent(trip, scrollController);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(tripNotifierProvider);
                      },
                      child: const Text('Intentar de nuevo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationInputSheet(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '¿A dónde vamos?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildLocationField(
          controller: _originController,
          label: 'Origen',
          icon: Icons.trip_origin,
          iconColor: Colors.green,
          hint: 'Mi ubicación actual',
        ),
        const SizedBox(height: 16),
        _buildLocationField(
          controller: _destinationController,
          label: 'Destino',
          icon: Icons.location_on,
          iconColor: Colors.red,
          hint: 'Ingresa destino',
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _requestTrip,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Solicitar viaje',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTripContent(Trip trip, ScrollController scrollController) {
    switch (trip.status) {
      case TripStatus.requested:
        return _buildSearchingSheet(scrollController);
      case TripStatus.accepted:
      case TripStatus.driverArriving:
      case TripStatus.inProgress:
        return SingleChildScrollView(
          controller: scrollController,
          child: DriverInfoCard(trip: trip),
        );
      case TripStatus.completed:
        return _buildCompletedSheet(scrollController, trip);
      case TripStatus.cancelled:
        return _buildCancelledSheet(scrollController);
    }
  }

  Widget _buildSearchingSheet(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 24),
        const Text(
          'Buscando conductor...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Esto puede tomar unos segundos',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCompletedSheet(ScrollController scrollController, Trip trip) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          '¡Viaje completado!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => ref.invalidate(tripNotifierProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Solicitar otro viaje'),
        ),
      ],
    );
  }

  Widget _buildCancelledSheet(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Icon(Icons.cancel, size: 80, color: Colors.red),
        const SizedBox(height: 24),
        const Text(
          'Viaje cancelado',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => ref.invalidate(tripNotifierProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Solicitar nuevo viaje'),
        ),
      ],
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: iconColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  void _requestTrip() {
    if (_originController.text.isEmpty) {
      _originController.text = 'Mi ubicación actual';
    }

    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un destino')),
      );
      return;
    }

    final origin = Location(
      latitude: _currentPosition?.latitude ?? _defaultLocation.latitude,
      longitude: _currentPosition?.longitude ?? _defaultLocation.longitude,
      address: _originController.text,
    );

    final destination = Location(
      latitude: origin.latitude + 0.01,
      longitude: origin.longitude + 0.01,
      address: _destinationController.text,
    );

    ref.read(tripNotifierProvider.notifier).requestTrip(
          origin: origin,
          destination: destination,
        );
  }
}
