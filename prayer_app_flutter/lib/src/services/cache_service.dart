import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  // ── Legacy single-day keys (kept for backward compat) ──
  static const String _dataKey = 'cached_prayer_json';
  static const String _dateKey = 'cached_prayer_date';

  // ── Monthly calendar cache keys ──
  static String _monthDataKey(int year, int month) =>
      'prayer_cal_${year}_${month.toString().padLeft(2, '0')}';
  static String _monthSavedKey(int year, int month) =>
      'prayer_cal_saved_${year}_${month.toString().padLeft(2, '0')}';

  static const int _ttlDays = 7;

  // ── Monthly calendar cache ──

  /// Save raw calendar API response for a given month.
  Future<void> saveMonth(int year, int month, String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_monthDataKey(year, month), jsonStr);
    await prefs.setString(
      _monthSavedKey(year, month),
      DateTime.now().toIso8601String(),
    );
    if (kDebugMode) {
      debugPrint('[PRAYER_CACHE] saved month=$month year=$year');
    }
  }

  /// Load cached calendar JSON for a given month, or null if missing.
  Future<String?> loadMonth(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_monthDataKey(year, month));
  }

  /// Check if the cached month is still within TTL (7 days).
  Future<bool> isMonthValid(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final savedStr = prefs.getString(_monthSavedKey(year, month));
    if (savedStr == null) return false;
    final savedAt = DateTime.tryParse(savedStr);
    if (savedAt == null) return false;
    return DateTime.now().difference(savedAt).inDays < _ttlDays;
  }

  /// Extract a single day's data map from a cached month response.
  /// [dayOfMonth] is 1-based (1..31).
  static Map<String, dynamic>? extractDay(String monthJson, int dayOfMonth) {
    try {
      final body = json.decode(monthJson) as Map<String, dynamic>;
      final dataList = body['data'] as List<dynamic>?;
      if (dataList == null) return null;
      // Calendar API returns array indexed 0..N-1 for day 1..N
      final idx = dayOfMonth - 1;
      if (idx < 0 || idx >= dataList.length) return null;
      return dataList[idx] as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('[PRAYER_CACHE] extractDay error: $e');
      return null;
    }
  }

  // ── Legacy single-day (kept for offline fallback) ──

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
