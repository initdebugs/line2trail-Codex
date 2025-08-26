import 'package:flutter/material.dart';
import '../../map/screens/map_screen.dart';
import '../../routes/screens/routes_screen.dart';
import '../../routes/models/saved_route.dart';
import '../../../core/theme/app_colors.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  SavedRoute? _routeToLoad;
  bool _shouldRefreshRoutes = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MapScreen(
        routeToLoad: _routeToLoad,
        onRouteSaved: () {
          // Mark that routes should refresh and switch to routes tab
          setState(() {
            _shouldRefreshRoutes = true;
            _currentIndex = 1;
          });
        },
        onRouteLoaded: () {
          // Clear the route after it's loaded
          setState(() {
            _routeToLoad = null;
          });
        },
      ),
      RoutesScreen(
        shouldRefresh: _shouldRefreshRoutes,
        onRefreshComplete: () {
          setState(() {
            _shouldRefreshRoutes = false;
          });
        },
        onRouteSelected: (route) {
          // Set the route to load and switch to map tab
          setState(() {
            _routeToLoad = route;
            _currentIndex = 0;
          });
        },
      ),
      const PlaceholderScreen(title: 'Navigation'),
      const PlaceholderScreen(title: 'Settings'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            activeIcon: Icon(Icons.route),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.navigation_outlined),
            activeIcon: Icon(Icons.navigation),
            label: 'Navigate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '$title Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This feature will be available in a future update.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feature under development'),
                  ),
                );
              },
              child: const Text('Learn More'),
            ),
          ],
        ),
      ),
    );
  }
}