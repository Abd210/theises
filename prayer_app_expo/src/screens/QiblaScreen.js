import React, { useState, useEffect, useRef, useCallback } from 'react';
import { View, Text, ScrollView, StyleSheet, Animated } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import Svg, { Circle, Line, Polygon, Rect, Text as SvgText } from 'react-native-svg';
import * as Location from 'expo-location';
import { Spacing, QiblaLayout, interFont, getTypography } from '../theme/theme';
import { useTheme } from '../providers/ThemeProvider';
import { useLocation } from '../providers/LocationProvider';
import { computeQiblaDegrees } from '../services/qiblaService';

const SMOOTH_ALPHA = 0.4;
const ANIM_DURATION = 50;
const TEXT_THROTTLE_MS = 200; // only re-render for text updates this often

// Arrow points UP at 0° rotation — no baseline correction needed
const ARROW_BASELINE_DEG = 0;

// ── Angle helpers ──
function normalizeAngle(a) {
    return ((a % 360) + 360) % 360;
}
function shortestDiff(from, to) {
    let diff = normalizeAngle(to - from);
    if (diff > 180) diff -= 360;
    return diff; // -180..180
}

export default function QiblaScreen() {
    const { theme: tc } = useTheme();
    const { location } = useLocation();
    const typo = getTypography(tc);

    const loc = location || {
        city: 'Bucharest', country: 'Romania',
        lat: 44.4268, lon: 26.1025, source: 'default',
    };
    const cityLabel = loc.country ? `${loc.city}, ${loc.country}` : loc.city;
    const degrees = computeQiblaDegrees(loc.lat, loc.lon);

    // heading state is only used for direction text — throttled, not per-update
    const [heading, setHeading] = useState(null);
    const [compassAvailable, setCompassAvailable] = useState(true);

    // Refs for high-frequency sensor path (no re-renders)
    const smoothedRef = useRef(null);
    const animatedRotation = useRef(new Animated.Value(0)).current;
    const cumulativeRotRef = useRef(0);
    const prevSmoothedRef = useRef(null);
    const lastTextUpdateRef = useRef(0);

    // Update frequency tracking (first 5 seconds)
    const freqStartRef = useRef(null);
    const freqCountRef = useRef(0);
    const freqLoggedRef = useRef(false);

    useEffect(() => {
        let sub;
        (async () => {
            const { status } = await Location.requestForegroundPermissionsAsync();
            if (status !== 'granted') {
                setCompassAvailable(false);
                console.log('[Qibla] Location permission denied');
                return;
            }

            sub = await Location.watchHeadingAsync((headingData) => {
                const rawHeading = (headingData.trueHeading >= 0)
                    ? headingData.trueHeading
                    : headingData.magHeading;
                if (rawHeading < 0) return;

                const now = Date.now();

                // ── Update frequency tracking (first 5s) ──
                if (freqStartRef.current === null) freqStartRef.current = now;
                freqCountRef.current++;
                const elapsed = now - freqStartRef.current;
                if (elapsed >= 5000 && !freqLoggedRef.current) {
                    const hz = (freqCountRef.current / (elapsed / 1000)).toFixed(1);
                    console.log(`[Qibla] Update rate: ${hz} Hz (${freqCountRef.current} updates in ${(elapsed / 1000).toFixed(1)}s)`);
                    freqLoggedRef.current = true;
                }

                // ── Smoothing (high-frequency, no setState) ──
                if (smoothedRef.current === null) {
                    smoothedRef.current = rawHeading;
                } else {
                    const diff = shortestDiff(smoothedRef.current, rawHeading);
                    smoothedRef.current = normalizeAngle(smoothedRef.current + diff * SMOOTH_ALPHA);
                }

                const smoothed = smoothedRef.current;

                // ── Cumulative rotation → Animated.Value (no re-render) ──
                if (prevSmoothedRef.current === null) {
                    cumulativeRotRef.current = -smoothed;
                } else {
                    const rotDiff = shortestDiff(prevSmoothedRef.current, smoothed);
                    cumulativeRotRef.current -= rotDiff;
                }
                prevSmoothedRef.current = smoothed;

                Animated.timing(animatedRotation, {
                    toValue: cumulativeRotRef.current,
                    duration: ANIM_DURATION,
                    useNativeDriver: true,
                }).start();

                // ── Throttled setState for text/debug only ──
                if (now - lastTextUpdateRef.current >= TEXT_THROTTLE_MS) {
                    lastTextUpdateRef.current = now;
                    setHeading(Math.round(smoothed * 10) / 10);
                }
            });
            console.log('[Qibla] Location heading subscription started');
        })();
        return () => { if (sub) sub.remove(); };
    }, []);

    // Direction guidance (only re-computed on throttled heading updates)
    let statusText = '';
    let facingQibla = false;
    if (compassAvailable && heading !== null) {
        const diff = shortestDiff(heading, degrees);
        if (Math.abs(diff) < 5) {
            statusText = 'Facing Qibla ✓';
            facingQibla = true;
        } else if (diff > 0) {
            statusText = 'Turn right to face Qibla';
        } else {
            statusText = 'Turn left to face Qibla';
        }
    }

    const hasHeading = compassAvailable && heading !== null;
    const animatedStyle = {
        transform: [{
            rotate: animatedRotation.interpolate({
                inputRange: [-3600, 3600],
                outputRange: ['-3600deg', '3600deg'],
            })
        }],
    };

    // Debug delta for overlay
    const debugDelta = hasHeading ? normalizeAngle(degrees - heading).toFixed(1) : '--';

    return (
        <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
            <View style={{ height: QiblaLayout.titleMarginTop }} />

            {/* Title */}
            <View style={styles.padH}>
                <Text style={typo.titleMedium}>Qibla</Text>
            </View>
            <View style={{ height: Spacing.s16 }} />

            {/* City row */}
            <View style={styles.cityRow}>
                <MaterialCommunityIcons name="map-marker" size={QiblaLayout.cityIconSize} color={tc.accent} />
                <View style={{ width: 4 }} />
                <Text style={{
                    fontFamily: interFont('500'),
                    fontSize: QiblaLayout.cityFontSize,
                    color: tc.textMuted,
                }}>{cityLabel}</Text>
            </View>
            <View style={{ height: Spacing.s24 }} />

            {/* Big degree */}
            <Text style={[styles.degreeText, { color: tc.accent }]}>{degrees.toFixed(1)}°</Text>
            <Text style={[styles.degreeSubtitle, { color: tc.textMuted }]}>from North</Text>
            <View style={{ height: Spacing.s24 }} />

            {/* Compass dial */}
            <View style={styles.compassBox}>
                {/* Fixed pointer triangle at top */}
                {hasHeading && (
                    <View style={styles.pointerContainer}>
                        <Svg width={QiblaLayout.pointerSize} height={QiblaLayout.pointerSize}>
                            <Polygon
                                points={`${QiblaLayout.pointerSize / 2},${QiblaLayout.pointerSize} 0,0 ${QiblaLayout.pointerSize},0`}
                                fill={tc.accent}
                            />
                        </Svg>
                    </View>
                )}
                <Animated.View style={hasHeading ? animatedStyle : undefined}>
                    <CompassDial degrees={degrees} tc={tc} showPointer={!hasHeading} />
                </Animated.View>
            </View>

            {/* Debug overlay (temporary) */}
            {hasHeading && (
                <View style={[styles.debugOverlay, { backgroundColor: tc.card, borderColor: tc.cardBorder }]}>
                    <Text style={{ fontFamily: interFont('400'), fontSize: 11, color: tc.textMuted }}>
                        heading={heading}° | qibla={degrees}° | delta={debugDelta}°
                    </Text>
                </View>
            )}

            {/* Compass not available notice */}
            {!compassAvailable && (
                <>
                    <View style={{ height: Spacing.s8 }} />
                    <View style={styles.padH}>
                        <View style={[styles.unavailableCard, {
                            backgroundColor: tc.card,
                            borderColor: tc.cardBorder,
                        }]}>
                            <MaterialCommunityIcons name="compass-off" size={16} color={tc.textMuted} />
                            <View style={{ width: 8 }} />
                            <Text style={{
                                fontFamily: interFont('500'),
                                fontSize: 12,
                                color: tc.textMuted,
                            }}>Compass not available on this device.</Text>
                        </View>
                    </View>
                </>
            )}
            <View style={{ height: Spacing.s24 }} />

            {/* Status text */}
            <View style={styles.padH}>
                {facingQibla ? (
                    <Text style={[styles.statusText, { color: tc.accent, fontFamily: interFont('600') }]}>
                        {statusText}
                    </Text>
                ) : hasHeading ? (
                    <Text style={[styles.statusText, { color: tc.textMuted }]}>
                        {statusText}
                    </Text>
                ) : (
                    <Text style={[styles.statusText, { color: tc.textMuted }]}>
                        Qibla is at{' '}
                        <Text style={{ color: tc.accent, fontFamily: interFont('600') }}>
                            {degrees.toFixed(1)}°
                        </Text>
                        {' '}from North.
                    </Text>
                )}
            </View>
            <View style={{ height: Spacing.s24 }} />

            {/* Kaaba label card */}
            <View style={styles.padH}>
                <View style={[styles.kaabaCard, {
                    backgroundColor: tc.card,
                    borderColor: tc.cardBorder,
                }]}>
                    <Text style={[styles.arabicText, { color: tc.accent }]}>
                        {'\u0627\u0644\u0643\u0639\u0628\u0629 \u0627\u0644\u0645\u0634\u0631\u0651\u0641\u0629'}
                    </Text>
                    <View style={{ height: 4 }} />
                    <Text style={[styles.translitText, { color: tc.textMuted }]}>
                        Al-Kaaba Al-Musharrafah
                    </Text>
                </View>
            </View>
            <View style={{ height: QiblaLayout.screenPadding }} />
        </ScrollView>
    );
}

