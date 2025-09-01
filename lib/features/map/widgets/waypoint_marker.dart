import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

class WaypointMarker extends StatelessWidget {
  final LatLng point;
  final int index;
  final bool isDraggable;
  final VoidCallback? onTap;
  final Function(LatLng)? onDragEnd;
  final bool isLoop;
  final int totalPoints;

  const WaypointMarker({
    super.key,
    required this.point,
    required this.index,
    this.isDraggable = false,
    this.onTap,
    this.onDragEnd,
    this.isLoop = false,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanEnd: isDraggable && onDragEnd != null
          ? (details) {
              // This is a simplified drag - in a real implementation,
              // you'd need to convert screen coordinates to map coordinates
              // For now, we'll handle this in the parent widget
            }
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo ring for better visibility
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getWaypointColor().withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
          // Core marker
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _getWaypointColor(),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textInverse,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: _buildWaypointIcon()),
          ),
        ],
      ),
    );
  }

  Color _getWaypointColor() {
    if (index == 0 && isLoop) {
      return AppColors.pathBlue; // Start/End point for loop - blue
    } else if (index == 0) {
      return AppColors.elevationGain; // Start point - green
    } else if (index == totalPoints - 1 && !isLoop) {
      return AppColors.errorRed; // End point - red
    } else if (isDraggable) {
      return AppColors.summitOrange; // Draggable waypoint - orange
    } else {
      return AppColors.pathBlue; // Other waypoints - blue
    }
  }

  Widget _buildWaypointIcon() {
    if (index == 0 && isLoop) {
      return const Icon(
        Icons.refresh, // Start/End point for loop - refresh icon
        color: AppColors.textInverse,
        size: 12,
      );
    } else if (index == 0) {
      return const Icon(
        Icons.flag, // Start point - flag
        color: AppColors.textInverse,
        size: 12,
      );
    } else if (index == totalPoints - 1 && !isLoop) {
      return const Icon(
        Icons.stop, // End point - stop icon
        color: AppColors.textInverse,
        size: 12,
      );
    } else if (isDraggable) {
      return Text(
        '${index + 1}',
        style: const TextStyle(
          color: AppColors.textInverse,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
        '${index + 1}',
        style: const TextStyle(
          color: AppColors.textInverse,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }
}

class EditableWaypointLayer extends StatelessWidget {
  final List<LatLng> points;
  final Function(int, LatLng)? onWaypointDragged;
  final Function(int)? onWaypointTapped;
  final bool showWaypoints;
  final bool showEndpoints; // Always show start/end points

  const EditableWaypointLayer({
    super.key,
    required this.points,
    this.onWaypointDragged,
    this.onWaypointTapped,
    this.showWaypoints = false,
    this.showEndpoints = true,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox.shrink();
    }

    // Check if route is a loop (start and end points are close)
    final isLoop = _isRouteLoop(points);

    final markersToShow = <Marker>[];
    
    for (int i = 0; i < points.length; i++) {
      final isEndpoint = i == 0 || i == points.length - 1;
      final shouldShow = showWaypoints || (showEndpoints && isEndpoint);
      
      if (shouldShow) {
        markersToShow.add(
          Marker(
            point: points[i],
            width: 22,
            height: 22,
            child: WaypointMarker(
              point: points[i],
              index: i,
              isDraggable: !isEndpoint,
              onTap: () => onWaypointTapped?.call(i),
              onDragEnd: (newPoint) => onWaypointDragged?.call(i, newPoint),
              isLoop: isLoop,
              totalPoints: points.length,
            ),
          ),
        );
      }
    }

    return MarkerLayer(markers: markersToShow);
  }

  bool _isRouteLoop(List<LatLng> points) {
    if (points.length < 2) return false;
    
    final start = points.first;
    final end = points.last;
    
    // Calculate distance using Haversine formula
    const double earthRadius = 6371000; // meters
    final double dLat = (end.latitude - start.latitude) * (3.14159 / 180);
    final double dLon = (end.longitude - start.longitude) * (3.14159 / 180);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * pi / 180) *
        cos(end.latitude * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;
    
    return distance < 30; // Within 30 meters
  }
}
