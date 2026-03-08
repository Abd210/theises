import React, { useState, useEffect, useCallback, useRef } from 'react';
import { View, Text, TouchableOpacity, TextInput, FlatList, StyleSheet, Dimensions } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';
import { useTheme } from '../providers/ThemeProvider';
import { Spacing, AzkarLayout } from '../theme/theme';
import { getTypography, interFont } from '../theme/theme';
import { azkarCategories } from '../data/azkarData';
import AzkarDetailScreen from './AzkarDetailScreen';
import SavedAzkarScreen from './SavedAzkarScreen';

const { width: SCREEN_W } = Dimensions.get('window');

export default function AzkarScreen({ onHideNav }) {
    const { theme: tc } = useTheme();
    const typo = getTypography(tc);
    const [selectedCategory, setSelectedCategory] = useState(null);
    const [selectedInitialIndex, setSelectedInitialIndex] = useState(0);
    const [showSaved, setShowSaved] = useState(false);
    const [lastCategoryKey, setLastCategoryKey] = useState(null);
    const [searchQuery, setSearchQuery] = useState('');
    const [searchResults, setSearchResults] = useState([]);
    const [isSearching, setIsSearching] = useState(false);
    const debounceRef = useRef(null);

    const loadLastCategory = useCallback(async () => {
        try {
            const key = await AsyncStorage.getItem('azkar_last_category');
            setLastCategoryKey(key);
        } catch (_) { /* skip */ }
    }, []);

    useEffect(() => {
        loadLastCategory();
    }, [loadLastCategory]);

    // Hide navbar when detail or saved is open
    useEffect(() => {
        if (onHideNav) onHideNav(!!selectedCategory || showSaved);
    }, [selectedCategory, showSaved, onHideNav]);

    const handleBack = useCallback(() => {
        setSelectedCategory(null);
        setSelectedInitialIndex(0);
        loadLastCategory();
    }, [loadLastCategory]);

    const handleSavedBack = useCallback(() => {
        setShowSaved(false);
    }, []);

    const onSearchChanged = useCallback((query) => {
        setSearchQuery(query);
        if (debounceRef.current) clearTimeout(debounceRef.current);
        debounceRef.current = setTimeout(() => {
            const trimmed = query.trim().toLowerCase();
            if (!trimmed) {
                setSearchResults([]);
                setIsSearching(false);
                return;
            }
            const results = [];
            for (const cat of azkarCategories) {
                for (let i = 0; i < cat.items.length; i++) {
                    const item = cat.items[i];
                    const matchArabic = item.arabic.includes(trimmed) || item.arabic.includes(query.trim());
                    const matchTranslation = item.translation && item.translation.toLowerCase().includes(trimmed);
                    if (matchArabic || matchTranslation) {
                        results.push({ category: cat, index: i, item });
                    }
                }
            }
            setSearchResults(results);
            setIsSearching(true);
        }, 200);
    }, []);

    const clearSearch = useCallback(() => {
        setSearchQuery('');
        setSearchResults([]);
        setIsSearching(false);
    }, []);

    if (showSaved) {
        return (
            <SavedAzkarScreen
                onBack={handleSavedBack}
                onOpenItem={(cat, idx) => {
                    setShowSaved(false);
                    setSelectedInitialIndex(idx);
                    setSelectedCategory(cat);
                }}
            />
        );
    }

    if (selectedCategory) {
        return (
            <AzkarDetailScreen
                category={selectedCategory}
                onBack={handleBack}
                propInitialIndex={selectedInitialIndex}
            />
        );
    }

    const cardWidth = (SCREEN_W - AzkarLayout.screenPadding * 2 - AzkarLayout.gridSpacing) / 2;

    const lastCategory = lastCategoryKey
        ? azkarCategories.find((c) => c.id === lastCategoryKey)
        : null;

    const renderCategory = ({ item }) => (
        <TouchableOpacity
            activeOpacity={0.7}
            onPress={() => {
                setSelectedInitialIndex(0);
                setSelectedCategory(item);
            }}
            style={[styles.card, {
                width: cardWidth,
                backgroundColor: tc.card,
                borderColor: tc.cardBorder,
            }]}
        >
            <View style={[styles.iconBox, { backgroundColor: tc.accent + '1F' }]}>
                <Icon name={item.icon} size={AzkarLayout.gridIconSize} color={tc.accent} />
            </View>
            <View style={styles.cardBottom}>
                <Text style={[styles.cardTitle, { color: tc.textPrimary }]}>{item.title}</Text>
                <View style={styles.subtitleRow}>
                    <Text style={[styles.cardSub, { color: tc.textMuted }]} numberOfLines={1}>
                        {item.subtitle}
                    </Text>
                    <Icon name="chevron-right" size={AzkarLayout.gridArrowSize} color={tc.textMuted} />
                </View>
            </View>
        </TouchableOpacity>
    );

    const renderSearchResult = ({ item: r }) => {
        const preview = r.item.arabic.replace(/\n/g, ' ');
        const previewText = preview.length > 60 ? preview.substring(0, 60) + '…' : preview;
        return (
            <TouchableOpacity
                activeOpacity={0.7}
                onPress={() => {
                    clearSearch();
                    setSelectedInitialIndex(r.index);
                    setSelectedCategory(r.category);
                }}
                style={[styles.resultCard, {
                    backgroundColor: tc.card,
                    borderColor: tc.cardBorder,
                }]}
            >
                <Text style={[styles.resultCategory, { color: tc.textMuted }]}>{r.category.title}</Text>
                <View style={{ height: 6 }} />
                <Text
                    style={[styles.resultPreview, { color: tc.textPrimary }]}
                    numberOfLines={2}
                >{previewText}</Text>
                {r.item.translation ? (
                    <>
                        <View style={{ height: 4 }} />
                        <Text style={[styles.resultTranslation, { color: tc.textMuted }]}>
                            {r.item.translation}
                        </Text>
                    </>
                ) : null}
            </TouchableOpacity>
        );
    };

    return (
        <FlatList
            data={isSearching ? [] : azkarCategories}
            keyExtractor={(item) => item.id}
            numColumns={isSearching ? 1 : 2}
            key={isSearching ? 'search' : 'grid'}
            columnWrapperStyle={isSearching ? undefined : styles.row}
            contentContainerStyle={{ paddingHorizontal: AzkarLayout.screenPadding }}
            ListHeaderComponent={
                <View>
                    <View style={{ height: AzkarLayout.titleMarginTop }} />
                    <Text style={typo.titleLarge}>Azkar</Text>
                    <View style={{ height: 4 }} />
                    <Text style={[styles.subtitle, { color: tc.textMuted }]}>
                        114 Surahs · Read & Reflect
                    </Text>
                    <View style={{ height: Spacing.s16 }} />
                    <View style={styles.searchRow}>
                        <View style={[styles.searchBar, {
                            backgroundColor: tc.card,
                            borderColor: tc.cardBorder,
                        }]}>
                            <Icon name="magnify" size={AzkarLayout.searchIconSize} color={tc.textMuted} />
                            <TextInput
                                value={searchQuery}
                                onChangeText={onSearchChanged}
                                placeholder="Search azkar..."
                                placeholderTextColor={tc.textMuted}
                                style={[styles.searchInput, { color: tc.textPrimary }]}
                            />
                            {searchQuery ? (
                                <TouchableOpacity onPress={clearSearch} hitSlop={8}>
                                    <Icon name="close" size={18} color={tc.textMuted} />
                                </TouchableOpacity>
                            ) : null}
                        </View>
                        <TouchableOpacity
                            onPress={() => setShowSaved(true)}
                            style={[styles.bookmarkBtn, {
                                backgroundColor: tc.card,
                                borderColor: tc.cardBorder,
                            }]}
                        >
                            <Icon name="bookmark-outline" size={20} color={tc.textMuted} />
                        </TouchableOpacity>
                    </View>
                    <View style={{ height: Spacing.s16 }} />

                    {isSearching ? (
                        searchResults.length === 0 ? (
                            <View style={{ paddingVertical: 40, alignItems: 'center' }}>
                                <Text style={[styles.emptyText, { color: tc.textMuted }]}>
                                    No results found.
                                </Text>
                            </View>
                        ) : (
                            <View>
                                <Text style={[styles.resultCount, { color: tc.textMuted }]}>
                                    {searchResults.length} result{searchResults.length === 1 ? '' : 's'}
                                </Text>
                                <View style={{ height: 8 }} />
                                {searchResults.map((r, i) => (
                                    <View key={`${r.category.id}:${r.index}`} style={{ marginBottom: AzkarLayout.listCardSpacing }}>
                                        {renderSearchResult({ item: r })}
                                    </View>
                                ))}
                                <View style={{ height: Spacing.s32 }} />
                            </View>
                        )
                    ) : (
                        <View>
                            {lastCategory && (
                                <TouchableOpacity
                                    activeOpacity={0.7}
                                    onPress={() => {
                                        setSelectedInitialIndex(0);
                                        setSelectedCategory(lastCategory);
                                    }}
                                    style={[styles.resumeCard, {
                                        backgroundColor: tc.accent + '14',
                                        borderColor: tc.accent + '33',
                                    }]}
                                >
                                    <Icon name="play-circle-outline" size={20} color={tc.accent} />
                                    <Text style={[typo.body, {
                                        fontFamily: interFont('600'),
                                        fontSize: 14,
                                        flex: 1,
                                        marginLeft: 10,
                                    }]}>
                                        Resume: {lastCategory.title}
                                    </Text>
                                    <Icon name="chevron-right" size={20} color={tc.accent} />
                                </TouchableOpacity>
                            )}
                            <View style={{ height: Spacing.s8 }} />
                        </View>
                    )}
                </View>
            }
            renderItem={isSearching ? null : renderCategory}
            ListFooterComponent={<View style={{ height: Spacing.s32 }} />}
        />
    );
}

