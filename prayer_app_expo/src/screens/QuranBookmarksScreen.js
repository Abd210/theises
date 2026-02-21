import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, ActivityIndicator, Alert } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useTheme } from '../providers/ThemeProvider';
import { QuranLayout, getTypography, interFont } from '../theme/theme';
import { loadBookmarks, removeBookmark } from '../services/quranStorageService';
import { fetchSurahList, loadCachedSurahList, loadCachedArabic, fetchSurahArabic } from '../services/quranApi';

export default function QuranBookmarksScreen({ onBack, onOpenReader }) {
    const { theme: tc } = useTheme();
    const typo = getTypography(tc);

    const [bookmarks, setBookmarks] = useState([]);
    const [surahMap, setSurahMap] = useState({});
    const [previews, setPreviews] = useState({});
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        load();
    }, []);

    async function load() {
        setLoading(true);
        const b = await loadBookmarks();

        let surahs = await loadCachedSurahList();
        if (!surahs?.length) {
            try {
                surahs = await fetchSurahList();
            } catch (_) {
                surahs = [];
            }
        }

        const map = {};
        for (const s of surahs) map[s.number] = s;

        setBookmarks(b);
        setSurahMap(map);
        setLoading(false);

        loadPreviews(b);
    }

    async function loadPreviews(bookmarksList) {
        const next = {};
        const cachedSurahAyahs = {};

        for (const b of bookmarksList) {
            if (!cachedSurahAyahs[b.surahNumber]) {
                let ayahs = await loadCachedArabic(b.surahNumber);
                if (!ayahs?.length) {
                    try {
                        ayahs = await fetchSurahArabic(b.surahNumber);
                    } catch (_) {
                        ayahs = [];
                    }
                }
                cachedSurahAyahs[b.surahNumber] = ayahs;
            }

            const ayahs = cachedSurahAyahs[b.surahNumber] || [];
            const idx = b.ayahNumber - 1;
            if (idx >= 0 && idx < ayahs.length) {
                const clean = (ayahs[idx].textAr || '').replace(/\n/g, ' ').trim();
                next[`${b.surahNumber}_${b.ayahNumber}`] = clean.length > 30 ? `${clean.slice(0, 30)}…` : clean;
            } else {
                next[`${b.surahNumber}_${b.ayahNumber}`] = '';
            }
        }

        setPreviews(next);
    }

    function onLongPressDelete(item) {
        Alert.alert(
            'Delete bookmark',
            `Remove ${surahMap[item.surahNumber]?.englishName || `Surah ${item.surahNumber}`} · Ayah ${item.ayahNumber}?`,
            [
                { text: 'Cancel', style: 'cancel' },
                {
                    text: 'Delete',
                    style: 'destructive',
                    onPress: async () => {
                        await removeBookmark(item);
                        load();
                    },
                },
            ]
        );
    }

    return (
        <View style={{ flex: 1 }}>
            <View style={styles.topBar}>
                <TouchableOpacity onPress={onBack} hitSlop={10}>
                    <MaterialCommunityIcons name="arrow-left" size={24} color={tc.textPrimary} />
                </TouchableOpacity>
                <View style={{ width: 12 }} />
                <Text style={typo.titleMedium}>Bookmarks</Text>
            </View>

            {loading ? (
                <View style={styles.center}><ActivityIndicator size="large" color={tc.accent} /></View>
            ) : bookmarks.length === 0 ? (
                <View style={styles.center}><Text style={typo.caption}>No bookmarks yet</Text></View>
            ) : (
                <FlatList
                    data={bookmarks}
                    keyExtractor={(item, idx) => `${item.surahNumber}_${item.ayahNumber}_${idx}`}
                    contentContainerStyle={{ paddingHorizontal: 20, paddingTop: 10, paddingBottom: 20 }}
                    renderItem={({ item }) => {
                        const surah = surahMap[item.surahNumber];
                        const preview = previews[`${item.surahNumber}_${item.ayahNumber}`] || '';
                        return (
                            <TouchableOpacity
                                style={[styles.row, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}
                                activeOpacity={0.85}
                                onPress={() => onOpenReader(surah || { number: item.surahNumber, englishName: `Surah ${item.surahNumber}`, nameAr: '' }, item.ayahNumber, 'bookmarks')}
                                onLongPress={() => onLongPressDelete(item)}
                            >
                                <MaterialCommunityIcons name="bookmark" size={20} color={tc.accent} style={{ marginTop: 2 }} />
                                <View style={{ width: 12 }} />
                                <View style={{ flex: 1 }}>
                                    <Text style={[typo.body, { fontFamily: interFont('600') }]}>
                                        {(surah?.englishName || `Surah ${item.surahNumber}`)} · Ayah {item.ayahNumber}
                                    </Text>
                                    {preview ? (
                                        <Text style={[typo.caption, { marginTop: 4 }]} numberOfLines={1}>{preview}</Text>
                                    ) : null}
                                </View>
                                <MaterialCommunityIcons name="chevron-right" size={20} color={tc.textMuted} />
                            </TouchableOpacity>
                        );
                    }}
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
    center: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
    },
    row: {
        padding: QuranLayout.cardPadding,
        borderRadius: QuranLayout.cardRadius,
        borderWidth: 1,
        marginBottom: 10,
        flexDirection: 'row',
        alignItems: 'flex-start',
    },
});
