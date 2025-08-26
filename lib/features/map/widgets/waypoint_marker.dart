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

  const WaypointMarker({
    super.key,
    required this.point,
    required this.index,
    this.isDraggable = false,
    this.onTap,
    this.onDragEnd,
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
    if (index == 0) {
      return AppColors.elevationGain; // Start point - green
    } else if (isDraggable) {
      return AppColors.summitOrange; // Draggable waypoint - orange
    } else {
      return AppColors.pathBlue; // End point - blue
    }
  }

  Widget _buildWaypointIcon() {
    if (index == 0) {
      return const Icon(
        Icons.flag,
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

  const EditableWaypointLayer({
    super.key,
    required this.points,
    this.onWaypointDragged,
    this.onWaypointTapped,
    this.showWaypoints = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showWaypoints || points.length < 2) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(
      markers: points.asMap().entries.map((entry) {
        final index = entry.key;
        final point = entry.value;
        final isEndpoint = index == 0 || index == points.length - 1;

        return Marker(
          point: point,
          width: 22,
          height: 22,
          child: WaypointMarker(
            point: point,
            index: index,
            isDraggable: !isEndpoint,
            onTap: () => onWaypointTapped?.call(index),
            onDragEnd: (newPoint) => onWaypointDragged?.call(index, newPoint),
          ),
        );
      }).toList(),
    );
  }
}
