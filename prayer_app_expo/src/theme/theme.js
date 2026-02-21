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
// QIBLA LAYOUT  (pixel-perfect checklist tokens)
// ───────────────────────────────────────────────
export const QiblaLayout = {
    screenPadding: 20,
    titleMarginTop: 12,

    // City row
    cityIconSize: 16,
    cityFontSize: 13,

    // Big degree
    degreeFontSize: 48,
    degreeSubtitleSize: 13,

    // Compass
    compassSize: 260,
    compassStroke: 2,
    tickLength: 10,
    tickLengthMajor: 16,
    cardinalFontSize: 14,
    needleWidth: 3,
    centerDotRadius: 5,
    kaabaIconSize: 22,
    pointerSize: 10,

    // Status text
    statusFontSize: 14,

    // Kaaba card
    cardPadding: 16,
    cardRadius: 18,
    arabicFontSize: 22,
    translitFontSize: 13,
};

// ───────────────────────────────────────────────
// AZKAR LAYOUT  (pixel-perfect checklist tokens)
// ───────────────────────────────────────────────
export const AzkarLayout = {
    screenPadding: 20,
    titleMarginTop: 12,
    subtitleSize: 13,
    topHeaderGap: 12,

    // Search bar
    searchHeight: 44,
    searchRadius: 14,
    searchIconSize: 20,
    searchFontSize: 14,

    // Grid
    gridSpacing: 12,
    gridCardRadius: 18,
    gridCardPadding: 14,
    gridIconSize: 28,
    gridTitleSize: 14,
    gridSubtitleSize: 11,
    gridArrowSize: 16,

    // Detail screen — card
    detailCardRadius: 22,
    detailCardBorderWidth: 1,
    detailCardBorderOpacity: 0.7,
    detailCardPadding: 16,
    detailArabicSize: 22,
    detailTranslationSize: 13,

    // Detail screen — pager
    cardsPagerHeightFactor: 0.62,

    // Detail screen — counter footer
    detailCounterSize: 18,
    detailCounterBtnSize: 44,
    footerHeight: 72,
    footerBottomInset: 14,

    // Detail screen — list
    listCardMinHeight: 140,
    listCardPadding: 16,
    listCardSpacing: 12,

    // Segmented control
    segmentHeight: 40,
    segmentRadius: 12,
    segmentFontSize: 13,
};

// ───────────────────────────────────────────────
// QURAN LAYOUT  (Step 5 parity tokens)
// ───────────────────────────────────────────────
export const QuranLayout = {
    screenPadding: 20,
    titleMarginTop: 12,
    subtitleSize: 13,
    sectionTitleSize: 16,
    sectionGap: 12,
    cardRadius: 22,
    cardPadding: 14,
    rowHeight: 56,
    searchHeight: 44,
    pillRadius: 14,
    searchRadius: 14,
    surahRowHeight: 56,
    ayahArabicSize: 28,
    ayahTranslationSize: 14,
    ayahItemPadding: 16,
    ayahItemGap: 10,
    juzButtonSize: 40,
    juzChipWidth: 78,
    juzChipGap: 8,
    topActionIconSize: 20,
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
