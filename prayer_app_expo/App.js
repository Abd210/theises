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
import { getTypography } from './src/theme/theme';
import { ThemeProvider, useTheme } from './src/providers/ThemeProvider';
import { LocationProvider } from './src/providers/LocationProvider';
import { PrayerSettingsProvider } from './src/providers/PrayerSettingsProvider';
import ScreenContainer from './src/components/ScreenContainer';
import BottomNavBar from './src/components/BottomNavBar';
import SalahScreen from './src/screens/SalahScreen';
import QiblaScreen from './src/screens/QiblaScreen';
import SettingsScreen from './src/screens/SettingsScreen';

// ── Disable font scaling globally for benchmark fairness ──
if (Text.defaultProps == null) Text.defaultProps = {};
Text.defaultProps.allowFontScaling = false;
if (TextInput.defaultProps == null) TextInput.defaultProps = {};
TextInput.defaultProps.allowFontScaling = false;

export default function App() {
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
                <ActivityIndicator color="#D4A847" size="large" />
            </View>
        );
    }

    return (
        <SafeAreaProvider>
            <ThemeProvider>
                <LocationProvider>
                    <PrayerSettingsProvider>
                        <AppContent />
                    </PrayerSettingsProvider>
                </LocationProvider>
            </ThemeProvider>
        </SafeAreaProvider>
    );
}

function AppContent() {
    const { theme: tc } = useTheme();
    const typo = getTypography(tc);
    const [activeTab, setActiveTab] = useState(0);
    const [showSettings, setShowSettings] = useState(false);

    const renderScreen = () => {
        if (showSettings) {
            return <SettingsScreen onBack={() => setShowSettings(false)} />;
        }
        switch (activeTab) {
            case 0:
                return <SalahScreen onSettingsTap={() => setShowSettings(true)} />;
            case 1:
                return <QiblaScreen />;
            default:
                return (
                    <View style={styles.placeholder}>
                        <Text style={typo.body}>Coming soon</Text>
                    </View>
                );
        }
    };

    return (
        <>
            <StatusBar style={tc.brightness === 'dark' ? 'light' : 'dark'} />
            <ScreenContainer>
                <View style={styles.content}>{renderScreen()}</View>
                <BottomNavBar
                    activeIndex={activeTab}
                    onTap={(i) => {
                        setActiveTab(i);
                        setShowSettings(false);
                    }}
                />
            </ScreenContainer>
        </>
    );
}

const styles = StyleSheet.create({
    content: { flex: 1 },
    placeholder: { flex: 1, justifyContent: 'center', alignItems: 'center' },
    loading: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#0D0D0D',
    },
});
