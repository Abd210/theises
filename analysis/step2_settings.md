# Step 2.1 — Settings: Theme Switching — Analysis

## Overview
This step adds user-selectable themes to both apps. While conceptually simple (swap colors), it required touching every UI component file in both codebases.

## Approach Comparison

### State Management for Themes

| Aspect | Flutter | Expo |
|--------|---------|------|
| Pattern | `ChangeNotifier` + `InheritedNotifier` | React Context + `useState` |
| Access | `ThemeScope.of(context).current` | `useTheme()` hook |
| Persistence | SharedPreferences | AsyncStorage |
| Rebuild scope | Widgets below `ThemeScope` auto-rebuild | Components using `useTheme()` re-render |

**Flutter observations:**
- `InheritedNotifier<ChangeNotifier>` is a clean built-in pattern — no external package needed
- `const` keyword on widgets is lost when they now depend on theme context
- `ThemeData` must be rebuilt when theme changes (involves `ColorScheme`, brightness)

**Expo observations:**
- React Context + hooks is the standard pattern, very straightforward
- No `const` optimization equivalent to worry about
- Colors are plain strings (hex/rgba), no `Color` class overhead

### Refactoring Effort

| Metric | Flutter | Expo |
|--------|---------|------|
| Files modified | 12 | 12 |
| New files | 3 | 3 |
| Lines added (approx) | ~450 | ~420 |
| Main challenge | Replacing `const` constructors | Converting static imports to hook calls |

### Dynamic Color Patterns

**Flutter** required changing:
- `AppColors.xxx` (static const) → `tc.xxx` (instance field from context)
- `AppTypography.titleLarge` (static final) → `AppTypography.titleLarge(tc)` (method taking theme)
- `const LinearGradient(...)` → `LinearGradient(...)` (no longer const)

**Expo** required changing:
- `Colors.xxx` (module-level const) → `tc.xxx` (from `useTheme()` hook)
- `Typography.xxx` (module-level object) → `getTypography(tc).xxx` (function call)
- Static style objects referencing colors → inline styles with dynamic values

### Light Theme Considerations
The Sand theme is the only light theme. Special handling:
- **Flutter**: `ThemeColors.brightness` field drives `ThemeData.brightness`, `ColorScheme.brightness`, and status bar style
- **Expo**: `tc.brightness` drives `StatusBar style` prop (`'light'` vs `'dark'`)
- Card colors use `rgba(0,0,0,0.08)` instead of `rgba(255,255,255,0.15)` for visible contrast on light backgrounds

## Difficulties Encountered
1. **No issues** — both builds passed on first attempt
2. The main complexity was the breadth of changes (every component file), not depth

## Key Takeaway
Both frameworks handle theming similarly. Flutter's `InheritedNotifier` is slightly more boilerplate than React Context but offers the same functionality. The refactoring effort was nearly identical in both apps.

---

# Step 2.2 — Location: Permission + City Name — Analysis

## Overview
This step adds location services to both apps: request permission, get GPS coordinates, reverse geocode to city name, persist, and display in Settings + header.

## Approach Comparison

### Location APIs

| Aspect | Flutter | Expo |
|--------|---------|------|
| Permission | `geolocator` (Geolocator.requestPermission) | `expo-location` (requestForegroundPermissionsAsync) |
| GPS coords | `geolocator` (getCurrentPosition) | `expo-location` (getCurrentPositionAsync) |
| Reverse geocode | `geocoding` (placemarkFromCoordinates) | `expo-location` (reverseGeocodeAsync) |
| Packages needed | 2 (`geolocator` + `geocoding`) | 1 (`expo-location`) |

**Flutter observations:**
- Needs two separate packages because `geolocator` doesn't do reverse geocoding
- `Geolocator.checkPermission()` / `requestPermission()` is synchronous-looking but async under the hood
- `Placemark` fields: `locality` for city, `country` for country — straightforward
- iOS Info.plist requires manual `NSLocationWhenInUseUsageDescription` entry

**Expo observations:**
- Single package (`expo-location`) handles everything — simpler dependency management
- `reverseGeocodeAsync` result uses `city` field (or `subregion`/`region` as fallback)
- Expo handles iOS plist keys automatically through the plugin system — no manual plist editing needed

### State Management for Location

| Aspect | Flutter | Expo |
|--------|---------|------|
| Pattern | `LocationNotifier` (ChangeNotifier) | `LocationContext` (React Context) |
| Listening | `ListenableBuilder` wraps AppHeader | `useLocation()` hook |
| Where defined | `location_service.dart` | `App.js` (alongside LocationProvider) |

**Flutter:** LocationNotifier extends ChangeNotifier, same pattern as ThemeProvider. Screens receive it as a prop from AppShell.

**Expo:** Used React Context in App.js, same pattern as ThemeProvider. Screens access via `useLocation()` hook — no prop drilling.

### Persistence

