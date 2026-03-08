import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';

// Configure how notifications appear when app is in foreground
Notifications.setNotificationHandler({
    handleNotification: async () => ({
        shouldShowAlert: true,
        shouldPlaySound: true,
        shouldSetBadge: false,
    }),
});

const CHANNEL_ID = 'prayer_times';
let initialized = false;

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
        trigger: null, // null = immediate
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

/**
 * Schedule prayer notifications for upcoming prayers.
 * @param {Object} weekTimings - dateKey -> timings object
 * @param {string} city - city name for body
 * @param {Object} enabledPrayers - { Fajr: true, Dhuhr: true, ... }
 * @param {number} leadMinutes - minutes before adhan
 */
async function scheduleAllPrayers({ weekTimings, city, enabledPrayers, leadMinutes }) {
    await init();

    // Cancel all previously scheduled prayer notifications
    const allScheduled = await Notifications.getAllScheduledNotificationsAsync();
    let cancelCount = 0;
    for (const n of allScheduled) {
        // Keep test notifications (identifiers that don't start with 'prayer_')
        if (n.identifier && n.identifier.startsWith('prayer_')) {
            await Notifications.cancelScheduledNotificationAsync(n.identifier);
            cancelCount++;
        }
    }
    console.log(`[NOTIF] cancelled previous scheduled notifications count=${cancelCount}`);

    const now = new Date();

    for (const [dateKey, t] of Object.entries(weekTimings)) {
        if (!t) continue;
        const prayers = t.mainPrayers || [];

        for (const prayer of prayers) {
            const name = prayer.name;
            if (!enabledPrayers[name]) continue;

            // Parse time24 (HH:mm or H:mm)
            const timeParts = prayer.time24?.split(':');
            if (!timeParts || timeParts.length < 2) continue;
            const hour = parseInt(timeParts[0], 10);
            const min = parseInt(timeParts[1], 10);

            // Parse dateKey (YYYY-MM-DD)
            const dateParts = dateKey.split('-');
            if (dateParts.length < 3) continue;
            const year = parseInt(dateParts[0], 10);
            const month = parseInt(dateParts[1], 10) - 1; // JS months are 0-indexed
            const day = parseInt(dateParts[2], 10);

            const scheduledTime = new Date(year, month, day, hour, min, 0);
            scheduledTime.setMinutes(scheduledTime.getMinutes() - leadMinutes);

            // Skip past times
            if (scheduledTime <= now) continue;

            const diffMs = scheduledTime.getTime() - now.getTime();
            const diffSeconds = Math.ceil(diffMs / 1000);

            let body;
            const time12 = formatTo12Hour(prayer.time24);
            if (leadMinutes > 0) {
                body = `${name} in ${leadMinutes} min • Adhan at ${time12} • ${city}`;
            } else {
                body = `Adhan at ${time12} • ${city}`;
            }

            const identifier = `prayer_${dateKey}_${name}`;
            await Notifications.scheduleNotificationAsync({
                identifier,
                content: {
                    title: `${name} Prayer`,
                    body,
                    sound: 'default',
                    ...(Platform.OS === 'android' ? { channelId: CHANNEL_ID } : {}),
                },
                trigger: {
                    type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
                    seconds: diffSeconds,
                },
            });
            console.log(`[NOTIF] scheduled ${name} at ${scheduledTime.toISOString()} id=${identifier}`);
        }
    }
}

/** Cancel all scheduled notifications */
async function cancelAll() {
    await Notifications.cancelAllScheduledNotificationsAsync();
    console.log('[NOTIF] cancelled all');
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
    scheduleAllPrayers,
    cancelAll,
};
