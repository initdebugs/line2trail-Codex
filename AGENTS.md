# Repository Guidelines

## Project Structure & Module Organization
- Source: `lib/` organized by features and layers
  - `lib/features/` (e.g., `map/`, `navigation/`, `routes/`): screens, widgets, models, services per feature
  - `lib/shared/`: cross‑feature widgets and services (e.g., `routing_service.dart`)
  - `lib/core/`: app‑wide theme, colors, constants
  - Entry point: `lib/main.dart`
- Platform: `android/` for Android config and manifests
- Tests: `test/` with `*_test.dart`

## Build, Test, and Development Commands
- Install deps: `flutter pub get`
- Analyze code: `dart analyze`
- Format code: `dart format .`
- Run tests: `flutter test` (coverage: `flutter test --coverage`)
- Run app (Android): `flutter run -d android`
- Build release APK: `flutter build apk --release`

## Coding Style & Naming Conventions
- Style: Dart with `flutter_lints` (see `analysis_options.yaml`)
- Indentation: 2 spaces; line length ~80–100 chars
- Naming: `lowerCamelCase` for vars/methods, `PascalCase` for classes, `snake_case.dart` for files (e.g., `main_navigation.dart`)
- Imports: prefer relative within `lib/` feature boundaries
- Widgets: keep small, composable; move shared UI to `lib/shared/widgets/`

## Testing Guidelines
- Framework: `flutter_test`
- Location: place tests under `test/` mirroring `lib/` paths
- Naming: `*_test.dart`; use clear `group()` and `test()` descriptions
- Expectations: add/extend tests with new features; keep `flutter test` and `dart analyze` green locally

## Commit & Pull Request Guidelines
- Commits: concise, imperative subject (e.g., "feat(map): add route snapping")
- PRs: include purpose, scope, and screenshots for UI changes; reference issues (e.g., `Closes #123`)
- Checks: ensure `dart analyze` and `flutter test` pass; run `dart format .`
- Scope: keep PRs small and feature‑focused; update docs when structure or behavior changes

## Architecture Overview
- Feature‑first: isolate domain UI/logic under `lib/features/<feature>/`
- Shared services: cross‑cutting utilities in `lib/shared/services/` (e.g., location, routing)
- Theming: centralized in `lib/core/theme/` with light/dark modes

## Security & Configuration Tips
- Location permissions: ensure runtime prompts and Android manifest entries align with `geolocator`/`permission_handler`
- Secrets: do not commit API keys; use runtime config or platform‑secure storage
