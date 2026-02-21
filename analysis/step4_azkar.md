# Step 4 — Azkar (Grid + Detail Reader)

## What was built

### Data Layer
- `AzkarItem` model: arabic text, translation, repeat count
- `AzkarCategory` model: id, title, subtitle, icon, items list
- 6 categories: Morning, Evening, After Salah, Sleep, Waking Up, General
- Flutter: `lib/src/models/azkar_data.dart` (const lists, compile-time optimization)
- Expo: `src/data/azkarData.js` (same content, same order)

### Theme Tokens
- `AzkarLayout` class/object added to both `app_theme.dart` and `theme.js`
- Tokens: screenPadding, titleMarginTop, subtitleSize, search, grid, detail, segmented control

### Screens
Both apps share identical layout, spacing, icons, and interaction patterns.

#### AzkarScreen (Grid Home)
- Title "Azkar" + subtitle + search bar (UI-only) + bookmark icon
- 2-column grid of glass cards: icon box, title, subtitle, arrow
- Category icons: weather-sunny, moon-waning-crescent, star-four-points-outline, power-sleep, weather-sunset-up, heart-outline

#### AzkarDetailScreen (Reader)
- Top bar: back arrow, category title, "N / total" badge
- Segmented control: Cards | List toggle
- Cards mode: swipeable PageView/FlatList paging, one dhikr per card
- List mode: scrollable list, tap to increment
- Per-item counter: increment (+) and reset buttons
- "Completed ✓" badge when count ≥ repeatCount
- Border color changes to gold accent when done

### Persistence
- SharedPreferences (Flutter) / AsyncStorage (Expo)
- Key: `azkar_{categoryId}` → JSON { counters: [...], lastIndex: N }
- Restored on screen open

### Navigation
- Tab index 3 wired in both `main.dart` and `App.js`
- Flutter: `Navigator.push` from grid → detail
- Expo: state-based navigation (selectedCategory → detail screen component)

## Parity Matrix

| Feature | Flutter | Expo | Match |
|---------|---------|------|-------|
| Grid layout | 2-col GridView | 2-col FlatList | ✅ |
| Card tokens | AzkarLayout.* | AzkarLayout.* | ✅ |
| Icons | MDI via material_design_icons_flutter | MDI via react-native-vector-icons | ✅ |
| Search bar | Container + Icon.search | View + Icon magnify | ✅ |
| Swipe (Cards) | PageView | FlatList horizontal paging | ✅ |
| List mode | ListView.separated | FlatList + ItemSeparator | ✅ |
| Segmented control | Custom Row + GestureDetector | Custom Row + TouchableOpacity | ✅ |
| Counter persist | SharedPreferences JSON | AsyncStorage JSON | ✅ |
| Navigation | Navigator.push | State-based | ✅ |

## Build Verification
- `flutter analyze` → 0 errors (info-level deprecation warnings only) ✅
- `npx expo export --platform ios` → Bundle OK ✅

---

## Step 4b — Expo Bug Fixes

### A. FlatList Crash
**Root cause**: `onViewableItemsChanged` was created inline — switching between Cards/List modes caused React Native to detect the callback changing between null and a function, throwing `Invariant Violation: Changing onViewableItemsChanged nullability on the fly is not supported`.

**Fix**: Both `onViewableItemsChanged` and `viewabilityConfig` are now wrapped in `useRef(...).current`, making them stable references that never change across renders.

### B. Wrong Theme Property
**Root cause**: Expo detail screen used `tc.accentGold` everywhere, but the Expo theme defines the property as `tc.accent`.

**Fix**: All occurrences of `tc.accentGold` replaced with `tc.accent`.

### C. Stale Closure in Counter
**Root cause**: `increment`/`reset` callbacks captured `currentIndex` from state, causing stale index in persistence calls.

**Fix**: Added `currentIndexRef` (useRef) updated in sync with state, used inside callbacks for accurate persistence.

### D. UI Token Parity
All spacing, padding, icon sizes, and colors now use `AzkarLayout.*` tokens identically to Flutter. Icon colors explicitly set to `tc.accent` (gold in Night theme).

### Build
- `npx expo export --platform ios` → **Bundle OK** ✅

---

## Step 4c — Azkar Parity Rescue

### 1. FlatList Crash (FINAL fix)
**Root cause**: Even with `useRef`, switching between Cards/List conditionally mounted the same FlatList with different props at different times.

