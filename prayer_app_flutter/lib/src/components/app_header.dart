import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import 'app_icon_button.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSettingsTap;

  const AppHeader({super.key, required this.title, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                MdiIcons.mapMarker,
                color: AppColors.accentGold,
                size: SalahLayout.locationIconSize,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                title,
                style: AppTypography.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          AppIconButton(
            icon: MdiIcons.cogOutline,
            size: SalahLayout.gearButtonSize,
            iconSize: SalahLayout.gearIconSize,
            onTap: onSettingsTap ?? () {},
          ),
        ],
      ),
    );
  }
}
