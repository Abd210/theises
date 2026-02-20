import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _dataKey = 'cached_prayer_json';
  static const String _dateKey = 'cached_prayer_date';

  Future<void> save(String jsonStr, String dateTag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dataKey, jsonStr);
    await prefs.setString(_dateKey, dateTag);
  }

  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dataKey);
  }

  Future<String?> getCachedDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dateKey);
  }
}
