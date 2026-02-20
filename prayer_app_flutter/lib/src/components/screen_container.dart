import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScreenContainer extends StatelessWidget {
  final Widget child;

  const ScreenContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: appBackgroundGradient),
      child: SafeArea(bottom: false, child: child),
    );
  }
}
