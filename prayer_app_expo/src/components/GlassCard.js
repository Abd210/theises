import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Colors, Spacing, Radius } from '../theme/theme';

export default function GlassCard({ children, style }) {
    return (
        <View style={[styles.card, style]}>
            {children}
        </View>
    );
}

const styles = StyleSheet.create({
    card: {
        padding: Spacing.s16,
        backgroundColor: Colors.card,
        borderRadius: Radius.card,
        borderWidth: 1,
        borderColor: Colors.cardBorder,
    },
});
