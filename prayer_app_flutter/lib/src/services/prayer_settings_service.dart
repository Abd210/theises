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
  static const String _kMethodMode = 'prayer_method_mode';
  static const String _kOffsetPrefix = 'prayer_offset_';

  static const int defaultMethodId = 3; // MWL
  static const int defaultSchool = 0;   // Shafi
  static const String defaultMethodMode = 'auto';

  /// Prayer names used for offset keys.
  static const List<String> offsetPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  static const List<MethodOption> methodOptions = [
    MethodOption(3, 'Muslim World League'),
    MethodOption(2, 'ISNA'),
    MethodOption(4, 'Umm al-Qura'),
    MethodOption(5, 'Egyptian General Authority'),
    MethodOption(1, 'Univ. of Islamic Sciences, Karachi'),
    MethodOption(7, 'Inst. of Geophysics, Univ. of Tehran'),
    MethodOption(13, 'Diyanet İşleri Başkanlığı, Turkey'),
    MethodOption(15, 'Moonsighting Committee'),
  ];

  static const List<SchoolOption> schoolOptions = [
    SchoolOption(0, 'Shafi (Standard)'),
    SchoolOption(1, 'Hanafi'),
  ];

  Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'methodId': prefs.getInt(_kMethod) ?? defaultMethodId,
      'school': prefs.getInt(_kSchool) ?? defaultSchool,
      'methodMode': prefs.getString(_kMethodMode) ?? defaultMethodMode,
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

  Future<void> setMethodMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMethodMode, mode);
    debugPrint('[PrayerSettings] methodMode set to $mode');
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
    return methodOptions.firstWhere((o) => o.id == id, orElse: () => methodOptions[0]).label;
  }

  static String schoolLabel(int id) {
    return schoolOptions.firstWhere((o) => o.id == id, orElse: () => schoolOptions[0]).label;
  }

  /// Pick the best calculation method based on detected country.
  static int autoMethodForCountry(String country) {
    final c = country.toLowerCase().trim();
    // US / Canada → Moonsighting Committee
    if (c == 'united states' || c == 'us' || c == 'usa' ||
        c == 'canada' || c == 'ca') {
      return 15;
    }
    // Turkey → Diyanet
    if (c == 'turkey' || c == 'türkiye' || c == 'tr') return 13;
    // Pakistan → Karachi
    if (c == 'pakistan' || c == 'pk') return 1;
    // Iran → Tehran
    if (c == 'iran' || c == 'ir') return 7;
    // Saudi Arabia → Umm al-Qura
    if (c == 'saudi arabia' || c == 'sa') return 4;
    // Egypt → Egyptian
    if (c == 'egypt' || c == 'eg') return 5;
    // Default → MWL
    return 3;
  }
}

/// Reactive wrapper so UI rebuilds when settings change.
class PrayerSettingsNotifier extends ChangeNotifier {
  final PrayerSettingsService _svc = PrayerSettingsService();

  int _methodId = PrayerSettingsService.defaultMethodId;
  int _school = PrayerSettingsService.defaultSchool;
  String _methodMode = PrayerSettingsService.defaultMethodMode;
  Map<String, int> _offsets = {
    for (final p in PrayerSettingsService.offsetPrayers) p: 0,
  };

  int get methodId => _methodId;
  int get school => _school;
  String get methodMode => _methodMode;
  Map<String, int> get offsets => Map.unmodifiable(_offsets);

  Future<void> load() async {
    final data = await _svc.load();
    _methodId = data['methodId'] as int;
    _school = data['school'] as int;
    _methodMode = data['methodMode'] as String;
    _offsets = await _svc.loadOffsets();
    notifyListeners();
  }

  /// Set method from picker — also sets mode to "manual".
  Future<void> setMethodId(int id) async {
    _methodId = id;
    _methodMode = 'manual';
    notifyListeners();
    await _svc.setMethodId(id);
    await _svc.setMethodMode('manual');
  }

  /// Set method from auto-select — does NOT change mode.
  Future<void> setMethodIdAuto(int id) async {
    if (_methodId == id) return; // no change
    _methodId = id;
    notifyListeners();
    await _svc.setMethodId(id);
    debugPrint('[PrayerSettings] auto-selected method $id');
  }

  Future<void> setMethodMode(String mode) async {
    _methodMode = mode;
    notifyListeners();
    await _svc.setMethodMode(mode);
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
