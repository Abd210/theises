import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Spacing, SalahLayout, interFont } from '../theme/theme';
import { useTheme } from '../providers/ThemeProvider';

const NAV_ITEMS = [
    { icon: 'clock-outline', label: 'Salah' },
    { icon: 'compass-outline', label: 'Qibla' },
    { icon: 'book-open-variant', label: 'Quran' },
    { icon: 'bookshelf', label: 'Azkar' },
];

export default function BottomNavBar({ activeIndex, onTap }) {
    const { theme: tc } = useTheme();
    return (
        <View style={[styles.bar, {
            backgroundColor: tc.navBar,
            borderColor: tc.cardBorder,
        }]}>
            {NAV_ITEMS.map((item, i) => {
                const isActive = i === activeIndex;
                return (
                    <TouchableOpacity
                        key={item.label}
                        style={[
                            styles.tab,
                            isActive && [styles.activeTab, { backgroundColor: tc.accent }],
                        ]}
                        onPress={() => onTap(i)}
                        activeOpacity={0.7}
                    >
                        <MaterialCommunityIcons
                            name={item.icon}
                            size={isActive ? SalahLayout.pillIconSize : SalahLayout.navInactiveIconSize}
                            color={isActive ? tc.backgroundStart : tc.inactive}
                        />
                        {isActive && (
                            <Text style={[styles.activeLabel, { color: tc.backgroundStart }]}>
                                {item.label}
                            </Text>
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
        borderRadius: SalahLayout.navRadius,
        borderWidth: 1,
    },
    tab: {
        paddingHorizontal: Spacing.s8,
        paddingVertical: Spacing.s8,
    },
    activeTab: {
        flexDirection: 'row',
        alignItems: 'center',
        height: SalahLayout.pillHeight,
        borderRadius: SalahLayout.pillRadius,
        paddingHorizontal: SalahLayout.pillPaddingH,
    },
    activeLabel: {
        fontFamily: interFont('600'),
        fontSize: SalahLayout.pillTextSize,
        marginLeft: Spacing.s8,
    },
});