**Fix (Option A)**: Split into **two separate React components** — `AzkarCardsPager` and `AzkarListView` — each with its own FlatList. When viewMode changes, one unmounts and the other mounts. No FlatList ever sees its props change.

Additionally removed `onViewableItemsChanged` entirely from Cards mode. Page index tracked via `onMomentumScrollEnd` only.

### 2. Card Layout (Centering + Snap)
**Root cause**: `CARD_WIDTH` was `SCREEN_W - 2*padding`, and padding was applied inside the item. This left partial next card visible.

**Fix**: `CARD_WIDTH = SCREEN_W` (full screen width). `pagingEnabled` on full-width items = perfect snap. Padding applied via `paddingHorizontal: screenPadding` inside each card item, so the card face is inset but the snap interval is exact.

### 3. Navbar Hidden on Detail
**Fix**: Added `onHideNav` callback from `AzkarScreen` → `App.js`. When `selectedCategory` is set, `hideNav=true`, removing the `BottomNavBar` from render. Matches Flutter's `Navigator.push()` behavior.

### 4. Data Parity
4 items were missing from Expo:
- Morning index 17: `أَصْبَحْنا عَلَى فِطْرَةِ الْإِسْلَامِ...`
- Evening index 8: `اللَّهُمَّ ما أمسَى بي مِن نِعمَةٍ...`
- AfterSalah index 2: `لَا إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَ...`
- Sleep index 10: `اللَّهُمَّ عَالِمَ الغَيْبِ وَالشَّهَادَةِ...`

**Fix**: Complete rewrite of `azkarData.js`, copied item-by-item from Flutter.

**Verified**: `morning:24✅ evening:15✅ after_salah:11✅ sleep:12✅ waking_up:3✅ general:8✅ TOTAL:73✅`

### Build
- `npx expo export --platform ios` → **Bundle OK** ✅
- `flutter analyze` → **0 errors** ✅

---

## Step 4d — Azkar Layout Parity

### A. AzkarLayout Tokens Updated (both apps)
New tokens added with identical values:
- `topHeaderGap: 12`, `segmentHeight: 40`, `detailCardRadius: 22`
- `detailCardBorderWidth: 1`, `detailCardBorderOpacity: 0.7`, `detailCardPadding: 16`
- `cardsPagerHeightFactor: 0.62`, `footerHeight: 72`, `footerBottomInset: 14`
- `listCardMinHeight: 140`, `listCardPadding: 16`, `listCardSpacing: 12`

### B. Cards Mode Vertical Alignment
Expo pager now uses full `SCREEN_W` for `pagingEnabled` snap. Card rendered inside with `paddingHorizontal: screenPadding`. Counter row uses fixed `height: footerHeight (72)`.

### C. List Mode Spacing
Both apps use `listCardSpacing: 12` between items and `listCardPadding: 16` inside cards. Expo list gets `paddingBottom: insets.bottom + footerBottomInset`.

### D. Flutter Bottom Strip Removed
Root cause: `ScreenContainer` wraps with `SafeArea(bottom: false)`, then detail screen adds its own `SafeArea` — gap between them painted the gradient differently.
Fix: Removed `ScreenContainer` from detail screen. Applied `appBackgroundGradient` directly to a `Container`, with single `SafeArea(bottom: true)`.

### E. Deprecated API Cleanup
All `withOpacity()` calls replaced with `withValues(alpha:)` in both Azkar screens.

### Build
- `flutter analyze` → 2 info (no errors/warnings) ✅
- `npx expo export --platform ios` → Bundle OK ✅

---

## Step 4.3 — Save & Restore Progress (Already Implemented)

Progress persistence was implemented during the initial detail screen build and has been preserved through all subsequent refactors.

### Data Model (both apps)
- Key: `azkar_{categoryId}` (e.g. `azkar_morning`)
- JSON: `{ "counters": [0, 2, 1, ...], "lastIndex": 3 }`
- Completed: derived from `counter >= item.repeatCount` (not stored separately)

### Storage
- **Flutter**: `SharedPreferences.getString/setString`
- **Expo**: `AsyncStorage.getItem/setItem`

### Behavior ✅
- Increment (+): persists immediately via `_saveProgress()` / `saveProgress()`
- Reset: sets counter to 0, persists immediately
- Swipe: updates `lastIndex`, persists immediately
- Reopen category: loads saved progress, scrolls to `lastIndex`, shows counter state

### Issues Found
None. Both apps behave identically.
