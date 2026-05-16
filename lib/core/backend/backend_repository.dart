import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_env.dart';
import '../time/medication_dose_status.dart';
import '../time/pakistan_time.dart';

class MedicationRecord {
  const MedicationRecord({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.doseLabel,
    required this.timeLabel,
    this.imageStoragePath,
    /// First schedule by time of day — kept for compatibility.
    this.firstScheduleRaw,
    this.scheduleRaws = const [],
  });

  final String id;
  final String nameEn;
  final String nameUr;
  final String doseLabel;
  final String timeLabel;

  /// Path inside bucket `medication-photos`; use [BackendRepository.signedMedicationImageUrl].
  final String? imageStoragePath;

  final String? firstScheduleRaw;

  /// All `local_time` values for this med, sorted ascending (PKT wall clock).
  final List<String> scheduleRaws;
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
    this.languageCode,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String role;
  final String? languageCode;
}

class TodayDoseSummary {
  const TodayDoseSummary({
    required this.taken,
    required this.total,
    required this.takenMedicationIds,
  });

  final int taken;
  final int total;
  final Set<String> takenMedicationIds;
}

class WeeklyAdherenceDay {
  const WeeklyAdherenceDay({required this.label, required this.rate});

  final String label;
  final double rate;
}

class PatientAdherenceSummary {
  const PatientAdherenceSummary({
    required this.todayTaken,
    required this.todayMissed,
    required this.todayUpcoming,
    required this.weeklyDays,
    required this.overallPercent,
  });

  final int todayTaken;
  final int todayMissed;
  final int todayUpcoming;
  final List<WeeklyAdherenceDay> weeklyDays;
  final int overallPercent;
}

class BackendRepository {
  BackendRepository(this._client);

  final SupabaseClient _client;

  static const medicationPhotosBucket = 'medication-photos';

