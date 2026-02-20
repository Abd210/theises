import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class ScreenContainer extends StatelessWidget {
  final Widget child;

  const ScreenContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return Container(
      decoration: BoxDecoration(gradient: appBackgroundGradient(tc)),
      child: SafeArea(bottom: false, child: child),
    );
  }
}
