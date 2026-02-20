import React from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Colors, Spacing, Radius, Typography, interFont } from '../theme/theme';
import ScreenContainer from '../components/ScreenContainer';
import GlassCard from '../components/GlassCard';
import AppHeader from '../components/AppHeader';
import AppIconButton from '../components/AppIconButton';
import AppDivider from '../components/AppDivider';

export default function DemoScreen() {
    return (
        <ScreenContainer>
            <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
                <AppHeader title="Bucharest" />
                <View style={{ height: Spacing.s24 }} />

                {/* Typography */}
                <Text style={Typography.titleLarge}>Title Large</Text>
                <View style={{ height: Spacing.s8 }} />
                <Text style={Typography.titleMedium}>Title Medium</Text>
                <View style={{ height: Spacing.s8 }} />
                <Text style={Typography.body}>Body text looks like this</Text>
                <View style={{ height: Spacing.s8 }} />
                <Text style={Typography.caption}>Caption text is muted</Text>

                <View style={{ height: Spacing.s24 }} />
                <AppDivider />
                <View style={{ height: Spacing.s24 }} />

                {/* Glass Card */}
                <GlassCard>
                    <Text style={Typography.body}>Next Prayer: MAGHRIB</Text>
                    <View style={{ height: Spacing.s8 }} />
                    <Text style={Typography.titleLarge}>Starts in 02:14:30</Text>
                    <View style={{ height: Spacing.s4 }} />
                    <Text style={Typography.caption}>Adhan at 5:50 PM</Text>
                </GlassCard>

                <View style={{ height: Spacing.s24 }} />

                {/* Button row */}
                <View style={styles.buttonRow}>
                    <AppIconButton icon="cog-outline" onPress={() => { }} />
                    <AppIconButton icon="bell-outline" onPress={() => { }} />
                    <AppIconButton icon="share-variant" onPress={() => { }} />
                </View>

                <View style={{ height: Spacing.s24 }} />

                {/* Color swatches */}
                {[
                    { label: 'backgroundStart', color: Colors.backgroundStart },
                    { label: 'backgroundEnd', color: Colors.backgroundEnd },
                    { label: 'card', color: Colors.card },
                    { label: 'accentGold', color: Colors.accentGold },
                    { label: 'textMuted', color: Colors.textMuted },
                    { label: 'inactive', color: Colors.inactive },
                ].map((s) => (
                    <View key={s.label} style={styles.swatch}>
                        <View style={[styles.swatchBox, { backgroundColor: s.color }]} />
                        <Text style={Typography.body}>{s.label}</Text>
                    </View>
                ))}
            </ScrollView>
        </ScreenContainer>
    );
}

const styles = StyleSheet.create({
    scroll: { flex: 1 },
    content: { padding: Spacing.s16 },
    buttonRow: {
        flexDirection: 'row',
        justifyContent: 'space-evenly',
    },
    swatch: {
        flexDirection: 'row',
        alignItems: 'center',
        marginVertical: Spacing.s4,
    },
    swatchBox: {
        width: 32,
        height: 32,
        borderRadius: 8,
        borderWidth: 1,
        borderColor: Colors.cardBorder,
        marginRight: Spacing.s12,
    },
});
