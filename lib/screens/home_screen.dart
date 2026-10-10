/// Home screen: play entry, coins, streak and menu grid.
library;

import 'package:flutter/material.dart';
import '../game/game_config.dart';
import '../services/audio_service.dart';
import '../theme/app_themes.dart';
import '../widgets/profile_scope.dart';
import '../widgets/ui_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.startBgm('bgm_calm');
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = effectiveTheme(themeById(profile.activeThemeId),
        highContrast: profile.highContrast);
    final text = theme.onBackground;

    final menu = [
      (
        '🧩',
        'Puzzles',
        () => Navigator.pushNamed(context, '/levels',
            arguments: GameModeId.tsumego)
      ),
      ('🎨', 'Themes', () => Navigator.pushNamed(context, '/themes')),
      ('🛒', 'Shop', () => Navigator.pushNamed(context, '/shop')),
      ('🏆', 'Stats', () => Navigator.pushNamed(context, '/stats')),
      ('👤', 'Profile', () => Navigator.pushNamed(context, '/profile')),
      ('📖', 'How to Play', () => Navigator.pushNamed(context, '/howto')),
      ('⚙️', 'Settings', () => Navigator.pushNamed(context, '/settings')),
      ('ℹ️', 'About', () => Navigator.pushNamed(context, '/about')),
    ];

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.accent,
                  child: Text(
                    profile.playerName.isEmpty
                        ? 'G'
                        : profile.playerName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.kidsMode
                            ? 'Hi ${profile.playerName}! 👋'
                            : 'Welcome, ${profile.playerName}',
                        style: TextStyle(
                            color: text,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text('🔥 ${profile.stats.dailyStreak}-day streak',
                              style: TextStyle(
                                  color: text.withValues(alpha: 0.75),
                                  fontSize: 13)),
                          if (profile.stats.coffeeSupporter) ...[
                            const SizedBox(width: 8),
                            const Text('☕', style: TextStyle(fontSize: 13)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/shop'),
                  child: CoinPill(coins: profile.coins, theme: theme),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Hero play card.
            QgmCard(
              theme: theme,
              onTap: () => Navigator.pushNamed(context, '/modes'),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.board,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: theme.line, width: 2),
                    ),
                    child: const Center(
                        child: Text('⬤', style: TextStyle(fontSize: 40))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Play Go',
                            style: TextStyle(
                                color: text,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                          '9x9 • 13x13 • 19x19\nBlitz, AI battles & puzzles',
                          style: TextStyle(
                              color: text.withValues(alpha: 0.7),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.play_circle_fill,
                      size: 52, color: theme.accent),
                ],
              ),
            ),
            if (profile.stats.gamesPlayed > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _miniStat(theme, '${profile.stats.gamesWon}',
                      'wins'),
                  const SizedBox(width: 8),
                  _miniStat(theme,
                      '${profile.stats.winRate.toStringAsFixed(0)}%', 'win rate'),
                  const SizedBox(width: 8),
                  _miniStat(theme, '${profile.stats.puzzlesSolved}',
                      'puzzles'),
                  const SizedBox(width: 8),
                  _miniStat(theme, '${profile.unlockedCount}/56',
                      'trophies'),
                ],
              ),
            ],
            SectionTitle('Explore', theme),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final (emoji, label, go) in menu)
                  QgmCard(
                    theme: theme,
                    onTap: () {
                      AudioService.instance.playSfx('button');
                      go();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji,
                            style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 6),
                        Text(label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: text, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Offline • No ads • v1.0.0',
                style: TextStyle(
                    color: text.withValues(alpha: 0.45), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(GoTheme theme, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: theme.onBackground,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(label,
                style: TextStyle(
                    color:
                        theme.onBackground.withValues(alpha: 0.6),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
