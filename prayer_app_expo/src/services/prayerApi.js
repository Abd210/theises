import { loadSavedLocation } from './locationService';
import { saveMonth, loadMonth, isMonthValid, extractDay } from './prayerCacheService';

const CALENDAR_URL = 'https://api.aladhan.com/v1/calendar';

/**
 * Clean timezone suffix from API time strings like "05:43 (EET)"
 */
export function cleanTime(raw) {
    if (!raw) return '00:00';
    return raw.replace(/\s*\(.*\)/, '').trim();
}

/**
 * Sanity check: Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha.
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

/**
 * Date key format: YYYY-MM-DD
 */
export function dateKey(d) {
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
}

/**
 * Parse a single day entry from the calendar API into a timings object.
 */
export function parseDayTimings(dayData) {
    const timings = dayData.timings;
    const hijri = dayData.date?.hijri;
    const greg = dayData.date?.gregorian;

    let gregFormatted = '';
    if (greg) {
        gregFormatted = `${greg.weekday?.en || ''}, ${greg.month?.en || ''} ${greg.day || ''}, ${greg.year || ''}`;
    }

    const hijriDay = hijri?.day || '';
    const hijriMonthAr = hijri?.month?.ar || '';
    const hijriYear = hijri?.year || '';
    const hijriFormatted = hijriDay
        ? `\u200E${hijriDay} ${hijriMonthAr} ${hijriYear} \u0647\u0640`
        : '—';

    const mainPrayers = [
        { name: 'Fajr', time24: cleanTime(timings.Fajr) },
        { name: 'Dhuhr', time24: cleanTime(timings.Dhuhr) },
        { name: 'Asr', time24: cleanTime(timings.Asr) },
        { name: 'Maghrib', time24: cleanTime(timings.Maghrib) },
        { name: 'Isha', time24: cleanTime(timings.Isha) },
    ];

    const supplementary = [
        { name: 'Sunrise', time24: cleanTime(timings.Sunrise) },
        { name: 'Last Third of Night', time24: cleanTime(timings.Lastthird) },
    ];

    return { mainPrayers, supplementary, gregFormatted, hijriFormatted };
}

/**
 * Fetch prayer times for 7 days (today..today+6).
 * Uses the monthly calendar endpoint and caches full months.
 */
export async function fetchWeekPrayerTimes({ methodId, school }) {
    const loc = await loadSavedLocation();
    const lat = loc.lat;
    const lng = loc.lon;
    const now = new Date();

    // Determine which months we need (today..today+6 might span 2 months)
    const dates = [];
    for (let i = 0; i < 7; i++) {
        const d = new Date(now);
        d.setDate(d.getDate() + i);
        dates.push(d);
    }

    const monthsNeeded = new Set();
    for (const d of dates) {
        monthsNeeded.add(`${d.getFullYear()}-${d.getMonth() + 1}`);
    }

    let anyNetworkFail = false;
    const monthJsons = {};

    // Fetch/load each needed month
    for (const key of monthsNeeded) {
        const [yearStr, monthStr] = key.split('-');
        const year = parseInt(yearStr, 10);
        const month = parseInt(monthStr, 10);

        // Check cache validity
        const valid = await isMonthValid(year, month);
        if (valid) {
            const cached = await loadMonth(year, month);
            if (cached) {
                monthJsons[key] = cached;
                if (__DEV__) console.log(`[PRAYER_CACHE] hit month=${month} year=${year}`);
                continue;
            }
        }

        // Fetch from API
        const url = `${CALENDAR_URL}?latitude=${lat}&longitude=${lng}&method=${methodId}&school=${school}&month=${month}&year=${year}`;

        if (__DEV__) console.log(`[PRAYER_CACHE] miss month=${month} year=${year}`);
        if (__DEV__) console.log(`[PrayerAPI] calendar URL: ${url}`);

        try {
            const response = await fetch(url);
            if (response.ok) {
                const text = await response.text();
                monthJsons[key] = text;
                await saveMonth(year, month, text);
            } else {
                anyNetworkFail = true;
                if (__DEV__) console.log(`[PrayerAPI] calendar failed status=${response.status}`);
                const stale = await loadMonth(year, month);
                if (stale) monthJsons[key] = stale;
            }
        } catch (e) {
            anyNetworkFail = true;
            if (__DEV__) console.log(`[PrayerAPI] calendar fetch error: ${e?.message || e}`);
            const stale = await loadMonth(year, month);
            if (stale) monthJsons[key] = stale;
        }
    }

    // Build 7-day map
    const weekMap = {};
    for (const d of dates) {
        const mKey = `${d.getFullYear()}-${d.getMonth() + 1}`;
        const monthJson = monthJsons[mKey];
        if (!monthJson) continue;

        const dayData = extractDay(monthJson, d.getDate());
        if (!dayData) continue;

        try {
            // Sanity check raw timings
            if (!sanityCheck(dayData.timings)) {
                if (__DEV__) console.log(`[PrayerAPI] ⚠️ sanity check failed for ${dateKey(d)}`);
                continue;
            }
            weekMap[dateKey(d)] = parseDayTimings(dayData);
        } catch (e) {
            if (__DEV__) console.log(`[PrayerAPI] parse error for ${dateKey(d)}: ${e?.message || e}`);
        }
    }

    if (Object.keys(weekMap).length === 0) {
        throw new Error('Could not load prayer times for any day. Check internet and retry.');
    }

    return {
        week: weekMap,
        offlineCached: anyNetworkFail && Object.keys(weekMap).length > 0,
    };
}
