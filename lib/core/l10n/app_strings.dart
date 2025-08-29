import 'package:flutter/material.dart';
import 'strings_nl.dart';

abstract class AppStrings {
  // Navigation
  String get map;
  String get routes;
  String get navigate;
  String get settings;
  
  // Map Screen
  String get draw;
  String get stop;
  String get distance;
  String get time;
  String get duration;
  String get today;
  String get yesterday;
  String get chooseActivity;
  
  // Route Tools
  String get undo;
  String get redo;
  String get clear;
  String get show;
  String get hide;
  String get more;
  
  // Routes Screen
  String get myRoutes;
  String get searchRoutes;
  String get all;
  String get share;
  String get delete;
  String get deleteRoute;
  String get deleteRouteConfirm;
  String get cancel;
  String get save;
  String get saveRoute;
  String get saveRoutePrompt;
  String get routeSavedSuccess;
  String get routeSaveError;
  String get routeDeleted;
  String get routeDeleteError;
  String get navigateRoute;
  String get routeNavigateComingSoon;
  
  // Activity Types
  String get walking;
  String get running;
  String get hiking;
  String get cycling;
  
  // Settings
  String get waypointsVisible;
  String get waypointsVisibleSubtitle;
  String get defaultMode;
  String get defaultModeSubtitle;
  String get language;
  String get languageSubtitle;
  
  // Settings Sections
  String get routeSettings;
  String get appSettings;
  String get mapSettings;
  String get routeRecording;
  String get notifications;
  String get dataPrivacy;
  String get about;
  
  // Map Settings
  String get mapTheme;
  String get mapThemeSubtitle;
  String get units;
  String get unitsSubtitle;
  String get showCompass;
  String get showCompassSubtitle;
  
  // Route Recording Settings
  String get gpsAccuracy;
  String get gpsAccuracySubtitle;
  String get autoPause;
  String get autoPauseSubtitle;
  String get recordingInterval;
  String get recordingIntervalSubtitle;
  
  // Notification Settings
  String get routeNotifications;
  String get routeNotificationsSubtitle;
  String get achievementNotifications;
  String get achievementNotificationsSubtitle;
  
  // Data & Privacy
  String get exportRoutes;
  String get exportRoutesSubtitle;
  String get clearData;
  String get clearDataSubtitle;
  String get privacyPolicy;
  String get privacyPolicySubtitle;
  
  // About
  String get appVersion;
  String get appVersionSubtitle;
  String get feedback;
  String get feedbackSubtitle;
  String get licenses;
  String get licensesSubtitle;
  
  // Time Formats
  String get daysAgo;
  String get minutesShort;
  String get hoursShort;
  
  // Messages
  String get featureComingSoon;
  String get featureInDevelopment;
  String get locationPermissionNeeded;
  String get layerOptionsComingSoon;
  String get offlineMapsComingSoon;
  String get gpxImportComingSoon;
  String get tutorialComingSoon;
  String get moreRouteOptionsComingSoon;
  String get routeNeedsThreePoints;
  String get tapWaypointToSplit;
  String get tapWaypointsToSelectSegment;
  String get routeReversed;
  String get routeSimplified;
  String get cannotSplitAtEndpoint;
  String get routeSplit;
  String get routeSplitDescription;
  String get whichSegmentToKeep;
  String get keepFirst;
  String get keepSecond;
  String get segmentKept;
  String get roundtripGenerator;
  
  // Dialog Actions
  String get ok;
  String get yes;
  String get no;
  
  // Waypoint Actions
  String get splitRouteHere;
  String get removeWaypoint;
  String get setToCurrentLocation;

  // Static method to get strings based on locale
  static AppStrings of(BuildContext context) {
    // Dutch-only app
    return StringsNl();
  }
  
  // Static method to get strings by language code
  static AppStrings byLanguage(String languageCode) {
    // Dutch-only app
    return StringsNl();
  }
}
