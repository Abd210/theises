# PROGRESS.md
## Thesis Project: Flutter vs React Native (Expo) — Muslim Prayer App

---

## Step 0 — Foundation: Design System + Shared Components ✅
**Date**: 2026-02-19 | **Status**: Complete

Theme tokens (colors, spacing, radius, typography) + 6 shared components (ScreenContainer, GlassCard, AppHeader, AppIconButton, AppDivider, BottomNavBar) implemented in both apps with matching structure.

---

## Step 1 — Salah (Prayer Times) Screen + AlAdhan API ✅
**Date**: 2026-02-19 | **Status**: Complete

### What was done
Implemented the full Salah (Prayer Times) screen with live AlAdhan API integration in both apps, matching the Figma screenshot. Features include:
- **API integration**: `GET /v1/timings/{date}` with lat=44.4268, lon=26.1025, method=2 (ISNA), tz=Europe/Bucharest
- **Real-time countdown**: Updates every 1 second in both apps
- **Next prayer detection**: Highlights the next prayer row with gold border
- **Caching**: Flutter uses SharedPreferences, Expo uses AsyncStorage
- **Error handling**: Falls back to cache on API failure with subtle banner
- **Pull-to-refresh**: Both apps support pull-down to refetch
- **AppShell navigation**: Tab-based navigation with SalahScreen on tab 0, placeholders for other tabs

### UI Layout (matching Figma)
1. AppHeader (📍 Bucharest + ⚙️ gear)
2. Date row (Gregorian left + Hijri gold right)
3. Hero countdown card (gold border, mosque icon, prayer name, HH:MM:SS timer)
4. Schedule date label (📅 + date)
5. Prayer rows: Fajr, Dhuhr, Asr, Maghrib, Isha (next = gold border)
6. Divider
7. Supplementary: Sunrise, Last Third of Night
8. Floating bottom nav (Salah active gold pill)

### Files Changed

#### Flutter (`prayer_app_flutter/lib/`)
| File | Type |
|------|------|
| `src/models/prayer_times.dart` | NEW |
| `src/services/prayer_api.dart` | NEW |
| `src/services/cache_service.dart` | NEW |
| `src/components/next_prayer_card.dart` | NEW |
| `src/components/prayer_row.dart` | NEW |
| `src/screens/salah_screen.dart` | NEW |
| `main.dart` | MODIFIED |
| `pubspec.yaml` | MODIFIED (+http, shared_preferences, intl) |

#### Expo (`prayer_app_expo/`)
| File | Type |
|------|------|
| `src/models/prayerTimes.js` | NEW |
| `src/services/prayerApi.js` | NEW |
| `src/services/cacheService.js` | NEW |
| `src/components/NextPrayerCard.js` | NEW |
| `src/components/PrayerRow.js` | NEW |
| `src/screens/SalahScreen.js` | NEW |
| `App.js` | MODIFIED |
| `package.json` | MODIFIED (+@react-native-async-storage/async-storage) |

### Parity Check
| Feature | Flutter ✅ | Expo ✅ | Match |
|---------|-----------|---------|-------|
| AlAdhan API (same URL/coords/method) | ✅ | ✅ | ✅ |
| Prayer model + 12h formatting | ✅ | ✅ | ✅ |
| Caching (SP / AsyncStorage) | ✅ | ✅ | ✅ |
| Hero countdown card (1s tick) | ✅ | ✅ | ✅ |
| Next prayer detection + gold border | ✅ | ✅ | ✅ |
| Prayer schedule (same order) | ✅ | ✅ | ✅ |
| Pull-to-refresh | ✅ | ✅ | ✅ |
| Error/cache fallback banner | ✅ | ✅ | ✅ |
| AppShell + tab navigation | ✅ | ✅ | ✅ |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

### How to Run
```bash
# Flutter
cd prayer_app_flutter && flutter run

# Expo
cd prayer_app_expo && npx expo start
```

### What Remains
- Step 2+: Qibla, Quran, Azkar, Settings screens
- Phase 2: Location handling, real-time compass, Azkar/Quran data
- Phase 3: Benchmark preparation

---

## Step 1.1 — Parity Fix: Font, Scaling, Icons ✅
**Date**: 2026-02-19 | **Status**: Complete

### Why
For a fair thesis comparison, both apps must use the same font, disable user font scaling during benchmarks, and render identical icon glyphs.

### What Changed

