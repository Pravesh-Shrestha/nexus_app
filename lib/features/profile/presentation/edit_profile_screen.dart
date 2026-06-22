import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/core/presentation/widgets/custom_text_field.dart';
import 'package:nexus_app/core/presentation/widgets/gradient_button.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  
  String _selectedRole = 'Streamer';
  String _selectedPlaystyle = 'Crazy';
  String _selectedSkillLevel = 'Pro';
  final List<String> _selectedGames = [];
  
  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _currentUserModel;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final model = await AuthService().getUserData(user.uid);
      if (model != null && mounted) {
        setState(() {
          _currentUserModel = model;
          _fullNameController.text = model.fullName;
          _usernameController.text = model.username;
          _selectedRole = model.role.isNotEmpty ? model.role : 'Streamer';
          _selectedPlaystyle = model.playstyle.isNotEmpty ? model.playstyle : 'Crazy';
          _selectedSkillLevel = model.skillLevel.isNotEmpty ? model.skillLevel : 'Pro';
          _selectedGames.addAll(model.favoriteGames);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_currentUserModel == null) return;
    
    setState(() => _isSaving = true);
    
    final updatedModel = _currentUserModel!.copyWith(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      role: _selectedRole,
      playstyle: _selectedPlaystyle,
      skillLevel: _selectedSkillLevel,
      favoriteGames: _selectedGames,
    );

    try {
      await AuthService().saveUserData(updatedModel);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info
                    CustomTextField(
                      controller: _fullNameController,
                      hintText: 'Full name',
                      prefixIcon: Icons.person_outline,
                    ),
                    CustomTextField(
                      controller: _usernameController,
                      hintText: 'Username',
                      prefixIcon: Icons.alternate_email,
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    
                    // WHO ARE YOU?
                    _buildSectionTitle('WHO ARE YOU?'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ['Gamer', 'Streamer', 'Creator', 'Others'].map((role) {
                        return _buildChip(
                          label: role,
                          isSelected: _selectedRole == role,
                          onTap: () => setState(() => _selectedRole = role),
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
                          onTap: () => setState(() => _selectedPlaystyle = style),
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
                          onTap: () => setState(() => _selectedSkillLevel = level),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 40),
                    GradientButton(
                      text: 'SAVE PROFILE',
                      onTap: _saveProfile,
                      isLoading: _isSaving,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
