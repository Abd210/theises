import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../services/location_service.dart';
import '../models/prayer_times.dart';
import '../services/prayer_api.dart';
import '../services/prayer_settings_service.dart';
import '../components/app_header.dart';
import '../components/next_prayer_card.dart';
import '../components/prayer_row.dart';
import '../components/app_divider.dart';

class SalahScreen extends StatefulWidget {
  final VoidCallback? onSettingsTap;
  final LocationNotifier locationNotifier;
  final PrayerSettingsNotifier prayerSettingsNotifier;

  const SalahScreen({
    super.key,
    this.onSettingsTap,
    required this.locationNotifier,
    required this.prayerSettingsNotifier,
  });

  @override
  State<SalahScreen> createState() => _SalahScreenState();
}

class _SalahScreenState extends State<SalahScreen> {
  final PrayerApiService _api = PrayerApiService();
  PrayerTimings? _timings;
  String? _error;
  bool _offlineCached = false;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Re-load prayer times when location or prayer settings change
    widget.locationNotifier.addListener(_onSettingsChanged);
    widget.prayerSettingsNotifier.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    _load();
  }

  @override
  void dispose() {
    widget.locationNotifier.removeListener(_onSettingsChanged);
    widget.prayerSettingsNotifier.removeListener(_onSettingsChanged);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _offlineCached = false;
    });
    try {
      final ps = widget.prayerSettingsNotifier;
      final result = await _api.fetchToday(
        methodId: ps.methodId,
        school: ps.school,
      );
      final raw = result.timings;

      // Apply per-prayer offsets
      final adjusted = raw.applyOffsets(ps.offsets);

      // Post-offset sanity check
      if (!adjusted.sanityCheck()) {
        debugPrint('[SalahScreen] ⚠️ Post-offset sanity check failed');
        debugPrint(
          '[SalahScreen] Raw: Fajr=${raw.fajr} Dhuhr=${raw.dhuhr} Asr=${raw.asr} Maghrib=${raw.maghrib} Isha=${raw.isha}',
        );
        debugPrint(
          '[SalahScreen] Adjusted: Fajr=${adjusted.fajr} Dhuhr=${adjusted.dhuhr} Asr=${adjusted.asr} Maghrib=${adjusted.maghrib} Isha=${adjusted.isha}',
        );
        if (mounted) {
          setState(() {
            // Keep previous timings if available, show error
            _error = 'Timing data invalid after offsets. Using previous data.';
            _loading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _timings = adjusted;
          _offlineCached = result.offlineCached;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load prayer times. Check internet and retry.';
          _loading = false;
        });
      }
    }
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;

    if (_loading && _timings == null) {
      return Center(child: CircularProgressIndicator(color: tc.accent));
    }

    final t = _timings;
    if (t == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ??
                  'Could not load prayer times. Check internet and retry.',
              style: AppTypography.caption(tc),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final next = t.getNextPrayer(now);
    final countdown = t.getTimeUntilNext(now);

    return RefreshIndicator(
      onRefresh: _load,
      color: tc.accent,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header ──
          const SizedBox(height: SalahLayout.headerMarginTop),
          ListenableBuilder(
            listenable: widget.locationNotifier,
            builder: (context, _) {
              final loc = widget.locationNotifier.data;
              final cityLabel = loc.country.isNotEmpty
                  ? '${loc.city}, ${loc.country}'
                  : loc.city;
              return AppHeader(
                title: cityLabel,
                onSettingsTap: widget.onSettingsTap,
              );
            },
          ),
          const SizedBox(height: SalahLayout.headerMarginBottom),

          // ── Default location banner (first launch denied or fallback) ──
          if (widget.locationNotifier.showDefaultLocationBanner)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: SalahLayout.screenPadding,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(AppSpacing.s8),
                border: Border.all(color: tc.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    MdiIcons.mapMarkerOffOutline,
                    size: 16,
                    color: tc.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      'Using default location',
                      style: AppTypography.caption(tc),
                    ),
                  ),
                ],
              ),
            ),

          if (widget.locationNotifier.showDefaultLocationBanner)
            const SizedBox(height: AppSpacing.s8),

          // ── Error banner ──
          if (_error != null)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: SalahLayout.screenPadding,
              ),
              padding: const EdgeInsets.all(AppSpacing.s8),
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(AppSpacing.s8),
              ),
              child: Text(_error!, style: AppTypography.caption(tc)),
            ),

          // ── Offline cached banner ──
          if (_offlineCached)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: SalahLayout.screenPadding,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(AppSpacing.s8),
                border: Border.all(color: tc.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(MdiIcons.wifiOff, size: 16, color: tc.textMuted),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      'Offline (cached)',
                      style: AppTypography.caption(tc),
                    ),
                  ),
                ],
              ),
            ),

          // ── Date row ──
          const SizedBox(height: SalahLayout.dateRowMarginTop),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SalahLayout.screenPadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.gregorianFormatted, style: AppTypography.caption(tc)),
                Text(
                  t.hijriFormatted,
                  textDirection: TextDirection.ltr,
                  style: AppTypography.caption(
                    tc,
                  ).copyWith(color: tc.accent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: SalahLayout.dateRowMarginBottom),

          // ── Hero countdown card ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SalahLayout.screenPadding,
            ),
            child: NextPrayerCard(
              name: next?.name ?? '—',
              countdown: _formatCountdown(countdown),
              adhanTime: next?.time12 ?? '—',
            ),
          ),
          const SizedBox(height: SalahLayout.heroMarginBottom),

          // ── Schedule label ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SalahLayout.screenPadding,
            ),
            child: Row(
              children: [
                Icon(
                  MdiIcons.calendarMonth,
                  size: SalahLayout.scheduleIconSize,
                  color: tc.textMuted,
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(t.gregorianFormatted, style: AppTypography.caption(tc)),
              ],
            ),
          ),
          const SizedBox(height: SalahLayout.scheduleMarginBottom),

          // ── Main prayer rows ──
          ...t.mainPrayers.map((p) {
            final isNext = p.name == next?.name;
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SalahLayout.screenPadding,
              ),
              child: Column(
                children: [
                  PrayerRow(
                    name: p.name,
                    time: p.time12,
                    icon: PrayerIcons.get(p.name),
                    isHighlighted: isNext,
                  ),
                  const SizedBox(height: SalahLayout.rowSpacing),
                ],
              ),
            );
          }),

          // ── Divider ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SalahLayout.screenPadding,
            ),
            child: Column(
              children: [
                const SizedBox(height: SalahLayout.dividerMarginTop),
                const AppDivider(),
                const SizedBox(height: SalahLayout.dividerMarginTop),
              ],
            ),
          ),

          // ── Supplementary rows ──
          ...t.supplementaryPrayers.map((p) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SalahLayout.screenPadding,
              ),
              child: Column(
                children: [
                  PrayerRow(
                    name: p.name,
                    time: p.time12,
                    icon: PrayerIcons.get(p.name),
                  ),
                  const SizedBox(height: SalahLayout.rowSpacing),
                ],
              ),
            );
          }),

          const SizedBox(height: SalahLayout.screenPadding),
        ],
      ),
    );
  }
}