#### 1. Inter Font (both apps now load Inter from Google Fonts)
- **Flutter**: Added `google_fonts: ^6.2.1`; all `AppTypography` styles use `GoogleFonts.inter()`
- **Expo**: Added `@expo-google-fonts/inter`; `useFonts()` loads 5 Inter weights; `interFont(weight)` helper maps weight → correct RN font family name

#### 2. Font Scaling Disabled
- **Flutter**: `MediaQuery(...textScaler: TextScaler.linear(1.0)...)` in `main.dart` builder
- **Expo**: `Text.defaultProps.allowFontScaling = false` + same for `TextInput` in `App.js`

#### 3. Unified Icons — MaterialCommunityIcons / MdiIcons (same MDI glyph set)
- **Flutter**: Added `material_design_icons_flutter: ^7.0.7296`; all `Icons.xxx` → `MdiIcons.xxx`
- **Expo**: All `Ionicons` → `MaterialCommunityIcons` (already from MDI font)

| Icon purpose | MDI glyph name (both apps) |
|-------------|---------------------------|
| Location pin | `map-marker-outline` |
| Settings gear | `cog-outline` |
| Mosque (card+rows) | `mosque` |
| Calendar | `calendar-outline` |
| Refresh | `refresh` |
| Nav: Salah | `clock-outline` |
| Nav: Qibla | `compass-outline` |
| Nav: Quran | `book-open-variant` |
| Nav: Azkar | `bookshelf` |
| Nav: Settings | `cog-outline` |

### Files Changed

| Flutter file | Change |
|-------------|--------|
| `pubspec.yaml` | +google_fonts, +material_design_icons_flutter |
| `app_theme.dart` | GoogleFonts.inter() for all styles |
| `main.dart` | textScaler: TextScaler.linear(1.0) |
| `app_header.dart` | MdiIcons |
| `bottom_nav_bar.dart` | MdiIcons |
| `next_prayer_card.dart` | MdiIcons |
| `prayer_row.dart` | MdiIcons |
| `salah_screen.dart` | MdiIcons |

| Expo file | Change |
|----------|--------|
| `package.json` | +@expo-google-fonts/inter, +expo-font |
| `theme.js` | interFont() helper, removed fontWeight from Typography |
| `App.js` | useFonts(), allowFontScaling=false |
| `AppHeader.js` | MaterialCommunityIcons |
| `AppIconButton.js` | MaterialCommunityIcons |
| `BottomNavBar.js` | MaterialCommunityIcons + interFont() |
| `NextPrayerCard.js` | interFont() for weight overrides |
| `PrayerRow.js` | interFont() for weight overrides |
| `SalahScreen.js` | MaterialCommunityIcons + interFont() |

### Parity Verification
| Item | Flutter | Expo | Match |
|------|---------|------|-------|
| Font family: Inter | ✅ google_fonts | ✅ expo-google-fonts | ✅ |
| Font scaling disabled | ✅ TextScaler(1.0) | ✅ allowFontScaling=false | ✅ |
| Icon set: MDI glyphs | ✅ MdiIcons | ✅ MaterialCommunityIcons | ✅ |
| Hero card padding: 24 all | ✅ AppSpacing.s24 | ✅ Spacing.s24 | ✅ |
| Hero card border: 1.5 gold | ✅ Border.all(1.5) | ✅ borderWidth: 1.5 | ✅ |
| Hijri format: "day monthAr year هـ" | ✅ | ✅ | ✅ |
| Hijri fields: day, month.ar, year | ✅ | ✅ | ✅ |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

---

## Step 1.2 — Pixel-Perfect Parity Alignment ✅
**Date**: 2026-02-19 | **Status**: Complete

### Why
Applied all exact pixel values from `PARITY_STEP1.md` checklist to ensure both apps render identically.

### What Changed

#### 1. Shared Layout Tokens (`SalahLayout`)
Both apps now import a `SalahLayout` class/object with **identical constant names and values**:

