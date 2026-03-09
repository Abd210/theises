import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
    View, Text, ScrollView, RefreshControl, StyleSheet, ActivityIndicator,
    TouchableOpacity, FlatList, useWindowDimensions,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Spacing, SalahLayout, interFont, getPrayerIcon, getTypography } from '../theme/theme';
import { useTheme } from '../providers/ThemeProvider';
import AppHeader from '../components/AppHeader';
import NextPrayerCard from '../components/NextPrayerCard';
import PrayerRow from '../components/PrayerRow';
import AppDivider from '../components/AppDivider';
import { fetchWeekPrayerTimes, dateKey } from '../services/prayerApi';
import { useLocation } from '../providers/LocationProvider';
import { usePrayerSettings } from '../providers/PrayerSettingsProvider';
import notificationService from '../services/notificationService';

// ── helpers ──
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

function dayLabel(d) {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const target = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    const diff = Math.round((target - today) / 86400000);
    if (diff === 0) return 'Today';
    if (diff === 1) return 'Tomorrow';
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${days[d.getDay()]}, ${months[d.getMonth()]} ${d.getDate()}`;
}

function applyOffsets(timingsObj, offsets) {
    const { mainPrayers, supplementary, gregFormatted, hijriFormatted } = timingsObj;
    const adjusted = mainPrayers.map((p) => {
        const mins = offsets[p.name] || 0;
        if (mins === 0) return { ...p };
        const now2 = new Date();
        const dt = timeToDate(p.time24, now2);
        dt.setMinutes(dt.getMinutes() + mins);
        return {
            ...p,
            time24: `${dt.getHours().toString().padStart(2, '0')}:${dt.getMinutes().toString().padStart(2, '0')}`,
        };
    });
    return { mainPrayers: adjusted, supplementary, gregFormatted, hijriFormatted };
}

export default function SalahScreen({ onSettingsTap }) {
    const { theme: tc } = useTheme();
    const { location } = useLocation();
    const usingDefaultLocationBanner = location?.source === 'default';
    const { methodId, school, offsets, settingsReady } = usePrayerSettings();
    const typo = getTypography(tc);
    const { width: screenWidth } = useWindowDimensions();
    const flatListRef = useRef(null);

    const [weekTimings, setWeekTimings] = useState(null);
    const [error, setError] = useState(null);
    const [offlineCached, setOfflineCached] = useState(false);
    const [loading, setLoading] = useState(true);
    const [selectedDay, setSelectedDay] = useState(0);
    const [, setTick] = useState(0);

    // 7 dates: today..today+6
    const dates = [];
    for (let i = 0; i < 7; i++) {
        const d = new Date();
        d.setDate(d.getDate() + i);
        dates.push(d);
    }
    const dayKeys = dates.map((d) => dateKey(d));

    const load = useCallback(async () => {
        // Gate: don't fetch until location snapshot AND settings are loaded
        if (!location || !settingsReady) {
            if (__DEV__) console.log(`[INIT] waiting... location=${!!location} settingsReady=${settingsReady}`);
            return;
        }
        if (__DEV__) console.log(`[INIT] ready locationReady=true settingsReady=true using source=${location.source} city=${location.city} lat=${location.lat} lon=${location.lon} method=${methodId} school=${school}`);

        setLoading(true);
        setError(null);
        setOfflineCached(false);
        try {
            const result = await fetchWeekPrayerTimes({ loc: location, methodId, school });

            // Apply per-prayer offsets to each day
            const adjusted = {};
            for (const [key, timings] of Object.entries(result.week)) {
                adjusted[key] = applyOffsets(timings, offsets);
            }

            setWeekTimings(adjusted);
            setOfflineCached(!!result.offlineCached);

            // Cache timings for notification scheduling
            const serialized = {};
            for (const [key, timings] of Object.entries(adjusted)) {
                serialized[key] = {
                    prayers: (timings.mainPrayers || []).map(p => ({
                        name: p.name,
                        time24: p.time24,
                    })),
                };
            }
            await notificationService.cacheTimingsForNotifications(serialized);
            notificationService.scheduleFromCache('cache_updated');
        } catch (e) {
            setError('Could not load prayer times. Check internet and retry.');
        } finally {
            setLoading(false);
        }
    }, [location, methodId, school, offsets, settingsReady]);

    useEffect(() => {
        load();
    }, [load]);

    // 1-second countdown tick
    useEffect(() => {
        const id = setInterval(() => setTick((t) => t + 1), 1000);
        return () => clearInterval(id);
    }, []);

    const onViewableItemsChanged = useRef(({ viewableItems }) => {
        if (viewableItems?.length > 0) {
            setSelectedDay(viewableItems[0].index);
        }
    }).current;

    const viewabilityConfig = useRef({ itemVisiblePercentThreshold: 50 }).current;

    if (loading && !weekTimings) {
        return (
            <View style={styles.center}>
                <ActivityIndicator color={tc.accent} size="large" />
            </View>
        );
    }

    if (!weekTimings || Object.keys(weekTimings).length === 0) {
        return (
            <View style={styles.center}>
                <Text style={[typo.caption, { textAlign: 'center', paddingHorizontal: 24 }]}>
                    {error || 'Could not load prayer times. Check internet and retry.'}
                </Text>
                <View style={{ height: Spacing.s16 }} />
                <TouchableOpacity onPress={load} style={[styles.retryButton, { backgroundColor: tc.card }]}>
                    <Text style={[typo.body, { fontSize: 14 }]}>Retry</Text>
                </TouchableOpacity>
            </View>
        );
    }

    const renderFixedDateAndHero = () => {
        if (!weekTimings || !dates[selectedDay]) return null;
        const key = dayKeys[selectedDay];
        const t = weekTimings[key];
        const isToday = selectedDay === 0;
        const now = new Date();

        if (!t) return null;

        // Next prayer
        let nextPrayer = null;
        if (isToday) {
            for (const p of t.mainPrayers) {
                if (timeToDate(p.time24, now) > now) {
                    nextPrayer = p;
                    break;
                }
            }
            if (!nextPrayer) nextPrayer = t.mainPrayers[0];
        } else {
            nextPrayer = t.mainPrayers[0];
        }

        // Countdown (today only)
        let countdown = '—';
        if (isToday) {
            let target = timeToDate(nextPrayer.time24, now);
            if (target <= now) target = new Date(target.getTime() + 86400000);
            const diff = Math.max(0, target - now);
            const hours = Math.floor(diff / 3600000);
            const mins = Math.floor((diff % 3600000) / 60000);
            const secs = Math.floor((diff % 60000) / 1000);
            countdown = `${padTwo(hours)}:${padTwo(mins)}:${padTwo(secs)}`;
        }

        return (
            <View>
                {/* Date row */}
                <View style={{ height: SalahLayout.dateRowMarginTop }} />
                <View style={styles.dateRow}>
                    <Text style={typo.caption}>{t.gregFormatted}</Text>
                    <Text style={[styles.hijriText, { color: tc.accent }]}>{t.hijriFormatted}</Text>
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
            </View>
        );
    };

    const renderDayPage = ({ item: dayIndex }) => {
        const date = dates[dayIndex];
        const key = dayKeys[dayIndex];
        const t = weekTimings[key];
        const isToday = dayIndex === 0;
        const now = new Date();

        if (!t) {
            return (
                <View style={[styles.center, { width: screenWidth }]}>
                    <Text style={typo.caption}>No data for {dayLabel(date)}</Text>
                </View>
            );
        }

        // Next prayer
        let nextPrayer = null;
        if (isToday) {
            for (const p of t.mainPrayers) {
                if (timeToDate(p.time24, now) > now) {
                    nextPrayer = p;
                    break;
                }
            }
            if (!nextPrayer) nextPrayer = t.mainPrayers[0];
        } else {
            nextPrayer = t.mainPrayers[0];
        }

        return (
            <ScrollView
                style={{ width: screenWidth }}
                contentContainerStyle={styles.scrollContent}
            >

                {/* Schedule label */}
                <View style={[styles.row, styles.padH]}>
                    <MaterialCommunityIcons
                        name="calendar-month"
                        size={SalahLayout.scheduleIconSize}
                        color={tc.textMuted}
                    />
                    <Text style={[typo.caption, { marginLeft: Spacing.s8 }]}>
                        {t.gregFormatted}
                    </Text>
                </View>
                <View style={{ height: SalahLayout.scheduleMarginBottom }} />

                {/* Main prayers */}
                {t.mainPrayers.map((p) => (
                    <View key={p.name} style={styles.padH}>
                        <PrayerRow
                            name={p.name}
                            time={formatTo12Hour(p.time24)}
                            isHighlighted={isToday && p.name === nextPrayer.name}
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
                {t.supplementary.map((p) => (
                    <View key={p.name} style={styles.padH}>
                        <PrayerRow
                            name={p.name}
                            time={formatTo12Hour(p.time24)}
                        />
                        <View style={{ height: SalahLayout.rowSpacing }} />
                    </View>
                ))}

                {/* Day dots */}
                <View style={styles.dotsRow}>
                    {[0, 1, 2, 3, 4, 5, 6].map((i) => (
                        <TouchableOpacity
                            key={i}
                            onPress={() => {
                                flatListRef.current?.scrollToIndex({ index: i, animated: true });
                            }}
                        >
                            <View
                                style={[
                                    styles.dot,
                                    {
                                        width: i === selectedDay ? 24 : 8,
                                        backgroundColor: i === selectedDay ? tc.accent : `${tc.textMuted}4D`,
                                    },
                                ]}
                            />
                        </TouchableOpacity>
                    ))}
                </View>

                {/* Day label */}
                <Text style={[typo.body, {
                    fontFamily: interFont('600'),
                    fontSize: 14,
                    textAlign: 'center',
                }]}>
                    {dayLabel(dates[dayIndex])}
                </Text>

                <View style={{ height: SalahLayout.screenPadding }} />
            </ScrollView>
        );
    };

    const dayIndices = [0, 1, 2, 3, 4, 5, 6];

    return (
        <View style={{ flex: 1 }}>
            {/* Header */}
            <View style={{ height: SalahLayout.headerMarginTop }} />
            <AppHeader
                title={location ? (location.country ? `${location.city}, ${location.country}` : location.city) : 'Bucharest'}
                onSettingsTap={onSettingsTap}
                onTestNotification={async () => {
                    const granted = await notificationService.requestPermission();
                    if (granted) await notificationService.sendTestNow();
                }}
            />
            <View style={{ height: SalahLayout.headerMarginBottom }} />

            {/* Default location banner */}
            {usingDefaultLocationBanner && (
                <View style={[styles.infoBanner, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}>
                    <MaterialCommunityIcons name="map-marker-off-outline" size={16} color={tc.textMuted} />
                    <Text style={[typo.caption, { marginLeft: 8 }]}>Using default location</Text>
                </View>
            )}

            {/* Offline cached banner */}
            {offlineCached && (
                <View style={[styles.infoBanner, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}>
                    <MaterialCommunityIcons name="wifi-off" size={16} color={tc.textMuted} />
                    <Text style={[typo.caption, { marginLeft: 8 }]}>Offline (cached)</Text>
                </View>
            )}

            {/* Error */}
            {error && (
                <View style={[styles.errorBanner, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}>
                    <Text style={typo.caption}>{error}</Text>
                </View>
            )}

            {/* Fixed Date & Hero */}
            {renderFixedDateAndHero()}

            {/* Day pager */}
            <FlatList
                ref={flatListRef}
                data={dayIndices}
                keyExtractor={(item) => `day-${item}`}
                horizontal
                pagingEnabled
                showsHorizontalScrollIndicator={false}
                initialScrollIndex={0}
                getItemLayout={(_, index) => ({
                    length: screenWidth,
                    offset: screenWidth * index,
                    index,
                })}
                onViewableItemsChanged={onViewableItemsChanged}
                viewabilityConfig={viewabilityConfig}
                renderItem={renderDayPage}
                onScrollToIndexFailed={() => {}}
                removeClippedSubviews
                refreshControl={
                    <RefreshControl
                        refreshing={loading}
                        onRefresh={load}
                        tintColor={tc.accent}
                    />
                }
            />
        </View>
    );
}

const styles = StyleSheet.create({
    center: { flex: 1, justifyContent: 'center', alignItems: 'center' },
    padH: { paddingHorizontal: SalahLayout.screenPadding },
    scrollContent: { flexGrow: 1 },
    dateRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingHorizontal: SalahLayout.screenPadding,
    },
    hijriText: {
        fontFamily: interFont('600'),
        fontSize: 13,
    },
    row: { flexDirection: 'row', alignItems: 'center' },
    errorBanner: {
        marginHorizontal: SalahLayout.screenPadding,
        padding: Spacing.s8,
        borderRadius: Spacing.s8,
        borderWidth: 1,
    },
    infoBanner: {
        marginHorizontal: SalahLayout.screenPadding,
        marginBottom: Spacing.s8,
        paddingHorizontal: Spacing.s12,
        paddingVertical: Spacing.s8,
        borderRadius: Spacing.s8,
        borderWidth: 1,
        flexDirection: 'row',
        alignItems: 'center',
    },
    retryButton: {
        height: 36,
        borderRadius: 18,
        paddingHorizontal: 18,
        justifyContent: 'center',
        alignItems: 'center',
    },
    dotsRow: {
        flexDirection: 'row',
        justifyContent: 'center',
        alignItems: 'center',
        paddingHorizontal: SalahLayout.screenPadding,
        paddingVertical: Spacing.s8,
    },
    dot: {
        height: 8,
        borderRadius: 4,
        marginHorizontal: 3,
    },
});
