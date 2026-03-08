import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /// Initialize plugin + timezone + request permission
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_resolveTimezone()));

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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    debugPrint('[NOTIF] scheduled test in 10s');
  }

  /// Schedule prayer notifications for upcoming prayers
  /// [timingsMap]: dateKey -> PrayerTimings
  /// [city]: city name for notification body
  /// [enabledPrayers]: map of prayer name -> enabled
  /// [leadMinutes]: minutes before adhan to notify
  Future<void> scheduleAllPrayers({
    required Map<String, dynamic> timingsMap,
    required String city,
    required Map<String, bool> enabledPrayers,
    required int leadMinutes,
  }) async {
    await init();

    // Cancel all previously scheduled prayer notifications (IDs 100+)
    final pending = await _plugin.pendingNotificationRequests();
    int cancelCount = 0;
    for (final p in pending) {
      if (p.id >= 100) {
        await _plugin.cancel(id: p.id);
        cancelCount++;
      }
    }
    debugPrint('[NOTIF] cancelled previous scheduled notifications count=$cancelCount');

    final now = DateTime.now();
    int notifId = 100;

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

    for (final entry in timingsMap.entries) {
      final t = entry.value;
      if (t == null) continue;

      // Access mainPrayers list
      final prayers = t.mainPrayers as List<dynamic>;
      for (final prayer in prayers) {
        final name = prayer.name as String;

        // Check if this prayer is enabled
        if (enabledPrayers[name] != true) continue;

        // Parse time24 (HH:mm)
        final parts = (prayer.time24 as String).split(':');
        if (parts.length < 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final min = int.tryParse(parts[1]) ?? 0;

        // Parse date from dateKey (YYYY-MM-DD)
        final dateParts = entry.key.split('-');
        if (dateParts.length < 3) continue;
        final year = int.tryParse(dateParts[0]) ?? now.year;
        final month = int.tryParse(dateParts[1]) ?? now.month;
        final day = int.tryParse(dateParts[2]) ?? now.day;

        var scheduledTime = DateTime(year, month, day, hour, min);
        scheduledTime = scheduledTime.subtract(Duration(minutes: leadMinutes));

        // Skip past times
        if (scheduledTime.isBefore(now)) continue;

        final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

        String body;
        if (leadMinutes > 0) {
          body = '$name in $leadMinutes min • Adhan at ${prayer.time12} • $city';
        } else {
          body = 'Adhan at ${prayer.time12} • $city';
        }

        await _plugin.zonedSchedule(
          id: notifId,
          title: '$name Prayer',
          body: body,
          scheduledDate: tzTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        debugPrint('[NOTIF] scheduled $name at $tzTime id=$notifId');
        notifId++;
      }
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NOTIF] cancelled all');
  }

  String _resolveTimezone() {
    try {
      // Fallback to UTC if we can't determine
      return 'UTC';
    } catch (_) {
      return 'UTC';
    }
  }
}
