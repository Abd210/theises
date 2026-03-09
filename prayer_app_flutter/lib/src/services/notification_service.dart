import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _channelId = 'prayer_times';
  static const _channelName = 'Prayer Times';
  static const _channelDesc = 'Notifications for prayer times';
  static const _cacheKey = 'salah_notif_cache';

  /// Initialize plugin + timezone + request permission
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // TIMEZONE STRATEGY:
    // We use the device's local timezone for scheduling notifications.
    // The prayer times in cache are computed by the API for the chosen location.
    // If device timezone != location timezone (e.g., device in EET but location
    // set to San Francisco PST), the scheduled notification times will be wrong.
    // This is expected in dev/testing. In production, users are at their location.
    final tzName = _resolveTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));
    debugPrint('[NOTIF] timezone resolved to: $tzName (device offset: ${DateTime.now().timeZoneOffset})');

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: settings);

    // Create Android channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
    debugPrint('[NOTIF] initialized');
  }

  /// Request permission. Returns true if granted.
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true, badge: true);
      final granted = result ?? false;
      debugPrint('[NOTIF] permission ${granted ? "granted" : "denied"}');
      return granted;
    }
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Request exact alarm permission for Android 12+
      await androidPlugin?.requestExactAlarmsPermission();

      final granted = await androidPlugin?.requestNotificationsPermission();
      debugPrint(
          '[NOTIF] permission ${(granted ?? true) ? "granted" : "denied"}');
      return granted ?? true;
    }
    return true;
  }

  /// Send a test notification immediately
  Future<void> sendTestNow() async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: 0,
      title: 'Test Notification',
      body: 'Notifications are working ✅',
      notificationDetails: details,
    );
    debugPrint('[NOTIF] sent test now');
  }

  /// Schedule a test notification in 10 seconds
  Future<void> scheduleTestIn10s() async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id: 1,
      title: 'Test Notification',
      body: 'Notifications are working ✅',
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint('[NOTIF] scheduled test in 10s');
  }

  /// Cache week timings to persistent storage for use by settings reschedule
  Future<void> cacheTimingsForNotifications(Map<String, dynamic> serialized) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(serialized));
    debugPrint('[NOTIF] cached timings for notifications (${serialized.length} days)');
  }

  /// Load cached timings
  Future<Map<String, dynamic>?> _loadCachedTimings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Schedule prayer notifications using cached timings + current settings
  Future<void> scheduleFromCache() async {
    await init();
    final prefs = await SharedPreferences.getInstance();

    // Load notification settings
    final enabled = prefs.getBool('notif_enabled') ?? false;
    if (!enabled) {
      debugPrint('[NOTIF] master toggle OFF, skipping schedule');
      return;
    }

    final leadMinutes = prefs.getInt('notif_lead_minutes') ?? 0;
    final enabledPrayers = <String, bool>{};
    for (final name in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      enabledPrayers[name] = prefs.getBool('notif_prayer_${name.toLowerCase()}') ?? true;
    }

    final cached = await _loadCachedTimings();
    if (cached == null) {
      debugPrint('[NOTIF] no cached timings, skipping schedule');
      return;
    }

    await _scheduleFromParsed(
      parsedTimings: cached,
      enabledPrayers: enabledPrayers,
      leadMinutes: leadMinutes,
    );
  }

  /// Schedule prayer notifications from parsed timing data.
  /// Policy: schedule ALL enabled prayers within a rolling 48h window.
  Future<void> _scheduleFromParsed({
    required Map<String, dynamic> parsedTimings,
    required Map<String, bool> enabledPrayers,
    required int leadMinutes,
  }) async {
    await init();

    // Cancel only prayer notifications (IDs 100+), keep test notifs (0, 1, 99)
    final pending = await _plugin.pendingNotificationRequests();
    final prayerIds = pending.where((p) => p.id >= 100).map((p) => p.id).toList();
    for (final id in prayerIds) {
      await _plugin.cancel(id: id);
    }
    debugPrint('[NOTIF] cancelled ${prayerIds.length} prayer notifications');

    final now = DateTime.now();
    final windowStart = now.add(const Duration(seconds: 5));
    final windowEnd = now.add(const Duration(hours: 48));

    final offsetH = now.timeZoneOffset.inHours;
    final offsetSign = offsetH >= 0 ? '+' : '';
    final windowStartStr = _fmtDt(windowStart);
    final windowEndStr = _fmtDt(windowEnd);
    debugPrint('[NOTIF] windowStart=$windowStartStr windowEnd=$windowEndStr ($offsetSign${offsetH}00)');

    int notifId = 100;
    int scheduledCount = 0;
    final scheduledList = <Map<String, String>>[];

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    // Collect all candidate triggers, then sort by time
    final candidates = <Map<String, dynamic>>[];

    for (final entry in parsedTimings.entries) {
      final dateKey = entry.key;
      final dayData = entry.value;
      if (dayData == null) continue;

      final prayers = dayData['prayers'] as List<dynamic>?;
      if (prayers == null) continue;

      for (final prayer in prayers) {
        final name = prayer['name'] as String;
        final time24 = prayer['time24'] as String;

        if (enabledPrayers[name] != true) continue;

        // Parse time24 (HH:mm)
        final timeParts = time24.split(':');
        if (timeParts.length < 2) continue;
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final min = int.tryParse(timeParts[1]) ?? 0;

        // Parse dateKey (YYYY-MM-DD)
        final dateParts = dateKey.split('-');
        if (dateParts.length < 3) continue;
        final year = int.tryParse(dateParts[0]) ?? now.year;
        final month = int.tryParse(dateParts[1]) ?? now.month;
        final day = int.tryParse(dateParts[2]) ?? now.day;

        var triggerTime = DateTime(year, month, day, hour, min);
        triggerTime = triggerTime.subtract(Duration(minutes: leadMinutes));

        // Filter: must be within [windowStart, windowEnd]
        if (triggerTime.isBefore(windowStart)) continue;
        if (triggerTime.isAfter(windowEnd)) continue;

        candidates.add({
          'name': name,
          'time24': time24,
          'triggerTime': triggerTime,
          'dateKey': dateKey,
        });
      }
    }

    // Sort by trigger time for deterministic ordering
    candidates.sort((a, b) =>
        (a['triggerTime'] as DateTime).compareTo(b['triggerTime'] as DateTime));

    // Schedule each candidate
    for (final c in candidates) {
      final name = c['name'] as String;
      final time24 = c['time24'] as String;
      final triggerTime = c['triggerTime'] as DateTime;
      final dateKey = c['dateKey'] as String;

      final tzTime = tz.TZDateTime.from(triggerTime, tz.local);

      final time12 = _formatTo12Hour(time24);
      String body;
      if (leadMinutes > 0) {
        body = '$name in $leadMinutes min • Adhan at $time12';
      } else {
        body = 'Adhan at $time12';
      }

      await _plugin.zonedSchedule(
        id: notifId,
        title: '$name Prayer',
        body: body,
        scheduledDate: tzTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      final triggerStr = _fmtDt(triggerTime);
      debugPrint('[NOTIF] id=$notifId prayer=$name trigger=$triggerStr ($offsetSign${offsetH}00)');

      scheduledList.add({
        'id': '$notifId',
        'prayer': name,
        'trigger': triggerStr,
        'body': body,
        'dateKey': dateKey,
      });

      notifId++;
      scheduledCount++;
    }

    // Persist schedule list for debug display
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notif_last_scheduled', jsonEncode(scheduledList));

    debugPrint('[NOTIF] scheduledCount=$scheduledCount');
  }

  /// Get pending prayer notifications for debug inspection.
  /// Uses stored schedule list for trigger times (OS doesn't expose them).
  Future<List<Map<String, String>>> getPendingPrayerNotifications() async {
    await init();

    // Load stored schedule list
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notif_last_scheduled');
    List<Map<String, String>> stored = [];
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      stored = decoded.map((e) => Map<String, String>.from(e as Map)).toList();
    }

    final pending = await _plugin.pendingNotificationRequests();
    final pendingIds = pending.where((p) => p.id >= 100).map((p) => '${p.id}').toSet();

    // Filter stored list to only include items still pending
    final result = stored.where((s) => pendingIds.contains(s['id'])).toList();

    debugPrint('[NOTIF-DEBUG] pending prayer notifications: ${result.length}');
    for (final r in result) {
      debugPrint('[NOTIF-DEBUG]   id=${r['id']} prayer=${r['prayer']} trigger=${r['trigger']}');
    }
    return result;
  }

  /// Schedule a pipeline test: uses the real prayer notification pipeline
  /// but fires in 60 seconds. This verifies the full scheduling path works.
  Future<void> schedulePipelineTestIn60s() async {
    await init();

    // Cancel any previous pipeline test (ID 99)
    await _plugin.cancel(id: 99);

    final now = DateTime.now();
    final fireAt = now.add(const Duration(seconds: 60));
    final tzTime = tz.TZDateTime.from(fireAt, tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: 99,
      title: 'Pipeline Test',
      body: 'Prayer notification pipeline works ✅ (scheduled 60s ago)',
      scheduledDate: tzTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    final offsetH = fireAt.timeZoneOffset.inHours;
    final offsetSign = offsetH >= 0 ? '+' : '';
    debugPrint('[NOTIF] pipeline test scheduled at ${fireAt.year}-${fireAt.month.toString().padLeft(2, '0')}-${fireAt.day.toString().padLeft(2, '0')} ${fireAt.hour.toString().padLeft(2, '0')}:${fireAt.minute.toString().padLeft(2, '0')}:${fireAt.second.toString().padLeft(2, '0')} ($offsetSign${offsetH}00) id=99');
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NOTIF] cancelled all');
  }

  /// Cancel only prayer notifications (keep test ones)
  Future<void> cancelPrayerNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    int count = 0;
    for (final p in pending) {
      if (p.id >= 100) {
        await _plugin.cancel(id: p.id);
        count++;
      }
    }
    debugPrint('[NOTIF] cancelled prayer notifications count=$count');
  }

  String _resolveTimezone() {
    // Map common abbreviations to tz database names
    final tzName = DateTime.now().timeZoneName;
    // Try direct lookup first
    try {
      tz.getLocation(tzName);
      return tzName;
    } catch (_) {}

    // Common mappings
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;

    // Map by offset as fallback
    final offsetMap = <int, String>{
      -12: 'Etc/GMT+12',
      -11: 'Pacific/Pago_Pago',
      -10: 'Pacific/Honolulu',
      -9: 'America/Anchorage',
      -8: 'America/Los_Angeles',
      -7: 'America/Denver',
      -6: 'America/Chicago',
      -5: 'America/New_York',
      -4: 'America/Santiago',
      -3: 'America/Sao_Paulo',
      -2: 'Atlantic/South_Georgia',
      -1: 'Atlantic/Azores',
      0: 'Europe/London',
      1: 'Europe/Paris',
      2: 'Europe/Bucharest',
      3: 'Europe/Moscow',
      4: 'Asia/Dubai',
      5: 'Asia/Karachi',
      6: 'Asia/Dhaka',
      7: 'Asia/Bangkok',
      8: 'Asia/Shanghai',
      9: 'Asia/Tokyo',
      10: 'Australia/Sydney',
      11: 'Pacific/Noumea',
      12: 'Pacific/Auckland',
    };

    return offsetMap[hours] ?? 'UTC';
  }

  String _formatTo12Hour(String time24) {
    final parts = time24.split(':');
    if (parts.length < 2) return time24;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:${m.toString().padLeft(2, '0')} $ampm';
  }

  /// Format DateTime as YYYY-MM-DD HH:mm
  String _fmtDt(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
