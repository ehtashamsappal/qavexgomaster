/// Splash screen: branding, profile boot, daily login bonus.
library;

import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import '../widgets/profile_scope.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _loginBonus = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final profile = ProfileScope.of(context);
    final bonus = await profile.recordDailyLogin();
    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    setState(() {
      _loginBonus = bonus;
      _done = true;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeById('kaya');
    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/icon.png', width: 140, height: 140),
            const SizedBox(height: 24),
            const Text(
              'QAVEX GO MASTER',
              style: TextStyle(
                color: Color(0xFFE8C87A),
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The ancient game of Go, beautifully simple',
              style: TextStyle(
                color: theme.onBackground.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            if (!_done)
              const CircularProgressIndicator(
                  color: Color(0xFFE8C87A))
            else if (_loginBonus > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.accent),
                ),
                child: Text(
                  '🪙 +$_loginBonus daily coins',
                  style: const TextStyle(
                    color: Color(0xFFE8C87A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
