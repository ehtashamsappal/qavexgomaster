/// Themes screen: preview and select from the 8 palettes.
library;

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/app_themes.dart';
import '../widgets/profile_scope.dart';
import '../widgets/ui_kit.dart';

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = effectiveTheme(themeById(profile.activeThemeId),
        highContrast: profile.highContrast);
    final text = theme.onBackground;

    return QgmScaffold(
      title: 'Board Themes',
      theme: theme,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
              child: CoinPill(coins: profile.coins, theme: theme)),
        ),
      ],
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
        children: [
          for (final t in goThemes)
            _themeCard(context, theme, profile, t, text),
        ],
      ),
    );
  }

  Widget _themeCard(BuildContext context, GoTheme theme,
      ProfileService profile, GoTheme t, Color text) {
    final owned = profile.ownedThemes.contains(t.id);
    final active = profile.activeThemeId == t.id;
    return QgmCard(
      theme: theme,
      onTap: () {
        AudioService.instance.playSfx('button');
        if (owned) {
          profile.setTheme(t.id);
        } else {
          Navigator.pushNamed(context, '/shop');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.board,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: active ? theme.accent : t.line, width: active ? 3 : 2),
              ),
              child: CustomPaint(painter: _MiniBoardPainter(t)),
            ),
          ),
          const SizedBox(height: 8),
          Text(t.name,
              style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            active
                ? '✅ Active'
                : owned
                    ? 'Tap to use'
                    : '🪙 ${t.priceCoins} — in Shop',
            style: TextStyle(
                color: active
                    ? GoTheme.bamboo
                    : text.withValues(alpha: 0.6),
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  final GoTheme t;
  _MiniBoardPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 9;
    final cell = size.width / n;
    final o = cell / 2;
    final p = Paint()
      ..color = t.line
      ..strokeWidth = 1;
    for (var i = 0; i < n; i++) {
      final c = o + i * cell;
      canvas.drawLine(Offset(o, c), Offset(size.width - o, c), p);
      canvas.drawLine(Offset(c, o), Offset(c, size.height - o), p);
    }
    void stone(int x, int y, Color c) {
      canvas.drawCircle(Offset(o + x * cell, o + y * cell),
          cell * 0.42, Paint()..color = c);
    }
    stone(2, 2, t.blackStone);
    stone(5, 3, t.whiteStone);
    stone(3, 5, t.blackStone);
    stone(6, 6, t.whiteStone);
    stone(4, 4, t.accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
