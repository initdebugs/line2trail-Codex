## Project Overview

This is a Flutter project named `pathify`. It's a mobile application designed as a "draw-your-own-route" planner for activities like hiking, running, cycling, and walking.

The application allows users to draw a route on a map, and it will snap the drawn path to actual roads and trails. It can calculate the distance and estimated time for the route based on the selected activity. Users can also save their routes for later use.

The project uses the following key technologies:

*   **Flutter:** For building the cross-platform mobile application.
*   **flutter_map:** For displaying the map and route overlays.
*   **geolocator:** For accessing the device's location.
*   **permission_handler:** For requesting location permissions.
*   **provider:** For state management.
*   **sqflite:** For local storage of saved routes.

The application's architecture is based on a feature-driven structure, with separate directories for features like `map`, `routes`, and `settings`. The UI is built with Material Design components.

## Building and Running

To build and run this project, you will need to have the Flutter SDK installed.

1.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Run the application:**
    ```bash
    flutter run
    ```

## Development Conventions

*   **Coding Style:** The project follows the standard Dart and Flutter coding conventions, as enforced by the `flutter_lints` package.
*   **Testing:** The project has a `test` directory with some basic widget and routing tests. To run the tests, use the following command:
    ```bash
    flutter test
    ```
*   **File Naming:** Files are named using `snake_case.dart`.
*   **Directory Structure:** The `lib` directory is organized by feature, with subdirectories for `screens`, `widgets`, `services`, and `models`.
