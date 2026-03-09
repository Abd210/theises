# WHAT WE DID UNTIL NOW

---

# 0) Quick Summary

**Thesis title**: "Performance and Productivity Analysis of Contemporary Cross-Platform Mobile Development Technologies"

**Objective**: Build two feature-identical Muslim prayer apps — one in **Flutter**, one in **React Native (Expo)** — then measure and compare **performance** (startup, rendering, FPS, CPU/memory, energy, app size) and **productivity** (time per feature, bugs, build time).

**App idea**: A Muslim mobile app with 5 tabs: Salah (prayer times), Qibla (compass), Quran (reader), Azkar (dhikr), Settings.

**Parity**: Both apps must have the **same UI layout, same features, same data logic, same storage keys, same API endpoints**. Only platform-native differences (library names, syntax) are acceptable. This ensures a fair comparison.

**Current status**:
| Tab | Status |
|-----|--------|
| Salah | ✅ Complete (API, cache, 7-day swipe, next prayer, countdown, notifications) |
| Qibla | ✅ Complete (bearing calculation, compass, heading sensor) |
| Quran | ✅ Complete (Mushaf pager, Surah reader, Juz jump, bookmarks, recents, continue reading) |
| Azkar | ✅ Complete (category grid, detail reader, counters, completion, resume, search, favorites) |
| Settings | ✅ Complete (themes, location, prayer method, offsets, notifications with debug) |
| Notifications | ✅ Complete (48h rolling window, per-prayer toggles, lead time, debug tools) |
| Benchmarks | ❌ Not started (Phase 3) |

---

# 1) Repo Overview

## 1.1 Folder Structure

```
/Volumes/ssd/theises/
├── prayer_app_flutter/       # Flutter implementation (Dart)
├── prayer_app_expo/          # React Native Expo implementation (JavaScript)
├── docs/                     # Specs, instructions
├── analysis/                 # Per-step analysis docs (STEP_0.md..step8_azkar_search_save.md)
├── results/                  # Benchmark logs (empty, Phase 3)
├── progress/                 # Old progress files
├── tests/                    # Test scripts
├── AppIcons/                 # App icon source files
├── azkar.md                  # Azkar text data source (73 items, 6 categories)
├── AGENT_INSTRUCTIONS.md     # Master agent rules for parity
├── PROGRESS.md               # Running implementation log
├── PARITY_STEP1.md           # Parity fix documentation
└── WHAT_WE_DID_UNTIL_NOW.md  # This file
```

## 1.2 How to Run

### Flutter
```bash
cd prayer_app_flutter

# iOS Simulator
flutter run                   # select iOS simulator from list

# Android Emulator
flutter run                   # select Android emulator from list

# iOS Physical Device (wireless)
flutter run                   # select iPhone (wireless)
# Note: wireless debugging on iOS 26 may be slower. Use USB for better performance.

# Release APK
flutter build apk --release   # → build/app/outputs/flutter-apk/app-release.apk (54.0MB)

# Release iOS
flutter build ios --no-codesign
```

**Known limitations**:
- Wireless iOS debugging requires "Allow" for local network discovery
- Dart VM Service discovery may take 75+ seconds over wireless

### Expo
```bash
cd prayer_app_expo

# Expo Go (development)
npx expo start                # scan QR with Expo Go app

# Dev build (REQUIRED for reliable notifications)
npx expo run:ios              # or: npx expo run:android
# Expo Go on Android has limited notification support

# Bundle verification
npx expo export --platform ios
```

**Known Expo Go limitations**:
- Background notifications may not fire reliably
- `expo-notifications` warns about Expo Go on Android
- For full notification testing, use a development build

---

# 2) Design System & UI Parity Foundation

## 2.1 Theme Tokens

Both apps use a token-based theme system. Only **colors** change per theme; spacing, radii, and typography are shared constants.

**Token fields** (class `ThemeColors` in Flutter, object shape in Expo):
`id`, `name`, `backgroundStart`, `backgroundEnd`, `card`, `cardBorder`, `modalBg`, `textPrimary`, `textMuted`, `accent`, `navBar`, `inactive`, `iconButtonBg`, `brightness`

**4 themes implemented**:

| Theme | ID | Accent | Background | Brightness |
|-------|-----|--------|------------|-----------|
| Night | `night` | Gold `#D4A847` | `#0D0D0D` → `#1A1A2E` | Dark |
| Forest | `forest` | Green `#4CAF50` | `#0A1A0A` → `#1A2E1A` | Dark |
| Sand | `sand` | Gold `#C49A3C` | `#F5F0E8` → `#EDE4D3` | Light |
| Midnight Blue | `midnight_blue` | Blue `#64B5F6` | `#0A0E1A` → `#141E3C` | Dark |

