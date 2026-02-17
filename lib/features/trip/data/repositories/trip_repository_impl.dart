import 'package:logger/logger.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_datasource.dart';
import '../../../../core/network/websocket_service.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDataSource _remoteDataSource;
  final WebSocketService _webSocketService;
  final Logger _logger = Logger();

  TripRepositoryImpl({
    required TripRemoteDataSource remoteDataSource,
    required WebSocketService webSocketService,
  })  : _remoteDataSource = remoteDataSource,
        _webSocketService = webSocketService;

  @override
  Future<Trip> requestTrip({
    required Location origin,
    required Location destination,
  }) async {
    try {
      _logger.i(
          '🚗 Requesting trip from ${origin.address} to ${destination.address}');

      final tripRequest = {
        'origin': origin.toJson(),
        'destination': destination.toJson(),
      };

      final trip = await _remoteDataSource.requestTrip(tripRequest);

      _logger.i('✅ Trip requested successfully: ${trip.id}');
      return trip;
    } catch (e) {
      _logger.e('❌ Error requesting trip: $e');
      rethrow;
    }
  }

  @override
  Future<Trip> getTripById(int tripId) async {
    try {
      _logger.i('📍 Getting trip: $tripId');
      final trip = await _remoteDataSource.getTripById(tripId);
      return trip;
    } catch (e) {
      _logger.e('❌ Error getting trip: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelTrip(int tripId) async {
    try {
      _logger.i('❌ Cancelling trip: $tripId');
      await _remoteDataSource.cancelTrip(tripId);
      _logger.i('✅ Trip cancelled successfully');
    } catch (e) {
      _logger.e('❌ Error cancelling trip: $e');
      rethrow;
    }
  }

  @override
  Stream<Trip> watchTripUpdates(int tripId) {
    _logger.i('👀 Watching trip updates: $tripId');

    // El backend Spring Boot emitirá eventos WebSocket como:
    // { "event": "trip_update_${tripId}", "data": {...} }
    return _webSocketService
        .on<Map<String, dynamic>>('trip_update_$tripId')
        .map((data) => Trip.fromJson(data));
  }

  @override
  Future<List<Trip>> getTripHistory() async {
    try {
      _logger.i('📜 Getting trip history');
      final trips = await _remoteDataSource.getTripHistory();
      return trips;
    } catch (e) {
      _logger.e('❌ Error getting trip history: $e');
      rethrow;
    }
  }

  @override
  Future<List<Driver>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusInKm = 5.0,
  }) async {
    try {
      _logger.i('🚕 Getting nearby drivers at ($latitude, $longitude)');
      final drivers = await _remoteDataSource.getNearbyDrivers(
        latitude: latitude,
        longitude: longitude,
        radius: radiusInKm,
      );
      _logger.i('✅ Found ${drivers.length} nearby drivers');
      return drivers;
    } catch (e) {
      _logger.e('❌ Error getting nearby drivers: $e');
      rethrow;
    }
  }
}
