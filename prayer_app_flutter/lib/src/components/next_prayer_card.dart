import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class NextPrayerCard extends StatelessWidget {
  final String name;
  final String countdown;
  final String adhanTime;

  const NextPrayerCard({
    super.key,
    required this.name,
    required this.countdown,
    required this.adhanTime,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return Container(
      constraints: const BoxConstraints(minHeight: SalahLayout.heroMinHeight),
      padding: const EdgeInsets.all(SalahLayout.heroPadding),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(SalahLayout.heroRadius),
        border: Border.all(
          color: tc.accent.withValues(alpha: SalahLayout.heroBorderOpacity),
          width: SalahLayout.heroBorderWidth,
        ),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: SalahLayout.heroIconBoxSize,
            height: SalahLayout.heroIconBoxSize,
            decoration: BoxDecoration(
              color: tc.accent,
              borderRadius: BorderRadius.circular(SalahLayout.heroIconBoxRadius),
            ),
            child: Icon(
              MdiIcons.mosque,
              color: tc.backgroundStart,
              size: SalahLayout.heroIconSize,
            ),
          ),
          const SizedBox(width: SalahLayout.heroIconTextGap),
          // Text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next Prayer: ${name.toUpperCase()}',
                  style: AppTypography.body(tc).copyWith(
                    fontSize: SalahLayout.heroLine1Size,
                    fontWeight: FontWeight.w500,
                    color: tc.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Starts in ',
                      style: AppTypography.caption(tc).copyWith(
                        fontSize: SalahLayout.heroLine1Size,
                        color: tc.textMuted,
                      ),
                    ),
                    Text(
                      countdown,
                      style: AppTypography.titleLarge(tc).copyWith(
                        fontSize: SalahLayout.heroCountdownSize,
                        fontWeight: FontWeight.w700,
                        color: tc.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Adhan at $adhanTime',
                  style: AppTypography.caption(tc).copyWith(
                    fontSize: SalahLayout.heroLine3Size,
                    color: tc.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
