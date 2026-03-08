/// Cleans timezone suffix from API time strings like "05:43 (EET)"
String cleanTime(String? raw) {
  if (raw == null || raw.isEmpty) return '00:00';
  return raw.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
}

/// Converts "17:49" → "5:49 PM"
String formatTo12Hour(String time24) {
  final parts = time24.split(':');
  if (parts.length < 2) return time24;
  int h = int.tryParse(parts[0]) ?? 0;
  final m = parts[1];
  final ampm = h >= 12 ? 'PM' : 'AM';
  if (h == 0) {
    h = 12;
  } else if (h > 12) {
    h -= 12;
  }
  return '$h:$m $ampm';
}

/// Parses "HH:MM" into a DateTime on the given date
DateTime timeToDateTime(String time24, DateTime date) {
  final parts = time24.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  return DateTime(date.year, date.month, date.day, h, m);
}

class PrayerEntry {
  final String name;
  final String time24;
  final bool isMain; // true for the 5 fard prayers

  const PrayerEntry({
    required this.name,
    required this.time24,
    this.isMain = true,
  });

  String get time12 => formatTo12Hour(time24);
}

class PrayerTimings {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String lastThird;
  final String hijriDay;
  final String hijriMonthAr;
  final String hijriYear;
  final String gregorianFormatted;

  const PrayerTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.lastThird,
    required this.hijriDay,
    required this.hijriMonthAr,
    required this.hijriYear,
    required this.gregorianFormatted,
  });

  factory PrayerTimings.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    final timings = data['timings'] as Map<String, dynamic>;
    final hijri = data['date']?['hijri'] as Map<String, dynamic>?;
    final greg = data['date']?['gregorian'] as Map<String, dynamic>?;

    String gregFormatted = '';
    if (greg != null) {
      gregFormatted =
          '${greg['weekday']?['en'] ?? ''}, ${greg['month']?['en'] ?? ''} ${greg['day'] ?? ''}, ${greg['year'] ?? ''}';
    }

    return PrayerTimings(
      fajr: cleanTime(timings['Fajr'] as String?),
      sunrise: cleanTime(timings['Sunrise'] as String?),
      dhuhr: cleanTime(timings['Dhuhr'] as String?),
      asr: cleanTime(timings['Asr'] as String?),
      maghrib: cleanTime(timings['Maghrib'] as String?),
      isha: cleanTime(timings['Isha'] as String?),
      lastThird: cleanTime(timings['Lastthird'] as String?),
      hijriDay: hijri?['day'] ?? '',
      hijriMonthAr: hijri?['month']?['ar'] ?? '',
      hijriYear: hijri?['year'] ?? '',
      gregorianFormatted: gregFormatted,
    );
  }

  /// Parse a single day entry from the calendar API response.
  /// Each entry in the calendar `data[]` array has the same structure
  /// as the single-day response's `data` field.
  factory PrayerTimings.fromCalendarDay(Map<String, dynamic> dayData) {
    return PrayerTimings.fromApiResponse({'data': dayData});
  }

  String get hijriFormatted {
    if (hijriDay.isEmpty) return '—';
    return '\u200E$hijriDay $hijriMonthAr $hijriYear هـ';
  }

  /// Main 5 prayers in schedule order (matching Figma)
  List<PrayerEntry> get mainPrayers => [
        PrayerEntry(name: 'Fajr', time24: fajr),
        PrayerEntry(name: 'Dhuhr', time24: dhuhr),
        PrayerEntry(name: 'Asr', time24: asr),
        PrayerEntry(name: 'Maghrib', time24: maghrib),
        PrayerEntry(name: 'Isha', time24: isha),
      ];

  /// Supplementary times shown below divider
  List<PrayerEntry> get supplementaryPrayers => [
        PrayerEntry(name: 'Sunrise', time24: sunrise, isMain: false),
        PrayerEntry(name: 'Last Third of Night', time24: lastThird, isMain: false),
      ];

  /// Returns the next upcoming main prayer, or null if all passed
  PrayerEntry? getNextPrayer(DateTime now) {
    for (final entry in mainPrayers) {
      final t = timeToDateTime(entry.time24, now);
      if (t.isAfter(now)) return entry;
    }
    return mainPrayers.first; // Tomorrow's Fajr
  }

  /// Countdown duration until the next prayer
  Duration getTimeUntilNext(DateTime now) {
    final next = getNextPrayer(now);
    if (next == null) return Duration.zero;
    var target = timeToDateTime(next.time24, now);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1)); // Tomorrow
    }
    return target.difference(now);
  }

  /// Apply per-prayer minute offsets. Returns a NEW PrayerTimings with adjusted times.
  /// Only main 5 prayers are offset; Sunrise and LastThird stay unchanged.
  PrayerTimings applyOffsets(Map<String, int> offsets) {
    String adjustTime(String time24, int minutes) {
      if (minutes == 0) return time24;
      final now = DateTime.now();
      final dt = timeToDateTime(time24, now).add(Duration(minutes: minutes));
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return PrayerTimings(
      fajr: adjustTime(fajr, offsets['Fajr'] ?? 0),
      sunrise: sunrise,
      dhuhr: adjustTime(dhuhr, offsets['Dhuhr'] ?? 0),
      asr: adjustTime(asr, offsets['Asr'] ?? 0),
      maghrib: adjustTime(maghrib, offsets['Maghrib'] ?? 0),
      isha: adjustTime(isha, offsets['Isha'] ?? 0),
      lastThird: lastThird,
      hijriDay: hijriDay,
      hijriMonthAr: hijriMonthAr,
      hijriYear: hijriYear,
      gregorianFormatted: gregorianFormatted,
    );
  }

  /// Check that adjusted times are in valid order:
  /// Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha
  bool sanityCheck() {
    final order = [fajr, sunrise, dhuhr, asr, maghrib, isha];
    int prev = -1;
    for (final t in order) {
      final parts = t.split(':');
      if (parts.length < 2) return false;
      final mins = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      if (mins <= prev) return false;
      prev = mins;
    }
    return true;
  }
}
