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
