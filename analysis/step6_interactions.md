# Step 6.0.1 — Touch Targets (Interactions Diary)

**Date**: 2026-03-07
**Goal**: Make every interactive element have ≥ 44×44pt hit area without changing visual UI.

---

## What I Did

Audited every interactive element across both Flutter and Expo apps. Found several components below the 44×44pt Apple HIG minimum:

- **AppIconButton**: 36×36 (gear icon, etc.) → only 8pt below threshold
- **Bottom nav inactive tabs**: ~38×38 (padding-based, close but inconsistent)
- **Settings back arrow**: bare 24×24 icon wrapped in a tap detector — very hard to hit
- **Settings offset +/- buttons**: tiny ~24×24 due to `padding: 4` + 16px icon
- **Azkar reset button**: 36×36 circle
- **Quran reader top-bar icons (Expo only)**: bare `TouchableOpacity` around 20px icons without `hitSlop`

## Difficulties / Decisions

1. **Flutter `IconButton` vs custom**: The Quran reader in Flutter already uses `IconButton`, which defaults to 48×48 with `materialTapTargetSize`. No changes needed there. But the Expo version used bare `TouchableOpacity` — needed `hitSlop` everywhere.

2. **SizedBox vs hitSlop strategy**: In Flutter, `hitSlop` doesn't exist on `GestureDetector`, so I used `SizedBox(width: 44, height: 44)` as a wrapper with `Center` to keep the visual element small but the tap area large. In Expo, `hitSlop` is the idiomatic solution since it expands the touch area without affecting layout.

3. **Bottom nav tab sizing**: Changed from `paddingVertical: 8` to `minHeight: 44` in Expo. This is more intentional and won't break if icon sizes change later.

4. **Settings counter buttons**: These were the worst offenders — about 24×24 total. The `padding: 4` around a 16px icon gave no real tap area. Wrapped in 44×44 minimum hit area in both platforms.

5. **No visual changes observed**: After all modifications, hot-reloaded both apps and visually confirmed: no layout shifts, no spacing changes, no visible differences. The buttons look exactly the same — only the invisible hit test area expanded.

## Flutter vs Expo Comparison

| Aspect | Flutter | Expo |
|--------|---------|------|
| Hit area expansion | `SizedBox(44,44)` + `Center` wrapper | `hitSlop` prop + `minWidth/minHeight` style |
| Default IconButton | 48×48 built-in | No equivalent — must add manually |
| `GestureDetector` | No hitSlop — requires wrapper | `TouchableOpacity` has native hitSlop |
| Hit test behavior | `HitTestBehavior.opaque` needed | Handled by hitSlop automatically |
| Code verbosity | More wrappers (SizedBox/Center) | Simpler (one-line hitSlop prop) |

**Key observation**: Expo's `hitSlop` is more concise and elegant for this use case. Flutter requires explicit wrapper widgets which add nesting depth. However, Flutter's `IconButton` provides 48×48 by default, which is arguably better default behavior.

## Parity Status
- Flutter ✅
- Expo ✅

## Next Step Plan
Step 6.0.2 or further interaction improvements as specified by the user.
