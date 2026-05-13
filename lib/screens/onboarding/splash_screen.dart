import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
      backgroundColor: AppTheme.lightGreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 56,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 18),
            Text('Khayal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Medication Reminder App'),
          ],
        ),
      ),
    );
  }
}