**Files**:
- Flutter: `lib/src/theme/app_themes.dart` (definitions), `lib/src/theme/app_theme.dart` (spacing/typography)
- Expo: `src/theme/themes.js` (definitions), `src/theme/theme.js` (spacing/typography)

**Spacing** (both apps): `s4=4, s8=8, s12=12, s16=16, s20=20, s24=24, s32=32`

**Persistence**: key `selected_theme_id` → stores theme `id` string

## 2.2 Shared UI Components (Parity Catalog)

### ScreenContainer
- **Purpose**: Wraps each tab screen with gradient background + SafeArea
- Flutter: `lib/src/components/screen_container.dart`
- Expo: `src/components/ScreenContainer.js`

### GlassCard
- **Purpose**: Translucent card with border radius, used for prayer info, settings sections
- Flutter: `lib/src/components/glass_card.dart`
- Expo: `src/components/GlassCard.js`
- Props: `child`/`children`, optional `padding`

### AppHeader
- **Purpose**: Top header bar with location label (left) and icon buttons (right: bell + gear)
- Flutter: `lib/src/components/app_header.dart`
- Expo: `src/components/AppHeader.js`
- Props: `title`, `subtitle`, `onSettingsTap`, `onTestNotification`

### BottomNavBar
- **Purpose**: Floating translucent bottom navigation with gold active pill indicator
- Flutter: `lib/src/components/bottom_nav_bar.dart`
- Expo: `src/components/BottomNavBar.js`
- 5 tabs: Salah, Qibla, Quran, Azkar, Settings
- Uses `MaterialCommunityIcons` in both apps

### AppIconButton
- **Purpose**: Circular translucent icon button (used in headers, etc.)
- Flutter: `lib/src/components/app_icon_button.dart`
- Expo: `src/components/AppIconButton.js`

### AppDivider
- **Purpose**: Subtle horizontal divider line
- Flutter: `lib/src/components/app_divider.dart`
- Expo: `src/components/AppDivider.js`

### NextPrayerCard
- **Purpose**: Highlighted card showing next prayer name + countdown timer
- Flutter: `lib/src/components/next_prayer_card.dart`
- Expo: `src/components/NextPrayerCard.js`

### PrayerRow
- **Purpose**: Single prayer time row (icon + name + time, optional active highlight)
- Flutter: `lib/src/components/prayer_row.dart`
- Expo: `src/components/PrayerRow.js`

---

# 3) Features by Tab

## 3.1 Salah (Prayer Times)

### UI
- **Header**: AppHeader with city name as title + country as subtitle; bell icon (test notification) + gear icon (settings)
- **NextPrayerCard**: Shows next prayer name, countdown (HH:MM:SS), accent-highlighted
- **Prayer rows**: 5 main prayers (Fajr, Dhuhr, Asr, Maghrib, Isha) with 12h formatted times
- **Day navigation**: 7-day horizontal swipe (today..+6) with dot indicators, date header showing Gregorian + Hijri
- **Banners**:
  - "Using default location" banner — shown when `location.source == 'default'`
  - "Offline (cached)" banner — shown when data came from cache without network

### Data & Logic

**API**: AlAdhan REST API
- **Endpoint**: `https://api.aladhan.com/v1/calendar`
- **Query params**: `latitude`, `longitude`, `method` (int), `school` (int), `month`, `year`
- Returns full month calendar with prayer times per day

**Calculation methods** (AlAdhan IDs):
| ID | Name |
|----|------|
| 3 | Muslim World League |
| 2 | ISNA |
| 4 | Umm al-Qura |
| 5 | Egyptian General Authority |
| 1 | Univ. of Islamic Sciences, Karachi |
| 7 | Inst. of Geophysics, Univ. of Tehran |
| 13 | Diyanet İşleri Başkanlığı, Turkey |
| 15 | Moonsighting Committee |

**Schools**: `0` = Shafi (Standard), `1` = Hanafi

**Offsets**: Per-prayer minute offset (−30..+30) applied client-side after API fetch

**Next prayer determination**: Compare current time against today's prayer times (HH:mm). First prayer whose time is after now is "next". If none today, next is tomorrow's Fajr.

**Countdown logic**: 1-second `setInterval` (Expo) / `Timer.periodic` (Flutter) tick. Computes diff between target prayer DateTime and now.

**Day navigation**: Flutter uses `PageView` (7 pages). Expo uses `FlatList` with `pagingEnabled`. Both show 7 days starting from today. Day index 0 = today.

