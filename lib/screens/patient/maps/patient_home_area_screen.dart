import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/maps/nearby_places_service.dart';
import '../../../core/maps/osm_geocoding_service.dart';
import '../../../core/maps/overpass_nearby_places_service.dart';
import '../../../core/maps/osm_map_constants.dart';
import '../../../core/maps/patient_home_location.dart';
import '../../../core/maps/patient_home_location_store.dart';
import 'care_map_markers.dart';

/// Set patient home on OpenStreetMap (tap map or use current location).
class PatientHomeAreaScreen extends StatefulWidget {
  const PatientHomeAreaScreen({super.key});

  @override
  State<PatientHomeAreaScreen> createState() => _PatientHomeAreaScreenState();
}

class _PatientHomeAreaScreenState extends State<PatientHomeAreaScreen> {
  static const Color _header = Color(0xFF608266);
  static const Color _canvas = Color(0xFFF9F8F3);

  final _mapController = MapController();
  final _labelController = TextEditingController();
  final _geocoder = OsmGeocodingService();
  final _placesService = NearbyPlacesService();

  LatLng? _pin;
  String? _resolvedAddress;
  List<NearbyCarePlace> _nearbyPlaces = [];
  bool _saving = false;
  bool _locating = false;
  bool _resolvingAddress = false;
  bool _loadingPlaces = false;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final userId = AppSession.currentUserId;
    if (userId == null) {
      setState(() {
        _pin = const LatLng(
          OsmMapConstants.defaultLat,
          OsmMapConstants.defaultLng,
        );
      });
      return;
    }
    final existing = await PatientHomeLocationStore.load(userId);
    if (!mounted) return;
    if (existing != null) {
      setState(() {
        _pin = LatLng(existing.latitude, existing.longitude);
        _labelController.text = existing.areaLabel ?? '';
        _resolvedAddress = existing.displayAddress;
      });
      _mapController.move(_pin!, 14);
      if (_resolvedAddress == null || _resolvedAddress!.isEmpty) {
        await _resolveAddressForPin(_pin!);
      }
      await _loadNearbyPlaces(_pin!);
    } else {
      setState(() {
        _pin = const LatLng(
          OsmMapConstants.defaultLat,
          OsmMapConstants.defaultLng,
        );
      });
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _labelController.dispose();
    _mapController.dispose();
    _geocoder.dispose();
    _placesService.dispose();
    super.dispose();
  }

  void _onPinMoved(LatLng point) {
    setState(() => _pin = point);
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 450), () {
      _resolveAddressForPin(point);
      _loadNearbyPlaces(point);
    });
  }

  Future<void> _loadNearbyPlaces(LatLng point) async {
    setState(() => _loadingPlaces = true);
    try {
      final list = await _placesService.fetchHospitalsAndClinics(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted) return;
      setState(() {
        _nearbyPlaces = list;
        _loadingPlaces = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _nearbyPlaces = [];
          _loadingPlaces = false;
        });
      }
    }
  }

  ({int hospitals, int clinics}) get _placeCounts {
    var hospitals = 0;
    var clinics = 0;
    for (final p in _nearbyPlaces) {
      if (p.kind == NearbyCareKind.hospital) {
        hospitals++;
      } else {
        clinics++;
      }
    }
    return (hospitals: hospitals, clinics: clinics);
  }

  Future<void> _resolveAddressForPin(LatLng point) async {
    setState(() => _resolvingAddress = true);
    final address = await _geocoder.reverseGeocode(
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (!mounted) return;
    setState(() {
      _resolvedAddress = address;
      _resolvingAddress = false;
    });
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is needed to use your current position.',
            ),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final point = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      _onPinMoved(point);
      _mapController.move(point, 15);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final userId = AppSession.currentUserId;
    final pin = _pin;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }
    if (pin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap the map to set your home area.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      var label = _labelController.text.trim();
      if (label.isEmpty) {
        label = _resolvedAddress?.trim() ?? '';
      }
      await PatientHomeLocationStore.save(
        userId: userId,
        location: PatientHomeLocation(
          latitude: pin.latitude,
          longitude: pin.longitude,
          areaLabel: label.isEmpty ? null : label,
          displayAddress: _resolvedAddress,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Home area saved.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSavedLocationCard(LatLng pin) {
    final coords = formatLatLngLabel(pin.latitude, pin.longitude);
    final address = _resolvedAddress?.trim();
    final counts = _placeCounts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _header.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_rounded, color: _header),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLanguageState.pick(
                        en: 'Selected home location',
                        ur: 'منتخب گھر کی جگہ',
                      ),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _header,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_resolvingAddress)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (address != null && address.isNotEmpty)
                      Text(
                        address,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      )
                    else
                      Text(
                        AppLanguageState.pick(
                          en: 'Looking up address… tap map if this stays empty.',
                          ur: 'پتہ تلاش ہو رہا ہے…',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      coords,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black45,
                        fontFamily: 'KhayalRoboto',
                      ),
                    ),
                    if (_loadingPlaces)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          AppLanguageState.pick(
                            en: 'Finding hospitals & clinics nearby…',
                            ur: 'قریبی ہسپتال اور کلینک تلاش ہو رہے ہیں…',
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.black54),
                        ),
                      )
                    else if (_nearbyPlaces.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            _LegendDot(
                              color: const Color(0xFFC62828),
                              label: AppLanguageState.pick(
                                en: '${counts.hospitals} hospitals',
                                ur: '${counts.hospitals} ہسپتال',
                              ),
                            ),
                            const SizedBox(width: 12),
                            _LegendDot(
                              color: const Color(0xFF1565C0),
                              label: AppLanguageState.pick(
                                en: '${counts.clinics} clinics',
                                ur: '${counts.clinics} کلینک',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pin = _pin;

    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _header,
        foregroundColor: Colors.white,
        title: Text(
          AppLanguageState.pick(
            en: 'Set home area',
            ur: 'گھر کا علاقہ مقرر کریں',
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              AppLanguageState.pick(
                en:
                    'Tap the map where you live. Your address will appear below the pin.',
                ur:
                    'نقشے پر اپنے گھر کی جگہ ٹیپ کریں۔ پتہ نیچے دکھایا جائے گا۔',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ),
          if (pin != null) _buildSavedLocationCard(pin),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              controller: _labelController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: AppLanguageState.pick(
                  en: 'Home name (optional)',
                  ur: 'گھر کا نام (اختیاری)',
                ),
                hintText: AppLanguageState.pick(
                  en: 'e.g. My home, Gulberg',
                  ur: 'مثلاً میرا گھر، گلبرگ',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: pin == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: pin,
                    initialZoom: 14,
                    onTap: (_, point) => _onPinMoved(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: OsmMapConstants.tileUrlTemplate,
                      userAgentPackageName: 'com.example.khayal_platform',
                    ),
                    MarkerLayer(
                      markers: [
                        homeMarker(pin),
                        for (final place in _nearbyPlaces)
                          carePlaceMarker(place),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(OsmMapConstants.attribution),
                      ],
                    ),
                  ],
                ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: _locating ? null : _useMyLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(
                    AppLanguageState.pick(
                      en: 'Use my current location',
                      ur: 'میری موجودہ جگہ استعمال کریں',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _header,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    _saving
                        ? AppLanguageState.pick(en: 'Saving…', ur: 'محفوظ ہو رہا ہے…')
                        : AppLanguageState.pick(
                            en: 'Save home area',
                            ur: 'گھر کا علاقہ محفوظ کریں',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
