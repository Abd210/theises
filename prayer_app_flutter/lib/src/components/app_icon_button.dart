import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.iconButtonBg,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: iconSize),
      ),
    );
  }
}
