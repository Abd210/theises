import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'app_icon_button.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onTestNotification;

  const AppHeader({
    super.key,
    required this.title,
    this.onSettingsTap,
    this.onTestNotification,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SalahLayout.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                MdiIcons.mapMarker,
                color: tc.accent,
                size: SalahLayout.locationIconSize,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                title,
                style: AppTypography.body(tc).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onTestNotification != null)
                AppIconButton(
                  icon: MdiIcons.bellOutline,
                  size: SalahLayout.gearButtonSize,
                  iconSize: SalahLayout.gearIconSize,
                  onTap: onTestNotification!,
                ),
              if (onTestNotification != null)
                const SizedBox(width: 4),
              AppIconButton(
                icon: MdiIcons.cogOutline,
                size: SalahLayout.gearButtonSize,
                iconSize: SalahLayout.gearIconSize,
                onTap: onSettingsTap ?? () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

