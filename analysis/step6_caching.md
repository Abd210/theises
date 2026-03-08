# Step 6 — Caching Analysis

## What I Did
Implemented offline-first caching for the app. This was my first time working with caching strategies in mobile — I had to think about TTLs, stale data, and month boundaries.

## Prayer Times Cache

### The Problem
The Salah screen fetched prayer times for today only, every time the screen loaded. No way to see tomorrow or next days. If you're offline, you get an error.

### What I Chose
Switched from the single-day `/v1/timings/{date}` endpoint to the monthly `/v1/calendar` endpoint. This gives you all 30-31 days in one request. I cache the full month JSON and extract individual days.

### Why Monthly Instead of Daily
- 1 network request covers 30 days instead of 7
- If user opens app on March 28, I only need to fetch March + April (2 requests max)
- Cache key is simple: `prayer_cal_{YYYY}_{MM}`

### TTL Decision
7 days. Prayer times for a given location/method don't change. But if someone travels, stale data from their old location shouldn't stick around forever. 7 days felt like a good balance.

### Stale-While-Revalidate
If the cache is expired but network fails, I return the stale data + show the "Offline (cached)" banner. Better to show slightly old times than nothing.

## Day Navigation

Added horizontal swipe (7 pages: today + next 6 days). Flutter uses `PageView.builder`, Expo uses `FlatList` with `pagingEnabled`. Day dots at top show which page you're on.

One tricky bit: the countdown timer only makes sense for "Today". For future days I show "—" instead.

## Azkar Resume

Simple: save the category ID when the user opens a category. On the grid screen, check for `azkar_last_category` in storage and show a "Resume" card if found. The per-category progress (counters + lastIndex) was already being saved.

## Location + Settings

Both were already fully persisted from earlier steps. Location persists lat/lon/city/country. Settings persist theme/method/school/offsets. Nothing new needed.

## Flutter vs Expo Differences

| Aspect | Flutter | Expo |
|--------|---------|------|
| Storage | SharedPreferences | AsyncStorage |
| Day pager | `PageView.builder` | `FlatList` horizontal pagingEnabled |
| Page change callback | `onPageChanged` | `onViewableItemsChanged` |
| State management | StatefulWidget + setState | useState + useCallback |
| AzkarScreen conversion | StatelessWidget → StatefulWidget | Already functional component |
| TextDirection conflict | `package:intl` shadowed `dart:ui`'s TextDirection → needed `hide TextDirection` | No issue |

## Test Checklist

| Test | Expected |
|------|----------|
| Open Salah | Shows today's times |
| Swipe left on Salah | Shows tomorrow's times |
| Swipe to day 7 | Shows 6-days-ahead times |
| Day dots update | Active dot moves with swipe |
| Turn on airplane mode → reopen | Cached times + "Offline (cached)" banner |
| No cache + no internet | Shows error + "Retry" button |
| Open Morning Azkar | `azkar_last_category` saved |
| Go back to Azkar grid | "Resume: Morning Azkar" card appears |
| Tap Resume card | Opens at last saved index |
| Change method → restart | Same method persisted |
| Change theme → restart | Same theme persisted |
| Detect location → restart | Same city shown |
