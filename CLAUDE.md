# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Pathify** (internal name: line2trail) is a Flutter mobile application for drawing custom routes for hiking, running, cycling, and walking. Users draw routes on a map with finger gestures, and the app automatically snaps paths to walkable/cyclable roads using OpenRouteService API, provides elevation profiles, and generates roundtrip routes.

## Development Commands

### Core Flutter Commands
- `flutter pub get` - Install dependencies
- `flutter run` - Run the app in debug mode
- `flutter run --release` - Run in release mode
- `flutter analyze` - Run static analysis and lint checks
- `dart format lib test` - Format code
- `flutter clean` - Clean build artifacts
- `flutter pub upgrade` - Upgrade dependencies

### Testing Commands
- `flutter test -r expanded` - Run all tests with expanded output
- `flutter test test/routing_test.dart` - Run routing service tests
- `flutter test test/roundtrip_generation_test.dart` - Run roundtrip generation tests
- `flutter test test/fast_roundtrip_test.dart` - Run fast roundtrip service tests
- `flutter test test/activity_specific_roundtrip_test.dart` - Run activity-specific roundtrip tests

### Build Commands
- `flutter build apk` - Build Android APK
- `flutter build appbundle` - Build Android App Bundle for Play Store
- `cd android && ./gradlew build` - Build Android project directly
- `cd android && ./gradlew clean` - Clean Android build

## Code Architecture

### Project Structure
```
lib/
├── main.dart                    # App entry point (PathifyApp with MaterialApp)
├── core/                        # App-wide constants, themes, and services
│   ├── constants/
│   │   ├── activity_types.dart  # ActivityType enum (walking, running, cycling, hiking)
│   │   └── map_layers.dart      # Map layer configurations
│   ├── l10n/                    # Localization (Dutch-only)
│   │   ├── app_strings.dart     # Base strings interface
│   │   └── strings_nl.dart      # Dutch translations
│   ├── services/
│   │   ├── localization_service.dart  # Localization management
│   │   └── settings_service.dart      # SharedPreferences wrapper for settings
│   ├── theme/                   # Material 3 theme
│   │   ├── app_colors.dart      # Color palette (outdoor/trail-inspired)
│   │   └── app_theme.dart       # Light/dark theme definitions
│   └── utils/
│       └── distance_formatter.dart    # Format distances with metric/imperial
├── features/                    # Feature modules (feature-first architecture)
│   ├── map/                     # Map and route drawing
│   │   ├── models/
│   │   │   └── route_drawing_state.dart  # Route state and history
│   │   ├── screens/
│   │   │   └── map_screen.dart           # Main map screen with drawing logic
│   │   ├── services/
│   │   │   └── route_editing_service.dart  # Route manipulation (split, merge, insert)
│   │   └── widgets/             # Map UI components (waypoint markers, controls, etc.)
│   ├── navigation/              # Bottom navigation wrapper
│   │   └── screens/
│   │       └── main_navigation.dart  # 4-tab navigation
│   ├── routes/                  # Saved routes management
│   │   ├── models/
│   │   │   └── saved_route.dart      # Route data model with elevation
│   │   ├── screens/
│   │   │   ├── routes_screen.dart    # Routes list
│   │   │   └── route_details_screen.dart  # Route details with elevation chart
│   │   ├── services/
│   │   │   └── route_storage_service.dart  # SQLite persistence
│   │   └── widgets/             # Route cards, elevation chart, map preview
│   └── settings/                # Settings screen
│       └── screens/
│           └── settings_screen.dart
└── shared/                      # Shared services and widgets
    ├── services/                # Core business logic services
    │   ├── location_service.dart           # GPS location with permissions
    │   ├── routing_service.dart            # OpenRouteService API integration
    │   ├── elevation_service.dart          # Open-Meteo elevation API
    │   ├── geocoding_service.dart          # Address search
    │   ├── haptic_feedback_service.dart    # Haptic feedback wrapper
    │   ├── path_analysis_service.dart      # Path type breakdown analysis
    │   ├── roundtrip_generation_service.dart  # Slow strategic roundtrip generation
    │   └── fast_roundtrip_service.dart     # Fast geometric roundtrip generation
    └── widgets/                 # Reusable UI components
        └── activity_mode_selector.dart
```

### Key Architecture Patterns
- **Feature-first organization**: Code organized by feature (map, routes, settings) rather than by layer
- **Service layer pattern**: Business logic encapsulated in stateless services under `shared/services/` and feature-specific `services/`
- **Widget composition**: Complex UI built from smaller, focused widgets with clear responsibilities
- **State management**: StatefulWidget with explicit state classes; Provider available but not yet integrated
- **Graceful degradation**: External APIs (routing, elevation) have fallback implementations when services fail

