import 'package:latlong2/latlong.dart';
import '../../../core/constants/activity_types.dart';

class SavedRoute {
  final String id;
  final String name;
  final List<LatLng> points;
  final ActivityType activityType;
  final double distance; // in km
  final double estimatedTime; // in hours
  final DateTime createdAt;
  final String? description;
  final String? location; // approximate city/region

  SavedRoute({
    required this.id,
    required this.name,
    required this.points,
    required this.activityType,
    required this.distance,
    required this.estimatedTime,
    required this.createdAt,
    this.description,
    this.location,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'activityType': activityType.name,
      'distance': distance,
      'estimatedTime': estimatedTime,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'location': location,
    };
  }

  // Create from JSON
  factory SavedRoute.fromJson(Map<String, dynamic> json) {
    return SavedRoute(
      id: json['id'],
      name: json['name'],
      points: (json['points'] as List)
          .map((p) => LatLng(p['lat'], p['lng']))
          .toList(),
      activityType: ActivityType.values.firstWhere((e) => e.name == json['activityType']),
      distance: json['distance'],
      estimatedTime: json['estimatedTime'],
      createdAt: DateTime.parse(json['createdAt']),
      description: json['description'],
      location: json['location'],
    );
  }

  // Formatted strings for display
  String get formattedDistance {
    if (distance < 1.0) {
      return '${(distance * 1000).round()}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  String get formattedTime {
    if (estimatedTime < 1.0) {
      return '${(estimatedTime * 60).round()}min';
    } else {
      final hours = estimatedTime.floor();
      final minutes = ((estimatedTime - hours) * 60).round();
      return '${hours}h ${minutes}min';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inDays == 0) {
      return 'Vandaag';
    } else if (diff.inDays == 1) {
      return 'Gisteren';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} dagen geleden';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}