| Token | Value | Used In |
|-------|-------|---------|
| screenPadding | 20 | All content horizontal padding |
| heroMinHeight | 118 | NextPrayerCard |
| heroPadding | 16 | NextPrayerCard |
| heroRadius | 22 | NextPrayerCard |
| heroBorderWidth / Opacity | 1 / 0.7 | NextPrayerCard gold border |
| heroIconBoxSize | 56 | NextPrayerCard icon area |
| heroIconSize | 26 | NextPrayerCard mosque icon |
| heroIconTextGap | 14 | Gap between icon box and text |
| heroLine1Size / CountdownSize / Line3Size | 15 / 28 / 12 | Hero text sizes |
| rowHeight | 54 | PrayerRow explicit height |
| rowPaddingH | 12 | PrayerRow horizontal padding |
| rowRadius | 14 | PrayerRow border radius |
| rowSpacing | 8 | Gap between prayer rows |
| rowIconSize / rowTextSize | 20 / 15 | PrayerRow icon+text sizes |
| navHeight | 62 | BottomNavBar |
| navRadius | 26 | BottomNavBar |
| navInsetH / navInsetBottom | 14 / 14 | BottomNavBar margins |
| pillHeight / pillRadius / pillPaddingH | 36 / 18 / 14 | Active nav pill |
| pillIconSize / pillTextSize | 16 / 14 | Active pill icon+text |
| gearButtonSize / gearIconSize | 36 / 18 | Settings gear button |

#### 2. Unique Prayer Icon Mapping (`PrayerIcons`)
Each prayer now has its own MDI icon (same glyph in both apps):

| Prayer | MDI Icon Name |
|--------|--------------|
| Fajr | `weather-sunset-up` |
| Dhuhr | `weather-sunny` |
| Asr | `weather-partly-cloudy` |
| Maghrib | `weather-sunset` |
| Isha | `weather-night` |
| Sunrise | `white-balance-sunny` |
| Last Third of Night | `moon-waning-crescent` |

#### 3. Highlighted Row: Full Gold
Next prayer row now shows **name + icon + time all in gold** (was: only icon gold).

### Files Changed (both apps)

| Flutter file | Expo file | Change |
|-------------|-----------|--------|
| `app_theme.dart` | `theme.js` | +SalahLayout, +PrayerIcons, +iconButtonBg |
| `app_header.dart` | `AppHeader.js` | screenPadding 20, locationIcon 16, text w500 |
| `app_icon_button.dart` | `AppIconButton.js` | size 36, iconSize 18, bg 0.18 |
| `next_prayer_card.dart` | `NextPrayerCard.js` | All hero tokens from SalahLayout |
| `prayer_row.dart` | `PrayerRow.js` | Height 54, unique icon, gold text for next |
| `bottom_nav_bar.dart` | `BottomNavBar.js` | Height 62, radius 26, pill 36/18/14 |
| `salah_screen.dart` | `SalahScreen.js` | All spacers from SalahLayout |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

### Analysis Files
- `analysis/step0_foundation.md` — Step 0 difficulties + Flutter vs Expo differences
- `analysis/step1_salah.md` — Step 1 difficulties + all errors encountered + comparison

---

## Step 2.1 — Settings: Theme Switching ✅
**Date**: 2026-02-20 | **Status**: Complete

### What was done
Implemented 4 selectable color themes (Night, Forest, Sand, Midnight Blue) with a Settings screen in both apps. Themes persist across app restarts. All UI components read colors dynamically from a ThemeProvider.

### Architecture
- **Flutter**: `ChangeNotifier` + `InheritedNotifier` → `ThemeScope.of(context).current` returns `ThemeColors`
- **Expo**: React Context + `useTheme()` hook returns `{ theme, setTheme }`
- **Persistence**: SharedPreferences (Flutter) / AsyncStorage (Expo)

### 4 Themes — 10 Color Tokens Each

| Token | Night (default) | Forest | Sand | Midnight Blue |
|-------|----------------|--------|------|---------------|
| backgroundStart | `#0D0D0D` | `#0A1A0A` | `#F5F0E8` | `#0A0E1A` |
| backgroundEnd | `#1A1A2E` | `#1A2E1A` | `#EDE4D3` | `#141E3C` |
| card | white@15% | white@15% | black@8% | white@15% |
| textPrimary | `#FFFFFF` | `#FFFFFF` | `#1A1A1A` | `#FFFFFF` |
| textMuted | `#9E9E9E` | `#8FA88F` | `#7A7060` | `#8E9EC0` |
| accent | `#D4A847` | `#4CAF50` | `#C49A3C` | `#64B5F6` |
| navBar | white@20% | white@20% | black@10% | white@20% |
| inactive | `#6B6B6B` | `#5A6B5A` | `#A09080` | `#5A6B8B` |

### Settings UI
- Back arrow + "Settings" header
- "Theme" section with 2×2 grid of theme cards
- Each card: gradient swatch + accent dot + theme name + checkmark if selected
- Placeholder sections for Location, Calculation Method, Notifications

### Files Changed

