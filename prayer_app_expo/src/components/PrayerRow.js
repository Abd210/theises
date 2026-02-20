import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Colors, SalahLayout, interFont, getPrayerIcon } from '../theme/theme';

export default function PrayerRow({ name, time, isHighlighted = false }) {
    const textColor = isHighlighted ? Colors.accentGold : Colors.textPrimary;
    const iconColor = isHighlighted ? Colors.accentGold : Colors.textMuted;
    const iconName = getPrayerIcon(name);

    return (
        <View style={[styles.row, isHighlighted && styles.highlighted]}>
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

const styles = StyleSheet.create({
    row: {
        flexDirection: 'row',
        alignItems: 'center',
        height: SalahLayout.rowHeight,
        paddingHorizontal: SalahLayout.rowPaddingH,
        borderRadius: SalahLayout.rowRadius,
    },
    highlighted: {
        backgroundColor: Colors.card,
        borderWidth: SalahLayout.rowBorderWidth,
        borderColor: `rgba(212, 168, 71, ${SalahLayout.rowBorderOpacity})`,
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
