// theme.js — Non-color tokens that stay the same across all themes.
// Colors are now dynamic via ThemeProvider. Use useTheme() to get current colors.

// ───────────────────────────────────────────────
// SPACING (8-pt grid)
// ───────────────────────────────────────────────
export const Spacing = {
    s4: 4,
    s8: 8,
    s12: 12,
    s16: 16,
    s24: 24,
    s32: 32,
};

// ───────────────────────────────────────────────
// RADIUS
// ───────────────────────────────────────────────
export const Radius = {
    card: 24,
    pill: 999,
    button: 16,
};

// ───────────────────────────────────────────────
// SALAH LAYOUT  (pixel-perfect checklist tokens)
// Same across all themes — only colors change.
// ───────────────────────────────────────────────
export const SalahLayout = {
    // Screen
    screenPadding: 20,

    // Header
    headerMarginTop: 12,
    headerMarginBottom: 14,
    locationIconSize: 16,
    gearButtonSize: 36,
    gearIconSize: 18,

    // Date row
    dateRowMarginTop: 6,
    dateRowMarginBottom: 14,

    // Hero card
    heroMinHeight: 118,
    heroPadding: 16,
    heroRadius: 22,
    heroBorderWidth: 1,
    heroBorderOpacity: 0.7,
    heroMarginTop: 10,
    heroMarginBottom: 18,
    heroIconBoxSize: 56,
    heroIconBoxRadius: 16,
    heroIconSize: 26,
    heroIconTextGap: 14,
    heroLine1Size: 15,
    heroCountdownSize: 28,
    heroLine3Size: 12,

    // Schedule header
    scheduleMarginTop: 6,
    scheduleIconSize: 14,
    scheduleMarginBottom: 10,

    // Prayer rows
    rowHeight: 54,
    rowPaddingH: 12,
    rowRadius: 14,
    rowSpacing: 8,
    rowIconSize: 20,
    rowTextSize: 15,
    rowBorderWidth: 1,
    rowBorderOpacity: 0.7,

    // Divider
    dividerMarginTop: 10,

    // Bottom nav
    navHeight: 62,
    navRadius: 26,
    navInsetH: 14,
    navInsetBottom: 14,
    pillHeight: 36,
    pillPaddingH: 14,
    pillRadius: 18,
    pillIconSize: 16,
    pillTextSize: 14,
    navInactiveIconSize: 22,
};

// ───────────────────────────────────────────────
// PRAYER ICON MAPPING (unique icon per prayer)
// ───────────────────────────────────────────────
export const PrayerIcons = {
    Fajr: 'weather-sunset-up',
    Dhuhr: 'weather-sunny',
    Asr: 'weather-partly-cloudy',
    Maghrib: 'weather-sunset',
    Isha: 'weather-night',
    Sunrise: 'white-balance-sunny',
    'Last Third of Night': 'moon-waning-crescent',
};

export function getPrayerIcon(name) {
    return PrayerIcons[name] || 'clock-outline';
}

// ───────────────────────────────────────────────
// INTER FONT HELPER
// ───────────────────────────────────────────────
export function interFont(weight = '400') {
    const map = {
        '400': 'Inter_400Regular',
        '500': 'Inter_500Medium',
        '600': 'Inter_600SemiBold',
        '700': 'Inter_700Bold',
        '800': 'Inter_800ExtraBold',
    };
    return map[weight] || 'Inter_400Regular';
}

// ───────────────────────────────────────────────
// TYPOGRAPHY (functions that take theme colors)
// ───────────────────────────────────────────────
export function getTypography(tc) {
    return {
        titleLarge: {
            fontFamily: interFont('700'),
            fontSize: 28,
            color: tc.textPrimary,
        },
        titleMedium: {
            fontFamily: interFont('600'),
            fontSize: 20,
            color: tc.textPrimary,
        },
        body: {
            fontFamily: interFont('400'),
            fontSize: 16,
            color: tc.textPrimary,
        },
        caption: {
            fontFamily: interFont('400'),
            fontSize: 13,
            color: tc.textMuted,
        },
    };
}
