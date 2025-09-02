import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/map_layers.dart';
import '../../../core/theme/app_colors.dart';

class RouteMapPreview extends StatelessWidget {
  final List<LatLng> points;

  const RouteMapPreview({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final bounds = points.isNotEmpty ? LatLngBounds.fromPoints(points) : null;
    final center = bounds == null
        ? const LatLng(52.3676, 4.9041)
        : LatLng(
            (bounds.north + bounds.south) / 2,
            (bounds.east + bounds.west) / 2,
          );
    double initialZoom = 13;
    if (bounds != null) {
      final latDiff = (bounds.north - bounds.south).abs();
      final lngDiff = (bounds.east - bounds.west).abs();
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
      if (maxDiff > 0.1) initialZoom = 10; // large
      else if (maxDiff > 0.05) initialZoom = 12; // medium
      else if (maxDiff > 0.01) initialZoom = 14; // small
      else initialZoom = 16; // very small
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: AbsorbPointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: initialZoom,
              interactionOptions: const InteractionOptions(enableMultiFingerGestureRace: false, flags: InteractiveFlag.none),
            ),
            children: [
              TileLayer(
                urlTemplate: MapLayerType.openStreetMap.urlTemplate,
                userAgentPackageName: 'com.example.pathify',
                additionalOptions: const {'attribution': ''},
              ),
              if (points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 4,
                      color: AppColors.activeRoute,
                    )
                  ],
                ),
              // Start and end point markers
              if (points.isNotEmpty)
                MarkerLayer(
                  markers: [
                    // Start point marker (green)
                    Marker(
                      point: points.first,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.trailGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                    // End point marker (red)
                    if (points.length > 1)
                      Marker(
                        point: points.last,
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
