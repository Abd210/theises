# Step 5 (Rework) — Quran Mushaf Pages

## What I Did

Ripped out the old surah-based Quran reader and replaced it with a page-based Mushaf pager. The Quran now shows pages 1–604, swiped horizontally like a real mushaf book.

## The Journey

### Starting Point
The previous reader loaded one surah at a time, scrolled vertically. Juz selection was broken because `getJuzStartPointer` returned a surah/ayah pair and opened the surah-level reader, which didn't even correctly position within the surah for most Juz boundaries.

### API Discovery
The `api.alquran.cloud/v1/page/{N}` endpoint was the key. Each page response includes ayahs with `surah`, `juz`, `page`, `numberInSurah` — everything needed to render a mushaf page and determine Juz boundaries without manual mapping.

### Building the Pager
- **Flutter**: `PageView.builder` with 604 items. Each page fetches ayahs on demand. Only current page + ±1 prefetch to avoid loading all 604 pages at once.
- **Expo**: `FlatList` with `horizontal` + `pagingEnabled` + `getItemLayout` for snapping. Same on-demand fetch logic.

### Hardest Part
Getting the Expo `FlatList` to behave like Flutter's `PageView` was finicky. The key was `getItemLayout` (giving exact width per item = screen width) plus `pagingEnabled` for snap behavior. Without `getItemLayout`, scroll-to-index fails.

### Juz Fix
The old approach called `getJuzStartPointer(juz)` which returned a surah+ayah and then tried to load that surah's reader. The fix: call the juz endpoint, read `data.ayahs[0].page`, and open the Mushaf pager at that page. Simple and correct.

## Differences Between Flutter and Expo

| Aspect | Flutter | Expo |
|--------|---------|------|
| Pager widget | `PageView.builder` (built-in) | `FlatList` horizontal + `pagingEnabled` |
| Page change detection | `onPageChanged` callback | `onViewableItemsChanged` |
| Scroll-to-page | `pageController.animateToPage` | `flatListRef.scrollToIndex` |
| Translation merge | Instance method on API service | Standalone exported function |

## What Changed
- New `PageAyah` model in both apps (includes `juz`, `page`, `surahNumber`, `globalNumber`)
- `QuranPointer` now has optional `pageNumber` field
- New `MushafPagerScreen` in both apps
- `QuranScreen` home rewired: Continue/Recents/Juz all open MushafPager
- Old surah-based reader files kept but no longer navigated to from home

## Parity Fixes

### Bottom Bar Overlap (Expo)
First version of the Expo bottom bar used `position: 'absolute'`, which caused it to float over the ayah content. Flutter's bar was part of a `Column` layout (below the `Expanded` PageView), so it never overlapped. Fix: removed `position: absolute` from Expo, wrapped `FlatList` in a `flex:1` View, and used `marginHorizontal/marginBottom` instead — matching Flutter's Column-based layout exactly.

### Bottom Bar Height Mismatch
Flutter's `IconButton` widget enforces a default 48×48 minimum touch area. Expo's `TouchableOpacity` only wrapped the 24px icon, making the bar visibly shorter. Fix: added a `navBtn` style (`width: 48, height: 48, alignItems: 'center', justifyContent: 'center'`) to both chevron buttons, matching Flutter's `IconButton` sizing. The bottom bar now renders at the same height in both apps.

### Key Takeaway
Flutter's `IconButton` silently enforces a 48×48 minimum — something easy to miss when porting to Expo where `TouchableOpacity` has no such default. Always check rendered sizes side-by-side, not just code structure.

## Parity Status
Flutter ✅ | Expo ✅ — Both apps show identical Mushaf pager UI.