Both apps persist 6 keys: `loc_lat`, `loc_lon`, `loc_city`, `loc_country`, `loc_timezone`, `loc_source`. On next launch, `loadSaved()` returns persisted data immediately (no GPS call needed).

## Difficulties Encountered

1. **Flutter: `ChangeNotifier` import** — `location_service.dart` initially didn't import `package:flutter/foundation.dart`, so the `LocationNotifier extends ChangeNotifier` line failed. Fixed by adding the import.

2. **Flutter: Two packages vs one** — Having to use both `geolocator` and `geocoding` is slightly more friction than Expo's single `expo-location` package. Not a bug, just a framework difference worth noting.

3. **Timezone bug (critical)** — Both location services originally persisted `timezone: 'Europe/Bucharest'` as a fallback and sent it as `timezonestring=Europe/Bucharest` in the AlAdhan API request. When the user's GPS returned San Francisco coords, the API still used Bucharest timezone, causing Fajr to appear as 15:41 (Bucharest offset of the SF local time). **Root cause**: we overrode the API's auto-detection by explicitly providing a wrong timezone. **Fix**: removed `timezonestring` entirely from the API URL. AlAdhan auto-detects the correct timezone from lat/lon and returns `meta.timezone=America/Los_Angeles`. Added a sanity check (`Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha`) to catch similar issues early.

4. **Expo require cycle** — `SalahScreen.js` and `SettingsScreen.js` imported `useLocation` from `App.js`, which itself imports those screens. Fixed by extracting `LocationProvider` to `src/providers/LocationProvider.js`.

5. **Flutter iOS 26 simulator crash** — `geolocator` triggers `objective_c.framework` errors on iOS 26 simulator (known issue). Works on physical device.

## Key Takeaway
Expo wins slightly on developer ergonomics here — one package vs two, and automatic plist handling. But the actual implementation effort was very similar. Both apps needed roughly the same amount of code (~110 lines for the service, ~30 lines of UI wiring). The critical learning: **never override AlAdhan's timezone auto-detection** — just send lat/lon and let the API figure it out.

---

## Step 2.3 — Prayer Settings: Method + Madhab (Store Only)

### What I did
Added a "Prayer Settings" glass card in Settings (below Location, above Notifications placeholder) with two tappable rows:
- Calculation Method → tap opens a list picker → persist to SharedPreferences / AsyncStorage
- Madhab (Asr) → same pattern

### How it went
Pretty smooth. The service layer was trivial — just two int keys with load/set helpers + option lists.

**Flutter side**: Created `PrayerSettingsNotifier` (ChangeNotifier) so the UI rebuilds reactively when a value changes. Used `showModalBottomSheet` for the picker — fits naturally with the existing pattern. The sheet uses themed colors with a drag handle, title, and checkmark on the selected option.

**Expo side**: Created `PrayerSettingsProvider` (Context + hook). Used React Native's `<Modal>` with `animationType="slide"` for the picker. Same layout — transparent overlay, bottom sheet card, option rows with checkmark. The `pickerType` state (`'method'` | `'school'` | `null`) elegantly handles which modal is open without needing two separate modals.

### Differences observed
- **Picker mechanism**: Flutter's `showModalBottomSheet` is a built-in API with nice defaults (dark scrim, swipe-to-dismiss). Expo's `<Modal>` needs manual overlay styling and `onRequestClose`. Slightly more manual work in Expo.
- **State management**: Both follow the same pattern (service → notifier/context → UI), but Flutter's `ChangeNotifier` + `ListenableBuilder` is slightly less boilerplate than React's `createContext` + `useContext` + `useState` + `useEffect` + `useCallback`.
- **No difficulties**: No bugs encountered. Both built clean on first try.

### Parity status
Flutter ✅ | Expo ✅

Both show same options, same defaults (MWL / Shafi), same persistence, same debug logs. Salah screen untouched.

---

## Step 2.4 — Offsets (Store Only) + Modal/Sheet Parity Fix

### What I did
1.  **Time Adjustments**: Per-prayer offset UI with `[-] [Value/Reset] [+]` controls, clamped -30 to +30 minutes.
2.  **Sheet Parity Fix**: Modals were too transparent (settings content bled through).

### Root cause
- **Flutter**: `Color.alphaBlend(tc.card, tc.backgroundEnd)` produced a light tint because `tc.card` is `rgba(255,255,255,0.15)` — blending a near-white over dark then making it 96% opaque still looked light.
- **Expo**: Appending `'F5'` hex suffix to an `rgba()` string is invalid CSS and produced undefined behavior.

### Fix applied
Added `modalBg` to both theme systems — a pre-computed **solid opaque color** per theme (Night: `#252538`, Forest: `#253825`, Sand: `#E4DBCA`, Midnight Blue: `#202A48`).

