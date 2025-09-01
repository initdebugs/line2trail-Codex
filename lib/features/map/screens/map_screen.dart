import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/activity_types.dart';
import '../../../core/constants/map_layers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/services/routing_service.dart';
import '../../../shared/services/haptic_feedback_service.dart';
import '../../routes/models/saved_route.dart';
import '../../routes/services/route_storage_service.dart';
import '../widgets/waypoint_marker.dart';
import '../widgets/route_bar.dart';
import '../widgets/route_tools.dart';
import '../widgets/map_control_rail.dart';
import '../widgets/draw_stats_panel.dart';
import '../widgets/km_marker.dart';
import '../widgets/roundtrip_generator_dialog.dart';
import '../widgets/map_search_bar.dart';
import '../models/route_drawing_state.dart';
import '../services/route_editing_service.dart';
import '../../../shared/services/geocoding_service.dart';
import '../../../shared/services/roundtrip_generation_service.dart' as slow_roundtrip;
import '../../../shared/services/fast_roundtrip_service.dart';

class MapScreen extends StatefulWidget {
  final VoidCallback? onRouteSaved;
  final SavedRoute? routeToLoad;
  final VoidCallback? onRouteLoaded;
  
  const MapScreen({super.key, this.onRouteSaved, this.routeToLoad, this.onRouteLoaded});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  ActivityType _selectedActivity = ActivityType.walking; // Start with walking for Phase 2 focus
  bool _isDrawingMode = false;
  List<LatLng> _currentRoute = [];
  List<LatLng> _snappedRoute = [];
  final Map<int, List<LatLng>> _snapCache = {};
  final RouteDrawingHistory _drawingHistory = RouteDrawingHistory();
  
  List<LatLng> _userTapPoints = []; // Track actual user tap locations for waypoints
  LatLng _currentLocation = const LatLng(37.7749, -122.4194); // Default fallback
  bool _locationLoading = true;
  bool _hasLocationPermission = false;
  bool _isSnapping = false;
  String _routingError = '';
  bool _showWaypoints = true;
  bool _allowMixedRouting = true; // Allow combining different transport modes
  MapLayerType _currentMapLayer = MapLayerType.openStreetMap;
  LatLng? _previewMarker; // Preview marker for first tap
  List<LatLng> _distanceMarkers = []; // Kilometer/mile markers along route
  
  // Roundtrip generator state
  bool _isRoundtripMode = false;
  ActivityType? _roundtripActivity;
  double? _roundtripDistance;
  RoundtripStrategy? _roundtripStrategy;
  bool _isGeneratingRoute = false;
  

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadSettings();
    // Test routing service when app starts
    RoutingService.testRouting();
    
    // Start background location tracking for better UX
    LocationService.startLocationTracking();
    
