import '../backend/backend.dart';
import '../time/medication_dose_status.dart';
import '../time/pakistan_time.dart';

/// Writes `missed` rows to [dose_logs] when a dose slot passes the grace window.
abstract final class DoseMissedSync {
  static Future<void> syncForPatient(String patientId) async {
    if (patientId.isEmpty) return;

    final meds = await Backend.repo.getMedicationsForPatient(patientId);
    if (meds.isEmpty) return;

    final takenSlots = await Backend.repo.getTodayTakenDoseSlotKeys(patientId);

    for (final med in meds) {
      final raws = med.scheduleRaws.isNotEmpty
          ? med.scheduleRaws
          : [if (med.firstScheduleRaw != null) med.firstScheduleRaw!];

      for (final raw in raws) {
        if (raw.isEmpty || raw == '--:--') continue;
        final key = MedicationDoseStatusLogic.doseSlotKey(med.id, raw);
        if (takenSlots.contains(key)) continue;
        if (MedicationDoseStatusLogic.fromScheduleRaw(raw) !=
            MedicationDoseStatus.missed) {
          continue;
        }

        final medMin = PakistanTime.parseScheduleToMinutes(raw);
        if (medMin == null) continue;
        final pkt = PakistanTime.now();
        if (PakistanTime.minutesOfDay(pkt) <= medMin) continue;

        try {
          await Backend.repo.confirmDose(
            patientId: patientId,
            medicationId: med.id,
            status: 'missed',
            scheduleRaw: raw,
          );
        } catch (_) {
          // RLS or duplicate — UI still shows missed from schedule logic.
        }
      }
    }
  }
}
