import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';

class BottomNavBarItem {
  final IconData icon;
  final String label;

  const BottomNavBarItem({required this.icon, required this.label});
}

final List<BottomNavBarItem> kNavItems = [
  BottomNavBarItem(icon: MdiIcons.clockOutline, label: 'Salah'),
  BottomNavBarItem(icon: MdiIcons.compassOutline, label: 'Qibla'),
  BottomNavBarItem(icon: MdiIcons.bookOpenVariant, label: 'Quran'),
  BottomNavBarItem(icon: MdiIcons.bookshelf, label: 'Azkar'),
];

class BottomNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SalahLayout.navHeight,
      margin: EdgeInsets.fromLTRB(
        SalahLayout.navInsetH,
        0,
        SalahLayout.navInsetH,
        SalahLayout.navInsetBottom,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.navBar,
        borderRadius: BorderRadius.circular(SalahLayout.navRadius),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(kNavItems.length, (i) {
          final item = kNavItems[i];
          final isActive = i == activeIndex;
          return _NavTab(
            icon: item.icon,
            label: item.label,
            isActive: isActive,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: SalahLayout.pillHeight,
          padding: const EdgeInsets.symmetric(horizontal: SalahLayout.pillPaddingH),
          decoration: BoxDecoration(
            color: AppColors.accentGold,
            borderRadius: BorderRadius.circular(SalahLayout.pillRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.backgroundStart, size: SalahLayout.pillIconSize),
              const SizedBox(width: AppSpacing.s8),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: SalahLayout.pillTextSize,
                  color: AppColors.backgroundStart,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8, vertical: AppSpacing.s8,
        ),
        child: Icon(icon, color: AppColors.inactive, size: SalahLayout.navInactiveIconSize),
      ),
    );
  }
}
