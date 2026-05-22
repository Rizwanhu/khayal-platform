import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'overpass_nearby_places_service.dart';

/// Fallback / supplement: Nominatim search (works well when Overpass is busy).
class NominatimNearbyPlacesService {
  NominatimNearbyPlacesService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _userAgent = 'KhayalPlatform/1.0 (patient care map)';

  Future<List<NearbyCarePlace>> fetchHospitalsAndClinics({
    required double latitude,
    required double longitude,
    int radiusMeters = OverpassNearbyPlacesService.defaultRadiusMeters,
  }) async {
    final origin = LatLng(latitude, longitude);
    const distance = Distance();
    final byKey = <String, NearbyCarePlace>{};

    final searches = <(String query, NearbyCareKind kind)>[
      ('hospital', NearbyCareKind.hospital),
      ('clinic', NearbyCareKind.clinic),
      ('medical centre', NearbyCareKind.clinic),
    ];

    for (var i = 0; i < searches.length; i++) {
      final (q, kind) = searches[i];
      if (i > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }

      try {
        final uri = Uri.https(
          'nominatim.openstreetmap.org',
          '/search',
          {
            'format': 'json',
            'q': q,
            'lat': latitude.toString(),
            'lon': longitude.toString(),
            'limit': '50',
            'dedupe': '1',
            'addressdetails': '0',
          },
        );

        final response = await _client
            .get(uri, headers: {'User-Agent': _userAgent})
            .timeout(const Duration(seconds: 25));

        if (response.statusCode != 200) continue;

        final list = jsonDecode(response.body) as List<dynamic>;
        for (final raw in list) {
          if (raw is! Map<String, dynamic>) continue;
          final lat = double.tryParse(raw['lat']?.toString() ?? '');
          final lon = double.tryParse(raw['lon']?.toString() ?? '');
          if (lat == null || lon == null) continue;

          final point = LatLng(lat, lon);
          final meters = distance.as(LengthUnit.Meter, origin, point);
          if (meters > radiusMeters) continue;

          if (!_looksLikeHealthcare(raw, kind)) continue;

          final osmType = raw['osm_type']?.toString() ?? 'node';
          final osmId = raw['osm_id']?.toString() ?? '${lat}_$lon';
          final key = 'nom_${osmType}_$osmId';

          final name = _nameFromResult(raw, kind);
          final existing = byKey[key];
          if (existing != null && existing.distanceMeters <= meters) continue;

          byKey[key] = NearbyCarePlace(
            osmId: key,
            name: name,
            latitude: lat,
            longitude: lon,
            kind: kind,
            distanceMeters: meters,
            address: _shortAddress(raw['display_name']?.toString()),
          );
        }
      } catch (e) {
        debugPrint('NominatimNearbyPlacesService: $q failed: $e');
      }
    }

    final results = byKey.values.toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }

  bool _looksLikeHealthcare(Map<String, dynamic> raw, NearbyCareKind kind) {
    final type = '${raw['type'] ?? ''}'.toLowerCase();
    final category = '${raw['category'] ?? ''}'.toLowerCase();
    final clazz = '${raw['class'] ?? ''}'.toLowerCase();
    final display = '${raw['display_name'] ?? ''}'.toLowerCase();

    if (clazz == 'amenity' || type == 'hospital' || type == 'clinic') {
      return true;
    }
    if (kind == NearbyCareKind.hospital) {
      return display.contains('hospital') || category.contains('hospital');
    }
    return display.contains('clinic') ||
        display.contains('doctor') ||
        category.contains('clinic');
  }

  String _nameFromResult(Map<String, dynamic> raw, NearbyCareKind kind) {
    final name = raw['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    final display = raw['display_name']?.toString();
    if (display != null && display.isNotEmpty) {
      return display.split(',').first.trim();
    }
    return kind == NearbyCareKind.hospital ? 'Hospital' : 'Clinic';
  }

  String? _shortAddress(String? display) {
    if (display == null || display.isEmpty) return null;
    final parts = display.split(',').map((e) => e.trim()).toList();
    if (parts.length <= 1) return display;
    return parts.skip(1).take(2).join(', ');
  }

  void dispose() => _client.close();
}
