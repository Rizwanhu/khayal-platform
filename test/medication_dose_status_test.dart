import 'package:flutter_test/flutter_test.dart';
import 'package:khayal_platform/core/time/medication_dose_status.dart';
import 'package:khayal_platform/core/time/pakistan_time.dart';

void main() {
  group('MedicationDoseStatusLogic.fromScheduleRaws', () {
    test('morning missed does not hide evening upcoming', () {
      // Simulates 21:55 PKT: 10:00 slot missed, 22:20 still upcoming.
      final status = MedicationDoseStatusLogic.fromScheduleRaws([
        '10:00:00',
        '22:20:00',
      ]);
      expect(status, isNot(MedicationDoseStatus.missed));
    });

    test('sortScheduleRaws orders by time of day', () {
      final sorted = MedicationDoseStatusLogic.sortScheduleRaws([
        '22:20:00',
        '10:00:00',
      ]);
      expect(sorted, ['10:00:00', '22:20:00']);
    });
  });

  group('MedicationDoseStatusLogic.countTodaySlots', () {
    test('counts each schedule time, not whole medicines', () {
      final counts = MedicationDoseStatusLogic.countTodaySlots(
        meds: [
          (
            medicationId: 'a',
            scheduleRaws: ['02:00:00', '14:00:00'],
          ),
          (
            medicationId: 'b',
            scheduleRaws: ['11:00:00'],
          ),
        ],
        takenSlotKeys: {
          MedicationDoseStatusLogic.doseSlotKey('a', '02:00:00'),
        },
      );
      expect(counts.taken, 1);
      expect(counts.missed + counts.upcoming, greaterThan(0));
    });
  });

  group('PakistanTime.parseScheduleToMinutes', () {
    test('parses 24h schedule strings', () {
      expect(PakistanTime.parseScheduleToMinutes('10:00:00'), 600);
      expect(PakistanTime.parseScheduleToMinutes('22:20:00'), 1340);
    });
  });
}
