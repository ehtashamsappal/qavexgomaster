/// Player profile: name, badges, coin balance and quick stats.
library;

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/app_themes.dart';
import '../widgets/profile_scope.dart';
import '../widgets/ui_kit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = effectiveTheme(themeById(profile.activeThemeId),
        highContrast: profile.highContrast);
    final text = theme.onBackground;
    final s = profile.stats;
    if (_nameCtrl.text.isEmpty) _nameCtrl.text = profile.playerName;

    final rows = [
      ('🎮 Games played', '${s.gamesPlayed}'),
      ('🏆 Wins', '${s.gamesWon}'),
      ('📈 Win rate', '${s.winRate.toStringAsFixed(1)}%'),
      ('🔥 Best win streak', '${s.longestWinStreak}'),
      ('📅 Best daily streak', '${s.bestDailyStreak} days'),
      ('⚔️ Stones captured', '${s.totalCaptures}'),
      ('🧩 Puzzles solved', '${s.puzzlesSolved}/8'),
      ('🪙 Coins earned', '${s.totalCoinsEarned}'),
    ];

    return QgmScaffold(
      title: 'Profile',
      theme: theme,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.accent,
                  child: Text(
                    profile.playerName.isEmpty
                        ? 'G'
                        : profile.playerName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                if (profile.stats.coffeeSupporter)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          GoTheme.bamboo.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('☕ QAVEX Supporter',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          QgmCard(
            theme: theme,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: TextStyle(color: text, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Player name',
                      labelStyle: TextStyle(
                          color:
                              text.withValues(alpha: 0.6)),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) {
                      profile.setName(_nameCtrl.text);
                      AudioService.instance.playSfx('button');
                      showQgmSnack(
                          context, theme, 'Name saved!');
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check, color: theme.accent),
                  onPressed: () {
                    profile.setName(_nameCtrl.text);
                    AudioService.instance.playSfx('button');
                    FocusScope.of(context).unfocus();
                    showQgmSnack(context, theme, 'Name saved!');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(child: CoinPill(coins: profile.coins, theme: theme)),
          SectionTitle('Lifetime stats', theme),
          QgmCard(
            theme: theme,
            child: Column(
              children: [
                for (final (label, value) in rows)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label,
                            style: TextStyle(
                                color: text.withValues(
                                    alpha: 0.75))),
                        Text(value,
                            style: TextStyle(
                                color: text,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          QgmButton(
            label: 'View Achievements',
            theme: theme,
            secondary: true,
            onPressed: () =>
                Navigator.pushNamed(context, '/stats'),
          ),
        ],
      ),
    );
  }
}
