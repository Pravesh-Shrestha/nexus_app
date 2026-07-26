import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/features/welcome/presentation/welcome_screen.dart';
import 'package:nexus_app/features/home/presentation/main_layout.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';
import 'package:nexus_app/features/auth/presentation/biometric_lock_screen.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/features/auth/presentation/profile_setup_screen.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    // Check auth status after the animation delay of 3 seconds
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        final authService = AuthService();
        final user = authService.currentUser;
        
        if (user != null) {
          // Verify if the user profile document exists in Firestore
          final userModel = await authService.getUserData(user.uid);
          if (userModel == null) {
            if (mounted) {
              final authUser = FirebaseAuth.instance.currentUser;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ProfileSetupScreen(
                    fullName: authUser?.displayName ?? '',
                    username: authUser?.email != null ? authUser!.email!.split('@')[0] : 'Gamer',
                    dob: '',
                    gender: 'Prefer not to say',
                  ),
                ),
              );
            }
          } else {
            _checkBiometricSession(userModel);
          }
        } else {
          // No user logged in
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );
        }
      }
    });
  }

  Future<void> _checkBiometricSession(UserModel userModel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool useBiometrics = prefs.getBool('use_biometrics') ?? false;
      final int lastVerification = prefs.getInt('last_biometric_verification') ?? 0;
      final int intervalDays = prefs.getInt('biometric_days_interval') ?? 3;

      if (useBiometrics) {
        final DateTime lastDateTime = DateTime.fromMillisecondsSinceEpoch(lastVerification);
        final int diffDays = DateTime.now().difference(lastDateTime).inDays;

        if (diffDays >= intervalDays || lastVerification == 0) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => BiometricLockScreen(
                  username: userModel.username,
                  profileImageUrl: userModel.profileImageUrl,
                ),
              ),
            );
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Biometric Session Check Failure: $e');
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Dark background color from image
      body: SafeArea(
        child: Column(
          children: [
            // Center Logo
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/splash/Frame.png',
                      width: 150,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/splash/Container.png',
                      width: 150,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Progress Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phase 01',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Connecting',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Gradient Progress Bar
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.purpleAccent,
                          Colors.lightBlueAccent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
