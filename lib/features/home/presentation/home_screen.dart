import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120), // Padding for bottom nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gamepad, color: AppColors.primaryPurple),
                        const SizedBox(width: 8),
                        Text(
                          'Nexus',
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHighlight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Greeting Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hello,User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready to RollOut !!',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Recommended Players
              _buildSectionHeader('Recommended Players', 'View More'),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                  children: [
                    _buildPlayerAvatar('Zenith', 'https://i.pravatar.cc/150?img=11', true, AppColors.primaryCyan),
                    _buildPlayerAvatar('Nova', 'https://i.pravatar.cc/150?img=12', true, AppColors.primaryPurple),
                    _buildPlayerAvatar('Pixel', 'https://i.pravatar.cc/150?img=47', false, AppColors.primaryCyan),
                    _buildPlayerAvatar('Rift', 'https://i.pravatar.cc/150?img=14', false, Colors.grey),
                    _buildPlayerAvatar('Viper', 'https://i.pravatar.cc/150?img=15', false, Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Trending Communities
              _buildSectionHeader('Trending Communities', 'Explore All'),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Column(
                  children: [
                    _buildCommunityCard(
                      'Valorant Tactics',
                      'Strategies, lineups, and...',
                      '12.4k Active',
                      'HOT',
                      AppColors.primaryCyan,
                      'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=200&auto=format&fit=crop',
                    ),
                    const SizedBox(height: 16),
                    _buildCommunityCard(
                      'Elite Setups',
                      'Showcase your battle station',
                      '8.1k Active',
                      'GLOBAL',
                      AppColors.primaryPurple,
                      'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?q=80&w=200&auto=format&fit=crop',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Upcoming Events
              _buildSectionHeader('Upcoming Events', 'View Calendar'),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.r24),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=800&auto=format&fit=crop'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.r24),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.secondaryPurple.withValues(alpha: 0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSizes.p20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(AppSizes.r16),
                              ),
                              child: const Text(
                                'LIVE IN 2H',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHighlight.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(AppSizes.r16),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Text(
                                'Valorant Champions',
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Grand Finals',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            action,
            style: const TextStyle(
              color: AppColors.primaryPurple,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatar(String name, String imageUrl, bool isOnline, Color glowColor) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.p20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: glowColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF00), // Online green
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(String title, String subtitle, String activeCount, String badge, Color badgeColor, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.r16),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(color: badgeColor, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, color: AppColors.textMuted, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          activeCount,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        borderRadius: BorderRadius.circular(AppSizes.r16),
                      ),
                      child: const Text(
                        'Join Comm',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
