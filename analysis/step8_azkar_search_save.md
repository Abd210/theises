# Step 8 — Azkar Search + Save (Favorites)

## What was implemented
1. **Search**: Working search bar on Azkar home screen filters all items across all 6 categories, matching Arabic text and translation. 200ms debounce, results show category label + preview text. Tap opens AzkarDetail at exact item index.
2. **Favorites/Bookmark**: Bookmark icon in both Cards mode (counter footer) and List mode (item row). Toggling saves/removes from persistent storage. Filled = saved (accent), outline = unsaved (muted).
3. **Saved Azkar Screen**: Accessible via bookmark button on Azkar home. Shows saved items with category label, preview, remove button. Tap opens AzkarDetail at that item. Empty state: "No saved azkar yet."
4. **Persistence**: Favorites stored under key `azkar_favorites_v1` as JSON array of `{categoryId, index}` objects. Flutter: SharedPreferences, Expo: AsyncStorage.

## Files changed

### Flutter
- `lib/src/screens/azkar_screen.dart` — static search bar → working TextField with debounce, results list, bookmark nav to SavedAzkarScreen
- `lib/src/screens/azkar_detail_screen.dart` — added `initialIndex` param, bookmark toggle in card footer + list rows, favorites load/save
- `lib/src/screens/saved_azkar_screen.dart` — **[NEW]** saved items list with remove functionality

### Expo
- `src/screens/AzkarScreen.js` — static search bar → working TextInput with debounce, results list, bookmark nav to SavedAzkarScreen
- `src/screens/AzkarDetailScreen.js` — added `propInitialIndex` prop, bookmark toggle in card footer + list rows, favorites load/save
- `src/screens/SavedAzkarScreen.js` — **[NEW]** saved items list with remove functionality

## Difficulties / errors
- None. Implementation went smoothly.

## Flutter vs Expo differences
- None. Same search behavior, same bookmark states, same storage keys, same navigation flow.

## Parity status
- Flutter ✅
- Expo ✅

## Next step
- Verify manually on device: search for known terms, save items, restart, verify persistence.
