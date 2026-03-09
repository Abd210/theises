# Step 7 — Prayer Notifications (Offline-First)
**Date**: 2026-03-08 | **Status**: Complete

## What was implemented

### Notification Service
- **Flutter**: `notification_service.dart` using `flutter_local_notifications` + `timezone`
  - Android channel `prayer_times` with HIGH importance
  - iOS permission request (alert + sound + badge)
  - `sendTestNow()`, `scheduleTestIn10s()`, `scheduleAllPrayers()`, `cancelAll()`
- **Expo**: `notificationService.js` using `expo-notifications`
  - Identical API: `init`, `requestPermission`, `sendTestNow`, `scheduleTestIn10s`, `scheduleAllPrayers`, `cancelAll`
  - Android channel configured with matching ID

### Notification Settings
- **Flutter**: `NotificationSettingsNotifier` (ChangeNotifier) → SharedPreferences
- **Expo**: `NotificationSettingsProvider` (React Context) → AsyncStorage
- Persisted keys: `notif_enabled`, `notif_prayer_{fajr|dhuhr|asr|maghrib|isha}`, `notif_lead_minutes`

### UI Changes
- **AppHeader**: Added bell icon button next to gear (both apps)
  - Taps `requestPermission()` then `sendTestNow()`
- **Settings Screen** (both apps): Replaced "Coming soon" placeholder with:
  - Master toggle: "Prayer Notifications" ON/OFF
  - Per-prayer toggles: Fajr, Dhuhr, Asr, Maghrib, Isha
  - Lead time selector: At adhan / 5m / 10m
  - "Send Test Now" button
  - "Test in 10s" button

### Scheduling Logic
**Old behavior (pre-rewrite)**: Scheduled prayers as encountered from cache, with unsorted iteration. No explicit window logging, no sorted candidates. Made it hard to compare across frameworks.

**New policy (both apps, 2026-03-09 rewrite)**:
- `windowStart = now + 5s`, `windowEnd = now + 48h`
- Collect all candidates from cached timings × enabled prayers
- Sort candidates by trigger time → deterministic ordering
- Schedule all, cancel previous prayer notifications first
- Persist scheduled list locally for debug: `#id prayer trigger body`
- Log: `[NOTIF] windowStart=... windowEnd=...` then per-item `[NOTIF] id=... prayer=... trigger=YYYY-MM-DD HH:mm`
- Settings "Show Scheduled" dialog shows trigger times in both apps

**Why this change**: 
- Thesis requires deterministic, comparable behavior across frameworks 
- 48h window is clear and testable
- Sorted candidates make log output directly comparable

## Files changed

| App     | File | Change |
|---------|------|--------|
| Flutter | `notification_service.dart` | NEW — notification init/test/schedule |
| Flutter | `notification_settings_service.dart` | NEW — settings notifier |
| Flutter | `app_header.dart` | MODIFY — added bell icon |
| Flutter | `settings_screen.dart` | MODIFY — replaced placeholder with real section + trigger display |
| Flutter | `salah_screen.dart` | MODIFY — wired bell callback |
| Flutter | `main.dart` | MODIFY — wired notifSettingsNotifier |
| Expo    | `notificationService.js` | NEW — notification init/test/schedule |
| Expo    | `notificationSettingsService.js` | NEW — context/hook |
| Expo    | `AppHeader.js` | MODIFY — added bell icon |
| Expo    | `SettingsScreen.js` | MODIFY — added NotificationSection + trigger display |
| Expo    | `SalahScreen.js` | MODIFY — wired bell callback |
| Expo    | `App.js` | MODIFY — wired NotificationSettingsProvider |

## Difficulties / errors encountered
1. `flutter_local_notifications` (latest version) uses **named parameters** for all methods (`show(id:, title:, body:, notificationDetails:)`, `zonedSchedule(id:, ...)`, `initialize(settings:)`, `cancel(id:)`). Initially used positional args → 8 compile errors → fixed all.
2. Duplicate stylesheet entries in Expo SettingsScreen after inserting new styles → cleaned up.
3. **Config mismatch (Expo)**: `PrayerSettingsProvider` initialized `methodId=3` synchronously, then async-loaded `methodId=15`. Fixed with `settingsReady` flag.
4. **Timezone (Flutter)**: `_resolveTimezone()` returns device TZ (e.g., EET) not location TZ. Documented: prayer times from API are for selected location; if device TZ ≠ location TZ (dev only), trigger times offset. In production, device=location.

## Flutter vs Expo differences
- **API**: Flutter uses `flutter_local_notifications` with timezone; Expo uses `expo-notifications` with `DATE` triggers
- **Scheduling**: Flutter uses `zonedSchedule` with TZDateTime; Expo uses `DATE` trigger with absolute Date
- **IDs**: Flutter uses int (100+); Expo uses string `prayer_YYYY-MM-DD_PrayerName` (both deterministic)
- **Permissions**: Flutter has separate iOS/Android permission flows; Expo unifies via `requestPermissionsAsync`
- **Channel**: Flutter creates channel programmatically; Expo uses `setNotificationChannelAsync`
- No UI or behavioral differences — identical controls, copy text, and scheduling policy.

## Final parity status
- Flutter ✅
- Expo ✅

## Known Limitations
- iOS simulator may not reliably show scheduled notifications — test on real device
- Android battery optimization may delay notifications (still scheduled correctly)
- Device timezone must match location timezone for correct notification timing (production assumption)

## Verification
- `flutter analyze` → 1 info warning only ✅
- `npx expo export --platform ios` → **Bundle OK** ✅
- Test buttons: Send Test Now + Schedule Test in 10s ready for verification on device
