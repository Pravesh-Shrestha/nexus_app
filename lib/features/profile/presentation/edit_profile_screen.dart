import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/core/presentation/widgets/custom_text_field.dart';
import 'package:nexus_app/core/presentation/widgets/gradient_button.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/core/services/cloudinary_service.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';
import 'package:nexus_app/core/widgets/custom_snackbar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedGender;
  String _profileImageUrl = '';
  
  String _selectedRole = 'Streamer';
  String _selectedPlaystyle = 'Crazy';
  String _selectedSkillLevel = 'Pro';
  final List<String> _selectedGames = [];
  
  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _currentUserModel;

  double? _latitude;
  double? _longitude;
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
        _locationController.text = 'User GPS Sector';
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
      final math.Random random = math.Random();
      final double simulatedLat = 27.7172 + (random.nextDouble() - 0.5) * 0.005;
      final double simulatedLng = 85.3240 + (random.nextDouble() - 0.5) * 0.005;
      setState(() {
        _latitude = simulatedLat;
        _longitude = simulatedLng;
        _locationController.text = 'Sector Grid ${random.nextInt(90) + 10}';
      });
    }
  }

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
          _dobController.text = model.dob;
          _selectedGender = model.gender.isNotEmpty ? model.gender : null;
          _bioController.text = model.bio;
          _phoneNumberController.text = model.phoneNumber;
          _locationController.text = model.location;
          _latitude = model.latitude;
          _longitude = model.longitude;
          _profileImageUrl = model.profileImageUrl;
          _selectedRole = model.role.isNotEmpty ? model.role : 'Streamer';
          _selectedPlaystyle = model.playstyle.isNotEmpty ? model.playstyle : 'Crazy';
          _selectedSkillLevel = model.skillLevel.isNotEmpty ? model.skillLevel : 'Pro';
          _selectedGames.clear();
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
    _dobController.dispose();
    _bioController.dispose();
    _phoneNumberController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
              surface: AppColors.surfaceHighlight,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formattedDate = "${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _dobController.text = formattedDate;
      });
    }
  }

  void _showGamingPreferencesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Widget buildSectionTitle(String title) {
              return Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              );
            }

            Widget buildChip({
              required String label,
              required bool isSelected,
              required VoidCallback onTap,
            }) {
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFF16171D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white10,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check : Icons.add,
                        color: isSelected ? const Color(0xFF00E5FF) : Colors.white54,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF0B0C10) : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gaming Preferences',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSectionTitle('WHO ARE YOU?'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Gamer', 'Streamer', 'Creator', 'Others'].map((role) {
                              return buildChip(
                                label: role,
                                isSelected: _selectedRole == role,
                                onTap: () {
                                  setModalState(() {
                                    _selectedRole = role;
                                  });
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),
                          buildSectionTitle('FAVORITE GAMES'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['FreeFire', 'Valorant', 'PUBG', 'Others'].map((game) {
                              final isSelected = _selectedGames.contains(game);
                              return buildChip(
                                label: game,
                                isSelected: isSelected,
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      _selectedGames.remove(game);
                                    } else {
                                      _selectedGames.add(game);
                                    }
                                  });
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),
                          buildSectionTitle('PLAYSTYLE'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Casual', 'Crazy', 'Hardcore', 'Others'].map((style) {
                              return buildChip(
                                label: style,
                                isSelected: _selectedPlaystyle == style,
                                onTap: () {
                                  setModalState(() {
                                    _selectedPlaystyle = style;
                                  });
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),
                          buildSectionTitle('SKILL LEVEL'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Noob', 'Soso', 'Pro', 'E-Player'].map((level) {
                              return buildChip(
                                label: level,
                                isSelected: _selectedSkillLevel == level,
                                onTap: () {
                                  setModalState(() {
                                    _selectedSkillLevel = level;
                                  });
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'DONE',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAvatar() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceHighlight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Select Profile Picture',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white70),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white70),
              title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 75,
      );

      if (image != null && mounted) {
        setState(() => _isSaving = true);

        // Upload to Cloudinary immediately
        final cloudinaryUrl = await CloudinaryService().uploadImage(File(image.path));
        
        if (cloudinaryUrl != null) {
          setState(() {
            _profileImageUrl = cloudinaryUrl;
            _isSaving = false;
          });
        } else {
          setState(() => _isSaving = false);
        }
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        CustomSnackBar.showErrorSnackBar(context, e);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'Upload Failed',
            message: 'Failed to upload image. Please try again.',
            actionText: 'Retry',
          ),
        );
      }
    }
  }

  Widget _buildAvatarImage(String imageUrl) {
    if (imageUrl.startsWith('data:image') || !imageUrl.startsWith('http')) {
      try {
        final cleanBase64 = imageUrl.contains(',') ? imageUrl.split(',')[1] : imageUrl;
        final decodedBytes = base64Decode(cleanBase64);
        return Image.memory(
          decodedBytes,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      } catch (e) {
        // Fallback
      }
    }
    
    final seedUsername = _usernameController.text.isNotEmpty ? _usernameController.text : 'default';
    return Image.network(
      imageUrl.isNotEmpty ? imageUrl : 'https://api.dicebear.com/7.x/adventurer/png?seed=$seedUsername',
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          width: 100,
          height: 100,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryPurple,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Image.network(
        'https://api.dicebear.com/7.x/adventurer/png?seed=$seedUsername',
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_currentUserModel == null) return;
    
    setState(() => _isSaving = true);
    
    final updatedModel = _currentUserModel!.copyWith(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _selectedGender ?? '',
      bio: _bioController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      location: _locationController.text.trim(),
      role: _selectedRole,
      playstyle: _selectedPlaystyle,
      skillLevel: _selectedSkillLevel,
      favoriteGames: _selectedGames,
      profileImageUrl: _profileImageUrl,
      latitude: _latitude,
      longitude: _longitude,
    );

    try {
      await AuthService().saveUserData(updatedModel);
      if (mounted) {
        CustomSnackBar.showSuccessSnackBar(
          context,
          title: 'Success',
          message: 'Profile updated successfully',
        );
        Navigator.of(context).pop();
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
            title: 'Update Failed',
            message: 'Failed to update profile. Please try again.',
            actionText: 'Retry',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
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
                              ),
                              child: ClipOval(
                                child: _buildAvatarImage(_profileImageUrl),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.background,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    CustomTextField(
                      controller: _dobController,
                      hintText: 'Date of Birth (YYYY/MM/DD)',
                      prefixIcon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSizes.p16),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.r16),
                      ),
                      height: 56,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          hint: const Row(
                            children: [
                              Icon(Icons.wc_outlined, color: AppColors.textMuted, size: 20),
                              SizedBox(width: 12),
                              Text('Gender', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                            ],
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                          dropdownColor: AppColors.surfaceHighlight,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          items: ['Male', 'Female', 'Other', 'Prefer not to say']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  const Icon(Icons.wc_outlined, color: AppColors.textMuted, size: 20),
                                  const SizedBox(width: 12),
                                  Text(value),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    CustomTextField(
                      controller: _bioController,
                      hintText: 'Bio',
                      prefixIcon: Icons.edit_note_outlined,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                    ),
                    CustomTextField(
                      controller: _phoneNumberController,
                      hintText: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: AppSizes.p16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13141B),
                        borderRadius: BorderRadius.circular(AppSizes.r16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.gps_fixed, color: AppColors.primaryCyan, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      _latitude != null ? 'GRID CALIBRATED' : 'OFFLINE',
                                      style: TextStyle(
                                        color: _latitude != null ? AppColors.primaryCyan : Colors.white38,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _latitude != null
                                      ? '${_locationController.text} (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
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
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    
                    GestureDetector(
                      onTap: _showGamingPreferencesBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: AppSizes.p16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.r16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sports_esports_outlined, color: Colors.white70),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gaming Preferences',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_selectedRole • $_selectedPlaystyle • $_selectedSkillLevel',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white30),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
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
