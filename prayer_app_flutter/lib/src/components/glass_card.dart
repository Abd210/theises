import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tc.cardBorder, width: 1),
      ),
      child: child,
    );
  }
}
