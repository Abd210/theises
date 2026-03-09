import AsyncStorage from '@react-native-async-storage/async-storage';

const TTL_DAYS = 7;

/**
 * Build a config fingerprint for cache keying.
 * Rounds lat/lon to 4 decimals so minor GPS drift doesn't bust cache.
 */
function configPrefix(lat, lon, method, school) {
    const latR = (lat || 0).toFixed(4);
    const lonR = (lon || 0).toFixed(4);
    return `${latR}_${lonR}_m${method}_s${school}`;
}

function monthDataKey(year, month, cfgPrefix) {
    return `prayer_cal_${cfgPrefix}_${year}_${String(month).padStart(2, '0')}`;
}
function monthSavedKey(year, month, cfgPrefix) {
    return `prayer_cal_saved_${cfgPrefix}_${year}_${String(month).padStart(2, '0')}`;
}

/**
 * Save raw calendar API JSON for a given month + config.
 */
export async function saveMonth(year, month, jsonStr, cfgPrefix) {
    try {
        await AsyncStorage.setItem(monthDataKey(year, month, cfgPrefix), jsonStr);
        await AsyncStorage.setItem(monthSavedKey(year, month, cfgPrefix), new Date().toISOString());
        if (__DEV__) console.log(`[PRAYER_CACHE] saved month=${month} year=${year} cfg=${cfgPrefix}`);
    } catch (e) {
        // Ignore
    }
}

/**
 * Load cached calendar JSON for a given month + config, or null.
 */
export async function loadMonth(year, month, cfgPrefix) {
    try {
        return await AsyncStorage.getItem(monthDataKey(year, month, cfgPrefix));
    } catch (e) {
        return null;
    }
}

/**
 * Check if cached month is within 7-day TTL.
 */
export async function isMonthValid(year, month, cfgPrefix) {
    try {
        const savedStr = await AsyncStorage.getItem(monthSavedKey(year, month, cfgPrefix));
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

export { configPrefix };
