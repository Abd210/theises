# Step 5 — Quran (API-based)

Quran feature implemented with full parity between Flutter and Expo.

## Features Built
- **Quran Home**: Title, search bar, continue reading card, recents list, juz grid.
- **Surah List**: Fetched from API, searchable by number/English/Arabic.
- **Reader**: Fetched from API (uthmani Arabic + sahih English). 
- **Persistence**: Scrolls to last ayah, saves recents, toggle bookmarks.
- **Caching**: AsyncStorage/SharedPreferences JSON storage with offline "cached" banner.

## Tech Specs
- **API**: AlQuran.cloud (Uthmani edition for Arabic, Saheeh International for English).
- **Architecture**: Separated API, Storage, and UI layers.
- **Parity**: Identical `QuranLayout` tokens used in both apps.
- **Caching Logic**: Try cache → Fetch API → Update cache → Fallback to cache if offline.

## Differences Found
- **Jump to Ayah**: 
  - Flutter uses `GlobalKeys` and `Scrollable.ensureVisible`.
  - Expo uses `FlatList.scrollToIndex` (approximate).
- **Text Rendering**: Both use system fonts for Arabic; Flutter's `height` property is slightly more sensitive than Expo's `lineHeight`.

## Verification
- Search "baq" → Al-Baqara shows up.
- Airplane mode → Cached surahs load with banner.
- Restart app → Continue Reading card restores correctly.
