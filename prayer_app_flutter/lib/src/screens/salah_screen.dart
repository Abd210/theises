import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../services/location_service.dart';
import '../models/prayer_times.dart';
import '../services/prayer_api.dart';
import '../services/prayer_settings_service.dart';
import '../services/notification_service.dart';
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
  Map<String, PrayerTimings>? _weekTimings;
  String? _error;
  bool _offlineCached = false;
  bool _loading = true;
  Timer? _timer;
  int _selectedDay = 0; // 0 = today, 1 = tomorrow, ... 6
  late PageController _pageController;

  /// The 7 dates we render (today..today+6).
  List<DateTime> get _dates =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
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
    _pageController.dispose();
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
      final result = await _api.fetchWeek(
        methodId: ps.methodId,
        school: ps.school,
      );

      // Apply per-prayer offsets to each day
      final adjusted = <String, PrayerTimings>{};
      for (final entry in result.week.entries) {
        final adj = entry.value.applyOffsets(ps.offsets);
        if (adj.sanityCheck()) {
          adjusted[entry.key] = adj;
        } else {
          // Keep raw if offset causes invalid order
          adjusted[entry.key] = entry.value;
          debugPrint('[SalahScreen] ⚠️ Post-offset sanity failed for ${entry.key}');
        }
      }

      if (mounted) {
        setState(() {
          _weekTimings = adjusted;
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

  /// Day label for the page indicator.
  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;

    if (_loading && _weekTimings == null) {
      return Center(child: CircularProgressIndicator(color: tc.accent));
    }

    if (_weekTimings == null || _weekTimings!.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _load,
      color: tc.accent,
      child: Column(
        children: [
          // ── Fixed header area ──
          _buildHeaderArea(tc),
          
          // ── Fixed Date & Hero ──
          Builder(builder: (context) {
            final dateStr = PrayerApiService.dateKey(_dates[_selectedDay]);
            final t = _weekTimings?[dateStr];
            if (t == null) return const SizedBox();
            return _buildFixedDateAndHero(t, _dates[_selectedDay], _selectedDay, tc);
          }),

          // ── Day pager ──
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: 7,
              onPageChanged: (i) => setState(() => _selectedDay = i),
              itemBuilder: (context, index) {
                final date = _dates[index];
                final key = PrayerApiService.dateKey(date);
                final t = _weekTimings![key];
                if (t == null) {
                  return Center(
                    child: Text(
                      'No data for ${_dayLabel(date)}',
                      style: AppTypography.caption(tc),
                    ),
                  );
                }
                return _buildDayContent(t, date, index, tc);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderArea(dynamic tc) {
    return Column(
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
              onTestNotification: () async {
                final ns = NotificationService();
                final granted = await ns.requestPermission();
                if (granted) await ns.sendTestNow();
              },
            );
          },
        ),
        const SizedBox(height: SalahLayout.headerMarginBottom),

        // ── Default location banner ──
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

      ],
    );
  }

  Widget _buildFixedDateAndHero(PrayerTimings t, DateTime date, int dayIndex, dynamic tc) {
    final now = DateTime.now();
    final isToday = dayIndex == 0;

    // Next prayer calculation (only meaningful for today)
    PrayerEntry? next;
    Duration countdown = Duration.zero;
    if (isToday) {
      next = t.getNextPrayer(now);
      countdown = t.getTimeUntilNext(now);
    } else {
      // For future days, show first prayer
      next = t.mainPrayers.first;
    }

    return Column(
      children: [
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
                textDirection: TextDirection.rtl,
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
            countdown: isToday ? _formatCountdown(countdown) : '—',
            adhanTime: next?.time12 ?? '—',
          ),
        ),
        const SizedBox(height: SalahLayout.heroMarginBottom),
      ],
    );
  }

  Widget _buildDayContent(PrayerTimings t, DateTime date, int dayIndex, dynamic tc) {
    final now = DateTime.now();
    final isToday = dayIndex == 0;

    // Next prayer calculation (only meaningful for today)
    PrayerEntry? next;
    if (isToday) {
      next = t.getNextPrayer(now);
    } else {
      // For future days, show first prayer
      next = t.mainPrayers.first;
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
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
          final isNext = isToday && p.name == next?.name;
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

        // ── Day selector dots ──
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SalahLayout.screenPadding,
            vertical: AppSpacing.s8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) {
              final isActive = i == _selectedDay;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? tc.accent : tc.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
        // ── Day label ──
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SalahLayout.screenPadding,
          ),
          child: Text(
            _dayLabel(_dates[_selectedDay]),
            style: AppTypography.body(tc).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: SalahLayout.screenPadding),
      ],
    );
  }
}
