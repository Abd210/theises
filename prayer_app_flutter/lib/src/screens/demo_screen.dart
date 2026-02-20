import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import '../components/screen_container.dart';
import '../components/glass_card.dart';
import '../components/app_header.dart';
import '../components/app_icon_button.dart';
import '../components/app_divider.dart';
import '../components/bottom_nav_bar.dart';

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenContainer(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            const AppHeader(title: 'Bucharest'),
            const SizedBox(height: AppSpacing.s24),

            // Typography
            Text('Title Large', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.s8),
            Text('Title Medium', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.s8),
            Text('Body text looks like this', style: AppTypography.body),
            const SizedBox(height: AppSpacing.s8),
            Text('Caption text is muted', style: AppTypography.caption),

            const SizedBox(height: AppSpacing.s24),
            const AppDivider(),
            const SizedBox(height: AppSpacing.s24),

            // Glass Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next Prayer: MAGHRIB', style: AppTypography.body),
                  const SizedBox(height: AppSpacing.s8),
                  Text('Starts in 02:14:30', style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.s4),
                  Text('Adhan at 5:50 PM', style: AppTypography.caption),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.s24),

            // Button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AppIconButton(
                  icon: MdiIcons.cogOutline,
                  onTap: () {},
                ),
                AppIconButton(
                  icon: MdiIcons.bellOutline,
                  onTap: () {},
                ),
                AppIconButton(
                  icon: MdiIcons.shareVariant,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.s24),

            // Color swatches
            _swatch('backgroundStart', AppColors.backgroundStart),
            _swatch('backgroundEnd', AppColors.backgroundEnd),
            _swatch('card', AppColors.card),
            _swatch('accentGold', AppColors.accentGold),
            _swatch('textMuted', AppColors.textMuted),
            _swatch('inactive', AppColors.inactive),
          ],
        ),
      ),
    );
  }

  Widget _swatch(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Text(label, style: AppTypography.body),
        ],
      ),
    );
  }
}
