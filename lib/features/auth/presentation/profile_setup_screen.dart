import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/auth/presentation/setup_success_screen.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';
import 'package:nexus_app/core/widgets/custom_snackbar.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String fullName;
  final String username;
  final String dob;
  final String gender;

  const ProfileSetupScreen({
    super.key,
    required this.fullName,
    required this.username,
    required this.dob,
    required this.gender,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // Store selected options
  String _selectedRole = 'Streamer';
  final List<String> _selectedGames = [];
  String _selectedPlaystyle = 'Crazy';
  String _selectedSkillLevel = 'Pro';

  double? _latitude;
  double? _longitude;
  String _locationName = '';
  bool _isCalibratingGps = false;

  Future<void> _calibrateGps() async {
    setState(() => _isCalibratingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationName = 'User GPS Sector';
        _isCalibratingGps = false;
      });
    } catch (e) {
      setState(() => _isCalibratingGps = false);
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'GPS Access Failed',
            message: 'GPS Access: $e. Simulating regional grid offset.',
            actionText: 'Okay',
          ),
        );
      }
      // Fallback
      final math.Random random = math.Random();
      final double simulatedLat = 27.7172 + (random.nextDouble() - 0.5) * 0.005;
      final double simulatedLng = 85.3240 + (random.nextDouble() - 0.5) * 0.005;
      setState(() {
        _latitude = simulatedLat;
        _longitude = simulatedLng;
        _locationName = 'Sector Grid ${random.nextInt(90) + 10}';
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF16171D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white10,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check : Icons.add,
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white54,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0B0C10) : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nexus',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/splash/Frame.png',
                        width: 20,
                        height: 20,
                        color: const Color(0xFF0B0C10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Tell Us About Yourself',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete your profile to find the perfect squad.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // WHO ARE YOU?
                    _buildSectionTitle('WHO ARE YOU?'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ['Gamer', 'Streamer', 'Creator', 'Others'].map((role) {
                        return _buildChip(
                          label: role,
                          isSelected: _selectedRole == role,
                          onTap: () {
                            setState(() {
                              _selectedRole = role;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    // FAVORITE GAMES
                    _buildSectionTitle('FAVORITE GAMES'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ['FreeFire', 'Valorant', 'PUBG', 'Others'].map((game) {
                        final isSelected = _selectedGames.contains(game);
                        return _buildChip(
                          label: game,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedGames.remove(game);
                              } else {
                                _selectedGames.add(game);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    // PLAYSTYLE
                    _buildSectionTitle('PLAYSTYLE'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ['Casual', 'Crazy', 'Hardcore', 'Others'].map((style) {
                        return _buildChip(
                          label: style,
                          isSelected: _selectedPlaystyle == style,
                          onTap: () {
                            setState(() {
                              _selectedPlaystyle = style;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    // SKILL LEVEL
                    _buildSectionTitle('SKILL LEVEL'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ['Noob', 'Soso', 'Pro', 'E-Player'].map((level) {
                        return _buildChip(
                          label: level,
                          isSelected: _selectedSkillLevel == level,
                          onTap: () {
                            setState(() {
                              _selectedSkillLevel = level;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    // GPS LOCATION
                    _buildSectionTitle('TACTICAL GPS POSITION (OPTIONAL)'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16171D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _latitude != null ? 'GRID CALIBRATED' : 'OFFLINE',
                                  style: TextStyle(
                                    color: _latitude != null ? const Color(0xFF00E5FF) : Colors.white38,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _latitude != null
                                      ? '$_locationName (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                                      : 'Share your location to find allies nearby.',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _isCalibratingGps ? null : _calibrateGps,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _latitude != null ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: _isCalibratingGps
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      _latitude != null ? 'Recalibrate' : 'Sync GPS',
                                      style: TextStyle(
                                        color: _latitude != null ? Colors.black : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Bottom Continue Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: GestureDetector(
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final userModel = UserModel(
                    uid: user.uid,
                    email: user.email ?? '',
                    fullName: widget.fullName,
                    username: widget.username,
                    dob: widget.dob,
                    gender: widget.gender,
                    role: _selectedRole,
                    favoriteGames: _selectedGames,
                    playstyle: _selectedPlaystyle,
                    skillLevel: _selectedSkillLevel,
                    latitude: _latitude,
                    longitude: _longitude,
                    location: _locationName,
                  );

                  final navigator = Navigator.of(context);

                  try {
                    await AuthService().saveUserData(userModel);
                    if (mounted) {
                      navigator.pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => SetupSuccessScreen(
                            email: userModel.email,
                            fullName: userModel.fullName,
                          ),
                        ),
                      );
                    }
                  } on AppException catch (e) {
                    if (mounted) {
                      CustomSnackBar.showErrorSnackBar(context, e);
                    }
                  } catch (e) {
                    if (mounted) {
                      CustomSnackBar.showErrorSnackBar(
                        context,
                        AppException(
                          title: 'Save Failed',
                          message: 'Failed to save profile. Please try again.',
                          actionText: 'Retry',
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF16171D),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CONTINUE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