### Caching

**Strategy**: Monthly calendar cache. The API returns an entire month's data in one call. Cached per month + config fingerprint.

- **Cache key structure**: `prayer_cal_{lat4}_{lon4}_m{method}_s{school}_{year}_{month}`
- **Saved timestamp key**: `prayer_cal_saved_{lat4}_{lon4}_m{method}_s{school}_{year}_{month}`
- **TTL**: 7 days (checked via saved timestamp)
- **Config prefix**: `configPrefix(lat, lon, method, school)` → rounds lat/lon to 4 decimals

**Cache flow**:
1. Build config prefix from current location + prayer settings
2. For each needed month (today..+6 may span 2 months):
   - Check `isMonthValid(year, month, cfgPrefix)` — compares saved timestamp against TTL
   - If valid: `loadMonth()` from local storage
   - If expired/missing: fetch from API, `saveMonth()` to local storage
3. Parse all days, build 7-day map keyed by `YYYY-MM-DD`

### Debug/Logs
- `[LOC] API using source=... city=... lat=... lon=... cfg=...`
- `[PRAYER] fetch month=... year=... cfg=...`
- `[PRAYER_CACHE] hit month=... cfg=...` / `[PRAYER_CACHE] miss month=... cfg=...`
- `[INIT] ready locationReady=... settingsReady=... using source=... city=... lat=... lon=... method=... school=...`

## 3.2 Qibla

### UI
- **DegreeHeader**: Large gold number showing bearing degrees + "from North"
- **Compass dial**: Rotatable compass with cardinal directions (N/S/E/W), Kaaba marker at computed bearing
- **InfoText**: Compass status message, accuracy indicator

### Sensors & Math

**Sensors**:
- Flutter: `flutter_compass` package → provides heading degrees from device magnetometer
- Expo: `expo-sensors` → `Magnetometer` → manual heading calculation from x/y/z

**Bearing to Kaaba**:
- Kaaba coordinates: `lat=21.4225, lon=39.8262`
- Formula (great-circle bearing):
  ```
  Δlon = kaabaLon - userLon
  y = sin(Δlon) × cos(kaabaLat)
  x = cos(userLat)×sin(kaabaLat) - sin(userLat)×cos(kaabaLat)×cos(Δlon)
  bearing = atan2(y, x) → degrees → normalize 0..360
  ```
- Implemented in:
  - Flutter: `lib/src/services/qibla_service.dart` → `computeQiblaDegrees()`
  - Expo: `src/services/qiblaService.js` → `computeQiblaDegrees()`

**Known limitations**:
- Simulators have no real magnetometer — heading stays at 0
- Real device: smoothing differs slightly between `flutter_compass` and raw `Magnetometer` → heading may jitter differently

### Storage
No persistent storage for Qibla.

## 3.3 Quran

### Current Approach
Two reader modes:
1. **Mushaf Pager**: Page-based reader (pages 1–604) with horizontal swipe. Each page shows ayahs from that Mushaf page.
2. **Surah Reader**: Surah-by-surah reading with Arabic + optional English translation

### API
**Base URL**: `https://api.alquran.cloud/v1`

**Endpoints used**:
| Endpoint | Purpose |
|----------|---------|
| `GET /surah` | List all 114 surahs (metadata) |
| `GET /surah/{n}/quran-uthmani` | Arabic text for surah N |
| `GET /surah/{n}/en.sahih` | English translation for surah N |
| `GET /juz/{n}/quran-uthmani` | Arabic text for juz N |
| `GET /juz/{n}/en.sahih` | English translation for juz N |
| `GET /page/{n}/quran-uthmani` | Arabic text for Mushaf page N |
| `GET /page/{n}/en.sahih` | English translation for Mushaf page N |

**Editions**: `quran-uthmani` (Arabic), `en.sahih` (English)

**Rendering**: Ayah list with Arabic text (Amiri font), optional English translation below each ayah. Surah headers (Bismillah) rendered for each new surah boundary.

### Juz Jump
- Quran screen shows Juz list (1–30)
- Tapping a Juz: fetches first ayah's page number via `/juz/{n}/quran-uthmani`, jumps to that page in MushafPagerScreen
- Function: `getJuzStartPage(juzNumber)` in `quran_api_service.dart` / `quranApi.js`

### Continue Reading / Recents / Bookmarks

**Continue reading**: Stores `QuranPointer` with `surahNumber`, `ayahNumber`, `pageNumber`, `surahName`, `timestamp`. On app open, "Continue reading" card appears on Quran screen. Tapping it opens MushafPager/QuranReader at saved position.

