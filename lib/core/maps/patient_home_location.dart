/// Saved patient home point for nearby care map (WGS84).
class PatientHomeLocation {
  const PatientHomeLocation({
    required this.latitude,
    required this.longitude,
    this.areaLabel,
    this.displayAddress,
  });

  final double latitude;
  final double longitude;

  /// User-chosen label (e.g. Gulberg, Lahore).
  final String? areaLabel;

  /// Reverse-geocoded street/area from OpenStreetMap.
  final String? displayAddress;

  String get summaryLine {
    if (areaLabel != null && areaLabel!.trim().isNotEmpty) {
      return areaLabel!.trim();
    }
    if (displayAddress != null && displayAddress!.trim().isNotEmpty) {
      return displayAddress!.trim();
    }
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}
