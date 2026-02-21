# Step 3 — Qibla Screen

## What I did
Built the Qibla screen from scratch in both Flutter and Expo. Static compass UI — no device sensors, just a computed bearing from the user's stored lat/lon to the Kaaba.

## Approach
Used the standard great-circle bearing formula:
- `Δlon = kaabaLon - userLon`
- `y = sin(Δlon) * cos(kaabaLat)`
- `x = cos(userLat)*sin(kaabaLat) - sin(userLat)*cos(kaabaLat)*cos(Δlon)`
- `bearing = atan2(y,x)` → normalize to 0–360°

Kaaba coords: 21.4225°N, 39.8262°E

For the compass rendering:
- **Flutter**: `CustomPaint` with a `_CompassPainter` — draws ring, ticks, cardinals, needle, pointer, Kaaba marker
- **Expo**: `react-native-svg` with `<Circle>`, `<Line>`, `<Polygon>`, `<Rect>` — same visual structure

## Changes
1. `qibla_service.dart` / `qiblaService.js` — pure `computeQiblaDegrees(lat, lon)` function
2. `QiblaLayout` tokens in both theme files — compass size, font sizes, spacing
3. `qibla_screen.dart` / `QiblaScreen.js` — full screen UI
4. `main.dart` / `App.js` — wired tab index 1 to Qibla
5. Added `react-native-svg` to Expo

## Difficulties
- Flutter's `ThemeScope` is in `providers/theme_provider.dart` — forgot to import initially, caught by `flutter analyze`.
- Had to install `react-native-svg` for the Expo compass since RN doesn't have a built-in canvas.
- The compass painting code is the "heaviest" part — 72 tick marks, 4 cardinal labels, a needle, pointer triangle, and a Kaaba marker. Same visual in both apps but achieved differently (CustomPaint vs SVG).

## Differences Between Flutter and Expo
- **Flutter** uses `CustomPaint`/`Canvas` API — imperative drawing
- **Expo** uses `react-native-svg` — declarative SVG elements
- Both produce the same visual output with identical token values
- No behavioral differences

## Parity status
Flutter ✅ | Expo ✅

Same bearing formula, same QiblaLayout tokens, same visual structure. Degree values will match within ±0.1° for the same lat/lon.

## Next step
Possibly add device compass sensor integration later, or proceed to Step 4 (Azkar or Quran screen).

---

## Step 3.1 — Dynamic Compass (Device Heading)

### What I did
Made the compass rotate with real device heading. When you hold the phone and turn, the compass dial rotates so N faces true north. The Qibla needle always points toward Mecca.

### Sensor integration
- **Flutter**: `flutter_compass` 0.8.1 — provides a `Stream<CompassEvent>` with heading in degrees. Straightforward.
- **Expo**: `expo-sensors` Magnetometer — gives raw `x, y, z` in microteslas. I compute heading with `atan2(y, x)` and adjust for coordinate system (`90 - angle`). More manual work than Flutter.

### Smoothing
Low-pass filter alpha=0.2 with circular interpolation (handles the 359°→1° wraparound). Without this, the compass jitters badly on real devices.

### Rotation strategy
The entire SVG/CustomPaint compass (ring, ticks, labels, needle, Kaaba marker) rotates by `-heading`. The pointer triangle stays fixed at top. Combined effect: the needle always points toward Qibla in the real world.

### Unavailable state
On simulators, the magnetometer isn't available. Both apps detect this and show a static compass + "Compass not available on this device." card. This is expected behavior.

### Direction guidance
- Within 5° of Qibla → "Facing Qibla ✓" (accent)
- Otherwise → "Turn left/right to face Qibla" (muted)

### Difficulties
- Expo's `Magnetometer` gives raw data, not heading. Had to manually do `atan2` and coordinate conversion. Flutter's `flutter_compass` is much simpler — just a stream of degrees.
- Fixed-pointer-on-top vs rotating-compass is a bit tricky with the SVG layer — needed absolute positioning for the pointer and z-index management.