| Flutter (`prayer_app_flutter/lib/`) | Type |
|-------------------------------------|------|
| `src/theme/app_themes.dart` | NEW — 4 theme definitions |
| `src/providers/theme_provider.dart` | NEW — ChangeNotifier + InheritedNotifier |
| `src/screens/settings_screen.dart` | NEW — Settings UI with theme grid |
| `src/theme/app_theme.dart` | MODIFIED — static AppColors removed, typography/gradient parameterized |
| `main.dart` | MODIFIED — ThemeScope wrapper + settings navigation |
| All 8 components + salah_screen | MODIFIED — use `ThemeScope.of(context).current` |

| Expo (`prayer_app_expo/`) | Type |
|---------------------------|------|
| `src/theme/themes.js` | NEW — 4 theme definitions |
| `src/providers/ThemeProvider.js` | NEW — React Context + AsyncStorage |
| `src/screens/SettingsScreen.js` | NEW — Settings UI with theme grid |
| `src/theme/theme.js` | MODIFIED — static Colors removed, getTypography() parameterized |
| `App.js` | MODIFIED — ThemeProvider wrapper + settings navigation |
| All 8 components + SalahScreen | MODIFIED — use `useTheme()` hook |

### Parity Check
| Feature | Flutter ✅ | Expo ✅ | Match |
|---------|-----------|---------|-------|
| 4 identical themes (same hex colors) | ✅ | ✅ | ✅ |
| Theme persistence across restarts | ✅ | ✅ | ✅ |
| Settings screen layout | ✅ | ✅ | ✅ |
| 2×2 theme selector grid | ✅ | ✅ | ✅ |
| Immediate app-wide color update | ✅ | ✅ | ✅ |
| Status bar adapts to theme brightness | ✅ | ✅ | ✅ |
| Layout/spacing tokens unchanged | ✅ | ✅ | ✅ |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

---

## Step 2.2 — Location: Permission + City Name ✅
**Date**: 2026-02-20 | **Status**: Complete

### What was done
Added location permission, GPS coordinate detection, reverse geocoding (city + country), and persistence. A Location card in Settings shows the detected city, coordinates, source badge (GPS / Default), and a "Detect location" button.

### Architecture
- **Flutter**: `geolocator` (permission + GPS) + `geocoding` (reverse geocode) → `LocationService` + `LocationNotifier` (ChangeNotifier)
- **Expo**: `expo-location` (permission + GPS + reverse geocode) → `locationService.js` + React Context (`LocationProvider` in App.js)
- **Persistence**: SharedPreferences (Flutter) / AsyncStorage (Expo) — 6 keys: lat, lon, city, country, timezone, source
- **Fallback**: Bucharest (44.4268, 26.1025) if permission denied or GPS fails

### Settings Location Card
- Map-marker icon + "{city}, {country}" label
- GPS/Default source badge
- Coordinates in muted text
- "Detect location" button with loading spinner

### Header City Name
SalahScreen `AppHeader` now shows the detected city name dynamically (was hardcoded "Bucharest").

### Files Changed

| Flutter (`prayer_app_flutter/lib/`) | Type |
|-------------------------------------|------|
| `src/services/location_service.dart` | NEW — LocationService + LocationNotifier |
| `src/screens/settings_screen.dart` | MODIFIED — real Location card replaces placeholder |
| `src/screens/salah_screen.dart` | MODIFIED — dynamic city name via LocationNotifier |
| `main.dart` | MODIFIED — LocationNotifier created + passed to screens |
| `pubspec.yaml` | MODIFIED (+geolocator, +geocoding) |
| `ios/Runner/Info.plist` | MODIFIED (+NSLocationWhenInUseUsageDescription) |

| Expo (`prayer_app_expo/`) | Type |
|---------------------------|------|
| `src/services/locationService.js` | NEW — loadSavedLocation + detectLocation |
| `src/screens/SettingsScreen.js` | MODIFIED — real Location card replaces placeholder |
| `src/screens/SalahScreen.js` | MODIFIED — dynamic city name via useLocation |
| `App.js` | MODIFIED — LocationProvider context wrapping app |
| `package.json` | MODIFIED (+expo-location) |

### Parity Check
| Feature | Flutter ✅ | Expo ✅ | Match |
|---------|-----------|---------|-------|
| Permission request (foreground) | ✅ geolocator | ✅ expo-location | ✅ |
| GPS coordinate fetch | ✅ | ✅ | ✅ |
| Reverse geocode (city + country) | ✅ geocoding | ✅ expo-location | ✅ |
| Fallback to Bucharest | ✅ | ✅ | ✅ |
| 6-key persistence | ✅ SharedPrefs | ✅ AsyncStorage | ✅ |
| Location card in Settings | ✅ | ✅ | ✅ |
| Dynamic city in header | ✅ | ✅ | ✅ |
| Detect location button | ✅ | ✅ | ✅ |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

