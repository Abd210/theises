# Step 5 — Quran (API + Core Polish + Juz Browsing)

## What I built

I completed Quran in both apps with parity, then added Juz browsing and fixed the Home search bar mismatch between Flutter and Expo.

### API and editions (same in both apps)
- Base: `https://api.alquran.cloud/v1`
- Surah endpoints:
  - `GET /surah`
  - `GET /surah/{surahNumber}/quran-uthmani`
  - `GET /surah/{surahNumber}/en.sahih`
- Juz endpoints:
  - `GET /juz/{juzNumber}/quran-uthmani`
  - `GET /juz/{juzNumber}/en.sahih`
- Editions locked:
  - Arabic: `quran-uthmani`
  - English: `en.sahih`

### Caching keys now used
- Surah list: `quran_surah_list_v1`
- Surah Arabic: `quran_surah_{n}_quran-uthmani_v1`
- Surah English: `quran_surah_{n}_en.sahih_v1`
- Juz Arabic: `quran_juz_{j}_quran-uthmani_v1`
- Juz English: `quran_juz_{j}_en.sahih_v1`

### Persistence keys (same both apps)
- `quran_last_read`
- `quran_recents`
- `quran_bookmarks`

## Feature status (both apps)

### Quran Home
- polished header + subtitle
- search entry to Surah List
- Continue card + empty hint
- Recents (top 3)
- 2-row horizontal Juz chip selector
- Juz chip tap now opens Reader at Juz start ayah (real API-backed)

### Surah List
- loads `/surah` with cache-first behavior + offline banner fallback
- search by number + English + Arabic

### Reader
- Arabic always loaded
- translation toggle loads English edition
- font +/-
- bookmark toggle
- jump-to-ayah on open
- brief flash highlight for target ayah
- lastRead updates while reading

### Bookmarks
- real bookmarks list
- Arabic preview snippet (~30 chars)
- long-press delete
- tap opens Reader at ayah

## What was fixed in this iteration

1. **Juz browsing implemented**
- Before: chips were UI-only.
- Now: chip -> resolve Juz start pointer from cached/fetched Juz Arabic ayahs -> open Reader.

2. **Search bar mismatch fixed**
- Before: Flutter and Expo search bars had different visual treatment (gradient mismatch).
- Now: both use the same glass-card style (`card` bg + `cardBorder`, same token radius/height).

## What went wrong / fixes

1. **Prompt path mismatch**
- Prompt asked for `/docs/AGENT_INSTRUCTIONS.md`, file not present.
- Used root `AGENT_INSTRUCTIONS.md`.

2. **Flutter analyze sandbox write restriction**
- Needed elevated permissions to run `flutter analyze` (SDK cache writes).

3. **Previous visual mismatch root cause**
- Flutter search used a high alpha gradient stop (`withValues(alpha: 0.85)`), producing a much brighter look than Expo.
- Fixed by removing special gradient and using same base style in both apps.

## Real Flutter vs Expo differences (implementation only)

- Juz open implementation uses the same logic but different async/state wiring:
  - Flutter: stateful widget + async `onTap` + `Navigator.push`
  - Expo: state-mode navigation + async `onTap` + React state updates
- Both now show loading state on the tapped Juz chip while opening.

## Verification

- Flutter: `flutter analyze` completed; only pre-existing Azkar warnings remain.
- Expo: `npx expo export --platform ios` passed.

## Parity status

- Flutter ✅
- Expo ✅

This step now includes real Juz browsing + visual search-bar parity in both apps.
