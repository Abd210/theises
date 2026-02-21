import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../services/location_service.dart';
import '../services/qibla_service.dart';

class QiblaScreen extends StatefulWidget {
  final LocationNotifier locationNotifier;

  const QiblaScreen({super.key, required this.locationNotifier});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading; // smoothed heading in degrees 0..360
  bool _compassAvailable = true;

  static const double _smoothAlpha = 0.2;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  Future<void> _initCompass() async {
    // flutter_compass exposes a nullable stream — null means unavailable
    final stream = FlutterCompass.events;
    if (stream == null) {
      if (mounted) setState(() => _compassAvailable = false);
      debugPrint('[Qibla] Compass not available (stream null)');
      return;
    }

    _compassSub = stream.listen(
      (event) {
        final raw = event.heading;
        if (raw == null) return;
        final normalized = (raw + 360) % 360;
        setState(() {
          if (_heading == null) {
            _heading = normalized;
          } else {
            // Low-pass filter with circular interpolation
            var diff = normalized - _heading!;
            if (diff > 180) diff -= 360;
            if (diff < -180) diff += 360;
            _heading = (_heading! + _smoothAlpha * diff + 360) % 360;
          }
        });
        debugPrint('[Qibla] heading=${_heading!.toStringAsFixed(1)}');
      },
      onError: (_) {
        if (mounted) setState(() => _compassAvailable = false);
        debugPrint('[Qibla] Compass error — marking unavailable');
      },
    );
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;

    return ListenableBuilder(
      listenable: widget.locationNotifier,
      builder: (context, _) {
        final loc = widget.locationNotifier.data;
        final qiblaBearing = computeQiblaDegrees(loc.lat, loc.lon);
        final cityLabel = loc.country.isNotEmpty
            ? '${loc.city}, ${loc.country}'
            : loc.city;

        // Compute direction guidance
        String statusText;
        bool facingQibla = false;
        if (_compassAvailable && _heading != null) {
          var diff = qiblaBearing - _heading!;
          if (diff > 180) diff -= 360;
          if (diff < -180) diff += 360;
          if (diff.abs() < 5) {
            statusText = 'Facing Qibla ✓';
            facingQibla = true;
          } else if (diff > 0) {
            statusText = 'Turn right to face Qibla';
          } else {
            statusText = 'Turn left to face Qibla';
          }
        } else {
          statusText = 'Qibla is at ${qiblaBearing.toStringAsFixed(1)}° from North.';
        }

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: QiblaLayout.titleMarginTop),

            // ── Title ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: QiblaLayout.screenPadding),
              child: Text('Qibla', style: AppTypography.titleMedium(tc)),
            ),
            const SizedBox(height: AppSpacing.s16),

            // ── City row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.mapMarker, color: tc.accent, size: QiblaLayout.cityIconSize),
                const SizedBox(width: 4),
                Text(
                  cityLabel,
                  style: GoogleFonts.inter(
                    fontSize: QiblaLayout.cityFontSize,
                    color: tc.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),

            // ── Big degree ──
            Center(
              child: Text(
                '${qiblaBearing.toStringAsFixed(1)}°',
                style: GoogleFonts.inter(
                  fontSize: QiblaLayout.degreeFontSize,
                  fontWeight: FontWeight.w700,
                  color: tc.accent,
                  height: 1.1,
                ),
              ),
            ),
            Center(
              child: Text(
                'from North',
                style: GoogleFonts.inter(
                  fontSize: QiblaLayout.degreeSubtitleSize,
                  color: tc.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // ── Compass dial or unavailable ──
            if (_compassAvailable && _heading != null) ...[
              Center(
                child: SizedBox(
                  width: QiblaLayout.compassSize,
                  height: QiblaLayout.compassSize,
                  child: Stack(
                    children: [
                      // Pointer triangle stays fixed at top
                      Positioned(
                        left: QiblaLayout.compassSize / 2 - QiblaLayout.pointerSize / 2,
                        top: 20 - QiblaLayout.pointerSize - 4,
                        child: CustomPaint(
                          size: Size(QiblaLayout.pointerSize, QiblaLayout.pointerSize),
                          painter: _PointerPainter(color: tc.accent),
                        ),
                      ),
                      // Rotating compass + needle
                      Transform.rotate(
                        angle: -_heading! * pi / 180,
                        child: CustomPaint(
                          size: const Size(QiblaLayout.compassSize, QiblaLayout.compassSize),
                          painter: _CompassPainter(
                            qiblaDegrees: qiblaBearing,
                            accent: tc.accent,
                            muted: tc.textMuted,
                            ring: tc.cardBorder,
                            needle: tc.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // static compass (no heading available)
              Center(
                child: SizedBox(
                  width: QiblaLayout.compassSize,
                  height: QiblaLayout.compassSize,
                  child: CustomPaint(
                    painter: _CompassPainter(
                      qiblaDegrees: qiblaBearing,
                      accent: tc.accent,
                      muted: tc.textMuted,
                      ring: tc.cardBorder,
                      needle: tc.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              // Unavailable notice
              if (!_compassAvailable)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: QiblaLayout.screenPadding),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: tc.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tc.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(MdiIcons.compassOff, size: 16, color: tc.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          'Compass not available on this device.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: tc.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.s8),

            // ── Debug overlay (temporary) ──
            if (_compassAvailable && _heading != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: QiblaLayout.screenPadding),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tc.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tc.cardBorder),
                  ),
                  child: Center(
                    child: Text(
                      'heading=${_heading!.toStringAsFixed(1)}° | qibla=${qiblaBearing.toStringAsFixed(1)}° | delta=${((qiblaBearing - _heading! + 360) % 360).toStringAsFixed(1)}°',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: tc.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.s24),

            // ── Status text ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: QiblaLayout.screenPadding),
              child: Center(
                child: facingQibla
                    ? Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: QiblaLayout.statusFontSize,
                          color: tc.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : (_compassAvailable && _heading != null)
                        ? Text(
                            statusText,
                            style: GoogleFonts.inter(
                              fontSize: QiblaLayout.statusFontSize,
                              color: tc.textMuted,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                        : RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: QiblaLayout.statusFontSize,
                                color: tc.textMuted,
                                fontWeight: FontWeight.w400,
                              ),
                              children: [
                                const TextSpan(text: 'Qibla is at '),
                                TextSpan(
                                  text: '${qiblaBearing.toStringAsFixed(1)}°',
                                  style: TextStyle(
                                    color: tc.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' from North.'),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // ── Kaaba label card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: QiblaLayout.screenPadding),
              child: Container(
                padding: const EdgeInsets.all(QiblaLayout.cardPadding),
                decoration: BoxDecoration(
                  color: tc.card,
                  borderRadius: BorderRadius.circular(QiblaLayout.cardRadius),
                  border: Border.all(color: tc.cardBorder, width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      'الكعبة المشرّفة',
                      style: GoogleFonts.inter(
                        fontSize: QiblaLayout.arabicFontSize,
                        fontWeight: FontWeight.w600,
                        color: tc.accent,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Al-Kaaba Al-Musharrafah',
                      style: GoogleFonts.inter(
                        fontSize: QiblaLayout.translitFontSize,
                        fontWeight: FontWeight.w500,
                        color: tc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: QiblaLayout.screenPadding),
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────
// POINTER PAINTER (fixed triangle at top, does NOT rotate)
// ────────────────────────────────────────────────
class _PointerPainter extends CustomPainter {
  final Color color;
  _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}

// ────────────────────────────────────────────────
// COMPASS PAINTER (rotates with device heading)
// ────────────────────────────────────────────────
class _CompassPainter extends CustomPainter {
  final double qiblaDegrees;
  final Color accent;
  final Color muted;
  final Color ring;
  final Color needle;

  _CompassPainter({
    required this.qiblaDegrees,
    required this.accent,
    required this.muted,
    required this.ring,
    required this.needle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // ── Outer ring ──
    final ringPaint = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = QiblaLayout.compassStroke;
    canvas.drawCircle(center, radius, ringPaint);

    // ── Tick marks ──
    final tickPaint = Paint()
      ..color = muted.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    final majorTickPaint = Paint()
      ..color = muted.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;

    for (int deg = 0; deg < 360; deg += 5) {
      final isMajor = deg % 90 == 0;
      final isMinor30 = deg % 30 == 0;
      final len = isMajor
          ? QiblaLayout.tickLengthMajor
          : (isMinor30 ? QiblaLayout.tickLength + 2 : QiblaLayout.tickLength);
      final rad = deg * pi / 180 - pi / 2;
      final outerX = center.dx + radius * cos(rad);
      final outerY = center.dy + radius * sin(rad);
      final innerX = center.dx + (radius - len) * cos(rad);
      final innerY = center.dy + (radius - len) * sin(rad);
      canvas.drawLine(
        Offset(outerX, outerY),
        Offset(innerX, innerY),
        isMajor || isMinor30 ? majorTickPaint : tickPaint,
      );
    }

    // ── Cardinal labels ──
    final cardinals = {'N': 0, 'E': 90, 'S': 180, 'W': 270};
    cardinals.forEach((label, deg) {
      final rad = deg * pi / 180 - pi / 2;
      final labelRadius = radius - QiblaLayout.tickLengthMajor - 12;
      final x = center.dx + labelRadius * cos(rad);
      final y = center.dy + labelRadius * sin(rad);
      final isNorth = label == 'N';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: QiblaLayout.cardinalFontSize,
            fontWeight: FontWeight.w700,
            color: isNorth ? accent : muted.withValues(alpha: 0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    });

    // ── Qibla needle ──
    final needleRad = qiblaDegrees * pi / 180 - pi / 2;
    final needlePaint = Paint()
      ..color = accent
      ..strokeWidth = QiblaLayout.needleWidth
      ..strokeCap = StrokeCap.round;
    final needleEnd = Offset(
      center.dx + (radius - QiblaLayout.tickLengthMajor - 24) * cos(needleRad),
      center.dy + (radius - QiblaLayout.tickLengthMajor - 24) * sin(needleRad),
    );
    canvas.drawLine(center, needleEnd, needlePaint);

    // ── Center dot ──
    canvas.drawCircle(center, QiblaLayout.centerDotRadius, Paint()..color = accent);

    // ── Kaaba marker on ring ──
    final kaabaX = center.dx + (radius + 2) * cos(needleRad);
    final kaabaY = center.dy + (radius + 2) * sin(needleRad);
    canvas.drawCircle(Offset(kaabaX, kaabaY), QiblaLayout.kaabaIconSize / 2 + 3, Paint()..color = accent);
    final kaabaRect = Rect.fromCenter(
      center: Offset(kaabaX, kaabaY),
      width: QiblaLayout.kaabaIconSize * 0.55,
      height: QiblaLayout.kaabaIconSize * 0.55,
    );
    canvas.drawRect(kaabaRect, Paint()..color = Colors.black..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.qiblaDegrees != qiblaDegrees || old.accent != accent;
}
