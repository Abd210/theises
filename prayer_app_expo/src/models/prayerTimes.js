// Cleans timezone suffix from API time strings like "05:43 (EET)"
export function cleanTime(raw) {
    if (!raw) return '00:00';
    return raw.replace(/\s*\(.*\)/, '').trim();
}

// Converts "17:49" → "5:49 PM"
export function formatTo12Hour(time24) {
    const parts = time24.split(':');
    if (parts.length < 2) return time24;
    let h = parseInt(parts[0], 10) || 0;
    const m = parts[1];
    const ampm = h >= 12 ? 'PM' : 'AM';
    if (h === 0) h = 12;
    else if (h > 12) h -= 12;
    return `${h}:${m} ${ampm}`;
}

// Parses "HH:MM" into a Date on the given date
export function timeToDate(time24, date) {
    const parts = time24.split(':');
    const h = parseInt(parts[0], 10) || 0;
    const m = parseInt(parts[1], 10) || 0;
    const d = new Date(date);
    d.setHours(h, m, 0, 0);
    return d;
}

// Parse API response into a PrayerTimings object
export function parsePrayerTimings(json) {
    const data = json.data;
    const timings = data.timings;
    const hijri = data.date?.hijri;
    const greg = data.date?.gregorian;

    const gregorianFormatted = greg
        ? `${greg.weekday?.en || ''}, ${greg.month?.en || ''} ${greg.day || ''}, ${greg.year || ''}`
        : '';

    return {
        fajr: cleanTime(timings.Fajr),
        sunrise: cleanTime(timings.Sunrise),
        dhuhr: cleanTime(timings.Dhuhr),
        asr: cleanTime(timings.Asr),
        maghrib: cleanTime(timings.Maghrib),
        isha: cleanTime(timings.Isha),
        lastThird: cleanTime(timings.Lastthird),
        hijriDay: hijri?.day || '',
        hijriMonthAr: hijri?.month?.ar || '',
        hijriYear: hijri?.year || '',
        gregorianFormatted,
        get hijriFormatted() {
            if (!this.hijriDay) return '—';
            return `${this.hijriDay} ${this.hijriMonthAr} ${this.hijriYear} هـ`;
        },
        get mainPrayers() {
            return [
                { name: 'Fajr', time24: this.fajr, time12: formatTo12Hour(this.fajr), isMain: true },
                { name: 'Dhuhr', time24: this.dhuhr, time12: formatTo12Hour(this.dhuhr), isMain: true },
                { name: 'Asr', time24: this.asr, time12: formatTo12Hour(this.asr), isMain: true },
                { name: 'Maghrib', time24: this.maghrib, time12: formatTo12Hour(this.maghrib), isMain: true },
                { name: 'Isha', time24: this.isha, time12: formatTo12Hour(this.isha), isMain: true },
            ];
        },
        get supplementaryPrayers() {
            return [
                { name: 'Sunrise', time24: this.sunrise, time12: formatTo12Hour(this.sunrise), isMain: false },
                { name: 'Last Third of Night', time24: this.lastThird, time12: formatTo12Hour(this.lastThird), isMain: false },
            ];
        },
    };
}

// Returns the next upcoming main prayer
export function getNextPrayer(timings, now) {
    const prayers = timings.mainPrayers;
    for (const p of prayers) {
        const t = timeToDate(p.time24, now);
        if (t > now) return p;
    }
    return prayers[0]; // Tomorrow's Fajr
}

// Duration (ms) until the next prayer
export function getTimeUntilNext(timings, now) {
    const next = getNextPrayer(timings, now);
    if (!next) return 0;
    let target = timeToDate(next.time24, now);
    if (target <= now) {
        target = new Date(target.getTime() + 24 * 60 * 60 * 1000);
    }
    return target.getTime() - now.getTime();
}

// Format milliseconds as "HH:MM:SS"
export function formatCountdown(ms) {
    if (ms <= 0) return '00:00:00';
    const totalSec = Math.floor(ms / 1000);
    const h = String(Math.floor(totalSec / 3600)).padStart(2, '0');
    const m = String(Math.floor((totalSec % 3600) / 60)).padStart(2, '0');
    const s = String(totalSec % 60).padStart(2, '0');
    return `${h}:${m}:${s}`;
}
