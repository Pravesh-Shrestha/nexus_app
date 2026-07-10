import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  bool _isBiometricSupported = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    _checkBiometricsSupport();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastEmail = prefs.getString('cached_user_email') ?? '';
      if (lastEmail.isNotEmpty && mounted) {
        _usernameController.text = lastEmail;
      }
    } catch (e) {
      debugPrint('Error loading saved email: $e');
    }
  }

  Future<void> _checkBiometricsSupport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool useBiometricsSetting = prefs.getBool('use_biometrics') ?? false;
      if (!useBiometricsSetting) return;

      final isAvailable = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (isAvailable && mounted) {
        setState(() {
          _isBiometricSupported = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking biometrics support: $e');
    }
  }

  Future<void> _loginWithBiometrics() async {
    setState(() => _isLoading = true);
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint or face to authenticate and decrypt Nexus profile.',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );

      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('cached_user_email') ?? '';
        final password = prefs.getString('cached_user_password') ?? '';

        if (email.isNotEmpty && password.isNotEmpty) {
          await _authService.signInWithEmail(email: email, password: password);
          await prefs.setInt('last_biometric_verification', DateTime.now().millisecondsSinceEpoch);

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainLayout()),
            );
          }
        } else {
          final currentUser = _authService.currentUser;
          if (currentUser != null) {
            await prefs.setInt('last_biometric_verification', DateTime.now().millisecondsSinceEpoch);
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainLayout()),
              );
            }
          } else {
            throw 'No cached credentials found. Please log in with password once first.';
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric Login Error: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_email', _usernameController.text.trim());
      await prefs.setString('cached_user_password', _passwordController.text.trim());

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

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    bool dialogLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0B0C10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white10),
              ),
              title: const Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your registered email address and we will send you a secure link to reset your password.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: emailController,
                    hintText: 'Email Address',
                    prefixIcon: Icons.email_outlined,
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: dialogLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: dialogLoading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryCyan),
                                ),
                              ),
                            )
                          : GradientButton(
                              text: 'SEND LINK',
                              onTap: () async {
                                final email = emailController.text.trim();
                                if (email.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter your email'),
                                      backgroundColor: AppColors.errorRed,
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => dialogLoading = true);
                                try {
                                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password reset link sent successfully!'),
                                        backgroundColor: AppColors.successGreen,
                                      ),
                                    );
                                  }
                                } on FirebaseAuthException catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.message ?? 'An error occurred. Please try again.'),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setDialogState(() => dialogLoading = false);
                                  }
                                }
                              },
                            ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    ).then((_) => emailController.dispose());
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
                          onPressed: _showForgotPasswordDialog,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: AppColors.primaryCyan, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          child: GradientButton(
                            text: 'LOGIN',
                            isLoading: _isLoading,
                            onTap: _isLoading ? () {} : _login,
                          ),
                        ),
                        if (_isBiometricSupported) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _isLoading ? null : _loginWithBiometrics,
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF16171D),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Icon(Icons.fingerprint, color: AppColors.primaryCyan, size: 28),
                            ),
                          ),
                        ],
                      ],
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
