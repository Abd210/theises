import AsyncStorage from '@react-native-async-storage/async-storage';

const DATA_KEY = 'cached_prayer_json';
const DATE_KEY = 'cached_prayer_date';

export async function saveCache(jsonStr, dateTag) {
    await AsyncStorage.setItem(DATA_KEY, jsonStr);
    await AsyncStorage.setItem(DATE_KEY, dateTag);
}

export async function loadCache() {
    return AsyncStorage.getItem(DATA_KEY);
}

export async function getCachedDate() {
    return AsyncStorage.getItem(DATE_KEY);
}
