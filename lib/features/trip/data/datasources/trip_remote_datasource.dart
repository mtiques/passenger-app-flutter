import 'package:dio/dio.dart';
import '../../domain/entities/trip.dart';

class TripRemoteDataSource {
  final Dio _dio;

  TripRemoteDataSource(this._dio);

  // 📍 Solicitar viaje
  Future<Trip> requestTrip(Map<String, dynamic> tripRequest) async {
    try {
      final response = await _dio.post('/trips', data: tripRequest);
      return Trip.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // 📍 Obtener viaje por ID
  Future<Trip> getTripById(int tripId) async {
    try {
      final response = await _dio.get('/trips/$tripId');
      return Trip.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // 📍 Cancelar viaje
  Future<void> cancelTrip(int tripId) async {
    try {
      await _dio.put('/trips/$tripId/status', data: {
        'status': 'CANCELLED',
      });
    } catch (e) {
      rethrow;
    }
  }

  // 📍 Obtener historial
  Future<List<Trip>> getTripHistory() async {
    try {
      final response = await _dio.get('/trips/history');
      final List<dynamic> data = response.data;
      return data.map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // 📍 Conductores cercanos (mock en backend)
  Future<List<Driver>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      final response = await _dio.get(
        '/drivers/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        },
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Driver.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
