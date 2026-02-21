import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../providers/theme_provider.dart';
import '../models/azkar_data.dart';
import 'azkar_detail_screen.dart';

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AzkarLayout.screenPadding),
      children: [
        SizedBox(height: AzkarLayout.titleMarginTop),
        // Title
        Text('Azkar', style: AppTypography.titleLarge(tc)),
        const SizedBox(height: 4),
        Text(
          '114 Surahs · Read & Reflect',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: AzkarLayout.subtitleSize,
            color: tc.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        // Search bar
        _buildSearchBar(tc),
        const SizedBox(height: AppSpacing.s24),
        // Grid
        _buildGrid(context, tc),
        const SizedBox(height: AppSpacing.s32),
      ],
    );
  }

  Widget _buildSearchBar(ThemeColors tc) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: AzkarLayout.searchHeight,
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(AzkarLayout.searchRadius),
              border: Border.all(color: tc.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search, size: AzkarLayout.searchIconSize, color: tc.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Search azkar...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: AzkarLayout.searchFontSize,
                    color: tc.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: AzkarLayout.searchHeight,
          height: AzkarLayout.searchHeight,
          decoration: BoxDecoration(
            color: tc.card,
            borderRadius: BorderRadius.circular(AzkarLayout.searchRadius),
            border: Border.all(color: tc.cardBorder),
          ),
          child: Icon(Icons.bookmark_outline, size: 20, color: tc.textMuted),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, ThemeColors tc) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: azkarCategories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AzkarLayout.gridSpacing,
        mainAxisSpacing: AzkarLayout.gridSpacing,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final cat = azkarCategories[index];
        return _CategoryCard(category: cat, tc: tc);
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AzkarCategory category;
  final ThemeColors tc;

  const _CategoryCard({required this.category, required this.tc});

  IconData _getIcon(String name) {
    final map = <String, IconData>{
      'weather-sunny': MdiIcons.weatherSunny,
      'moon-waning-crescent': MdiIcons.moonWaningCrescent,
      'star-four-points-outline': MdiIcons.starFourPointsOutline,
      'power-sleep': MdiIcons.powerSleep,
      'weather-sunset-up': MdiIcons.weatherSunsetUp,
      'heart-outline': MdiIcons.heartOutline,
    };
    return map[name] ?? MdiIcons.bookOpenVariant;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AzkarDetailScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(AzkarLayout.gridCardRadius),
          border: Border.all(color: tc.cardBorder),
        ),
        padding: EdgeInsets.all(AzkarLayout.gridCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tc.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(category.icon),
                size: AzkarLayout.gridIconSize,
                color: tc.accent,
              ),
            ),
            const Spacer(),
            // Title
            Text(
              category.title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: AzkarLayout.gridTitleSize,
                color: tc.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle + arrow row
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: AzkarLayout.gridSubtitleSize,
                      color: tc.textMuted,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: AzkarLayout.gridArrowSize,
                  color: tc.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
