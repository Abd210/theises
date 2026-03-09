import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../providers/theme_provider.dart';
import '../services/location_service.dart';
import '../services/prayer_settings_service.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final LocationNotifier locationNotifier;
  final PrayerSettingsNotifier prayerSettingsNotifier;
  final NotificationSettingsNotifier notifSettingsNotifier;

  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.locationNotifier,
    required this.prayerSettingsNotifier,
    required this.notifSettingsNotifier,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _detecting = false;

  Future<void> _detectLocation() async {
    setState(() => _detecting = true);
    await widget.locationNotifier.detect();
    // Auto-select method based on new country
    final ps = widget.prayerSettingsNotifier;
    if (ps.methodMode == 'auto') {
      final country = widget.locationNotifier.data.country;
      final bestMethod = PrayerSettingsService.autoMethodForCountry(country);
      await ps.setMethodIdAuto(bestMethod);
    }
    if (mounted) setState(() => _detecting = false);
  }

  void _showMethodPicker(ThemeColors tc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _OptionSheet(
        tc: tc,
        title: 'Calculation Method',
        options: PrayerSettingsService.methodOptions
            .map((o) => _SheetOption(id: o.id, label: o.label))
            .toList(),
        selectedId: widget.prayerSettingsNotifier.methodId,
        onSelect: (id) {
          widget.prayerSettingsNotifier.setMethodId(id);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSchoolPicker(ThemeColors tc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _OptionSheet(
        tc: tc,
        title: 'Madhab (Asr)',
        options: PrayerSettingsService.schoolOptions
            .map((o) => _SheetOption(id: o.id, label: o.label))
            .toList(),
        selectedId: widget.prayerSettingsNotifier.school,
        onSelect: (id) {
          widget.prayerSettingsNotifier.setSchool(id);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ThemeScope.of(context);
    final tc = provider.current;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Header ──
        const SizedBox(height: SalahLayout.headerMarginTop),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onBack,
                  child: Center(
                    child: Icon(MdiIcons.arrowLeft, color: tc.textPrimary, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Text('Settings', style: AppTypography.titleMedium(tc)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s24),

        // ── Theme section ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
          child: Text(
            'Theme',
            style: AppTypography.body(tc).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),

        // ── 2×2 Theme grid ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ThemeCard(
                      theme: nightTheme,
                      isSelected: tc.id == 'night',
                      onTap: () => provider.setTheme('night'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: _ThemeCard(
                      theme: forestTheme,
                      isSelected: tc.id == 'forest',
                      onTap: () => provider.setTheme('forest'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Expanded(
                    child: _ThemeCard(
                      theme: sandTheme,
                      isSelected: tc.id == 'sand',
                      onTap: () => provider.setTheme('sand'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: _ThemeCard(
                      theme: midnightBlueTheme,
                      isSelected: tc.id == 'midnight_blue',
                      onTap: () => provider.setTheme('midnight_blue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s32),

        // ── Location section ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
          child: Text(
            'Location',
            style: AppTypography.body(tc).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),

        ListenableBuilder(
          listenable: widget.locationNotifier,
          builder: (context, _) {
            final loc = widget.locationNotifier.data;
            final cityLabel = loc.country.isNotEmpty
                ? '${loc.city}, ${loc.country}'
                : loc.city;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: tc.card,
                  borderRadius: BorderRadius.circular(AppSpacing.s16),
                  border: Border.all(color: tc.cardBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(MdiIcons.mapMarkerOutline, color: tc.accent, size: 20),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: Text(
                            cityLabel,
                            style: AppTypography.body(tc).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: loc.source == 'gps'
                                ? tc.accent.withValues(alpha: 0.15)
                                : tc.inactive.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            loc.source == 'gps' ? 'GPS' : 'Default',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: loc.source == 'gps' ? tc.accent : tc.inactive,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      '${loc.lat.toStringAsFixed(4)}, ${loc.lon.toStringAsFixed(4)}',
                      style: AppTypography.caption(tc).copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    GestureDetector(
                      onTap: _detecting ? null : _detectLocation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: tc.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_detecting)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: tc.accent,
                                ),
                              )
                            else
                              Icon(MdiIcons.crosshairsGps, color: tc.accent, size: 16),
                            const SizedBox(width: AppSpacing.s8),
                            Text(
                              _detecting ? 'Detecting…' : 'Detect location',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: tc.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.s32),

        // ── Prayer Settings section ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
          child: Text(
            'Prayer Settings',
            style: AppTypography.body(tc).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),

        ListenableBuilder(
          listenable: widget.prayerSettingsNotifier,
          builder: (context, _) {
            final ps = widget.prayerSettingsNotifier;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: tc.card,
                  borderRadius: BorderRadius.circular(AppSpacing.s16),
                  border: Border.all(color: tc.cardBorder, width: 1),
                ),
                child: Column(
                  children: [
                    _SettingsRow(
                      tc: tc,
                      icon: MdiIcons.calculatorVariantOutline,
                      label: 'Calculation Method',
                      value: PrayerSettingsService.methodLabel(ps.methodId),
                      onTap: () => _showMethodPicker(tc),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                      child: Divider(color: tc.cardBorder, height: 1),
                    ),
                    _SettingsRow(
                      tc: tc,
                      icon: MdiIcons.handsPray,
                      label: 'Madhab (Asr)',
                      value: PrayerSettingsService.schoolLabel(ps.school),
                      onTap: () => _showSchoolPicker(tc),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.s12),

        // ── Auto-select toggle ──
        ListenableBuilder(
          listenable: widget.prayerSettingsNotifier,
          builder: (context, _) {
            final ps = widget.prayerSettingsNotifier;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s4),
                decoration: BoxDecoration(
                  color: tc.card,
                  borderRadius: BorderRadius.circular(AppSpacing.s16),
                  border: Border.all(color: tc.cardBorder, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(MdiIcons.mapMarkerRadius, color: tc.textMuted, size: 18),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Text(
                        'Auto-select method',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tc.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: Switch.adaptive(
                        value: ps.methodMode == 'auto',
                        activeTrackColor: tc.accent,
                        onChanged: (on) async {
                          if (on) {
                            await ps.setMethodMode('auto');
                            // Immediately auto-select for current country
                            final country = widget.locationNotifier.data.country;
                            final bestMethod = PrayerSettingsService.autoMethodForCountry(country);
                            await ps.setMethodIdAuto(bestMethod);
                          } else {
                            await ps.setMethodMode('manual');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.s32),

        // ── Time Adjustments section ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time Adjustments',
                style: AppTypography.body(tc).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                'minutes for each prayer',
                style: AppTypography.caption(tc).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),

        ListenableBuilder(
          listenable: widget.prayerSettingsNotifier,
          builder: (context, _) {
            final ps = widget.prayerSettingsNotifier;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: tc.card,
                  borderRadius: BorderRadius.circular(AppSpacing.s16),
                  border: Border.all(color: tc.cardBorder, width: 1),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < PrayerSettingsService.offsetPrayers.length; i++) ...[
                      _OffsetRow(
                        tc: tc,
                        prayer: PrayerSettingsService.offsetPrayers[i],
                        minutes: ps.offsets[PrayerSettingsService.offsetPrayers[i]] ?? 0,
                        onChanged: (val) => widget.prayerSettingsNotifier.setOffset(
                          PrayerSettingsService.offsetPrayers[i],
                          val,
                        ),
                      ),
                      if (i < PrayerSettingsService.offsetPrayers.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                          child: Divider(color: tc.cardBorder, height: 1),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.s16),

        // ── Notifications section ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
          child: Text(
            'Notifications',
            style: AppTypography.body(tc).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),

        ListenableBuilder(
          listenable: widget.notifSettingsNotifier,
          builder: (context, _) {
            final ns = widget.notifSettingsNotifier;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: tc.card,
                  borderRadius: BorderRadius.circular(AppSpacing.s16),
                  border: Border.all(color: tc.cardBorder, width: 1),
                ),
                child: Column(
                  children: [
                    // Master toggle
                    Row(
                      children: [
                        Icon(MdiIcons.bellOutline, color: tc.accent, size: 20),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Text(
                            'Prayer Notifications',
                            style: AppTypography.body(tc).copyWith(fontSize: 14),
                          ),
                        ),
                        SizedBox(
                          height: 36,
                          child: Switch.adaptive(
                            value: ns.enabled,
                            activeTrackColor: tc.accent,
                            onChanged: (on) async {
                              if (on) {
                                final perm = await NotificationService().requestPermission();
                                if (!perm) return;
                              }
                              await ns.setEnabled(on);
                              if (on) {
                                await NotificationService().scheduleFromCache();
                              } else {
                                await NotificationService().cancelPrayerNotifications();
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    if (ns.enabled) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                        child: Divider(color: tc.cardBorder, height: 1),
                      ),

                      // Per-prayer toggles
                      for (final prayer in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const SizedBox(width: 32),
                              Expanded(
                                child: Text(
                                  prayer,
                                  style: AppTypography.body(tc).copyWith(fontSize: 13),
                                ),
                              ),
                              SizedBox(
                                height: 32,
                                child: Switch.adaptive(
                                  value: ns.isPrayerEnabled(prayer),
                                  activeTrackColor: tc.accent,
                                  onChanged: (on) async {
                                    await ns.setPrayerEnabled(prayer, on);
                                    await NotificationService().scheduleFromCache();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                        child: Divider(color: tc.cardBorder, height: 1),
                      ),

                      // Lead time
                      Row(
                        children: [
                          Icon(MdiIcons.clockOutline, color: tc.textMuted, size: 18),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(
                            child: Text(
                              'Notify before',
                              style: AppTypography.body(tc).copyWith(fontSize: 13),
                            ),
                          ),
                          ...NotificationSettingsNotifier.leadTimeOptions.map((mins) {
                            final isActive = ns.leadMinutes == mins;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: GestureDetector(
                                onTap: () async {
                                  await ns.setLeadMinutes(mins);
                                  await NotificationService().scheduleFromCache();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isActive ? tc.accent.withValues(alpha: 0.2) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isActive ? tc.accent : tc.cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    mins == 0 ? 'At adhan' : '${mins}m',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isActive ? tc.accent : tc.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.s16),

                      // Test buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final perm = await NotificationService().requestPermission();
                                if (perm) await NotificationService().sendTestNow();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: tc.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Send Test Now',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: tc.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final perm = await NotificationService().requestPermission();
                                if (perm) await NotificationService().scheduleTestIn10s();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: tc.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Test in 10s',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: tc.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.s8),

                      // Debug: show scheduled
                      GestureDetector(
                        onTap: () async {
                          final pending = await NotificationService().getPendingPrayerNotifications();
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: tc.card,
                              title: Text(
                                'Scheduled Notifications (${pending.length})',
                                style: TextStyle(color: tc.textPrimary, fontSize: 16),
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: 300,
                                child: pending.isEmpty
                                    ? Center(
                                        child: Text('No prayer notifications scheduled.',
                                          style: TextStyle(color: tc.textMuted, fontSize: 13)),
                                      )
                                    : ListView.builder(
                                        itemCount: pending.length,
                                        itemBuilder: (_, i) {
                                          final p = pending[i];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Text(
                                              '#${p['id']} ${p['prayer']} Prayer\n${p['body']}\nTrigger: ${p['trigger']}',
                                              style: TextStyle(color: tc.textPrimary, fontSize: 12),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close', style: TextStyle(color: tc.accent)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tc.cardBorder),
                          ),
                          child: Center(
                            child: Text(
                              'Show Scheduled (Debug)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tc.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.s8),

                      // Pipeline test: schedule in 60s using real pipeline
                      GestureDetector(
                        onTap: () async {
                          final perm = await NotificationService().requestPermission();
                          if (perm) {
                            await NotificationService().schedulePipelineTestIn60s();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pipeline test scheduled in 60s. Close the app and wait.'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tc.accent.withValues(alpha: 0.5)),
                          ),
                          child: Center(
                            child: Text(
                              'Pipeline Test 60s',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tc.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: SalahLayout.screenPadding),
      ],
    );
  }
}

class _OffsetRow extends StatelessWidget {
  final ThemeColors tc;
  final String prayer;
  final int minutes;
  final ValueChanged<int> onChanged;

  const _OffsetRow({
    required this.tc,
    required this.prayer,
    required this.minutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            prayer,
            style: AppTypography.body(tc).copyWith(fontSize: 14),
          ),
        ),
        Row(
          children: [
            _CounterButton(
              tc: tc,
              icon: MdiIcons.minus,
              onTap: () => onChanged(minutes - 1),
            ),
            const SizedBox(width: AppSpacing.s8),
            GestureDetector(
              onTap: () => onChanged(0),
              child: Container(
                constraints: const BoxConstraints(minWidth: 40),
                alignment: Alignment.center,
                child: Text(
                  minutes == 0 ? '0' : (minutes > 0 ? '+$minutes' : '$minutes'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: minutes == 0 ? tc.textMuted : tc.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            _CounterButton(
              tc: tc,
              icon: MdiIcons.plus,
              onTap: () => onChanged(minutes + 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final ThemeColors tc;
  final IconData icon;
  final VoidCallback onTap;

  const _CounterButton({
    required this.tc,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: tc.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: tc.accent),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final ThemeColors tc;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.tc,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: tc.accent, size: 20),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(tc).copyWith(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: tc.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Icon(MdiIcons.chevronRight, color: tc.textMuted, size: 18),
        ],
      ),
    );
  }
}

class _SheetOption {
  final int id;
  final String label;
  const _SheetOption({required this.id, required this.label});
}

class _OptionSheet extends StatelessWidget {
  final ThemeColors tc;
  final String title;
  final List<_SheetOption> options;
  final int selectedId;
  final ValueChanged<int> onSelect;

  const _OptionSheet({
    required this.tc,
    required this.title,
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.45,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: tc.modalBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Grabber
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: tc.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: AppTypography.titleMedium(tc).copyWith(fontSize: 17),
              ),
            ),
            const SizedBox(height: 12),
            // Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: options.map((opt) {
                  final isSelected = opt.id == selectedId;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(opt.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? tc.accent.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt.label,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? tc.accent : tc.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(MdiIcons.checkCircle, color: tc.accent, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final ThemeColors theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.s16),
          border: Border.all(
            color: isSelected ? tc.accent : tc.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          color: tc.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [theme.backgroundStart, theme.backgroundEnd],
                    ),
                    border: Border.all(color: tc.cardBorder, width: 1),
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(MdiIcons.checkCircle, color: tc.accent, size: 20),
              ],
            ),
            const Spacer(),
            Text(
              theme.name,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tc.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

