import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, TouchableOpacity, FlatList, StyleSheet, Dimensions } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';
import { useTheme } from '../providers/ThemeProvider';
import { Spacing, AzkarLayout } from '../theme/theme';
import { getTypography, interFont } from '../theme/theme';
import { azkarCategories } from '../data/azkarData';
import AzkarDetailScreen from './AzkarDetailScreen';

const { width: SCREEN_W } = Dimensions.get('window');

export default function AzkarScreen({ onHideNav }) {
    const { theme: tc } = useTheme();
    const typo = getTypography(tc);
    const [selectedCategory, setSelectedCategory] = useState(null);
    const [lastCategoryKey, setLastCategoryKey] = useState(null);

    const loadLastCategory = useCallback(async () => {
        try {
            const key = await AsyncStorage.getItem('azkar_last_category');
            setLastCategoryKey(key);
        } catch (_) { /* skip */ }
    }, []);

    useEffect(() => {
        loadLastCategory();
    }, [loadLastCategory]);

    // Hide navbar when detail is open
    useEffect(() => {
        if (onHideNav) onHideNav(!!selectedCategory);
    }, [selectedCategory, onHideNav]);

    // Reload resume state when returning from detail
    const handleBack = useCallback(() => {
        setSelectedCategory(null);
        loadLastCategory();
    }, [loadLastCategory]);

    if (selectedCategory) {
        return (
            <AzkarDetailScreen
                category={selectedCategory}
                onBack={handleBack}
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
            onPress={() => setSelectedCategory(item)}
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

    return (
        <FlatList
            data={azkarCategories}
            keyExtractor={(item) => item.id}
            numColumns={2}
            columnWrapperStyle={styles.row}
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
                            <Text style={[styles.searchText, { color: tc.textMuted }]}>Search azkar...</Text>
                        </View>
                        <View style={[styles.bookmarkBtn, {
                            backgroundColor: tc.card,
                            borderColor: tc.cardBorder,
                        }]}>
                            <Icon name="bookmark-outline" size={20} color={tc.textMuted} />
                        </View>
                    </View>
                    <View style={{ height: Spacing.s16 }} />

                    {/* Resume card */}
                    {lastCategory && (
                        <TouchableOpacity
                            activeOpacity={0.7}
                            onPress={() => setSelectedCategory(lastCategory)}
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
            }
            renderItem={renderCategory}
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
    searchText: {
        fontFamily: interFont('400'),
        fontSize: AzkarLayout.searchFontSize,
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
});
