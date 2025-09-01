# Repository Guidelines

## Project Structure & Modules

- lib/: application code organized by feature.
  - core/: theming, services, utils, constants, l10n.
  - features/: feature folders (map, routes, navigation, settings).
  - shared/: cross‑feature widgets/services.
  - main.dart: app entry (`PathifyApp`).
- test/: Dart/Flutter tests mirroring `lib/` (e.g., `lib/features/routes/...` → `test/features/routes/...`).
- android/: Android Gradle project; use for platform config and builds.

## Build, Test, and Dev Commands

- Install deps: `flutter pub get`
- Analyze code: `flutter analyze`
- Format code: `dart format lib test` (or `flutter format .`)
- Run app: `flutter run` (choose device/emulator)
- Run tests: `flutter test -r expanded`
- Coverage (optional): `flutter test --coverage`
- Android release: `flutter build apk --release`

## Coding Style & Naming

- Language: Dart (Flutter). Follow `flutter_lints` in `analysis_options.yaml`.
- Indentation: 2 spaces; no tabs.
- Files: `snake_case.dart` (e.g., `saved_route.dart`).
- Types/Widgets: `PascalCase`; methods/fields: `camelCase`.
- Folders by role: `models/`, `services/`, `screens/`, `widgets/` per feature.
- Avoid `print`; prefer logging/services; keep widget build methods pure.

## Testing Guidelines

- Framework: `flutter_test`.
- Location: mirror `lib/` paths; name files `*_test.dart`.
- Structure: use `group()` for features; prefer widget tests for UI and unit tests for services/utils.
- Run locally: `flutter test`; ensure tests pass before PR.

## Commit & Pull Requests

- Commit style: Prefer Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`).
  - Examples: `feat(routes): add GPX import`, `fix(map): correct marker tap area`.
  - Keep messages imperative and scoped. Current history mixes styles; new commits should standardize on the above.
- PR checklist:
  - Clear description and rationale; link issues (`Closes #123`).
  - Screenshots/screencasts for UI changes.
  - Include tests or explain why not; all checks green (`analyze`, tests, format).

## Security & Configuration

- Do not commit secrets/keys. Android settings like SDK paths belong in `android/local.properties` (ignored).
- Assets: declare in `pubspec.yaml` (`assets:`). Keep large binaries out of git.

## Architecture Notes

- Feature‑first structure; keep shared code in `shared/` and cross‑cutting concerns in `core/`.
- Prefer dependency injection via constructors; keep `StatefulWidget` state minimal and use services/providers where needed.

