import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Colors, Spacing, SalahLayout, Typography, interFont } from '../theme/theme';
import AppIconButton from './AppIconButton';

export default function AppHeader({ title, onSettingsTap }) {
    return (
        <View style={styles.container}>
            <View style={styles.locationRow}>
                <MaterialCommunityIcons
                    name="map-marker"
                    size={SalahLayout.locationIconSize}
                    color={Colors.accentGold}
                />
                <Text style={styles.title}>{title}</Text>
            </View>
            <AppIconButton
                icon="cog-outline"
                size={SalahLayout.gearButtonSize}
                iconSize={SalahLayout.gearIconSize}
                onPress={onSettingsTap || (() => { })}
            />
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: SalahLayout.screenPadding,
    },
    locationRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: Spacing.s8,
    },
    title: {
        fontFamily: interFont('500'),
        fontSize: 16,
        color: Colors.textPrimary,
    },
});
