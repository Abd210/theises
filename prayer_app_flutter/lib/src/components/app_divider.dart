import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return Container(
      height: 1,
      color: tc.cardBorder,
    );
  }
}
