import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsNotifier extends ChangeNotifier {
  bool _enabled = false;
  final Map<String, bool> _prayerEnabled = {
    'Fajr': true,
    'Dhuhr': true,
    'Asr': true,
    'Maghrib': true,
    'Isha': true,
  };
  int _leadMinutes = 0;

  bool get enabled => _enabled;
  int get leadMinutes => _leadMinutes;
  Map<String, bool> get prayerEnabled => Map.unmodifiable(_prayerEnabled);

  bool isPrayerEnabled(String name) => _prayerEnabled[name] ?? true;

  static const _keyEnabled = 'notif_enabled';
  static const _keyLeadMinutes = 'notif_lead_minutes';
  static const _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const leadTimeOptions = [0, 5, 10];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_keyEnabled) ?? false;
    _leadMinutes = prefs.getInt(_keyLeadMinutes) ?? 0;
    for (final name in _prayerNames) {
      _prayerEnabled[name] = prefs.getBool('notif_prayer_${name.toLowerCase()}') ?? true;
    }
    notifyListeners();
  }

  Future<void> setEnabled(bool val) async {
    _enabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, val);
    notifyListeners();
  }

  Future<void> setPrayerEnabled(String name, bool val) async {
    _prayerEnabled[name] = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_prayer_${name.toLowerCase()}', val);
    notifyListeners();
  }

  Future<void> setLeadMinutes(int val) async {
    _leadMinutes = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLeadMinutes, val);
    notifyListeners();
  }
}
