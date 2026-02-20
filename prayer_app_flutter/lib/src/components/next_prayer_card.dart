import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';

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
    return Container(
      constraints: const BoxConstraints(minHeight: SalahLayout.heroMinHeight),
      padding: const EdgeInsets.all(SalahLayout.heroPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(SalahLayout.heroRadius),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: SalahLayout.heroBorderOpacity),
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
              color: AppColors.accentGold,
              borderRadius: BorderRadius.circular(SalahLayout.heroIconBoxRadius),
            ),
            child: Icon(
              MdiIcons.mosque,
              color: AppColors.backgroundStart,
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
                  style: AppTypography.body.copyWith(
                    fontSize: SalahLayout.heroLine1Size,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Starts in ',
                      style: AppTypography.caption.copyWith(
                        fontSize: SalahLayout.heroLine1Size,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      countdown,
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: SalahLayout.heroCountdownSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Adhan at $adhanTime',
                  style: AppTypography.caption.copyWith(
                    fontSize: SalahLayout.heroLine3Size,
                    color: AppColors.textMuted,
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
