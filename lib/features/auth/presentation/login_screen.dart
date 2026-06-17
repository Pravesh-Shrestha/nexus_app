import 'package:flutter/material.dart';
import 'package:nexus_app/features/auth/presentation/signup_screen.dart';
import 'package:nexus_app/features/home/presentation/main_layout.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/presentation/widgets/custom_text_field.dart';
import 'package:nexus_app/core/presentation/widgets/gradient_button.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmail(
        email: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToSignup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  Widget _buildSocialButton(String assetName, IconData fallbackIcon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceHighlight,
          border: Border.all(color: Colors.white10),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/auth/$assetName',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: Colors.white, size: 24),
          ),
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
              // Background Gradient & Top section
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Top Gradient
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.5,
                        colors: [
                          AppColors.secondaryPurple.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                  
                  Column(
                    children: [
                      const SizedBox(height: 40),
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
                        'Dive In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome back, legend',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Central Avatar/Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.iconContainer,
                          border: Border.all(color: Colors.white12, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryPurple.withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/splash/Frame.png',
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Form fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _usernameController,
                      hintText: 'Username or email',
                      prefixIcon: Icons.alternate_email,
                    ),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    
                    // Remember me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: AppColors.primaryPurple,
                                checkColor: Colors.white,
                                side: const BorderSide(color: Colors.white30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Remember me',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: AppColors.primaryCyan, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    GradientButton(
                      text: 'LOGIN',
                      isLoading: _isLoading,
                      onTap: _isLoading ? () {} : _login,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'New Member? ',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        GestureDetector(
                          onTap: _goToSignup,
                          child: const Text(
                            'Register now',
                            style: TextStyle(
                              color: AppColors.primaryPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Or continue with
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white10)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or continue with',
                            style: TextStyle(color: Colors.white30, fontSize: 12),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.white10)),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Social buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton('google.png', Icons.g_mobiledata, onTap: _isLoading ? null : _loginWithGoogle),
                        _buildSocialButton('facebook.png', Icons.facebook),
                        _buildSocialButton('apple.png', Icons.apple),
                      ],
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
