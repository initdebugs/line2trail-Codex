import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_route.dart';

class RouteStorageService {
  static const String _routesKey = 'saved_routes';
  static const String _routeCounterKey = 'route_counter';
  
  // Save a route to persistent storage
  static Future<void> saveRoute(SavedRoute route) async {
    final prefs = await SharedPreferences.getInstance();
    final routes = await getAllRoutes();
    
    // Add the new route
    routes.add(route);
    
    // Convert to JSON and save
    final routesJson = routes.map((r) => r.toJson()).toList();
    await prefs.setString(_routesKey, jsonEncode(routesJson));
  }
  
  // Get all saved routes
  static Future<List<SavedRoute>> getAllRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final routesString = prefs.getString(_routesKey);
    
    if (routesString == null) return [];
    
    final routesJson = jsonDecode(routesString) as List;
    return routesJson.map((json) => SavedRoute.fromJson(json)).toList();
  }
  
  // Delete a route by ID
  static Future<void> deleteRoute(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final routes = await getAllRoutes();
    
    // Remove the route with matching ID
    routes.removeWhere((route) => route.id == routeId);
    
    // Save updated list
    final routesJson = routes.map((r) => r.toJson()).toList();
    await prefs.setString(_routesKey, jsonEncode(routesJson));
  }
  
  // Generate a unique ID for a new route
  static Future<String> generateRouteId() async {
    final prefs = await SharedPreferences.getInstance();
    final counter = prefs.getInt(_routeCounterKey) ?? 0;
    final newCounter = counter + 1;
    await prefs.setInt(_routeCounterKey, newCounter);
    return 'route_$newCounter';
  }
  
  // Get route by ID
  static Future<SavedRoute?> getRouteById(String routeId) async {
    final routes = await getAllRoutes();
    try {
      return routes.firstWhere((route) => route.id == routeId);
    } catch (e) {
      return null;
    }
  }
  
  // Update an existing route
  static Future<void> updateRoute(SavedRoute route) async {
    final routes = await getAllRoutes();
    final index = routes.indexWhere((r) => r.id == route.id);
    
    if (index != -1) {
      routes[index] = route;
      final prefs = await SharedPreferences.getInstance();
      final routesJson = routes.map((r) => r.toJson()).toList();
      await prefs.setString(_routesKey, jsonEncode(routesJson));
    }
  }
}