import 'package:flutter/foundation.dart';

import 'nominatim_nearby_places_service.dart';
import 'overpass_nearby_places_service.dart';

/// Loads clinics/hospitals from OpenStreetMap (Overpass, then Nominatim fallback).
class NearbyPlacesService {
  NearbyPlacesService({
    OverpassNearbyPlacesService? overpass,
    NominatimNearbyPlacesService? nominatim,
  }) : _overpass = overpass ?? OverpassNearbyPlacesService(),
       _nominatim = nominatim ?? NominatimNearbyPlacesService();

  final OverpassNearbyPlacesService _overpass;
  final NominatimNearbyPlacesService _nominatim;

  Future<List<NearbyCarePlace>> fetchHospitalsAndClinics({
    required double latitude,
    required double longitude,
    int radiusMeters = OverpassNearbyPlacesService.defaultRadiusMeters,
  }) async {
    try {
      final overpass = await _overpass.fetchHospitalsAndClinics(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
      if (overpass.isNotEmpty) return overpass;
    } catch (e) {
      debugPrint('NearbyPlacesService: Overpass failed: $e');
    }

    final nominatim = await _nominatim.fetchHospitalsAndClinics(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
    return nominatim;
  }

  void dispose() {
    _overpass.dispose();
    _nominatim.dispose();
  }
}
