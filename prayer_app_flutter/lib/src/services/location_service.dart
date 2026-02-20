import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted location data.
class LocationData {
  final double lat;
  final double lon;
  final String city;
  final String country;
  final String timezone;
  final String source; // "gps" or "default"

  const LocationData({
    required this.lat,
    required this.lon,
    required this.city,
    required this.country,
    required this.timezone,
    required this.source,
  });

  static const LocationData fallback = LocationData(
    lat: 44.4268,
    lon: 26.1025,
    city: 'Bucharest',
    country: 'Romania',
    timezone: 'Europe/Bucharest',
    source: 'default',
  );
}

class LocationService {
  static const String _kLat = 'loc_lat';
  static const String _kLon = 'loc_lon';
  static const String _kCity = 'loc_city';
  static const String _kCountry = 'loc_country';
  static const String _kTz = 'loc_timezone';
  static const String _kSource = 'loc_source';

  /// Load persisted location, or return fallback.
  Future<LocationData> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_kSource);
    if (source == null) return LocationData.fallback;
    return LocationData(
      lat: prefs.getDouble(_kLat) ?? LocationData.fallback.lat,
      lon: prefs.getDouble(_kLon) ?? LocationData.fallback.lon,
      city: prefs.getString(_kCity) ?? 'Unknown',
      country: prefs.getString(_kCountry) ?? '',
      timezone: prefs.getString(_kTz) ?? LocationData.fallback.timezone,
      source: source,
    );
  }

  /// Request permission, get coords, reverse geocode, persist.
  /// Returns the detected or fallback LocationData.
  Future<LocationData> detect() async {
    // 1. Check / request permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      // Permission denied → save and return fallback
      await _persist(LocationData.fallback);
      return LocationData.fallback;
    }

    // 2. Get coordinates
    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      await _persist(LocationData.fallback);
      return LocationData.fallback;
    }

    // 3. Reverse geocode
    String city = 'Unknown';
    String country = '';
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? 'Unknown';
        country = p.country ?? '';
      }
    } catch (_) {
      // Keep city = 'Unknown'
    }

    // 4. Timezone — detect from device
    final deviceTz = _getDeviceTimezone();

    final data = LocationData(
      lat: pos.latitude,
      lon: pos.longitude,
      city: city,
      country: country,
      timezone: deviceTz,
      source: 'gps',
    );

    await _persist(data);
    return data;
  }

  /// Get device IANA timezone string.
  /// DateTime.timeZoneName may return abbreviations on some platforms,
  /// so we try mapping common ones. Falls back to the abbreviation itself.
  String _getDeviceTimezone() {
    final tz = DateTime.now().timeZoneName;
    // If it already looks like IANA (contains '/'), use it directly
    if (tz.contains('/')) return tz;
    // Common abbreviation → IANA mapping
    const abbrevMap = {
      'PST': 'America/Los_Angeles',
      'PDT': 'America/Los_Angeles',
      'MST': 'America/Denver',
      'MDT': 'America/Denver',
      'CST': 'America/Chicago',
      'CDT': 'America/Chicago',
      'EST': 'America/New_York',
      'EDT': 'America/New_York',
      'GMT': 'Europe/London',
      'BST': 'Europe/London',
      'CET': 'Europe/Berlin',
      'CEST': 'Europe/Berlin',
      'EET': 'Europe/Bucharest',
      'EEST': 'Europe/Bucharest',
      'IST': 'Asia/Kolkata',
      'JST': 'Asia/Tokyo',
      'KST': 'Asia/Seoul',
      'AEST': 'Australia/Sydney',
      'AEDT': 'Australia/Sydney',
      'NZST': 'Pacific/Auckland',
      'NZDT': 'Pacific/Auckland',
      'AST': 'Asia/Riyadh',
      'GST': 'Asia/Dubai',
      'PKT': 'Asia/Karachi',
      'WIB': 'Asia/Jakarta',
      'SGT': 'Asia/Singapore',
      'HKT': 'Asia/Hong_Kong',
      'PHT': 'Asia/Manila',
      'ICT': 'Asia/Bangkok',
      'TRT': 'Europe/Istanbul',
    };
    return abbrevMap[tz] ?? LocationData.fallback.timezone;
  }

  Future<void> _persist(LocationData d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLat, d.lat);
    await prefs.setDouble(_kLon, d.lon);
    await prefs.setString(_kCity, d.city);
    await prefs.setString(_kCountry, d.country);
    await prefs.setString(_kTz, d.timezone);
    await prefs.setString(_kSource, d.source);
  }
}

/// Reactive wrapper so UI rebuilds when location changes.
class LocationNotifier extends ChangeNotifier {
  final LocationService _svc = LocationService();

  LocationData _data = LocationData.fallback;
  LocationData get data => _data;

  Future<void> load() async {
    _data = await _svc.loadSaved();
    notifyListeners();
  }

  Future<void> detect() async {
    _data = await _svc.detect();
    // Invalidate prayer cache so SalahScreen refetches with new coords
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_prayer_date');
    notifyListeners();
  }
}
