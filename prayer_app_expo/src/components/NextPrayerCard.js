import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Colors, Spacing, SalahLayout, Typography, interFont } from '../theme/theme';

export default function NextPrayerCard({ name, countdown, adhanTime }) {
    return (
        <View style={styles.card}>
            {/* Icon box */}
            <View style={styles.iconBox}>
                <MaterialCommunityIcons
                    name="mosque"
                    size={SalahLayout.heroIconSize}
                    color={Colors.backgroundStart}
                />
            </View>
            <View style={styles.gap} />
            {/* Text column */}
            <View style={styles.textCol}>
                <Text style={styles.line1}>
                    Next Prayer: {name.toUpperCase()}
                </Text>
                <View style={styles.countdownRow}>
                    <Text style={styles.startsIn}>Starts in </Text>
                    <Text style={styles.countdown}>{countdown}</Text>
                </View>
                <Text style={styles.line3}>Adhan at {adhanTime}</Text>
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    card: {
        flexDirection: 'row',
        alignItems: 'center',
        alignSelf: 'stretch',
        minHeight: SalahLayout.heroMinHeight,
        padding: SalahLayout.heroPadding,
        backgroundColor: Colors.card,
        borderRadius: SalahLayout.heroRadius,
        borderWidth: SalahLayout.heroBorderWidth,
        borderColor: `rgba(212, 168, 71, ${SalahLayout.heroBorderOpacity})`,
    },
    iconBox: {
        width: SalahLayout.heroIconBoxSize,
        height: SalahLayout.heroIconBoxSize,
        borderRadius: SalahLayout.heroIconBoxRadius,
        backgroundColor: Colors.accentGold,
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
        color: Colors.textPrimary,
    },
    countdownRow: {
        flexDirection: 'row',
        alignItems: 'baseline',
        marginTop: 2,
    },
    startsIn: {
        fontFamily: interFont('400'),
        fontSize: SalahLayout.heroLine1Size,
        color: Colors.textMuted,
    },
    countdown: {
        fontFamily: interFont('700'),
        fontSize: SalahLayout.heroCountdownSize,
        color: Colors.textPrimary,
    },
    line3: {
        fontFamily: interFont('400'),
        fontSize: SalahLayout.heroLine3Size,
        color: Colors.textMuted,
        marginTop: 2,
    },
});
