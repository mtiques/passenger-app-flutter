import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
class Trip with _$Trip {
  const factory Trip({
    required int id,
    required Location origin,
    required Location destination,
    required TripStatus status,
    Driver? driver,
    double? estimatedPrice,
    double? finalPrice,
    String? estimatedDuration,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}

@freezed
class Location with _$Location {
  const factory Location({
    required double latitude,
    required double longitude,
    String? address, // ✅ Opcional (antes era required)
    String? name,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
}

@freezed
class Driver with _$Driver {
  const factory Driver({
    required int id,
    required String name,
    @JsonKey(name: 'phoneNumber') required String phone,
    @JsonKey(name: 'licenseNumber') String? licenseNumber,
    @JsonKey(name: 'rating') @Default(0.0) double rating,
    String? email,
    String? photo,
    Location? currentLocation,
  }) = _Driver;

  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);
}

enum TripStatus {
  @JsonValue('REQUESTED')
  requested,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('DRIVER_ARRIVING')
  driverArriving,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('CANCELLED')
  cancelled,
}