**Recents**: Last 10 reading positions stored as ordered list. Deduplicated by `surahNumber`.

**Bookmarks**: User can bookmark any surah/page. Toggle bookmark via icon. Bookmarks screen accessible from Quran tab.

### Storage Keys (Quran)

| Key | Value | Purpose |
|-----|-------|---------|
| `quran_last_read` | JSON QuranPointer | Continue reading position |
| `quran_recents` | JSON array of QuranPointer | Recent reading history (max 10) |
| `quran_bookmarks` | JSON array of QuranPointer | User bookmarks |
| `quran_surah_list_v1` | JSON surah metadata list | Cached surah list |
| `quran_surah_{n}_quran-uthmani_v1` | JSON ayah list | Cached Arabic surah N |
| `quran_surah_{n}_en.sahih_v1` | JSON ayah list | Cached English surah N |
| `quran_juz_{n}_quran-uthmani_v1` | JSON ayah list | Cached Arabic juz N |
| `quran_juz_{n}_en.sahih_v1` | JSON ayah list | Cached English juz N |

**Files**:
- Flutter: `lib/src/services/quran_api_service.dart`, `lib/src/services/quran_storage_service.dart`
- Expo: `src/services/quranApi.js`, `src/services/quranStorageService.js`
- Screens: `quran_screen.dart`/`QuranScreen.js`, `quran_reader_screen.dart`/`QuranReaderScreen.js`, `mushaf_pager_screen.dart`/`MushafPagerScreen.js`, `quran_surah_list_screen.dart`/`QuranSurahListScreen.js`, `quran_bookmarks_screen.dart`/`QuranBookmarksScreen.js`

## 3.4 Azkar

### Data Source
- File: `azkar.md` in repo root (78KB, plain text)
- **73 items across 6 categories**: Morning Azkar, Evening Azkar, After Prayer, Before Sleep, Upon Waking, General Dhikr
- Parsed in-app:
  - Flutter: `lib/src/models/azkar_data.dart` — parses markdown into `AzkarCategory` / `AzkarItem` models
  - Expo: `src/data/azkarData.js` — same parsing, matches Flutter exactly (73 items, 6 categories)

### UI
- **Category grid**: Grid/list of 6 category cards with icon + title + item count + arrow
- **Detail reader**: Card-based swipe view. Each card shows: Arabic text, transliteration (if present), translation, repeat count, counter controls (+/reset)
- **Counter controls**: Increment button, reset button. Counter tracks current count vs target repeat count.
- **Completion**: When count reaches target, card marked as completed (visual indicator)
- **Resume**: Re-opening a category resumes at last card index with preserved counters

### Resume + Counters + Completion

**Persisted per category** (key `azkar_{categoryId}`):
```json
{
  "cardIndex": 3,
  "counters": [0, 0, 5, 3, ...],
  "completed": [false, false, true, true, ...]
}
```

**Resume flow**:
1. On entering a category detail screen, load `azkar_{categoryId}` from storage
2. Restore `cardIndex`, `counters[]`, `completed[]`
3. On any change (counter increment, card swipe), save back to storage

### Search / Favorites

**Search**: ✅ Implemented in both apps
- Search bar on Azkar home screen
- Searches across ALL azkar items in all categories
- Matches against: Arabic text, transliteration, translation, category title

**Favorites**: ✅ Implemented in both apps
- Bookmark icon on each azkar item in detail reader
- Saved favorites viewable from "Saved" tab/screen
- Key: `azkar_favorites_v1` → JSON array of `{ categoryId, itemIndex }`

**Files**:
- Flutter: `azkar_screen.dart`, `azkar_detail_screen.dart`, `saved_azkar_screen.dart`
- Expo: `AzkarScreen.js`, `AzkarDetailScreen.js`, `SavedAzkarScreen.js`

### Storage Keys (Azkar)

| Key | Value | Purpose |
|-----|-------|---------|
| `azkar_last_category` | category ID string | Resume: which category was last opened |
| `azkar_{categoryId}` | JSON `{cardIndex, counters, completed}` | Per-category progress |
| `azkar_favorites_v1` | JSON array of `{categoryId, itemIndex}` | Saved favorites |

## 3.5 Settings

### UI Sections
1. **Themes**: Horizontal row of 4 theme cards (Night/Forest/Sand/Midnight Blue). Tapping switches theme instantly.
2. **Location**: City + country display, "Detect Location" button, "Using default location" banner
3. **Prayer Settings**: Method picker (8 methods), Madhab picker (Shafi/Hanafi), per-prayer offset adjusters (−30..+30 min)
4. **Notifications**: Master toggle, per-prayer toggles (Fajr/Dhuhr/Asr/Maghrib/Isha), lead time selector (At adhan / 5min / 10min), debug buttons (Test Now, Test 10s, Show Scheduled, Pipeline Test 60s)

