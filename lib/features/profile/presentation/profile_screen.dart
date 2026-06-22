import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/auth/presentation/login_screen.dart';
import 'package:nexus_app/features/profile/presentation/advanced_settings_screen.dart';
import 'package:nexus_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:nexus_app/features/profile/presentation/change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final data = await AuthService().getUserData(user.uid);
        if (mounted) {
          setState(() {
            _userModel = data;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryPurple,
          ),
        ),
      );
    }

    final model = _userModel;
    final String fullName = model?.fullName.isNotEmpty == true ? model!.fullName : 'Viper Protocol';
    final String username = model?.username.isNotEmpty == true ? model!.username : 'Viper_Protocol';
    final String skillLevel = model?.skillLevel.isNotEmpty == true ? model!.skillLevel.toUpperCase() : 'PRO LEAGUE';
    final String role = model?.role.isNotEmpty == true ? model!.role : 'Streamer';
    final String playstyle = model?.playstyle.isNotEmpty == true ? model!.playstyle : 'Crazy';
    final List<String> favoriteGames = model?.favoriteGames ?? ['Valorant', 'FreeFire'];
    final String bio = model != null
        ? '$role • $playstyle Gamer\nPlays: ${favoriteGames.isNotEmpty ? favoriteGames.join(", ") : "No games selected"}'
        : 'Tactical specialist. 24/7 competitive grind.\nSquad leader of [NEON_RAIDERS].';

    final String imageUrl = model?.profileImageUrl.isNotEmpty == true
        ? model!.profileImageUrl
        : 'https://api.dicebear.com/7.x/adventurer/png?seed=$username';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120), // Padding for bottom nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.p24,
                  vertical: AppSizes.p16,
                ),
                child: Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // User Info Section
              Center(
                child: Column(
                  children: [
                    // Avatar with Camera Icon
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryPurple,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurple.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.statusOnline,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Username and Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppSizes.r16),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            skillLevel,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bio
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Stats Row (Friends and Communities)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Row(
                  children: [
                    Expanded(child: _buildStatBox('Friends', '1.2k')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatBox('Communities', '42')),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Account Management Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Text(
                  'ACCOUNT MANAGEMENT',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.r16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        Icons.edit,
                        'Edit Profile',
                        Colors.greenAccent,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                          _loadUserData();
                        },
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildSettingsTile(
                        Icons.notifications_none,
                        'Notification Settings',
                        Colors.greenAccent,
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildSettingsTile(
                        Icons.lock_outline,
                        'Change Password',
                        Colors.tealAccent,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Other Settings Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Text(
                  'OTHER SETTINGS',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.r16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        Icons.shield_outlined,
                        'Privacy & Safety',
                        Colors.white70,
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildSettingsTile(
                        Icons.help_outline,
                        'Support Center',
                        Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Advanced Settings Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Text(
                  'ADVANCED SETTINGS',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.r16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        Icons.settings_suggest_outlined,
                        'View More Options',
                        Colors.purpleAccent,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdvancedSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Log Out Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: GestureDetector(
                  onTap: () {
                    _showLogoutConfirmation(context);
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                      border: Border.all(color: AppColors.logoutBorder, width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: AppColors.logoutText, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'LOG OUT',
                          style: TextStyle(
                            color: AppColors.logoutText,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Version Text
              const Center(
                child: Text(
                  'Nexus Version 2.4.0-Stable',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white30,
        size: 20,
      ),
      onTap: onTap ?? () {},
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.p24),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(AppSizes.r24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background.withValues(alpha: 0.5),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.logout,
                      color: AppColors.primaryPurple,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Are You Sure?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                const Text(
                  'Log Out from NEXUS? You will\nneed to sign back in to access your\nstats and community.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Buttons
                GestureDetector(
                  onTap: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                      border: Border.all(color: AppColors.statusOnline, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'YES',
                        style: TextStyle(
                          color: AppColors.statusOnline,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                      border: Border.all(color: AppColors.logoutBorder, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'NO',
                        style: TextStyle(
                          color: AppColors.logoutText,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
