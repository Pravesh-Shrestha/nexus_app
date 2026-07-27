import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/features/home/presentation/home_screen.dart';
import 'package:nexus_app/features/profile/presentation/profile_screen.dart';
import 'package:nexus_app/features/chat/presentation/inbox_screen.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:nexus_app/features/explore/presentation/explore_screen.dart';
import 'package:nexus_app/core/presentation/widgets/shake_refresh_wrapper.dart';

class TabNavigationController {
  static final ValueNotifier<int> activeTab = ValueNotifier<int>(0);
  static final ValueNotifier<bool> exploreEventsTab = ValueNotifier<bool>(false);
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _pageController = PageController(initialPage: 0);
  final _notchBottomBarController = NotchBottomBarController(index: 0);

  int maxCount = 4;
  
  // Track keys dynamically to force tab rebuild on shake refresh
  final List<Key> _pageKeys = [
    UniqueKey(),
    UniqueKey(),
    UniqueKey(),
    UniqueKey(),
  ];

  @override
  void initState() {
    super.initState();
    TabNavigationController.activeTab.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    TabNavigationController.activeTab.removeListener(_onTabChanged);
    _pageController.dispose();
    _notchBottomBarController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final idx = TabNavigationController.activeTab.value;
    if (idx >= 0 && idx < maxCount) {
      _pageController.jumpToPage(idx);
      _notchBottomBarController.jumpTo(idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ShakeRefreshWrapper(
        onRefresh: () async {
          setState(() {
            final activeIndex = TabNavigationController.activeTab.value;
            if (activeIndex >= 0 && activeIndex < _pageKeys.length) {
              _pageKeys[activeIndex] = UniqueKey();
            }
          });
          // Wait 1.5 seconds for reconstruction and network fetch
          await Future.delayed(const Duration(milliseconds: 1500));
        },
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            HomeScreen(key: _pageKeys[0]),
            ExploreScreen(key: _pageKeys[1]),
            InboxScreen(key: _pageKeys[2]),
            ProfileScreen(key: _pageKeys[3]),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: maxCount > 0
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
                TabNavigationController.activeTab.value = index;
              },
              kIconSize: 24.0,
              kBottomRadius: 28.0,
            )
          : null,
    );
  }
}
