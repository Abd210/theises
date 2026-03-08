import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
    View,
    Text,
    StyleSheet,
    TouchableOpacity,
    FlatList,
    ScrollView,
    ActivityIndicator,
    useWindowDimensions,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useTheme } from '../providers/ThemeProvider';
import { QuranLayout, SalahLayout, interFont, getTypography } from '../theme/theme';
import {
    fetchPageArabic,
    fetchPageTranslation,
    mergePageArabicAndEnglish,
} from '../services/quranApi';
import {
    setLastRead,
    pushRecent,
} from '../services/quranStorageService';

const TOTAL_PAGES = 604;

export default function MushafPagerScreen({ initialPage = 1, onBack }) {
    const { theme: tc } = useTheme();
    const typo = getTypography(tc);
    const { width: screenWidth } = useWindowDimensions();
    const flatListRef = useRef(null);

    const [currentPage, setCurrentPage] = useState(Math.max(1, Math.min(initialPage, TOTAL_PAGES)));
    const [currentJuz, setCurrentJuz] = useState(1);
    const [pageCache, setPageCache] = useState({});
    const [translationCache, setTranslationCache] = useState({});
    const [loadingPages, setLoadingPages] = useState(new Set());
    const [pageErrors, setPageErrors] = useState({});
    const [showTranslation, setShowTranslation] = useState(false);
    const [fontScale, setFontScale] = useState(1.0);

    // Pages data array (1..604)
    const pages = useMemo(() => Array.from({ length: TOTAL_PAGES }, (_, i) => i + 1), []);

    const fetchPage = useCallback(async (page) => {
        if (pageCache[page] || loadingPages.has(page)) return;
        setLoadingPages((prev) => new Set(prev).add(page));

        try {
            const ayahs = await fetchPageArabic(page);
            setPageCache((prev) => ({ ...prev, [page]: ayahs }));
            setPageErrors((prev) => {
                const next = { ...prev };
                delete next[page];
                return next;
            });
        } catch (e) {
            setPageErrors((prev) => ({ ...prev, [page]: `Failed to load page ${page}` }));
            if (__DEV__) console.log(`[MushafPager] Error loading page ${page}:`, e?.message || e);
        } finally {
            setLoadingPages((prev) => {
                const next = new Set(prev);
                next.delete(page);
                return next;
            });
        }
    }, [pageCache, loadingPages]);

    const fetchTranslationForPage = useCallback(async (page) => {
        if (translationCache[page]) return;
        try {
            const ayahs = await fetchPageTranslation(page);
            setTranslationCache((prev) => ({ ...prev, [page]: ayahs }));
        } catch (e) {
            if (__DEV__) console.log(`[MushafPager] Translation error page ${page}:`, e?.message || e);
        }
    }, [translationCache]);

    // Initial page load
    useEffect(() => {
        const page = Math.max(1, Math.min(initialPage, TOTAL_PAGES));
        fetchPage(page);
        if (page > 1) fetchPage(page - 1);
        if (page < TOTAL_PAGES) fetchPage(page + 1);
    }, []);

    // Update juz from cache
    useEffect(() => {
        const cached = pageCache[currentPage];
        if (cached?.length) {
            setCurrentJuz(cached[0].juz);
        }
    }, [currentPage, pageCache]);

    // Save position on page change
    useEffect(() => {
        const cached = pageCache[currentPage];
        const first = cached?.[0];
        const pointer = {
            surahNumber: first?.surahNumber ?? 1,
            ayahNumber: first?.numberInSurah ?? 1,
            pageNumber: currentPage,
        };
        setLastRead(pointer);
        pushRecent(pointer);
    }, [currentPage]);

    const onViewableItemsChanged = useRef(({ viewableItems }) => {
        if (viewableItems?.length > 0) {
            const page = viewableItems[0].item;
            setCurrentPage(page);
        }
    }).current;

    const viewabilityConfig = useRef({ itemVisiblePercentThreshold: 50 }).current;

    const onMomentumEnd = () => {
        // Prefetch adjacent
        if (currentPage > 1) fetchPage(currentPage - 1);
        fetchPage(currentPage);
        if (currentPage < TOTAL_PAGES) fetchPage(currentPage + 1);
        if (showTranslation) fetchTranslationForPage(currentPage);
    };

    const getMergedAyahs = (page) => {
        const arabic = pageCache[page];
        if (!arabic) return [];
        if (!showTranslation) return arabic;
        const english = translationCache[page];
        if (!english) return arabic;
        return mergePageArabicAndEnglish(arabic, english);
    };

    const goToPrev = () => {
        if (currentPage > 1) {
            flatListRef.current?.scrollToIndex({ index: currentPage - 2, animated: true });
        }
    };

    const goToNext = () => {
        if (currentPage < TOTAL_PAGES) {
            flatListRef.current?.scrollToIndex({ index: currentPage, animated: true });
        }
    };

    const renderPage = ({ item: page }) => {
        const isLoading = loadingPages.has(page) && !pageCache[page];
        const error = pageErrors[page];
        const ayahs = getMergedAyahs(page);

        return (
            <View style={{ width: screenWidth }}>
                {isLoading ? (
                    <View style={styles.center}>
                        <ActivityIndicator size="large" color={tc.accent} />
                    </View>
                ) : error && !pageCache[page] ? (
                    <View style={styles.center}>
                        <Text style={[typo.caption, { textAlign: 'center', paddingHorizontal: 24 }]}>{error}</Text>
                        <View style={{ height: 12 }} />
                        <TouchableOpacity
                            style={[styles.retryBtn, { borderColor: tc.cardBorder }]}
                            onPress={() => {
                                setPageErrors((prev) => {
                                    const next = { ...prev };
                                    delete next[page];
                                    return next;
                                });
                                fetchPage(page);
                            }}
                        >
                            <Text style={[typo.body, { fontSize: 14 }]}>Retry</Text>
                        </TouchableOpacity>
                    </View>
                ) : ayahs.length === 0 ? (
                    <View style={styles.center}>
                        <ActivityIndicator size="large" color={tc.accent} />
                    </View>
                ) : (
                    <ScrollView
                        contentContainerStyle={{
                            paddingHorizontal: QuranLayout.screenPadding,
                            paddingTop: 8,
                            paddingBottom: 20,
                        }}
                    >
                        {ayahs.map((ayah, index) => {
                            const showSurahHeader = index === 0 || ayah.surahNumber !== ayahs[index - 1].surahNumber;
                            return (
                                <View key={`${ayah.globalNumber}`}>
                                    {showSurahHeader && (
                                        <View style={[styles.surahHeader, {
                                            backgroundColor: `${tc.accent}14`,
                                            borderColor: `${tc.accent}33`,
                                        }]}>
                                            <MaterialCommunityIcons name="book-open-variant" size={18} color={tc.accent} />
                                            <View style={{ width: 8 }} />
                                            <Text style={[typo.body, { flex: 1, fontFamily: interFont('600'), fontSize: 14 }]}>
                                                {ayah.surahEnglishName}
                                            </Text>
                                            <Text style={{ fontFamily: 'serif', fontSize: 16, color: tc.accent }}>
                                                {ayah.surahNameAr}
                                            </Text>
                                        </View>
                                    )}
                                    <View style={[styles.ayahItem, {
                                        backgroundColor: tc.card,
                                        borderColor: tc.cardBorder,
                                    }]}>
                                        <View style={[styles.ayahBadge, { backgroundColor: `${tc.accent}1F` }]}>
                                            <Text style={{ color: tc.accent, fontFamily: interFont('600'), fontSize: 13 }}>
                                                {ayah.numberInSurah}
                                            </Text>
                                        </View>
                                        <View style={{ height: 8 }} />
                                        <Text style={[styles.arabic, {
                                            color: tc.textPrimary,
                                            fontSize: QuranLayout.ayahArabicSize * fontScale,
                                            lineHeight: QuranLayout.ayahArabicSize * fontScale * 1.9,
                                        }]}>
                                            {ayah.textAr}
                                        </Text>
                                        {showTranslation && ayah.textEn ? (
                                            <>
                                                <View style={{ height: 12 }} />
                                                <Text style={{
                                                    color: tc.textMuted,
                                                    fontFamily: interFont('400'),
                                                    fontSize: QuranLayout.ayahTranslationSize * fontScale,
                                                    lineHeight: QuranLayout.ayahTranslationSize * fontScale * 1.45,
                                                }}>
                                                    {ayah.textEn}
                                                </Text>
                                            </>
                                        ) : null}
                                    </View>
                                </View>
                            );
                        })}
                    </ScrollView>
                )}
            </View>
        );
    };

    return (
        <View style={{ flex: 1 }}>
            {/* Top bar */}
            <View style={styles.topBar}>
                <TouchableOpacity onPress={onBack} hitSlop={10}>
                    <MaterialCommunityIcons name="arrow-left" size={24} color={tc.textPrimary} />
                </TouchableOpacity>
                <View style={{ flex: 1, marginHorizontal: 10 }}>
                    <Text style={[typo.body, { fontFamily: interFont('600') }]} numberOfLines={1}>
                        Page {currentPage} / {TOTAL_PAGES}
                    </Text>
                    <Text style={typo.caption} numberOfLines={1}>Juz {currentJuz}</Text>
                </View>
                <TouchableOpacity
                    onPress={() => setFontScale((s) => Math.max(0.8, +(s - 0.1).toFixed(1)))}
                    hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                >
                    <MaterialCommunityIcons name="format-font-size-decrease" size={QuranLayout.topActionIconSize} color={tc.textPrimary} />
                </TouchableOpacity>
                <View style={{ width: 8 }} />
                <TouchableOpacity
                    onPress={() => setFontScale((s) => Math.min(1.6, +(s + 0.1).toFixed(1)))}
                    hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                >
                    <MaterialCommunityIcons name="format-font-size-increase" size={QuranLayout.topActionIconSize} color={tc.textPrimary} />
                </TouchableOpacity>
                <View style={{ width: 8 }} />
                <TouchableOpacity
                    onPress={() => {
                        const next = !showTranslation;
                        setShowTranslation(next);
                        if (next) fetchTranslationForPage(currentPage);
                    }}
                    hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                >
                    <MaterialCommunityIcons
                        name={showTranslation ? 'translate' : 'translate-off'}
                        size={QuranLayout.topActionIconSize}
                        color={showTranslation ? tc.accent : tc.textPrimary}
                    />
                </TouchableOpacity>
            </View>

            {/* Pager */}
            <View style={{ flex: 1 }}>
                <FlatList
                    ref={flatListRef}
                    data={pages}
                    keyExtractor={(item) => `page-${item}`}
                    horizontal
                    pagingEnabled
                    showsHorizontalScrollIndicator={false}
                    initialScrollIndex={Math.max(0, currentPage - 1)}
                    getItemLayout={(_, index) => ({
                        length: screenWidth,
                        offset: screenWidth * index,
                        index,
                    })}
                    onViewableItemsChanged={onViewableItemsChanged}
                    viewabilityConfig={viewabilityConfig}
                    onMomentumScrollEnd={onMomentumEnd}
                    renderItem={renderPage}
                    onScrollToIndexFailed={() => {}}
                    removeClippedSubviews
                />
            </View>

            {/* Bottom bar */}
            <View style={[styles.bottomBar, {
                backgroundColor: tc.navBar,
                borderColor: tc.cardBorder,
            }]}>
                <TouchableOpacity
                    onPress={goToPrev}
                    disabled={currentPage <= 1}
                    hitSlop={10}
                    style={styles.navBtn}
                >
                    <MaterialCommunityIcons
                        name="chevron-left"
                        size={24}
                        color={currentPage > 1 ? tc.textPrimary : tc.textMuted}
                    />
                </TouchableOpacity>
                <Text style={[typo.body, { fontFamily: interFont('600'), fontSize: 14 }]}>
                    Page {currentPage}
                </Text>
                <TouchableOpacity
                    onPress={goToNext}
                    disabled={currentPage >= TOTAL_PAGES}
                    hitSlop={10}
                    style={styles.navBtn}
                >
                    <MaterialCommunityIcons
                        name="chevron-right"
                        size={24}
                        color={currentPage < TOTAL_PAGES ? tc.textPrimary : tc.textMuted}
                    />
                </TouchableOpacity>
            </View>
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
    retryBtn: {
        height: 34,
        borderRadius: 17,
        borderWidth: 1,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: 14,
    },
    surahHeader: {
        marginBottom: 12,
        paddingHorizontal: 16,
        paddingVertical: 10,
        borderRadius: 14,
        borderWidth: 1,
        flexDirection: 'row',
        alignItems: 'center',
    },
    ayahItem: {
        marginBottom: QuranLayout.ayahItemGap,
        padding: QuranLayout.ayahItemPadding,
        borderRadius: QuranLayout.cardRadius,
        borderWidth: 1,
    },
    ayahBadge: {
        alignSelf: 'flex-start',
        paddingHorizontal: 8,
        paddingVertical: 2,
        borderRadius: 8,
    },
    arabic: {
        fontFamily: 'serif',
        textAlign: 'right',
    },
    bottomBar: {
        marginHorizontal: 20,
        marginBottom: 20,
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: 12,
        paddingVertical: 8,
        borderRadius: SalahLayout.navRadius,
        borderWidth: 1,
    },
    navBtn: {
        width: 48,
        height: 48,
        alignItems: 'center',
        justifyContent: 'center',
    },
});
