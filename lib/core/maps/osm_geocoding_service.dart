import 'dart:convert';

import 'package:http/http.dart' as http;

/// Reverse geocoding via OpenStreetMap Nominatim (no Google).
class OsmGeocodingService {
  OsmGeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _userAgent = 'KhayalPlatform/1.0 (patient care map)';

  /// Human-readable address for map pin, or null if lookup fails.
  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'format': 'json',
          'addressdetails': '1',
          'accept-language': 'en,ur',
        },
      );

      final response = await _client
          .get(
            uri,
            headers: {'User-Agent': _userAgent},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final display = data['display_name']?.toString().trim();
      if (display != null && display.isNotEmpty) return display;

      final addr = data['address'] as Map<String, dynamic>?;
      if (addr == null) return null;
      return _formatAddressParts(addr);
    } catch (_) {
      return null;
    }
  }

  String? _formatAddressParts(Map<String, dynamic> addr) {
    final parts = <String>[];
    void add(String key) {
      final v = addr[key]?.toString().trim();
      if (v != null && v.isNotEmpty) parts.add(v);
    }

    add('road');
    add('neighbourhood');
    add('suburb');
    add('city');
    add('town');
    add('village');
    add('state');
    if (parts.isEmpty) add('county');
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  void dispose() => _client.close();
}

String formatLatLngLabel(double lat, double lng) {
  return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}
