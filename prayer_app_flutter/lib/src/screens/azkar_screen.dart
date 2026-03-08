import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../providers/theme_provider.dart';
import '../models/azkar_data.dart';
import 'azkar_detail_screen.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  String? _lastCategoryKey;

  @override
  void initState() {
    super.initState();
    _loadLastCategory();
  }

  Future<void> _loadLastCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('azkar_last_category');
    if (mounted && key != null) {
      setState(() => _lastCategoryKey = key);
    }
  }

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
        const SizedBox(height: AppSpacing.s16),

        // Resume card
        if (_lastCategoryKey != null)
          _buildResumeCard(context, tc),

        const SizedBox(height: AppSpacing.s8),
        // Grid
        _buildGrid(context, tc),
        const SizedBox(height: AppSpacing.s32),
      ],
    );
  }

  Widget _buildResumeCard(BuildContext context, ThemeColors tc) {
    final cat = azkarCategories.firstWhere(
      (c) => c.id == _lastCategoryKey,
      orElse: () => azkarCategories.first,
    );
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AzkarDetailScreen(category: cat),
          ),
        ).then((_) => _loadLastCategory());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tc.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tc.accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(MdiIcons.playCircleOutline, color: tc.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Resume: ${cat.title}',
                style: AppTypography.body(tc).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(MdiIcons.chevronRight, color: tc.accent, size: 20),
          ],
        ),
      ),
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
        return _CategoryCard(
          category: cat,
          tc: tc,
          onReturn: _loadLastCategory,
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AzkarCategory category;
  final ThemeColors tc;
  final VoidCallback? onReturn;

  const _CategoryCard({required this.category, required this.tc, this.onReturn});

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
        ).then((_) => onReturn?.call());
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
