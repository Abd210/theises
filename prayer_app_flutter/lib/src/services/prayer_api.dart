import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/prayer_times.dart';
import 'cache_service.dart';
import 'location_service.dart';

class PrayerFetchResult {
  final PrayerTimings timings;
  final bool offlineCached;

  const PrayerFetchResult({required this.timings, required this.offlineCached});
}

class PrayerApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1/timings';

  final CacheService _cache = CacheService();

  Future<PrayerFetchResult> fetchToday({
    required int methodId,
    required int school,
  }) async {
    // Read detected/persisted location
    final locSvc = LocationService();
    final loc = await locSvc.loadSaved();

    final now = DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(now);

    // Cache key includes coords so changing location forces re-fetch
    final cacheTag =
        '${dateStr}_${loc.lat.toStringAsFixed(2)}_${loc.lon.toStringAsFixed(2)}_${methodId}_$school';

    // Try exact-day cache first.
    final cachedDate = await _cache.getCachedDate();
    if (cachedDate == cacheTag) {
      final cached = await _cache.load();
      if (cached != null) {
        return PrayerFetchResult(
          timings: PrayerTimings.fromApiResponse(json.decode(cached)),
          offlineCached: false,
        );
      }
    }

    // Fetch from API — NO timezonestring; let API auto-detect from lat/lon
    final url =
        '$_baseUrl/$dateStr?latitude=${loc.lat}&longitude=${loc.lon}'
        '&method=$methodId&school=$school';

    if (kDebugMode) debugPrint('[PrayerAPI] URL: $url');

    http.Response response;
    try {
      response = await http.get(Uri.parse(url));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PrayerAPI] Request failed: url=$url error=$e');
      }
      final cached = await _cache.load();
      if (cached != null) {
        return PrayerFetchResult(
          timings: PrayerTimings.fromApiResponse(json.decode(cached)),
          offlineCached: true,
        );
      }
      throw Exception('Could not load prayer times. Check internet and retry.');
    }

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final timings = body['data']?['timings'];
      final metaTz = body['data']?['meta']?['timezone'];
      debugPrint('[PrayerAPI] meta.timezone=$metaTz');
      debugPrint(
        '[PrayerAPI] Fajr=${timings?['Fajr']} Sunrise=${timings?['Sunrise']} '
        'Dhuhr=${timings?['Dhuhr']} Asr=${timings?['Asr']} '
        'Maghrib=${timings?['Maghrib']} Isha=${timings?['Isha']}',
      );

      // Sanity check: Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha
      if (!_sanityCheck(timings)) {
        debugPrint(
          '[PrayerAPI] ⚠️ SANITY CHECK FAILED — timings not in expected order',
        );
        debugPrint(
          '[PrayerAPI] meta.timezone=$metaTz lat=${loc.lat} lon=${loc.lon}',
        );
        throw Exception('Invalid timing data — prayer order check failed');
      }

      await _cache.save(response.body, cacheTag);
      return PrayerFetchResult(
        timings: PrayerTimings.fromApiResponse(body),
        offlineCached: false,
      );
    } else {
      if (kDebugMode) {
        debugPrint(
          '[PrayerAPI] Request failed: url=$url status=${response.statusCode}',
        );
      }
      // Fallback to cache
      final cached = await _cache.load();
      if (cached != null) {
        return PrayerFetchResult(
          timings: PrayerTimings.fromApiResponse(json.decode(cached)),
          offlineCached: true,
        );
      }
      throw Exception('Could not load prayer times. Check internet and retry.');
    }
  }

  /// Returns true if Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha.
  bool _sanityCheck(Map<String, dynamic>? timings) {
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
