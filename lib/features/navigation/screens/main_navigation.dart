import 'package:flutter/material.dart';
import '../../map/screens/map_screen.dart';
import '../../routes/screens/routes_screen.dart';
import '../../settings/screens/new_settings_screen.dart';
import '../../routes/models/saved_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/localization_service.dart';

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
          PlaceholderScreen(title: LocalizationService.navigationTab),
          const NewSettingsScreen(),
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            activeIcon: const Icon(Icons.map),
            label: LocalizationService.mapTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.route_outlined),
            activeIcon: const Icon(Icons.route),
            label: LocalizationService.routesTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.navigation_outlined),
            activeIcon: const Icon(Icons.navigation),
            label: LocalizationService.navigationTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: LocalizationService.settingsTab,
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
              '$title ${LocalizationService.comingSoon}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationService.featureComingSoon,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LocalizationService.featureInDevelopment),
                  ),
                );
              },
              child: Text(LocalizationService.moreInfo),
            ),
          ],
        ),
      ),
    );
  }
}
