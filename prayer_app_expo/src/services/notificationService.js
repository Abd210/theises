import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Configure how notifications appear when app is in foreground
Notifications.setNotificationHandler({
    handleNotification: async () => ({
        shouldShowAlert: true,
        shouldPlaySound: true,
        shouldSetBadge: false,
    }),
});

const CHANNEL_ID = 'prayer_times';
const CACHE_KEY = 'salah_notif_cache';
const LAST_SCHEDULED_KEY = 'notif_last_scheduled';
let initialized = false;

// Debounce + single-flight state
let _debounceTimer = null;
let _inFlight = false;
let _pendingReason = null;

/** Initialize notification channel (Android) */
async function init() {
    if (initialized) return;

    if (Platform.OS === 'android') {
        await Notifications.setNotificationChannelAsync(CHANNEL_ID, {
            name: 'Prayer Times',
            description: 'Notifications for prayer times',
            importance: Notifications.AndroidImportance.HIGH,
            sound: 'default',
        });
    }

    initialized = true;
    console.log('[NOTIF] initialized');
}

/** Request permission. Returns true if granted. */
async function requestPermission() {
    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    if (existingStatus === 'granted') {
        console.log('[NOTIF] permission granted');
        return true;
    }

    const { status } = await Notifications.requestPermissionsAsync({
        ios: { allowAlert: true, allowSound: true, allowBadge: true },
    });
    const granted = status === 'granted';
    console.log(`[NOTIF] permission ${granted ? 'granted' : 'denied'}`);
    return granted;
}

/** Send a test notification immediately */
async function sendTestNow() {
    await init();
    await Notifications.scheduleNotificationAsync({
        content: {
            title: 'Test Notification',
            body: 'Notifications are working ✅',
            sound: 'default',
            ...(Platform.OS === 'android' ? { channelId: CHANNEL_ID } : {}),
        },
        trigger: null,
    });
    console.log('[NOTIF] sent test now');
}

/** Schedule a test notification in 10 seconds */
async function scheduleTestIn10s() {
    await init();
    await Notifications.scheduleNotificationAsync({
        content: {
            title: 'Test Notification',
            body: 'Notifications are working ✅',
            sound: 'default',
            ...(Platform.OS === 'android' ? { channelId: CHANNEL_ID } : {}),
        },
        trigger: {
            type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
            seconds: 10,
        },
    });
    console.log('[NOTIF] scheduled test in 10s');
}

/** Cache week timings for notification scheduling */
async function cacheTimingsForNotifications(serialized) {
    try {
        await AsyncStorage.setItem(CACHE_KEY, JSON.stringify(serialized));
        console.log(`[NOTIF] cached timings (${Object.keys(serialized).length} days)`);
    } catch (_) { /* skip */ }
}

/** Load cached timings */
async function _loadCachedTimings() {
    try {
        const raw = await AsyncStorage.getItem(CACHE_KEY);
        return raw ? JSON.parse(raw) : null;
    } catch (_) {
        return null;
    }
}

/**
 * Central entry point for (re)scheduling prayer notifications.
 * Debounced (300ms) + single-flight guard so multiple rapid calls collapse into one.
 * @param {string} reason - why this reschedule was triggered (for logging)
 */
function scheduleFromCache(reason = 'unknown') {
    // If already debouncing, update the reason and reset timer
    if (_debounceTimer) {
        clearTimeout(_debounceTimer);
        console.log(`[NOTIF] reschedule debounced (reason=${reason})`);
    }
    _pendingReason = reason;

    _debounceTimer = setTimeout(async () => {
        _debounceTimer = null;
        await _executeSchedule(_pendingReason);
    }, 300);
}

/** Actually execute the scheduling (called after debounce) */
async function _executeSchedule(reason) {
    // Single-flight: if already running, skip
    if (_inFlight) {
        console.log(`[NOTIF] schedule already in-flight, skipping (reason=${reason})`);
        return;
    }
    _inFlight = true;

    try {
        await init();

        // Load notification settings
        const enabledRaw = await AsyncStorage.getItem('notif_enabled');
        const enabled = enabledRaw === 'true';
        if (!enabled) {
            console.log(`[NOTIF] master toggle OFF, skipping schedule (reason=${reason})`);
            return;
        }

        const leadRaw = await AsyncStorage.getItem('notif_lead_minutes');
        const leadMinutes = leadRaw ? parseInt(leadRaw, 10) : 0;

        const enabledPrayers = {};
        for (const name of ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
            const val = await AsyncStorage.getItem(`notif_prayer_${name.toLowerCase()}`);
            enabledPrayers[name] = val === null ? true : val === 'true';
        }

        const cached = await _loadCachedTimings();
        if (!cached) {
            console.log(`[NOTIF] no cached timings, skipping (reason=${reason})`);
            return;
        }

        console.log(`[NOTIF] reschedule reason=${reason}`);
        await _scheduleFromParsed({ parsedTimings: cached, enabledPrayers, leadMinutes });
    } catch (e) {
        console.log('[NOTIF] scheduleFromCache error:', e);
    } finally {
        _inFlight = false;
    }
}

