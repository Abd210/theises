# STEP 1 — Salah (Prayer Times) Screen + AlAdhan API

## 1) What Was Implemented
- **Models**: Prayer times parser (12h format, next prayer logic, countdown calc, Hijri date)
- **API**: AlAdhan API integration (`GET /v1/timings/{date}`, Bucharest coords, ISNA method, Europe/Bucharest tz)
- **Caching**: SharedPreferences (Flutter) / AsyncStorage (Expo)
- **UI**: NextPrayerCard (hero countdown), PrayerRow (schedule list), SalahScreen (full layout)
- **Real-time countdown**: 1-second timer, HH:MM:SS format
- **Pull-to-refresh**: Error banner + cache fallback
- **AppShell**: Tab navigation with placeholders for other screens

### Parity Fixes Applied (3 rounds)
1. **Round 1**: Inter font loaded in both apps, font scaling disabled, icons unified to MDI
2. **Round 2**: All pixel values from `PARITY_STEP1.md` applied — SalahLayout shared tokens (~40 constants)
3. **Round 3**: Unique prayer icon per row, Hijri BiDi text direction fix

## 2) Files Changed

### Flutter (`prayer_app_flutter/lib/`)
| File | Type |
|------|------|
| `src/models/prayer_times.dart` | NEW |
| `src/services/prayer_api.dart` | NEW |
| `src/services/cache_service.dart` | NEW |
| `src/components/next_prayer_card.dart` | NEW (then modified x2) |
| `src/components/prayer_row.dart` | NEW (then modified x2) |
| `src/screens/salah_screen.dart` | NEW (then modified x2) |
| `src/theme/app_theme.dart` | MODIFIED (+SalahLayout, +PrayerIcons) |
| `src/components/app_header.dart` | MODIFIED (MdiIcons, new sizes) |
| `src/components/app_icon_button.dart` | MODIFIED (36×36, 0.18 bg) |
| `src/components/bottom_nav_bar.dart` | MODIFIED (62×26, pill 36) |
| `main.dart` | MODIFIED (textScaler, Inter font) |
| `pubspec.yaml` | MODIFIED (+http, +shared_preferences, +intl, +google_fonts, +material_design_icons_flutter) |

### Expo (`prayer_app_expo/`)
| File | Type |
|------|------|
| `src/models/prayerTimes.js` | NEW |
| `src/services/prayerApi.js` | NEW |
| `src/services/cacheService.js` | NEW |
| `src/components/NextPrayerCard.js` | NEW (then modified x2) |
| `src/components/PrayerRow.js` | NEW (then modified x2) |
| `src/screens/SalahScreen.js` | NEW (then modified x2) |
| `src/theme/theme.js` | MODIFIED (+SalahLayout, +PrayerIcons, +interFont) |
| `src/components/AppHeader.js` | MODIFIED (MaterialCommunityIcons, new sizes) |
| `src/components/AppIconButton.js` | MODIFIED (36×36, 0.18 bg) |
| `src/components/BottomNavBar.js` | MODIFIED (62×26, pill 36) |
| `App.js` | MODIFIED (useFonts Inter, allowFontScaling=false) |
| `package.json` | MODIFIED (+@react-native-async-storage/async-storage, +@expo-google-fonts/inter, +expo-font) |

## 3) Difficulties / Errors + Fixes

### Flutter
1. **`withOpacity` deprecated** — Flutter 3.x deprecated `Color.withOpacity()` → fixed with `Color.withValues(alpha:)`
2. **`const` + `GoogleFonts`** — `GoogleFonts.inter()` returns non-const → changed `static const TextStyle` to `static final`
3. **`MdiIcons` not const** — `MdiIcons.xxx` are dynamic getters → removed `const` from Icon widgets
4. **Hijri BiDi reordering** — Arabic chars in `"2 رَمَضان 1447 هـ"` caused Skia to reorder digits → fixed with `\u200E` LTR mark + `textDirection: TextDirection.ltr`

### Expo
1. **fontWeight ↔ fontFamily coupling** — RN on Android ignores `fontWeight` without matching `fontFamily` → created `interFont(weight)` helper mapping `'700'` → `'Inter_700Bold'`
2. **npm install interrupted** — Initial `create-expo-app` npm install was interrupted (exit 130) → re-ran `npm install` separately
3. **No baseline alignment** — `alignItems: 'baseline'` less reliable than Flutter → required careful font size tuning
4. **Border opacity syntax** — No `Color.withValues()` equivalent → used template literals `` `rgba(212,168,71,${opacity})` ``

## 4) Differences Observed

| Aspect | Flutter | React Native (Expo) |
|--------|---------|-------------------|
| HTTP | `http` package | Built-in `fetch()` |
| Caching | `SharedPreferences` | `AsyncStorage` |
| Pull-to-refresh | Built-in `RefreshIndicator` | Built-in `RefreshControl` |
| Timer | `Timer.periodic()` (dart:async) | `setInterval()` + `useEffect` cleanup |
| State | `StatefulWidget` + `setState()` | `useState` + `useCallback` hooks |
| Font loading | `google_fonts` (runtime download) | `@expo-google-fonts` + `useFonts()` (bundled) |
| Font weight | `fontWeight: FontWeight.w700` auto-resolves | Must set `fontFamily: 'Inter_700Bold'` per weight |
| Font scaling | `MediaQuery(textScaler: TextScaler.linear(1.0))` | `Text.defaultProps.allowFontScaling = false` |
| Icons | `material_design_icons_flutter` → `MdiIcons.xxx` | `@expo/vector-icons` → `MaterialCommunityIcons name="xxx"` |
| BiDi text | Skia applies Unicode BiDi → needs `\u200E` or `textDirection` | Native renderer → renders LTR by default |
| Shadow | `BoxShadow` in `BoxDecoration` | `shadowColor` + `shadowOffset` + `elevation` |
| Layout tokens | `static const double` → compile-time | JS object → runtime-only |

## 5) Parity Status
- Flutter ✅
- Expo ✅

### Non-negotiable checks passed
| Check | Flutter | Expo | Match |
|-------|---------|------|-------|
| Hero card width (full available) | ✅ | ✅ | ✅ |
| Hero card minHeight 118 | ✅ | ✅ | ✅ |
| Hero icon box 56×56 | ✅ | ✅ | ✅ |
| Hijri string `"2 رَمَضان 1447 هـ"` | ✅ (LTR mark) | ✅ | ✅ |
| Row height 54 + spacing 8 | ✅ | ✅ | ✅ |
| Unique icon per prayer | ✅ | ✅ | ✅ |
| Same font (Inter) + weights | ✅ | ✅ | ✅ |
| Font scaling disabled | ✅ | ✅ | ✅ |

## 6) Next Step
Step 2: Implement Qibla screen (degree display + compass UI), then Quran, Azkar, and Settings screens.
