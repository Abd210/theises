import AsyncStorage from '@react-native-async-storage/async-storage';

const BASE_URL = 'https://api.aladhan.com/v1/timings';
const LAT = 44.4268;
const LNG = 26.1025;
const METHOD = 2; // ISNA
const TIMEZONE = 'Europe/Bucharest';
const CACHE_KEY = 'cached_prayer_json';
const CACHE_DATE_KEY = 'cached_prayer_date';

function formatDateDD(date) {
    const d = date.getDate().toString().padStart(2, '0');
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const y = date.getFullYear();
    return `${d}-${m}-${y}`;
}

export async function fetchPrayerTimes() {
    const now = new Date();
    const dateStr = formatDateDD(now);

    // Try cache first
    try {
        const cachedDate = await AsyncStorage.getItem(CACHE_DATE_KEY);
        if (cachedDate === dateStr) {
            const cached = await AsyncStorage.getItem(CACHE_KEY);
            if (cached) return JSON.parse(cached);
        }
    } catch (e) {
        // Ignore cache errors
    }

    // Fetch from API
    const url = `${BASE_URL}/${dateStr}?latitude=${LAT}&longitude=${LNG}&method=${METHOD}&timezonestring=${TIMEZONE}`;
    const response = await fetch(url);

    if (response.ok) {
        const json = await response.json();
        // Cache it
        try {
            await AsyncStorage.setItem(CACHE_KEY, JSON.stringify(json));
            await AsyncStorage.setItem(CACHE_DATE_KEY, dateStr);
        } catch (e) {
            // Ignore cache errors
        }
        return json;
    } else {
        // Fallback to cache
        try {
            const cached = await AsyncStorage.getItem(CACHE_KEY);
            if (cached) return JSON.parse(cached);
        } catch (e) {
            // Ignore
        }
        throw new Error(`Failed to load prayer times (${response.status})`);
    }
}
