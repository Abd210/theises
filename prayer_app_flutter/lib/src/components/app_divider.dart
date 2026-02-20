import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.cardBorder,
    );
  }
}
