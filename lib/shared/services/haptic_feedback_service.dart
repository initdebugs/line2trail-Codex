import 'package:flutter/services.dart';

/// Service for providing haptic feedback throughout the app
class HapticFeedbackService {
  /// Light impact feedback for subtle interactions
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact feedback for standard interactions
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact feedback for important actions
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection click feedback for UI element selection
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Success feedback for completed actions
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Error feedback for failed actions
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Drawing feedback for route drawing actions
  static Future<void> drawingFeedback() async {
    await HapticFeedback.lightImpact();
  }

  /// Route completed feedback for finishing a route
  static Future<void> routeCompleted() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.lightImpact();
  }
}