// ────────────────────────────────────────────────
// COMPASS DIAL (SVG) — memoized to avoid redraws
// ────────────────────────────────────────────────
const CompassDial = React.memo(function CompassDial({ degrees, tc, showPointer }) {
    const size = QiblaLayout.compassSize;
    const cx = size / 2;
    const cy = size / 2;
    const radius = size / 2 - 20;

    const ticks = [];
    for (let deg = 0; deg < 360; deg += 5) {
        const isMajor = deg % 90 === 0;
        const is30 = deg % 30 === 0;
        const len = isMajor
            ? QiblaLayout.tickLengthMajor
            : (is30 ? QiblaLayout.tickLength + 2 : QiblaLayout.tickLength);
        const rad = (deg - 90) * Math.PI / 180;
        const x1 = cx + radius * Math.cos(rad);
        const y1 = cy + radius * Math.sin(rad);
        const x2 = cx + (radius - len) * Math.cos(rad);
        const y2 = cy + (radius - len) * Math.sin(rad);
        ticks.push(
            <Line
                key={`t${deg}`}
                x1={x1} y1={y1} x2={x2} y2={y2}
                stroke={isMajor || is30 ? tc.textMuted + 'CC' : tc.textMuted + '80'}
                strokeWidth={isMajor || is30 ? 1.5 : 1}
            />
        );
    }

    // Cardinal labels
    const cardinals = [
        { label: 'N', deg: 0 },
        { label: 'E', deg: 90 },
        { label: 'S', deg: 180 },
        { label: 'W', deg: 270 },
    ];
    const labels = cardinals.map(({ label, deg }) => {
        const rad = (deg - 90) * Math.PI / 180;
        const labelR = radius - QiblaLayout.tickLengthMajor - 12;
        const x = cx + labelR * Math.cos(rad);
        const y = cy + labelR * Math.sin(rad);
        const isN = label === 'N';
        return (
            <SvgText
                key={label}
                x={x} y={y + 5}
                textAnchor="middle"
                fontSize={QiblaLayout.cardinalFontSize}
                fontWeight="700"
                fill={isN ? tc.accent : tc.textMuted + '99'}
            >
                {label}
            </SvgText>
        );
    });

    // Pointer triangle at top (only in static mode)
    const pointerY = cy - radius - 4;
    const ps = QiblaLayout.pointerSize;
    const pointerPoints = `${cx},${pointerY} ${cx - ps / 2},${pointerY - ps} ${cx + ps / 2},${pointerY - ps}`;

    // Qibla needle
    const needleRad = (degrees - 90) * Math.PI / 180;
    const needleLen = radius - QiblaLayout.tickLengthMajor - 24;
    const nx = cx + needleLen * Math.cos(needleRad);
    const ny = cy + needleLen * Math.sin(needleRad);

    // Kaaba marker on ring
    const kx = cx + (radius + 2) * Math.cos(needleRad);
    const ky = cy + (radius + 2) * Math.sin(needleRad);
    const ksq = QiblaLayout.kaabaIconSize * 0.55;

    return (
        <Svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
            {/* Outer ring */}
            <Circle
                cx={cx} cy={cy} r={radius}
                stroke={tc.cardBorder} strokeWidth={QiblaLayout.compassStroke}
                fill="none"
            />
            {/* Ticks */}
            {ticks}
            {/* Labels */}
            {labels}
            {/* Pointer triangle (only static mode) */}
            {showPointer && <Polygon points={pointerPoints} fill={tc.accent} />}
            {/* Needle */}
            <Line
                x1={cx} y1={cy} x2={nx} y2={ny}
                stroke={tc.accent} strokeWidth={QiblaLayout.needleWidth}
                strokeLinecap="round"
            />
            {/* Center dot */}
            <Circle cx={cx} cy={cy} r={QiblaLayout.centerDotRadius} fill={tc.accent} />
            {/* Kaaba marker */}
            <Circle cx={kx} cy={ky} r={QiblaLayout.kaabaIconSize / 2 + 3} fill={tc.accent} />
            <Rect
                x={kx - ksq / 2} y={ky - ksq / 2}
                width={ksq} height={ksq}
                fill="#000"
            />
        </Svg>
    );
});

