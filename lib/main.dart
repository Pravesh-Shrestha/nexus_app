import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_theme.dart';
import 'package:nexus_app/features/splash/presentation/splash_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:nexus_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
