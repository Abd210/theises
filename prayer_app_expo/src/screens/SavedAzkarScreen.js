import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, TouchableOpacity, FlatList, StyleSheet } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';
import { useTheme } from '../providers/ThemeProvider';
import { AzkarLayout } from '../theme/theme';
import { getTypography, interFont } from '../theme/theme';
import { azkarCategories } from '../data/azkarData';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function SavedAzkarScreen({ onBack, onOpenItem }) {
    const { theme: tc } = useTheme();
    const typo = getTypography(tc);
    const insets = useSafeAreaInsets();
    const [favorites, setFavorites] = useState([]);

    const loadFavorites = useCallback(async () => {
        try {
            const raw = await AsyncStorage.getItem('azkar_favorites_v1');
            if (raw) setFavorites(JSON.parse(raw));
            else setFavorites([]);
        } catch (_) { setFavorites([]); }
    }, []);

    useEffect(() => { loadFavorites(); }, [loadFavorites]);

    const removeFavorite = useCallback(async (index) => {
        const updated = [...favorites];
        updated.splice(index, 1);
        setFavorites(updated);
        try {
            await AsyncStorage.setItem('azkar_favorites_v1', JSON.stringify(updated));
        } catch (_) { /* skip */ }
    }, [favorites]);

    const findCategory = (categoryId) => {
        return azkarCategories.find(c => c.id === categoryId) || null;
    };

    const renderItem = ({ item: fav, index: listIdx }) => {
        const cat = findCategory(fav.categoryId);
        if (!cat || fav.index >= cat.items.length) return null;
        const azkarItem = cat.items[fav.index];
        const preview = azkarItem.arabic.replace(/\n/g, ' ');
        const previewText = preview.length > 60 ? preview.substring(0, 60) + '…' : preview;

        return (
            <TouchableOpacity
                activeOpacity={0.7}
                onPress={() => onOpenItem(cat, fav.index)}
                style={[styles.itemCard, {
                    backgroundColor: tc.card,
                    borderColor: tc.cardBorder,
                }]}
            >
                <View style={{ flex: 1 }}>
                    <Text style={[styles.catLabel, { color: tc.textMuted }]}>{cat.title}</Text>
                    <View style={{ height: 6 }} />
                    <Text
                        style={[styles.previewText, { color: tc.textPrimary }]}
                        numberOfLines={2}
                    >{previewText}</Text>
                    {azkarItem.translation ? (
                        <>
                            <View style={{ height: 4 }} />
                            <Text style={[styles.translation, { color: tc.textMuted }]}>
                                {azkarItem.translation}
                            </Text>
                        </>
                    ) : null}
                </View>
                <View style={{ width: 12 }} />
                <TouchableOpacity onPress={() => removeFavorite(listIdx)} hitSlop={8}>
                    <Icon name="bookmark" size={22} color={tc.accent} />
                </TouchableOpacity>
            </TouchableOpacity>
        );
    };

    return (
        <View style={styles.container}>
            {/* Top bar */}
            <View style={styles.topBar}>
                <TouchableOpacity onPress={onBack} hitSlop={12}>
                    <Icon name="chevron-left" size={28} color={tc.textPrimary} />
                </TouchableOpacity>
                <Text style={[typo.titleMedium, { flex: 1, textAlign: 'center' }]}>
                    Saved Azkar
                </Text>
                <View style={{ width: 48 }} />
            </View>

            {favorites.length === 0 ? (
                <View style={styles.empty}>
                    <Icon name="bookmark-outline" size={48} color={tc.textMuted} />
                    <View style={{ height: 12 }} />
                    <Text style={[styles.emptyText, { color: tc.textMuted }]}>
                        No saved azkar yet.
                    </Text>
                </View>
            ) : (
                <FlatList
                    data={favorites}
                    keyExtractor={(item, i) => `${item.categoryId}:${item.index}:${i}`}
                    renderItem={renderItem}
                    contentContainerStyle={{
                        paddingHorizontal: AzkarLayout.screenPadding,
                        paddingBottom: insets.bottom + AzkarLayout.footerBottomInset,
                    }}
                    ItemSeparatorComponent={() => <View style={{ height: AzkarLayout.listCardSpacing }} />}
                />
            )}
        </View>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1 },
    topBar: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 8,
        paddingVertical: 8,
        gap: 8,
    },
    empty: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
    },
    emptyText: {
        fontFamily: interFont('400'),
        fontSize: 15,
    },
    itemCard: {
        padding: AzkarLayout.listCardPadding,
        borderRadius: AzkarLayout.gridCardRadius,
        borderWidth: 1,
        flexDirection: 'row',
        alignItems: 'center',
    },
    catLabel: {
        fontFamily: interFont('400'),
        fontSize: 11,
    },
    previewText: {
        fontSize: 15,
        lineHeight: 15 * 1.6,
        writingDirection: 'rtl',
        textAlign: 'right',
    },
    translation: {
        fontFamily: interFont('400'),
        fontSize: 12,
    },
});