### Files changed
| File | Change |
|------|--------|
| Flutter `pubspec.yaml` | Added `flutter_compass` |
| Flutter `qibla_screen.dart` | StatefulWidget + heading stream + Transform.rotate |
| Expo `package.json` | Added `expo-sensors` |
| Expo `QiblaScreen.js` | Magnetometer hook + CSS transform rotate |

### Parity status
Flutter ✅ | Expo ✅

Both apps rotate the compass with heading, show direction guidance, and fall back to static UI on simulators. The sensor integration approach differs (stream vs atan2) but the visual result is identical.

---

## Step 3.1a — Fix Expo Compass Direction + Smoothing

### Problem
Two issues after initial dynamic compass implementation:
1. Needle rotated **opposite** to expected direction
2. Motion was **laggy/jittery** compared to Flutter, with occasional "long spins" crossing 0°/360°

### Root Causes
- `atan2(y, x)` gives the wrong heading sign on iOS — the y-axis is inverted for compass convention. Should be `atan2(-y, x)`.
- Basic smoothing was doing `angle - smoothed` without normalizing to shortest path. Near 359°→1° that gives a -358° diff instead of +2°.
- `Animated.Value` was set to absolute angles (e.g. -350 → -10). Crossing north caused RN to animate the long way around.

### Fix
- Heading: `atan2(-y, x)` + `normalizeAngle(90 - angle)` to match iOS compass
- Added `normalizeAngle(a)` = `((a % 360) + 360) % 360`
- Added `shortestDiff(from, to)` = normalized diff clamped to ±180°
- Smoothing now uses `shortestDiff(smoothed, raw) * alpha`
- Cumulative rotation tracker: instead of setting absolute angle on Animated.Value, I accumulate small diffs via `shortestDiff(prev, current)`. This means the value might be -720° or +1080° but it always takes the shortest path.
- 50ms update interval (was 100ms)
- `Animated.timing` with 100ms duration + native driver for interpolated smoothness

---

## Step 3.1b — Switch to expo-location Heading

### Why
Raw Magnetometer (`atan2(-y, x)`) is **not tilt-compensated**. Even slight phone tilt distorts the reading. iOS's `CLHeading` (what Flutter uses via `flutter_compass`) does sensor fusion internally, correcting for tilt and magnetic declination.

### What changed
- Replaced `expo-sensors` Magnetometer with `Location.watchHeadingAsync()`
- Uses `trueHeading` (declination-corrected), fallback `magHeading`
- Smoothing alpha 0.2 → 0.25 for snappier response
- Animation duration 100ms → 80ms
- Added `ARROW_BASELINE_DEG = 0` constant
- Added temporary debug overlay showing `heading | qibla | delta` on screen

### Now matches Flutter
Both apps now use OS-level tilt-compensated heading. The Qibla direction should be accurate.

---

## Step 3.1c — Smoothness Optimization

### The lag problem
`setHeading()` was called on every sensor update → React re-rendered the entire component every time → SVG CompassDial redrawn from scratch. On a 20Hz sensor, that's 20 full re-renders/sec including SVG layout.

### Fix: two-tier update architecture
1. **High-frequency path** (every sensor reading): smoothing → cumulative rotation → `Animated.timing(animatedRotation, ...)` with `useNativeDriver: true`. This runs on the native thread, never touches React.
2. **Low-frequency path** (every 200ms): `setHeading()` → re-render for direction text + debug overlay. Text doesn't need 20Hz.

### Additional changes
- `CompassDial` wrapped in `React.memo` — won't re-render unless `degrees`, `tc`, or `showPointer` change
- Smoothing alpha 0.25 → 0.4 (faster response)
- Animation duration 80ms → 50ms (snappier)
- Added Hz logging for first 5 seconds to measure actual update rate