### Location

**Permission flow**:
1. Check `Geolocator` / `expo-location` permission
2. If granted: get GPS position → reverse geocode → save as `source=gps`
3. If denied / unavailable: use fallback

**Reverse geocode**:
- Flutter: `geocoding` package → `placemarkFromCoordinates(lat, lon)`
- Expo: `expo-location` → `reverseGeocodeAsync({latitude, longitude})`

**Fallback default**: Bucharest, Romania (`lat=44.4268, lon=26.1025, timezone=Europe/Bucharest, source=default`)

**Banner rule**: Show "Using default location" banner when `location.source == 'default'`. Hide when `source == 'gps'`. If location not loaded yet, show nothing.

**First run**: On first launch, app attempts auto-detection. If successful, saves GPS location. Marked via key `app_first_run_location_v3`.

### Prayer Method Selection

**Auto vs Manual mode** (key `prayer_method_mode`):
- `auto` (default): Method chosen automatically based on region/IP (basic logic)
- `manual`: User explicitly chose a method from the picker

When user taps a method, mode switches to `manual` and persists.

### Storage Keys (Location)

| Key | Value | Purpose |
|-----|-------|---------|
| `loc_lat` | double | Saved latitude |
| `loc_lon` | double | Saved longitude |
| `loc_city` | string | City name |
| `loc_country` | string | Country name |
| `loc_timezone` | string | IANA timezone |
| `loc_source` | `"gps"` or `"default"` | How location was obtained |
| `app_first_run_location_v3` | bool | Whether first-run detection completed |

---

# 4) Notifications (Local)

### Libraries
- **Flutter**: `flutter_local_notifications` + `timezone`
- **Expo**: `expo-notifications`

### Permission Request
- iOS: Request alert + sound + badge permissions
- Android: Request exact alarms permission (Android 12+) + notification permission

### Scheduling Policy

**Rolling 48-hour window** (identical in both apps):
```
windowStart = now + 5 seconds
windowEnd   = now + 48 hours
```

**Algorithm**:
1. Cancel all existing prayer notifications (Flutter: IDs ≥ 100; Expo: identifiers starting with `prayer_`)
2. Log: `[NOTIF] windowStart=... windowEnd=... (+offset)`
3. Collect candidates from cached prayer timings (today..+6 days):
   - For each day, for each enabled prayer (Fajr/Dhuhr/Asr/Maghrib/Isha)
   - Apply `leadMinutes` offset (subtract from prayer time)
   - Filter: `windowStart ≤ trigger ≤ windowEnd`
4. Sort all candidates by trigger time (deterministic ordering)
5. Schedule each with per-item log: `[NOTIF] id=... prayer=... trigger=YYYY-MM-DD HH:mm (+offset)`
6. Persist schedule list for debug display
7. Log: `[NOTIF] scheduledCount=N`

**Typical result**: 6–10 notifications depending on time of day.

**IDs**:
- Flutter: Sequential ints starting at 100 (IDs 0, 1, 99 reserved for test notifications)
- Expo: String identifiers `prayer_YYYY-MM-DD_PrayerName`

### Cancellation / Reschedule Rules
Reschedule triggers (collapse via 300ms debounce + single-flight guard in Expo):
- Notification settings change (master toggle, per-prayer toggle, lead time)
- Prayer cache updated (new timings fetched)
- Location or prayer settings change (method/school/offsets)

**NOT** triggered by: screen focus, navigation, or tab switching

### Debug Tools (Settings Screen)
| Button | Action |
|--------|--------|
| Send Test Now | Immediate notification via `show()` |
| Test in 10s | Scheduled 10s from now via `zonedSchedule()` / `TIME_INTERVAL` |
| Show Scheduled (Debug) | Alert dialog listing all pending prayer notifications with trigger times |
| Pipeline Test 60s | Uses real prayer pipeline (same channel/ID logic), fires in 60s |

### Expo Go Limitation
`expo-notifications` has limited support in Expo Go, especially on Android. For reliable background notification testing, a **development build** (`npx expo run:ios` / `npx expo run:android`) is required.

### Storage Keys (Notifications)

