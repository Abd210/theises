export function toSurahMeta(apiItem) {
    return {
        number: apiItem?.number ?? 0,
        nameAr: apiItem?.name ?? '',
        englishName: apiItem?.englishName ?? '',
        englishNameTranslation: apiItem?.englishNameTranslation ?? '',
        ayahCount: apiItem?.numberOfAyahs ?? 0,
        revelationType: apiItem?.revelationType ?? '',
    };
}

export function toAyahArabic(apiItem) {
    return {
        numberInSurah: apiItem?.numberInSurah ?? 0,
        textAr: apiItem?.text ?? '',
        textEn: null,
    };
}

export function toAyahEnglish(apiItem) {
    return {
        numberInSurah: apiItem?.numberInSurah ?? 0,
        textAr: '',
        textEn: apiItem?.text ?? '',
    };
}

export function toJuzAyahArabic(apiItem) {
    return {
        surahNumber: apiItem?.surah?.number ?? 0,
        numberInSurah: apiItem?.numberInSurah ?? 0,
        textAr: apiItem?.text ?? '',
        textEn: null,
    };
}

export function toJuzAyahEnglish(apiItem) {
    return {
        surahNumber: apiItem?.surah?.number ?? 0,
        numberInSurah: apiItem?.numberInSurah ?? 0,
        textAr: '',
        textEn: apiItem?.text ?? '',
    };
}

export function toPageAyah(apiItem) {
    return {
        globalNumber: apiItem?.number ?? 0,
        surahNumber: apiItem?.surah?.number ?? 0,
        surahNameAr: apiItem?.surah?.name ?? '',
        surahEnglishName: apiItem?.surah?.englishName ?? '',
        numberInSurah: apiItem?.numberInSurah ?? 0,
        textAr: apiItem?.text ?? '',
        textEn: null,
        juz: apiItem?.juz ?? 1,
        page: apiItem?.page ?? 1,
    };
}

export function toPageAyahEnglish(apiItem) {
    return {
        globalNumber: apiItem?.number ?? 0,
        surahNumber: apiItem?.surah?.number ?? 0,
        surahNameAr: apiItem?.surah?.name ?? '',
        surahEnglishName: apiItem?.surah?.englishName ?? '',
        numberInSurah: apiItem?.numberInSurah ?? 0,
        textAr: '',
        textEn: apiItem?.text ?? '',
        juz: apiItem?.juz ?? 1,
        page: apiItem?.page ?? 1,
    };
}

export function mergeArabicAndEnglish(arabicAyahs, englishAyahs) {
    const byAyah = new Map();
    for (const a of englishAyahs || []) {
        if (a?.textEn) byAyah.set(a.numberInSurah, a.textEn);
    }
    return (arabicAyahs || []).map((a) => ({
        ...a,
        textEn: byAyah.get(a.numberInSurah) || null,
    }));
}

export function mergePageArabicAndEnglish(arabicAyahs, englishAyahs) {
    const byGlobal = new Map();
    for (const a of englishAyahs || []) {
        if (a?.textEn) byGlobal.set(a.globalNumber, a.textEn);
    }
    return (arabicAyahs || []).map((a) => ({
        ...a,
        textEn: byGlobal.get(a.globalNumber) || null,
    }));
}

export function pointerKey(pointer) {
    if (pointer.pageNumber != null) return `page_${pointer.pageNumber}`;
    return `${pointer.surahNumber}_${pointer.ayahNumber}`;
}
