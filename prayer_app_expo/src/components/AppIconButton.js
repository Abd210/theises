import React from 'react';
import { TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Radius, SalahLayout } from '../theme/theme';
import { useTheme } from '../providers/ThemeProvider';

export default function AppIconButton({ icon, onPress, size, iconSize }) {
    const { theme: tc } = useTheme();
    const btnSize = size || SalahLayout.gearButtonSize;
    const icnSize = iconSize || SalahLayout.gearIconSize;

    return (
        <TouchableOpacity
            style={[styles.button, {
                width: btnSize,
                height: btnSize,
                backgroundColor: tc.iconButtonBg,
                borderColor: tc.cardBorder,
            }]}
            onPress={onPress}
            activeOpacity={0.7}
            hitSlop={{ top: (44 - btnSize) / 2, bottom: (44 - btnSize) / 2, left: (44 - btnSize) / 2, right: (44 - btnSize) / 2 }}
        >
            <MaterialCommunityIcons
                name={icon}
                size={icnSize}
                color={tc.textPrimary}
            />
        </TouchableOpacity>
    );
}

const styles = StyleSheet.create({
    button: {
        justifyContent: 'center',
        alignItems: 'center',
        borderRadius: Radius.button,
        borderWidth: 1,
    },
});