const styles = StyleSheet.create({
    subtitle: {
        fontFamily: interFont('400'),
        fontSize: AzkarLayout.subtitleSize,
    },
    searchRow: {
        flexDirection: 'row',
        gap: 12,
    },
    searchBar: {
        flex: 1,
        height: AzkarLayout.searchHeight,
        borderRadius: AzkarLayout.searchRadius,
        borderWidth: 1,
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 12,
        gap: 8,
    },
    searchInput: {
        flex: 1,
        fontFamily: interFont('400'),
        fontSize: AzkarLayout.searchFontSize,
        padding: 0,
        margin: 0,
    },
    bookmarkBtn: {
        width: AzkarLayout.searchHeight,
        height: AzkarLayout.searchHeight,
        borderRadius: AzkarLayout.searchRadius,
        borderWidth: 1,
        justifyContent: 'center',
        alignItems: 'center',
    },
    row: {
        gap: AzkarLayout.gridSpacing,
        marginBottom: AzkarLayout.gridSpacing,
    },
    card: {
        padding: AzkarLayout.gridCardPadding,
        borderRadius: AzkarLayout.gridCardRadius,
        borderWidth: 1,
        aspectRatio: 1 / 0.95,
    },
    iconBox: {
        width: 44,
        height: 44,
        borderRadius: 12,
        justifyContent: 'center',
        alignItems: 'center',
    },
    cardBottom: {
        flex: 1,
        justifyContent: 'flex-end',
    },
    cardTitle: {
        fontFamily: interFont('600'),
        fontSize: AzkarLayout.gridTitleSize,
    },
    subtitleRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginTop: 2,
    },
    cardSub: {
        fontFamily: interFont('400'),
        fontSize: AzkarLayout.gridSubtitleSize,
        flex: 1,
    },
    resumeCard: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 14,
        paddingVertical: 12,
        borderRadius: 14,
        borderWidth: 1,
    },
    resultCard: {
        padding: AzkarLayout.listCardPadding,
        borderRadius: AzkarLayout.gridCardRadius,
        borderWidth: 1,
    },
    resultCategory: {
        fontFamily: interFont('400'),
        fontSize: 11,
    },
    resultPreview: {
        fontSize: 15,
        lineHeight: 15 * 1.6,
        writingDirection: 'rtl',
        textAlign: 'right',
    },
    resultTranslation: {
        fontFamily: interFont('400'),
        fontSize: 12,
    },
    resultCount: {
        fontFamily: interFont('400'),
        fontSize: 12,
    },
    emptyText: {
        fontFamily: interFont('400'),
        fontSize: 14,
    },
});
