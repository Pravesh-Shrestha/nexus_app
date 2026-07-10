import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/home/presentation/main_layout.dart';

class BiometricLockScreen extends StatefulWidget {
  final String username;
  final String profileImageUrl;
  
  const BiometricLockScreen({
    super.key,
    required this.username,
    required this.profileImageUrl,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _statusMessage = 'TACTICAL ENCLAVE LOCKED';

  @override
  void initState() {
    super.initState();
    // Trigger authentication automatically on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'SCANNING PROFILE DATA...';
    });

    try {
      final isAvailable = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!isAvailable) {
        setState(() {
          _isAuthenticating = false;
          _statusMessage = 'BIOMETRIC HARDWARE OFFLINE';
        });
        return;
      }

      final success = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint or face to authenticate and decrypt Nexus profile.',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );

      if (success) {
        // Save the timestamp of this successful biometric verification
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_biometric_verification', DateTime.now().millisecondsSinceEpoch);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainLayout()),
          );
        }
      } else {
        setState(() {
          _isAuthenticating = false;
          _statusMessage = 'VERIFICATION FAILED';
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _statusMessage = 'SECURE CHANNEL ERROR';
      });
      debugPrint('Biometric Auth Error: $e');
    }
  }

  Widget _buildAvatarImage(String imageUrl, String seed, {double size = 100}) {
    if (imageUrl.startsWith('data:image') || !imageUrl.startsWith('http')) {
      try {
        final cleanBase64 = imageUrl.contains(',') ? imageUrl.split(',')[1] : imageUrl;
        final decodedBytes = base64Decode(cleanBase64);
        return ClipOval(
          child: Image.memory(
            decodedBytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    return ClipOval(
      child: Image.network(
        imageUrl.isNotEmpty ? imageUrl : 'https://api.dicebear.com/7.x/adventurer/png?seed=$seed',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.network(
          'https://api.dicebear.com/7.x/adventurer/png?seed=$seed',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Branded Title Header
                const Text(
                  'NEXUS HUD',
                  style: TextStyle(
                    color: AppColors.primaryCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 32),

                // User profile avatar with glowing rings
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryCyan, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    _buildAvatarImage(widget.profileImageUrl, widget.username, size: 100),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'Welcome Back, ${widget.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('FAILED') ? AppColors.errorRed : Colors.white30,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),

                const Spacer(),

                // Verification trigger buttons
                GestureDetector(
                  onTap: _authenticate,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isAuthenticating ? AppColors.primaryPurple : AppColors.primaryCyan,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isAuthenticating ? AppColors.primaryPurple : AppColors.primaryCyan)
                              .withValues(alpha: 0.2),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.fingerprint,
                        color: _isAuthenticating ? AppColors.primaryPurple : AppColors.primaryCyan,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'TAP SCANNER TO AUTHENTICATE',
                  style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.0),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
