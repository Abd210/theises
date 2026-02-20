import * as Location from 'expo-location';
import AsyncStorage from '@react-native-async-storage/async-storage';

const KEYS = {
    lat: 'loc_lat',
    lon: 'loc_lon',
    city: 'loc_city',
    country: 'loc_country',
    timezone: 'loc_timezone',
    source: 'loc_source',
};

export const FALLBACK_LOCATION = {
    lat: 44.4268,
    lon: 26.1025,
    city: 'Bucharest',
    country: 'Romania',
    timezone: 'Europe/Bucharest',
    source: 'default',
};

/** Load previously persisted location, or return fallback. */
export async function loadSavedLocation() {
    try {
        const source = await AsyncStorage.getItem(KEYS.source);
        if (!source) return { ...FALLBACK_LOCATION };
        const lat = parseFloat(await AsyncStorage.getItem(KEYS.lat)) || FALLBACK_LOCATION.lat;
        const lon = parseFloat(await AsyncStorage.getItem(KEYS.lon)) || FALLBACK_LOCATION.lon;
        const city = (await AsyncStorage.getItem(KEYS.city)) || 'Unknown';
        const country = (await AsyncStorage.getItem(KEYS.country)) || '';
        const timezone = (await AsyncStorage.getItem(KEYS.timezone)) || FALLBACK_LOCATION.timezone;
        return { lat, lon, city, country, timezone, source };
    } catch (_) {
        return { ...FALLBACK_LOCATION };
    }
}

/** Request permission, get coords, reverse geocode, persist. */
export async function detectLocation() {
    // 1. Request permission
    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== 'granted') {
        await persistLocation(FALLBACK_LOCATION);
        return { ...FALLBACK_LOCATION };
    }

    // 2. Get coordinates
    let coords;
    try {
        const pos = await Location.getCurrentPositionAsync({
            accuracy: Location.Accuracy.Low,
        });
        coords = { lat: pos.coords.latitude, lon: pos.coords.longitude };
    } catch (_) {
        await persistLocation(FALLBACK_LOCATION);
        return { ...FALLBACK_LOCATION };
    }

    // 3. Reverse geocode
    let city = 'Unknown';
    let country = '';
    try {
        const results = await Location.reverseGeocodeAsync({
            latitude: coords.lat,
            longitude: coords.lon,
        });
        if (results.length > 0) {
            const r = results[0];
            city = r.city || r.subregion || r.region || 'Unknown';
            country = r.country || '';
        }
    } catch (_) {
        // Keep city = 'Unknown'
    }

    // 4. Timezone — use device's IANA timezone
    const deviceTz = Intl.DateTimeFormat().resolvedOptions().timeZone || FALLBACK_LOCATION.timezone;

    const data = {
        lat: coords.lat,
        lon: coords.lon,
        city,
        country,
        timezone: deviceTz,
        source: 'gps',
    };

    await persistLocation(data);
    return data;
}

async function persistLocation(d) {
    try {
        await AsyncStorage.setItem(KEYS.lat, String(d.lat));
        await AsyncStorage.setItem(KEYS.lon, String(d.lon));
        await AsyncStorage.setItem(KEYS.city, d.city);
        await AsyncStorage.setItem(KEYS.country, d.country);
        await AsyncStorage.setItem(KEYS.timezone, d.timezone);
        await AsyncStorage.setItem(KEYS.source, d.source);
    } catch (_) { /* ignore */ }
}
