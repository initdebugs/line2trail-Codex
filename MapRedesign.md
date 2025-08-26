# Map Screen Redesign Plan

## Objectives
- Keep route drawing via map taps unchanged.
- Reduce button clutter; make controls obvious, grouped, and thumb‑reachable.
- Surface live stats (distance/time) and primary actions contextually.

## Proposed Layout
- Bottom Route Bar (persistent): pill‑style segmented activity selector + live stats + primary Draw toggle.
- Contextual Tool Row (appears when a route exists): Undo, Redo, Snap/Original toggle, Waypoints, Clear, More (⋯).
- Compact Map Rail (top‑right): Locate me, Layers (small square buttons, stacked).
- Inline Hints: lightweight banner when Draw is enabled; snackbars for mode changes.

## Controls & Behavior
- Activity selector: 4 compact segments (Walk/Run/Bike/Hike). Changing re‑snaps route if applicable.
- Draw toggle: single prominent pill; On = taps add points, Off = navigate map normally.
- Snap toggle: switch between snapped path and original taps.
- Waypoints: toggles draggable waypoint handles; tap waypoint opens actions (split/remove).
- More (⋯): opens sheet with Reverse, Simplify, Split, Export/Save (future), GPX import (future).

## Visual Style
- Material 3, rounded 12–16dp, elevation 2–8.
- Touch targets ≥ 44dp, labels on non‑obvious icons.
- Theming via `lib/core/theme` colors; dark mode respected.

## Implementation Plan
1) Route Bar widget
- New: `lib/features/map/widgets/route_bar.dart`
  - Left: `ActivitySegmentedSelector` (or refactor existing `ActivityModeSelector` to compact segmented form).
  - Center: stats (distance/time) derived from current/snapped route.
  - Right: `Draw` pill button (selected state mirrors `_isDrawingMode`).

2) Contextual Tool Row
- New: `lib/features/map/widgets/route_tools.dart`
  - Buttons: Undo, Redo, Snap, Waypoints, Clear, More.
  - Visible only when `_currentRoute` or `_snappedRoute` non‑empty.

3) Map Rail
- Replace ad‑hoc FAB stack with `MapControlRail` in `lib/features/map/widgets/map_control_rail.dart` (reuse logic from `map_controls.dart`).

4) Screen integration
- In `map_screen.dart`:
  - Remove `_buildModernActivitySelector/_buildModernActionButtons/_buildModernRouteStats` overlays.
  - Add bottom‑center `RouteBar` and, above it, `RouteTools` when route exists.
  - Keep `onTap: _isDrawingMode ? _onMapTap : null` unchanged.
  - Keep existing handlers: `_toggleDrawingMode`, `_toggleMixedRouting`, `_toggleWaypointMode`, `_undo/redo`, `_clearRoute`, `_snapCurrentRoute`.

5) Motion & polish
- Use `AnimatedSlide/Opacity` for showing/hiding bars; `AnimatedSwitcher` for Draw state.
- Provide `Semantics`/`tooltip` for all actions.

## File/Refactor Map
- Add: `widgets/route_bar.dart`, `widgets/route_tools.dart`, `widgets/map_control_rail.dart`, optional `widgets/activity_segmented_selector.dart`.
- Update: `map_screen.dart` overlay composition only; no logic changes to tapping/drawing.

## QA Checklist
- Tapping to draw works identically; undo/redo/snap behave as before.
- One‑handed reach: primary controls usable at bottom on phones.
- Analyzer/tests pass: `dart analyze`, `flutter test`.