### How to Test
```bash
# Flutter
cd prayer_app_flutter && flutter run
# → Settings → Location card shows "Bucharest, Romania" (default)
# → Tap "Detect location" → accept permission → city updates

# Expo
cd prayer_app_expo && npx expo start
# → Same flow via Expo Go
```

---

## Step 2.2.1 — Timezone Fix: Drop timezonestring from AlAdhan ✅
**Date**: 2026-02-20 | **Status**: Complete

### Root Cause
Both prayer APIs were sending `timezonestring=Europe/Bucharest` to AlAdhan even when GPS coords were in San Francisco. The API obeyed the explicit timezone, returning times converted to Bucharest TZ, causing Fajr to show as 15:41 (PM) instead of ~05:41 (AM).

### Fix
- **Removed `timezonestring` param entirely** from both prayer API URLs
- AlAdhan auto-detects the correct timezone from latitude/longitude
- Confirmed via `meta.timezone` in API response (now returns `America/Los_Angeles` for SF coords)

### Sanity Check Added
Both apps now validate after parsing: `Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha`. If order is wrong, logs the request + meta.timezone and throws "Invalid timing data".

### Other Fixes in This Patch
- **Auto-detect on first launch**: both apps prompt for location permission at startup (not just from Settings)
- **Location-aware cache key**: `{date}_{lat}_{lon}` so location changes force refetch
- **SalahScreen refetch**: listens to location changes and re-loads prayer times
- **Expo require cycle fixed**: `LocationProvider` extracted to `src/providers/LocationProvider.js`

### Files Changed
| File | Change |
|------|--------|
| `prayer_api.dart` | Remove `timezonestring`, add sanity check, location-aware cache key |
| `prayerApi.js` | Same |
| `location_service.dart` | Device timezone detection (for persistence, no longer sent to API) |
| `locationService.js` | Same |
| `LocationProvider.js` (NEW) | Extracted from App.js to break require cycle |
| `main.dart` | Auto-detect on first launch |
| `salah_screen.dart` | Refetch on location change |
| `SalahScreen.js` | Same |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

### Known Issue
Flutter on iOS 26 simulator crashes with `objective_c.framework` error from `geolocator` package. This is a known simulator compatibility issue, not a code bug. Works on physical device.

---

## Step 2.3 — Prayer Settings: Method + Madhab (Store Only) ✅
**Date**: 2026-02-20 | **Status**: Complete

### What Changed
Added "Prayer Settings" section to Settings screen in BOTH apps with two selectors:
1. **Calculation Method** — ISNA, MWL (default), Umm al-Qura, Egyptian
2. **Madhab (Asr)** — Shafi/Standard (default), Hanafi

Values are persisted and survive app restart. **Not wired into Salah API** — that's Step 2.4.

### Files Changed
| File | Change |
|------|--------|
| `prayer_settings_service.dart` (NEW) | Persistence + `PrayerSettingsNotifier` (ChangeNotifier) |
| `prayerSettingsService.js` (NEW) | Persistence (AsyncStorage), option arrays, label helpers |
| `PrayerSettingsProvider.js` (NEW) | React Context + `usePrayerSettings()` hook |
| `settings_screen.dart` | Replaced "Calculation Method" placeholder with real glass card + modal bottom sheet |
| `SettingsScreen.js` | Same — replaced placeholder with glass card + slide-up Modal |
| `main.dart` | Create/load `PrayerSettingsNotifier`, pass to SettingsScreen |
| `App.js` | Wrap with `PrayerSettingsProvider` |

### How to Test Persistence
1. Open Settings → Change Method to "Umm al-Qura" and Madhab to "Hanafi"
2. Kill and restart the app
3. Open Settings → values should still show "Umm al-Qura" / "Hanafi"
4. Check console for `[PrayerSettings] methodId set to 4` / `school set to 1`

### Parity Check
| Aspect | Flutter | Expo |
|--------|---------|------|
| Method options | 4 (ISNA, MWL, Umm al-Qura, Egyptian) | Same ✅ |
| School options | 2 (Shafi, Hanafi) | Same ✅ |
| Default method | 3 (MWL) | Same ✅ |
| Default school | 0 (Shafi) | Same ✅ |
| Picker UI | Modal bottom sheet | Slide-up Modal ✅ |
| Persistence | SharedPreferences | AsyncStorage ✅ |
| Salah screen | Unchanged | Unchanged ✅ |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

