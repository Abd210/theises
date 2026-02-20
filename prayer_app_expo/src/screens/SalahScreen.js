import React, { useState, useEffect, useCallback } from 'react';
import {
    View, Text, ScrollView, RefreshControl, StyleSheet, ActivityIndicator,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Colors, Spacing, Typography, SalahLayout, interFont, getPrayerIcon } from '../theme/theme';
import AppHeader from '../components/AppHeader';
import NextPrayerCard from '../components/NextPrayerCard';
import PrayerRow from '../components/PrayerRow';
import AppDivider from '../components/AppDivider';
import { fetchPrayerTimes } from '../services/prayerApi';

// ── helpers ──
function cleanTime(raw) {
    if (!raw) return '00:00';
    return raw.replace(/\s*\(.*\)/, '').trim();
}

function formatTo12Hour(time24) {
    const parts = time24.split(':');
    if (parts.length < 2) return time24;
    let h = parseInt(parts[0], 10) || 0;
    const m = parts[1];
    const ampm = h >= 12 ? 'PM' : 'AM';
    if (h === 0) h = 12;
    else if (h > 12) h -= 12;
    return `${h}:${m} ${ampm}`;
}

function timeToDate(time24, now) {
    const parts = time24.split(':');
    const h = parseInt(parts[0], 10) || 0;
    const m = parseInt(parts[1], 10) || 0;
    return new Date(now.getFullYear(), now.getMonth(), now.getDate(), h, m, 0);
}

function padTwo(n) {
    return n.toString().padStart(2, '0');
}

