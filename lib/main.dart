import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nuxtray/screens/main_navigation.dart';
import 'package:nuxtray/vpn_provider.dart';

void main() {
  runApp(const NuxtrayApp());
}

class NuxtrayApp extends StatelessWidget {
  const NuxtrayApp({super.key});

  static const _defaultSeedColor = Color(0xFF6750A4);

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VpnProvider(),
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          ColorScheme lightScheme;
          ColorScheme darkScheme;

          if (lightDynamic != null && darkDynamic != null) {
            lightScheme = lightDynamic.harmonized();
            darkScheme = darkDynamic.harmonized();
          } else {
            lightScheme = ColorScheme.fromSeed(
              seedColor: _defaultSeedColor,
            );
            darkScheme = ColorScheme.fromSeed(
              seedColor: _defaultSeedColor,
              brightness: Brightness.dark,
              surface: Colors.black,
              surfaceContainerLow: const Color(0xFF1A1A1A),
            );
          }

          return Consumer<VpnProvider>(
            builder: (context, vpn, _) {
              return MaterialApp(
                title: 'Nuxtray',
                themeMode: _getThemeMode(vpn.settings.themeMode),
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: lightScheme,
                  textTheme: GoogleFonts.googleSansTextTheme(),
                  scaffoldBackgroundColor: lightScheme.surface,
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: darkScheme,
                  textTheme: GoogleFonts.googleSansTextTheme(
                    ThemeData.dark().textTheme,
                  ),
                  scaffoldBackgroundColor: darkScheme.surface,
                ),
                home: const MainNavigation(),
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}

