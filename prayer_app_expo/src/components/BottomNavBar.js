import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Colors, Spacing, SalahLayout, interFont } from '../theme/theme';

const NAV_ITEMS = [
    { icon: 'clock-outline', label: 'Salah' },
    { icon: 'compass-outline', label: 'Qibla' },
    { icon: 'book-open-variant', label: 'Quran' },
    { icon: 'bookshelf', label: 'Azkar' },
];

export default function BottomNavBar({ activeIndex, onTap }) {
    return (
        <View style={styles.bar}>
            {NAV_ITEMS.map((item, i) => {
                const isActive = i === activeIndex;
                return (
                    <TouchableOpacity
                        key={item.label}
                        style={[styles.tab, isActive && styles.activeTab]}
                        onPress={() => onTap(i)}
                        activeOpacity={0.7}
                    >
                        <MaterialCommunityIcons
                            name={item.icon}
                            size={isActive ? SalahLayout.pillIconSize : SalahLayout.navInactiveIconSize}
                            color={isActive ? Colors.backgroundStart : Colors.inactive}
                        />
                        {isActive && (
                            <Text style={styles.activeLabel}>{item.label}</Text>
                        )}
                    </TouchableOpacity>
                );
            })}
        </View>
    );
}

const styles = StyleSheet.create({
    bar: {
        flexDirection: 'row',
        justifyContent: 'space-around',
        alignItems: 'center',
        height: SalahLayout.navHeight,
        marginHorizontal: SalahLayout.navInsetH,
        marginBottom: SalahLayout.navInsetBottom,
        paddingHorizontal: Spacing.s8,
        backgroundColor: Colors.navBar,
        borderRadius: SalahLayout.navRadius,
        borderWidth: 1,
        borderColor: Colors.cardBorder,
    },
    tab: {
        paddingHorizontal: Spacing.s8,
        paddingVertical: Spacing.s8,
    },
    activeTab: {
        flexDirection: 'row',
        alignItems: 'center',
        height: SalahLayout.pillHeight,
        backgroundColor: Colors.accentGold,
        borderRadius: SalahLayout.pillRadius,
        paddingHorizontal: SalahLayout.pillPaddingH,
    },
    activeLabel: {
        fontFamily: interFont('600'),
        fontSize: SalahLayout.pillTextSize,
        color: Colors.backgroundStart,
        marginLeft: Spacing.s8,
    },
});