export default function SalahScreen() {
    const [timings, setTimings] = useState(null);
    const [error, setError] = useState(null);
    const [loading, setLoading] = useState(true);
    const [, setTick] = useState(0);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const json = await fetchPrayerTimes();
            const data = json.data;
            const t = data.timings;
            const hijri = data.date?.hijri;
            const greg = data.date?.gregorian;

            let gregFormatted = '';
            if (greg) {
                gregFormatted = `${greg.weekday?.en || ''}, ${greg.month?.en || ''} ${greg.day || ''}, ${greg.year || ''}`;
            }

            const hijriDay = hijri?.day || '';
            const hijriMonthAr = hijri?.month?.ar || '';
            const hijriYear = hijri?.year || '';
            const hijriFormatted = hijriDay
                ? `\u200E${hijriDay} ${hijriMonthAr} ${hijriYear} هـ`
                : '—';

            const mainPrayers = [
                { name: 'Fajr', time24: cleanTime(t.Fajr) },
                { name: 'Dhuhr', time24: cleanTime(t.Dhuhr) },
                { name: 'Asr', time24: cleanTime(t.Asr) },
                { name: 'Maghrib', time24: cleanTime(t.Maghrib) },
                { name: 'Isha', time24: cleanTime(t.Isha) },
            ];

            const supplementary = [
                { name: 'Sunrise', time24: cleanTime(t.Sunrise) },
                { name: 'Last Third of Night', time24: cleanTime(t.Lastthird) },
            ];

            setTimings({
                mainPrayers,
                supplementary,
                gregFormatted,
                hijriFormatted,
            });
        } catch (e) {
            setError(e.message || 'Unknown error');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    // 1-second countdown tick
    useEffect(() => {
        const id = setInterval(() => setTick((t) => t + 1), 1000);
        return () => clearInterval(id);
    }, []);

    if (loading && !timings) {
        return (
            <View style={styles.center}>
                <ActivityIndicator color={Colors.accentGold} size="large" />
            </View>
        );
    }

    if (!timings) {
        return (
            <View style={styles.center}>
                <Text style={Typography.caption}>{error || 'Unknown error'}</Text>
            </View>
        );
    }

    // Next prayer
    const now = new Date();
    let nextPrayer = null;
    for (const p of timings.mainPrayers) {
        if (timeToDate(p.time24, now) > now) {
            nextPrayer = p;
            break;
        }
    }
    if (!nextPrayer) nextPrayer = timings.mainPrayers[0];

    // Countdown
    let target = timeToDate(nextPrayer.time24, now);
    if (target <= now) {
        target = new Date(target.getTime() + 86400000);
    }
    const diff = Math.max(0, target - now);
    const hours = Math.floor(diff / 3600000);
    const mins = Math.floor((diff % 3600000) / 60000);
    const secs = Math.floor((diff % 60000) / 1000);
    const countdown = `${padTwo(hours)}:${padTwo(mins)}:${padTwo(secs)}`;

    return (
        <ScrollView
            style={styles.scroll}
            contentContainerStyle={styles.scrollContent}
            refreshControl={
                <RefreshControl
                    refreshing={loading}
                    onRefresh={load}
                    tintColor={Colors.accentGold}
                />
            }
        >
            {/* Header */}
            <View style={{ height: SalahLayout.headerMarginTop }} />
            <AppHeader title="Bucharest" />
            <View style={{ height: SalahLayout.headerMarginBottom }} />

            {/* Error */}
            {error && (
                <View style={styles.errorBanner}>
                    <Text style={Typography.caption}>{error}</Text>
                </View>
            )}

            {/* Date row */}
            <View style={{ height: SalahLayout.dateRowMarginTop }} />
            <View style={styles.dateRow}>
                <Text style={Typography.caption}>{timings.gregFormatted}</Text>
                <Text style={styles.hijriText}>{timings.hijriFormatted}</Text>
            </View>
            <View style={{ height: SalahLayout.dateRowMarginBottom }} />

            {/* Hero card */}
            <View style={styles.padH}>
                <NextPrayerCard
                    name={nextPrayer.name}
                    countdown={countdown}
                    adhanTime={formatTo12Hour(nextPrayer.time24)}
                />
            </View>
            <View style={{ height: SalahLayout.heroMarginBottom }} />

            {/* Schedule label */}
            <View style={[styles.row, styles.padH]}>
                <MaterialCommunityIcons
                    name="calendar-month"
                    size={SalahLayout.scheduleIconSize}
                    color={Colors.textMuted}
                />
                <Text style={[Typography.caption, { marginLeft: Spacing.s8 }]}>
                    {timings.gregFormatted}
                </Text>
            </View>
            <View style={{ height: SalahLayout.scheduleMarginBottom }} />

            {/* Main prayers */}
            {timings.mainPrayers.map((p) => (
                <View key={p.name} style={styles.padH}>
                    <PrayerRow
                        name={p.name}
                        time={formatTo12Hour(p.time24)}
                        isHighlighted={p.name === nextPrayer.name}
                    />
                    <View style={{ height: SalahLayout.rowSpacing }} />
                </View>
            ))}

            {/* Divider */}
            <View style={styles.padH}>
                <View style={{ height: SalahLayout.dividerMarginTop }} />
                <AppDivider />
                <View style={{ height: SalahLayout.dividerMarginTop }} />
            </View>

            {/* Supplementary */}
            {timings.supplementary.map((p) => (
                <View key={p.name} style={styles.padH}>
                    <PrayerRow
                        name={p.name}
                        time={formatTo12Hour(p.time24)}
                    />
                    <View style={{ height: SalahLayout.rowSpacing }} />
                </View>
            ))}

            <View style={{ height: SalahLayout.screenPadding }} />
        </ScrollView>
    );
}

const styles = StyleSheet.create({
    scroll: { flex: 1 },
    scrollContent: { flexGrow: 1 },
    center: { flex: 1, justifyContent: 'center', alignItems: 'center' },
    padH: { paddingHorizontal: SalahLayout.screenPadding },
    dateRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingHorizontal: SalahLayout.screenPadding,
    },
    hijriText: {
        fontFamily: interFont('600'),
        fontSize: 13,
        color: Colors.accentGold,
    },
    row: { flexDirection: 'row', alignItems: 'center' },
    errorBanner: {
        marginHorizontal: SalahLayout.screenPadding,
        padding: Spacing.s8,
        backgroundColor: Colors.card,
        borderRadius: Spacing.s8,
    },
});
