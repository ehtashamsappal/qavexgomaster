/// Level select: board size, AI difficulty, handicap, color — or the
/// tsumego puzzle list when the mode is puzzles.
library;

import 'package:flutter/material.dart';
import '../game/game_config.dart';
import '../game/go_ai.dart';
import '../game/go_engine.dart';
import '../game/tsumego.dart';
import '../services/audio_service.dart';
import '../theme/app_themes.dart';
import '../widgets/profile_scope.dart';
import '../widgets/ui_kit.dart';

class LevelSelectScreen extends StatefulWidget {
  final GameModeId mode;
  const LevelSelectScreen({super.key, required this.mode});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  late int _boardSize;
  String _aiId = 'medium';
  int _handicap = 0;
  Stone _humanColor = Stone.black;

  @override
  void initState() {
    super.initState();
    _boardSize = widget.mode.defaultBoardSize;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = effectiveTheme(themeById(profile.activeThemeId),
        highContrast: profile.highContrast);
    if (widget.mode == GameModeId.tsumego) {
      return _puzzleList(theme, profile);
    }
    return QgmScaffold(
      title: widget.mode.title,
      theme: theme,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!widget.mode.fixedBoardSize) ...[
            SectionTitle('Board size', theme),
            Row(
              children: [
                for (final s in [9, 13, 19])
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('${s}x$s'),
                        selected: _boardSize == s,
                        selectedColor: theme.accent,
                        labelStyle: TextStyle(
                            color: _boardSize == s
                                ? Colors.white
                                : theme.onBackground),
                        onSelected: (_) =>
                            setState(() => _boardSize = s),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (widget.mode.usesAi) ...[
            SectionTitle('AI opponent', theme),
            for (final ai in GoAi.all())
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: QgmCard(
                  theme: theme,
                  onTap: () {
                    AudioService.instance.playSfx('button');
                    setState(() => _aiId = ai.id);
                  },
                  child: Row(
                    children: [
                      Icon(
                        _aiId == ai.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: theme.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(ai.name,
                                style: TextStyle(
                                    color: theme.onBackground,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text(ai.description,
                                style: TextStyle(
                                    color: theme.onBackground
                                        .withValues(alpha: 0.65),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SectionTitle('Your color', theme),
            Row(
              children: [
                for (final c in [Stone.black, Stone.white])
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(
                            c == Stone.black ? '⬤ Black' : '⬤ White'),
                        selected: _humanColor == c,
                        selectedColor: theme.accent,
                        labelStyle: TextStyle(
                            color: _humanColor == c
                                ? Colors.white
                                : theme.onBackground),
                        onSelected: (_) =>
                            setState(() => _humanColor = c),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          SectionTitle('Handicap stones', theme),
          QgmCard(
            theme: theme,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle,
                      color: theme.accent),
                  onPressed: _handicap > 0
                      ? () => setState(() => _handicap--)
                      : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _handicap == 0
                          ? 'Even game'
                          : '$_handicap stones',
                      style: TextStyle(
                          color: theme.onBackground,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle,
                      color: theme.accent),
                  onPressed: _handicap < 9
                      ? () => setState(() => _handicap++)
                      : null,
                ),
              ],
            ),
          ),
          if (widget.mode.defaultTimeSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '⏱ ${widget.mode.defaultTimeSeconds ~/ 60} minutes each on the clock.',
                style: TextStyle(
                    color:
                        theme.onBackground.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
          QgmButton(
            label: 'Start Game',
            theme: theme,
            onPressed: () {
              AudioService.instance.playSfx('button');
              Navigator.pushNamed(context, '/game',
                  arguments: GameConfig(
                    mode: widget.mode,
                    boardSize: _boardSize,
                    aiId: _aiId,
                    handicap: _handicap,
                    humanColor: _humanColor,
                    timeSeconds:
                        widget.mode.defaultTimeSeconds,
                  ));
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _puzzleList(GoTheme theme, ProfileService profile) {
    return QgmScaffold(
      title: 'Tsumego Puzzles',
      theme: theme,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Black to play and capture. Find the vital move!',
            style: TextStyle(
                color: theme.onBackground.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          for (final p in tsumegoPuzzles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QgmCard(
                theme: theme,
                onTap: () {
                  AudioService.instance.playSfx('button');
                  Navigator.pushNamed(context, '/game',
                      arguments: GameConfig(
                        mode: GameModeId.tsumego,
                        boardSize: p.size,
                        puzzle: p,
                      ));
                },
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.board,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: theme.line),
                      ),
                      child: Center(
                        child: Text('🧩',
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(p.title,
                                    style: TextStyle(
                                        color: theme.onBackground,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                              Text('★' * p.difficulty,
                                  style: TextStyle(
                                      color: theme.accent,
                                      fontSize: 12)),
                            ],
                          ),
                          Text(p.theme,
                              style: TextStyle(
                                  color: theme.onBackground
                                      .withValues(alpha: 0.6),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    if (profile.solvedPuzzles.contains(p.id))
                      const Text('✅', style: TextStyle(fontSize: 22))
                    else
                      Icon(Icons.chevron_right,
                          color: theme.onBackground
                              .withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
