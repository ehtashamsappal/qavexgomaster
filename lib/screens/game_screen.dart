/// The game screen: board play vs AI / pass & play / tsumego, clocks,
// scoring, hints, undo and result flow.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/game_config.dart';
import '../game/go_ai.dart';
import '../game/go_engine.dart';
import '../services/audio_service.dart';
import '../theme/app_themes.dart';
import '../widgets/go_board.dart';
import '../widgets/profile_scope.dart';
import '../widgets/ui_kit.dart';

class _Snapshot {
  final GoGame game;
  final int caps;
  final int big;
  final int lost;
  final int moves;
  _Snapshot(this.game, this.caps, this.big, this.lost, this.moves);
}

class GameScreen extends StatefulWidget {
  final GameConfig config;
  const GameScreen({super.key, required this.config});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GoGame _game;
  GoAi? _ai;
  bool _aiThinking = false;
  (int, int)? _hint;
  late int _hintsLeft;
  bool _showEstimate = false;
  final List<_Snapshot> _undoStack = [];
  Map<Stone, int> _clocks = {};
  Timer? _timer;
  bool _over = false;
  int _humanCaps = 0;
  int _humanBig = 0;
  int _humanLost = 0;
  int _moveCount = 0;

  bool get _isPuzzle =>
      widget.config.mode == GameModeId.tsumego &&
      widget.config.puzzle != null;
  bool get _usesAi => widget.config.mode.usesAi;
  Stone get _humanStone =>
      _usesAi ? widget.config.humanColor : Stone.black;
  Stone get _aiStone => opposite(widget.config.humanColor);

