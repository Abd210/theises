import AsyncStorage from '@react-native-async-storage/async-storage';
import { loadSavedLocation } from './locationService';

const BASE_URL = 'https://api.aladhan.com/v1/timings';
const CACHE_KEY = 'cached_prayer_json';
const CACHE_DATE_KEY = 'cached_prayer_date';

function formatDateDD(date) {
    const d = date.getDate().toString().padStart(2, '0');
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const y = date.getFullYear();
    return `${d}-${m}-${y}`;
}

/**
 * Sanity check: Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha.
 * Returns true if order is valid.
 */
function sanityCheck(timings) {
    if (!timings) return false;
    const order = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    let prev = -1;
    for (const name of order) {
        const raw = (timings[name] || '').replace(/\s*\(.*\)/, '').trim();
        const parts = raw.split(':');
        if (parts.length < 2) return false;
        const mins = (parseInt(parts[0], 10) || 0) * 60 + (parseInt(parts[1], 10) || 0);
        if (mins <= prev) return false;
        prev = mins;
    }
    return true;
}

export async function fetchPrayerTimes({ methodId, school }) {
    // Read detected/persisted location
    const loc = await loadSavedLocation();
    const lat = loc.lat;
    const lng = loc.lon;

    const now = new Date();
    const dateStr = formatDateDD(now);

    // Cache key includes coords so changing location forces re-fetch
    const cacheTag = `${dateStr}_${lat.toFixed(2)}_${lng.toFixed(2)}_${methodId}_${school}`;

    // Try cache first
    try {
        const cachedDate = await AsyncStorage.getItem(CACHE_DATE_KEY);
        if (cachedDate === cacheTag) {
            const cached = await AsyncStorage.getItem(CACHE_KEY);
            if (cached) return { json: JSON.parse(cached), offlineCached: false };
        }
    } catch (e) {
        // Ignore cache errors
    }

    // Fetch from API — NO timezonestring; let API auto-detect from lat/lon
    const url = `${BASE_URL}/${dateStr}?latitude=${lat}&longitude=${lng}&method=${methodId}&school=${school}`;

    if (__DEV__) {
        console.log('[PrayerAPI] URL:', url);
    }

    let response;
    try {
        response = await fetch(url);
    } catch (e) {
        if (__DEV__) {
            console.log(`[PrayerAPI] Request failed: url=${url} error=${e?.message || e}`);
        }
        try {
            const cached = await AsyncStorage.getItem(CACHE_KEY);
            if (cached) return { json: JSON.parse(cached), offlineCached: true };
        } catch (_) {
            // Ignore
        }
        throw new Error('Could not load prayer times. Check internet and retry.');
    }

    if (response.ok) {
        const json = await response.json();
        const timings = json.data?.timings;
        const metaTz = json.data?.meta?.timezone;
        if (__DEV__) {
            console.log(`[PrayerAPI] meta.timezone=${metaTz}`);
            console.log(`[PrayerAPI] Fajr=${timings?.Fajr} Sunrise=${timings?.Sunrise} Dhuhr=${timings?.Dhuhr} Asr=${timings?.Asr} Maghrib=${timings?.Maghrib} Isha=${timings?.Isha}`);
        }

        // Sanity check
        if (!sanityCheck(timings)) {
            console.warn('[PrayerAPI] ⚠️ SANITY CHECK FAILED — timings not in expected order');
            console.warn(`[PrayerAPI] meta.timezone=${metaTz} lat=${lat} lon=${lng}`);
            throw new Error('Invalid timing data — prayer order check failed');
        }

        // Cache it
        try {
            await AsyncStorage.setItem(CACHE_KEY, JSON.stringify(json));
            await AsyncStorage.setItem(CACHE_DATE_KEY, cacheTag);
        } catch (e) {
            // Ignore cache errors
        }
        return { json, offlineCached: false };
    } else {
        if (__DEV__) {
            console.log(`[PrayerAPI] Request failed: url=${url} status=${response.status}`);
        }
        // Fallback to cache
        try {
            const cached = await AsyncStorage.getItem(CACHE_KEY);
            if (cached) return { json: JSON.parse(cached), offlineCached: true };
        } catch (e) {
            // Ignore
        }
        throw new Error('Could not load prayer times. Check internet and retry.');
    }
}
