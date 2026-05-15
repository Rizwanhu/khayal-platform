import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicationRecord {
  const MedicationRecord({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.doseLabel,
    required this.timeLabel,
    this.imageStoragePath,
  });

  final String id;
  final String nameEn;
  final String nameUr;
  final String doseLabel;
  final String timeLabel;

  /// Path inside bucket `medication-photos`; use [BackendRepository.signedMedicationImageUrl].
  final String? imageStoragePath;
}

class MedicationEditRecord {
  const MedicationEditRecord({
    required this.id,
    required this.patientId,
    required this.nameEn,
    required this.nameUr,
    required this.doseAmount,
    required this.doseUnit,
    required this.medicationType,
    required this.times,
    this.imageStoragePath,
  });

  final String id;
  final String patientId;
  final String nameEn;
  final String nameUr;
  final String doseAmount;
  final String doseUnit;
  final String medicationType;
  final List<String> times;
  final String? imageStoragePath;
}

class PatientHistoryRecord {
  const PatientHistoryRecord({
    required this.dayLabel,
    required this.status,
    required this.scheduledFor,
  });

  final String dayLabel;
  final String status;
  final DateTime scheduledFor;
}

class DoctorPatientSummary {
  const DoctorPatientSummary({
    required this.patientId,
    required this.patientName,
    required this.subtitle,
  });

  final String patientId;
  final String patientName;
  final String subtitle;
}

class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String role;
}

class BackendRepository {
  BackendRepository(this._client);

  final SupabaseClient _client;

  static const medicationPhotosBucket = 'medication-photos';

  Future<String> createPatientLinkCode({required String patientPhone}) async {
    final code =
        (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 10));

    await _client.from('otp_artifacts').insert({
      'patient_phone': patientPhone,
      'otp_hash': code,
      'expires_at': expiresAt.toIso8601String(),
    });

