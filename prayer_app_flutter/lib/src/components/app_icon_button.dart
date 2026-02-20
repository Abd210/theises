import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tc.iconButtonBg,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: tc.cardBorder, width: 1),
        ),
        child: Icon(icon, color: tc.textPrimary, size: iconSize),
      ),
    );
  }
}
