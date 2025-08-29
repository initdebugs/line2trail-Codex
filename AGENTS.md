# Repository Guidelines

## Project Structure & Modules
- `lib/core`: app-wide constants, services, theme, i18n.
- `lib/features`: vertical features (map, routes, navigation, settings) with `models/`, `services/`, `widgets/`, `screens/`.
- `lib/shared`: cross-feature services and widgets.
- `test/`: Flutter/Dart tests (`*_test.dart`).
- `android/`: Android build config; update permissions here.
- `pubspec.yaml`: dependencies, assets (e.g., `logo.png`).

## Build, Test, and Development
- Install: `flutter pub get` — fetches dependencies.
- Run (device): `flutter run` — launches the app on a connected device/emulator.
- Run (web): `flutter run -d chrome` — web debug build.
- Tests: `flutter test` — runs unit/widget tests in `test/`.
- Lint: `dart analyze` — static analysis using `flutter_lints`.
- Clean: `flutter clean` — resets build artifacts.
- Release Android: `flutter build apk --release`.

## Coding Style & Naming
- Indentation: 2 spaces; no tabs.
- Files: `snake_case.dart` (e.g., `route_storage_service.dart`).
- Types/widgets: UpperCamelCase; members/locals: lowerCamelCase; constants: lowerCamelCase `const` unless enum.
- Strings: prefer `l10n` entries under `lib/core/l10n/` for user-facing text.
- The analyzer is configured via `analysis_options.yaml`; fix all warnings.

## Testing Guidelines
- Frameworks: `flutter_test` with `testWidgets` for UI; pure Dart tests for utils.
- Location: mirror `lib/` structure under `test/`.
- Names: `*_test.dart` (e.g., `routing_service_test.dart`).
- Run locally: `flutter test`; aim to keep tests hermetic (mock I/O and network).

## Commit & Pull Requests
- Messages: use Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`, `test:`). First line ≤ 72 chars.
- Scope by feature when helpful (e.g., `feat(map): add route snapping`).
- PRs: include summary, linked issues, test plan, and screenshots for UI changes. Keep diffs focused and pass `dart analyze` + `flutter test`.

## Security & Configuration
- Do not hardcode secrets. Pass runtime config via `--dart-define=KEY=VALUE` and read in code.
- For location features, ensure Android permissions are updated in `android/app/src/main/AndroidManifest.xml`.