/** Internal: schedule from parsed timing data.
 *  Policy: schedule ALL enabled prayers within a rolling 48h window. */
async function _scheduleFromParsed({ parsedTimings, enabledPrayers, leadMinutes }) {
    await init();

    // Cancel only prayer notifications (identifiers starting with 'prayer_')
    const allScheduled = await Notifications.getAllScheduledNotificationsAsync();
    const prayerIds = allScheduled.filter(n => n.identifier?.startsWith('prayer_')).map(n => n.identifier);
    for (const id of prayerIds) {
        await Notifications.cancelScheduledNotificationAsync(id);
    }
    console.log(`[NOTIF] cancelled ${prayerIds.length} prayer notifications`);

    const now = new Date();
    const windowStartMs = now.getTime() + 5000; // now + 5s
    const windowEndMs = now.getTime() + 48 * 60 * 60 * 1000; // now + 48h
    const windowStart = new Date(windowStartMs);
    const windowEnd = new Date(windowEndMs);

    const offsetH = -(now.getTimezoneOffset() / 60);
    const offsetSign = offsetH >= 0 ? '+' : '';
    console.log(`[NOTIF] windowStart=${_fmtDt(windowStart)} windowEnd=${_fmtDt(windowEnd)} (${offsetSign}${offsetH}00)`);

    const scheduledMap = {};
    let scheduledCount = 0;

    // Collect all candidate triggers
    const candidates = [];

    for (const [dateKey, dayData] of Object.entries(parsedTimings)) {
        if (!dayData) continue;
        const prayers = dayData.prayers || [];

        for (const prayer of prayers) {
            const name = prayer.name;
            const time24 = prayer.time24;
            if (!enabledPrayers[name]) continue;

            // Parse time24 (HH:mm)
            const timeParts = time24?.split(':');
            if (!timeParts || timeParts.length < 2) continue;
            const hour = parseInt(timeParts[0], 10);
            const min = parseInt(timeParts[1], 10);

            // Parse dateKey (YYYY-MM-DD)
            const dateParts = dateKey.split('-');
            if (dateParts.length < 3) continue;
            const year = parseInt(dateParts[0], 10);
            const month = parseInt(dateParts[1], 10) - 1;
            const day = parseInt(dateParts[2], 10);

            const triggerTime = new Date(year, month, day, hour, min, 0);
            triggerTime.setMinutes(triggerTime.getMinutes() - leadMinutes);

            // Filter: must be within [windowStart, windowEnd]
            if (triggerTime.getTime() < windowStartMs) continue;
            if (triggerTime.getTime() > windowEndMs) continue;

            candidates.push({ name, time24, triggerTime, dateKey });
        }
    }

    // Sort by trigger time for deterministic ordering
    candidates.sort((a, b) => a.triggerTime.getTime() - b.triggerTime.getTime());

    // Schedule each candidate
    for (const c of candidates) {
        const { name, time24, triggerTime, dateKey } = c;

        const time12 = formatTo12Hour(time24);
        let body;
        if (leadMinutes > 0) {
            body = `${name} in ${leadMinutes} min • Adhan at ${time12}`;
        } else {
            body = `Adhan at ${time12}`;
        }

        const identifier = `prayer_${dateKey}_${name}`;
        const triggerStr = _fmtDt(triggerTime);

        await Notifications.scheduleNotificationAsync({
            identifier,
            content: {
                title: `${name} Prayer`,
                body,
                sound: 'default',
                ...(Platform.OS === 'android' ? { channelId: CHANNEL_ID } : {}),
            },
            trigger: {
                type: Notifications.SchedulableTriggerInputTypes.DATE,
                date: triggerTime,
            },
        });

        console.log(`[NOTIF] id=${identifier} prayer=${name} trigger=${triggerStr} (${offsetSign}${offsetH}00)`);

        scheduledMap[identifier] = {
            prayer: name,
            trigger: triggerStr,
            body,
            dateKey,
        };
        scheduledCount++;
    }

    // Persist for debug display
    try {
        await AsyncStorage.setItem(LAST_SCHEDULED_KEY, JSON.stringify(scheduledMap));
    } catch (_) { /* skip */ }

    console.log(`[NOTIF] scheduledCount=${scheduledCount}`);
}

