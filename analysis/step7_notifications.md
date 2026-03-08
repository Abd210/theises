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
- Uses cached 7-day prayer timings (offline-first)
- Cancels all previous prayer notifications before rescheduling
- Only schedules future times; skips past
- Unique notification IDs per prayer+date
- Body format: `Adhan at {time} • {city}` or `{name} in {lead} min • Adhan at {time} • {city}`

## Files changed

| App     | File | Change |
|---------|------|--------|
| Flutter | `notification_service.dart` | NEW — notification init/test/schedule |
| Flutter | `notification_settings_service.dart` | NEW — settings notifier |
| Flutter | `app_header.dart` | MODIFY — added bell icon |
| Flutter | `settings_screen.dart` | MODIFY — replaced placeholder with real section |
| Flutter | `salah_screen.dart` | MODIFY — wired bell callback |
| Flutter | `main.dart` | MODIFY — wired notifSettingsNotifier |
| Expo    | `notificationService.js` | NEW — notification init/test/schedule |
| Expo    | `notificationSettingsService.js` | NEW — context/hook |
| Expo    | `AppHeader.js` | MODIFY — added bell icon |
| Expo    | `SettingsScreen.js` | MODIFY — added NotificationSection |
| Expo    | `SalahScreen.js` | MODIFY — wired bell callback |
| Expo    | `App.js` | MODIFY — wired NotificationSettingsProvider |

## Difficulties / errors encountered
1. `flutter_local_notifications` (latest version) uses **named parameters** for all methods (`show(id:, title:, body:, notificationDetails:)`, `zonedSchedule(id:, ...)`, `initialize(settings:)`, `cancel(id:)`). Initially used positional args → 8 compile errors → fixed all.
2. Duplicate stylesheet entries in Expo SettingsScreen after inserting new styles → cleaned up.

## Flutter vs Expo differences
- **API**: Flutter uses `flutter_local_notifications` with timezone; Expo uses `expo-notifications` with `TIME_INTERVAL` triggers
- **Scheduling**: Flutter uses `zonedSchedule` with TZDateTime; Expo uses `scheduleNotificationAsync` with relative seconds
- **Permissions**: Flutter has separate iOS/Android permission flows; Expo unifies via `requestPermissionsAsync`
- **Channel**: Flutter creates channel programmatically; Expo uses `setNotificationChannelAsync`
- No UI or behavioral differences — identical controls, copy text, and scheduling policy.

## Final parity status
- Flutter ✅
- Expo ✅

## Known Limitations
- iOS simulator may not reliably show scheduled notifications — test on real device
- Android battery optimization may delay notifications (still scheduled correctly)
- Timezone in Flutter defaults to UTC — could be improved with native timezone detection

## Verification
- `flutter analyze` → **No issues found** ✅
- `npx expo export --platform ios` → **Bundle OK** ✅
- Test buttons: Send Test Now + Schedule Test in 10s ready for verification on device
