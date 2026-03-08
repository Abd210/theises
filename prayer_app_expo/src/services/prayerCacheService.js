import AsyncStorage from '@react-native-async-storage/async-storage';

const TTL_DAYS = 7;

function monthDataKey(year, month) {
    return `prayer_cal_${year}_${String(month).padStart(2, '0')}`;
}
function monthSavedKey(year, month) {
    return `prayer_cal_saved_${year}_${String(month).padStart(2, '0')}`;
}

/**
 * Save raw calendar API JSON for a given month.
 */
export async function saveMonth(year, month, jsonStr) {
    try {
        await AsyncStorage.setItem(monthDataKey(year, month), jsonStr);
        await AsyncStorage.setItem(monthSavedKey(year, month), new Date().toISOString());
        if (__DEV__) console.log(`[PRAYER_CACHE] saved month=${month} year=${year}`);
    } catch (e) {
        // Ignore
    }
}

/**
 * Load cached calendar JSON for a given month, or null.
 */
export async function loadMonth(year, month) {
    try {
        return await AsyncStorage.getItem(monthDataKey(year, month));
    } catch (e) {
        return null;
    }
}

/**
 * Check if cached month is within 7-day TTL.
 */
export async function isMonthValid(year, month) {
    try {
        const savedStr = await AsyncStorage.getItem(monthSavedKey(year, month));
        if (!savedStr) return false;
        const savedAt = new Date(savedStr);
        const diffDays = (Date.now() - savedAt.getTime()) / (1000 * 60 * 60 * 24);
        return diffDays < TTL_DAYS;
    } catch (e) {
        return false;
    }
}

/**
 * Extract a single day from a cached month JSON.
 * dayOfMonth is 1-based.
 */
export function extractDay(monthJson, dayOfMonth) {
    try {
        const body = JSON.parse(monthJson);
        const dataList = body?.data;
        if (!Array.isArray(dataList)) return null;
        const idx = dayOfMonth - 1;
        if (idx < 0 || idx >= dataList.length) return null;
        return dataList[idx];
    } catch (e) {
        return null;
    }
}
