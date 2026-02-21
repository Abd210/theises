import AsyncStorage from '@react-native-async-storage/async-storage';

const KEYS = {
    methodId: 'prayer_method_id',
    school: 'prayer_school',
    methodMode: 'prayer_method_mode',
    offsetPrefix: 'prayer_offset_',
};

export const DEFAULT_METHOD_ID = 3; // MWL
export const DEFAULT_SCHOOL = 0;    // Shafi
export const DEFAULT_METHOD_MODE = 'auto';

export const OFFSET_PRAYERS = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

export const METHOD_OPTIONS = [
    { id: 3, label: 'Muslim World League' },
    { id: 2, label: 'ISNA' },
    { id: 4, label: 'Umm al-Qura' },
    { id: 5, label: 'Egyptian General Authority' },
    { id: 1, label: 'Univ. of Islamic Sciences, Karachi' },
    { id: 7, label: 'Inst. of Geophysics, Univ. of Tehran' },
    { id: 13, label: 'Diyanet İşleri Başkanlığı, Turkey' },
    { id: 15, label: 'Moonsighting Committee' },
];

export const SCHOOL_OPTIONS = [
    { id: 0, label: 'Shafi (Standard)' },
    { id: 1, label: 'Hanafi' },
];

export function methodLabel(id) {
    const opt = METHOD_OPTIONS.find((o) => o.id === id);
    return opt ? opt.label : METHOD_OPTIONS[0].label;
}

export function schoolLabel(id) {
    const opt = SCHOOL_OPTIONS.find((o) => o.id === id);
    return opt ? opt.label : SCHOOL_OPTIONS[0].label;
}

/** Pick the best calculation method based on detected country. */
export function autoMethodForCountry(country) {
    const c = (country || '').toLowerCase().trim();
    if (c === 'united states' || c === 'us' || c === 'usa' ||
        c === 'canada' || c === 'ca') return 15;
    if (c === 'turkey' || c === 'türkiye' || c === 'tr') return 13;
    if (c === 'pakistan' || c === 'pk') return 1;
    if (c === 'iran' || c === 'ir') return 7;
    if (c === 'saudi arabia' || c === 'sa') return 4;
    if (c === 'egypt' || c === 'eg') return 5;
    return 3; // MWL
}

export async function loadPrayerSettings() {
    try {
        const m = await AsyncStorage.getItem(KEYS.methodId);
        const s = await AsyncStorage.getItem(KEYS.school);
        const mode = await AsyncStorage.getItem(KEYS.methodMode);
        return {
            methodId: m !== null ? parseInt(m, 10) : DEFAULT_METHOD_ID,
            school: s !== null ? parseInt(s, 10) : DEFAULT_SCHOOL,
            methodMode: mode || DEFAULT_METHOD_MODE,
        };
    } catch (_) {
        return { methodId: DEFAULT_METHOD_ID, school: DEFAULT_SCHOOL, methodMode: DEFAULT_METHOD_MODE };
    }
}

export async function loadOffsets() {
    const offsets = {};
    try {
        for (const prayer of OFFSET_PRAYERS) {
            const val = await AsyncStorage.getItem(KEYS.offsetPrefix + prayer);
            offsets[prayer] = val !== null ? parseInt(val, 10) : 0;
        }
    } catch (_) {
        for (const prayer of OFFSET_PRAYERS) {
            offsets[prayer] = 0;
        }
    }
    return offsets;
}

export async function setOffset(prayer, minutes) {
    const clamped = Math.max(-30, Math.min(30, minutes));
    await AsyncStorage.setItem(KEYS.offsetPrefix + prayer, String(clamped));
    console.log(`[PrayerSettings] offset ${prayer} set to ${clamped}`);
}

export async function setMethodId(id) {
    await AsyncStorage.setItem(KEYS.methodId, String(id));
    console.log(`[PrayerSettings] methodId set to ${id}`);
}

export async function setSchool(id) {
    await AsyncStorage.setItem(KEYS.school, String(id));
    console.log(`[PrayerSettings] school set to ${id}`);
}

export async function setMethodMode(mode) {
    await AsyncStorage.setItem(KEYS.methodMode, mode);
    console.log(`[PrayerSettings] methodMode set to ${mode}`);
}
