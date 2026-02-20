import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/prayer_times.dart';
import 'cache_service.dart';

class PrayerApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1/timings';
  static const double _lat = 44.4268;
  static const double _lng = 26.1025;
  static const int _method = 2; // ISNA
  static const String _timezone = 'Europe/Bucharest';

  final CacheService _cache = CacheService();

  Future<PrayerTimings> fetchToday() async {
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(now);

    // Try cache first
    final cachedDate = await _cache.getCachedDate();
    if (cachedDate == dateStr) {
      final cached = await _cache.load();
      if (cached != null) {
        return PrayerTimings.fromApiResponse(json.decode(cached));
      }
    }

    // Fetch from API
    final url = '$_baseUrl/$dateStr?latitude=$_lat&longitude=$_lng'
        '&method=$_method&timezonestring=$_timezone';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      await _cache.save(response.body, dateStr);
      return PrayerTimings.fromApiResponse(json.decode(response.body));
    } else {
      // Fallback to cache
      final cached = await _cache.load();
      if (cached != null) {
        return PrayerTimings.fromApiResponse(json.decode(cached));
      }
      throw Exception('Failed to load prayer times (${response.statusCode})');
    }
  }
}
