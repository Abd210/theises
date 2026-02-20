import React from 'react';
import { TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Colors, Radius, SalahLayout } from '../theme/theme';

export default function AppIconButton({ icon, onPress, size, iconSize }) {
    const btnSize = size || SalahLayout.gearButtonSize;
    const icnSize = iconSize || SalahLayout.gearIconSize;

    return (
        <TouchableOpacity
            style={[styles.button, { width: btnSize, height: btnSize }]}
            onPress={onPress}
            activeOpacity={0.7}
        >
            <MaterialCommunityIcons
                name={icon}
                size={icnSize}
                color={Colors.textPrimary}
            />
        </TouchableOpacity>
    );
}

const styles = StyleSheet.create({
    button: {
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: Colors.iconButtonBg,
        borderRadius: Radius.button,
        borderWidth: 1,
        borderColor: Colors.cardBorder,
    },
});
