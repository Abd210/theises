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

## Step 2.4 — Offsets (Store Only) + Modal Fix

### What I did
1.  **Time Adjustments**: Implemented the UI for per-prayer offsets. Each prayer has a row with a label and `[-] [Value/Reset] [+]` controls. Tapping the value resets it to 0. Range is clamped at -30 to +30 minutes.
2.  **Modal Fix**: The previous modals were too transparent and had inconsistent heights. I aligned them to a shared spec: 45% screen height, 24px corner radius, solid card background (0.96 opacity), and a drag handle.

### How it went
The state management for offsets was easy as I just extended the existing `PrayerSettingsNotifier` and `PrayerSettingsProvider`. 

**Flutter**: `showModalBottomSheet` with `isScrollControlled: true` allowed for the fixed 45% height. I used `Container` with a fixed height factor and `tc.card.withValues(alpha: 0.96)` for the background.

**Expo**: Updated the `Modal` to have a wrapper `View` at `SCREEN_HEIGHT * 0.45`. I used a hex suffix `F5` for the 0.96 opacity fix. Added `ScrollView` inside the modal so it can handle long lists of methods if needed in the future.

### Parity status
Flutter ✅ | Expo ✅

Both apps now have identical settings UI for offsets and matching selection modals. The "Time Adjustments" section looks tight and fits the design language perfectly in both frameworks.
