# Step 6.1 — Android Fix Pack (Network + First-Launch Permission + Offline UX)

## What I built

I implemented the Android fix pack in both Flutter and Expo with parity.

### 1) First-launch location permission with one-time flag
- Added persistent first-run key: `app_first_run_location_v1`.
- On first launch only:
  - app requests foreground location permission
  - if granted, location is detected and reverse geocoded
  - if denied (or detection fails), app keeps default Bucharest location
- Added subtle banner on Salah screen: `Using default location` when app is running on default fallback after first-run flow.
- Manual `Detect location` in Settings still works and can update location later.

### 2) Network reliability + offline UX
- Removed raw exception exposure in UI for network failures.
- Added friendly fallback behavior:
  - cache available -> show cached data + `Offline (cached)`
  - no cache -> friendly error + `Retry` button
- Applied this where users saw breakage:
  - Salah
  - Quran Home / Surah List / Reader metadata flows

### 3) Debug-only request failure logging
- Added URL + error/status logs for failing requests in prayer and Quran API services.
- Logs are debug/dev only (no noisy production logging intent).

### 4) Android connectivity permission (Flutter)
- Added missing `INTERNET` permission to Flutter Android manifest.

### 5) Quran Juz failure behavior
- Kept Juz failures graceful:
  - Flutter uses `SnackBar`
  - Expo uses toast/alert fallback
- No crash or broken navigation when Juz fetch fails.

## What went wrong / fixes

1. Flutter SDK writes were sandbox-restricted for `dart format`.
- I reran formatting with elevated permissions.

2. Existing Flutter lint warnings in Azkar file surfaced during verify.
- Cleaned them so `flutter analyze` returns clean.

3. The old location flow depended on `source == default`, which could retry detect too often.
- Replaced with explicit first-run persistence logic so permission prompt runs once unless user manually triggers detect.

## Real Flutter vs Expo differences

- Flutter first-run setup is run in `main.dart` via `LocationNotifier.ensureFirstRunSetup()` before app mount.
- Expo first-run setup runs in `LocationProvider` startup effect and then exposes `usingDefaultLocationBanner` via context.
- User-facing behavior is aligned across both.

## Android verification (actually run)

- Flutter: `flutter analyze` -> no issues.
- Expo: `npx expo export --platform android` -> success.

## Manual test steps (Android)

1. Uninstall app and install fresh build.
2. Open app: location permission prompt appears on first launch.
3. Deny permission: Salah shows `Using default location` and defaults are used.
4. Disable internet and open Salah/Quran:
   - with cache: content + `Offline (cached)` banner
   - no cache: friendly error + `Retry`
5. Re-enable internet, go Settings -> `Detect location`, grant permission, confirm city/country updates.
6. Open Quran Home and tap a Juz while offline: graceful failure message, no UI break.

## Final parity status

- Flutter ✅
- Expo ✅
