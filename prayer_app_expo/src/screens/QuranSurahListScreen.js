import React, { useEffect, useMemo, useState } from 'react';
import {
    View,
    Text,
    StyleSheet,
    TouchableOpacity,
    TextInput,
    FlatList,
    ActivityIndicator,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useTheme } from '../providers/ThemeProvider';
import { QuranLayout, interFont, getTypography } from '../theme/theme';
import { fetchSurahList, loadCachedSurahList } from '../services/quranApi';
import { loadLastRead } from '../services/quranStorageService';

export default function QuranSurahListScreen({ onBack, onOpenReader, autofocusSearch = false }) {
    const { theme: tc } = useTheme();
    const typo = getTypography(tc);

    const [query, setQuery] = useState('');
    const [surahs, setSurahs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [offlineCached, setOfflineCached] = useState(false);
    const [error, setError] = useState(null);
    const [lastRead, setLastRead] = useState(null);

    useEffect(() => {
        loadData();
        refreshLastRead();
    }, []);

    async function refreshLastRead() {
        const p = await loadLastRead();
        setLastRead(p);
    }

    async function loadData() {
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
                setError('Failed to load surah list');
                setLoading(false);
            }
        }
    }

    const filtered = useMemo(() => {
        const qRaw = query.trim();
        const q = qRaw.toLowerCase();
        if (!qRaw) return surahs;
        return surahs.filter((s) =>
            String(s.number).includes(q) ||
            (s.englishName || '').toLowerCase().includes(q) ||
            (s.nameAr || '').includes(qRaw)
        );
    }, [query, surahs]);

    return (
        <View style={{ flex: 1 }}>
            <View style={styles.topBar}>
                <TouchableOpacity onPress={onBack} hitSlop={10}>
                    <MaterialCommunityIcons name="arrow-left" size={24} color={tc.textPrimary} />
                </TouchableOpacity>
                <View style={{ width: 12 }} />
                <Text style={typo.titleMedium}>All Surahs</Text>
            </View>

            <View style={{ paddingHorizontal: QuranLayout.screenPadding }}>
                <View style={[styles.searchWrap, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}> 
                    <MaterialCommunityIcons name="magnify" size={20} color={tc.textMuted} />
                    <View style={{ width: 8 }} />
                    <TextInput
                        value={query}
                        onChangeText={setQuery}
                        autoFocus={autofocusSearch}
                        placeholder="Search by number, English, or Arabic"
                        placeholderTextColor={tc.textMuted}
                        style={[styles.searchInput, { color: tc.textPrimary }]}
                    />
                </View>
            </View>

            {offlineCached && (
                <View style={[styles.banner, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}> 
                    <MaterialCommunityIcons name="wifi-off" size={16} color={tc.textMuted} />
                    <Text style={[typo.caption, { marginLeft: 8 }]}>Offline (cached)</Text>
                </View>
            )}

            {loading && surahs.length === 0 ? (
                <View style={styles.center}><ActivityIndicator size="large" color={tc.accent} /></View>
            ) : error && surahs.length === 0 ? (
                <View style={styles.center}><Text style={typo.caption}>{error}</Text></View>
            ) : (
                <FlatList
                    data={filtered}
                    keyExtractor={(item) => String(item.number)}
                    contentContainerStyle={{ paddingHorizontal: 20, paddingTop: 10, paddingBottom: 20 }}
                    renderItem={({ item }) => {
                        const isLastRead = lastRead?.surahNumber === item.number;
                        const initialAyah = isLastRead ? lastRead.ayahNumber : 1;
                        return (
                            <TouchableOpacity
                                activeOpacity={0.8}
                                onPress={async () => {
                                    await onOpenReader(item, initialAyah, 'list');
                                    refreshLastRead();
                                }}
                                style={[
                                    styles.row,
                                    {
                                        backgroundColor: tc.card,
                                        borderColor: isLastRead ? `${tc.accent}AA` : tc.cardBorder,
                                    },
                                ]}
                            >
                                <View style={[styles.badge, { backgroundColor: `${tc.accent}2E` }]}> 
                                    <Text style={[typo.caption, { color: tc.accent, fontFamily: interFont('600') }]}>{item.number}</Text>
                                </View>
                                <View style={{ width: 12 }} />
                                <View style={{ flex: 1 }}>
                                    <Text style={[typo.body, { fontFamily: interFont('600') }]} numberOfLines={1}>{item.englishName}</Text>
                                    <Text style={typo.caption} numberOfLines={1}>{item.nameAr}</Text>
                                </View>
                                <View style={{ marginLeft: 8, alignItems: 'flex-end' }}>
                                    <Text style={typo.caption}>{item.ayahCount} ayahs</Text>
                                    <Text style={typo.caption}>{item.revelationType}</Text>
                                </View>
                                <View style={{ width: 4 }} />
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
    searchWrap: {
        height: QuranLayout.searchHeight,
        borderWidth: 1,
        borderRadius: QuranLayout.searchRadius,
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 12,
    },
    searchInput: {
        flex: 1,
        fontFamily: interFont('400'),
        fontSize: 14,
    },
    banner: {
        marginHorizontal: 20,
        marginTop: 8,
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
    row: {
        height: QuranLayout.surahRowHeight,
        marginBottom: 10,
        borderRadius: QuranLayout.cardRadius,
        borderWidth: 1,
        paddingHorizontal: 12,
        flexDirection: 'row',
        alignItems: 'center',
    },
    badge: {
        width: 32,
        height: 32,
        borderRadius: 16,
        alignItems: 'center',
        justifyContent: 'center',
    },
});
