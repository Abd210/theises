// ───────────────────────────────────────────────
// 4 THEMES — color tokens only, layout unchanged
// ───────────────────────────────────────────────

export const nightTheme = {
    id: 'night',
    name: 'Night',
    backgroundStart: '#0D0D0D',
    backgroundEnd: '#1A1A2E',
    card: 'rgba(255, 255, 255, 0.15)',
    cardBorder: 'rgba(255, 255, 255, 0.10)',
    modalBg: '#252538', // Blended solid dark
    textPrimary: '#FFFFFF',
    textMuted: '#9E9E9E',
    accent: '#D4A847',
    navBar: 'rgba(255, 255, 255, 0.20)',
    inactive: '#6B6B6B',
    iconButtonBg: 'rgba(255, 255, 255, 0.18)',
    brightness: 'dark',
};

export const forestTheme = {
    id: 'forest',
    name: 'Forest',
    backgroundStart: '#0A1A0A',
    backgroundEnd: '#1A2E1A',
    card: 'rgba(255, 255, 255, 0.15)',
    cardBorder: 'rgba(255, 255, 255, 0.10)',
    modalBg: '#253825', // Blended solid forest
    textPrimary: '#FFFFFF',
    textMuted: '#8FA88F',
    accent: '#4CAF50',
    navBar: 'rgba(255, 255, 255, 0.20)',
    inactive: '#5A6B5A',
    iconButtonBg: 'rgba(255, 255, 255, 0.18)',
    brightness: 'dark',
};

export const sandTheme = {
    id: 'sand',
    name: 'Sand',
    backgroundStart: '#F5F0E8',
    backgroundEnd: '#EDE4D3',
    card: 'rgba(0, 0, 0, 0.08)',
    cardBorder: 'rgba(0, 0, 0, 0.06)',
    modalBg: '#E4DBCA', // Blended solid sand
    textPrimary: '#1A1A1A',
    textMuted: '#7A7060',
    accent: '#C49A3C',
    navBar: 'rgba(0, 0, 0, 0.10)',
    inactive: '#A09080',
    iconButtonBg: 'rgba(0, 0, 0, 0.08)',
    brightness: 'light',
};

export const midnightBlueTheme = {
    id: 'midnight_blue',
    name: 'Midnight Blue',
    backgroundStart: '#0A0E1A',
    backgroundEnd: '#141E3C',
    card: 'rgba(255, 255, 255, 0.15)',
    cardBorder: 'rgba(255, 255, 255, 0.10)',
    modalBg: '#202A48', // Blended solid blue
    textPrimary: '#FFFFFF',
    textMuted: '#8E9EC0',
    accent: '#64B5F6',
    navBar: 'rgba(255, 255, 255, 0.20)',
    inactive: '#5A6B8B',
    iconButtonBg: 'rgba(255, 255, 255, 0.18)',
    brightness: 'dark',
};

/** All themes keyed by id */
export const appThemes = {
    night: nightTheme,
    forest: forestTheme,
    sand: sandTheme,
    midnight_blue: midnightBlueTheme,
};

/** Ordered list for UI display */
export const appThemeList = [
    nightTheme,
    forestTheme,
    sandTheme,
    midnightBlueTheme,
];
