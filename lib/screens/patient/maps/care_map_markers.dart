import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/maps/overpass_nearby_places_service.dart';

Marker homeMarker(LatLng point) {
  return Marker(
    point: point,
    width: 48,
    height: 48,
    child: const _MapPin(
      color: Color(0xFF2E7D32),
      icon: Icons.home_rounded,
      label: 'Home',
    ),
  );
}

Marker carePlaceMarker(NearbyCarePlace place, {VoidCallback? onTap}) {
  final isHospital = place.kind == NearbyCareKind.hospital;
  return Marker(
    point: place.latLng,
    width: 52,
    height: 58,
    child: GestureDetector(
      onTap: onTap,
      child: _MapPin(
        color: isHospital ? const Color(0xFFC62828) : const Color(0xFF1565C0),
        icon:
            isHospital
                ? Icons.local_hospital_rounded
                : Icons.medical_services_rounded,
        label: isHospital ? 'Hospital' : 'Clinic',
        showLabel: true,
      ),
    ),
  );
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.color,
    required this.icon,
    this.label,
    this.showLabel = false,
  });

  final Color color;
  final IconData icon;
  final String? label;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel && label != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}
