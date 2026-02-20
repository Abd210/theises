import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../providers/theme_provider.dart';
import '../components/glass_card.dart';
import '../components/app_divider.dart';

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s24),
      children: [
        // ── COLORS ──
        Text('Color Swatches', style: AppTypography.titleMedium(tc)),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            _swatch('backgroundStart', tc.backgroundStart),
            _swatch('backgroundEnd', tc.backgroundEnd),
            _swatch('card', tc.card),
            _swatch('accent', tc.accent),
            _swatch('textMuted', tc.textMuted),
            _swatch('inactive', tc.inactive),
          ],
        ),

        const SizedBox(height: AppSpacing.s32),

        // ── TYPOGRAPHY ──
        Text('Typography', style: AppTypography.titleMedium(tc)),
        const SizedBox(height: AppSpacing.s12),
        Text('Title Large 28px', style: AppTypography.titleLarge(tc)),
        const SizedBox(height: AppSpacing.s8),
        Text('Title Medium 20px', style: AppTypography.titleMedium(tc)),
        const SizedBox(height: AppSpacing.s8),
        Text('Body 16px', style: AppTypography.body(tc)),
        const SizedBox(height: AppSpacing.s8),
        Text('Caption 13px', style: AppTypography.caption(tc)),

        const SizedBox(height: AppSpacing.s32),

        // ── SPACING ──
        Text('Spacing Scale', style: AppTypography.titleMedium(tc)),
        const SizedBox(height: AppSpacing.s12),
        _spacingBar(tc, 's4', 4),
        _spacingBar(tc, 's8', 8),
        _spacingBar(tc, 's12', 12),
        _spacingBar(tc, 's16', 16),
        _spacingBar(tc, 's24', 24),
        _spacingBar(tc, 's32', 32),

        const SizedBox(height: AppSpacing.s32),

        // ── GLASS CARD ──
        Text('GlassCard', style: AppTypography.titleMedium(tc)),
        const SizedBox(height: AppSpacing.s12),
        GlassCard(
          child: Text('Sample glass card content', style: AppTypography.body(tc)),
        ),

        const SizedBox(height: AppSpacing.s32),

        // ── DIVIDER ──
        Text('AppDivider', style: AppTypography.titleMedium(tc)),
        const SizedBox(height: AppSpacing.s12),
        const AppDivider(),

        const SizedBox(height: AppSpacing.s32),

        // ── RADIUS ──
        Text('Border Radii', style: AppTypography.titleMedium(tc)),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            _radiusBox(tc, 'card 24', AppRadius.card),
            const SizedBox(width: AppSpacing.s12),
            _radiusBox(tc, 'button 16', AppRadius.button),
            const SizedBox(width: AppSpacing.s12),
            _radiusBox(tc, 'pill', AppRadius.pill),
          ],
        ),
      ],
    );
  }

  Widget _swatch(String label, Color color) {
    return Column(
      children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        )),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white54)),
      ],
    );
  }

  Widget _spacingBar(ThemeColors tc, String label, double width) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text(label, style: AppTypography.caption(tc))),
          const SizedBox(width: 8),
          Container(height: 12, width: width, color: tc.accent),
        ],
      ),
    );
  }

  Widget _radiusBox(ThemeColors tc, String label, double radius) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: tc.card,
            borderRadius: BorderRadius.circular(radius.clamp(0, 24)),
            border: Border.all(color: tc.cardBorder),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.caption(tc)),
      ],
    );
  }
}
