/// OpenStreetMap raster tiles (attribution required in UI).
abstract final class OsmMapConstants {
  static const tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Required by OSM tile usage policy.
  static const attribution =
      '© OpenStreetMap contributors';

  /// Default centre when no GPS (Lahore).
  static const defaultLat = 31.5204;
  static const defaultLng = 74.3587;
}
