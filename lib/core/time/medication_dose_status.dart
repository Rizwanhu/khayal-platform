import 'pakistan_time.dart';

/// Dose timing relative to schedule in Pakistan time.
enum MedicationDoseStatus {
  /// More than [dueSoonMinutesBefore] before the scheduled dose.
  upcoming,

  /// Within 30 minutes before dose, or overdue but inside the grace window.
  dueSoon,

  /// Grace window elapsed without a logged dose.
  missed,
}

class MedicationDoseStatusLogic {
  MedicationDoseStatusLogic._();

  /// Red highlight window before the scheduled time.
  static const int dueSoonMinutesBefore = 30;

  /// Minutes after scheduled time before marking as missed.
  static const int missedAfterMinutes = 5;

  static MedicationDoseStatus fromScheduleRaw(String? raw) {
    final medMin = PakistanTime.parseScheduleToMinutes(raw);
    if (medMin == null) return MedicationDoseStatus.upcoming;

    final nowMin = PakistanTime.minutesOfDay(PakistanTime.now());

    if (nowMin > medMin + missedAfterMinutes) {
      return MedicationDoseStatus.missed;
    }
    if (nowMin >= medMin - dueSoonMinutesBefore) {
      return MedicationDoseStatus.dueSoon;
    }
    return MedicationDoseStatus.upcoming;
  }

  /// Status for a medication with multiple daily times (e.g. 10:00 and 22:20).
  ///
  /// Uses the best actionable state: a later dose still upcoming must not be
  /// hidden because an earlier slot is already missed.
  static MedicationDoseStatus fromScheduleRaws(Iterable<String?> schedules) {
    final raws = schedules
        .whereType<String>()
        .where((s) => s.isNotEmpty && s != '--:--')
        .toList();
    if (raws.isEmpty) return MedicationDoseStatus.upcoming;

    final statuses = raws.map(fromScheduleRaw).toList();
    if (statuses.any((s) => s == MedicationDoseStatus.dueSoon)) {
      return MedicationDoseStatus.dueSoon;
    }
    if (statuses.any((s) => s == MedicationDoseStatus.upcoming)) {
      return MedicationDoseStatus.upcoming;
    }
    return MedicationDoseStatus.missed;
  }

  /// Next dose time to confirm or highlight (upcoming / due soon first).
  static String? nextActionableScheduleRaw(Iterable<String?> schedules) {
    final sorted = sortScheduleRaws(schedules);
    for (final raw in sorted) {
      final status = fromScheduleRaw(raw);
      if (status == MedicationDoseStatus.upcoming ||
          status == MedicationDoseStatus.dueSoon) {
        return raw;
      }
    }
    return sorted.isNotEmpty ? sorted.last : null;
  }

  static List<String> sortScheduleRaws(Iterable<String?> schedules) {
    final pairs = <int, String>{};
    for (final raw in schedules) {
      if (raw == null || raw.isEmpty || raw == '--:--') continue;
      final min = PakistanTime.parseScheduleToMinutes(raw);
      if (min == null) continue;
      pairs[min] = raw;
    }
    final keys = pairs.keys.toList()..sort();
    return keys.map((k) => pairs[k]!).toList();
  }

  /// True when [nowMin] is still before the scheduled dose minute.
  static bool isBeforeScheduledDose(String? raw) {
    final medMin = PakistanTime.parseScheduleToMinutes(raw);
    if (medMin == null) return true;
    final nowMin = PakistanTime.minutesOfDay(PakistanTime.now());
    return nowMin < medMin;
  }

  /// Key for a single daily dose slot (`medicationId|HH:mm:ss`).
  static String doseSlotKey(String medicationId, String scheduleRaw) {
    return '$medicationId|${PakistanTime.normalizeScheduleRaw(scheduleRaw)}';
  }

  /// Counts each scheduled time today — not whole medicines.
  static TodayDoseSlotCounts countTodaySlots({
    required Iterable<({String medicationId, List<String> scheduleRaws})> meds,
    required Set<String> takenSlotKeys,
  }) {
    var taken = 0;
    var missed = 0;
    var upcoming = 0;

    for (final med in meds) {
      final raws = med.scheduleRaws
          .where((s) => s.isNotEmpty && s != '--:--')
          .toList();
      if (raws.isEmpty) continue;

      for (final raw in raws) {
        final key = doseSlotKey(med.medicationId, raw);
        if (takenSlotKeys.contains(key)) {
          taken++;
          continue;
        }
        switch (fromScheduleRaw(raw)) {
          case MedicationDoseStatus.missed:
            missed++;
          case MedicationDoseStatus.upcoming:
          case MedicationDoseStatus.dueSoon:
            upcoming++;
        }
      }
    }

    return TodayDoseSlotCounts(
      taken: taken,
      missed: missed,
      upcoming: upcoming,
    );
  }

  /// Card-level status when a medicine has multiple daily times.
  static MedicationDoseStatus statusForMedicationSlots({
    required List<String> scheduleRaws,
    required Set<String> takenSlotKeys,
    required String medicationId,
  }) {
    final raws = scheduleRaws
        .where((s) => s.isNotEmpty && s != '--:--')
        .toList();
    if (raws.isEmpty) return MedicationDoseStatus.upcoming;

    final open = <MedicationDoseStatus>[];
    for (final raw in raws) {
      if (takenSlotKeys.contains(doseSlotKey(medicationId, raw))) continue;
      open.add(fromScheduleRaw(raw));
    }
    if (open.isEmpty) return MedicationDoseStatus.upcoming;

    if (open.any((s) => s == MedicationDoseStatus.dueSoon)) {
      return MedicationDoseStatus.dueSoon;
    }
    if (open.any((s) => s == MedicationDoseStatus.upcoming)) {
      return MedicationDoseStatus.upcoming;
    }
    return MedicationDoseStatus.missed;
  }

  static int countTakenSlotsForMedication({
    required String medicationId,
    required List<String> scheduleRaws,
    required Set<String> takenSlotKeys,
  }) {
    return scheduleRaws
        .where(
          (r) =>
              r.isNotEmpty &&
              r != '--:--' &&
              takenSlotKeys.contains(doseSlotKey(medicationId, r)),
        )
        .length;
  }
}

/// Per-dose-slot totals for the home summary bar.
class TodayDoseSlotCounts {
  const TodayDoseSlotCounts({
    required this.taken,
    required this.missed,
    required this.upcoming,
  });

  final int taken;
  final int missed;
  final int upcoming;
}
