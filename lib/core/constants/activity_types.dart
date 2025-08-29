import 'package:flutter/material.dart';

enum ActivityType {
  walking,
  running,
  hiking,
  cycling,
}

extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.walking:
        return 'Wandelen';
      case ActivityType.running:
        return 'Hardlopen';
      case ActivityType.hiking:
        return 'Hiken';
      case ActivityType.cycling:
        return 'Fietsen';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.hiking:
        return Icons.hiking;
      case ActivityType.cycling:
        return Icons.directions_bike;
    }
  }

  String get routingProfile {
    switch (this) {
      case ActivityType.walking:
        return 'foot-walking';
      case ActivityType.running:
        return 'foot-walking';
      case ActivityType.hiking:
        return 'foot-hiking';
      case ActivityType.cycling:
        return 'cycling-regular';
    }
  }

  double get averageSpeed {
    switch (this) {
      case ActivityType.walking:
        return 5.0; // km/h
      case ActivityType.running:
        return 10.0; // km/h
      case ActivityType.hiking:
        return 4.0; // km/h
      case ActivityType.cycling:
        return 20.0; // km/h
    }
  }
}