import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Calculation method options (AlAdhan method IDs).
class MethodOption {
  final int id;
  final String label;
  const MethodOption(this.id, this.label);
}

/// Madhab / school options (AlAdhan school IDs).
class SchoolOption {
  final int id;
  final String label;
  const SchoolOption(this.id, this.label);
}

class PrayerSettingsService {
  static const String _kMethod = 'prayer_method_id';
  static const String _kSchool = 'prayer_school';
  static const String _kOffsetPrefix = 'prayer_offset_';

  static const int defaultMethodId = 3; // MWL
  static const int defaultSchool = 0;   // Shafi

  /// Prayer names used for offset keys.
  static const List<String> offsetPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  static const List<MethodOption> methodOptions = [
    MethodOption(2, 'ISNA'),
    MethodOption(3, 'Muslim World League'),
    MethodOption(4, 'Umm al-Qura'),
    MethodOption(5, 'Egyptian General Authority'),
  ];

  static const List<SchoolOption> schoolOptions = [
    SchoolOption(0, 'Shafi (Standard)'),
    SchoolOption(1, 'Hanafi'),
  ];

  Future<Map<String, int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'methodId': prefs.getInt(_kMethod) ?? defaultMethodId,
      'school': prefs.getInt(_kSchool) ?? defaultSchool,
    };
  }

  Future<void> setMethodId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMethod, id);
    debugPrint('[PrayerSettings] methodId set to $id');
  }

  Future<void> setSchool(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSchool, id);
    debugPrint('[PrayerSettings] school set to $id');
  }

  /// Load all offsets. Returns map { 'Fajr': 0, 'Dhuhr': 0, ... }.
  Future<Map<String, int>> loadOffsets() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, int>{};
    for (final name in offsetPrayers) {
      map[name] = prefs.getInt('$_kOffsetPrefix$name') ?? 0;
    }
    return map;
  }

  /// Set a single prayer offset (clamped to -30..+30).
  Future<void> setOffset(String prayer, int minutes) async {
    final clamped = minutes.clamp(-30, 30);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kOffsetPrefix$prayer', clamped);
    debugPrint('[PrayerSettings] offset $prayer set to $clamped');
  }

  static String methodLabel(int id) {
    return methodOptions.firstWhere((o) => o.id == id, orElse: () => methodOptions[1]).label;
  }

  static String schoolLabel(int id) {
    return schoolOptions.firstWhere((o) => o.id == id, orElse: () => schoolOptions[0]).label;
  }
}

/// Reactive wrapper so UI rebuilds when settings change.
class PrayerSettingsNotifier extends ChangeNotifier {
  final PrayerSettingsService _svc = PrayerSettingsService();

  int _methodId = PrayerSettingsService.defaultMethodId;
  int _school = PrayerSettingsService.defaultSchool;
  Map<String, int> _offsets = {
    for (final p in PrayerSettingsService.offsetPrayers) p: 0,
  };

  int get methodId => _methodId;
  int get school => _school;
  Map<String, int> get offsets => Map.unmodifiable(_offsets);

  Future<void> load() async {
    final data = await _svc.load();
    _methodId = data['methodId']!;
    _school = data['school']!;
    _offsets = await _svc.loadOffsets();
    notifyListeners();
  }

  Future<void> setMethodId(int id) async {
    _methodId = id;
    notifyListeners();
    await _svc.setMethodId(id);
  }

  Future<void> setSchool(int id) async {
    _school = id;
    notifyListeners();
    await _svc.setSchool(id);
  }

  Future<void> setOffset(String prayer, int minutes) async {
    _offsets[prayer] = minutes.clamp(-30, 30);
    notifyListeners();
    await _svc.setOffset(prayer, minutes);
  }
}
