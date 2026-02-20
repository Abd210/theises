import AsyncStorage from '@react-native-async-storage/async-storage';

const KEYS = {
    methodId: 'prayer_method_id',
    school: 'prayer_school',
    offsetPrefix: 'prayer_offset_',
};

export const DEFAULT_METHOD_ID = 3; // MWL
export const DEFAULT_SCHOOL = 0;    // Shafi

export const OFFSET_PRAYERS = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

export const METHOD_OPTIONS = [
    { id: 2, label: 'ISNA' },
    { id: 3, label: 'Muslim World League' },
    { id: 4, label: 'Umm al-Qura' },
    { id: 5, label: 'Egyptian General Authority' },
];

export const SCHOOL_OPTIONS = [
    { id: 0, label: 'Shafi (Standard)' },
    { id: 1, label: 'Hanafi' },
];

export function methodLabel(id) {
    const opt = METHOD_OPTIONS.find((o) => o.id === id);
    return opt ? opt.label : METHOD_OPTIONS[1].label;
}

export function schoolLabel(id) {
    const opt = SCHOOL_OPTIONS.find((o) => o.id === id);
    return opt ? opt.label : SCHOOL_OPTIONS[0].label;
}

export async function loadPrayerSettings() {
    try {
        const m = await AsyncStorage.getItem(KEYS.methodId);
        const s = await AsyncStorage.getItem(KEYS.school);
        return {
            methodId: m !== null ? parseInt(m, 10) : DEFAULT_METHOD_ID,
            school: s !== null ? parseInt(s, 10) : DEFAULT_SCHOOL,
        };
    } catch (_) {
        return { methodId: DEFAULT_METHOD_ID, school: DEFAULT_SCHOOL };
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