| Key | Value | Purpose |
|-----|-------|---------|
| `notif_enabled` | bool | Master notification toggle |
| `notif_lead_minutes` | int | Minutes before adhan (0, 5, or 10) |
| `notif_prayer_fajr` | bool | Fajr toggle |
| `notif_prayer_dhuhr` | bool | Dhuhr toggle |
| `notif_prayer_asr` | bool | Asr toggle |
| `notif_prayer_maghrib` | bool | Maghrib toggle |
| `notif_prayer_isha` | bool | Isha toggle |
| `salah_notif_cache` | JSON map | Cached week timings for scheduling |
| `notif_last_scheduled` | JSON list/map | Last scheduled notification list (for debug) |

### Timezone Strategy
Notifications use **device local timezone**. Prayer times from the API are for the selected location. If device timezone ≠ location timezone (e.g., device in EET, location set to SF PST), trigger times will be offset. This is expected in dev/testing. In production, users are physically at their location.

---

# 5) Storage & Persistence Index (All Keys)

| Domain | Key | Stored Value | Used By | Flutter File | Expo File |
|--------|-----|-------------|---------|-------------|-----------|
| Theme | `selected_theme_id` | theme ID string (`night`, `forest`, `sand`, `midnight_blue`) | Settings | `providers/theme_provider.dart` | `providers/ThemeProvider.js` |
| Location | `loc_lat` | double | Salah, Settings | `services/location_service.dart` | `services/locationService.js` |
| Location | `loc_lon` | double | Salah, Settings | `services/location_service.dart` | `services/locationService.js` |
| Location | `loc_city` | string | Header, Settings | `services/location_service.dart` | `services/locationService.js` |
| Location | `loc_country` | string | Header, Settings | `services/location_service.dart` | `services/locationService.js` |
| Location | `loc_timezone` | IANA timezone | Notifications | `services/location_service.dart` | `services/locationService.js` |
| Location | `loc_source` | `"gps"` / `"default"` | Banner, API | `services/location_service.dart` | `services/locationService.js` |
| Location | `app_first_run_location_v3` | bool | First-run flow | `services/location_service.dart` | `services/locationService.js` |
| Prayer Settings | `prayer_method_id` | int (AlAdhan method) | Salah, Cache | `services/prayer_settings_service.dart` | `services/prayerSettingsService.js` |
| Prayer Settings | `prayer_school` | int (0=Shafi, 1=Hanafi) | Salah, Cache | `services/prayer_settings_service.dart` | `services/prayerSettingsService.js` |
| Prayer Settings | `prayer_method_mode` | `"auto"` / `"manual"` | Settings | `services/prayer_settings_service.dart` | `services/prayerSettingsService.js` |
| Prayer Settings | `prayer_offset_{Prayer}` | int (−30..+30 min) | Salah | `services/prayer_settings_service.dart` | `services/prayerSettingsService.js` |
| Prayer Cache | `prayer_cal_{cfg}_{year}_{month}` | JSON month calendar | Salah | `services/cache_service.dart` | `services/prayerCacheService.js` |
| Prayer Cache | `prayer_cal_saved_{cfg}_{year}_{month}` | ISO timestamp | Cache TTL | `services/cache_service.dart` | `services/prayerCacheService.js` |
| Prayer Cache | `cached_prayer_json` | JSON (legacy) | Legacy compat | `services/cache_service.dart` | `services/cacheService.js` |
| Prayer Cache | `cached_prayer_date` | date string (legacy) | Legacy compat | `services/cache_service.dart` | `services/cacheService.js` |
| Notifications | `notif_enabled` | bool | Settings | `services/notification_settings_service.dart` | `services/notificationSettingsService.js` |
| Notifications | `notif_lead_minutes` | int | Settings | `services/notification_settings_service.dart` | `services/notificationSettingsService.js` |
| Notifications | `notif_prayer_{name}` | bool | Settings | `services/notification_settings_service.dart` | `services/notificationSettingsService.js` |
| Notifications | `salah_notif_cache` | JSON map | Notification scheduling | `services/notification_service.dart` | `services/notificationService.js` |
| Notifications | `notif_last_scheduled` | JSON list/map | Debug display | `services/notification_service.dart` | `services/notificationService.js` |
| Quran | `quran_last_read` | JSON QuranPointer | Continue reading | `services/quran_storage_service.dart` | `services/quranStorageService.js` |
| Quran | `quran_recents` | JSON array | Recent reads | `services/quran_storage_service.dart` | `services/quranStorageService.js` |
| Quran | `quran_bookmarks` | JSON array | Bookmarks | `services/quran_storage_service.dart` | `services/quranStorageService.js` |
| Quran | `quran_surah_list_v1` | JSON array | Surah list cache | `services/quran_api_service.dart` | `services/quranApi.js` |
| Quran | `quran_surah_{n}_{edition}_v1` | JSON ayah list | Surah text cache | `services/quran_api_service.dart` | `services/quranApi.js` |
| Quran | `quran_juz_{n}_{edition}_v1` | JSON ayah list | Juz text cache | `services/quran_api_service.dart` | `services/quranApi.js` |
| Azkar | `azkar_last_category` | category ID string | Resume | `screens/azkar_screen.dart` | `screens/AzkarScreen.js` |
| Azkar | `azkar_{categoryId}` | JSON `{cardIndex, counters, completed}` | Per-category state | `screens/azkar_detail_screen.dart` | `screens/AzkarDetailScreen.js` |
| Azkar | `azkar_favorites_v1` | JSON array | Saved favorites | `screens/azkar_detail_screen.dart` | `screens/AzkarDetailScreen.js` |