  /// E.164-style phone, e.g. `+923001234567`, or null if invalid.
  static String? normalizePhone(String raw) {
    final trimmed = raw.trim().replaceAll(' ', '');
    if (trimmed.isEmpty) return null;
    final withPlus = trimmed.startsWith('+') ? trimmed : '+$trimmed';
    final digits = withPlus.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 9 || !digits.startsWith('+')) return null;
    return digits;
  }

  /// Synthetic auth email for a phone account (Supabase requires email+password).
  static String authEmailForPhone(String normalizedPhone) {
    final digits = normalizedPhone.replaceAll(RegExp(r'[^0-9]'), '');
    return 'phone+$digits@khayal.app';
  }

  /// Sign in or register using phone only (no SMS OTP).
  Future<User> signInOrSignUpWithPhone({required String phone}) async {
    final normalized = normalizePhone(phone);
    if (normalized == null) {
      throw ArgumentError('Invalid phone number');
    }

    final email = authEmailForPhone(normalized);
    final password = AppEnv.phoneAuthPassword;
    if (password.isEmpty) {
      throw AuthException(
        'PHONE_AUTH_PASSWORD is not set in .env. Ask your team for app config.',
      );
    }

    try {
      final signIn = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = signIn.user ?? _client.auth.currentUser;
      if (user != null) return user;
    } on AuthException catch (e) {
      if (!_authErrorAllowsSignUp(e)) rethrow;
    }

    final signUp = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'phone': normalized},
    );
    final newUser = signUp.user ?? _client.auth.currentUser;
    if (newUser != null) return newUser;

    final retry = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final retryUser = retry.user ?? _client.auth.currentUser;
    if (retryUser != null) return retryUser;

    throw AuthException('Could not sign in with this phone number.');
  }

  bool _authErrorAllowsSignUp(AuthException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('invalid') ||
        msg.contains('credentials') ||
        msg.contains('not found') ||
        e.statusCode == '400';
  }

  /// Phone for caregiver link codes: Auth phone, else [profiles].phone (dev email login).
  Future<String?> resolvePatientLinkPhone(String userId) async {
    final authPhone = _client.auth.currentUser?.phone?.trim();
    if (authPhone != null && authPhone.isNotEmpty) return authPhone;
    final profile = await getPatientProfile(userId);
    final profilePhone = profile?.phone?.trim();
    if (profilePhone != null && profilePhone.isNotEmpty) return profilePhone;
    return null;
  }

  Future<String> createPatientLinkCode({required String patientPhone}) async {
    final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
        .toString();
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
    final normalizedPhone = patientPhone.startsWith('+')
        ? patientPhone
        : '+$patientPhone';

    final patient = await _client
        .from('profiles')
        .select('id,role,phone')
        .eq('phone', normalizedPhone)
        .eq('role', 'patient')
        .maybeSingle();
    if (patient == null) return false;

    final patientId = patient['id'].toString();

    final existingLink = await _client
        .from('caregiver_patient_links')
        .select('id')
        .eq('caregiver_id', caregiverId)
        .eq('patient_id', patientId)
        .eq('status', 'active')
        .maybeSingle();
    if (existingLink != null) return true;

    final artifact = await _client
        .from('otp_artifacts')
        .select('id,expires_at,used_at')
        .eq('patient_phone', normalizedPhone)
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

    await _client.from('caregiver_patient_links').upsert({
      'caregiver_id': caregiverId,
      'patient_id': patientId,
      'status': 'active',
    }, onConflict: 'caregiver_id,patient_id');

    await _client
        .from('otp_artifacts')
        .update({
          'used_at': DateTime.now().toUtc().toIso8601String(),
          'caregiver_id': caregiverId,
        })
        .eq('id', artifact['id'].toString());

    return true;
  }

  Future<bool> linkDoctorToPatientViaCode({
    required String doctorId,
    required String patientPhone,
    required String code,
  }) async {
    final normalizedPhone = patientPhone.startsWith('+')
        ? patientPhone
        : '+$patientPhone';

    final patient = await _client
        .from('profiles')
        .select('id,role,phone')
        .eq('phone', normalizedPhone)
        .eq('role', 'patient')
        .maybeSingle();
    if (patient == null) return false;

    final patientId = patient['id'].toString();

    final existingLink = await _client
        .from('doctor_patient_links')
        .select('id')
        .eq('doctor_id', doctorId)
        .eq('patient_id', patientId)
        .eq('status', 'active')
        .maybeSingle();
    if (existingLink != null) return true;

    final artifact = await _client
        .from('otp_artifacts')
        .select('id,expires_at,used_at')
        .eq('patient_phone', normalizedPhone)
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

    await _client.from('doctor_patient_links').upsert({
      'doctor_id': doctorId,
      'patient_id': patientId,
      'status': 'active',
    }, onConflict: 'doctor_id,patient_id');

    await _client
        .from('otp_artifacts')
        .update({'used_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', artifact['id'].toString());

    return true;
  }

  Future<void> upsertProfile({
    required String userId,
    required String role,
    required String fullName,
    String? phone,
    String languageCode = 'en',
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'language_code': languageCode,
    });
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

  Future<void> updateProfileLanguage({
    required String userId,
    required String languageCode,
  }) async {
    await _client
        .from('profiles')
        .update({'language_code': languageCode})
        .eq('id', userId);
  }

  /// Patient home point for nearby care map (requires `profiles.home_lat` columns).
  Future<({double lat, double lng, String? areaLabel})?> getPatientHomeLocation(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('profiles')
          .select('home_lat,home_lng,home_area_label')
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      final lat = data['home_lat'];
      final lng = data['home_lng'];
      if (lat == null || lng == null) return null;
      return (
        lat: (lat as num).toDouble(),
        lng: (lng as num).toDouble(),
        areaLabel: data['home_area_label']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> updatePatientHomeLocation({
    required String userId,
    required double latitude,
    required double longitude,
    String? areaLabel,
  }) async {
    try {
      await _client.from('profiles').update({
        'home_lat': latitude,
        'home_lng': longitude,
        'home_area_label': areaLabel?.trim().isEmpty == true
            ? null
            : areaLabel?.trim(),
      }).eq('id', userId);
    } catch (_) {
      // Columns may not exist until SQL migration is applied; local store still works.
    }
  }

  Future<PatientProfile?> getPatientProfile(String patientId) async {
    final data = await _client
        .from('profiles')
        .select('id,role,full_name,phone,language_code')
        .eq('id', patientId)
        .maybeSingle();

    if (data == null) return null;

    return PatientProfile(
      id: data['id'].toString(),
      fullName: (data['full_name'] ?? 'Unknown').toString(),
      phone: data['phone']?.toString(),
      role: (data['role'] ?? 'patient').toString(),
      languageCode: data['language_code']?.toString(),
    );
  }

  Future<String?> getFirstPatientForDoctor(String doctorId) async {
    final links = List<Map<String, dynamic>>.from(
      await _client
          .from('doctor_patient_links')
          .select('patient_id,status')
          .eq('doctor_id', doctorId)
          .eq('status', 'active')
          .limit(1),
    );

    if (links.isEmpty) return null;
    return links.first['patient_id'] as String?;
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

  static const Set<String> _placeholderProfileNames = {
    'New User',
    'New Caregiver',
  };

  /// False until the user saved a real display name (not a sign-in placeholder).
  Future<bool> profileNameIsComplete(String userId) async {
    final data = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return false;
    final name = (data['full_name'] ?? '').toString().trim();
    return name.isNotEmpty && !_placeholderProfileNames.contains(name);
  }

  Future<bool> caregiverProfileIsComplete(String caregiverId) =>
      profileNameIsComplete(caregiverId);

  Future<bool> patientProfileIsComplete(String patientId) =>
      profileNameIsComplete(patientId);

  Future<bool> doctorProfileIsComplete(String doctorId) =>
      profileNameIsComplete(doctorId);

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

  Future<int> countAssignedPatientsForDoctor(String doctorId) async {
    final ids = await getPatientIdsForDoctor(doctorId);
    return ids.length;
  }

  /// Missed dose log rows for this doctor's patients, [scheduled_for] in the device's local calendar day.
  Future<int> countMissedDosesTodayForDoctor(String doctorId) async {
    final patientIds = await getPatientIdsForDoctor(doctorId);
    if (patientIds.isEmpty) return 0;

    final n = DateTime.now();
    final dayStart = DateTime(n.year, n.month, n.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('dose_logs')
          .select('id')
          .inFilter('patient_id', patientIds)
          .eq('status', 'missed')
          .gte('scheduled_for', dayStart.toIso8601String())
          .lt('scheduled_for', dayEnd.toIso8601String()),
    );
    return rows.length;
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
      final scheduleRaws = _sortedScheduleRawsFromRows(schedules);
      final timeLabel = scheduleRaws.isEmpty
          ? '--:--'
          : scheduleRaws.map(_formatTime).join(', ');
      final path = row['image_storage_path'];
      return MedicationRecord(
        id: row['id'].toString(),
        nameEn: (row['english_name'] ?? '').toString(),
        nameUr: (row['urdu_name'] ?? '').toString(),
        doseLabel: '${row['dose_amount']} ${row['dose_unit']}',
        timeLabel: timeLabel,
        imageStoragePath: path?.toString(),
        firstScheduleRaw:
            scheduleRaws.isNotEmpty ? scheduleRaws.first : null,
        scheduleRaws: scheduleRaws,
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
    required String timesCsv,
  }) async {
    final dose = double.tryParse(doseAmountRaw.trim()) ?? 1;
    final inserted = await _client
        .from('medications')
        .insert({
          'patient_id': patientId,
          'created_by': createdBy,
          'urdu_name': urduName,
          'english_name': englishName,
          'dose_amount': dose,
          'dose_unit': doseUnit,
          'medication_type': medicationType,
        })
        .select('id')
        .single();

    final medId = inserted['id']?.toString();
    if (medId == null) return null;

    final times = timesCsv
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
    final data = await _client
        .from('medications')
        .select(
          'id,patient_id,english_name,urdu_name,dose_amount,dose_unit,medication_type,'
          'image_storage_path,'
          'medication_schedules(local_time)',
        )
        .eq('id', medicationId)
        .maybeSingle();

    if (data == null) return null;
    final schedules = (data['medication_schedules'] as List<dynamic>? ?? [])
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

  /// Each scheduled dose logged today: `medicationId|HH:mm:ss` (PKT).
  Future<Set<String>> getTodayTakenDoseSlotKeys(String patientId) async {
    final pkt = PakistanTime.now();
    final start = PakistanTime.dayStartUtc(pkt);
    final end = PakistanTime.dayEndUtc(pkt);

    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('dose_logs')
          .select('medication_id,scheduled_for')
          .eq('patient_id', patientId)
          .eq('status', 'taken')
          .gte('scheduled_for', start.toIso8601String())
          .lt('scheduled_for', end.toIso8601String()),
    );

    return rows.map((r) {
      final medId = r['medication_id'].toString();
      final scheduled = DateTime.tryParse(
        (r['scheduled_for'] ?? '').toString(),
      );
      if (scheduled == null) return medId;
      final raw = PakistanTime.scheduleRawFromUtc(scheduled);
      return MedicationDoseStatusLogic.doseSlotKey(medId, raw);
    }).toSet();
  }

  Future<Set<String>> getTodayTakenMedicationIds(String patientId) async {
    final pkt = PakistanTime.now();
    final start = PakistanTime.dayStartUtc(pkt);
    final end = PakistanTime.dayEndUtc(pkt);

    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('dose_logs')
          .select('medication_id')
          .eq('patient_id', patientId)
          .eq('status', 'taken')
          .gte('scheduled_for', start.toIso8601String())
          .lt('scheduled_for', end.toIso8601String()),
    );

    return rows.map((r) => r['medication_id'].toString()).toSet();
  }

  Future<TodayDoseSummary> getTodayDoseSummary(String patientId) async {
    final meds = await getMedicationsForPatient(patientId);
    final takenIds = await getTodayTakenMedicationIds(patientId);
    return TodayDoseSummary(
      taken: takenIds.length,
      total: meds.length,
      takenMedicationIds: takenIds,
    );
  }

  Future<int> _countExpectedDailyDoses(String patientId) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('medications')
          .select('medication_schedules(id)')
          .eq('patient_id', patientId)
          .eq('is_active', true),
    );
    var count = 0;
    for (final row in rows) {
      final schedules = row['medication_schedules'] as List<dynamic>? ?? [];
      count += schedules.isEmpty ? 1 : schedules.length;
    }
    return count;
  }

  Future<int> _countTakenDosesOnPktDay(String patientId, DateTime pktDay) async {
    final start = PakistanTime.dayStartUtc(pktDay);
    final end = PakistanTime.dayEndUtc(pktDay);
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('dose_logs')
          .select('id')
          .eq('patient_id', patientId)
          .eq('status', 'taken')
          .gte('scheduled_for', start.toIso8601String())
          .lt('scheduled_for', end.toIso8601String()),
    );
    return rows.length;
  }

  Future<PatientAdherenceSummary> getPatientAdherenceSummary(
    String patientId,
  ) async {
    final meds = await getMedicationsForPatient(patientId);
    final takenIds = await getTodayTakenMedicationIds(patientId);

    var todayTaken = 0;
    var todayMissed = 0;
    var todayUpcoming = 0;
    for (final med in meds) {
      if (takenIds.contains(med.id)) {
        todayTaken++;
        continue;
      }
      switch (MedicationDoseStatusLogic.fromScheduleRaws(med.scheduleRaws)) {
        case MedicationDoseStatus.missed:
          todayMissed++;
        case MedicationDoseStatus.upcoming:
        case MedicationDoseStatus.dueSoon:
          todayUpcoming++;
      }
    }

    final pktToday = PakistanTime.now();
    const shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeklyDays = <WeeklyAdherenceDay>[];
    var rateSum = 0.0;
    final expectedDaily = await _countExpectedDailyDoses(patientId);

    for (var i = 6; i >= 0; i--) {
      final pktDay = pktToday.subtract(Duration(days: i));
      final expected = expectedDaily;
      final taken = await _countTakenDosesOnPktDay(patientId, pktDay);
      final rate = expected == 0 ? 0.0 : (taken / expected).clamp(0.0, 1.0);
      rateSum += rate;
      weeklyDays.add(
        WeeklyAdherenceDay(
          label: shortDays[pktDay.weekday - 1],
          rate: rate,
        ),
      );
    }

    final overallPercent = weeklyDays.isEmpty
        ? 0
        : ((rateSum / weeklyDays.length) * 100).round();

    return PatientAdherenceSummary(
      todayTaken: todayTaken,
      todayMissed: todayMissed,
      todayUpcoming: todayUpcoming,
      weeklyDays: weeklyDays,
      overallPercent: overallPercent,
    );
  }

  Future<void> confirmDose({
    required String patientId,
    required String medicationId,
    required String status,
    String? scheduleRaw,
  }) async {
    final scheduledFor = PakistanTime.scheduledForTodayUtc(scheduleRaw);
    final nowUtc = DateTime.now().toUtc();

    await _client.from('dose_logs').upsert({
      'patient_id': patientId,
      'medication_id': medicationId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'status': status,
      'confirmed_at': nowUtc.toIso8601String(),
    }, onConflict: 'patient_id,medication_id,scheduled_for');
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

  List<String> _sortedScheduleRawsFromRows(List<dynamic> schedules) {
    final byMinute = <int, String>{};
    for (final entry in schedules) {
      final map = entry as Map<String, dynamic>;
      final raw = map['local_time']?.toString();
      if (raw == null || raw.isEmpty || raw == '--:--') continue;
      final min = PakistanTime.parseScheduleToMinutes(raw);
      if (min == null) continue;
      byMinute[min] = raw;
    }
    final keys = byMinute.keys.toList()..sort();
    return keys.map((k) => byMinute[k]!).toList();
  }

  String _normalizeTime(String input) {
    final s = input.trim().toUpperCase();
    if (s.contains('AM') || s.contains('PM')) {
      final isPm = s.contains('PM');
      var numeric = s.replaceAll(RegExp(r'\s*(AM|PM)\s*'), '').trim();
      if (!numeric.contains(':') && numeric.contains(RegExp(r'\s+'))) {
        final spaceParts =
            numeric.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
        if (spaceParts.length >= 2) {
          numeric = '${spaceParts[0]}:${spaceParts[1]}';
        }
      }
      final parts = numeric.split(':');
      var hour = int.tryParse(parts.first.trim()) ?? 0;
      final min =
          parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
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
