# line2trail

Path planning and route management in Flutter, organized feature-first.

## Build & Dev
- Install deps: `flutter pub get`
- Analyze: `flutter analyze`
- Format: `dart format lib test`
- Run app: `flutter run`
- Tests: `flutter test -r expanded`

## Project Structure
- `lib/`: core, features, and shared modules (feature-first).
- `test/`: mirrors `lib/` paths (`*_test.dart`).
- `android/`: platform config and builds.

## Roadmap
- The short-term plan focuses on a new Route Details screen: small map preview, key stats, path type breakdown (footpath/cycle/road), and elevation profile.
- See `docs/ROADMAP.md` for the full, actionable spec integrating `next_steps.md`.