---

# 6) Parity & Verification

## 6.1 Current Parity Status

**What matches** ✅:
- Theme tokens (same hex values, same 4 themes)
- All 5 tab screens with same layout structure
- Same API endpoints and query parameters
- Same cache key structure and TTL
- Same storage keys (identical key names in SharedPreferences/AsyncStorage)
- Same notification scheduling policy (48h window, same log format)
- Same Qibla bearing formula
- Same Azkar data (73 items, 6 categories from same source file)
- Same Quran reader approach (Mushaf pager + Surah reader)
- Same component catalog (8 shared components)

**Known differences** (platform-inherent, acceptable):
- Flutter: `flutter_local_notifications` + `zonedSchedule` with TZDateTime; Expo: `expo-notifications` + `DATE` trigger
- Flutter: `flutter_compass` heading; Expo: raw `Magnetometer` x/y/z with manual heading math
- Notification IDs: Flutter uses ints (100+); Expo uses strings (`prayer_YYYY-MM-DD_Name`)
- Minor spacing/rendering differences inherent to native rendering engines

## 6.2 How to Verify Parity (Checklist)

1. **Set location**: Both apps → same GPS coordinates (or set simulator location to same city)
2. **Set method**: Both apps → Settings → same calculation method + school
3. **Compare Salah**:
   - Same prayer times for today (should be identical ±1 minute due to rounding)
   - Swipe through 7 days — same dates, same times
   - Lead time / offset changes reflected identically
4. **Compare Quran**:
   - Open same surah → same Arabic text + translation
   - "Continue reading" persists and restores in both
   - Bookmarks save/remove in both
5. **Compare Azkar**:
   - Same 6 categories, same item count
   - Counter increments and completion tracking
   - Resume position matches after closing and reopening category
   - Search returns same results for same query
6. **Compare Notifications**:
   - Enable notifications in both → "Show Scheduled" → same prayers listed
   - Check log output: `[NOTIF] windowStart=... windowEnd=...` and per-prayer triggers match
   - Change lead time → triggers shift by same offset
7. **Compare Settings**:
   - Theme switching → same visual result
   - Location detect → same city/coordinates

---

# 7) Known Issues / TODO

### Known Issues
- **Timezone mismatch in dev**: If device timezone ≠ location timezone, notification trigger times are offset. Only affects dev/testing with simulated GPS.
- **Android emulator**: Shows "Using default location" if GPS not set via Extended Controls → Location
- **Expo Go Android**: Limited notification support — use development build for full testing
- **Wireless iOS debugging**: Can be slow, Dart VM Service discovery may take 75+ seconds

### TODO (Future Work)
- **Phase 3: Benchmarks** — create performance test scripts, run on both frameworks
  - Startup time measurement
  - Rendering/FPS profiling
  - CPU + memory usage under load
  - Battery/energy consumption
  - APK/IPA size comparison
- Results tables in `/results/` directory
- Thesis writing with comparative analysis

---

# 8) File/Module Inventory

## Flutter (`prayer_app_flutter/lib/src/`)

### Theme
| File | Purpose |
|------|---------|
| `theme/app_themes.dart` | 4 theme definitions (ThemeColors class) |
| `theme/app_theme.dart` | Spacing constants, typography, layout tokens |

### Services
| File | Purpose |
|------|---------|
| `services/location_service.dart` | GPS, reverse geocode, fallback, LocationData model, LocationNotifier |
| `services/prayer_api.dart` | AlAdhan API fetch + monthly cache orchestration |
| `services/cache_service.dart` | Config-keyed monthly prayer cache (SharedPreferences) |
| `services/prayer_settings_service.dart` | Method/school/offset persistence, PrayerSettingsNotifier |
| `services/notification_service.dart` | Init, schedule, cancel, debug, pipeline test |
| `services/notification_settings_service.dart` | Master/per-prayer/lead-time toggles (NotificationSettingsNotifier) |
| `services/qibla_service.dart` | `computeQiblaDegrees()` bearing math |
| `services/quran_api_service.dart` | alquran.cloud API + surah/juz/page cache |
| `services/quran_storage_service.dart` | Last read, recents, bookmarks persistence |

