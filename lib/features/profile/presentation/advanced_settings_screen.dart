import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key});

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
      body: SingleChildScrollView(
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
                      Colors.purpleAccent,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildSettingsTile(
                      Icons.sensors,
                      'Proximity Sensor',
                      Colors.blueAccent,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildSettingsTile(
                      Icons.vibration,
                      'Haptic Feedback',
                      Colors.orangeAccent,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildSettingsTile(
                      Icons.data_usage,
                      'Data Saver',
                      Colors.lightGreenAccent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, Color iconColor) {
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
      onTap: () {},
    );
  }
}