- **Flutter**: `FractionallySizedBox(heightFactor: 0.45)` + `tc.modalBg` (fully opaque). Grabber 44×5 px. `barrierColor: Colors.black.withValues(alpha: 0.35)`.
- **Expo**: Separated backdrop (`absoluteFillObject`, `rgba(0,0,0,0.35)`) from sheet. Background: `tc.modalBg` (solid). Grabber 44×5 px. Padding 16px.

### Files changed
| File | Change |
|------|--------|
| `app_themes.dart` | Added `modalBg` field to `ThemeColors` + all 4 themes |
| `settings_screen.dart` | `_OptionSheet` → `FractionallySizedBox` + `tc.modalBg` |
| `themes.js` | Added `modalBg` to all 4 themes |
| `SettingsScreen.js` | Solid `tc.modalBg`, separate backdrop, 44×5 grabber |

### Parity status
Flutter ✅ | Expo ✅

Both apps now show a fully opaque, theme-matched modal. No settings content bleeds through.

---

## Step 2.5 — Wire Settings Into Salah (Safe Integration)

### What I did
Wired the stored prayer settings (method, school, offsets) into the Salah API and display. Before this, the API hardcoded `method=2` (ISNA) and ignored the user's selections.

### Changes
1. **API URL**: `method={methodId}&school={school}` now sent to AlAdhan. The old `_method = 2` constant was removed in both apps.
2. **Cache key**: Extended to `{date}_{lat}_{lon}_{methodId}_{school}` so switching method/school forces a refetch.
3. **Offsets**: Applied post-fetch as minute adjustments to the 5 main prayer times. Sunrise and Last Third stay unadjusted.
4. **Sanity check**: After offsets, validate `Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha`. If broken (e.g., aggressive offset pushes Asr past Maghrib), show error banner and keep previous valid data.
5. **Re-fetch on change**: SalahScreen now listens to prayer settings changes in addition to location changes.

### Difficulties
- **No real difficulties**. The wiring was straightforward since the prayer settings service, persistence, and UI were already complete from Steps 2.3–2.4.
- I was careful not to touch any UI layout tokens or spacing — only the data feeding.
- The Hijri string in Expo had a literal Unicode character `هـ` that I preserved by switching to `\u0647\u0640` to avoid encoding issues.

### Files changed
| File | Change |
|------|--------|
| `prayer_api.dart` | `fetchToday({methodId, school})` — removed hardcoded method, added school param |
| `prayer_times.dart` | `applyOffsets()` + `sanityCheck()` methods |
| `salah_screen.dart` | Passes settings to API, applies offsets, listens to settings changes |
| `main.dart` | Passes `prayerSettingsNotifier` to `SalahScreen` |
| `prayerApi.js` | `fetchPrayerTimes({methodId, school})` — removed hardcoded METHOD |
| `SalahScreen.js` | Uses `usePrayerSettings()`, applies offsets, listens to settings changes |

### Parity status
Flutter ✅ | Expo ✅

Both apps use the same API params, same cache key format, same offset logic, same sanity check. No UI regressions.

---

## Step 2.3.1 — Expand to 8 Methods + Auto-Select

### What I did
Expanded the method picker from 4 to 8 options. Added `methodMode` (auto/manual) as a stored setting. When auto is ON and the user presses Detect Location, I pick the method based on country (US→Moonsighting, Turkey→Diyanet, etc). Added a Switch toggle in the Prayer Settings section.

### Changes
1. **8 methods**: MWL, ISNA, Umm al-Qura, Egyptian, Karachi, Tehran, Diyanet, Moonsighting
2. **methodMode**: persisted via SharedPreferences / AsyncStorage, default "auto"
3. **autoMethodForCountry()**: static helper matching country string to best method ID
4. **Detect button**: after location detect, if auto → set method based on new country
5. **Manual picker**: tapping a method in the sheet now sets mode to "manual"
6. **Toggle**: "Auto-select method" with Switch/toggle. ON → auto-select runs immediately for current country. OFF → manual.

### Difficulties
- Flutter's `Switch.adaptive` has deprecated `activeColor` since 3.31. Had to switch to `activeTrackColor`.
- In Expo, `detect()` needed to return the location so the caller can read the country immediately. Updated `LocationProvider.js` to `return loc` after detecting — minor but necessary.

### Files changed
| File | Change |
|------|--------|
| `prayer_settings_service.dart` | 8 methods, `methodMode`, `autoMethodForCountry()`, `setMethodIdAuto()` |
| `settings_screen.dart` | Auto-select toggle, wired detect button |
| `prayerSettingsService.js` | 8 methods, `methodMode`, `autoMethodForCountry()` |
| `PrayerSettingsProvider.js` | `methodMode` state, `setMethodIdAuto`, `setMethodMode` |
| `LocationProvider.js` | `detect()` returns loc |
| `SettingsScreen.js` | Auto-select toggle, wired detect button |

### Parity status
Flutter ✅ | Expo ✅

Both apps show identical 8-method list, identical auto-select rules, identical toggle behavior. No Salah UI changes.
