import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/activity_types.dart';
import '../models/saved_route.dart';
import '../services/route_storage_service.dart';
import 'route_details_screen.dart';

class RoutesScreen extends StatefulWidget {
  final Function(SavedRoute)? onRouteSelected;
  final VoidCallback? onSwitchToMap;
  final bool shouldRefresh;
  final VoidCallback? onRefreshComplete;
  
  const RoutesScreen({super.key, this.onRouteSelected, this.onSwitchToMap, this.shouldRefresh = false, this.onRefreshComplete});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> 
    with TickerProviderStateMixin {
  String _searchQuery = '';
  ActivityType? _filterActivity;
  List<SavedRoute> _savedRoutes = [];
  bool _isLoading = true;
  
  late AnimationController _listController;
  late Animation<double> _listFadeAnimation;
  late Animation<Offset> _listSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _listFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOut,
    ));
    
    _listSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadRoutes();
  }
  
  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RoutesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Refresh routes if requested
    if (widget.shouldRefresh && !oldWidget.shouldRefresh) {
      _loadRoutes();
      widget.onRefreshComplete?.call();
    }
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await RouteStorageService.getAllRoutes();
      setState(() {
        _savedRoutes = routes;
        _isLoading = false;
      });
      
      // Start list animation after loading
      _listController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Public method to refresh routes from external calls
  void refreshRoutes() {
    _loadRoutes();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRoutes = _getFilteredRoutes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn Routes'),
        actions: [
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Routes zoeken...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.trailGreenSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),

          // Filter Chips
          if (_filterActivity != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(_filterActivity!.displayName),
                    avatar: Icon(
                      _filterActivity!.icon,
                      size: 16,
                      color: AppColors.trailGreen,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _filterActivity = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Routes List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRoutes.isEmpty
                    ? _buildEmptyState()
                    : SlideTransition(
                        position: _listSlideAnimation,
                        child: FadeTransition(
                          opacity: _listFadeAnimation,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredRoutes.length,
                            itemBuilder: (context, index) {
                              return _buildAnimatedRouteCard(
                                filteredRoutes[index],
                                index,
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<SavedRoute> _getFilteredRoutes() {
    return _savedRoutes.where((route) {
      final matchesSearch = _searchQuery.isEmpty ||
          route.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterActivity == null || route.activityType == _filterActivity;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No routes found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Create your first route by drawing on the map!'
                : 'Try adjusting your search or filters.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Alle'),
                  selected: _filterActivity == null,
                  onSelected: (_) {
                    setState(() {
                      _filterActivity = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                ...ActivityType.values.map(
                  (activity) => FilterChip(
                    label: Text(activity.displayName),
                    avatar: Icon(activity.icon, size: 16),
                    selected: _filterActivity == activity,
                    onSelected: (_) {
                      setState(() {
                        _filterActivity = activity;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedRouteCard(SavedRoute route, int index) {
    return AnimatedBuilder(
      animation: _listFadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _listFadeAnimation.value)),
          child: Opacity(
            opacity: _listFadeAnimation.value,
            child: child,
          ),
        );
      },
      child: _buildRouteCard(route),
    );
  }
  
  Widget _buildRouteCard(SavedRoute route) {
    return Hero(
      tag: 'route-${route.id}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showRouteDetails(route),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.trailGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      route.activityType.icon,
                      size: 20,
                      color: AppColors.trailGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route.location ?? 'Unknown Location',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Navigate button - blue with white arrow
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _navigateRoute(route),
                            borderRadius: BorderRadius.circular(18),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Navigeren',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _deleteRoute(route),
                            borderRadius: BorderRadius.circular(18),
                            child: const Center(
                              child: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildStatChip(Icons.straighten, route.formattedDistance),
                  _buildStatChip(Icons.schedule, route.formattedTime),
                  _buildStatChip(Icons.calendar_today, route.formattedDate),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pathBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.pathBlue),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: AppColors.pathBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  void _showRouteDetails(SavedRoute route) {
    // Immediately load the route on the map in the background
    widget.onRouteSelected?.call(route);
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RouteDetailsScreen(
          route: route,
          onOpenOnMap: (r) {
            // Route is already loaded in background - just switch to map tab
            Navigator.of(context).pop(); // Close route details
            widget.onSwitchToMap?.call(); // Switch to map tab
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth slide up transition
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var offsetAnimation = animation.drive(tween);
          
          // Also add fade animation
          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ));

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
  
  void _navigateRoute(SavedRoute route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigatie voor ${route.name} - Komt binnenkort!'),
      ),
    );
  }

  void _deleteRoute(SavedRoute route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Verwijderen'),
        content: Text('Weet je zeker dat je "${route.name}" wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await RouteStorageService.deleteRoute(route.id);
        await _loadRoutes(); // Reload the routes list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${route.name} verwijderd'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fout bij verwijderen route: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

