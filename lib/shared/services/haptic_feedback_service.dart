import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class HapticFeedbackService {
  static bool _isEnabled = true;

  /// Enable or disable haptic feedback system-wide
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if haptic feedback is currently enabled
  static bool get isEnabled => _isEnabled;

  /// Light impact - for subtle feedback (taps, selections)
  static Future<void> lightImpact() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Light haptic feedback failed: $e');
    }
  }

  /// Medium impact - for standard actions (button presses, toggles)
  static Future<void> mediumImpact() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Medium haptic feedback failed: $e');
    }
  }

  /// Heavy impact - for significant actions (deletions, completions)
  static Future<void> heavyImpact() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Heavy haptic feedback failed: $e');
    }
  }

  /// Selection click - for navigation and mode changes
  static Future<void> selectionClick() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Selection haptic feedback failed: $e');
    }
  }

  /// Vibrate pattern - for errors or important notifications
  static Future<void> vibrate() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      debugPrint('Vibrate haptic feedback failed: $e');
    }
  }

  /// Success pattern - for completed actions
  static Future<void> success() async {
    await mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await lightImpact();
  }

  /// Error pattern - for failed actions
  static Future<void> error() async {
    await heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await heavyImpact();
  }

  /// Drawing feedback - light feedback for route drawing
  static Future<void> drawingFeedback() async {
    await lightImpact();
  }

  /// Route completed feedback - celebration pattern
  static Future<void> routeCompleted() async {
    await success();
    await Future.delayed(const Duration(milliseconds: 100));
    await lightImpact();
  }
}