### Critical Services Architecture

#### Routing Services (lib/shared/services/)
- **RoutingService**: OpenRouteService API integration for path snapping
  - Attempts real API first, falls back to mock geometric routing on failure
  - Supports mixed-mode routing (tries alternative activity types when primary fails)
  - Activity-specific profiles: `foot-walking`, `foot-hiking`, `cycling-regular`
- **RoundtripGenerationService**: Strategic waypoint-based roundtrip generation (slower, more realistic)
- **FastRoundtripService**: Geometric circle-based roundtrip generation (faster, simpler)

#### Location & Elevation Services
- **LocationService**: GPS location with permission handling via `geolocator` and `permission_handler`
- **ElevationService**: Fetches elevation profiles from Open-Meteo API, falls back to synthetic profiles
- **GeocodingService**: Address search and geocoding

#### Route Management Services
- **RouteEditingService**: Pure functions for route manipulation (split, merge, insert points)
  - Stateless utility class, no instance state
  - Used by MapScreen for undo/redo functionality
- **RouteStorageService**: SQLite persistence for saved routes using `sqflite`
- **PathAnalysisService**: Analyzes path composition (footpath/cycleway/road percentages)

#### Settings & Preferences
- **SettingsService**: SharedPreferences wrapper for user settings (units, default activity, waypoint visibility, speed preferences)
- **LocalizationService**: Dutch-only localization (language settings removed)

### Key Dependencies
- **flutter_map** (^7.0.2): Interactive map widget with OpenStreetMap tiles
- **latlong2** (^0.9.0): Geographic coordinate calculations and distance utilities
- **geolocator** (^13.0.1): GPS location access
- **permission_handler** (^11.3.1): Runtime permissions for location
- **dio** (^5.4.3+1): HTTP client for routing and elevation API calls
- **sqflite** (^2.3.3+1): Local SQLite database for route storage
- **provider** (^6.1.2): State management (available but not yet integrated)
- **shared_preferences** (^2.2.3): Persistent key-value storage for settings

### Testing Strategy
Tests mirror the `lib/` structure with `*_test.dart` naming:
- **test/widget_test.dart**: Basic widget tests
- **test/routing_test.dart**: RoutingService tests (API integration and fallback)
- **test/roundtrip_generation_test.dart**: RoundtripGenerationService tests
- **test/fast_roundtrip_test.dart**: FastRoundtripService tests
- **test/activity_specific_roundtrip_test.dart**: Activity-specific roundtrip generation tests

### Important Implementation Details

#### Activity Types (core/constants/activity_types.dart)
- Enum: `walking`, `running`, `hiking`, `cycling`
- Each has: `displayName` (Dutch), `icon`, `routingProfile` (OpenRouteService profile), `averageSpeed` (km/h)
- Running uses same profile as walking (`foot-walking`) but different average speed

#### Map & Drawing (features/map/screens/map_screen.dart)
- MapScreen is a complex StatefulWidget with TickerProviderStateMixin for animations
- Drawing mode: tap to add waypoints, routes snap to paths via RoutingService
- Maintains `_currentRoute` (user taps) and `_snappedRoute` (snapped path)
- Route history with undo/redo via RouteDrawingHistory model
- Kilometer markers placed along route at regular intervals
- Roundtrip mode: generates circular routes from a starting point with target distance

#### Route Storage & Details
- SavedRoute model includes: name, distance, duration, elevation profile, activity type, coordinates
- RouteDetailsScreen shows: map preview, stats, elevation chart (ElevationChart widget), path type breakdown
- Elevation chart is an interactive widget showing ascent/descent profile

#### Localization
- **Dutch-only app**: All UI text is in Dutch
- Language settings have been intentionally removed
- Localization structure exists under `core/l10n/` but only Dutch (StringsNL) is active
- When adding UI text, use Dutch labels directly or via StringsNL

#### UI/UX Design
- Material 3 design with custom outdoor/trail-inspired color palette
- Bottom navigation: Kaart (Map), Routes, Navigeren (Navigate), Instellingen (Settings)
- Smooth animations for mode transitions (draw mode on/off) using AnimationController
- Haptic feedback on interactions via HapticFeedbackService
- Search bar and stats panel animate in/out when entering/exiting draw mode

#### External API Integration
- OpenRouteService: path snapping (no API key required, uses public endpoint with rate limits)
- Open-Meteo: elevation data (no API key required)
- Both APIs have fallback implementations for offline/failure scenarios
- API failures are logged via debugPrint but should not crash the app

#### Current Known Issues (see next_steps.md)
- Route bar animations incomplete (instant transitions instead of animated)
- Search bar and time/distance widget animations partially implemented
- Route detail map preview missing start/end point markers