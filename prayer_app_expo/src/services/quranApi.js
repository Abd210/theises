import AsyncStorage from '@react-native-async-storage/async-storage';
import {
    toAyahArabic,
    toAyahEnglish,
    toJuzAyahArabic,
    toJuzAyahEnglish,
    toSurahMeta,
    mergeArabicAndEnglish,
} from '../models/quranModels';

const BASE = 'https://api.alquran.cloud/v1';
export const ARABIC_EDITION = 'quran-uthmani';
export const ENGLISH_EDITION = 'en.sahih';

export const SURAH_LIST_CACHE_KEY = 'quran_surah_list_v1';
export const arabicCacheKey = (n) => `quran_surah_${n}_${ARABIC_EDITION}_v1`;
export const englishCacheKey = (n) => `quran_surah_${n}_${ENGLISH_EDITION}_v1`;
export const juzArabicCacheKey = (j) => `quran_juz_${j}_${ARABIC_EDITION}_v1`;
export const juzEnglishCacheKey = (j) => `quran_juz_${j}_${ENGLISH_EDITION}_v1`;

async function fetchJson(url) {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`Request failed: ${res.status}`);
    return res.json();
}

export async function loadCachedSurahList() {
    try {
        const raw = await AsyncStorage.getItem(SURAH_LIST_CACHE_KEY);
        return raw ? JSON.parse(raw) : null;
    } catch (_) {
        return null;
    }
}

export async function loadCachedArabic(surahNumber) {
    try {
        const raw = await AsyncStorage.getItem(arabicCacheKey(surahNumber));
        return raw ? JSON.parse(raw) : null;
    } catch (_) {
        return null;
    }
}

export async function loadCachedEnglish(surahNumber) {
    try {
        const raw = await AsyncStorage.getItem(englishCacheKey(surahNumber));
        return raw ? JSON.parse(raw) : null;
    } catch (_) {
        return null;
    }
}

export async function loadCachedJuzArabic(juzNumber) {
    try {
        const raw = await AsyncStorage.getItem(juzArabicCacheKey(juzNumber));
        return raw ? JSON.parse(raw) : null;
    } catch (_) {
        return null;
    }
}

export async function loadCachedJuzEnglish(juzNumber) {
    try {
        const raw = await AsyncStorage.getItem(juzEnglishCacheKey(juzNumber));
        return raw ? JSON.parse(raw) : null;
    } catch (_) {
        return null;
    }
}

export async function fetchSurahList() {
    const json = await fetchJson(`${BASE}/surah`);
    const list = (json?.data || []).map(toSurahMeta);
    await AsyncStorage.setItem(SURAH_LIST_CACHE_KEY, JSON.stringify(list));
    return list;
}

export async function fetchSurahArabic(surahNumber) {
    const json = await fetchJson(`${BASE}/surah/${surahNumber}/${ARABIC_EDITION}`);
    const ayahs = (json?.data?.ayahs || []).map(toAyahArabic);
    await AsyncStorage.setItem(arabicCacheKey(surahNumber), JSON.stringify(ayahs));
    return ayahs;
}

export async function fetchSurahTranslation(surahNumber) {
    const json = await fetchJson(`${BASE}/surah/${surahNumber}/${ENGLISH_EDITION}`);
    const ayahs = (json?.data?.ayahs || []).map(toAyahEnglish);
    await AsyncStorage.setItem(englishCacheKey(surahNumber), JSON.stringify(ayahs));
    return ayahs;
}

export async function fetchJuzArabic(juzNumber) {
    const json = await fetchJson(`${BASE}/juz/${juzNumber}/${ARABIC_EDITION}`);
    const ayahs = (json?.data?.ayahs || []).map(toJuzAyahArabic);
    await AsyncStorage.setItem(juzArabicCacheKey(juzNumber), JSON.stringify(ayahs));
    return ayahs;
}

export async function fetchJuzTranslation(juzNumber) {
    const json = await fetchJson(`${BASE}/juz/${juzNumber}/${ENGLISH_EDITION}`);
    const ayahs = (json?.data?.ayahs || []).map(toJuzAyahEnglish);
    await AsyncStorage.setItem(juzEnglishCacheKey(juzNumber), JSON.stringify(ayahs));
    return ayahs;
}

export async function getJuzStartPointer(juzNumber) {
    const cached = await loadCachedJuzArabic(juzNumber);
    if (cached?.length) {
        return {
            surahNumber: cached[0].surahNumber,
            ayahNumber: cached[0].numberInSurah,
        };
    }
    const fresh = await fetchJuzArabic(juzNumber);
    if (!fresh?.length) return null;
    return {
        surahNumber: fresh[0].surahNumber,
        ayahNumber: fresh[0].numberInSurah,
    };
}

export { mergeArabicAndEnglish };
