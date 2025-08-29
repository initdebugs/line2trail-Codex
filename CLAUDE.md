# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Line2Trail is a Flutter mobile application for drawing custom routes for hiking, running, cycling, and walking. The app allows users to draw routes on a map with finger gestures, automatically snaps drawn paths to walkable/cyclable roads, and provides route statistics.

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the app in debug mode
- `flutter run --release` - Run the app in release mode
- `flutter build apk` - Build Android APK
- `flutter build appbundle` - Build Android App Bundle for Play Store
- `flutter test` - Run all tests
- `flutter analyze` - Run static analysis and lint checks
- `flutter clean` - Clean build artifacts
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

### Testing Commands
- `flutter test test/widget_test.dart` - Run specific widget tests
- `flutter test test/routing_test.dart` - Run routing service tests

### Platform-specific Build Commands
- **Android**: `cd android && ./gradlew build` - Build Android project
- **Android Clean**: `cd android && ./gradlew clean` - Clean Android build

## Code Architecture

### Project Structure
```
lib/
├── main.dart                    # App entry point
├── core/                        # App-wide constants and themes
│   ├── constants/
│   │   └── activity_types.dart  # Walking, running, cycling, hiking enums
│   └── theme/                   # Material 3 theme configuration
│       ├── app_colors.dart      # Color palette
│       └── app_theme.dart       # Light/dark theme definitions
├── features/                    # Feature modules
│   ├── map/                     # Map and route drawing functionality
│   │   ├── models/              # Route data models
│   │   ├── screens/             # Map screen UI
│   │   ├── services/            # Route editing business logic
│   │   └── widgets/             # Map controls and UI components
│   ├── navigation/              # Bottom navigation
│   │   └── screens/             # Main navigation wrapper
│   └── routes/                  # Saved routes management
│       ├── screens/             # Routes list screen
│       └── widgets/             # Route cards and UI
└── shared/                      # Shared services and widgets
    ├── services/                # Location and routing services
    └── widgets/                 # Reusable UI components
```

### Key Architecture Patterns
- **Feature-based organization**: Each major feature (map, routes, navigation) has its own directory
- **Service layer pattern**: Location and routing logic separated into services
- **Widget composition**: Complex screens built from smaller, reusable widgets
- **State management**: Currently using StatefulWidget, preparing for Provider integration
- **Mock services**: Routing service has mock fallback for development without API keys

### Core Services
- **LocationService**: GPS location handling with permission management
- **RoutingService**: Path snapping using OpenRouteService API with mock fallback
- **RouteEditingService**: Route manipulation (undo, redo, waypoint editing)

### Key Dependencies
- `flutter_map`: Interactive map widget with OpenStreetMap tiles
- `latlong2`: Geographic coordinate calculations
- `geolocator`: GPS location access
- `dio`: HTTP client for routing API calls
- `provider`: State management (planned integration)
- `sqflite`: Local database for route storage (planned)

### Current Development Status
The app is in Phase 3 of development (see DEVELOPMENT_PLAN.md):
- ✅ Phases 1-2: Basic map, route drawing, and path snapping completed
- 🚧 Phase 3: Route analysis and statistics (partially complete)
- 📋 Phases 4-9: Navigation, data management, offline support, and release preparation

### Testing Strategy
- Widget tests for UI components (`test/widget_test.dart`)
- Service tests for routing functionality (`test/routing_test.dart`)
- Uses standard Flutter testing framework with `flutter_test`

### Key Implementation Notes
- Map uses OpenStreetMap tiles via flutter_map
- Route snapping attempts real OpenRouteService API, falls back to mock service
- Activity types support different routing profiles (walking, cycling, etc.)
- Theme follows Material 3 design system with custom outdoor/trail-inspired colors
- Bottom navigation with 4 tabs: Kaart (Map), Routes, Navigeren (Navigate), Instellingen (Settings)
- **Language**: App interface is in Dutch by default, with English as secondary option in settings
- All user-facing text, labels, buttons, and messages should be in Dutch
- Settings screen includes comprehensive placeholder options for future features