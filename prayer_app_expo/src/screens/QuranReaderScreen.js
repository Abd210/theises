import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
    View,
    Text,
    StyleSheet,
    TouchableOpacity,
    FlatList,
    ActivityIndicator,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useTheme } from '../providers/ThemeProvider';
import { QuranLayout, interFont, getTypography } from '../theme/theme';
import {
    fetchSurahArabic,
    fetchSurahTranslation,
    loadCachedArabic,
    loadCachedEnglish,
    mergeArabicAndEnglish,
} from '../services/quranApi';
import {
    loadBookmarks,
    setLastRead,
    pushRecent,
    toggleBookmark,
    isBookmarked,
} from '../services/quranStorageService';

const AVG_AYAH_HEIGHT = 150;

export default function QuranReaderScreen({ surah, initialAyahNumber = 1, onBack }) {
    const { theme: tc } = useTheme();
    const typo = getTypography(tc);
    const listRef = useRef(null);

    const [arabic, setArabic] = useState([]);
    const [english, setEnglish] = useState(null);
    const [bookmarks, setBookmarks] = useState([]);

    const [showTranslation, setShowTranslation] = useState(false);
    const [translationLoading, setTranslationLoading] = useState(false);
    const [fontScale, setFontScale] = useState(1.0);

    const [loading, setLoading] = useState(true);
    const [offlineCached, setOfflineCached] = useState(false);
    const [error, setError] = useState(null);
    const [currentAyah, setCurrentAyah] = useState(initialAyahNumber);
    const [flashAyah, setFlashAyah] = useState(initialAyahNumber);
    const flashTimerRef = useRef(null);

    useEffect(() => {
        (async () => {
            const saved = await loadBookmarks();
            setBookmarks(saved);
        })();
    }, []);

    useEffect(() => {
        loadArabic();
    }, [surah.number]);

    const merged = useMemo(() => {
        if (showTranslation && english) {
            return mergeArabicAndEnglish(arabic, english);
        }
        return arabic;
    }, [arabic, english, showTranslation]);

    useEffect(() => {
        if (merged.length > 0) {
            jumpToAyah(initialAyahNumber);
        }
    }, [merged.length]);

    useEffect(() => {
        return () => {
            if (flashTimerRef.current) clearTimeout(flashTimerRef.current);
        };
    }, []);

    async function loadArabic() {
        setLoading(true);
        setOfflineCached(false);
        setError(null);

        const cached = await loadCachedArabic(surah.number);
        if (cached?.length) {
            setArabic(cached);
            setLoading(false);
        }

        try {
            const fresh = await fetchSurahArabic(surah.number);
            setArabic(fresh);
            setLoading(false);
            setOfflineCached(false);
            if (showTranslation) loadTranslation();
        } catch (e) {
            if (cached?.length) {
                setOfflineCached(true);
                setLoading(false);
            } else {
                setError('Failed to load surah text');
                setLoading(false);
            }
        }
    }

    async function loadTranslation() {
        if (translationLoading) return;
        setTranslationLoading(true);

        const cached = await loadCachedEnglish(surah.number);
        if (cached?.length) {
            setEnglish(cached);
            setTranslationLoading(false);
        }

        try {
            const fresh = await fetchSurahTranslation(surah.number);
            setEnglish(fresh);
            setTranslationLoading(false);
            setOfflineCached(false);
        } catch (e) {
            setTranslationLoading(false);
            if (cached?.length) setOfflineCached(true);
        }
    }

    function jumpToAyah(ayahNumber) {
        if (flashTimerRef.current) clearTimeout(flashTimerRef.current);
        setFlashAyah(ayahNumber || 1);
        flashTimerRef.current = setTimeout(() => setFlashAyah(null), 1400);
        const idx = Math.max(0, Math.min((ayahNumber || 1) - 1, Math.max(0, merged.length - 1)));
        setTimeout(() => {
            try {
                listRef.current?.scrollToIndex({ index: idx, animated: true, viewPosition: 0.05 });
            } catch (_) {
                // best effort
            }
        }, 60);
    }

    async function updateLastRead(ayahNumber) {
        if (!ayahNumber || ayahNumber === currentAyah) return;
        setCurrentAyah(ayahNumber);
        const pointer = { surahNumber: surah.number, ayahNumber };
        await setLastRead(pointer);
        await pushRecent(pointer);
    }

    async function onToggleBookmark() {
        const pointer = { surahNumber: surah.number, ayahNumber: currentAyah };
        const next = await toggleBookmark(pointer);
        setBookmarks(next);
    }

    function updateFromOffset(y) {
        if (!merged.length) return;
        const idx = Math.max(0, Math.min(Math.round(y / AVG_AYAH_HEIGHT), merged.length - 1));
        updateLastRead(merged[idx].numberInSurah);
    }

    const currentBookmarked = isBookmarked(bookmarks, {
        surahNumber: surah.number,
        ayahNumber: currentAyah,
    });

    return (
        <View style={{ flex: 1 }}>
            <View style={styles.topBar}>
                <TouchableOpacity onPress={onBack} hitSlop={10}>
                    <MaterialCommunityIcons name="arrow-left" size={24} color={tc.textPrimary} />
                </TouchableOpacity>
                <View style={{ flex: 1, marginHorizontal: 10 }}>
                    <Text style={[typo.body, { fontFamily: interFont('600') }]} numberOfLines={1}>{surah.englishName}</Text>
                    <Text style={[typo.caption]} numberOfLines={1}>{surah.nameAr} · Ayah {currentAyah}</Text>
                </View>
                <TouchableOpacity onPress={() => setFontScale((s) => Math.max(0.8, +(s - 0.1).toFixed(1)))}>
                    <MaterialCommunityIcons name="format-font-size-decrease" size={QuranLayout.topActionIconSize} color={tc.textPrimary} />
                </TouchableOpacity>
                <View style={{ width: 8 }} />
                <TouchableOpacity onPress={() => setFontScale((s) => Math.min(1.6, +(s + 0.1).toFixed(1)))}>
                    <MaterialCommunityIcons name="format-font-size-increase" size={QuranLayout.topActionIconSize} color={tc.textPrimary} />
                </TouchableOpacity>
                <View style={{ width: 8 }} />
                <TouchableOpacity
                    onPress={() => {
                        const next = !showTranslation;
                        setShowTranslation(next);
                        if (next && !english) loadTranslation();
                    }}
                >
                    {translationLoading ? (
                        <ActivityIndicator size="small" color={tc.accent} />
                    ) : (
                        <MaterialCommunityIcons
                            name={showTranslation ? 'translate' : 'translate-off'}
                            size={QuranLayout.topActionIconSize}
                            color={showTranslation ? tc.accent : tc.textPrimary}
                        />
                    )}
                </TouchableOpacity>
                <View style={{ width: 8 }} />
                <TouchableOpacity onPress={onToggleBookmark}>
                    <MaterialCommunityIcons
                        name={currentBookmarked ? 'bookmark' : 'bookmark-outline'}
                        size={QuranLayout.topActionIconSize}
                        color={currentBookmarked ? tc.accent : tc.textPrimary}
                    />
                </TouchableOpacity>
            </View>

            {offlineCached && (
                <View style={[styles.banner, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}> 
                    <MaterialCommunityIcons name="wifi-off" size={16} color={tc.textMuted} />
                    <Text style={[typo.caption, { marginLeft: 8 }]}>Offline (cached)</Text>
                </View>
            )}

            {loading && merged.length === 0 ? (
                <View style={styles.center}><ActivityIndicator size="large" color={tc.accent} /></View>
            ) : error && merged.length === 0 ? (
                <View style={styles.center}>
                    <Text style={[typo.caption, { textAlign: 'center', paddingHorizontal: 24 }]}>{error}</Text>
                    <View style={{ height: 12 }} />
                    <TouchableOpacity style={[styles.retryBtn, { borderColor: tc.cardBorder }]} onPress={loadArabic}>
                        <Text style={[typo.body, { fontSize: 14 }]}>Retry</Text>
                    </TouchableOpacity>
                </View>
            ) : (
                <FlatList
                    ref={listRef}
                    data={merged}
                    keyExtractor={(item) => `ayah-${item.numberInSurah}`}
                    contentContainerStyle={{ paddingHorizontal: 20, paddingBottom: 24, paddingTop: 8 }}
                    onMomentumScrollEnd={(e) => updateFromOffset(e.nativeEvent.contentOffset.y)}
                    onScrollEndDrag={(e) => updateFromOffset(e.nativeEvent.contentOffset.y)}
                    onScrollToIndexFailed={() => {
                        // best effort only
                    }}
                    renderItem={({ item }) => (
                        <TouchableOpacity
                            activeOpacity={0.8}
                            onPress={() => updateLastRead(item.numberInSurah)}
                            style={[
                                styles.ayahItem,
                                {
                                    backgroundColor: tc.card,
                                    borderColor: item.numberInSurah === flashAyah
                                        ? `${tc.accent}EE`
                                        : item.numberInSurah === currentAyah
                                            ? `${tc.accent}88`
                                            : tc.cardBorder,
                                },
                            ]}
                        >
                            <Text style={[typo.caption, { color: tc.accent, fontFamily: interFont('600') }]}>{item.numberInSurah}</Text>
                            <View style={{ height: 8 }} />
                            <Text style={[
                                styles.arabic,
                                {
                                    color: tc.textPrimary,
                                    fontSize: QuranLayout.ayahArabicSize * fontScale,
                                },
                            ]}>
                                {item.textAr}
                            </Text>
                            {showTranslation && item.textEn ? (
                                <>
                                    <View style={{ height: 12 }} />
                                    <Text
                                        style={{
                                            color: tc.textMuted,
                                            fontFamily: interFont('400'),
                                            fontSize: QuranLayout.ayahTranslationSize * fontScale,
                                            lineHeight: QuranLayout.ayahTranslationSize * fontScale * 1.45,
                                        }}
                                    >
                                        {item.textEn}
                                    </Text>
                                </>
                            ) : null}
                        </TouchableOpacity>
                    )}
                />
            )}
        </View>
    );
}

const styles = StyleSheet.create({
    topBar: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 12,
        paddingVertical: 8,
    },
    banner: {
        marginHorizontal: 20,
        marginTop: 8,
        marginBottom: 4,
        borderWidth: 1,
        borderRadius: 10,
        paddingHorizontal: 12,
        paddingVertical: 8,
        flexDirection: 'row',
        alignItems: 'center',
    },
    center: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
    },
    retryBtn: {
        height: 34,
        borderRadius: 17,
        borderWidth: 1,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: 14,
    },
    ayahItem: {
        marginBottom: QuranLayout.ayahItemGap,
        padding: QuranLayout.ayahItemPadding,
        borderRadius: QuranLayout.cardRadius,
        borderWidth: 1,
    },
    arabic: {
        fontFamily: 'serif',
        textAlign: 'right',
        lineHeight: QuranLayout.ayahArabicSize * 1.9,
    },
});
