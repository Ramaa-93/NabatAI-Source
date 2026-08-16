import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: NabatAIApp(),
    ),
  );
}

class NabatAIApp extends StatelessWidget {
  const NabatAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nabat AI',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}