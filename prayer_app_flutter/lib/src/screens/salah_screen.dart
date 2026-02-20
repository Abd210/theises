import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import '../models/prayer_times.dart';
import '../services/prayer_api.dart';
import '../components/app_header.dart';
import '../components/next_prayer_card.dart';
import '../components/prayer_row.dart';
import '../components/app_divider.dart';

class SalahScreen extends StatefulWidget {
  const SalahScreen({super.key});

  @override
  State<SalahScreen> createState() => _SalahScreenState();
}

class _SalahScreenState extends State<SalahScreen> {
  final PrayerApiService _api = PrayerApiService();
  PrayerTimings? _timings;
  String? _error;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchToday();
      if (mounted) {
        setState(() {
          _timings = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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
    if (_loading && _timings == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGold),
      );
    }

    final t = _timings;
    if (t == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Unknown error', style: AppTypography.caption),
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
      color: AppColors.accentGold,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header ──
          const SizedBox(height: SalahLayout.headerMarginTop),
          const AppHeader(title: 'Bucharest'),
          const SizedBox(height: SalahLayout.headerMarginBottom),

          // ── Error banner ──
          if (_error != null)
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: SalahLayout.screenPadding),
              padding: const EdgeInsets.all(AppSpacing.s8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.s8),
              ),
              child: Text(_error!, style: AppTypography.caption),
            ),

          // ── Date row ──
          const SizedBox(height: SalahLayout.dateRowMarginTop),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: SalahLayout.screenPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.gregorianFormatted, style: AppTypography.caption),
                Text(
                  t.hijriFormatted,
                  textDirection: TextDirection.ltr,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SalahLayout.dateRowMarginBottom),

          // ── Hero countdown card ──
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: SalahLayout.screenPadding),
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
                horizontal: SalahLayout.screenPadding),
            child: Row(
              children: [
                Icon(MdiIcons.calendarMonth,
                    size: SalahLayout.scheduleIconSize,
                    color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.s8),
                Text(t.gregorianFormatted, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: SalahLayout.scheduleMarginBottom),

          // ── Main prayer rows ──
          ...t.mainPrayers.map((p) {
            final isNext = p.name == next?.name;
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: SalahLayout.screenPadding),
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
                horizontal: SalahLayout.screenPadding),
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
                  horizontal: SalahLayout.screenPadding),
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
