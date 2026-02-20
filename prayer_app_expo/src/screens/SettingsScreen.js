import React, { useState } from 'react';
import { View, Text, TouchableOpacity, ScrollView, StyleSheet, ActivityIndicator, Modal, Dimensions } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { Spacing, SalahLayout, interFont, getTypography } from '../theme/theme';
import { appThemeList } from '../theme/themes';
import { useTheme } from '../providers/ThemeProvider';
import { useLocation } from '../providers/LocationProvider';
import { usePrayerSettings } from '../providers/PrayerSettingsProvider';
import { METHOD_OPTIONS, SCHOOL_OPTIONS, OFFSET_PRAYERS, methodLabel, schoolLabel } from '../services/prayerSettingsService';

const SCREEN_HEIGHT = Dimensions.get('window').height;

export default function SettingsScreen({ onBack }) {
    const { theme: tc, setTheme } = useTheme();
    const { location, detecting, detect } = useLocation();
    const { methodId, school, offsets, setMethodId, setSchool, setOffset } = usePrayerSettings();
    const typo = getTypography(tc);
    const [pickerType, setPickerType] = useState(null); // 'method' | 'school' | null

    const loc = location || {
        city: 'Bucharest', country: 'Romania',
        lat: 44.4268, lon: 26.1025, source: 'default',
    };
    const cityLabel = loc.country
        ? `${loc.city}, ${loc.country}`
        : loc.city;

    const pickerTitle = pickerType === 'method' ? 'Calculation Method' : 'Madhab (Asr)';
    const pickerOptions = pickerType === 'method' ? METHOD_OPTIONS : SCHOOL_OPTIONS;
    const pickerSelectedId = pickerType === 'method' ? methodId : school;
    const pickerOnSelect = pickerType === 'method' ? setMethodId : setSchool;

    return (
        <>
            <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
                {/* Header with back arrow */}
                <View style={{ height: SalahLayout.headerMarginTop }} />
                <View style={styles.header}>
                    <TouchableOpacity onPress={onBack}>
                        <MaterialCommunityIcons name="arrow-left" size={24} color={tc.textPrimary} />
                    </TouchableOpacity>
                    <View style={{ width: Spacing.s12 }} />
                    <Text style={typo.titleMedium}>Settings</Text>
                </View>
                <View style={{ height: Spacing.s24 }} />

                {/* Theme section */}
                <View style={styles.padH}>
                    <Text style={[typo.body, { fontWeight: '600', fontSize: 15 }]}>Theme</Text>
                </View>
                <View style={{ height: Spacing.s12 }} />

                <View style={styles.padH}>
                    <View style={styles.gridRow}>
                        <ThemeCard theme={appThemeList[0]} isSelected={tc.id === appThemeList[0].id} onTap={() => setTheme(appThemeList[0].id)} tc={tc} />
                        <View style={{ width: Spacing.s12 }} />
                        <ThemeCard theme={appThemeList[1]} isSelected={tc.id === appThemeList[1].id} onTap={() => setTheme(appThemeList[1].id)} tc={tc} />
                    </View>
                    <View style={{ height: Spacing.s12 }} />
                    <View style={styles.gridRow}>
                        <ThemeCard theme={appThemeList[2]} isSelected={tc.id === appThemeList[2].id} onTap={() => setTheme(appThemeList[2].id)} tc={tc} />
                        <View style={{ width: Spacing.s12 }} />
                        <ThemeCard theme={appThemeList[3]} isSelected={tc.id === appThemeList[3].id} onTap={() => setTheme(appThemeList[3].id)} tc={tc} />
                    </View>
                </View>
                <View style={{ height: Spacing.s32 }} />

                {/* Location section */}
                <View style={styles.padH}>
                    <Text style={[typo.body, { fontWeight: '600', fontSize: 15 }]}>Location</Text>
                </View>
                <View style={{ height: Spacing.s12 }} />

                <View style={styles.padH}>
                    <View style={[styles.locationCard, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}>
                        <View style={styles.locationRow}>
                            <MaterialCommunityIcons name="map-marker-outline" size={20} color={tc.accent} />
                            <Text style={[styles.locationCity, { color: tc.textPrimary }]} numberOfLines={1}>
                                {cityLabel}
                            </Text>
                            <View style={[styles.sourceBadge, {
                                backgroundColor: loc.source === 'gps' ? tc.accent + '26' : tc.inactive + '26',
                            }]}>
                                <Text style={[styles.sourceBadgeText, {
                                    color: loc.source === 'gps' ? tc.accent : tc.inactive,
                                }]}>
                                    {loc.source === 'gps' ? 'GPS' : 'Default'}
                                </Text>
                            </View>
                        </View>
                        <Text style={[styles.coordsText, { color: tc.textMuted }]}>
                            {loc.lat.toFixed(4)}, {loc.lon.toFixed(4)}
                        </Text>
                        <View style={{ height: Spacing.s12 }} />
                        <TouchableOpacity
                            style={[styles.detectButton, { backgroundColor: tc.accent + '1F' }]}
                            onPress={detect}
                            disabled={detecting}
                            activeOpacity={0.7}
                        >
                            {detecting ? (
                                <ActivityIndicator size="small" color={tc.accent} />
                            ) : (
                                <MaterialCommunityIcons name="crosshairs-gps" size={16} color={tc.accent} />
                            )}
                            <Text style={[styles.detectText, { color: tc.accent }]}>
                                {detecting ? 'Detecting…' : 'Detect location'}
                            </Text>
                        </TouchableOpacity>
                    </View>
                </View>
                <View style={{ height: Spacing.s32 }} />

                {/* Prayer Settings section */}
                <View style={styles.padH}>
                    <Text style={[typo.body, { fontWeight: '600', fontSize: 15 }]}>Prayer Settings</Text>
                </View>
                <View style={{ height: Spacing.s12 }} />

                <View style={styles.padH}>
                    <View style={[styles.locationCard, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}>
                        {/* Method row */}
                        <SettingsRow
                            tc={tc}
                            icon="calculator-variant-outline"
                            label="Calculation Method"
                            value={methodLabel(methodId)}
                            onTap={() => setPickerType('method')}
                        />
                        <View style={[styles.divider, { borderColor: tc.cardBorder }]} />
                        {/* Madhab row */}
                        <SettingsRow
                            tc={tc}
                            icon="hands-pray"
                            label="Madhab (Asr)"
                            value={schoolLabel(school)}
                            onTap={() => setPickerType('school')}
                        />
                    </View>
                </View>
                <View style={{ height: Spacing.s32 }} />

                {/* Time Adjustments section */}
                <View style={styles.padH}>
                    <Text style={[typo.body, { fontWeight: '600', fontSize: 15 }]}>Time Adjustments</Text>
                    <Text style={[typo.caption, { color: tc.textMuted, fontSize: 12 }]}>minutes for each prayer</Text>
                </View>
                <View style={{ height: Spacing.s12 }} />

                <View style={styles.padH}>
                    <View style={[styles.locationCard, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}>
                        {OFFSET_PRAYERS.map((prayer, i) => (
                            <React.Fragment key={prayer}>
                                <OffsetRow
                                    tc={tc}
                                    prayer={prayer}
                                    minutes={offsets[prayer] || 0}
                                    onChanged={(val) => setOffset(prayer, val)}
                                />
                                {i < OFFSET_PRAYERS.length - 1 && (
                                    <View style={[styles.divider, { borderColor: tc.cardBorder }]} />
                                )}
                            </React.Fragment>
                        ))}
                    </View>
                </View>
                <View style={{ height: Spacing.s16 }} />

                {/* Notifications placeholder */}
                <PlaceholderSection tc={tc} title="Notifications" icon="bell-outline" />
                <View style={{ height: SalahLayout.screenPadding }} />
            </ScrollView>

            {/* Option picker modal */}
            <Modal
                visible={pickerType !== null}
                transparent
                animationType="slide"
                onRequestClose={() => setPickerType(null)}
            >
                <TouchableOpacity
                    style={styles.modalOverlay}
                    activeOpacity={1}
                    onPress={() => setPickerType(null)}
                >
                    <View style={[styles.modalSheet, {
                        backgroundColor: (tc.modalBg || tc.card) + 'F5',
                        height: SCREEN_HEIGHT * 0.45
                    }]}>
                        <View style={[styles.modalHandle, { backgroundColor: tc.textMuted + '4D' }]} />
                        <View style={{ paddingHorizontal: 16 }}>
                            <Text style={[typo.titleMedium, { fontSize: 17, marginBottom: 12 }]}>
                                {pickerTitle}
                            </Text>
                        </View>
                        <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 16 }}>
                            {pickerOptions.map((opt) => {
                                const isSelected = opt.id === pickerSelectedId;
                                return (
                                    <TouchableOpacity
                                        key={opt.id}
                                        style={[styles.optionRow, isSelected && { backgroundColor: tc.accent + '1A' }]}
                                        onPress={() => {
                                            pickerOnSelect(opt.id);
                                            setPickerType(null);
                                        }}
                                        activeOpacity={0.7}
                                    >
                                        <Text style={[styles.optionLabel, {
                                            color: isSelected ? tc.accent : tc.textPrimary,
                                            fontWeight: isSelected ? '600' : '400',
                                        }]}>
                                            {opt.label}
                                        </Text>
                                        {isSelected && (
                                            <MaterialCommunityIcons name="check-circle" size={20} color={tc.accent} />
                                        )}
                                    </TouchableOpacity>
                                );
                            })}
                        </ScrollView>
                    </View>
                </TouchableOpacity>
            </Modal>
        </>
    );
}

function OffsetRow({ tc, prayer, minutes, onChanged }) {
    return (
        <View style={styles.offsetRow}>
            <Text style={[styles.settingsRowLabel, { color: tc.textPrimary }]}>{prayer}</Text>
            <View style={styles.counterGroup}>
                <TouchableOpacity
                    style={[styles.counterBtn, { backgroundColor: tc.accent + '26' }]}
                    onPress={() => onChanged(minutes - 1)}
                    activeOpacity={0.7}
                >
                    <MaterialCommunityIcons name="minus" size={16} color={tc.accent} />
                </TouchableOpacity>
                <TouchableOpacity
                    onPress={() => onChanged(0)}
                    activeOpacity={0.7}
                    style={styles.counterValueWrap}
                >
                    <Text style={[styles.counterValue, { color: minutes === 0 ? tc.textMuted : tc.accent }]}>
                        {minutes === 0 ? '0' : (minutes > 0 ? `+${minutes}` : minutes)}
                    </Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={[styles.counterBtn, { backgroundColor: tc.accent + '26' }]}
                    onPress={() => onChanged(minutes + 1)}
                    activeOpacity={0.7}
                >
                    <MaterialCommunityIcons name="plus" size={16} color={tc.accent} />
                </TouchableOpacity>
            </View>
        </View>
    );
}

function SettingsRow({ tc, icon, label, value, onTap }) {
    return (
        <TouchableOpacity style={styles.settingsRow} onPress={onTap} activeOpacity={0.7}>
            <MaterialCommunityIcons name={icon} size={20} color={tc.accent} />
            <View style={{ width: Spacing.s12 }} />
            <Text style={[styles.settingsRowLabel, { color: tc.textPrimary }]}>{label}</Text>
            <Text style={[styles.settingsRowValue, { color: tc.textMuted }]}>{value}</Text>
            <View style={{ width: Spacing.s8 }} />
            <MaterialCommunityIcons name="chevron-right" size={18} color={tc.textMuted} />
        </TouchableOpacity>
    );
}

function ThemeCard({ theme, isSelected, onTap, tc }) {
    return (
        <TouchableOpacity
            style={[styles.themeCard, {
                backgroundColor: tc.card,
                borderColor: isSelected ? tc.accent : tc.cardBorder,
                borderWidth: isSelected ? 2 : 1,
            }]}
            onPress={onTap}
            activeOpacity={0.7}
        >
            <View style={styles.themeCardTop}>
                <View style={styles.swatchWrapper}>
                    <LinearGradient
                        colors={[theme.backgroundStart, theme.backgroundEnd]}
                        start={{ x: 0, y: 0 }}
                        end={{ x: 1, y: 1 }}
                        style={[styles.swatch, { borderColor: tc.cardBorder }]}
                    >
                        <View style={[styles.accentDot, { backgroundColor: theme.accent }]} />
                    </LinearGradient>
                </View>
                {isSelected && (
                    <MaterialCommunityIcons name="check-circle" size={20} color={tc.accent} />
                )}
            </View>
            <View style={styles.spacer} />
            <Text style={[styles.themeName, { color: tc.textPrimary }]}>{theme.name}</Text>
        </TouchableOpacity>
    );
}

function PlaceholderSection({ tc, title, icon }) {
    return (
        <View style={styles.padH}>
            <View style={[styles.placeholder, {
                backgroundColor: tc.card,
                borderColor: tc.cardBorder,
            }]}>
                <MaterialCommunityIcons name={icon} size={20} color={tc.inactive} />
                <Text style={[styles.placeholderTitle, { color: tc.inactive }]}>{title}</Text>
                <View style={styles.spacer} />
                <Text style={[styles.placeholderSub, { color: tc.inactive }]}>Coming soon</Text>
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    scroll: { flex: 1 },
    content: { flexGrow: 1 },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: SalahLayout.screenPadding,
    },
    padH: { paddingHorizontal: SalahLayout.screenPadding },
    gridRow: { flexDirection: 'row' },
    themeCard: {
        flex: 1,
        height: 100,
        padding: Spacing.s12,
        borderRadius: 16,
    },
    themeCardTop: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
    },
    swatchWrapper: {},
    swatch: {
        width: 32,
        height: 32,
        borderRadius: 8,
        borderWidth: 1,
        justifyContent: 'center',
        alignItems: 'center',
    },
    accentDot: {
        width: 10,
        height: 10,
        borderRadius: 5,
    },
    spacer: { flex: 1 },
    themeName: {
        fontFamily: interFont('600'),
        fontSize: 13,
    },
    locationCard: {
        padding: Spacing.s16,
        borderRadius: 16,
        borderWidth: 1,
    },
    locationRow: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    locationCity: {
        fontFamily: interFont('600'),
        fontSize: 15,
        flex: 1,
        marginLeft: Spacing.s8,
    },
    sourceBadge: {
        paddingHorizontal: 8,
        paddingVertical: 3,
        borderRadius: 8,
    },
    sourceBadgeText: {
        fontFamily: interFont('600'),
        fontSize: 11,
    },
    coordsText: {
        fontFamily: interFont('400'),
        fontSize: 12,
        marginTop: Spacing.s8,
    },
    detectButton: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        paddingVertical: 10,
        borderRadius: 10,
    },
    detectText: {
        fontFamily: interFont('600'),
        fontSize: 13,
        marginLeft: Spacing.s8,
    },
    divider: {
        borderBottomWidth: 1,
        marginVertical: Spacing.s12,
    },
    settingsRow: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    settingsRowLabel: {
        fontFamily: interFont('400'),
        fontSize: 14,
        flex: 1,
    },
    settingsRowValue: {
        fontFamily: interFont('500'),
        fontSize: 13,
    },
    modalOverlay: {
        flex: 1,
        justifyContent: 'flex-end',
        backgroundColor: 'rgba(0,0,0,0.35)',
    },
    modalSheet: {
        borderTopLeftRadius: 24,
        borderTopRightRadius: 24,
        paddingTop: 12,
    },
    modalHandle: {
        width: 36,
        height: 4,
        borderRadius: 2,
        alignSelf: 'center',
        marginBottom: 16,
    },
    optionRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingVertical: 14,
        paddingHorizontal: 12,
        borderRadius: 10,
        marginBottom: 4,
    },
    optionLabel: {
        fontFamily: interFont('400'),
        fontSize: 15,
        flex: 1,
    },
    offsetRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
    },
    counterGroup: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    counterBtn: {
        padding: 4,
        borderRadius: 6,
    },
    counterValueWrap: {
        minWidth: 40,
        alignItems: 'center',
    },
    counterValue: {
        fontFamily: interFont('600'),
        fontSize: 13,
    },
    placeholder: {
        flexDirection: 'row',
        alignItems: 'center',
        padding: Spacing.s16,
        borderRadius: 16,
        borderWidth: 1,
    },
    placeholderTitle: {
        fontFamily: interFont('400'),
        fontSize: 14,
        marginLeft: Spacing.s12,
    },
    placeholderSub: {
        fontFamily: interFont('400'),
        fontSize: 12,
    },
});
