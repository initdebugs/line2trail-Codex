import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/activity_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/services/routing_service.dart';
import '../../../shared/services/geocoding_service.dart';
import '../../routes/models/saved_route.dart';
import '../../routes/services/route_storage_service.dart';
import '../widgets/waypoint_marker.dart';
import '../widgets/route_bar.dart';
import '../widgets/route_tools.dart';
import '../widgets/map_control_rail.dart';
import '../widgets/draw_stats_panel.dart';
import '../models/route_drawing_state.dart';
import '../services/route_editing_service.dart';

class MapScreen extends StatefulWidget {
  final VoidCallback? onRouteSaved;
  final SavedRoute? routeToLoad;
  final VoidCallback? onRouteLoaded;
  
  const MapScreen({super.key, this.onRouteSaved, this.routeToLoad, this.onRouteLoaded});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  ActivityType _selectedActivity = ActivityType.walking; // Start with walking for Phase 2 focus
  bool _isDrawingMode = false;
  List<LatLng> _currentRoute = [];
  List<LatLng> _snappedRoute = [];
  final Map<int, List<LatLng>> _snapCache = {};
  final RouteDrawingHistory _drawingHistory = RouteDrawingHistory();
  
  LatLng _currentLocation = const LatLng(37.7749, -122.4194); // Default fallback
  bool _locationLoading = true;
  bool _hasLocationPermission = false;
  bool _isSnapping = false;
  String _routingError = '';
  bool _showWaypoints = true;
  bool _allowMixedRouting = true; // Allow combining different transport modes

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadSettings();
    // Test routing service when app starts
    RoutingService.testRouting();
    
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
    
    setState(() {
      _selectedActivity = defaultActivity;
      _showWaypoints = showWaypoints;
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
              onTap: _isDrawingMode ? _onMapTap : null,
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.pathify',
              ),
              // Route polyline (prefer snapped path)
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
                  ],
                ),
              // Waypoint markers
              EditableWaypointLayer(
                points: _snappedRoute.isNotEmpty ? _snappedRoute : _currentRoute,
                showWaypoints: _showWaypoints && (_currentRoute.isNotEmpty || _snappedRoute.isNotEmpty),
                onWaypointTapped: _onWaypointTapped,
                onWaypointDragged: _onWaypointDragged,
              ),
            ],
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
    if (_isDrawingMode) {
      setState(() {
        _currentRoute.add(point);
        _routingError = '';
      });

      // Add to history
      _drawingHistory.addState(
        _currentRoute,
        'Added point ${_currentRoute.length}',
      );

      // Always snap after 2+ points
      if (_currentRoute.length >= 2) {
        await _snapCurrentRoute();
      }
    }
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (!_isDrawingMode && _currentRoute.isNotEmpty && _snappedRoute.isEmpty) {
        // Snap to path when finishing drawing
        _snapCurrentRoute();
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

  void _undoLastPoint() {
    final newRoute = _drawingHistory.undo();
    setState(() {
      _currentRoute.clear();
      _currentRoute.addAll(newRoute);
      _snappedRoute.clear(); // Clear snapped route when undoing
      _routingError = '';
    });
    
    // Use cache if available; otherwise re-snap
    if (_currentRoute.length >= 2) {
      final cached = _snapCache[_currentRoute.length];
      if (cached != null) {
        setState(() => _snappedRoute = List<LatLng>.of(cached));
      } else {
        _snapCurrentRoute();
      }
    }
  }

  void _redoLastPoint() {
    final newRoute = _drawingHistory.redo();
    setState(() {
      _currentRoute.clear();
      _currentRoute.addAll(newRoute);
      _snappedRoute.clear(); // Clear snapped route when redoing
      _routingError = '';
    });
    
    // Use cache if available; otherwise re-snap
    if (_currentRoute.length >= 2) {
      final cached = _snapCache[_currentRoute.length];
      if (cached != null) {
        setState(() => _snappedRoute = List<LatLng>.of(cached));
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
      });
    } else if (_currentRoute.length >= 2) {
      // Snap to path
      _snapCurrentRoute();
    }
  }

  void _clearRoute() {
    setState(() {
      _currentRoute.clear();
      _snappedRoute.clear();
      _snapCache.clear();
      _isDrawingMode = false;
      _routingError = '';
    });
    _drawingHistory.clear();
  }

  void _saveRoute() async {
    if (_currentRoute.isEmpty && _snappedRoute.isEmpty) return;

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
      
      // Notify parent that route was saved
      widget.onRouteSaved?.call();
      
      // Clear current route
      setState(() {
        _currentRoute.clear();
        _snappedRoute.clear();
        _snapCache.clear();
        _isDrawingMode = false;
        _routingError = '';
      });
      _drawingHistory.clear();
      
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
      
      // Get current camera state
      final currentCenter = _mapController.camera.center;
      final currentZoom = _mapController.camera.zoom;
      final currentRotation = _mapController.camera.rotation;
      
      const targetZoom = 17.0;
      const targetRotation = 0.0; // North-up
      
      // Create animation controller
      late AnimationController animationController;
      animationController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );
      
      // Create animations for all properties
      final latTween = Tween<double>(
        begin: currentCenter.latitude,
        end: targetLocation.latitude,
      );
      final lngTween = Tween<double>(
        begin: currentCenter.longitude,
        end: targetLocation.longitude,
      );
      final zoomTween = Tween<double>(
        begin: currentZoom,
        end: targetZoom,
      );
      final rotationTween = Tween<double>(
        begin: currentRotation,
        end: targetRotation,
      );
      
      // Use eased animation curve
      final curvedAnimation = CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOutCubic,
      );
      
      // Listen to animation updates
      void animationListener() {
        if (mounted) {
          final lat = latTween.evaluate(curvedAnimation);
          final lng = lngTween.evaluate(curvedAnimation);
          final zoom = zoomTween.evaluate(curvedAnimation);
          final rotation = rotationTween.evaluate(curvedAnimation);
          
          _mapController.moveAndRotate(
            LatLng(lat, lng),
            zoom,
            rotation,
          );
        }
      }
      
      curvedAnimation.addListener(animationListener);
      
      // Start animation
      await animationController.forward();
      
      // Clean up
      curvedAnimation.removeListener(animationListener);
      animationController.dispose();
      
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laagopties komen binnenkort!'),
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

  Future<String?> _getApproximateLocation(LatLng point) async {
    try {
      // Use reverse geocoding to get the actual city/region name
      return await GeocodingService.getCityFromCoordinates(point);
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  // Public method to load a saved route
  void loadSavedRoute(SavedRoute savedRoute) {
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
    
    // Center map on the route
    if (savedRoute.points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(savedRoute.points);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
    }
  }

  void _showRoundtripDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rondrit Generator'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Roundtrip route generation is coming soon!',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'This feature will generate circular routes from your current location.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
