import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';
import 'package:nexus_app/features/auth/data/user_settings_model.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  UserSettingsModel? _userSettings;
  bool _isLoading = true;

  bool _useBiometrics = false;
  int _biometricIntervalDays = 3;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final localBiometrics = prefs.getBool('use_biometrics') ?? false;
    final localInterval = prefs.getInt('biometric_days_interval') ?? 3;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final settings = await AuthService().getUserSettings(user.uid);
        if (mounted) {
          setState(() {
            _userSettings = settings;
            _useBiometrics = localBiometrics;
            _biometricIntervalDays = localInterval;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _useBiometrics = localBiometrics;
            _biometricIntervalDays = localInterval;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _useBiometrics = localBiometrics;
          _biometricIntervalDays = localInterval;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleBiometrics(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    if (enable) {
      try {
        final isAvailable = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
        if (!isAvailable) {
          throw 'Biometric hardware is not supported or configured on this device.';
        }

        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Enable biometrics to securely log into Nexus.',
          persistAcrossBackgrounding: true,
          biometricOnly: true,
        );

        if (authenticated) {
          await prefs.setBool('use_biometrics', true);
          await prefs.setInt('last_biometric_verification', DateTime.now().millisecondsSinceEpoch);
          setState(() {
            _useBiometrics = true;
          });
        } else {
          throw 'Authentication cancelled.';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to enable biometrics: $e'), backgroundColor: AppColors.errorRed),
          );
        }
      }
    } else {
      await prefs.setBool('use_biometrics', false);
      setState(() {
        _useBiometrics = false;
      });
    }
  }

  Future<void> _updateBiometricInterval(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('biometric_days_interval', days);
    setState(() {
      _biometricIntervalDays = days;
    });
  }

  Future<void> _updateSetting(UserSettingsModel updatedSettings) async {
    setState(() {
      _userSettings = updatedSettings;
    });
    try {
      await AuthService().updateUserSettings(updatedSettings);
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Advanced Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryCyan),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            Icons.palette_outlined,
                            'Theme Selection',
                            'Customize the visual color palette and theme mode',
                            Colors.purpleAccent,
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _buildSettingsTile(
                            Icons.sensors,
                            'Proximity Sensor',
                            'Locks screen automatically when phone is close to ear',
                            Colors.blueAccent,
                            trailing: Switch(
                              value: _userSettings?.proximityEnabled ?? true,
                              activeThumbColor: AppColors.primaryCyan,
                              activeTrackColor: AppColors.primaryPurple.withValues(alpha: 0.5),
                              inactiveThumbColor: Colors.white60,
                              inactiveTrackColor: Colors.white10,
                              onChanged: (value) {
                                if (_userSettings != null) {
                                  _updateSetting(_userSettings!.copyWith(proximityEnabled: value));
                                }
                              },
                            ),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _buildSettingsTile(
                            Icons.vibration,
                            'Haptic Feedback',
                            'Enable subtle physical vibrations during interactions',
                            Colors.orangeAccent,
                            trailing: Switch(
                              value: _userSettings?.hapticsEnabled ?? true,
                              activeThumbColor: AppColors.primaryCyan,
                              activeTrackColor: AppColors.primaryPurple.withValues(alpha: 0.5),
                              inactiveThumbColor: Colors.white60,
                              inactiveTrackColor: Colors.white10,
                              onChanged: (value) {
                                if (_userSettings != null) {
                                  _updateSetting(_userSettings!.copyWith(hapticsEnabled: value));
                                }
                              },
                            ),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _buildSettingsTile(
                            Icons.data_usage,
                            'Data Saver',
                            'Compresses images and assets to reduce data consumption',
                            Colors.lightGreenAccent,
                            trailing: Switch(
                              value: _userSettings?.dataSaverEnabled ?? false,
                              activeThumbColor: AppColors.primaryCyan,
                              activeTrackColor: AppColors.primaryPurple.withValues(alpha: 0.5),
                              inactiveThumbColor: Colors.white60,
                              inactiveTrackColor: Colors.white10,
                              onChanged: (value) {
                                if (_userSettings != null) {
                                  _updateSetting(_userSettings!.copyWith(dataSaverEnabled: value));
                                }
                              },
                            ),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _buildSettingsTile(
                            Icons.fingerprint,
                            'Biometric Security',
                            'Unlock Nexus with fingerprint or facial ID scan',
                            Colors.tealAccent,
                            trailing: Switch(
                              value: _useBiometrics,
                              activeThumbColor: AppColors.primaryCyan,
                              activeTrackColor: AppColors.primaryPurple.withValues(alpha: 0.5),
                              inactiveThumbColor: Colors.white60,
                              inactiveTrackColor: Colors.white10,
                              onChanged: (value) => _toggleBiometrics(value),
                            ),
                          ),
                          if (_useBiometrics) ...[
                            const Divider(color: Colors.white10, height: 1),
                            _buildSettingsTile(
                              Icons.history_toggle_off,
                              'Verification Cycle',
                              'Enforce biometrics lock after interval',
                              Colors.cyanAccent,
                              trailing: DropdownButton<int>(
                                value: _biometricIntervalDays,
                                dropdownColor: AppColors.surface,
                                underline: const SizedBox(),
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                items: const [
                                  DropdownMenuItem(value: 3, child: Text('Every 3 Days')),
                                  DropdownMenuItem(value: 5, child: Text('Every 5 Days')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    _updateBiometricInterval(value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor, {
    Widget? trailing,
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
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 11,
          ),
        ),
      ),
      trailing: trailing ?? const Icon(
        Icons.chevron_right,
        color: Colors.white30,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
