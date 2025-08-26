import 'package:latlong2/latlong.dart';

class RouteDrawingState {
  final List<LatLng> points;
  final DateTime timestamp;
  final String description;

  const RouteDrawingState({
    required this.points,
    required this.timestamp,
    required this.description,
  });

  RouteDrawingState copyWith({
    List<LatLng>? points,
    DateTime? timestamp,
    String? description,
  }) {
    return RouteDrawingState(
      points: points ?? List.from(this.points),
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
    );
  }
}

class RouteDrawingHistory {
  final List<RouteDrawingState> _history = [];
  int _currentIndex = -1;
  static const int maxHistorySize = 50;

  List<LatLng> get currentPoints => _history.isEmpty ? [] : _history[_currentIndex].points;
  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _history.length - 1;
  int get historyLength => _history.length;

  void addState(List<LatLng> points, String description) {
    // Remove any future states when adding a new state
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Add new state
    _history.add(RouteDrawingState(
      points: List.from(points),
      timestamp: DateTime.now(),
      description: description,
    ));

    // Maintain max history size
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    } else {
      _currentIndex++;
    }

    // Ensure current index is valid
    _currentIndex = _history.length - 1;
  }

  List<LatLng> undo() {
    if (canUndo) {
      _currentIndex--;
      return List.from(_history[_currentIndex].points);
    }
    return currentPoints;
  }

  List<LatLng> redo() {
    if (canRedo) {
      _currentIndex++;
      return List.from(_history[_currentIndex].points);
    }
    return currentPoints;
  }

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }

  String getCurrentDescription() {
    if (_history.isEmpty) return '';
    return _history[_currentIndex].description;
  }
}