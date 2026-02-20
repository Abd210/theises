import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { SalahLayout, interFont, getPrayerIcon } from '../theme/theme';
import { useTheme } from '../providers/ThemeProvider';

export default function PrayerRow({ name, time, isHighlighted = false }) {
    const { theme: tc } = useTheme();
    const textColor = isHighlighted ? tc.accent : tc.textPrimary;
    const iconColor = isHighlighted ? tc.accent : tc.textMuted;
    const iconName = getPrayerIcon(name);

    const borderColor = isHighlighted
        ? hexToRgba(tc.accent, SalahLayout.rowBorderOpacity)
        : 'transparent';

    return (
        <View style={[
            styles.row,
            isHighlighted && {
                backgroundColor: tc.card,
                borderWidth: SalahLayout.rowBorderWidth,
                borderColor: borderColor,
            },
        ]}>
            <MaterialCommunityIcons
                name={iconName}
                size={SalahLayout.rowIconSize}
                color={iconColor}
            />
            <Text style={[styles.name, { color: textColor }]}>{name}</Text>
            <View style={styles.spacer} />
            <Text style={[styles.time, { color: textColor }]}>{time}</Text>
        </View>
    );
}

function hexToRgba(hex, alpha) {
    const h = hex.replace('#', '');
    const r = parseInt(h.substring(0, 2), 16);
    const g = parseInt(h.substring(2, 4), 16);
    const b = parseInt(h.substring(4, 6), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

const styles = StyleSheet.create({
    row: {
        flexDirection: 'row',
        alignItems: 'center',
        height: SalahLayout.rowHeight,
        paddingHorizontal: SalahLayout.rowPaddingH,
        borderRadius: SalahLayout.rowRadius,
    },
    name: {
        fontFamily: interFont('500'),
        fontSize: SalahLayout.rowTextSize,
        marginLeft: SalahLayout.rowPaddingH,
    },
    spacer: {
        flex: 1,
    },
    time: {
        fontFamily: interFont('500'),
        fontSize: SalahLayout.rowTextSize,
    },
});
