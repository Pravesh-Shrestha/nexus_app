import 'package:flutter/material.dart';
import 'package:nexus_app/features/auth/presentation/login_screen.dart';
import 'package:nexus_app/features/auth/presentation/profile_setup_screen.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  String? _selectedGender;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.r16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
          prefixIcon: Icon(prefixIcon, color: Colors.white30, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white30,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Section with Gradient
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.5,
                        colors: [
                          AppColors.secondaryPurple.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 30),
                      const Text(
                        'Nexus',
                        style: TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.iconContainer,
                          border: Border.all(color: Colors.white12, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryPurple.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/splash/Frame.png',
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_add_alt_1, color: Colors.white, size: 30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Already Linked?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already Linked? ',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: _goToLogin,
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Form Fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _fullNameController,
                      hintText: 'Full name',
                      prefixIcon: Icons.person_outline,
                    ),
                    _buildTextField(
                      controller: _usernameController,
                      hintText: 'Username',
                      prefixIcon: Icons.alternate_email,
                    ),
                    
                    // DOB and Gender Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppSizes.p16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSizes.r16),
                            ),
                            child: TextField(
                              controller: _dobController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'YYYY/MM/DD',
                                hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                                prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.white30, size: 18),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppSizes.p16),
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSizes.r16),
                            ),
                            height: AppSizes.buttonHeight,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender,
                                hint: const Text('Gender', style: TextStyle(color: Colors.white30, fontSize: 14)),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white30),
                                dropdownColor: AppColors.surfaceHighlight,
                                isExpanded: true,
                                style: const TextStyle(color: Colors.white),
                                items: ['Male', 'Female', 'Other', 'Prefer not to say']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
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
                        ),
                      ],
                    ),
                    
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'Email address',
                      prefixIcon: Icons.mail_outline,
                    ),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Terms
                    const Text(
                      'I agree to the Terms and Privacy Policy',
                      style: TextStyle(color: Colors.white30, fontSize: 10),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // SIGN UP Button
                    GestureDetector(
                      onTap: _signup,
                      child: Container(
                        width: double.infinity,
                        height: AppSizes.buttonHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSizes.r28),
                          gradient: AppColors.authButtonGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryCyan.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppSizes.r26),
                          ),
                          child: const Center(
                            child: Text(
                              'SIGN UP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
