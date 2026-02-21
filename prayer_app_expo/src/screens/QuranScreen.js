import React, { useEffect, useMemo, useState } from 'react';
import {
    View,
    Text,
    StyleSheet,
    TouchableOpacity,
    ScrollView,
    ActivityIndicator,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useTheme } from '../providers/ThemeProvider';
import { QuranLayout, interFont, getTypography } from '../theme/theme';
import { fetchSurahList, getJuzStartPointer, loadCachedSurahList } from '../services/quranApi';
import { loadLastRead, loadRecents } from '../services/quranStorageService';
import QuranSurahListScreen from './QuranSurahListScreen';
import QuranReaderScreen from './QuranReaderScreen';
import QuranBookmarksScreen from './QuranBookmarksScreen';

export default function QuranScreen({ onHideNav }) {
    const { theme: tc } = useTheme();
    const typo = getTypography(tc);

    const [mode, setMode] = useState('home'); // home | list | reader | bookmarks
    const [readerBackMode, setReaderBackMode] = useState('home');
    const [selectedSurah, setSelectedSurah] = useState(null);
    const [selectedAyah, setSelectedAyah] = useState(1);
    const [listAutofocus, setListAutofocus] = useState(false);

    const [surahs, setSurahs] = useState([]);
    const [lastRead, setLastReadState] = useState(null);
    const [recents, setRecents] = useState([]);

    const [loading, setLoading] = useState(true);
    const [offlineCached, setOfflineCached] = useState(false);
    const [error, setError] = useState(null);
    const [selectedJuz, setSelectedJuz] = useState(null);
    const [openingJuz, setOpeningJuz] = useState(null);

    useEffect(() => {
        onHideNav?.(mode !== 'home');
    }, [mode, onHideNav]);

    useEffect(() => {
        loadPersisted();
        loadSurahList();
    }, []);

    useEffect(() => {
        if (mode === 'home') {
            loadPersisted();
        }
    }, [mode]);

    async function loadPersisted() {
        const [lr, rc] = await Promise.all([loadLastRead(), loadRecents()]);
        setLastReadState(lr);
        setRecents(rc || []);
    }

    async function loadSurahList() {
        setLoading(true);
        setOfflineCached(false);
        setError(null);

        const cached = await loadCachedSurahList();
        if (cached?.length) {
            setSurahs(cached);
            setLoading(false);
        }

        try {
            const fresh = await fetchSurahList();
            setSurahs(fresh);
            setLoading(false);
            setOfflineCached(false);
        } catch (_) {
            if (cached?.length) {
                setOfflineCached(true);
                setLoading(false);
            } else {
                setError('Failed to load surah metadata');
                setLoading(false);
            }
        }
    }

    const surahMap = useMemo(() => {
        const map = {};
        for (const s of surahs) map[s.number] = s;
        return map;
    }, [surahs]);

    function openReader(surah, ayahNumber = 1, backMode = 'home') {
        if (!surah) return;
        setSelectedSurah(surah);
        setSelectedAyah(ayahNumber || 1);
        setReaderBackMode(backMode);
        setMode('reader');
    }

    async function onJuzTap(juz) {
        setSelectedJuz(juz);
        setOpeningJuz(juz);
        try {
            const pointer = await getJuzStartPointer(juz);
            if (!pointer) return;
            let surah = surahMap[pointer.surahNumber];
            if (!surah) {
                const refreshed = await fetchSurahList();
                setSurahs(refreshed);
                surah = refreshed.find((s) => s.number === pointer.surahNumber);
            }
            if (!surah) return;
            openReader(surah, pointer.ayahNumber, 'home');
        } catch (e) {
            console.log('[QuranHome] Juz open failed:', e?.message || e);
        } finally {
            setOpeningJuz(null);
        }
    }

    function sectionTitle(text) {
        return (
            <Text style={[typo.body, { fontFamily: interFont('600'), fontSize: QuranLayout.sectionTitleSize }]}>
                {text}
            </Text>
        );
    }

    if (mode === 'list') {
        return (
            <QuranSurahListScreen
                autofocusSearch={listAutofocus}
                onBack={() => {
                    setMode('home');
                    setListAutofocus(false);
                }}
                onOpenReader={openReader}
            />
        );
    }

    if (mode === 'reader' && selectedSurah) {
        return (
            <QuranReaderScreen
                surah={selectedSurah}
                initialAyahNumber={selectedAyah}
                onBack={() => setMode(readerBackMode)}
            />
        );
    }

    if (mode === 'bookmarks') {
        return (
            <QuranBookmarksScreen
                onBack={() => setMode('home')}
                onOpenReader={openReader}
            />
        );
    }

    return (
        <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
            <View style={{ height: QuranLayout.titleMarginTop }} />

            <View style={styles.headerRow}>
                <View style={{ flex: 1 }}>
                    <Text style={typo.titleLarge}>Quran</Text>
                    <Text style={[typo.caption, { fontSize: QuranLayout.subtitleSize }]}>114 Surahs · Read & Reflect</Text>
                </View>
                <TouchableOpacity
                    style={[styles.bookmarkBtn, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}
                    onPress={() => setMode('bookmarks')}
                >
                    <MaterialCommunityIcons name="bookmark-outline" size={20} color={tc.textPrimary} />
                </TouchableOpacity>
            </View>

            <View style={{ height: QuranLayout.sectionGap }} />
            <TouchableOpacity
                activeOpacity={0.8}
                onPress={() => {
                    setListAutofocus(true);
                    setMode('list');
                }}
            >
                <View style={[styles.searchWrap, { borderColor: tc.cardBorder, backgroundColor: tc.card }]}>
                    <MaterialCommunityIcons name="magnify" size={20} color={tc.textMuted} />
                    <View style={{ width: 8 }} />
                    <Text style={[typo.caption, { fontSize: 14 }]}>Search Surah</Text>
                </View>
            </TouchableOpacity>

            {offlineCached && (
                <View style={[styles.banner, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}> 
                    <MaterialCommunityIcons name="wifi-off" size={16} color={tc.textMuted} />
                    <Text style={[typo.caption, { marginLeft: 8 }]}>Offline (cached)</Text>
                </View>
            )}
            {error ? <Text style={[typo.caption, { marginTop: 8 }]}>{error}</Text> : null}

            <View style={{ height: QuranLayout.sectionGap }} />
            {sectionTitle('Continue Reading')}
            <View style={{ height: 8 }} />
            {lastRead ? (
                <ActionCard
                    tc={tc}
                    text={`Continue: ${(surahMap[lastRead.surahNumber]?.englishName || `Surah ${lastRead.surahNumber}`)} · Ayah ${lastRead.ayahNumber}`}
                    onPress={() => openReader(surahMap[lastRead.surahNumber] || { number: lastRead.surahNumber, englishName: `Surah ${lastRead.surahNumber}`, nameAr: '' }, lastRead.ayahNumber, 'home')}
                />
            ) : (
                <HintCard tc={tc} text="Start reading to continue here." onPress={() => setMode('list')} />
            )}

            <View style={{ height: QuranLayout.sectionGap }} />
            <View style={styles.recentsHeader}>
                {sectionTitle('Recents')}
                {loading ? <MaterialCommunityIcons name="loading" size={16} color={tc.accent} /> : null}
            </View>
            <View style={{ height: 8 }} />
            {(recents || []).slice(0, 3).map((r, i) => (
                <View key={`${r.surahNumber}_${r.ayahNumber}_${i}`} style={{ marginBottom: 8 }}>
                    <ActionCard
                        compact
                        tc={tc}
                        text={`${surahMap[r.surahNumber]?.englishName || `Surah ${r.surahNumber}`} · Ayah ${r.ayahNumber}`}
                        onPress={() => openReader(surahMap[r.surahNumber] || { number: r.surahNumber, englishName: `Surah ${r.surahNumber}`, nameAr: '' }, r.ayahNumber, 'home')}
                    />
                </View>
            ))}
            {(recents || []).length === 0 ? <Text style={typo.caption}>No recent reading yet.</Text> : null}

            <View style={{ height: QuranLayout.sectionGap }} />
            {sectionTitle('Juz')}
            <View style={{ height: 8 }} />
            <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                <View style={styles.juzColumns}>
                    {Array.from({ length: 15 }, (_, col) => {
                        const top = col + 1;
                        const bottom = col + 16;
                        return (
                            <View key={`col-${col}`} style={styles.juzColumn}>
                                <JuzChip tc={tc} number={top} selected={selectedJuz === top} loading={openingJuz === top} onPress={() => onJuzTap(top)} />
                                <View style={{ height: QuranLayout.juzChipGap }} />
                                <JuzChip tc={tc} number={bottom} selected={selectedJuz === bottom} loading={openingJuz === bottom} onPress={() => onJuzTap(bottom)} />
                            </View>
                        );
                    })}
                </View>
            </ScrollView>
        </ScrollView>
    );
}

function ActionCard({ tc, text, onPress, compact = false }) {
    return (
        <TouchableOpacity
            activeOpacity={0.8}
            onPress={onPress}
            style={[
                styles.actionCard,
                compact && { height: QuranLayout.rowHeight },
                { backgroundColor: tc.card, borderColor: tc.cardBorder },
            ]}
        >
            <MaterialCommunityIcons name="book-open-variant" size={20} color={tc.accent} />
            <View style={{ width: 10 }} />
            <Text style={[styles.actionText, { color: tc.textPrimary }]} numberOfLines={compact ? 1 : 2}>{text}</Text>
            <MaterialCommunityIcons name="chevron-right" size={20} color={tc.textMuted} />
        </TouchableOpacity>
    );
}

function HintCard({ tc, text, onPress }) {
    return (
        <TouchableOpacity
            activeOpacity={0.8}
            onPress={onPress}
            style={[styles.hintCard, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}
        >
            <Text style={[styles.hintText, { color: tc.textMuted }]}>{text}</Text>
        </TouchableOpacity>
    );
}

function JuzChip({ tc, number, selected, loading, onPress }) {
    return (
        <TouchableOpacity
            activeOpacity={0.8}
            onPress={onPress}
            style={[
                styles.juzChip,
                {
                    backgroundColor: selected ? `${tc.accent}2A` : tc.card,
                    borderColor: selected ? `${tc.accent}CC` : tc.cardBorder,
                },
            ]}
        >
            {loading ? (
                <ActivityIndicator size="small" color={selected ? tc.accent : tc.textMuted} />
            ) : (
                <Text style={{ color: selected ? tc.accent : tc.textPrimary, fontFamily: interFont('600'), fontSize: 13 }}>
                    Juz {number}
                </Text>
            )}
        </TouchableOpacity>
    );
}

const styles = StyleSheet.create({
    scroll: { flex: 1 },
    content: {
        paddingHorizontal: QuranLayout.screenPadding,
        paddingBottom: 20,
    },
    headerRow: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    bookmarkBtn: {
        width: 40,
        height: 40,
        borderRadius: QuranLayout.pillRadius,
        borderWidth: 1,
        alignItems: 'center',
        justifyContent: 'center',
    },
    searchWrap: {
        height: QuranLayout.searchHeight,
        borderWidth: 1,
        borderRadius: QuranLayout.pillRadius,
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 12,
    },
    banner: {
        marginTop: 8,
        borderWidth: 1,
        borderRadius: 10,
        paddingHorizontal: 12,
        paddingVertical: 8,
        flexDirection: 'row',
        alignItems: 'center',
    },
    actionCard: {
        borderWidth: 1,
        borderRadius: QuranLayout.cardRadius,
        padding: QuranLayout.cardPadding,
        flexDirection: 'row',
        alignItems: 'center',
    },
    actionText: {
        flex: 1,
        fontFamily: interFont('400'),
        fontSize: 15,
    },
    hintCard: {
        borderWidth: 1,
        borderRadius: QuranLayout.cardRadius,
        paddingHorizontal: 14,
        paddingVertical: 12,
    },
    hintText: {
        fontFamily: interFont('400'),
        fontSize: 13,
    },
    recentsHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    juzColumns: {
        flexDirection: 'row',
    },
    juzColumn: {
        marginRight: QuranLayout.juzChipGap,
    },
    juzChip: {
        width: QuranLayout.juzChipWidth,
        height: QuranLayout.juzButtonSize,
        borderRadius: QuranLayout.pillRadius,
        borderWidth: 1,
        alignItems: 'center',
        justifyContent: 'center',
    },
});
