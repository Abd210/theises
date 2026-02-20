# STEP 0 — Foundation: Design System + Shared Components

## 1) What Was Implemented
- Theme tokens: Colors, spacing (8-pt grid), border radius, typography
- 6 shared components: ScreenContainer, GlassCard, AppHeader, AppIconButton, AppDivider, BottomNavBar
- Demo screen rendering all components for visual verification
- Gradient background with SafeArea handling

## 2) Files Changed

### Flutter (`prayer_app_flutter/lib/`)
| File | Type |
|------|------|
| `src/theme/app_theme.dart` | NEW |
| `src/components/screen_container.dart` | NEW |
| `src/components/glass_card.dart` | NEW |
| `src/components/app_header.dart` | NEW |
| `src/components/app_icon_button.dart` | NEW |
| `src/components/app_divider.dart` | NEW |
| `src/components/bottom_nav_bar.dart` | NEW |
| `main.dart` | MODIFIED |
| `pubspec.yaml` | MODIFIED |

### Expo (`prayer_app_expo/`)
| File | Type |
|------|------|
| `src/theme/theme.js` | NEW |
| `src/components/ScreenContainer.js` | NEW |
| `src/components/GlassCard.js` | NEW |
| `src/components/AppHeader.js` | NEW |
| `src/components/AppIconButton.js` | NEW |
| `src/components/AppDivider.js` | NEW |
| `src/components/BottomNavBar.js` | NEW |
| `App.js` | MODIFIED |
| `package.json` | MODIFIED |

## 3) Difficulties / Errors + Fixes

### Flutter
- **No major issues.** Widget-based architecture maps naturally to a component catalog. `const` constructors and typed `ThemeData` made the token system strict and fast.
- Minor: Gradient background needed `BoxDecoration` + `LinearGradient` on `Container` wrapping `SafeArea`.

### Expo
- **Linear gradient**: RN has no built-in gradient — required `expo-linear-gradient` dependency (Flutter doesn't need extra deps for gradients).
- **Safe area**: Required `react-native-safe-area-context` + `SafeAreaProvider` at app root (Flutter's `SafeArea` is built-in).
- **Glass card border**: Low-opacity `borderColor` required `rgba()` strings vs Flutter's `Color(0x1AFFFFFF)` hex.
- **Bottom nav floating bar**: No Flutter `ClipRRect` equivalent; used `overflow: 'hidden'` + `borderRadius`.

## 4) Differences Observed

| Aspect | Flutter | React Native (Expo) |
|--------|---------|-------------------|
| Gradient | Built-in `LinearGradient` in `BoxDecoration` | Requires `expo-linear-gradient` package |
| SafeArea | Built-in `SafeArea` widget | Requires external package + provider |
| Styling | `BoxDecoration`, `EdgeInsets`, typed constants | `StyleSheet.create()`, inline style objects |
| Color format | `Color(0xAARRGGBB)` hex | `'rgba(r,g,b,a)'` strings |
| Theming | `static const` fields → compile-time safety | JS objects → runtime-only |
| Component model | `StatelessWidget` / `StatefulWidget` classes | Functional components + hooks |

## 5) Parity Status
- Flutter ✅
- Expo ✅

## 6) Next Step
Step 1: Implement Salah (Prayer Times) screen with AlAdhan API integration, real-time countdown, caching, and pull-to-refresh.
