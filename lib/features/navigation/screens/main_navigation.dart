import 'package:flutter/material.dart';
import '../../map/screens/map_screen.dart';
import '../../routes/screens/routes_screen.dart';
import '../../settings/screens/new_settings_screen.dart';
import '../../routes/models/saved_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../shared/services/haptic_feedback_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  SavedRoute? _routeToLoad;
  bool _shouldRefreshRoutes = false;
  late PageController _pageController;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
          MapScreen(
            routeToLoad: _routeToLoad,
            onRouteSaved: () {
              // Mark that routes should refresh and switch to routes tab
              setState(() {
                _shouldRefreshRoutes = true;
              });
              _animateToPage(1);
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
              });
              _animateToPage(0);
            },
          ),
          PlaceholderScreen(title: LocalizationService.navigationTab),
          const NewSettingsScreen(),
        ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (!_isTransitioning) {
            await HapticFeedbackService.selectionClick();
            _animateToPage(index);
          }
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

  /// Navigate to a specific page
  void _animateToPage(int index) {
    if (_isTransitioning || index == _currentIndex) return;

    setState(() {
      _isTransitioning = true;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      if (mounted) {
        setState(() {
          _isTransitioning = false;
          _currentIndex = index;
        });
      }
    });
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
