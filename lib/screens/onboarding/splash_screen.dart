import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/auth_restore.dart';
import '../../core/navigation/app_routes.dart';

/// Splash: shows brand, then opens home if already signed in, else onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _creamCenter = Color(0xFFFDFBF7);
  static const Color _creamEdge = Color(0xFFF2EBE1);
  static const Color _logoSage = Color(0xFF6B8E7B);

  @override
  void initState() {
    super.initState();
    unawaited(_goNext());
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    try {
      final homeRoute = await AuthRestore.routeForRestoredSession();
      if (!mounted) return;
      if (homeRoute != null) {
        Navigator.pushReplacementNamed(context, homeRoute);
        return;
      }
    } catch (_) {
      // Fall through to first-time onboarding.
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.languageSelect);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_creamEdge, _creamCenter, _creamCenter, _creamEdge],
            stops: [0.0, 0.32, 0.68, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/khayal.jpeg',
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                    width: 92,
                    height: 92,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _logoSage,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      r'$',
                      style: TextStyle(
                        fontFamily: 'KhayalRoboto',
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'خیال',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 40,
                    height: 1.15,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Khayal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'KhayalRoboto',
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.35,
                    height: 1.2,
                    color: Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
