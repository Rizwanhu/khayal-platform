import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/maps/map_directions.dart';
import '../../../core/maps/osm_geocoding_service.dart';
import '../../../core/maps/nearby_places_service.dart';
import '../../../core/maps/overpass_nearby_places_service.dart';
import '../../../core/maps/osm_map_constants.dart';
import '../../../core/maps/patient_home_location.dart';
import '../../../core/maps/patient_home_location_store.dart';
import '../../../core/navigation/app_routes.dart';
import 'care_map_markers.dart';

enum _PlaceFilter { all, hospitals, clinics }

/// OpenStreetMap view of hospitals and clinics near the patient's saved home.
class NearbyCareMapScreen extends StatefulWidget {
  const NearbyCareMapScreen({super.key});

  @override
  State<NearbyCareMapScreen> createState() => _NearbyCareMapScreenState();
}

class _NearbyCareMapScreenState extends State<NearbyCareMapScreen> {
  static const Color _header = Color(0xFF608266);
  static const Color _canvas = Color(0xFFF9F8F3);

  final _mapController = MapController();
  final _placesService = NearbyPlacesService();

  PatientHomeLocation? _home;
  List<NearbyCarePlace> _places = [];
  NearbyCarePlace? _selected;
  _PlaceFilter _filter = _PlaceFilter.all;
  bool _loadingHome = true;
  bool _loadingPlaces = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _placesService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final userId = AppSession.currentUserId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _loadingHome = false;
        _error = 'Session missing. Please sign in again.';
      });
      return;
    }

    var home = await PatientHomeLocationStore.load(userId);
    if (!mounted) return;

    if (home != null &&
        (home.displayAddress == null || home.displayAddress!.trim().isEmpty)) {
      final geocoder = OsmGeocodingService();
      final addr = await geocoder.reverseGeocode(
        latitude: home.latitude,
        longitude: home.longitude,
      );
      geocoder.dispose();
      if (addr != null && addr.isNotEmpty && mounted) {
        home = PatientHomeLocation(
          latitude: home.latitude,
          longitude: home.longitude,
          areaLabel: home.areaLabel,
          displayAddress: addr,
        );
        await PatientHomeLocationStore.save(userId: userId, location: home);
      }
    }

    if (home == null) {
      setState(() => _loadingHome = false);
      final saved = await Navigator.pushNamed<bool>(
        context,
        AppRoutes.patientHomeArea,
      );
      if (!mounted) return;
      if (saved != true) {
        Navigator.pop(context);
        return;
      }
      await _init();
      return;
    }

    setState(() {
      _home = home;
      _loadingHome = false;
    });
    _mapController.move(LatLng(home.latitude, home.longitude), 13);
    await _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    final home = _home;
    if (home == null) return;

    setState(() {
      _loadingPlaces = true;
      _error = null;
    });

    try {
      final list = await _placesService.fetchHospitalsAndClinics(
        latitude: home.latitude,
        longitude: home.longitude,
      );
      if (!mounted) return;
      setState(() {
        _places = list;
        _loadingPlaces = false;
        if (list.isEmpty) {
          _error = AppLanguageState.pick(
            en:
                'No clinics or hospitals found in OpenStreetMap within 5 km. '
                'Try moving your home pin closer to a city centre, or refresh.',
            ur:
                '۵ کلومیٹر میں OpenStreetMap پر کوئی کلینک/ہسپتال نہیں ملا۔ '
                'گھر کا نشان شہر کے قریب رکھیں یا تازہ کریں۔',
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPlaces = false;
        _error = 'Could not load clinics and hospitals: $e';
      });
    }
  }

  List<NearbyCarePlace> get _filtered {
    return switch (_filter) {
      _PlaceFilter.all => _places,
      _PlaceFilter.hospitals =>
        _places.where((p) => p.kind == NearbyCareKind.hospital).toList(),
      _PlaceFilter.clinics =>
        _places.where((p) => p.kind == NearbyCareKind.clinic).toList(),
    };
  }

  void _selectPlace(NearbyCarePlace place) {
    setState(() => _selected = place);
    _mapController.move(place.latLng, 16);
    _showPlaceSheet(place);
  }

  Future<void> _showPlaceSheet(NearbyCarePlace place) async {
    final home = _home;
    if (home == null) return;

    final isHospital = place.kind == NearbyCareKind.hospital;
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _KindBadge(
                      label: isHospital ? 'Hospital' : 'Clinic',
                      color:
                          isHospital
                              ? const Color(0xFFC62828)
                              : const Color(0xFF1565C0),
                      icon:
                          isHospital
                              ? Icons.local_hospital_rounded
                              : Icons.medical_services_rounded,
                    ),
                    const Spacer(),
                    Text(
                      formatDistanceMeters(place.distanceMeters),
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  place.name,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (place.address != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    place.address!,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _header,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final ok = await openOsmDirections(
                        fromLat: home.latitude,
                        fromLng: home.longitude,
                        toLat: place.latitude,
                        toLng: place.longitude,
                        destinationLabel: place.name,
                      );
                      if (!ctx.mounted) return;
                      if (!ok) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open directions.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.directions_rounded),
                    label: Text(
                      AppLanguageState.pick(
                        en: 'Directions (OpenStreetMap)',
                        ur: 'راستہ (OpenStreetMap)',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingHome) {
      return Scaffold(
        backgroundColor: _canvas,
        appBar: AppBar(
          backgroundColor: _header,
          foregroundColor: Colors.white,
          title: Text(
            AppLanguageState.pick(
              en: 'Clinics & hospitals',
              ur: 'کلینک اور ہسپتال',
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final home = _home;
    if (home == null) {
      return Scaffold(
        backgroundColor: _canvas,
        appBar: AppBar(
          backgroundColor: _header,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text(_error ?? 'Home area not set.')),
      );
    }

    final homePoint = LatLng(home.latitude, home.longitude);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _header,
        foregroundColor: Colors.white,
        title: Text(
          AppLanguageState.pick(
            en: 'Clinics & hospitals',
            ur: 'کلینک اور ہسپتال',
          ),
        ),
        actions: [
          IconButton(
            tooltip: AppLanguageState.pick(
              en: 'Change home area',
              ur: 'گھر کا علاقہ بدلیں',
            ),
            onPressed: () async {
              final updated = await Navigator.pushNamed<bool>(
                context,
                AppRoutes.patientHomeArea,
              );
              if (updated == true && mounted) {
                final userId = AppSession.currentUserId;
                if (userId != null) {
                  final h = await PatientHomeLocationStore.load(userId);
                  if (h != null && mounted) {
                    setState(() => _home = h);
                    _mapController.move(
                      LatLng(h.latitude, h.longitude),
                      13,
                    );
                    await _loadPlaces();
                  }
                }
              }
            },
            icon: const Icon(Icons.home_work_outlined),
          ),
          IconButton(
            tooltip: AppLanguageState.pick(en: 'Refresh', ur: 'تازہ کریں'),
            onPressed: _loadingPlaces ? null : _loadPlaces,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLanguageState.pick(
                      en: 'Near: ${home.summaryLine} (5 km)',
                      ur: 'قریب: ${home.summaryLine} (۵ کلومیٹر)',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: AppLanguageState.pick(en: 'All', ur: 'سب'),
                  selected: _filter == _PlaceFilter.all,
                  onTap: () => setState(() => _filter = _PlaceFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppLanguageState.pick(en: 'Hospitals', ur: 'ہسپتال'),
                  selected: _filter == _PlaceFilter.hospitals,
                  color: const Color(0xFFC62828),
                  onTap:
                      () => setState(() => _filter = _PlaceFilter.hospitals),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppLanguageState.pick(en: 'Clinics', ur: 'کلینک'),
                  selected: _filter == _PlaceFilter.clinics,
                  color: const Color(0xFF1565C0),
                  onTap: () => setState(() => _filter = _PlaceFilter.clinics),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: homePoint,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: OsmMapConstants.tileUrlTemplate,
                      userAgentPackageName: 'com.example.khayal_platform',
                    ),
                    MarkerLayer(
                      markers: [
                        homeMarker(homePoint),
                        for (final p in filtered)
                          carePlaceMarker(
                            p,
                            onTap: () => _selectPlace(p),
                          ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(OsmMapConstants.attribution),
                      ],
                    ),
                  ],
                ),
                if (_loadingPlaces)
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFC62828), fontSize: 13),
              ),
            ),
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child:
                  filtered.isEmpty && !_loadingPlaces
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              AppLanguageState.pick(
                                en:
                                    'No hospitals or clinics found within 5 km. Try changing your home area or refresh.',
                                ur:
                                    '۵ کلومیٹر میں کوئی ہسپتال یا کلینک نہیں ملا۔ گھر کا علاقہ بدلیں یا تازہ کریں۔',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final place = filtered[index];
                            final isHospital =
                                place.kind == NearbyCareKind.hospital;
                            final selected = _selected?.osmId == place.osmId;
                            return Material(
                              color:
                                  selected
                                      ? (isHospital
                                          ? const Color(0xFFFFEBEE)
                                          : const Color(0xFFE3F2FD))
                                      : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _selectPlace(place),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      _KindBadge(
                                        label:
                                            isHospital
                                                ? 'Hospital'
                                                : 'Clinic',
                                        color:
                                            isHospital
                                                ? const Color(0xFFC62828)
                                                : const Color(0xFF1565C0),
                                        icon:
                                            isHospital
                                                ? Icons.local_hospital_rounded
                                                : Icons
                                                    .medical_services_rounded,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (place.address != null)
                                              Text(
                                                place.address!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        formatDistanceMeters(
                                          place.distanceMeters,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _NearbyCareMapScreenState._header;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: c.withValues(alpha: 0.2),
      checkmarkColor: c,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? c : Colors.black87,
      ),
    );
  }
}
