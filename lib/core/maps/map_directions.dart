import 'package:url_launcher/url_launcher.dart';

/// Opens OpenStreetMap directions from home to a care place (external app/browser).
Future<bool> openOsmDirections({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
  String? destinationLabel,
}) async {
  final label = destinationLabel?.trim();
  final dest =
      label != null && label.isNotEmpty
          ? '$toLat,$toLng (${Uri.encodeComponent(label)})'
          : '$toLat,$toLng';
  final uri = Uri.parse(
    'https://www.openstreetmap.org/directions?from=$fromLat,$fromLng&to=$dest',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> openOsmPlaceView({
  required double lat,
  required double lng,
}) async {
  final uri = Uri.parse(
    'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=17/$lat/$lng',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
