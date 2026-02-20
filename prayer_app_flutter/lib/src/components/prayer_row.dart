import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

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
    final tc = ThemeScope.of(context).current;
    final textColor = isHighlighted ? tc.accent : tc.textPrimary;
    final iconColor = isHighlighted ? tc.accent : tc.textMuted;

    return Container(
      height: SalahLayout.rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: SalahLayout.rowPaddingH),
      decoration: BoxDecoration(
        color: isHighlighted ? tc.card : Colors.transparent,
        borderRadius: BorderRadius.circular(SalahLayout.rowRadius),
        border: isHighlighted
            ? Border.all(
                color: tc.accent.withValues(alpha: SalahLayout.rowBorderOpacity),
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
            style: AppTypography.body(tc).copyWith(
              fontSize: SalahLayout.rowTextSize,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: AppTypography.body(tc).copyWith(
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
