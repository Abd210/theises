import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, ActivityIndicator } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import {
    useFonts,
    Inter_400Regular,
    Inter_500Medium,
    Inter_600SemiBold,
    Inter_700Bold,
    Inter_800ExtraBold,
} from '@expo-google-fonts/inter';
import { Colors, Typography } from './src/theme/theme';
import ScreenContainer from './src/components/ScreenContainer';
import BottomNavBar from './src/components/BottomNavBar';
import SalahScreen from './src/screens/SalahScreen';

// ── Disable font scaling globally for benchmark fairness ──
if (Text.defaultProps == null) Text.defaultProps = {};
Text.defaultProps.allowFontScaling = false;
if (TextInput.defaultProps == null) TextInput.defaultProps = {};
TextInput.defaultProps.allowFontScaling = false;

export default function App() {
    const [activeTab, setActiveTab] = useState(0);

    const [fontsLoaded] = useFonts({
        Inter_400Regular,
        Inter_500Medium,
        Inter_600SemiBold,
        Inter_700Bold,
        Inter_800ExtraBold,
    });

    if (!fontsLoaded) {
        return (
            <View style={styles.loading}>
                <ActivityIndicator color={Colors.accentGold} size="large" />
            </View>
        );
    }

    const renderScreen = () => {
        switch (activeTab) {
            case 0:
                return <SalahScreen />;
            default:
                return (
                    <View style={styles.placeholder}>
                        <Text style={Typography.body}>Coming soon</Text>
                    </View>
                );
        }
    };

    return (
        <SafeAreaProvider>
            <StatusBar style="light" />
            <ScreenContainer>
                <View style={styles.content}>{renderScreen()}</View>
                <BottomNavBar activeIndex={activeTab} onTap={setActiveTab} />
            </ScreenContainer>
        </SafeAreaProvider>
    );
}

const styles = StyleSheet.create({
    content: { flex: 1 },
    placeholder: { flex: 1, justifyContent: 'center', alignItems: 'center' },
    loading: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: Colors.backgroundStart,
    },
});