    return code;
  }

  Future<bool> linkCaregiverToPatientViaCode({
    required String caregiverId,
    required String patientPhone,
    required String code,
  }) async {
    final artifact =
        await _client
            .from('otp_artifacts')
            .select('id,expires_at,used_at')
            .eq('patient_phone', patientPhone)
            .eq('otp_hash', code)
            .isFilter('used_at', null)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    if (artifact == null) return false;
    final expiresAt = DateTime.tryParse(
      (artifact['expires_at'] ?? '').toString(),
    );
    if (expiresAt == null || expiresAt.isBefore(DateTime.now().toUtc())) {
      return false;
    }

    final patient =
        await _client
            .from('profiles')
            .select('id,role,phone')
            .eq('phone', patientPhone)
            .eq('role', 'patient')
            .maybeSingle();
    if (patient == null) return false;

    final patientId = patient['id'].toString();
    await _client.from('caregiver_patient_links').upsert({
      'caregiver_id': caregiverId,
      'patient_id': patientId,
      'status': 'active',
    });

    await _client
        .from('otp_artifacts')
        .update({
          'used_at': DateTime.now().toUtc().toIso8601String(),
          'caregiver_id': caregiverId,
        })
        .eq('id', artifact['id'].toString());

    return true;
  }

  Future<void> upsertProfile({
    required String userId,
    required String role,
    required String fullName,
    String? phone,
    String? relationship,
    String languageCode = 'en',
  }) async {
    final payload = {
      'id': userId,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'language_code': languageCode,
    };
    if (relationship != null && relationship.isNotEmpty) {
      payload['relationship'] = relationship;
    }
    await _client.from('profiles').upsert(payload);
  }

  Future<void> updateProfileName({
    required String userId,
    required String fullName,
  }) async {
    await _client
        .from('profiles')
        .update({'full_name': fullName})
        .eq('id', userId);
  }

  Future<PatientProfile?> getPatientProfile(String patientId) async {
    final data =
        await _client
            .from('profiles')
            .select('id,role,full_name,phone')
            .eq('id', patientId)
            .maybeSingle();

    if (data == null) return null;

    return PatientProfile(
      id: data['id'].toString(),
      fullName: (data['full_name'] ?? 'Unknown').toString(),
      phone: data['phone']?.toString(),
      role: (data['role'] ?? 'patient').toString(),
    );
  }

  Future<String?> getFirstPatientForCaregiver(String caregiverId) async {
    final links = List<Map<String, dynamic>>.from(
      await _client
          .from('caregiver_patient_links')
          .select('patient_id,status')
          .eq('caregiver_id', caregiverId)
          .eq('status', 'active')
          .limit(1),
    );

    if (links.isEmpty) return null;
    return links.first['patient_id'] as String?;
  }

  Future<List<String>> getPatientIdsForDoctor(String doctorId) async {
    final links = List<Map<String, dynamic>>.from(
      await _client
          .from('doctor_patient_links')
          .select('patient_id,status')
          .eq('doctor_id', doctorId)
          .eq('status', 'active'),
    );
    return links
        .map((e) => e['patient_id'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<List<MedicationRecord>> getMedicationsForPatient(
    String patientId,
  ) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('medications')
          .select(
            'id,english_name,urdu_name,dose_amount,dose_unit,image_storage_path,'
            'medication_schedules(local_time)',
          )
          .eq('patient_id', patientId)
          .eq('is_active', true),
    );

    return rows.map((row) {
      final schedules = (row['medication_schedules'] as List<dynamic>? ?? []);
      final firstTime =
          schedules.isNotEmpty
              ? ((schedules.first as Map<String, dynamic>)['local_time']
                      ?.toString() ??
                  '--:--')
              : '--:--';
      final path = row['image_storage_path'];
      return MedicationRecord(
        id: row['id'].toString(),
        nameEn: (row['english_name'] ?? '').toString(),
        nameUr: (row['urdu_name'] ?? '').toString(),
        doseLabel: '${row['dose_amount']} ${row['dose_unit']}',
        timeLabel: _formatTime(firstTime),
        imageStoragePath: path?.toString(),
      );
    }).toList();
  }

  /// Returns new medication row id, or null if insert failed.
  Future<String?> createMedication({
    required String patientId,
    required String createdBy,
    required String urduName,
    required String englishName,
    required String doseAmountRaw,
    required String doseUnit,
    required String medicationType,
    required String frequency,
    required String timesCsv,
  }) async {
    final dose = double.tryParse(doseAmountRaw.trim()) ?? 1;
    final inserted =
        await _client
            .from('medications')
            .insert({
              'patient_id': patientId,
              'created_by': createdBy,
              'urdu_name': urduName,
              'english_name': englishName,
              'dose_amount': dose,
              'dose_unit': doseUnit,
              'medication_type': medicationType,
              'frequency': frequency,
            })
            .select('id')
            .single();

    final medId = inserted['id']?.toString();
    if (medId == null) return null;

    final times =
        timesCsv
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    for (final t in times) {
      final normalized = _normalizeTime(t);
      await _client.from('medication_schedules').insert({
        'medication_id': medId,
        'local_time': normalized,
      });
    }
    return medId;
  }

  Future<void> setMedicationImageStoragePath(
    String medicationId,
    String? imageStoragePath,
  ) async {
    await _client
        .from('medications')
        .update({'image_storage_path': imageStoragePath})
        .eq('id', medicationId);
  }

  String _imageExtensionForContentType(String contentType) {
    final lower = contentType.toLowerCase();
    if (lower.contains('png')) return 'png';
    if (lower.contains('webp')) return 'webp';
    return 'jpg';
  }

  /// Uploads bytes to `medication-photos/{patientId}/{medicationId}.{ext}` and saves path on the row.
  Future<void> uploadMedicationPhotoAndSave({
    required String patientId,
    required String medicationId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ext = _imageExtensionForContentType(contentType);
    final path = '$patientId/$medicationId.$ext';
    await _client.storage
        .from(medicationPhotosBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    await setMedicationImageStoragePath(medicationId, path);
  }

  Future<String?> signedMedicationImageUrl(
    String? imageStoragePath, {
    int expiresInSeconds = 3600,
  }) async {
    if (imageStoragePath == null || imageStoragePath.isEmpty) return null;
    return _client.storage
        .from(medicationPhotosBucket)
        .createSignedUrl(imageStoragePath, expiresInSeconds);
  }

  Future<MedicationEditRecord?> getMedicationById(String medicationId) async {
    final data =
        await _client
            .from('medications')
            .select(
              'id,patient_id,english_name,urdu_name,dose_amount,dose_unit,medication_type,'
              'image_storage_path,'
              'medication_schedules(local_time)',
            )
            .eq('id', medicationId)
            .maybeSingle();

    if (data == null) return null;
    final schedules =
        (data['medication_schedules'] as List<dynamic>? ?? [])
            .map((e) => (e as Map<String, dynamic>)['local_time'].toString())
            .toList();
    final img = data['image_storage_path'];

    return MedicationEditRecord(
      id: data['id'].toString(),
      patientId: (data['patient_id'] ?? '').toString(),
      nameEn: (data['english_name'] ?? '').toString(),
      nameUr: (data['urdu_name'] ?? '').toString(),
      doseAmount: (data['dose_amount'] ?? '').toString(),
      doseUnit: (data['dose_unit'] ?? '').toString(),
      medicationType: (data['medication_type'] ?? 'tablet').toString(),
      times: schedules,
      imageStoragePath: img?.toString(),
    );
  }

  Future<void> updateMedication({
    required String medicationId,
    required String urduName,
    required String englishName,
    required String doseAmountRaw,
    required String doseUnit,
    required String medicationType,
    required List<String> times,
  }) async {
    final dose = double.tryParse(doseAmountRaw.trim()) ?? 1;
    await _client
        .from('medications')
        .update({
          'urdu_name': urduName,
          'english_name': englishName,
          'dose_amount': dose,
          'dose_unit': doseUnit,
          'medication_type': medicationType,
        })
        .eq('id', medicationId);

    await _client
        .from('medication_schedules')
        .delete()
        .eq('medication_id', medicationId);
    for (final t in times) {
      await _client.from('medication_schedules').insert({
        'medication_id': medicationId,
        'local_time': _normalizeTime(t),
      });
    }
  }

  Future<List<PatientHistoryRecord>> getPatientHistory(String patientId) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('dose_logs')
          .select('scheduled_for,status')
          .eq('patient_id', patientId)
          .order('scheduled_for', ascending: false)
          .limit(30),
    );

    return rows.map((row) {
      final scheduled =
          DateTime.tryParse((row['scheduled_for'] ?? '').toString()) ??
          DateTime.now();
      return PatientHistoryRecord(
        dayLabel: _weekdayLabel(scheduled),
        status: _statusLabel((row['status'] ?? 'upcoming').toString()),
        scheduledFor: scheduled,
      );
    }).toList();
  }

  Future<void> confirmDose({
    required String patientId,
    required String medicationId,
    required String status,
  }) async {
    await _client.from('dose_logs').upsert({
      'patient_id': patientId,
      'medication_id': medicationId,
      'scheduled_for': DateTime.now().toIso8601String(),
      'status': status,
      'confirmed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<DoctorPatientSummary>> getDoctorPatients(String doctorId) async {
    final patientIds = await getPatientIdsForDoctor(doctorId);
    if (patientIds.isEmpty) return const [];

    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('profiles')
          .select('id,full_name')
          .inFilter('id', patientIds),
    );

    return rows
        .map(
          (row) => DoctorPatientSummary(
            patientId: row['id'].toString(),
            patientName: (row['full_name'] ?? 'Unknown').toString(),
            subtitle: 'Assigned patient',
          ),
        )
        .toList();
  }

  String _weekdayLabel(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dt.weekday - 1];
  }

  String _statusLabel(String raw) {
    switch (raw) {
      case 'taken':
        return 'Taken';
      case 'missed':
        return 'Missed';
      default:
        return 'Upcoming';
    }
  }

  String _formatTime(String time) {
    // expects "HH:mm:ss" or "HH:mm"
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hh = int.tryParse(parts[0]) ?? 0;
    final mm = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: hh, minute: mm);
    final suffix = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m $suffix';
  }

  String _normalizeTime(String input) {
    final s = input.trim().toUpperCase();
    if (s.contains('AM') || s.contains('PM')) {
      final isPm = s.contains('PM');
      final numeric = s.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = numeric.split(':');
      var hour = int.tryParse(parts.first) ?? 0;
      final min = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}:00';
    }
    final parts = s.split(':');
    if (parts.length == 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
    }
    return '08:00:00';
  }
}
