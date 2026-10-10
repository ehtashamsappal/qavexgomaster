/// Stats & achievements: lifetime numbers plus the 56-achievement grid.
library;

import 'package:flutter/material.dart';
import '../game/achievements.dart';
import '../theme/app_themes.dart';
import '../widgets/profile_scope.dart';
import '../widgets/ui_kit.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = effectiveTheme(themeById(profile.activeThemeId),
        highContrast: profile.highContrast);
    final text = theme.onBackground;
    final s = profile.stats;
    final unlocked = profile.unlockedCount;
    final total = profile.achievements.length;

    final statTiles = [
      ('🎮', '${s.gamesPlayed}', 'Games'),
      ('🏆', '${s.gamesWon}', 'Wins'),
      ('📈', '${s.winRate.toStringAsFixed(0)}%', 'Win rate'),
      ('⚔️', '${s.totalCaptures}', 'Captured'),
      ('🔥', '${s.longestWinStreak}', 'Win streak'),
      ('📅', '${s.bestDailyStreak}', 'Day streak'),
      ('🧩', '${s.puzzlesSolved}', 'Puzzles'),
      ('🪙', '${s.totalCoinsEarned}', 'Coins earned'),
      ('⬤ 9x9', '${s.wins9}', 'Wins'),
      ('⬤ 13x13', '${s.wins13}', 'Wins'),
      ('⬤ 19x19', '${s.wins19}', 'Wins'),
      ('💥', '${s.bestMargin}', 'Best margin'),
    ];

    return QgmScaffold(
      title: 'Stats & Achievements',
      theme: theme,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle('Lifetime stats', theme),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final (emoji, value, label) in statTiles)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(value,
                          style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(label,
                          style: TextStyle(
                              color: text.withValues(alpha: 0.6),
                              fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
          SectionTitle('Achievements ($unlocked/$total)', theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : unlocked / total,
                minHeight: 10,
                backgroundColor: theme.surface,
                valueColor:
                    AlwaysStoppedAnimation(theme.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final a in profile.achievements)
            _achievementTile(theme, text, a,
                profile.ownedAchievements.contains(a.id)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _achievementTile(GoTheme theme, Color text, AchievementDef a,
      bool unlocked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: QgmCard(
        theme: theme,
        child: Row(
          children: [
            Text(unlocked ? '🏆' : '🔒',
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      style: TextStyle(
                          color: unlocked
                              ? text
                              : text.withValues(alpha: 0.45),
                          fontWeight: FontWeight.bold)),
                  Text(a.description,
                      style: TextStyle(
                          color: text.withValues(alpha: 0.6),
                          fontSize: 12)),
                ],
              ),
            ),
            Text('+${a.coins} 🪙',
                style: TextStyle(
                    color: unlocked
                        ? GoTheme.bamboo
                        : text.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
