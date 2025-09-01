# New Features (Offline‑First)

## Route Editing & Management

- Smart snap-to-trail (offline):
  - Value: Draw clean routes that follow paths without internet.
  - UX: Toggle “Snap” in map toolbar; long‑press to add/move vertices; hold to disable snap temporarily.
  - Tech: Build a lightweight spatial index (R‑tree) over locally cached polylines; fallback to geometric smoothing. Integrate in `shared/services/routing_service.dart` with an offline mode flag.
- Advanced edit tools:
  - Split/merge routes; reverse direction; trim start/end; simplify polyline with tolerance.
  - Store edit history per route for undo/redo (persist last N operations in `sqflite`).
- Waypoints & POIs:
  - Categories (water, view, transit, hazards), icons, notes, photos (file paths only).
  - Tech: `features/routes/models/` for `Waypoint`; `shared/widgets/` for quick‑add.

## Navigation & Guidance

- On‑device turn prompts:
  - Value: Guidance without cloud calls.
  - UX: Big arrow card + distance; optional haptic cues; off‑route buzzer >30m.
  - Tech: Local turn detection from polyline geometry; `flutter_tts` optional; reuse `HapticFeedbackService`.
- Off‑route detection:
  - Periodic nearest‑segment search; alert when distance threshold exceeded; quick “Rejoin route” action.
- Track recording:
  - Record GPX locally with pause/resume/auto‑split; show live stats (pace, ascent, distance).

## Offline Maps & Data

- Tile caching & MBTiles:
  - Value: Full offline map browsing.
  - UX: “Download area for offline use” (bounding box, size estimate).
  - Tech: `flutter_map` with file cache; support `.mbtiles` import; hillshade/contour overlays as optional MBTiles.
- Elevation profile & colorized path:
  - Pre‑download DEM tiles (SRTM/ASTER) by region; compute ascent, grade, and segment difficulty.
  - UI: Profile chart with tappable cursor; polyline colored by grade.
- Offline routing fallback:
  - Basic: snap to cached polylines + A* over a simplified local graph built from imported vector data.
  - Configurable per activity (walking/running/cycling/hiking) via cost weights.

## Import/Export & Interop (Local Only)

- GPX/KML import/export:
  - Import routes/waypoints; merge/split; de‑dup by checksum.
  - Export with metadata (activity, total ascent, surfaces) to `Downloads/Pathify/`.
- Nearby/air‑gap sharing:
  - Share files via QR (short GPX), local Wi‑Fi hotspot, or Bluetooth—no accounts/servers.

## Analysis & Planning

- Loop generator upgrades:
  - Inputs: distance, direction bias, avoid repeats, surface preference.
  - Outputs: multiple candidates with quality score (distance fit, turn cost, variety); uses `RoundtripGenerationService` + `FastRoundtripService`.
- Segment library:
  - Save frequent sections; suggest “stitching” segments into new routes.
- Constraints & alerts:
  - Max gradient, unpaved ratio, road type exposure; warn and suggest edits.

## UX & Accessibility

- Gesture toolkit: two‑finger measure, long‑press waypoint, drag handle to reorder points.
- Map styles: day/night/high‑contrast; large labels; colorblind‑safe palettes.
- Quick presets: activity chips (walk/run/ride/hike) that set default costs and UI.

## Storage & Reliability (Local)

- SQLite schema:
  - `routes(id, name, activity, distance_m, ascent_m, created_at, updated_at)`
  - `route_points(route_id, seq, lat, lon, ele)`; `waypoints(route_id, seq, type, note, photo_path)`
- Local backups:
  - Export/restore a `.zip` bundle (DB + assets) to device storage; never cloud.

## Testing Targets

- Unit: snap indexing, A* cost functions, elevation sampler.
- Widget: editor gestures, turn‑card, off‑route banner.
- Integration: roundtrip generation variance and time budgets (existing tests as baseline).

