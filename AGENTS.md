# Repository Guidelines

## Project Structure & Module Organization
- Source: `lib/` organized by feature.
  - `lib/core/`: theming, services, utils, constants, l10n.
  - `lib/features/<feature>/`: `models/`, `services/`, `screens/`, `widgets/`.
  - `lib/shared/`: cross‑feature widgets/services.
  - `lib/main.dart`: app entry (`PathifyApp`).
- Tests: mirror `lib/` under `test/` (e.g., `lib/features/routes/...` → `test/features/routes/...`).
- Android: `android/` for platform config and builds.
- Assets: declare in `pubspec.yaml` under `assets:`.

## Build, Test, and Development Commands
- Install deps: `flutter pub get`
- Analyze code: `flutter analyze`
- Format code: `dart format lib test` (or `flutter format .`)
- Run app: `flutter run` (select a device/emulator)
- Run tests (verbose): `flutter test -r expanded`
- Coverage (optional): `flutter test --coverage`
- Android release: `flutter build apk --release`

## Coding Style & Naming Conventions
- Language: Dart (Flutter) with `flutter_lints` (see `analysis_options.yaml`).
- Indentation: 2 spaces; no tabs.
- Files: `snake_case.dart`; types/widgets in `PascalCase`; fields/methods in `camelCase`.
- Avoid `print`; prefer logging/services. Keep widget `build` methods pure and side‑effect free.
- Organize features first; keep cross‑cutting code in `core/` and shared UI in `shared/`.

## Testing Guidelines
- Framework: `flutter_test`.
- Location: mirror `lib/`; name files `*_test.dart`.
- Structure: use `group()` per feature; prefer widget tests for UI and unit tests for services/utils.
- Run locally: `flutter test`; ensure all tests pass before opening a PR.

## Commit & Pull Request Guidelines
- Commits: follow Conventional Commits.
  - Examples: `feat(routes): add GPX import`, `fix(map): correct marker tap area`.
- PRs: include clear description and rationale; link issues (e.g., `Closes #123`). Attach screenshots/screencasts for UI changes. Include tests or explain why not. Ensure `flutter analyze`, tests, and formatting all pass.

## Security & Configuration
- Do not commit secrets/keys. Keep Android SDK paths in `android/local.properties` (git‑ignored).
- Declare assets in `pubspec.yaml`. Avoid large binaries in git.
- Prefer dependency injection via constructors; keep `StatefulWidget` state minimal.

