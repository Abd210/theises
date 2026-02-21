import AsyncStorage from '@react-native-async-storage/async-storage';
import { pointerKey } from '../models/quranModels';

export const LAST_READ_KEY = 'quran_last_read';
export const RECENTS_KEY = 'quran_recents';
export const BOOKMARKS_KEY = 'quran_bookmarks';

export async function loadLastRead() {
    try {
        const raw = await AsyncStorage.getItem(LAST_READ_KEY);
        return raw ? JSON.parse(raw) : null;
    } catch (_) {
        return null;
    }
}

export async function setLastRead(pointer) {
    await AsyncStorage.setItem(LAST_READ_KEY, JSON.stringify(pointer));
}

export async function loadRecents() {
    try {
        const raw = await AsyncStorage.getItem(RECENTS_KEY);
        return raw ? JSON.parse(raw) : [];
    } catch (_) {
        return [];
    }
}

export async function pushRecent(pointer) {
    const recents = await loadRecents();
    const key = pointerKey(pointer);
    const deduped = recents.filter((r) => pointerKey(r) !== key);
    deduped.unshift(pointer);
    const sliced = deduped.slice(0, 10);
    await AsyncStorage.setItem(RECENTS_KEY, JSON.stringify(sliced));
    return sliced;
}

export async function loadBookmarks() {
    try {
        const raw = await AsyncStorage.getItem(BOOKMARKS_KEY);
        return raw ? JSON.parse(raw) : [];
    } catch (_) {
        return [];
    }
}

export async function toggleBookmark(pointer) {
    const bookmarks = await loadBookmarks();
    const key = pointerKey(pointer);
    const idx = bookmarks.findIndex((b) => pointerKey(b) === key);
    if (idx >= 0) {
        bookmarks.splice(idx, 1);
    } else {
        bookmarks.unshift(pointer);
    }
    await AsyncStorage.setItem(BOOKMARKS_KEY, JSON.stringify(bookmarks));
    return bookmarks;
}

export async function removeBookmark(pointer) {
    const bookmarks = await loadBookmarks();
    const key = pointerKey(pointer);
    const next = bookmarks.filter((b) => pointerKey(b) !== key);
    await AsyncStorage.setItem(BOOKMARKS_KEY, JSON.stringify(next));
    return next;
}

export function isBookmarked(bookmarks, pointer) {
    return (bookmarks || []).some((b) => pointerKey(b) === pointerKey(pointer));
}