// ────────────────────────────────────────────────
// STYLES
// ────────────────────────────────────────────────
const styles = StyleSheet.create({
    scroll: { flex: 1 },
    content: { paddingBottom: 0 },
    padH: { paddingHorizontal: QiblaLayout.screenPadding },
    cityRow: {
        flexDirection: 'row',
        justifyContent: 'center',
        alignItems: 'center',
    },
    degreeText: {
        fontFamily: interFont('700'),
        fontSize: QiblaLayout.degreeFontSize,
        textAlign: 'center',
        lineHeight: QiblaLayout.degreeFontSize * 1.1,
    },
    degreeSubtitle: {
        fontFamily: interFont('500'),
        fontSize: QiblaLayout.degreeSubtitleSize,
        textAlign: 'center',
    },
    compassBox: {
        alignItems: 'center',
        justifyContent: 'center',
    },
    pointerContainer: {
        position: 'absolute',
        top: 20 - QiblaLayout.pointerSize - 4,
        zIndex: 10,
    },
    debugOverlay: {
        marginTop: 8,
        marginHorizontal: QiblaLayout.screenPadding,
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 8,
        borderWidth: 1,
        alignItems: 'center',
    },
    statusText: {
        fontFamily: interFont('400'),
        fontSize: QiblaLayout.statusFontSize,
        textAlign: 'center',
    },
    unavailableCard: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: 16,
        paddingVertical: 10,
        borderRadius: 12,
        borderWidth: 1,
    },
    kaabaCard: {
        padding: QiblaLayout.cardPadding,
        borderRadius: QiblaLayout.cardRadius,
        borderWidth: 1,
        alignItems: 'center',
    },
    arabicText: {
        fontFamily: interFont('600'),
        fontSize: QiblaLayout.arabicFontSize,
        textAlign: 'center',
    },
    translitText: {
        fontFamily: interFont('500'),
        fontSize: QiblaLayout.translitFontSize,
        textAlign: 'center',
    },
});
