# AGENT_INSTRUCTIONS.md
## Thesis Project: Flutter vs React Native (Expo) — Muslim App (Performance + Productivity)

You are an AI coding agent helping Abd build TWO feature-identical mobile apps:
- App A: Flutter
- App B: React Native (Expo)

Purpose: compare **Performance** and **Productivity** fairly for a thesis titled:
“Performance and Productivity Analysis of Contemporary Cross-Platform Mobile Development Technologies”
using a Muslim app as the case study.

### Key Rule (Critical)
Everything you implement MUST be done in **both apps** with the **same UI, same features, same behavior**, unless explicitly stated as platform-limited.

---

## 1) Project Understanding (What we’re building)
A Muslim mobile app with **5 bottom tabs**:
1. Salah (Prayer Times)
2. Qibla
3. Quran
4. Azkar
5. Settings

Style: Dark premium UI with warm-gold accents (like the provided mockups).
Navigation: bottom nav bar with a floating translucent background + a gold “active pill”.

Main goal: Build both apps to match the same Figma mockups, then measure:
- Performance: startup, rendering time, FPS/jank, CPU/memory, energy, app size
- Productivity: time per feature, bugs/fix time, change request speed, build time

---

## 2) Repository Structure (Expected)
/prayer_app_flutter        -> Flutter implementation
/prayer_app_expo           -> React Native Expo implementation
/docs               -> specs, instructions, test plans
/results            -> benchmark logs, screenshots, CSV/XLSX

If folders don’t exist, create them.

---

## 3) Non-Negotiable Parity Rules (for fair comparison)
### UI Parity
- Use the SAME layout structure, same content density, same component types across both apps.
- Keep spacing on an 8px grid. Keep card sizes and paddings consistent (±2px allowed).
- Use the same icon set and same font family in both apps.
- Avoid adding extra animations or heavy effects in only one app.

### Feature Parity
- Every feature exists in both apps:
  - Salah: next prayer card + list
  - Qibla: degree + compass UI
  - Quran: search + sections (recents, juz placeholders ok for MVP)
  - Azkar: category grid -> detail list
  - Settings: theme + location + method + adjustments

### Data / Logic Parity
- Use the same data model and same rules in both apps.
- If one app uses API calls, the other must use the same API calls.
- If caching exists, same caching behavior.

### Performance Measurement Parity
- Keep comparable UI complexity:
  - similar number of list rows, same number of cards, similar shadows/blur levels.
- Benchmark in Release/Production modes (not Debug).

---

## 4) Theme + Design System (Classic Rules)
### Theme Identity
- Background: deep charcoal/black gradient
- Cards: translucent “glass” panels (subtle, not bright)
- Accent: warm gold/yellow for highlights
- Text: white primary + muted gray secondary

### Tokens (Define once, reuse everywhere)
Create a theme token file in BOTH apps with these values (fill with exact hex later):
- Colors:
  - backgroundStart
  - backgroundEnd
  - card
  - cardBorder (very subtle)
  - textPrimary
  - textMuted
  - accentGold
- Typography:
  - fontFamily (same in both)
  - titleLarge, titleMedium, body, caption
- Radius:
  - radiusCard (≈ 24–28)
  - radiusPill (≈ 999)
- Spacing:
  - s8, s16, s24, s32

### Components must use tokens only
No hardcoding random colors/sizes inside components.
All UI should reference the theme tokens.

---

## 5) UI Components Catalog (Build these first)
Create reusable components in BOTH apps with same props & behavior:

### Shared
- ScreenContainer (gradient background + safe area)
- AppHeader (left: location, right: gear/settings)
- GlassCard (translucent card with radiusCard)
- Divider (subtle)
- IconButton (circular translucent)
- BottomNavBar (floating bar + gold active pill)

### Salah
- NextPrayerCard (icon + “Next Prayer: X” + countdown)
- PrayerRow (icon + name + time + optional highlight)

### Qibla
- DegreeHeader (big gold degrees + “from North”)
- CompassDial (static UI; real sensor later if needed)
- InfoText (compass unavailable message + gold degree highlight)
- KaabaLabelCard

### Azkar
- CategoryGridCard (icon + title + subtitle + arrow)
- AzkarItemCard (Arabic + transliteration + counter controls)
- CounterControls (+ / reset)

### Quran
- SearchBar
- SectionCard (Recents, Juz)
- List placeholders until content is implemented

### Settings
- ThemeSelectorCard (Night/Forest/Sand mock)
- LocationCard (city + detect button)
- DropdownRow (calculation method)
- TimeAdjustmentsList (Fajr/Dhuhr/Asr/Maghrib/Isha with stepper)

---

## 6) Navigation Rules
- Bottom tabs always visible on main screens.
- Tab order: Salah, Qibla, Quran, Azkar, Settings.
- Azkar:
  - Main screen = category grid
  - Tapping a category navigates to AzkarDetail screen (push navigation).
- Settings can be a tab screen (not modal). Gear icon can navigate to Settings too (optional).

---

## 7) “Do it for both apps” Workflow (Mandatory)
When Abd asks to implement something:
1) First, describe changes needed in BOTH apps in a short checklist.
2) Implement in Flutter.
3) Implement the equivalent in Expo (same names, same structure).
4) Provide a “Parity Check” summary:
   - screens changed
   - components changed
   - any intentional differences (must be justified)

Never implement a feature in only one app unless explicitly requested.

---

## 8) Definition of Done (for any task)
A task is DONE only when:
- ✅ Flutter has it
- ✅ Expo has it
- ✅ UI looks the same (structure, spacing, colors, typography)
- ✅ Navigation works
- ✅ No console/runtime errors
- ✅ Uses theme tokens, not random hardcoded values

---

## 9) MVP Scope (What to build first)
### Phase 1: UI-only (no real APIs yet)
- Build all 5 tabs with mock data matching the Figma.
- Ensure theme + components are reusable.
- Ensure navigation works.

### Phase 2: Data + Logic
- Add location handling (permission + manual fallback)
- Add prayer times source (API or algorithm)
- Next prayer calculation + countdown
- Qibla calculation (degrees) + sensor optional
- Azkar data (static JSON list)
- Quran data (static placeholders or JSON)

### Phase 3: Benchmark Preparation
- Release builds
- Stable test scripts
- Logging templates in /results

---

## 10) Performance/Benchmark Hooks (keep simple)
Add optional instrumentation points in both apps (same naming):
- logEvent("app_start")
- logEvent("home_rendered")
- logEvent("prayer_times_visible")
Store logs for later measurement.

Do NOT add heavy analytics SDKs. Keep it lightweight.

---

## 11) Coding Style Rules
- Keep code modular and readable.
- Mirror folder structure across both apps as much as possible:
  - /src/theme
  - /src/components
  - /src/screens
  - /src/navigation
  - /src/data (mock JSON)
- Keep component names consistent across frameworks.

---

## 12) What you MUST ask Abd only if needed
Avoid questions unless blocked.
Only ask if a decision is required:
- exact hex codes / font choice
- prayer time source choice (API vs offline)
- devices for benchmarking

Otherwise proceed with best defaults that match the mockups.

---

## 13) Quick Defaults (Use unless Abd overrides)
- Theme: dark gradient + gold accent
- Bottom nav: floating translucent + active gold pill
- Icons: pick ONE consistent icon pack and use in both
- Fonts: use the same font in both (system if needed)

END OF INSTRUCTIONS
