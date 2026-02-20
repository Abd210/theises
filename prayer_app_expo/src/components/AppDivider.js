import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Colors } from '../theme/theme';

export default function AppDivider() {
    return <View style={styles.divider} />;
}

const styles = StyleSheet.create({
    divider: {
        height: 1,
        backgroundColor: Colors.cardBorder,
    },
});
