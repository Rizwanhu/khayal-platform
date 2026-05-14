import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';

/// Role select: warm neutral canvas, header, bordered Patient / Caregiver cards.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  static const Color _canvas = Color(0xFFFAF9F6);
  static const Color _title = Color(0xFF1A1A1A);
  static const Color _subtitle = Color(0xFF757575);
  static const Color _patientBorder = Color(0xFF4A6D63);
  static const Color _patientIconBg = Color(0xFFEBF1EF);
  static const Color _patientIcon = Color(0xFF4A6D63);
  static const Color _caregiverBorder = Color(0xFFC99A72);
  static const Color _caregiverIconBg = Color(0xFFF9F2EB);
  static const Color _caregiverIcon = Color(0xFFC17F4A);
  static const Color _cardSubtitle = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Text(
                'Who are you?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: _title,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your role',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'KhayalRoboto',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: _subtitle,
                    ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoleCard(
                      borderColor: _patientBorder,
                      iconBackground: _patientIconBg,
                      icon: Icons.person_rounded,
                      iconColor: _patientIcon,
                      title: 'Patient',
                      subtitle: 'I take medications',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.patientHome),
                    ),
                    const SizedBox(height: 18),
                    _RoleCard(
                      borderColor: _caregiverBorder,
                      iconBackground: _caregiverIconBg,
                      icon: Icons.people_alt_rounded,
                      iconColor: _caregiverIcon,
                      title: 'Caregiver',
                      subtitle: 'I help manage medications',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.caregiverDashboard,
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
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.borderColor,
    required this.iconBackground,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color borderColor;
  final Color iconBackground;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: RoleSelectScreen._title,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'KhayalRoboto',
                      fontSize: 14,
                      color: RoleSelectScreen._cardSubtitle,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
