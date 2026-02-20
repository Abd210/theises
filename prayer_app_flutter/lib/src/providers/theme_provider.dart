import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';

const String _prefKey = 'selected_theme_id';

/// Manages the current theme and persists selection.
class ThemeProvider extends ChangeNotifier {
  ThemeColors _current = nightTheme;

  ThemeColors get current => _current;

  /// Load persisted theme (call once at startup).
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKey) ?? 'night';
    _current = appThemes[id] ?? nightTheme;
    notifyListeners();
  }

  /// Switch theme and persist.
  Future<void> setTheme(String id) async {
    final theme = appThemes[id];
    if (theme == null || theme.id == _current.id) return;
    _current = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, id);
  }
}

/// InheritedNotifier to provide ThemeProvider down the tree.
class ThemeScope extends InheritedNotifier<ThemeProvider> {
  const ThemeScope({
    super.key,
    required ThemeProvider notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ThemeProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    return scope!.notifier!;
  }
}
