import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';

/// Splash (SCR-001): cream gradient, sage circle with `$`, Urdu + English wordmark.
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
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.languageSelect);
    });
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
                Container(
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
                const SizedBox(height: 22),
                const Text(
                  'خیال',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 44,
                    height: 1.25,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Khayal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'KhayalRoboto',
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.35,
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