    // Load route if provided
    if (widget.routeToLoad != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadSavedRoute(widget.routeToLoad!);
        widget.onRouteLoaded?.call();
      });
    }
  }

  Future<void> _loadSettings() async {
    await SettingsService.init();
    final defaultActivity = SettingsService.getDefaultActivity();
    final showWaypoints = SettingsService.getWaypointsVisible();
    final mapLayerName = SettingsService.getMapLayer();
    final mapLayer = MapLayerHelper.fromString(mapLayerName);
    
    setState(() {
      _selectedActivity = defaultActivity;
      _showWaypoints = showWaypoints;
      _currentMapLayer = mapLayer;
    });
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if there's a new route to load
    if (widget.routeToLoad != null && widget.routeToLoad != oldWidget.routeToLoad) {
      // Defer the callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadSavedRoute(widget.routeToLoad!);
        widget.onRouteLoaded?.call();
      });
    }
  }


  Future<void> _initializeLocation() async {
    try {
      // Check for location permission first
      _hasLocationPermission = await LocationService.hasLocationPermission();
      
      // Get initial location (current or last known)
      final location = await LocationService.getInitialLocation();
      
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _locationLoading = false;
        });

        // Move map to the location
        _mapController.move(location, 15.0);
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      if (mounted) {
        setState(() {
          _locationLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (_isDrawingMode || _isRoundtripMode) ? _onMapTap : null,
              onMapEvent: (event) {
                // Save the map center when user moves the map
                if (event is MapEventMoveEnd) {
                  LocationService.updateLastLocation(event.camera.center);
                }
              },
            ),
            children: [
              // Tile layer
              TileLayer(
                urlTemplate: _currentMapLayer.urlTemplate,
                userAgentPackageName: 'com.example.pathify',
                retinaMode: RetinaMode.isHighDensity(context),
                additionalOptions: const {
                  'attribution': '',
                },
              ),
              // Route polyline (prefer snapped, then current)
              if (_snappedRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _snappedRoute,
                      strokeWidth: 5.0,
                      color: AppColors.activeRoute,
                      borderColor: AppColors.textInverse,
                      borderStrokeWidth: 1.0,
                    ),
                  ],
                )
              else if (_currentRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _currentRoute,
                      strokeWidth: 4.0,
                      color: _isDrawingMode ? AppColors.drawingRoute : AppColors.activeRoute,
                    ),
                  ],
                ),
              // Location marker (placeholder)
              // User location marker
              if (!_locationLoading)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.locationMarker,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textInverse,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.locationMarker.withValues(alpha: 0.3),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: AppColors.textInverse,
                          size: 14,
                        ),
                      ),
                    ),
                    // Preview marker for first tap
                    if (_previewMarker != null)
                      Marker(
                        point: _previewMarker!,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.pathBlue.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.textInverse,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.pathBlue.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_location_alt,
                            color: AppColors.textInverse,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              // Distance markers (place before waypoints to be visible)
              if (_distanceMarkers.isNotEmpty)
                MarkerLayer(
                  markers: [
                    ..._distanceMarkers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final markerPoint = entry.value;
                      final unitsSystem = SettingsService.getUnitsSystem();
                      final isMetric = unitsSystem == 'Metric';
                      // Calculate the actual distance for this marker
                      final markerDistance = (index + 1) * (isMetric ? 1.0 : 1.0);
                      final label = isMetric 
                        ? '${markerDistance.toInt()}k'
                        : '${markerDistance.toInt()}m';
                      return Marker(
                        point: markerPoint,
                        width: 22,
                        height: 22,
                        child: KmMarker(label: label),
                      );
                    }),
                  ],
                ),
              // Waypoint markers (show user tap points with endpoints always visible)
              EditableWaypointLayer(
                points: _userTapPoints,
                showWaypoints: _showWaypoints && _userTapPoints.isNotEmpty,
                showEndpoints: _userTapPoints.isNotEmpty, // Always show start/end when route exists
                onWaypointTapped: _onWaypointTapped,
                onWaypointDragged: _onWaypointDragged,
              ),
            ],
          ),

          // Roundtrip mode visual guidance (non-blocking)
          if (_isRoundtripMode) ...[
            // Top instruction banner
            Positioned(
              top: MediaQuery.of(context).padding.top + 80, // Below search bar area
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.trailGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.trailGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tik ergens op de kaart om je rondrit te starten',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Pulsing center indicator (non-blocking)
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 30,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.trailGreen.withValues(alpha: 0.2),
                          border: Border.all(
                            color: AppColors.trailGreen,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.trailGreen,
                          size: 24,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    // Restart the animation
                    if (_isRoundtripMode && mounted) {
                      setState(() {});
                    }
                  },
                ),
              ),
            ),
          ],

          // Search bar at the top (only when map is clean and not in special modes)
          if (!_isDrawingMode && !_isRoundtripMode && _currentRoute.isEmpty && _snappedRoute.isEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 80, // Leave space for location button (64px + 16px margin)
              child: MapSearchBar(
                isVisible: !_isDrawingMode && !_isRoundtripMode && _currentRoute.isEmpty && _snappedRoute.isEmpty,
                userLocation: _currentLocation,
                onLocationSelected: _onSearchLocationSelected,
              ),
            ),

          // New overlay UI per MapRedesign.md

          // Top-right compact map rail
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: MapControlRail(
              onLocate: _centerOnLocation,
              onLayers: _showLayerOptions,
            ),
          ),

          // Top-left draw stats when drawing/route exists
          if (_isDrawingMode || _currentRoute.isNotEmpty || _snappedRoute.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: DrawStatsPanel(
                distance: DistanceFormatter.formatDistance(_getTotalDistance()),
                time: _formatTime(_getEstimatedTime()),
                isLoading: _isSnapping,
              ),
            ),
          if (_routingError.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 64,
              left: 16,
              right: 88,
              child: _buildErrorChip(_routingError),
            ),

          // Bottom tool row (only when route exists)
          if (_currentRoute.isNotEmpty || _snappedRoute.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 80, // above route bar safe area (reduced since route bar is now more compact)
              child: RouteTools(
                onUndo: _undoLastPoint,
                onRedo: _redoLastPoint,
                onClear: _clearRoute,
                onMore: _showRouteEditingMenu,
                showWaypoints: _showWaypoints,
                onToggleWaypoints: _toggleWaypointMode,
                onLoopBack: _loopBackToStart,
                canLoopBack: _canLoopBack(),
              ),
            ),

          // Persistent bottom route bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RouteBar(
              selectedActivity: _selectedActivity,
              onActivityChanged: (a) {
                setState(() {
                  _selectedActivity = a;
                  _snapCache.clear();
                });
                if (_currentRoute.length >= 2) {
                  _snapCurrentRoute();
                }
              },
              isDrawing: _isDrawingMode,
              onToggleDraw: _toggleDrawingMode,
              onSave: _saveRoute,
              hasRoute: _currentRoute.isNotEmpty || _snappedRoute.isNotEmpty,
              onRoundtrip: _showRoundtripDialog,
              isRoundtripMode: _isRoundtripMode,
              onCancelRoundtrip: _cancelRoundtrip,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) async {
    if (_isRoundtripMode) {
      // Handle roundtrip start point selection
      await HapticFeedbackService.mediumImpact();
      
      // Show visual confirmation of selection
      setState(() {
        _previewMarker = point;
      });
      
      await _generateRoundtrip(point);
      return;
    }
    
    if (_isDrawingMode) {
      // Provide haptic feedback for map taps
      await HapticFeedbackService.lightImpact();
      
      if (_currentRoute.isEmpty && _previewMarker == null) {
        // First tap: show preview marker
        setState(() {
          _previewMarker = point;
          _routingError = '';
        });
      } else if (_currentRoute.isEmpty && _previewMarker != null) {
        // Second tap: start actual route with preview marker as first point
        setState(() {
          _currentRoute.add(_previewMarker!);
          _currentRoute.add(point);
          _userTapPoints.add(_previewMarker!);
          _userTapPoints.add(point);
          _previewMarker = null; // Clear preview marker
          _routingError = '';
          // Calculate distance markers for the initial route
          _distanceMarkers = _generateDistanceMarkers();
        });

        // Add to history
        _drawingHistory.addState(
          _currentRoute,
          'Started route with ${_currentRoute.length} points',
        );

        // Provide success feedback for route start
        await HapticFeedbackService.mediumImpact();
        
        // Snap the initial route segment
        await _snapCurrentRoute();
      } else {
        // Subsequent taps: continue adding to existing route
        setState(() {
          _currentRoute.add(point);
          _userTapPoints.add(point);
          _routingError = '';
          // Calculate distance markers for current route (even before snapping)
          _distanceMarkers = _generateDistanceMarkers();
        });

        // Add to history
        _drawingHistory.addState(
          _currentRoute,
          'Added point ${_currentRoute.length}',
        );

        
        await HapticFeedbackService.drawingFeedback();
        
        // Always snap after 2+ points
        await _snapCurrentRoute();
      }
    }
  }

  void _toggleDrawingMode() async {
    // Provide haptic feedback for mode toggle
    await HapticFeedbackService.selectionClick();
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (!_isDrawingMode) {
        // Clear preview marker when exiting drawing mode
        _previewMarker = null;
        if (_currentRoute.isNotEmpty && _snappedRoute.isEmpty) {
          // Snap to path when finishing drawing
          _snapCurrentRoute();
        }
      }
    });
  }

  Future<void> _snapCurrentRoute() async {
    if (_currentRoute.length < 2) return;

    setState(() {
      _isSnapping = true;
      _routingError = '';
    });

    try {
      debugPrint('🎯 Starting route snapping with ${_currentRoute.length} points for activity: $_selectedActivity');
      debugPrint('📍 Route points: ${_currentRoute.map((p) => '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}').join(' -> ')}');
      
      // Use mixed routing for better path coverage across different infrastructure types
      final snappedPoints = await RoutingService.snapToPathMixed(
        points: _currentRoute,
        primaryActivityType: _selectedActivity,
        allowMixedModes: _allowMixedRouting, // User-controlled mixed routing
      );
      
      debugPrint('✅ Route snapping completed: ${snappedPoints.length} points returned');
      if (snappedPoints.length > _currentRoute.length * 1.5) {
        debugPrint('🎉 Good route coverage - likely using real infrastructure!');
      } else {
        debugPrint('⚠️ Low route coverage - might be using straight lines or mock routing');
      }

      if (mounted) {
        setState(() {
          _snappedRoute = snappedPoints;
          _snapCache[_currentRoute.length] = List<LatLng>.of(snappedPoints);
          _isSnapping = false;
          // Calculate distance markers for the new route
          _distanceMarkers = _generateDistanceMarkers();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          String errorMsg = 'Could not find paths between these points.';
          if (e.toString().contains('connection') || e.toString().contains('timeout')) {
            errorMsg = 'No internet connection. Using straight lines.';
          } else if (e.toString().contains('rate limit')) {
            errorMsg = 'Too many requests. Using offline mode.';
          }
          _routingError = errorMsg;
          _isSnapping = false;
        });
      }
    }
  }



  void _undoLastPoint() async {
    // Provide haptic feedback for undo action
    await HapticFeedbackService.mediumImpact();
    
    final newRoute = _drawingHistory.undo();
    setState(() {
      _currentRoute.clear();
      _currentRoute.addAll(newRoute);
      // Keep user tap points in sync with current route length
      if (_userTapPoints.length > newRoute.length) {
        _userTapPoints.removeRange(newRoute.length, _userTapPoints.length);
      }
      _snappedRoute.clear(); // Clear snapped route when undoing
      _routingError = '';
      _distanceMarkers = _generateDistanceMarkers();
    });
    
    // Use cache if available; otherwise re-snap
    if (_currentRoute.length >= 2) {
      final cached = _snapCache[_currentRoute.length];
      if (cached != null) {
        setState(() {
          _snappedRoute = List<LatLng>.of(cached);
          _distanceMarkers = _generateDistanceMarkers();
        });
      } else {
        _snapCurrentRoute();
      }
    }
  }

  void _redoLastPoint() async {
    // Provide haptic feedback for redo action
    await HapticFeedbackService.mediumImpact();
    
    final newRoute = _drawingHistory.redo();
    setState(() {
      _currentRoute.clear();
      _currentRoute.addAll(newRoute);
      _snappedRoute.clear(); // Clear snapped route when redoing
      _routingError = '';
      _distanceMarkers = _generateDistanceMarkers();
    });
    
    // Use cache if available; otherwise re-snap
    if (_currentRoute.length >= 2) {
      final cached = _snapCache[_currentRoute.length];
      if (cached != null) {
        setState(() {
          _snappedRoute = List<LatLng>.of(cached);
          _distanceMarkers = _generateDistanceMarkers();
        });
      } else {
        _snapCurrentRoute();
      }
    }
  }

  void _toggleSnapToPath() {
    if (_snappedRoute.isNotEmpty) {
      // Show original drawn route
      setState(() {
        _snappedRoute.clear();
        _distanceMarkers = _generateDistanceMarkers();
      });
    } else if (_currentRoute.length >= 2) {
      // Snap to path
      _snapCurrentRoute();
    }
  }

  void _clearRoute() async {
    // Provide strong haptic feedback for destructive action
    await HapticFeedbackService.heavyImpact();
    
    setState(() {
      _currentRoute.clear();
      _snappedRoute.clear();
      _userTapPoints.clear(); // Clear user tap points too
      _snapCache.clear();
      _isDrawingMode = false;
      _routingError = '';
      _previewMarker = null; // Clear preview marker
      _distanceMarkers.clear(); // Clear distance markers
    });
    
    _drawingHistory.clear();
  }

  bool _canLoopBack() {
    // Can loop back if we have at least 2 points
    return _currentRoute.length >= 2;
  }

  void _loopBackToStart() async {
    if (!_canLoopBack()) return;

    // Use the actual route endpoints (prefer snapped route if available)
    final actualRoute = _snappedRoute.isNotEmpty ? _snappedRoute : _currentRoute;
    final startPoint = actualRoute.first;
    final endPoint = actualRoute.last;

    // Check if route is already a loop using Haversine formula
    final lat1Rad = startPoint.latitude * (pi / 180);
    final lat2Rad = endPoint.latitude * (pi / 180);
    final deltaLatRad = (endPoint.latitude - startPoint.latitude) * (pi / 180);
    final deltaLngRad = (endPoint.longitude - startPoint.longitude) * (pi / 180);
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distanceMeters = 6371000.0 * c; // Earth's radius in meters

    final isAlreadyLoop = distanceMeters < 30; // Within 30 meters
    if (isAlreadyLoop) {
      // Points are within ~30 meters; consider it already a loop
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route is al een lus!'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }

    debugPrint('🔄 Creating loop back route from ${endPoint.latitude.toStringAsFixed(6)},${endPoint.longitude.toStringAsFixed(6)} to ${startPoint.latitude.toStringAsFixed(6)},${startPoint.longitude.toStringAsFixed(6)}');
    debugPrint('🔄 Distance to close: ${distanceMeters.toStringAsFixed(1)}m');

    // Add the end->start connection to _currentRoute to create the loop
    _currentRoute.add(startPoint);
    _userTapPoints.add(startPoint); // Add start point as final waypoint

    // Add to history
    _drawingHistory.addState(
      _currentRoute,
      'Added loop back to start',
    );

    // Provide haptic feedback
    await HapticFeedbackService.mediumImpact();

    // Use standard route snapping for the loop back connection
    await _snapCurrentRoute();

    debugPrint('✅ Loop back route initiated - will be snapped and animated');
  }

  List<LatLng> _generateDistanceMarkers() {
    final List<LatLng> markers = [];

    // Get the route to analyze (prefer snapped route if available)
    final route = _snappedRoute.isNotEmpty ? _snappedRoute : _currentRoute;
    debugPrint('🔍 Calculating distance markers for route with ${route.length} points');
    if (route.length < 2) {
      debugPrint('⚠️ Route too short for distance markers');
      return markers;
    }

    // Calculate total route distance first
    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      final currentPoint = route[i];
      final nextPoint = route[i + 1];
      
      // Use Haversine formula directly since Distance() is unreliable
      final lat1Rad = currentPoint.latitude * (pi / 180);
      final lat2Rad = nextPoint.latitude * (pi / 180);
      final deltaLatRad = (nextPoint.latitude - currentPoint.latitude) * (pi / 180);
      final deltaLngRad = (nextPoint.longitude - currentPoint.longitude) * (pi / 180);
      
      final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
          cos(lat1Rad) * cos(lat2Rad) *
          sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      final segmentDistance = 6371.0 * c; // Earth's radius in kilometers
      
      if (segmentDistance > 0.000001) { // Threshold for very small distances (about 1mm)
        totalDistance += segmentDistance;
        debugPrint('  Distance segment ${i}->${i + 1}: ${segmentDistance.toStringAsFixed(6)}km');
      } else {
        debugPrint('  Skipping tiny segment ${i}->${i + 1}: ${segmentDistance.toStringAsFixed(8)}km');
      }
    }
    
    debugPrint('📐 Total route distance: ${totalDistance.toStringAsFixed(2)}km');

    final unitsSystem = SettingsService.getUnitsSystem();
    final isMetric = unitsSystem == 'Metric';
    // Use full intervals - 1km or 1 mile
    final markerInterval = isMetric ? 1.0 : 1.60934; // 1 km or 1 mile in km
    debugPrint('📏 Using ${isMetric ? 'metric' : 'imperial'} units, marker interval: ${markerInterval}km');

    // If route is too short, don't place any markers
    if (totalDistance < markerInterval) {
      debugPrint('⚠️ Route too short (${totalDistance.toStringAsFixed(2)}km) for markers (need at least ${markerInterval}km)');
      return markers;
    }

    double cumulativeDistance = 0.0;
    double nextMarkerDistance = markerInterval;

    for (int i = 0; i < route.length - 1; i++) {
      final currentPoint = route[i];
      final nextPoint = route[i + 1];

      // Use Haversine formula directly since Distance() is unreliable
      final lat1Rad = currentPoint.latitude * (pi / 180);
      final lat2Rad = nextPoint.latitude * (pi / 180);
      final deltaLatRad = (nextPoint.latitude - currentPoint.latitude) * (pi / 180);
      final deltaLngRad = (nextPoint.longitude - currentPoint.longitude) * (pi / 180);
      
      final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
          cos(lat1Rad) * cos(lat2Rad) *
          sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      final segmentDistance = 6371.0 * c; // Earth's radius in kilometers
      
      debugPrint('  Segment ${i}->${i + 1}: ${segmentDistance.toStringAsFixed(3)}km');
      
      if (segmentDistance <= 0) continue; // avoid division by zero

      final segmentStart = cumulativeDistance;
      final segmentEnd = cumulativeDistance + segmentDistance;

      while (nextMarkerDistance >= segmentStart && nextMarkerDistance <= segmentEnd && nextMarkerDistance <= totalDistance) {
        final ratio = (nextMarkerDistance - segmentStart) / segmentDistance;
        final markerLat = currentPoint.latitude + (nextPoint.latitude - currentPoint.latitude) * ratio;
        final markerLng = currentPoint.longitude + (nextPoint.longitude - currentPoint.longitude) * ratio;
        markers.add(LatLng(markerLat, markerLng));
        debugPrint('  📍 Added marker at ${nextMarkerDistance.toStringAsFixed(2)}km: ${markerLat.toStringAsFixed(6)}, ${markerLng.toStringAsFixed(6)}');
        nextMarkerDistance += markerInterval;
      }

      cumulativeDistance = segmentEnd;
    }

    debugPrint('📏 Generated ${markers.length} distance markers total');
    return markers;
  }

  void _saveRoute() async {
    if (_currentRoute.isEmpty && _snappedRoute.isEmpty) return;

    // Provide haptic feedback for save action
    await HapticFeedbackService.mediumImpact();

    final routeToSave = _snappedRoute.isNotEmpty ? _snappedRoute : _currentRoute;
    
    // Show save dialog
    final routeName = await _showSaveRouteDialog();
    if (routeName == null || routeName.trim().isEmpty) return;
    
    try {
      // Generate route ID and get location info
      final routeId = await RouteStorageService.generateRouteId();
      final distance = _getTotalDistance();
      final time = _getEstimatedTime();
      final location = await _getApproximateLocation(routeToSave.first);
      
      // Create saved route
      final savedRoute = SavedRoute(
        id: routeId,
        name: routeName.trim(),
        points: List<LatLng>.from(routeToSave),
        activityType: _selectedActivity,
        distance: distance,
        estimatedTime: time,
        createdAt: DateTime.now(),
        location: location,
      );
      
      // Save to storage
      await RouteStorageService.saveRoute(savedRoute);
      
      // Clear current route
      setState(() {
        _currentRoute.clear();
        _snappedRoute.clear();
        _snapCache.clear();
        _isDrawingMode = false;
        _routingError = '';
        _distanceMarkers.clear(); // Clear distance markers too
      });
      _drawingHistory.clear();
      
      // Notify parent that route was saved - defer to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onRouteSaved?.call();
      });
      
      // Provide success haptic feedback
      await HapticFeedbackService.routeCompleted();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Route "$routeName" succesvol opgeslagen!'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Switch to routes tab
              DefaultTabController.of(context)?.animateTo(1);
            },
          ),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij opslaan route: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }


  void _centerOnLocation() async {
    try {
      // Try to get current location first
      final location = await LocationService.getCurrentLocation();
      
      final targetLocation = location ?? _currentLocation;
      
      // Simple move with north-up orientation
      _mapController.moveAndRotate(targetLocation, 17.0, 0.0);
      
      // Update current location if we got a fresh one
      if (location != null && mounted) {
        setState(() {
          _currentLocation = location;
        });
      }
      
    } catch (e) {
      debugPrint('Error centering on location: $e');
      // Fallback to simple move with north-up orientation
      _mapController.moveAndRotate(_currentLocation, 17.0, 0.0);
    }
  }

  Future<void> _requestLocationPermission() async {
    final granted = await LocationService.requestLocationPermission();
    
    if (granted) {
      setState(() {
        _hasLocationPermission = true;
        _locationLoading = true;
      });
      
      // Get current location
      final location = await LocationService.getCurrentLocation();
      
      if (location != null && mounted) {
        setState(() {
          _currentLocation = location;
          _locationLoading = false;
        });
        
        _mapController.move(location, 17.0);
      } else if (mounted) {
        setState(() {
          _locationLoading = false;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Locatietoestemming is nodig voor de beste ervaring'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showLayerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kaartlaag Kiezen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...MapLayerType.values.map((layer) => ListTile(
              leading: Icon(
                Icons.map,
                color: _currentMapLayer == layer ? AppColors.trailGreen : AppColors.textSecondary,
              ),
              title: Text(layer.displayName),
              subtitle: Text(layer.attribution),
              trailing: _currentMapLayer == layer 
                ? const Icon(Icons.check, color: AppColors.trailGreen) 
                : null,
              onTap: () async {
                await SettingsService.setMapLayer(layer.displayName);
                setState(() {
                  _currentMapLayer = layer;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kaartlaag gewijzigd naar ${layer.displayName}')),
                );
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showMenuBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Offline Kaarten'),
              subtitle: const Text('Download kaarten voor offline gebruik'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline kaarten komen binnenkort!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.import_export),
              title: const Text('Importeer GPX'),
              subtitle: const Text('Importeer route uit GPX bestand'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GPX import komt binnenkort!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Tutorial'),
              subtitle: const Text('Leer hoe je Pathify gebruikt'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tutorial komt binnenkort!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _calculateDistance() {
    return _getTotalDistance().toStringAsFixed(1);
  }

  String _calculateTime() {
    final route = _snappedRoute.isNotEmpty ? _snappedRoute : _currentRoute;
    if (route.length < 2) return '0m';
    
    final distance = double.tryParse(_calculateDistance()) ?? 0.0;
    final speed = _selectedActivity.averageSpeed;
    final timeInHours = distance / speed;
    
    if (timeInHours < 1) {
      return '${(timeInHours * 60).round()}m';
    }
    return '${timeInHours.toStringAsFixed(1)}h';
  }

  void _toggleWaypointMode() {
    setState(() {
      _showWaypoints = !_showWaypoints;
      if (_showWaypoints) {
        _isDrawingMode = false; // Disable drawing mode when showing waypoints
      }
    });
  }

  void _toggleMixedRouting() {
    setState(() {
      _allowMixedRouting = !_allowMixedRouting;
      _snapCache.clear();
    });
    
    // Automatically re-snap the route with the new setting
    if (_currentRoute.length >= 2) {
      _snapCurrentRoute();
    }
    
    // Show a helpful message to the user
    final mode = _allowMixedRouting ? 'Mixed routing enabled' : 'Single-mode routing';
    final description = _allowMixedRouting 
        ? 'Will use roads, footpaths, and bike paths' 
        : 'Will only use ${_selectedActivity.name.toLowerCase()} infrastructure';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$mode: $description'),
        duration: const Duration(seconds: 2),
        backgroundColor: _allowMixedRouting ? AppColors.summitOrange : AppColors.pathBlue,
      ),
    );
  }

  void _onWaypointTapped(int index) {
    if (index == 0 || index == (_snappedRoute.isNotEmpty ? _snappedRoute.length - 1 : _currentRoute.length - 1)) {
      // Endpoint - show options
      _showWaypointOptions(index);
    } else {
      // Middle waypoint - show options including split
      _showMiddleWaypointOptions(index);
    }
  }

  void _showMiddleWaypointOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waypoint ${index + 1} Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.call_split),
              title: const Text('Route Hier Splitsen'),
              onTap: () {
                Navigator.pop(context);
                _splitRouteAt(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Waypoint Verwijderen'),
              onTap: () {
                Navigator.pop(context);
                _removeWaypoint(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onWaypointDragged(int index, LatLng newPosition) {
    // For now, we'll implement a simplified version
    // In a full implementation, you'd need proper coordinate conversion
    setState(() {
      if (_snappedRoute.isNotEmpty && index < _snappedRoute.length) {
        _snappedRoute[index] = newPosition;
      } else if (index < _currentRoute.length) {
        _currentRoute[index] = newPosition;
      }
    });

    // Re-snap route if applicable
    if (_currentRoute.length >= 2) {
      _snapCurrentRoute();
    }
  }

  void _showWaypointOptions(int index) {
    final isStart = index == 0;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isStart ? 'Start Point Options' : 'End Point Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Naar Huidige Locatie'),
              onTap: () async {
                Navigator.pop(context);
                final location = await LocationService.getCurrentLocation();
                if (location != null) {
                  _updateWaypoint(index, location);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(isStart ? 'Remove Start Point' : 'Remove End Point'),
              onTap: () {
                Navigator.pop(context);
                _removeWaypoint(index);
              },
            ),
          ],
        ),
      ),
    );
  }


  void _updateWaypoint(int index, LatLng newPosition) {
    setState(() {
      if (_snappedRoute.isNotEmpty && index < _snappedRoute.length) {
        _snappedRoute[index] = newPosition;
      } else if (index < _currentRoute.length) {
        _currentRoute[index] = newPosition;
      }
    });

    // Add to history
    _drawingHistory.addState(
      _currentRoute,
      'Updated waypoint ${index + 1}',
    );

    // Re-snap if applicable
    if (_currentRoute.length >= 2) {
      _snapCurrentRoute();
    }
  }

  void _removeWaypoint(int index) {
    setState(() {
      if (_snappedRoute.isNotEmpty && index < _snappedRoute.length) {
        _snappedRoute.removeAt(index);
      }
      if (index < _currentRoute.length) {
        _currentRoute.removeAt(index);
      }
    });

    // Add to history
    _drawingHistory.addState(
      _currentRoute,
      'Removed waypoint ${index + 1}',
    );

    // Re-snap if we still have enough points
    if (_currentRoute.length >= 2) {
      final cached = _snapCache[_currentRoute.length];
      if (cached != null) {
        setState(() => _snappedRoute = List<LatLng>.of(cached));
      } else {
        _snapCurrentRoute();
      }
    } else if (_currentRoute.length < 2) {
      setState(() {
        _snappedRoute.clear();
      });
    }
  }

  void _showRouteEditingMenu() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meer route opties komen binnenkort!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _enableRouteSplitting() {
    if ((_snappedRoute.isNotEmpty ? _snappedRoute : _currentRoute).length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route heeft minimaal 3 punten nodig om te splitsen'),
        ),
      );
      return;
    }

    setState(() {
      _showWaypoints = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tik op een waypoint om de route daar te splitsen'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _enableSegmentDeletion() {
    setState(() {
      _showWaypoints = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tik op waypoints om segment te selecteren voor verwijdering'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _reverseRoute() {
    final currentRouteToReverse = _snappedRoute.isNotEmpty ? _snappedRoute : _currentRoute;
    if (currentRouteToReverse.length < 2) return;

    setState(() {
      if (_snappedRoute.isNotEmpty) {
        _snappedRoute = RouteEditingService.reverseRoute(_snappedRoute);
      }
      _currentRoute = RouteEditingService.reverseRoute(_currentRoute);
    });

    _drawingHistory.addState(_currentRoute, 'Reversed route');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route omgekeerd')),
    );
  }

  void _simplifyRoute() {
    final currentRouteToSimplify = _snappedRoute.isNotEmpty ? _snappedRoute : _currentRoute;
    if (currentRouteToSimplify.length < 3) return;

    final originalLength = currentRouteToSimplify.length;
    
    setState(() {
      if (_snappedRoute.isNotEmpty) {
        _snappedRoute = RouteEditingService.simplifyRoute(_snappedRoute, minDistanceMeters: 20);
      }
      _currentRoute = RouteEditingService.simplifyRoute(_currentRoute, minDistanceMeters: 20);
    });

    _drawingHistory.addState(_currentRoute, 'Simplified route');

    final newLength = (_snappedRoute.isNotEmpty ? _snappedRoute : _currentRoute).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Route vereenvoudigd: $originalLength → $newLength punten')),
    );
  }

  void _splitRouteAt(int index) {
    final routeToSplit = _snappedRoute.isNotEmpty ? _snappedRoute : _currentRoute;
    
    if (index <= 0 || index >= routeToSplit.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kan niet splitsen op eindpunt')),
      );
      return;
    }

    final splits = RouteEditingService.splitRoute(routeToSplit, index);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Gesplitst'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Route is gesplitst in 2 segmenten:'),
            const SizedBox(height: 8),
            Text('Segment 1: ${splits[0].length} punten'),
            Text('Segment 2: ${splits[1].length} punten'),
            const SizedBox(height: 16),
            const Text('Welk segment wil je behouden?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _keepRouteSegment(splits[0]);
            },
            child: const Text('Eerste Behouden'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _keepRouteSegment(splits[1]);
            },
            child: const Text('Tweede Behouden'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
        ],
      ),
    );
  }

  void _keepRouteSegment(List<LatLng> segment) {
    setState(() {
      _currentRoute.clear();
      _currentRoute.addAll(segment);
      _snappedRoute.clear();
    });

    _drawingHistory.addState(_currentRoute, 'Kept route segment');

    // Re-snap if applicable
    if (_currentRoute.length >= 2) {
      _snapCurrentRoute();
    }

    setState(() {
      _showWaypoints = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Segment met ${segment.length} punten behouden')),
    );
  }

  

  Widget _buildErrorChip(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningAmber.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning, size: 16, color: AppColors.warningAmber),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.warningAmber, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _routingError = ''),
            child: const Icon(Icons.close, size: 16, color: AppColors.warningAmber),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String message,
    required Color color,
    bool showProgress = false,
    VoidCallback? onDismiss,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (showProgress)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )
          else
            Icon(icon, color: color, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: color,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods for modern UI
  double _getTotalDistance() {
    final route = _snappedRoute.isNotEmpty ? _snappedRoute : _currentRoute;
    if (route.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      final lat1 = route[i].latitude;
      final lon1 = route[i].longitude;
      final lat2 = route[i + 1].latitude;
      final lon2 = route[i + 1].longitude;
      
      // Haversine formula for distance calculation
      const double earthRadius = 6371; // km
      final double dLat = _toRadians(lat2 - lat1);
      final double dLon = _toRadians(lon2 - lon1);
      final double a = (sin(dLat / 2) * sin(dLat / 2)) +
          (cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
           sin(dLon / 2) * sin(dLon / 2));
      final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      totalDistance += earthRadius * c;
    }
    return totalDistance;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  double _getEstimatedTime() {
    final distance = _getTotalDistance();
    if (distance == 0) return 0;
    
    // Estimate based on activity type
    double speedKmh;
    switch (_selectedActivity) {
      case ActivityType.walking:
        speedKmh = 5.0;
        break;
      case ActivityType.running:
        speedKmh = 10.0;
        break;
      case ActivityType.cycling:
        speedKmh = 20.0;
        break;
      case ActivityType.hiking:
        speedKmh = 4.0;
        break;
    }
    
    return distance / speedKmh; // hours
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()}m';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km';
    }
  }

  String _formatTime(double timeHours) {
    if (timeHours < 1.0) {
      return '${(timeHours * 60).round()}min';
    } else {
      final hours = timeHours.floor();
      final minutes = ((timeHours - hours) * 60).round();
      return '${hours}h ${minutes}min';
    }
  }

  Future<String?> _showSaveRouteDialog() async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Opslaan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Geef je route een naam:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter route name...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }


  // Public method to load a saved route
  void loadSavedRoute(SavedRoute savedRoute) async {
    setState(() {
      _currentRoute = List<LatLng>.from(savedRoute.points);
      _snappedRoute.clear();
      _selectedActivity = savedRoute.activityType;
      _snapCache.clear();
      _isDrawingMode = false;
      _routingError = '';
    });
    _drawingHistory.clear();
    _drawingHistory.addState(_currentRoute, 'Loaded saved route');
    
    // Center map on the route and update distance markers
    if (savedRoute.points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(savedRoute.points);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
      
      setState(() {
        _distanceMarkers = _generateDistanceMarkers();
      });
    }
  }




  /// Show roundtrip generator dialog
  Future<void> _showRoundtripDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const RoundtripGeneratorDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        _isRoundtripMode = true;
        _roundtripActivity = result['activity'] as ActivityType;
        _roundtripDistance = result['distance'] as double;
        _roundtripStrategy = result['strategy'] as RoundtripStrategy? ?? RoundtripStrategy.balanced;
        _selectedActivity = _roundtripActivity!;
      });
    }
  }

  /// Cancel roundtrip generator mode
  void _cancelRoundtrip() {
    setState(() {
      _isRoundtripMode = false;
      _roundtripActivity = null;
      _roundtripDistance = null;
      _roundtripStrategy = null;
    });
  }

  /// Generate roundtrip route from selected start point
  Future<void> _generateRoundtrip(LatLng startPoint) async {
    if (_isGeneratingRoute || _roundtripActivity == null || _roundtripDistance == null) {
      return;
    }

    setState(() {
      _isGeneratingRoute = true;
      _isRoundtripMode = false; // Exit roundtrip mode immediately to restore normal UI
      _previewMarker = null; // Clear preview marker
    });

    // Show loading dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Rondrit genereren...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Dit kan even duren',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelRoundtripGeneration();
              },
              child: const Text('Annuleer'),
            ),
          ],
        ),
      ),
    );

    try {
      // Generate a simple roundtrip route (placeholder implementation)
      final generatedRoute = await _generateRoundtripRoute(startPoint, _roundtripDistance!, _roundtripActivity!, _roundtripStrategy!);
      
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Set the generated route
        setState(() {
          _currentRoute = generatedRoute;
          _userTapPoints = [startPoint, startPoint]; // Start and end are the same
          _snappedRoute.clear();
          _snapCache.clear();
          _isRoundtripMode = false;
          _isGeneratingRoute = false;
          _isDrawingMode = false;
          _distanceMarkers = _generateDistanceMarkers();
        });

        _drawingHistory.clear();
        _drawingHistory.addState(_currentRoute, 'Generated roundtrip route');

        // Fit map to route
        if (_currentRoute.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(_currentRoute);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        setState(() {
          _isGeneratingRoute = false;
          _isRoundtripMode = false; // Make sure we exit roundtrip mode on error
          _roundtripActivity = null;
          _roundtripDistance = null;
          _previewMarker = null;
        });
        
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij genereren rondrit: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  /// Cancel ongoing route generation
  void _cancelRoundtripGeneration() {
    setState(() {
      _isGeneratingRoute = false;
      _isRoundtripMode = false;
      _roundtripActivity = null;
      _roundtripDistance = null;
      _roundtripStrategy = null;
    });
  }

  /// Generate a realistic roundtrip route using the FAST routing service
  Future<List<LatLng>> _generateRoundtripRoute(LatLng startPoint, double distanceKm, ActivityType activity, RoundtripStrategy strategy) async {
    try {
      // Use the FAST roundtrip generation service (target: <10 seconds)
      final fastRoute = await FastRoundtripService.generateFastRoundtrip(
        startPoint: startPoint,
        targetDistanceKm: distanceKm,
        activityType: activity,
        strategy: strategy,
      );
      
      if (fastRoute != null && fastRoute.routedPath.isNotEmpty) {
        debugPrint('✅ Generated FAST roundtrip in ${fastRoute.generationTimeMs}ms: ${fastRoute.actualDistanceKm.toStringAsFixed(1)}km, ${fastRoute.routedPath.length} points');
        return fastRoute.routedPath;
      } else {
        debugPrint('⚠️ Fast roundtrip generation failed, trying slow method...');
        
        // Fallback to the original detailed service (with timeout)
        final timeoutFuture = Future.delayed(const Duration(seconds: 15), () => null);
        final roundtripFuture = slow_roundtrip.RoundtripGenerationService.generateRealisticRoundtrip(
          startPoint: startPoint,
          targetDistanceKm: distanceKm,
          activityType: activity,
          strategy: slow_roundtrip.RoundtripStrategy.values.firstWhere(
            (s) => s.toString().split('.').last == strategy.toString().split('.').last,
            orElse: () => slow_roundtrip.RoundtripStrategy.balanced,
          ),
        );
        
        final roundtripRoute = await Future.any([roundtripFuture, timeoutFuture]);
        
        if (roundtripRoute != null && roundtripRoute.routedPath.isNotEmpty) {
          debugPrint('✅ Generated detailed roundtrip: ${roundtripRoute.actualDistanceKm.toStringAsFixed(1)}km');
          return roundtripRoute.routedPath;
        } else {
          debugPrint('⚠️ All roundtrip methods failed/timed out, using geometric fallback');
          return _generateFallbackCircularRoute(startPoint, distanceKm);
        }
      }
    } catch (e) {
      debugPrint('❌ Roundtrip generation error: $e, falling back to geometric route');
      return _generateFallbackCircularRoute(startPoint, distanceKm);
    }
  }
  
  /// Fallback circular route generation (enhanced with realistic variation)
  Future<List<LatLng>> _generateFallbackCircularRoute(LatLng startPoint, double distanceKm) async {
    debugPrint('🔄 Creating geometric fallback route: ${distanceKm}km');
    
    // Generate a more realistic circular route with variation
    final List<LatLng> route = [];
    final int numberOfPoints = (distanceKm * 8).round().clamp(20, 60); // More points for smoother curves
    final double baseRadius = (distanceKm * 1000) / (2 * pi); // Radius in meters
    
    for (int i = 0; i <= numberOfPoints; i++) {
      final double angle = (i / numberOfPoints) * 2 * pi;
      
      // Add radius variation for more interesting shape
      final double radiusVariation = 0.8 + 0.4 * (sin(angle * 2.5) + 1) / 2; // Wave pattern
      final double effectiveRadius = baseRadius * radiusVariation;
      
      // Convert to geographic coordinates
      final double latOffset = effectiveRadius * cos(angle) / 111320; // ~111320m per degree latitude
      final double lngOffset = effectiveRadius * sin(angle) / (111320 * cos(startPoint.latitude * pi / 180));
      
      // Add small random variation to simulate road following
      final double randomVariation = 0.00005; // ~5m
      final double randomLat = (Random().nextDouble() - 0.5) * randomVariation;
      final double randomLng = (Random().nextDouble() - 0.5) * randomVariation;
      
      final LatLng point = LatLng(
        startPoint.latitude + latOffset + randomLat,
        startPoint.longitude + lngOffset + randomLng,
      );
      
      route.add(point);
    }
    
    debugPrint('📐 Generated geometric route with ${route.length} points');
    return route;
  }

  /// Handle search location selection with smooth animation
  void _onSearchLocationSelected(LatLng location, {bool isCity = false}) async {
    await HapticFeedbackService.mediumImpact();
    
    // Move map to the selected location with appropriate zoom
    final targetZoom = isCity ? 13.0 : 16.0;
    _mapController.moveAndRotate(location, targetZoom, 0.0);
  }

  /// Get approximate location name for route saving
  Future<String?> _getApproximateLocation(LatLng point) async {
    try {
      // Use reverse geocoding to get the actual city/region name
      return await GeocodingService.getCityFromCoordinates(point);
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  @override
  void dispose() {
    LocationService.stopLocationTracking();
    super.dispose();
  }
}
