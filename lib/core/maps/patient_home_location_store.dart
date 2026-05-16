import 'package:shared_preferences/shared_preferences.dart';

import '../backend/backend.dart';
import 'patient_home_location.dart';

/// Local + optional Supabase sync for patient home coordinates.
abstract final class PatientHomeLocationStore {
  static String _latKey(String userId) => 'patient_home_lat_$userId';
  static String _lngKey(String userId) => 'patient_home_lng_$userId';
  static String _labelKey(String userId) => 'patient_home_label_$userId';
  static String _addressKey(String userId) => 'patient_home_address_$userId';

  static Future<PatientHomeLocation?> load(String userId) async {
    final local = await _readLocal(userId);
    final remote = await Backend.repo.getPatientHomeLocation(userId);
    if (remote != null) {
      final loc = PatientHomeLocation(
        latitude: remote.lat,
        longitude: remote.lng,
        areaLabel: remote.areaLabel ?? local?.areaLabel,
        displayAddress: local?.displayAddress,
      );
      if (loc.isValid) {
        await _writeLocal(userId, loc);
        return loc;
      }
    }
    return local;
  }

  static Future<void> save({
    required String userId,
    required PatientHomeLocation location,
  }) async {
    if (!location.isValid) return;
    await _writeLocal(userId, location);
    await Backend.repo.updatePatientHomeLocation(
      userId: userId,
      latitude: location.latitude,
      longitude: location.longitude,
      areaLabel: location.areaLabel,
    );
  }

  static Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_latKey(userId));
    await prefs.remove(_lngKey(userId));
    await prefs.remove(_labelKey(userId));
    await prefs.remove(_addressKey(userId));
  }

  static Future<PatientHomeLocation?> _readLocal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey(userId));
    final lng = prefs.getDouble(_lngKey(userId));
    if (lat == null || lng == null) return null;
    final loc = PatientHomeLocation(
      latitude: lat,
      longitude: lng,
      areaLabel: prefs.getString(_labelKey(userId)),
      displayAddress: prefs.getString(_addressKey(userId)),
    );
    return loc.isValid ? loc : null;
  }

  static Future<void> _writeLocal(
    String userId,
    PatientHomeLocation location,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey(userId), location.latitude);
    await prefs.setDouble(_lngKey(userId), location.longitude);
    final label = location.areaLabel?.trim();
    if (label == null || label.isEmpty) {
      await prefs.remove(_labelKey(userId));
    } else {
      await prefs.setString(_labelKey(userId), label);
    }
    final address = location.displayAddress?.trim();
    if (address == null || address.isEmpty) {
      await prefs.remove(_addressKey(userId));
    } else {
      await prefs.setString(_addressKey(userId), address);
    }
  }
}
