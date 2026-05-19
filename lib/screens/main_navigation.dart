import 'dart:ui';
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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _selectedIndex = index);
            },
            children: _screens,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding + 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withAlpha(180),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(50),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _NavIcon(
                          icon: Icons.home_rounded,
                          isSelected: _selectedIndex == 0,
                          onTap: () => _onNavTap(0),
                        ),
                        const SizedBox(width: 8),
                        _NavIcon(
                          icon: Icons.dns_rounded,
                          isSelected: _selectedIndex == 1,
                          onTap: () => _onNavTap(1),
                        ),
                        const SizedBox(width: 8),
                        // Routing shortcut removed from pill bar; use Settings -> Проксирование приложений
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          scale: isSelected ? 1.1 : 1.0,
          child: Icon(
            icon,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withAlpha(150),
            size: 26,
          ),
        ),
      ),
    );
  }
}
