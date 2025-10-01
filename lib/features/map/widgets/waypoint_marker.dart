import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

class WaypointMarker extends StatefulWidget {
  final LatLng point;
  final int index;
  final bool isDraggable;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(LatLng)? onDragEnd;
  final bool isLoop;
  final int totalPoints;

  const WaypointMarker({
    super.key,
    required this.point,
    required this.index,
    this.isDraggable = false,
    this.onTap,
    this.onLongPress,
    this.onDragEnd,
    this.isLoop = false,
    required this.totalPoints,
  });

  @override
  State<WaypointMarker> createState() => _WaypointMarkerState();
}

class _WaypointMarkerState extends State<WaypointMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    // Start animation with a slight delay based on index for stagger effect
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onPanEnd: widget.isDraggable && widget.onDragEnd != null
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
        ),
      ),
    );
  }

  Color _getWaypointColor() {
    if (widget.index == 0 && widget.isLoop) {
      return AppColors.pathBlue; // Start/End point for loop - blue
    } else if (widget.index == 0) {
      return AppColors.elevationGain; // Start point - green
    } else if (widget.index == widget.totalPoints - 1 && !widget.isLoop) {
      return AppColors.errorRed; // End point - red
    } else if (widget.isDraggable) {
      return AppColors.summitOrange; // Draggable waypoint - orange
    } else {
      return AppColors.pathBlue; // Other waypoints - blue
    }
  }

  Widget _buildWaypointIcon() {
    if (widget.index == 0 && widget.isLoop) {
      return const Icon(
        Icons.refresh, // Start/End point for loop - refresh icon
        color: AppColors.textInverse,
        size: 12,
      );
    } else if (widget.index == 0) {
      return const Icon(
        Icons.flag, // Start point - flag
        color: AppColors.textInverse,
        size: 12,
      );
    } else if (widget.index == widget.totalPoints - 1 && !widget.isLoop) {
      return const Icon(
        Icons.stop, // End point - stop icon
        color: AppColors.textInverse,
        size: 12,
      );
    } else if (widget.isDraggable) {
      return Text(
        '${widget.index + 1}',
        style: const TextStyle(
          color: AppColors.textInverse,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
        '${widget.index + 1}',
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
  final Function(int)? onWaypointLongPressed;
  final bool showWaypoints;
  final bool showEndpoints; // Always show start/end points

  const EditableWaypointLayer({
    super.key,
    required this.points,
    this.onWaypointDragged,
    this.onWaypointTapped,
    this.onWaypointLongPressed,
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
              onLongPress: () => onWaypointLongPressed?.call(i),
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
