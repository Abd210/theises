import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Spacing, SalahLayout, interFont } from '../theme/theme';
import { useTheme } from '../providers/ThemeProvider';
import AppIconButton from './AppIconButton';

export default function AppHeader({ title, onSettingsTap, onTestNotification }) {
    const { theme: tc } = useTheme();
    return (
        <View style={styles.container}>
            <View style={styles.locationRow}>
                <MaterialCommunityIcons
                    name="map-marker"
                    size={SalahLayout.locationIconSize}
                    color={tc.accent}
                />
                <Text style={[styles.title, { color: tc.textPrimary }]}>{title}</Text>
            </View>
            <View style={styles.buttonRow}>
                {onTestNotification && (
                    <AppIconButton
                        icon="bell-outline"
                        size={SalahLayout.gearButtonSize}
                        iconSize={SalahLayout.gearIconSize}
                        onPress={onTestNotification}
                    />
                )}
                {onTestNotification && <View style={{ width: 4 }} />}
                <AppIconButton
                    icon="cog-outline"
                    size={SalahLayout.gearButtonSize}
                    iconSize={SalahLayout.gearIconSize}
                    onPress={onSettingsTap || (() => { })}
                />
            </View>
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
    buttonRow: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    title: {
        fontFamily: interFont('500'),
        fontSize: 16,
    },
});

