import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Clinic vs hospital for map styling and filters.
enum NearbyCareKind { hospital, clinic }

class NearbyCarePlace {
  const NearbyCarePlace({
    required this.osmId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.kind,
    required this.distanceMeters,
    this.address,
  });

  final String osmId;
  final String name;
  final double latitude;
  final double longitude;
  final NearbyCareKind kind;
  final double distanceMeters;
  final String? address;

  LatLng get latLng => LatLng(latitude, longitude);
}

/// Fetches hospitals and clinics near a point from OpenStreetMap (Overpass API).
class OverpassNearbyPlacesService {
  OverpassNearbyPlacesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  static const defaultRadiusMeters = 5000;

  Future<List<NearbyCarePlace>> fetchHospitalsAndClinics({
    required double latitude,
    required double longitude,
    int radiusMeters = defaultRadiusMeters,
  }) async {
    final query = '''
[out:json][timeout:45];
(
  nwr["amenity"="hospital"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="clinic"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="doctors"](around:$radiusMeters,$latitude,$longitude);
  nwr["healthcare"="hospital"](around:$radiusMeters,$latitude,$longitude);
  nwr["healthcare"="clinic"](around:$radiusMeters,$latitude,$longitude);
  nwr["healthcare"="doctor"](around:$radiusMeters,$latitude,$longitude);
  nwr["healthcare"="centre"](around:$radiusMeters,$latitude,$longitude);
  nwr["healthcare"="center"](around:$radiusMeters,$latitude,$longitude);
  nwr["building"="hospital"](around:$radiusMeters,$latitude,$longitude);
);
out center tags;
''';

    Object? lastError;
    for (final endpoint in _endpoints) {
      try {
        final list = await _request(endpoint, query, latitude, longitude);
        if (list.isNotEmpty) return list;
        // Empty on first server — try mirror before giving up.
        if (endpoint != _endpoints.last) continue;
        return list;
      } catch (e) {
        lastError = e;
        debugPrint('OverpassNearbyPlacesService: $endpoint failed: $e');
      }
    }
    throw Exception(lastError ?? 'Could not load map places');
  }

  Future<List<NearbyCarePlace>> _request(
    String url,
    String query,
    double latitude,
    double longitude,
  ) async {
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
      'User-Agent': 'KhayalPlatform/1.0 (patient care map)',
    };

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: 'data=${Uri.encodeComponent(query)}',
          )
          .timeout(const Duration(seconds: 35));
    } catch (_) {
      response = await _client
          .get(
            Uri.parse(
              '$url?data=${Uri.encodeComponent(query)}',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 35));
    }

    if (response.statusCode != 200) {
      final snippet = response.body.length > 120
          ? response.body.substring(0, 120)
          : response.body;
      throw Exception(
        'Map data unavailable (${response.statusCode}): $snippet',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    final remark = decoded['remark']?.toString();
    if (remark != null && remark.toLowerCase().contains('error')) {
      throw Exception(remark);
    }

    final elements = decoded['elements'] as List<dynamic>? ?? [];
    final origin = LatLng(latitude, longitude);
    const distance = Distance();
    final byId = <String, NearbyCarePlace>{};

    for (final raw in elements) {
      if (raw is! Map<String, dynamic>) continue;
      final tags = raw['tags'] as Map<String, dynamic>? ?? {};
      final kind = _kindFromTags(tags);
      if (kind == null) continue;

      final coords = _coordsFromElement(raw);
      if (coords == null) continue;

      final id = '${raw['type']}_${raw['id']}';
      final name = _nameFromTags(tags, kind);
      final meters = distance.as(LengthUnit.Meter, origin, coords);
      final address = _addressFromTags(tags);

      final existing = byId[id];
      if (existing != null && existing.distanceMeters <= meters) continue;

      byId[id] = NearbyCarePlace(
        osmId: id,
        name: name,
        latitude: coords.latitude,
        longitude: coords.longitude,
        kind: kind,
        distanceMeters: meters,
        address: address,
      );
    }

    final list = byId.values.toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return list;
  }

  NearbyCareKind? _kindFromTags(Map<String, dynamic> tags) {
    final amenity = tags['amenity']?.toString().toLowerCase();
    final healthcare = tags['healthcare']?.toString().toLowerCase();
    final building = tags['building']?.toString().toLowerCase();

    if (amenity == 'hospital' ||
        healthcare == 'hospital' ||
        building == 'hospital') {
      return NearbyCareKind.hospital;
    }
    if (amenity == 'clinic' ||
        amenity == 'doctors' ||
        healthcare == 'clinic' ||
        healthcare == 'doctor' ||
        healthcare == 'centre' ||
        healthcare == 'center') {
      return NearbyCareKind.clinic;
    }
    return null;
  }

  String _nameFromTags(Map<String, dynamic> tags, NearbyCareKind kind) {
    for (final key in [
      'name',
      'name:en',
      'name:ur',
      'brand',
      'operator',
      'alt_name',
      'official_name',
    ]) {
      final v = tags[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return kind == NearbyCareKind.hospital
        ? 'Hospital (OpenStreetMap)'
        : 'Clinic (OpenStreetMap)';
  }

  String? _addressFromTags(Map<String, dynamic> tags) {
    final parts = <String>[];
    for (final key in [
      'addr:full',
      'addr:street',
      'addr:housenumber',
      'addr:suburb',
      'addr:city',
    ]) {
      final v = tags[key]?.toString().trim();
      if (v != null && v.isNotEmpty) parts.add(v);
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  LatLng? _coordsFromElement(Map<String, dynamic> el) {
    final lat = el['lat'];
    final lon = el['lon'];
    if (lat != null && lon != null) {
      return LatLng(
        (lat as num).toDouble(),
        (lon as num).toDouble(),
      );
    }
    final center = el['center'] as Map<String, dynamic>?;
    if (center != null) {
      final clat = center['lat'];
      final clon = center['lon'];
      if (clat != null && clon != null) {
        return LatLng(
          (clat as num).toDouble(),
          (clon as num).toDouble(),
        );
      }
    }
    return null;
  }

  void dispose() => _client.close();
}

/// Format distance for list UI.
String formatDistanceMeters(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
}
