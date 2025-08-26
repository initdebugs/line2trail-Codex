import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/activity_types.dart';
import '../widgets/route_card.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  String _searchQuery = '';
  ActivityType? _filterActivity;

  // Empty routes list - routes will be added when actual saving is implemented
  final List<RouteData> _savedRoutes = [];

  @override
  Widget build(BuildContext context) {
    final filteredRoutes = _getFilteredRoutes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routes'),
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
                hintText: 'Search routes...',
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
            child: filteredRoutes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredRoutes.length,
                    itemBuilder: (context, index) {
                      return RouteCard(
                        route: filteredRoutes[index],
                        onTap: () => _showRouteDetails(filteredRoutes[index]),
                        onShare: () => _shareRoute(filteredRoutes[index]),
                        onDelete: () => _deleteRoute(filteredRoutes[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<RouteData> _getFilteredRoutes() {
    return _savedRoutes.where((route) {
      final matchesSearch = _searchQuery.isEmpty ||
          route.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterActivity == null || route.activity == _filterActivity;
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
                  label: const Text('All'),
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

  void _showRouteDetails(RouteData route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${route.name} details...'),
      ),
    );
  }

  void _shareRoute(RouteData route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${route.name}...'),
      ),
    );
  }

  void _deleteRoute(RouteData route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete "${route.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _savedRoutes.removeWhere((r) => r.id == route.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${route.name} deleted'),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class RouteData {
  final String id;
  final String name;
  final ActivityType activity;
  final double distance;
  final int elevationGain;
  final Duration duration;
  final String difficulty;
  final DateTime createdAt;

  RouteData({
    required this.id,
    required this.name,
    required this.activity,
    required this.distance,
    required this.elevationGain,
    required this.duration,
    required this.difficulty,
    required this.createdAt,
  });
}