  @override
  void initState() {
    super.initState();
    final c = widget.config;
    if (_isPuzzle) {
      _game = c.puzzle!.toGame();
    } else {
      _game = GoGame(c.boardSize);
      if (c.handicap > 0) _game.placeHandicap(c.handicap);
    }
    if (_usesAi) _ai = GoAi.forId(c.aiId);
    if (c.timeSeconds > 0) {
      _clocks = {Stone.black: c.timeSeconds, Stone.white: c.timeSeconds};
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
    _hintsLeft = 99; // adjusted below once profile is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final kids = ProfileScope.of(context).kidsMode;
      setState(() => _hintsLeft = kids ? 99 : 3);
      AudioService.instance.startBgm('bgm_focus');
      if (_usesAi && _game.turn != c.humanColor && !_game.finished) {
        _aiMove();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer t) {
    if (_over || _game.finished) return;
    final side = _game.turn;
    final left = (_clocks[side] ?? 0) - 1;
    _clocks[side] = left;
    if (left <= 5 && left > 0) {
      AudioService.instance.playSfx('tick');
    }
    if (left <= 0) {
      _finishByTime(loser: side);
      return;
    }
    if (mounted) setState(() {});
  }

  void _pushSnapshot() {
    _undoStack.add(
        _Snapshot(_game.clone(), _humanCaps, _humanBig, _humanLost, _moveCount));
  }

  void _restore(_Snapshot s) {
    _game = s.game;
    _humanCaps = s.caps;
    _humanBig = s.big;
    _humanLost = s.lost;
    _moveCount = s.moves;
    _hint = null;
  }

  Future<void> _onTapPoint(int x, int y) async {
    if (_over || _aiThinking || _game.finished) return;
    if (_isPuzzle) {
      _puzzleMove(x, y);
      return;
    }
    if (_usesAi && _game.turn != widget.config.humanColor) return;
    final mover = _game.turn;
    final reason = _game.legality(mover, x, y);
    if (reason != null) {
      final theme = _theme();
      AudioService.instance.playSfx('error');
      HapticFeedback.lightImpact();
      showQgmSnack(context, theme, reason);
      return;
    }
    _pushSnapshot();
    final caps = _game.play(GoMove(x, y));
    _afterHumanOrAiMove(mover, caps);
    if (_game.finished) {
      _finishByScore();
      return;
    }
    if (_usesAi && _game.turn == _aiStone) _aiMove();
  }

  void _afterHumanOrAiMove(Stone mover, int caps) {
    _moveCount++;
    if (mover == _humanStone) {
      _humanCaps += caps;
      if (caps > _humanBig) _humanBig = caps;
    } else {
      _humanLost += caps;
    }
    _hint = null;
    AudioService.instance.playSfx(caps > 0 ? 'capture' : 'stone_place');
    if (caps > 0) HapticFeedback.mediumImpact();
    if (mounted) setState(() {});
  }

  Future<void> _aiMove() async {
    if (_over || _ai == null || _game.finished) return;
    setState(() => _aiThinking = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted || _over || _game.finished) {
      if (mounted) setState(() => _aiThinking = false);
      return;
    }
    final ai = _ai!;
    final mover = _game.turn;
    final move = ai.chooseMove(_game,
        timeLimit:
            Duration(milliseconds: min(ai.defaultTimeLimitMs, 2500)));
    if (!mounted || _over || _game.finished) {
      if (mounted) setState(() => _aiThinking = false);
      return;
    }
    _pushSnapshot();
    var caps = 0;
    try {
      caps = _game.play(move);
    } catch (_) {
      try {
        _game.play(const GoMove.pass());
      } catch (_) {}
    }
    _afterHumanOrAiMove(mover, caps);
    setState(() => _aiThinking = false);
    if (_game.finished) _finishByScore();
  }

  Future<void> _pass() async {
    if (_over || _aiThinking || _game.finished || _isPuzzle) return;
    if (_usesAi && _game.turn != widget.config.humanColor) return;
    final theme = _theme();
    final ok = await confirmDialog(context, theme, 'Pass?',
        'Pass your turn? Two consecutive passes end the game.',
        okLabel: 'Pass');
    if (!ok) return;
    _pushSnapshot();
    final mover = _game.turn;
    _game.play(const GoMove.pass());
    _moveCount++;
    AudioService.instance.playSfx('pass');
    setState(() {});
    if (_game.finished) {
      _finishByScore();
      return;
    }
    if (_usesAi && _game.turn == _aiStone) {
      _moverNote(mover);
      _aiMove();
    }
  }

  void _moverNote(Stone mover) {
    // placeholder for pass-and-play turn announcements (kept for clarity)
  }

  Future<void> _resign() async {
    if (_over || _game.finished || _isPuzzle) return;
    final theme = _theme();
    final ok = await confirmDialog(
        context, theme, 'Resign?', 'Resign this game?',
        okLabel: 'Resign');
    if (!ok) return;
    final side = _usesAi ? widget.config.humanColor : _game.turn;
    _game.resign(side);
    _finishByResign();
  }

  void _undo() {
    if (_over || _aiThinking || _game.finished || _isPuzzle) return;
    if (_undoStack.isEmpty) return;
    var popped = 0;
    while (_undoStack.isNotEmpty &&
        (popped == 0 || (_usesAi && _game.turn != _humanStone))) {
      _restore(_undoStack.removeLast());
      popped++;
    }
    AudioService.instance.playSfx('button');
    setState(() {});
  }

  void _showHint() {
    if (_over || _aiThinking || _game.finished || _isPuzzle) return;
    if (_usesAi && _game.turn != widget.config.humanColor) return;
    if (_hintsLeft <= 0) {
      showQgmSnack(context, _theme(), 'No hints left this game.');
      return;
    }
    final s = MediumAi()
        .chooseMove(_game, timeLimit: const Duration(milliseconds: 400));
    AudioService.instance.playSfx('button');
    if (!s.isPass) {
      setState(() {
        _hint = (s.x, s.y);
        _hintsLeft--;
      });
    }
  }

  void _puzzleMove(int x, int y) {
    final p = widget.config.puzzle!;
    final theme = _theme();
    if (p.winningMoves.contains((x, y))) {
      _game.play(GoMove(x, y));
      AudioService.instance.playSfx('capture');
      HapticFeedback.heavyImpact();
      _finishPuzzle();
    } else {
      AudioService.instance.playSfx('error');
      HapticFeedback.lightImpact();
      showQgmSnack(context, theme,
          'Not quite! Hint: ${p.hint}');
    }
    setState(() {});
  }

  Future<void> _finishPuzzle() async {
    if (_over) return;
    _over = true;
    _timer?.cancel();
    final profile = ProfileScope.of(context);
    final p = widget.config.puzzle!;
    final rewards =
        await profile.recordPuzzleSolved(p.id, p.rewardCoins);
    AudioService.instance.playSfx('win');
    if (!mounted) return;
    _showRewardsDialog(
      title: profile.kidsMode ? 'Amazing! 🎉' : 'Puzzle Solved!',
      lines: [
        'You found the vital move.',
        '🪙 +${rewards.coinsEarned} Stone Coins',
      ],
      rewards: rewards,
    );
  }

  String _modeKey() {
    final m = widget.config.mode;
    if (m == GameModeId.passPlay) return 'pass_play';
    return m.name;
  }

  Future<void> _finishByScore() async {
    if (_over) return;
    _over = true;
    _timer?.cancel();
    final s = _game.score();
    final winner = s.winner;
    await _recordAndShow(
      winner: winner,
      score: s,
      byResign: false,
      timedOut: false,
    );
  }

  Future<void> _finishByTime({required Stone loser}) async {
    if (_over) return;
    _over = true;
    _timer?.cancel();
    final winner = opposite(loser);
    AudioService.instance.playSfx('lose');
    await _recordAndShow(
      winner: winner,
      score: null,
      byResign: false,
      timedOut: true,
      timeLoser: loser,
    );
  }

  Future<void> _finishByResign() async {
    if (_over) return;
    _over = true;
    _timer?.cancel();
    await _recordAndShow(
      winner: _game.winnerByResign,
      score: null,
      byResign: true,
      timedOut: false,
    );
  }

  Future<void> _recordAndShow({
    required Stone? winner,
    required ScoreResult? score,
    required bool byResign,
    required bool timedOut,
    Stone? timeLoser,
  }) async {
    final profile = ProfileScope.of(context);
    final c = widget.config;
    final won = winner != null && winner == _humanStone;
    final result = GameResult(
      won: won,
      boardSize: c.boardSize,
      mode: _modeKey(),
      aiLevel: _usesAi ? c.aiId : null,
      capturesMade: _humanCaps,
      biggestMoveCapture: _humanBig,
      stonesLost: _humanLost,
      movesPlayed: _moveCount,
      margin: score?.margin ?? 0,
      byResign: byResign,
      handicapGiven: c.handicap > 0,
      kidsMode: profile.kidsMode,
    );
    final rewards = await profile.recordGame(result);
    AudioService.instance.playSfx(won ? 'win' : 'lose');
    if (rewards.newAchievements.isNotEmpty) {
      AudioService.instance.playSfx('achievement');
    }
    if (!mounted) return;

    final lines = <String>[];
    if (timedOut) {
      lines.add(
          '${timeLoser == Stone.black ? 'Black' : 'White'} ran out of time.');
    } else if (byResign) {
      lines.add('Won by resignation.');
    } else if (score != null) {
      lines.add(
          '⬤ Black ${score.blackScore.toStringAsFixed(1)} (stones ${score.blackStones} + territory ${score.blackTerritory})');
      lines.add(
          '⬤ White ${score.whiteScore.toStringAsFixed(1)} (stones ${score.whiteStones} + territory ${score.whiteTerritory} + komi ${score.komi})');
      lines.add('Captures — you: $_humanCaps, opponent: $_humanLost');
    }
    lines.add('🪙 +${rewards.coinsEarned} Stone Coins');

    final title = winner == null
        ? 'Jigo — Draw!'
        : won
            ? (profile.kidsMode ? 'You Win! 🎉' : 'Victory!')
            : (profile.kidsMode
                ? 'Good Game! 💪'
                : '${winner == Stone.black ? 'Black' : 'White'} Wins');
    _showRewardsDialog(title: title, lines: lines, rewards: rewards);
  }

  void _showRewardsDialog({
    required String title,
    required List<String> lines,
    required GameRewards rewards,
  }) {
    final theme = _theme();
    final text = theme.onBackground;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: theme.background,
        title: Text(title,
            style: TextStyle(
                color: text, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final l in lines)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3),
                  child: Text(l,
                      style: TextStyle(
                          color:
                              text.withValues(alpha: 0.85),
                          fontSize: 14)),
                ),
              if (rewards.newAchievements.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('🏆 Achievements unlocked:',
                    style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.bold)),
                for (final a in rewards.newAchievements)
                  Text('• ${a.title} (+${a.coins} 🪙)',
                      style: TextStyle(
                          color:
                              text.withValues(alpha: 0.85),
                          fontSize: 13)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              Navigator.pushReplacementNamed(context, '/game',
                  arguments: widget.config);
            },
            child:
                Text('Rematch', style: TextStyle(color: text)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(c);
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (_) => false);
            },
            child: const Text('Home'),
          ),
        ],
      ),
    );
  }

  GoTheme _theme() {
    final profile = ProfileScope.of(context);
    return effectiveTheme(themeById(profile.activeThemeId),
        highContrast: profile.highContrast);
  }

  String _clockLabel(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = _theme();
    final text = theme.onBackground;
    final turn = _game.turn;
    final turnLabel = _isPuzzle
        ? 'Black to play and capture'
        : _usesAi
            ? (turn == widget.config.humanColor
                ? 'Your move'
                : 'AI is thinking…')
            : '${turn == Stone.black ? 'Black' : 'White'} to play';

    return QgmScaffold(
      title: widget.config.mode.title,
      theme: theme,
      actions: [
        IconButton(
          tooltip: 'Score estimate',
          icon: Icon(
              _showEstimate ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            AudioService.instance.playSfx('button');
            setState(() => _showEstimate = !_showEstimate);
          },
        ),
        if (!_isPuzzle)
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: _undoStack.isEmpty ? null : _undo,
          ),
      ],
      body: Column(
        children: [
          // Status bar.
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: turn == Stone.black
                        ? theme.blackStone
                        : theme.whiteStone,
                    border: Border.all(
                        color: theme.onBackground
                            .withValues(alpha: 0.4)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _aiThinking ? 'AI is thinking…' : turnLabel,
                    style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
                if (_aiThinking)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2),
                  ),
                if (_clocks.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _clockChip(theme, Stone.black,
                      _clockLabel(_clocks[Stone.black] ?? 0), turn),
                  const SizedBox(width: 6),
                  _clockChip(theme, Stone.white,
                      _clockLabel(_clocks[Stone.white] ?? 0), turn),
                ],
              ],
            ),
          ),
          // Board.
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GoBoardWidget(
                  game: _game,
                  theme: theme,
                  onTapPoint: _onTapPoint,
                  hintPoint: _hint,
                  showEstimate: _showEstimate,
                  highContrast: profile.highContrast,
                ),
              ),
            ),
          ),
          // Info row.
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('⬤ ${_game.blackCaptures} captured',
                    style: TextStyle(
                        color: text.withValues(alpha: 0.75),
                        fontSize: 13)),
                const SizedBox(width: 16),
                Text('Move $_moveCount',
                    style: TextStyle(
                        color: text.withValues(alpha: 0.75),
                        fontSize: 13)),
                const SizedBox(width: 16),
                Text('⬤ ${_game.whiteCaptures} captured',
                    style: TextStyle(
                        color: text.withValues(alpha: 0.75),
                        fontSize: 13)),
              ],
            ),
          ),
          if (_isPuzzle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                widget.config.puzzle!.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: text.withValues(alpha: 0.8),
                    fontSize: 13),
              ),
            ),
          // Action buttons.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Row(
              children: [
                if (!_isPuzzle) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pass,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: text),
                      child: const Text('Pass'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _hintsLeft > 0 ? _showHint : null,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: text),
                    child: Text(profile.kidsMode
                        ? '💡 Hint'
                        : '💡 Hint ($_hintsLeft)'),
                  ),
                ),
                if (!_isPuzzle) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resign,
                      style: OutlinedButton.styleFrom(
                          foregroundColor:
                              theme.accent),
                      child: const Text('Resign'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _clockChip(
      GoTheme theme, Stone color, String label, Stone turn) {
    final active = turn == color;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? theme.accent
            : theme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${color == Stone.black ? '⬤' : '⬤'} $label',
        style: TextStyle(
          color: active ? Colors.white : theme.onBackground,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
