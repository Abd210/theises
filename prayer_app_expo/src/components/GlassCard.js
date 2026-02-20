import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Spacing, Radius } from '../theme/theme';
import { useTheme } from '../providers/ThemeProvider';

export default function GlassCard({ children, style }) {
    const { theme: tc } = useTheme();
    return (
        <View style={[styles.card, { backgroundColor: tc.card, borderColor: tc.cardBorder }, style]}>
            {children}
        </View>
    );
}

const styles = StyleSheet.create({
    card: {
        padding: Spacing.s16,
        borderRadius: Radius.card,
        borderWidth: 1,
    },
});