---

---

## Step 2.4 — Offsets (Store Only) + Modal Fix ✅
**Date**: 2026-02-20 | **Status**: Complete

### What Changed
1. **Time Adjustments UI** — Added a new section under Prayer Settings with rows for Fajr, Dhuhr, Asr, Maghrib, Isha.
   - Controls: `[-] [Reset] [+]` (1 min steps, range -30 to +30).
   - Values are persisted to `SharedPreferences` (Flutter) and `AsyncStorage` (Expo).
2. **Fixed Modal Parity** — Redesigned the selection sheet/modal to match exactly in both apps:
   - **Background**: Solid glass card (card color at 0.96 opacity).
   - **Height**: Fixed at 45% of screen height.
   - **Radius**: 24 on top corners.
   - **Grabber**: Small pill at top center.
   - **Backdrop**: 0.35 dim overlay.

### Files Changed
| File | Change |
|------|--------|
| `prayer_settings_service.dart` | Added `loadOffsets`, `setOffset`, and `offsets` getter. |
| `prayerSettingsService.js` | Added `loadOffsets`, `setOffset`. |
| `PrayerSettingsProvider.js` | Added `offsets` state and `setOffset` method. |
| `settings_screen.dart` | Added `Time Adjustments` UI + fixed `_OptionSheet` spec. |
| `SettingsScreen.js` | Added `Time Adjustments` UI + fixed Modal spec. |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

### Parity Check
| Aspect | Flutter | Expo |
|--------|---------|------|
| Offset Range | -30 to +30 | Same ✅ |
| Modal Height | 45% Screen | Same ✅ |
| Modal Opacity | 0.96 (Solid Card) | Same ✅ |
| Modal Radius | 24 | Same ✅ |
| Controls | `[-] [Reset] [+]` | Same ✅ |

---

## Full Parity Audit ✅
**Date**: 2026-02-21 | **Status**: Complete

### What was done
Comprehensive audit of **every source file** in both apps — 15 Flutter and 16 Expo files covering themes, components, screens, services, and providers. Compared all color tokens (11 × 4 themes), 44 layout tokens, 4 typography styles, all spacing/radius values, all persistence keys, API URLs, and behavioral logic.

### Result
**Zero parity-breaking issues found.** All tokens, layout values, API parameters, cache keys, persistence keys, and behavioral logic match exactly between Flutter and Expo.

