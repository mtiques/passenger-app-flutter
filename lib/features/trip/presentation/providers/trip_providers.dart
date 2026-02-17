import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../data/datasources/trip_remote_datasource.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/websocket_service.dart';
import 'dart:async';

part 'trip_providers.g.dart';

// 🏭 Repository Provider
@Riverpod(keepAlive: true)
TripRepository tripRepository(TripRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  final webSocket = ref.watch(webSocketServiceProvider);

  return TripRepositoryImpl(
    remoteDataSource: TripRemoteDataSource(dio),
    webSocketService: webSocket,
  );
}

// 🎯 Trip State Notifier con Riverpod 3.0
@riverpod
class TripNotifier extends _$TripNotifier {
  @override
  AsyncValue<Trip?> build() {
    return const AsyncValue.data(null);
  }

  /// 1️⃣ Solicitar viaje
  Future<void> requestTrip({
    required Location origin,
    required Location destination,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      final trip = await repository.requestTrip(
        origin: origin,
        destination: destination,
      );

      // Iniciar escucha de actualizaciones en tiempo real
      _listenToTripUpdates(trip.id);

      return trip;
    });
  }

  /// 👂 Escuchar actualizaciones del viaje por WebSocket
  void _listenToTripUpdates(int tripId) {
    // ✅ Cambiado a int
    // Por ahora usamos polling cada 3 segundos
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final repository = ref.read(tripRepositoryProvider);
        final updatedTrip = await repository.getTripById(tripId);

        state = AsyncValue.data(updatedTrip);

        // Detener polling si el viaje terminó
        if (updatedTrip.status == TripStatus.completed ||
            updatedTrip.status == TripStatus.cancelled) {
          timer.cancel();
        }
      } catch (e) {
        // Si hay error, cancelar polling
        timer.cancel();
      }
    });
  }

  /// ❌ Cancelar viaje
  Future<void> cancelTrip(int tripId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      await repository.cancelTrip(tripId);
      return null;
    });
  }

  /// 🔄 Refrescar estado del viaje
  Future<void> refreshTrip(int tripId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      return await repository.getTripById(tripId);
    });
  }
}

// 📡 Stream Provider para actualizaciones en tiempo real
@riverpod
Stream<Trip> tripUpdatesStream(TripUpdatesStreamRef ref, int tripId) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.watchTripUpdates(tripId);
}

// 🚕 Nearby Drivers Provider
@riverpod
class NearbyDrivers extends _$NearbyDrivers {
  @override
  FutureOr<List<Driver>> build({
    required double latitude,
    required double longitude,
  }) async {
    final repository = ref.watch(tripRepositoryProvider);
    return repository.getNearbyDrivers(
      latitude: latitude,
      longitude: longitude,
    );
  }

  // Refrescar conductores cercanos
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      return repository.getNearbyDrivers(
        latitude: latitude,
        longitude: longitude,
      );
    });
  }
}

// 📜 Trip History Provider
@riverpod
Future<List<Trip>> tripHistory(TripHistoryRef ref) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getTripHistory();
}
