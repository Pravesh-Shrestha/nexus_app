import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';

class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _activeTab = 0; // 0 for Terms, 1 for Privacy

  void _switchTab(int index) {
    if (_activeTab == index) return;
    setState(() {
      _activeTab = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String body) {
    return Text(
      body,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        height: 1.6,
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
          'Legal Agreements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Custom Segmented Toggle Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchTab(0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _activeTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                color: _activeTab == 0 ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchTab(1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _activeTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: _activeTab == 1 ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // PageView to separate screens with smooth animations/swipes
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _activeTab = index;
                  });
                },
                children: [
                  // Terms & Conditions Page
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Last updated: June 22, 2026',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionBody(
                          'Welcome to Nexus! By accessing or using our mobile application, you agree to comply with and be bound by the following Terms & Conditions. Please read them carefully.',
                        ),
                        _buildSectionTitle('1. Acceptance of Terms'),
                        _buildSectionBody(
                          'By creating an account, linking profiles, or engaging in our community matchmaker features, you acknowledge that you have read, understood, and agree to these terms. If you do not agree, you must terminate use of Nexus immediately.',
                        ),
                        _buildSectionTitle('2. User Conduct & Guidelines'),
                        _buildSectionBody(
                          'Nexus is a competitive gaming community designed to help players find matches and form squads. We maintain a zero-tolerance policy towards: \n• Toxic behavior, hate speech, or harassment.\n• Cheating, hacking, or modifications that violate game developers\' terms of service.\n• Impersonating other players, Streamers, or Creators.',
                        ),
                        _buildSectionTitle('3. Account Registration & Security'),
                        _buildSectionBody(
                          'You are responsible for maintaining the confidentiality of your credentials. You agree that all registration data (Name, Date of Birth, Gender) is accurate. Nexus reserves the right to suspend accounts providing false information.',
                        ),
                        _buildSectionTitle('4. User Preferences & Setup'),
                        _buildSectionBody(
                          'When completing the "Tell Us About Yourself" setup, you grant Nexus permission to share your preferences (Role, Playstyle, Skill Level, Favorite Games) with other users to enable matchmaking. Nexus does not claim ownership of user-submitted content.',
                        ),
                        _buildSectionTitle('5. Limitation of Liability'),
                        _buildSectionBody(
                          'Nexus is provided "as is" without warranty of any kind. We are not liable for interactions between players online or offline, nor for services provided by third-party games listed in the application.',
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),

                  // Privacy Policy Page
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Last updated: June 22, 2026',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionBody(
                          'Your privacy is critical to us. This Privacy Policy details how Nexus collects, stores, uses, and shares your data when you interact with our platform.',
                        ),
                        _buildSectionTitle('1. Information We Collect'),
                        _buildSectionBody(
                          'We collect information to customize and improve your gaming squad connections: \n• Account Information: Name, Email Address, Password, Date of Birth, and Gender.\n• Profile details: Bio, Phone Number, Location, Avatar image seed.\n• Game Preferences: Playing roles, preferred playstyle, and skill level ratings.',
                        ),
                        _buildSectionTitle('2. How We Use Your Information'),
                        _buildSectionBody(
                          'Your profile is used to connect you with relevant players. \n• Matchmaking: We display your preferences (Games, Role, Playstyle) publicly to other users.\n• Security: Email and phone number details are used to verify accounts and prevent spam.\n• Customization: Location details help find local servers and community players.',
                        ),
                        _buildSectionTitle('3. Data Sharing'),
                        _buildSectionBody(
                          'We do not sell, rent, or trade your personal data to third parties. We may disclose anonymized usage statistics to game developers to improve matchmaking parameters.',
                        ),
                        _buildSectionTitle('4. Data Security'),
                        _buildSectionBody(
                          'Nexus implements industry-standard encryption protocols (SSL/TLS) for data in transit and at rest via Google Firebase servers. However, no electronic transmission over the internet can be guaranteed 100% secure.',
                        ),
                        _buildSectionTitle('5. Your Choices & Controls'),
                        _buildSectionBody(
                          'You can edit your personal details and preference settings at any time directly through the Edit Profile page. You may request account deletion by contacting support.',
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
