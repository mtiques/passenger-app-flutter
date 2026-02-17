import '../entities/trip.dart';

abstract class TripRepository {
  /// Solicitar un nuevo viaje
  Future<Trip> requestTrip({
    required Location origin,
    required Location destination,
  });

  /// Obtener el estado actual de un viaje
  Future<Trip> getTripById(int tripId);

  /// Cancelar un viaje
  Future<void> cancelTrip(int tripId);

  /// Escuchar actualizaciones en tiempo real de un viaje (WebSocket)
  Stream<Trip> watchTripUpdates(int tripId);

  /// Obtener historial de viajes del usuario
  Future<List<Trip>> getTripHistory();

  /// Obtener conductores disponibles cerca (mock)
  Future<List<Driver>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusInKm = 5.0,
  });
}
