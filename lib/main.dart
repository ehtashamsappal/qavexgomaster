/// Qavex Go Master — entry point.
library;

import 'package:flutter/material.dart';
import 'game/game_config.dart';
import 'screens/about_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/mode_select_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/themes_screen.dart';
import 'services/audio_service.dart';
import 'theme/app_themes.dart';
import 'widgets/profile_scope.dart';
import 'widgets/ui_kit.dart';

void main() {
  runApp(const QavexGoMasterApp());
}

class QavexGoMasterApp extends StatefulWidget {
  const QavexGoMasterApp({super.key});

  @override
  State<QavexGoMasterApp> createState() => _QavexGoMasterAppState();
}

class _QavexGoMasterAppState extends State<QavexGoMasterApp> {
  final ProfileService _profile = ProfileService();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _profile.load();
    await AudioService.instance.init(
        sound: _profile.soundOn, music: _profile.musicOn);
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF26221C),
          body: Center(
            child: CircularProgressIndicator(
                color: Color(0xFFE8C87A)),
          ),
        ),
      );
    }
    return ProfileScope(
      profile: _profile,
      child: Builder(
        builder: (context) {
          final profile = ProfileScope.of(context);
          final theme = effectiveTheme(
              themeById(profile.activeThemeId),
              highContrast: profile.highContrast);
          AudioService.instance.syncSettings(
              sound: profile.soundOn, music: profile.musicOn);
          return MaterialApp(
            title: 'Qavex Go Master',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: theme.accent,
                brightness: theme.background.computeLuminance() > 0.4
                    ? Brightness.light
                    : Brightness.dark,
              ),
              scaffoldBackgroundColor: theme.background,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                    profile.largeText ? 1.25 : 1.0),
              ),
              child: child!,
            ),
            initialRoute: '/',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                      builder: (_) => const SplashScreen());
                case '/home':
                  return MaterialPageRoute(
                      builder: (_) => const HomeScreen());
                case '/modes':
                  return MaterialPageRoute(
                      builder: (_) =>
                          const ModeSelectScreen());
                case '/levels':
                  final mode =
                      settings.arguments as GameModeId;
                  return MaterialPageRoute(
                      builder: (_) =>
                          LevelSelectScreen(mode: mode));
                case '/game':
                  final config =
                      settings.arguments as GameConfig;
                  return MaterialPageRoute(
                      builder: (_) =>
                          GameScreen(config: config));
                case '/shop':
                  return MaterialPageRoute(
                      builder: (_) => const ShopScreen());
                case '/settings':
                  return MaterialPageRoute(
                      builder: (_) =>
                          const SettingsScreen());
                case '/themes':
                  return MaterialPageRoute(
                      builder: (_) => const ThemesScreen());
                case '/profile':
                  return MaterialPageRoute(
                      builder: (_) => const ProfileScreen());
                case '/stats':
                  return MaterialPageRoute(
                      builder: (_) => const StatsScreen());
                case '/howto':
                  return MaterialPageRoute(
                      builder: (_) =>
                          const HowToPlayScreen());
                case '/about':
                  return MaterialPageRoute(
                      builder: (_) => const AboutScreen());
                default:
                  return MaterialPageRoute(
                      builder: (_) => const HomeScreen());
              }
            },
          );
        },
      ),
    );
  }
}
