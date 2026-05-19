import 'package:flutter/material.dart';
import 'package:nuxtray/screens/home_screen.dart';
import 'package:nuxtray/screens/server_list_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ServerListScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onNavTap,
          animationDuration: const Duration(milliseconds: 500),
          height: 72,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Главная',
            ),
            NavigationDestination(
              icon: Icon(Icons.dns_outlined),
              selectedIcon: Icon(Icons.dns_rounded),
              label: 'Серверы',
            ),
          ],
        ),
      ),
    );
  }
}
