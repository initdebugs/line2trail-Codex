import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class RouteAnimationService {
  /// Animates drawing a route on the map from start to end
  static AnimationController createRouteDrawingAnimation({
    required TickerProvider vsync,
    required List<LatLng> route,
    required Function(List<LatLng>) onUpdate,
    Duration duration = const Duration(seconds: 2),
  }) {
    final animationController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubic,
    );

    animation.addListener(() {
      final progress = animation.value;
      final pointsToShow = (route.length * progress).round().clamp(0, route.length);
      
      if (pointsToShow > 0) {
        final animatedRoute = route.sublist(0, pointsToShow);
        
        // Interpolate the last point if we're mid-animation
        if (pointsToShow < route.length && progress < 1.0) {
          final segmentProgress = (route.length * progress) - (pointsToShow - 1);
          if (segmentProgress > 0 && pointsToShow > 1) {
            final currentPoint = route[pointsToShow - 1];
            final nextPoint = route[pointsToShow];
            
            final interpolatedLat = currentPoint.latitude + 
                (nextPoint.latitude - currentPoint.latitude) * segmentProgress;
            final interpolatedLng = currentPoint.longitude + 
                (nextPoint.longitude - currentPoint.longitude) * segmentProgress;
            
            animatedRoute[animatedRoute.length - 1] = LatLng(interpolatedLat, interpolatedLng);
          }
        }
        
        onUpdate(animatedRoute);
      }
    });

    return animationController;
  }

  /// Animates the route snapping process with a smooth curve effect
  static AnimationController createSnapAnimation({
    required TickerProvider vsync,
    required List<LatLng> originalRoute,
    required List<LatLng> snappedRoute,
    required Function(List<LatLng>) onUpdate,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    final animationController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    );

    animation.addListener(() {
      final progress = animation.value;
      final animatedRoute = <LatLng>[];

      // Interpolate between original and snapped routes
      final pointCount = originalRoute.length.clamp(0, snappedRoute.length);
      
      for (int i = 0; i < pointCount; i++) {
        final originalIndex = (i * (originalRoute.length - 1) / (pointCount - 1).clamp(1, double.infinity)).round();
        final snappedIndex = (i * (snappedRoute.length - 1) / (pointCount - 1).clamp(1, double.infinity)).round();
        
        if (originalIndex < originalRoute.length && snappedIndex < snappedRoute.length) {
          final originalPoint = originalRoute[originalIndex];
          final snappedPoint = snappedRoute[snappedIndex];
          
          final interpolatedLat = originalPoint.latitude + 
              (snappedPoint.latitude - originalPoint.latitude) * progress;
          final interpolatedLng = originalPoint.longitude + 
              (snappedPoint.longitude - originalPoint.longitude) * progress;
          
          animatedRoute.add(LatLng(interpolatedLat, interpolatedLng));
        }
      }

      onUpdate(animatedRoute);
    });

    return animationController;
  }

  /// Creates a pulsing animation for route markers
  static AnimationController createPulseAnimation({
    required TickerProvider vsync,
    required Function(double) onUpdate,
    Duration duration = const Duration(seconds: 1),
  }) {
    final animationController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    final animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));

    animation.addListener(() {
      onUpdate(animation.value);
    });

    return animationController;
  }

  /// Creates a fade-in animation for UI elements
  static AnimationController createFadeInAnimation({
    required TickerProvider vsync,
    required Function(double) onUpdate,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final animationController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    animation.addListener(() {
      onUpdate(animation.value);
    });

    return animationController;
  }

  /// Creates a slide animation for page transitions
  static Widget createSlideTransition({
    required Widget child,
    required AnimationController controller,
    SlideDirection direction = SlideDirection.left,
  }) {
    late Offset beginOffset;
    late Offset endOffset;

    switch (direction) {
      case SlideDirection.left:
        beginOffset = const Offset(1.0, 0.0);
        endOffset = Offset.zero;
        break;
      case SlideDirection.right:
        beginOffset = const Offset(-1.0, 0.0);
        endOffset = Offset.zero;
        break;
      case SlideDirection.up:
        beginOffset = const Offset(0.0, 1.0);
        endOffset = Offset.zero;
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0.0, -1.0);
        endOffset = Offset.zero;
        break;
    }

    final slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: endOffset,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: child,
    );
  }
}

enum SlideDirection {
  left,
  right,
  up,
  down,
}