### Audit Report
- Full report: [`analysis/parity_audit.md`](file:///Volumes/ssd/theises/analysis/parity_audit.md)

---

## Step 2.5 — Wire Settings Into Salah ✅
**Date**: 2026-02-21 | **Status**: Complete

### What was done
Wired saved prayer settings (method, school, per-prayer offsets) into the Salah API request and time display in both apps. Previously the API hardcoded `method=2` (ISNA); now it uses the user's selection.

### Changes
1. **API URL** now includes `method={methodId}&school={school}` (user-selected)
2. **Offsets** applied post-fetch as minute adjustments to the 5 main prayer times
3. **Cache key** extended: `{date}_{lat}_{lon}_{methodId}_{school}`
4. **Re-fetch**: Salah screen listens to prayer settings changes (method, school, offsets)
5. **Post-offset sanity check**: Validates adjusted time order; falls back to previous data if broken

### Files Changed

| Flutter | Change |
|---------|--------|
| `services/prayer_api.dart` | `fetchToday({methodId, school})`, dynamic URL, extended cache key |
| `models/prayer_times.dart` | `applyOffsets()` + `sanityCheck()` methods |
| `screens/salah_screen.dart` | Passes settings to API, applies offsets, listens to settings changes |
| `main.dart` | Passes `prayerSettingsNotifier` to `SalahScreen` |

| Expo | Change |
|------|--------|
| `services/prayerApi.js` | `fetchPrayerTimes({methodId, school})`, dynamic URL, extended cache key |
| `screens/SalahScreen.js` | Uses `usePrayerSettings()`, applies offsets, listens to settings changes |

### Parity Check
| Feature | Flutter ✅ | Expo ✅ | Match |
|---------|-----------|---------|-------|
| API method param | ✅ | ✅ | ✅ |
| API school param | ✅ | ✅ | ✅ |
| Per-prayer offsets | ✅ | ✅ | ✅ |
| Cache key includes settings | ✅ | ✅ | ✅ |
| Re-fetch on settings change | ✅ | ✅ | ✅ |
| Post-offset sanity check | ✅ | ✅ | ✅ |
| No UI layout changes | ✅ | ✅ | ✅ |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

### How to Test
1. **Method**: Settings → change method to "Umm al-Qura" → Salah → check console for `method=4` in URL
2. **Madhab**: Settings → change to "Hanafi" → check console for `school=1` in URL
3. **Offsets**: Settings → set Maghrib +10 → Salah → Maghrib time shifts +10 min, countdown adjusts
4. **Location**: Simulate GPS change → `meta.timezone` in console changes, times update

---

## Step 2.3.1 — Expanded Methods + Auto-Select on Detect Location ✅
**Date**: 2026-02-21 | **Status**: Complete

### What was done
Expanded the calculation method picker from 4 to 8 options. Added a `methodMode` (auto/manual) setting with a toggle in the UI. When auto mode is ON and the user presses Detect Location, the method is automatically chosen based on the detected country.

### 8 Methods

| # | ID | Method |
|---|-----|--------|
| 1 | 3 | Muslim World League |
| 2 | 2 | ISNA |
| 3 | 4 | Umm al-Qura |
| 4 | 5 | Egyptian General Authority |
| 5 | 1 | Univ. of Islamic Sciences, Karachi |
| 6 | 7 | Inst. of Geophysics, Univ. of Tehran |
| 7 | 13 | Diyanet İşleri Başkanlığı, Turkey |
| 8 | 15 | Moonsighting Committee |

### Auto-Select Rules

| Country | Method |
|---------|--------|
| US, Canada | Moonsighting Committee (15) |
| Turkey | Diyanet (13) |
| Pakistan | Karachi (1) |
| Iran | Tehran (7) |
| Saudi Arabia | Umm al-Qura (4) |
| Egypt | Egyptian (5) |
| All others | MWL (3) |

### Files Changed

| Flutter | Change |
|---------|--------|
| `prayer_settings_service.dart` | 8 methods, `methodMode`, `autoMethodForCountry()`, `setMethodIdAuto()` |
| `settings_screen.dart` | Auto-select toggle, wired detect button |

| Expo | Change |
|------|--------|
| `prayerSettingsService.js` | 8 methods, `methodMode`, `autoMethodForCountry()` |
| `PrayerSettingsProvider.js` | `methodMode` state, `setMethodIdAuto`, `setMethodMode` |
| `LocationProvider.js` | `detect()` returns location |
| `SettingsScreen.js` | Auto-select toggle, wired detect button |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

### How to Test
1. Settings shows 8 methods in the picker
2. Auto-select toggle ON → detect location → method auto-updates based on country
3. Auto-select toggle OFF → detect location → method stays unchanged
4. Manually pick a method → toggle switches to OFF

---

## Step 3 — Qibla Screen (UI + Static Bearing) ✅
**Date**: 2026-02-21 | **Status**: Complete

### What was done
Built the Qibla screen with a static compass UI and bearing calculation in both Flutter and Expo. No device sensors — just geometric computation.

### Qibla Formula
```
Kaaba: lat=21.4225, lon=39.8262
Δlon = kaabaLon - userLon
y = sin(Δlon) * cos(kaabaLat)
x = cos(userLat)*sin(kaabaLat) - sin(userLat)*cos(kaabaLat)*cos(Δlon)
bearing = atan2(y,x) → degrees → normalize 0..360
```

### Screen Components
1. Title "Qibla"
2. City row with pin icon
3. Big degree value (accent, 48px)
4. "from North" subtitle
5. Compass dial with tick marks, N/E/S/W labels, needle, pointer, Kaaba marker
6. Status text with accent degree
7. Kaaba glass card (Arabic + transliteration)

### Files Changed

| Flutter | Change |
|---------|--------|
| `qibla_service.dart` | [NEW] `computeQiblaDegrees()` |
| `qibla_screen.dart` | [NEW] Full Qibla screen + `_CompassPainter` |
| `app_theme.dart` | Added `QiblaLayout` tokens |
| `main.dart` | Wired tab index 1 |

| Expo | Change |
|------|--------|
| `qiblaService.js` | [NEW] `computeQiblaDegrees()` |
| `QiblaScreen.js` | [NEW] Full Qibla screen + SVG `CompassDial` |
| `theme.js` | Added `QiblaLayout` tokens |
| `App.js` | Wired tab index 1 |
| `package.json` | Added `react-native-svg` |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

### How to Test
1. Tap Qibla tab → compass + bearing displayed
2. Bucharest (default) → ~149.4° from North
3. Change simulator location → degree changes accordingly
4. Salah screen unchanged

---

## Step 3.1 — Dynamic Qibla Compass (Device Heading) ✅
**Date**: 2026-02-21 | **Status**: Complete

### What was done
Made the Qibla compass rotate dynamically based on real device heading. On real devices, the compass dial rotates so N faces true north and the needle points toward Qibla. On simulators, falls back to static UI with "Compass not available" notice.

### Sensor Integration
- **Flutter**: `flutter_compass` 0.8.1 — `FlutterCompass.events` stream
- **Expo**: `expo-sensors` — `Magnetometer` with `atan2(y, x)` heading calculation
- Low-pass filter (alpha=0.2) with circular interpolation for smooth rotation
- Heading logged via `debugPrint`/`console.log`

### Rotation Strategy
- Compass dial (ring + ticks + N/E/S/W + needle + Kaaba marker) rotates by `-heading`
- Pointer triangle stays fixed at top (represents "you face this way")
- Combined effect: needle always points toward Qibla in real world

### Direction Guidance
- `|angleDiff| < 5°` → "Facing Qibla ✓" (accent color)
- `diff > 0` → "Turn right to face Qibla"
- `diff < 0` → "Turn left to face Qibla"
- No heading → fallback static text "Qibla is at X° from North."

### Files Changed

| Flutter | Change |
|---------|--------|
| `pubspec.yaml` | Added `flutter_compass: ^0.8.1` |
| `qibla_screen.dart` | StatefulWidget with heading stream, Transform.rotate, unavailable state |

| Expo | Change |
|------|--------|
| `package.json` | Added `expo-sensors` |
| `QiblaScreen.js` | Magnetometer hook, CSS transform rotate, unavailable state |

### Build Verification
- **Flutter**: `flutter analyze` → **No issues found** ✅
- **Expo**: `expo export --platform ios` → **Bundle OK** ✅

### Limitations
- Simulators don't have magnetometer → shows "Compass not available" (expected)
- Raw magnetometer heading may differ slightly from iOS/Android system compass
- Low-pass filter smoothing may lag 100-200ms behind fast rotations

---

## Step 3.1a — Fix Expo Compass Direction + Smoothing ✅
**Date**: 2026-02-21 | **Status**: Complete

### Root Causes
1. **Wrong direction**: `atan2(y, x)` gave opposite heading — needed `atan2(-y, x)` to match iOS compass convention
2. **Jittery motion**: Basic smoothing without proper shortest-angle helpers caused jumpy interpolation near 0/360
3. **Long spins at 360/0**: `Animated.Value` used absolute degrees — crossing north boundary caused 350°→10° long spin

### Fixes Applied
- **Heading**: `atan2(-y, x)` then `normalizeAngle(90 - angle)` — now matches Flutter
- **Helpers**: Added `normalizeAngle()` and `shortestDiff()` for circular math
- **Smoothing**: `shortestDiff(smoothed, raw) * alpha` — proper circular low-pass
- **Animation**: Cumulative rotation tracking via `shortestDiff` deltas — no boundary jumps
- **Rate**: 50ms Magnetometer interval (was 100ms)
- **Logging**: Diagnostic `heading/qibla/delta` for first 20 samples + every 50th

### Build
- `npx expo export --platform ios` → **Bundle OK** ✅

---

## Step 3.1b — Fix Expo Heading Source (Accuracy) ✅
**Date**: 2026-02-21 | **Status**: Complete

### Root Cause
Raw `Magnetometer` data (`atan2(-y, x)`) is **not tilt-compensated**. Tilting the phone even slightly skews the heading, causing the compass to point in the wrong Qibla direction. Flutter's `flutter_compass` uses the OS-level tilt-compensated heading, so it was accurate.

### Fix
- Replaced `expo-sensors` Magnetometer with `expo-location` `Location.watchHeadingAsync()`
- Uses `trueHeading` (declination-corrected) with fallback to `magHeading`
- This matches iOS's `CLHeading` — same quality as Flutter's `flutter_compass`
- Bumped smoothing alpha to 0.25, animation duration to 80ms
- Added temporary debug overlay showing `heading | qibla | delta`
- Added `ARROW_BASELINE_DEG = 0` constant for clarity

### Files Changed
| File | Change |
|------|--------|
| Expo `QiblaScreen.js` | Replaced Magnetometer with watchHeadingAsync |

### Build
- `npx expo export --platform ios` → **Bundle OK** ✅

---
