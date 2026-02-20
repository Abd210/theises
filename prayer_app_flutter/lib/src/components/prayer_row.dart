import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrayerRow extends StatelessWidget {
  final String name;
  final String time;
  final IconData icon;
  final bool isHighlighted;

  const PrayerRow({
    super.key,
    required this.name,
    required this.time,
    required this.icon,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isHighlighted ? AppColors.accentGold : AppColors.textPrimary;
    final iconColor = isHighlighted ? AppColors.accentGold : AppColors.textMuted;

    return Container(
      height: SalahLayout.rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: SalahLayout.rowPaddingH),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.card : Colors.transparent,
        borderRadius: BorderRadius.circular(SalahLayout.rowRadius),
        border: isHighlighted
            ? Border.all(
                color: AppColors.accentGold.withValues(alpha: SalahLayout.rowBorderOpacity),
                width: SalahLayout.rowBorderWidth,
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: SalahLayout.rowIconSize),
          const SizedBox(width: SalahLayout.rowPaddingH),
          Text(
            name,
            style: AppTypography.body.copyWith(
              fontSize: SalahLayout.rowTextSize,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: AppTypography.body.copyWith(
              fontSize: SalahLayout.rowTextSize,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
