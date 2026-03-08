import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/prayer_times.dart';
import 'cache_service.dart';
import 'location_service.dart';

class PrayerWeekResult {
  /// Date-keyed map (YYYY-MM-DD → PrayerTimings) for 7 days.
  final Map<String, PrayerTimings> week;
  final bool offlineCached;

  const PrayerWeekResult({required this.week, required this.offlineCached});
}

class PrayerApiService {
  static const String _calendarUrl = 'https://api.aladhan.com/v1/calendar';

  final CacheService _cache = CacheService();

  /// Date key format used everywhere: YYYY-MM-DD
  static String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Fetch prayer times for 7 days (today..today+6).
  /// Uses the monthly calendar endpoint and caches full months.
  Future<PrayerWeekResult> fetchWeek({
    required int methodId,
    required int school,
  }) async {
    final locSvc = LocationService();
    final loc = await locSvc.loadSaved();
    final now = DateTime.now();

    // Determine which months we need (today..today+6 might span 2 months)
    final dates = List.generate(7, (i) => now.add(Duration(days: i)));
    final monthsNeeded = <String>{};
    for (final d in dates) {
      monthsNeeded.add('${d.year}-${d.month}');
    }

    bool anyNetworkFail = false;

    // Fetch/load each needed month
    final monthJsons = <String, String>{};
    for (final key in monthsNeeded) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      // Check cache validity
      final valid = await _cache.isMonthValid(year, month);
      if (valid) {
        final cached = await _cache.loadMonth(year, month);
        if (cached != null) {
          monthJsons[key] = cached;
          if (kDebugMode) {
            debugPrint('[PRAYER_CACHE] hit month=$month year=$year');
          }
          continue;
        }
      }

      // Fetch from API
      final url =
          '$_calendarUrl?latitude=${loc.lat}&longitude=${loc.lon}'
          '&method=$methodId&school=$school'
          '&month=$month&year=$year';

      if (kDebugMode) debugPrint('[PRAYER_CACHE] miss month=$month year=$year');
      if (kDebugMode) debugPrint('[PrayerAPI] calendar URL: $url');

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          monthJsons[key] = response.body;
          await _cache.saveMonth(year, month, response.body);
        } else {
          anyNetworkFail = true;
          if (kDebugMode) {
            debugPrint('[PrayerAPI] calendar failed status=${response.statusCode}');
          }
          // Try stale cache
          final stale = await _cache.loadMonth(year, month);
          if (stale != null) monthJsons[key] = stale;
        }
      } catch (e) {
        anyNetworkFail = true;
        if (kDebugMode) {
          debugPrint('[PrayerAPI] calendar fetch error: $e');
        }
        // Try stale cache
        final stale = await _cache.loadMonth(year, month);
        if (stale != null) monthJsons[key] = stale;
      }
    }

    // Build the 7-day map
    final weekMap = <String, PrayerTimings>{};
    for (final d in dates) {
      final mKey = '${d.year}-${d.month}';
      final monthJson = monthJsons[mKey];
      if (monthJson == null) continue;

      final dayData = CacheService.extractDay(monthJson, d.day);
      if (dayData == null) continue;

      try {
        final timings = PrayerTimings.fromCalendarDay(dayData);

        // Sanity check
        if (!timings.sanityCheck()) {
          if (kDebugMode) {
            debugPrint('[PrayerAPI] ⚠️ sanity check failed for ${dateKey(d)}');
          }
          continue;
        }

        weekMap[dateKey(d)] = timings;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[PrayerAPI] parse error for ${dateKey(d)}: $e');
        }
      }
    }

    if (weekMap.isEmpty) {
      throw Exception('Could not load prayer times for any day. Check internet and retry.');
    }

    return PrayerWeekResult(
      week: weekMap,
      offlineCached: anyNetworkFail && weekMap.isNotEmpty,
    );
  }

  /// Returns true if Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha.
  bool sanityCheck(Map<String, dynamic>? timings) {
    if (timings == null) return false;
    final order = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    int prev = -1;
    for (final name in order) {
      final raw = (timings[name] as String?)
          ?.replaceAll(RegExp(r'\s*\(.*\)'), '')
          .trim();
      if (raw == null) return false;
      final parts = raw.split(':');
      if (parts.length < 2) return false;
      final mins =
          (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      if (mins <= prev) return false;
      prev = mins;
    }
    return true;
  }
}