### Providers
| File | Purpose |
|------|---------|
| `providers/theme_provider.dart` | ThemeProvider (ChangeNotifier) + ThemeScope |

### Models
| File | Purpose |
|------|---------|
| `models/prayer_times.dart` | PrayerTimings model |
| `models/quran_models.dart` | SurahMeta, Ayah, JuzAyah, PageAyah, QuranPointer |
| `models/azkar_data.dart` | AzkarCategory, AzkarItem, markdown parser |

### Screens (12)
| File | Tab |
|------|-----|
| `screens/salah_screen.dart` | Salah |
| `screens/qibla_screen.dart` | Qibla |
| `screens/quran_screen.dart` | Quran |
| `screens/quran_reader_screen.dart` | Quran (surah reader) |
| `screens/quran_surah_list_screen.dart` | Quran (all surahs) |
| `screens/quran_bookmarks_screen.dart` | Quran (bookmarks) |
| `screens/mushaf_pager_screen.dart` | Quran (Mushaf pager) |
| `screens/azkar_screen.dart` | Azkar |
| `screens/azkar_detail_screen.dart` | Azkar (category detail) |
| `screens/saved_azkar_screen.dart` | Azkar (saved favorites) |
| `screens/settings_screen.dart` | Settings |
| `screens/demo_screen.dart` | Demo/test |

### Components (8)
`screen_container.dart`, `glass_card.dart`, `app_header.dart`, `bottom_nav_bar.dart`, `app_icon_button.dart`, `app_divider.dart`, `next_prayer_card.dart`, `prayer_row.dart`

---

## Expo (`prayer_app_expo/src/`)

### Theme
| File | Purpose |
|------|---------|
| `theme/themes.js` | 4 theme definitions |
| `theme/theme.js` | Spacing, typography, layout tokens |

### Services
| File | Purpose |
|------|---------|
| `services/locationService.js` | GPS, reverse geocode, fallback |
| `services/prayerApi.js` | AlAdhan API fetch + cache orchestration |
| `services/prayerCacheService.js` | Config-keyed monthly cache (AsyncStorage) |
| `services/cacheService.js` | Legacy cache compatibility |
| `services/prayerSettingsService.js` | Method/school/offset persistence |
| `services/notificationService.js` | Init, schedule, cancel, debug |
| `services/notificationSettingsService.js` | Notification settings context/hooks |
| `services/qiblaService.js` | `computeQiblaDegrees()` |
| `services/quranApi.js` | alquran.cloud API + cache |
| `services/quranStorageService.js` | Last read, recents, bookmarks |
| `services/azkarService.js` | Azkar data loading |

### Providers
| File | Purpose |
|------|---------|
| `providers/ThemeProvider.js` | ThemeContext + useTheme hook |
| `providers/LocationProvider.js` | LocationContext + useLocation hook |
| `providers/PrayerSettingsProvider.js` | PrayerSettingsContext + usePrayerSettings hook + settingsReady flag |

### Data
| File | Purpose |
|------|---------|
| `data/azkarData.js` | Parsed azkar data (73 items, 6 categories) |

### Screens (12)
| File | Tab |
|------|-----|
| `screens/SalahScreen.js` | Salah |
| `screens/QiblaScreen.js` | Qibla |
| `screens/QuranScreen.js` | Quran |
| `screens/QuranReaderScreen.js` | Quran (surah reader) |
| `screens/QuranSurahListScreen.js` | Quran (all surahs) |
| `screens/QuranBookmarksScreen.js` | Quran (bookmarks) |
| `screens/MushafPagerScreen.js` | Quran (Mushaf pager) |
| `screens/AzkarScreen.js` | Azkar |
| `screens/AzkarDetailScreen.js` | Azkar (category detail) |
| `screens/SavedAzkarScreen.js` | Azkar (saved favorites) |
| `screens/SettingsScreen.js` | Settings |
| `screens/DemoScreen.js` | Demo/test |

### Components (8)
`ScreenContainer.js`, `GlassCard.js`, `AppHeader.js`, `BottomNavBar.js`, `AppIconButton.js`, `AppDivider.js`, `NextPrayerCard.js`, `PrayerRow.js`
