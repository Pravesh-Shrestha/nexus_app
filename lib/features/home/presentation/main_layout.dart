import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/features/home/presentation/home_screen.dart';
import 'package:nexus_app/features/profile/presentation/profile_screen.dart';
import 'package:nexus_app/features/chat/presentation/inbox_screen.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _pageController = PageController(initialPage: 0);
  final _notchBottomBarController = NotchBottomBarController(index: 0);

  int maxCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _notchBottomBarController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    const HomeScreen(),
    const Center(child: Text('Explore Screen', style: TextStyle(color: Colors.white))),
    const InboxScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: _pages.length <= maxCount
          ? AnimatedNotchBottomBar(
              notchBottomBarController: _notchBottomBarController,
              color: AppColors.surfaceHighlight,
              showLabel: false,
              notchColor: AppColors.primaryPurple,
              removeMargins: false,
              bottomBarWidth: 500,
              durationInMilliSeconds: 300,
              bottomBarItems: const [
                BottomBarItem(
                  inActiveItem: Icon(Icons.home_outlined, color: Colors.white30),
                  activeItem: Icon(Icons.home_filled, color: Colors.white),
                  itemLabel: 'Home',
                ),
                BottomBarItem(
                  inActiveItem: Icon(Icons.explore_outlined, color: Colors.white30),
                  activeItem: Icon(Icons.explore, color: Colors.white),
                  itemLabel: 'Explore',
                ),
                BottomBarItem(
                  inActiveItem: Icon(Icons.chat_bubble_outline, color: Colors.white30),
                  activeItem: Icon(Icons.chat_bubble, color: Colors.white),
                  itemLabel: 'Chat',
                ),
                BottomBarItem(
                  inActiveItem: Icon(Icons.person_outline, color: Colors.white30),
                  activeItem: Icon(Icons.person, color: Colors.white),
                  itemLabel: 'Profile',
                ),
              ],
              onTap: (index) {
                _pageController.jumpToPage(index);
              },
              kIconSize: 24.0,
              kBottomRadius: 28.0,
            )
          : null,
    );
  }
}
