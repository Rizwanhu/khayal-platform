/// Pakistan Standard Time (UTC+5, no daylight saving).
class PakistanTime {
  PakistanTime._();

  static const Duration _pktOffset = Duration(hours: 5);

  /// Current clock in Pakistan, independent of device local timezone.
  static DateTime now() => DateTime.now().toUtc().add(_pktOffset);

  static int minutesOfDay(DateTime pkt) => pkt.hour * 60 + pkt.minute;

  /// Start of the PKT calendar day as UTC instant (for Supabase `timestamptz` filters).
  static DateTime dayStartUtc(DateTime pkt) {
    return DateTime.utc(pkt.year, pkt.month, pkt.day).subtract(_pktOffset);
  }

  static DateTime dayEndUtc(DateTime pkt) {
    return dayStartUtc(pkt).add(const Duration(days: 1));
  }

  /// Today's scheduled dose instant in UTC for [scheduleRaw] on the PKT calendar day.
  static DateTime scheduledForTodayUtc(String? scheduleRaw) {
    final pkt = now();
    final medMin = parseScheduleToMinutes(scheduleRaw);
    if (medMin == null) {
      return DateTime.utc(pkt.year, pkt.month, pkt.day, pkt.hour, pkt.minute)
          .subtract(_pktOffset);
    }
    final h = medMin ~/ 60;
    final m = medMin % 60;
    return DateTime.utc(pkt.year, pkt.month, pkt.day, h, m).subtract(_pktOffset);
  }

  /// PKT wall-clock from a UTC instant (e.g. Supabase `scheduled_for`).
  static DateTime pktFromUtc(DateTime utc) => utc.toUtc().add(_pktOffset);

  /// Normalized `HH:mm:ss` for comparing schedule slots to dose logs.
  static String normalizeScheduleRaw(String raw) {
    final min = parseScheduleToMinutes(raw);
    if (min == null) return raw.trim();
    final h = min ~/ 60;
    final m = min % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
  }

  static String scheduleRawFromUtc(DateTime scheduledForUtc) {
    final pkt = pktFromUtc(scheduledForUtc);
    return '${pkt.hour.toString().padLeft(2, '0')}:${pkt.minute.toString().padLeft(2, '0')}:00';
  }

  /// Parses `HH:mm` or `HH:mm:ss` schedule strings to minutes since midnight.
  static int? parseScheduleToMinutes(String? raw) {
    if (raw == null || raw.isEmpty || raw == '--:--') return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }
}
