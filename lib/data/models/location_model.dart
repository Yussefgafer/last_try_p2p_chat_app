import 'package:hive/hive.dart';

part 'location_model.g.dart';

/// Model for location data
@HiveType(typeId: 3)
class LocationModel extends HiveObject {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final double? accuracy;

  @HiveField(3)
  final double? altitude;

  @HiveField(4)
  final double? heading;

  @HiveField(5)
  final double? speed;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final String? address;

  @HiveField(8)
  final String? name;

  @HiveField(9)
  final String? description;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    required this.timestamp,
    this.address,
    this.name,
    this.description,
  });

  /// Create LocationModel from JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      address: json['address'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
    );
  }

  /// Convert LocationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'heading': heading,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
      'name': name,
      'description': description,
    };
  }

  /// Create a copy with updated fields
  LocationModel copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
    DateTime? timestamp,
    String? address,
    String? name,
    String? description,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  /// Get formatted coordinates string
  String get coordinatesString => '$latitude, $longitude';

  /// Get formatted accuracy string
  String get accuracyString {
    if (accuracy == null) return 'Unknown accuracy';
    return '±${accuracy!.round()}m';
  }

  /// Get formatted altitude string
  String get altitudeString {
    if (altitude == null) return 'Unknown altitude';
    return '${altitude!.round()}m';
  }

  /// Get formatted speed string
  String get speedString {
    if (speed == null) return 'Unknown speed';
    final speedKmh = speed! * 3.6; // Convert m/s to km/h
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }

  /// Get display name (name or address or coordinates)
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (address != null && address!.isNotEmpty) return address!;
    return coordinatesString;
  }

  /// Check if location has high accuracy
  bool get isHighAccuracy {
    return accuracy != null && accuracy! <= 10.0;
  }

  /// Check if location is recent (within last hour)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours < 1;
  }

  @override
  String toString() {
    return 'LocationModel(lat: $latitude, lng: $longitude, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.accuracy == accuracy &&
        other.altitude == altitude &&
        other.heading == heading &&
        other.speed == speed &&
        other.timestamp == timestamp &&
        other.address == address &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^
        longitude.hashCode ^
        accuracy.hashCode ^
        altitude.hashCode ^
        heading.hashCode ^
        speed.hashCode ^
        timestamp.hashCode ^
        address.hashCode ^
        name.hashCode ^
        description.hashCode;
  }
}
