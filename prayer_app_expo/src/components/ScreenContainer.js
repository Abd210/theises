import React from 'react';
import { View, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '../providers/ThemeProvider';

export default function ScreenContainer({ children }) {
    const insets = useSafeAreaInsets();
    const { theme: tc } = useTheme();

    return (
        <LinearGradient
            colors={[tc.backgroundStart, tc.backgroundEnd]}
            style={styles.container}
        >
            <View style={[styles.inner, { paddingTop: insets.top }]}>
                {children}
            </View>
        </LinearGradient>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1 },
    inner: { flex: 1 },
});
