import React from 'react';
import { View, StyleSheet } from 'react-native';
import { useTheme } from '../providers/ThemeProvider';

export default function AppDivider() {
    const { theme: tc } = useTheme();
    return <View style={[styles.divider, { backgroundColor: tc.cardBorder }]} />;
}

const styles = StyleSheet.create({
    divider: {
        height: 1,
    },
});
