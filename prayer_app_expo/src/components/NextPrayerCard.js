import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Spacing, SalahLayout, interFont } from '../theme/theme';
import { useTheme } from '../providers/ThemeProvider';

export default function NextPrayerCard({ name, countdown, adhanTime }) {
    const { theme: tc } = useTheme();

    // Build dynamic border color with opacity
    const borderColor = hexToRgba(tc.accent, SalahLayout.heroBorderOpacity);

    return (
        <View style={[styles.card, {
            backgroundColor: tc.card,
            borderColor: borderColor,
        }]}>
            {/* Icon box */}
            <View style={[styles.iconBox, { backgroundColor: tc.accent }]}>
                <MaterialCommunityIcons
                    name="mosque"
                    size={SalahLayout.heroIconSize}
                    color={tc.backgroundStart}
                />
            </View>
            <View style={styles.gap} />
            {/* Text column */}
            <View style={styles.textCol}>
                <Text style={[styles.line1, { color: tc.textPrimary }]}>
                    Next Prayer: {name.toUpperCase()}
                </Text>
                <View style={styles.countdownRow}>
                    <Text style={[styles.startsIn, { color: tc.textMuted }]}>Starts in </Text>
                    <Text style={[styles.countdown, { color: tc.textPrimary }]}>{countdown}</Text>
                </View>
                <Text style={[styles.line3, { color: tc.textMuted }]}>Adhan at {adhanTime}</Text>
            </View>
        </View>
    );
}

/** Convert hex color + alpha to rgba string */
function hexToRgba(hex, alpha) {
    const h = hex.replace('#', '');
    const r = parseInt(h.substring(0, 2), 16);
    const g = parseInt(h.substring(2, 4), 16);
    const b = parseInt(h.substring(4, 6), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

const styles = StyleSheet.create({
    card: {
        flexDirection: 'row',
        alignItems: 'center',
        alignSelf: 'stretch',
        minHeight: SalahLayout.heroMinHeight,
        padding: SalahLayout.heroPadding,
        borderRadius: SalahLayout.heroRadius,
        borderWidth: SalahLayout.heroBorderWidth,
    },
    iconBox: {
        width: SalahLayout.heroIconBoxSize,
        height: SalahLayout.heroIconBoxSize,
        borderRadius: SalahLayout.heroIconBoxRadius,
        justifyContent: 'center',
        alignItems: 'center',
    },
    gap: {
        width: SalahLayout.heroIconTextGap,
    },
    textCol: {
        flex: 1,
    },
    line1: {
        fontFamily: interFont('500'),
        fontSize: SalahLayout.heroLine1Size,
    },
    countdownRow: {
        flexDirection: 'row',
        alignItems: 'baseline',
        marginTop: 2,
    },
    startsIn: {
        fontFamily: interFont('400'),
        fontSize: SalahLayout.heroLine1Size,
    },
    countdown: {
        fontFamily: interFont('700'),
        fontSize: SalahLayout.heroCountdownSize,
    },
    line3: {
        fontFamily: interFont('400'),
        fontSize: SalahLayout.heroLine3Size,
        marginTop: 2,
    },
});