/** Format Date as YYYY-MM-DD HH:mm */
function _fmtDt(dt) {
    return `${dt.getFullYear()}-${String(dt.getMonth()+1).padStart(2,'0')}-${String(dt.getDate()).padStart(2,'0')} ${String(dt.getHours()).padStart(2,'0')}:${String(dt.getMinutes()).padStart(2,'0')}`;
}

/** Get pending prayer notifications for debug.
 *  Falls back to stored schedule map if Expo Go hides trigger details. */
async function getPendingPrayerNotifications() {
    await init();

    // Load stored schedule map as fallback
    let storedMap = {};
    try {
        const raw = await AsyncStorage.getItem(LAST_SCHEDULED_KEY);
        if (raw) storedMap = JSON.parse(raw);
    } catch (_) { /* skip */ }

    const all = await Notifications.getAllScheduledNotificationsAsync();
    const pendingIds = new Set(
        all.filter(n => n.identifier?.startsWith('prayer_')).map(n => n.identifier)
    );

    // Build result from stored map, filtered to still-pending
    const result = [];
    for (const [id, info] of Object.entries(storedMap)) {
        if (!pendingIds.has(id)) continue;
        result.push({
            id,
            prayer: info.prayer || '',
            trigger: info.trigger || 'unknown',
            body: info.body || '',
        });
    }

    // Sort by trigger for consistent ordering
    result.sort((a, b) => a.trigger.localeCompare(b.trigger));

    console.log(`[NOTIF-DEBUG] pending prayer notifications: ${result.length}`);
    for (const r of result) {
        console.log(`[NOTIF-DEBUG]   id=${r.id} prayer=${r.prayer} trigger=${r.trigger}`);
    }
    return result;
}

/** Schedule a pipeline test: fires in 60 seconds using real pipeline */
async function schedulePipelineTestIn60s() {
    await init();

    try {
        await Notifications.cancelScheduledNotificationAsync('pipeline_test');
    } catch (_) { /* may not exist */ }

    const fireAt = new Date(Date.now() + 60 * 1000);

    await Notifications.scheduleNotificationAsync({
        identifier: 'pipeline_test',
        content: {
            title: 'Pipeline Test',
            body: 'Prayer notification pipeline works \u2705 (scheduled 60s ago)',
            sound: 'default',
            ...(Platform.OS === 'android' ? { channelId: CHANNEL_ID } : {}),
        },
        trigger: {
            type: Notifications.SchedulableTriggerInputTypes.DATE,
            date: fireAt,
        },
    });

    const offsetH = -(fireAt.getTimezoneOffset() / 60);
    const offsetSign = offsetH >= 0 ? '+' : '';
    const dateStr = `${fireAt.getFullYear()}-${String(fireAt.getMonth()+1).padStart(2,'0')}-${String(fireAt.getDate()).padStart(2,'0')} ${String(fireAt.getHours()).padStart(2,'0')}:${String(fireAt.getMinutes()).padStart(2,'0')}:${String(fireAt.getSeconds()).padStart(2,'0')}`;
    console.log(`[NOTIF] pipeline test scheduled at ${dateStr} (${offsetSign}${offsetH}00) id=pipeline_test`);
}

/** Cancel all scheduled notifications */
async function cancelAll() {
    await Notifications.cancelAllScheduledNotificationsAsync();
    console.log('[NOTIF] cancelled all');
}

/** Cancel only prayer notifications */
async function cancelPrayerNotifications() {
    const all = await Notifications.getAllScheduledNotificationsAsync();
    const prayerIds = all.filter(n => n.identifier?.startsWith('prayer_')).map(n => n.identifier);
    for (const id of prayerIds) {
        await Notifications.cancelScheduledNotificationAsync(id);
    }
    console.log(`[NOTIF] cancelled prayer notifications count=${prayerIds.length}`);
}

/** Helper: HH:mm -> h:mm AM/PM */
function formatTo12Hour(time24) {
    if (!time24) return '';
    const [h, m] = time24.split(':').map(Number);
    const ampm = h >= 12 ? 'PM' : 'AM';
    const hour12 = h % 12 || 12;
    return `${hour12}:${String(m).padStart(2, '0')} ${ampm}`;
}

export default {
    init,
    requestPermission,
    sendTestNow,
    scheduleTestIn10s,
    cacheTimingsForNotifications,
    scheduleFromCache,
    getPendingPrayerNotifications,
    schedulePipelineTestIn60s,
    cancelAll,
    cancelPrayerNotifications,
};
