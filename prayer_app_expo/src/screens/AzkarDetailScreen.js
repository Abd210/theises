import React, { useState, useRef, useEffect, useCallback } from 'react';
import {
    View, Text, TouchableOpacity, FlatList, ScrollView,
    StyleSheet, Dimensions,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '../providers/ThemeProvider';
import { Spacing, AzkarLayout } from '../theme/theme';
import { getTypography, interFont } from '../theme/theme';

const { width: SCREEN_W } = Dimensions.get('window');
const CARD_WIDTH = SCREEN_W;
const CARD_MAX_W = SCREEN_W - AzkarLayout.screenPadding * 2;

// ════════════════════════════════════════════════════════════
// AzkarCardsPager — horizontal paging FlatList (Cards mode)
// ════════════════════════════════════════════════════════════
function AzkarCardsPager({ items, counters, increment, reset, currentIndex, initialIndex, onPageChange, tc, bottomInset }) {
    const flatListRef = useRef(null);

    const renderCard = useCallback(({ item, index }) => {
        const count = counters[index];
        const done = count >= item.repeatCount;
        return (
            <View style={{ width: CARD_WIDTH, paddingHorizontal: AzkarLayout.screenPadding, paddingBottom: bottomInset }}>
                <View style={[styles.card, {
                    backgroundColor: tc.card,
                    borderColor: done ? tc.accent + 'B3' : tc.cardBorder,
                }]}>
                    <TouchableOpacity
                        activeOpacity={0.8}
                        onPress={() => increment(index)}
                        style={{ flex: 1 }}
                    >
                        <ScrollView
                            style={styles.cardScroll}
                            contentContainerStyle={styles.cardContent}
                        >
                            {done && (
                                <View style={[styles.completedBadge, {
                                    backgroundColor: tc.accent + '26',
                                }]}>
                                    <Text style={[styles.completedText, {
                                        color: tc.accent,
                                    }]}>Completed ✓</Text>
                                </View>
                            )}
                            <Text style={[styles.arabic, { color: tc.textPrimary }]}>
                                {item.arabic}
                            </Text>
                            {item.translation ? (
                                <Text style={[styles.translation, { color: tc.textMuted }]}>
                                    {item.translation}
                                </Text>
                            ) : null}
                        </ScrollView>
                    </TouchableOpacity>

                    {/* Counter footer */}
                    <View style={[styles.counterRow, { borderTopColor: tc.cardBorder }]}>
                        <TouchableOpacity
                            onPress={() => reset(index)}
                            hitSlop={{ top: 4, bottom: 4, left: 4, right: 4 }}
                            style={[styles.resetBtn, {
                                backgroundColor: tc.card,
                                borderColor: tc.cardBorder,
                            }]}
                        >
                            <Icon name="refresh" size={18} color={tc.textMuted} />
                        </TouchableOpacity>
                        <Text style={[styles.counterText, {
                            color: done ? tc.accent : tc.textPrimary,
                        }]}>
                            {count} / {item.repeatCount}
                        </Text>
                        <TouchableOpacity
                            onPress={() => increment(index)}
                            style={[styles.addBtn, {
                                backgroundColor: tc.accent + '26',
                            }]}
                        >
                            <Icon name="plus" size={24} color={tc.accent} />
                        </TouchableOpacity>
                    </View>
                </View>
            </View>
        );
    }, [counters, tc, increment, reset]);

    return (
        <FlatList
            ref={flatListRef}
            data={items}
            horizontal
            pagingEnabled
            showsHorizontalScrollIndicator={false}
            keyExtractor={(_, i) => `card-${i}`}
            renderItem={renderCard}
            initialScrollIndex={initialIndex || 0}
            getItemLayout={(_, index) => ({
                length: CARD_WIDTH,
                offset: CARD_WIDTH * index,
                index,
            })}
            onScrollToIndexFailed={(info) => {
                setTimeout(() => {
                    flatListRef.current?.scrollToIndex({ index: info.index, animated: false });
                }, 100);
            }}
            onMomentumScrollEnd={(e) => {
                const idx = Math.round(e.nativeEvent.contentOffset.x / CARD_WIDTH);
                onPageChange(idx);
            }}
        />
    );
}

// ════════════════════════════════════════════════════════════
// AzkarListView — vertical list (List mode)
// ════════════════════════════════════════════════════════════
function AzkarListView({ items, counters, increment, tc, bottomInset }) {
    const renderListItem = useCallback(({ item, index }) => {
        const count = counters[index];
        const done = count >= item.repeatCount;
        return (
            <TouchableOpacity
                activeOpacity={0.7}
                onPress={() => increment(index)}
                style={[styles.listItem, {
                    backgroundColor: tc.card,
                    borderColor: done ? tc.accent + 'B3' : tc.cardBorder,
                }]}
            >
                <Text style={[styles.listArabic, { color: tc.textPrimary }]}>
                    {item.arabic}
                </Text>
                <View style={{ height: 8 }} />
                <View style={styles.listBottom}>
                    {item.translation ? (
                        <Text
                            style={[styles.listTranslation, { color: tc.textMuted }]}
                            numberOfLines={1}
                        >
                            {item.translation}
                        </Text>
                    ) : <View style={{ flex: 1 }} />}
                    <Text style={[styles.listCounter, {
                        color: done ? tc.accent : tc.textMuted,
                    }]}>
                        {count} / {item.repeatCount}
                    </Text>
                </View>
            </TouchableOpacity>
        );
    }, [counters, tc, increment]);

    return (
        <FlatList
            data={items}
            keyExtractor={(_, i) => `list-${i}`}
            renderItem={renderListItem}
            contentContainerStyle={{
                paddingHorizontal: AzkarLayout.screenPadding,
                paddingBottom: bottomInset + AzkarLayout.footerBottomInset,
            }}
            ItemSeparatorComponent={() => <View style={{ height: AzkarLayout.listCardSpacing }} />}
        />
    );
}

// ════════════════════════════════════════════════════════════
// AzkarDetailScreen — parent orchestrator
// ════════════════════════════════════════════════════════════
export default function AzkarDetailScreen({ category, onBack }) {
    const { theme: tc } = useTheme();
    const typo = getTypography(tc);
    const insets = useSafeAreaInsets();
    const items = category.items;

    const [viewMode, setViewMode] = useState(0);
    const [currentIndex, setCurrentIndex] = useState(0);
    const [initialIndex, setInitialIndex] = useState(0);
    const [counters, setCounters] = useState(() => items.map(() => 0));
    const [progressLoaded, setProgressLoaded] = useState(false);
    const currentIndexRef = useRef(0);

    useEffect(() => {
        console.log(`[AzkarData] categoryKey=${category.id}, itemCount=${items.length}`);
        AsyncStorage.setItem('azkar_last_category', category.id).catch(() => {});
    }, [category.id, items.length]);

    useEffect(() => {
        (async () => {
            try {
                const raw = await AsyncStorage.getItem(`azkar_${category.id}`);
                if (raw) {
                    const data = JSON.parse(raw);
                    if (data.counters) {
                        setCounters(prev => {
                            const c = [...prev];
                            for (let i = 0; i < data.counters.length && i < c.length; i++) {
                                c[i] = data.counters[i];
                            }
                            return c;
                        });
                    }
                    if (data.lastIndex != null) {
                        const idx = Math.min(data.lastIndex, items.length - 1);
                        currentIndexRef.current = idx;
                        setCurrentIndex(idx);
                        setInitialIndex(idx);
                        console.log(`[AZKAR_RESUME] categoryKey=${category.id} savedLastIndex=${idx} itemsLen=${items.length}`);
                    } else {
                        console.log(`[AZKAR_RESUME] categoryKey=${category.id} savedLastIndex=null itemsLen=${items.length}`);
                    }
                } else {
                    console.log(`[AZKAR_RESUME] categoryKey=${category.id} savedLastIndex=null itemsLen=${items.length}`);
                }
            } catch (_) { /* skip */ }
            setProgressLoaded(true);
        })();
    }, []);

    const saveProgress = useCallback(async (newCounters, newIdx) => {
        try {
            await AsyncStorage.setItem(`azkar_${category.id}`, JSON.stringify({
                counters: newCounters,
                lastIndex: newIdx,
            }));
        } catch (_) { /* skip */ }
    }, [category.id]);

    const increment = useCallback((index) => {
        setCounters(prev => {
            const c = [...prev];
            c[index]++;
            saveProgress(c, currentIndexRef.current);
            return c;
        });
    }, [saveProgress]);

    const reset = useCallback((index) => {
        setCounters(prev => {
            const c = [...prev];
            c[index] = 0;
            saveProgress(c, currentIndexRef.current);
            return c;
        });
    }, [saveProgress]);

    const handlePageChange = useCallback((idx) => {
        currentIndexRef.current = idx;
        setCurrentIndex(idx);
        saveProgress(counters, idx);
    }, [counters, saveProgress]);

    return (
        <View style={styles.container}>
            {/* Top bar */}
            <View style={styles.topBar}>
                <TouchableOpacity onPress={onBack} hitSlop={12}>
                    <Icon name="chevron-left" size={28} color={tc.textPrimary} />
                </TouchableOpacity>
                <Text
                    style={[typo.titleMedium, { flex: 1, textAlign: 'center' }]}
                    numberOfLines={1}
                >
                    {category.title}
                </Text>
                <View style={[styles.badge, {
                    backgroundColor: tc.card,
                    borderColor: tc.cardBorder,
                }]}>
                    <Text style={[styles.badgeText, { color: tc.accent }]}>
                        {currentIndex + 1} / {items.length}
                    </Text>
                </View>
            </View>

            {/* Segmented control */}
            <View style={{
                paddingHorizontal: AzkarLayout.screenPadding,
                marginTop: AzkarLayout.topHeaderGap,
                marginBottom: Spacing.s16,
            }}>
                <View style={[styles.segment, {
                    backgroundColor: tc.card,
                    borderColor: tc.cardBorder,
                }]}>
                    {['Cards', 'List'].map((label, i) => {
                        const active = viewMode === i;
                        return (
                            <TouchableOpacity
                                key={label}
                                onPress={() => setViewMode(i)}
                                style={[
                                    styles.segTab,
                                    active && { backgroundColor: tc.accent + '26' },
                                ]}
                            >
                                <Text style={[styles.segText, {
                                    color: active ? tc.accent : tc.textMuted,
                                    fontFamily: interFont(active ? '600' : '400'),
                                }]}>
                                    {label}
                                </Text>
                            </TouchableOpacity>
                        );
                    })}
                </View>
            </View>

            {/* Content */}
            {!progressLoaded ? (
                <View style={styles.center}>
                    <Text style={[typo.caption, { color: tc.textMuted }]}>Loading...</Text>
                </View>
            ) : viewMode === 0 ? (
                <AzkarCardsPager
                    items={items}
                    counters={counters}
                    increment={increment}
                    reset={reset}
                    currentIndex={currentIndex}
                    initialIndex={initialIndex}
                    onPageChange={handlePageChange}
                    tc={tc}
                    bottomInset={insets.bottom}
                />
            ) : (
                <AzkarListView
                    items={items}
                    counters={counters}
                    increment={increment}
                    tc={tc}
                    bottomInset={insets.bottom}
                />
            )}
        </View>
    );
}

// ════════════════════════════════════════════════════════════
const styles = StyleSheet.create({
    container: { flex: 1 },
    center: { flex: 1, justifyContent: 'center', alignItems: 'center' },
    topBar: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 8,
        paddingVertical: 8,
        gap: 8,
    },
    badge: {
        paddingHorizontal: 10,
        paddingVertical: 4,
        borderRadius: 999,
        borderWidth: AzkarLayout.detailCardBorderWidth,
    },
    badgeText: {
        fontFamily: interFont('600'),
        fontSize: 12,
    },
    segment: {
        height: AzkarLayout.segmentHeight,
        borderRadius: AzkarLayout.segmentRadius,
        borderWidth: AzkarLayout.detailCardBorderWidth,
        flexDirection: 'row',
        padding: 3,
    },
    segTab: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        borderRadius: AzkarLayout.segmentRadius - 2,
    },
    segText: {
        fontSize: AzkarLayout.segmentFontSize,
    },
    // Card
    card: {
        flex: 1,
        borderRadius: AzkarLayout.detailCardRadius,
        borderWidth: AzkarLayout.detailCardBorderWidth,
        overflow: 'hidden',
    },
    cardScroll: { flex: 1 },
    cardContent: {
        padding: AzkarLayout.detailCardPadding,
        alignItems: 'center',
    },
    completedBadge: {
        paddingHorizontal: 12,
        paddingVertical: 4,
        borderRadius: 999,
        marginBottom: 12,
    },
    completedText: {
        fontFamily: interFont('600'),
        fontSize: 12,
    },
    arabic: {
        fontSize: AzkarLayout.detailArabicSize,
        lineHeight: AzkarLayout.detailArabicSize * 2,
        textAlign: 'center',
        writingDirection: 'rtl',
    },
    translation: {
        fontFamily: interFont('400'),
        fontSize: AzkarLayout.detailTranslationSize,
        textAlign: 'center',
        marginTop: 16,
    },
    counterRow: {
        height: AzkarLayout.footerHeight,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        borderTopWidth: AzkarLayout.detailCardBorderWidth,
        paddingHorizontal: 20,
        gap: 20,
    },
    resetBtn: {
        width: 36,
        height: 36,
        borderRadius: 18,
        borderWidth: AzkarLayout.detailCardBorderWidth,
        justifyContent: 'center',
        alignItems: 'center',
    },
    counterText: {
        fontFamily: interFont('700'),
        fontSize: AzkarLayout.detailCounterSize,
    },
    addBtn: {
        width: AzkarLayout.detailCounterBtnSize,
        height: AzkarLayout.detailCounterBtnSize,
        borderRadius: AzkarLayout.detailCounterBtnSize / 2,
        justifyContent: 'center',
        alignItems: 'center',
    },
    // List
    listItem: {
        padding: AzkarLayout.listCardPadding,
        borderRadius: AzkarLayout.gridCardRadius,
        borderWidth: AzkarLayout.detailCardBorderWidth,
    },
    listArabic: {
        fontSize: 18,
        lineHeight: 18 * 1.8,
        textAlign: 'right',
        writingDirection: 'rtl',
    },
    listBottom: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    listTranslation: {
        fontFamily: interFont('400'),
        fontSize: 12,
        flex: 1,
    },
    listCounter: {
        fontFamily: interFont('600'),
        fontSize: 13,
    },
});
