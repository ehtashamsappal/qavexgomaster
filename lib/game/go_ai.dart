/// Go AI opponents: Easy, Medium, Hard, Expert.
///
/// All AIs are time-capped heuristic players. Expert adds shape-pattern
/// bonuses and a Monte Carlo-lite playout search. Pure Dart, no Flutter.
library;

import 'dart:math';
import 'go_engine.dart';

abstract class GoAi {
  String get id;
  String get name;
  String get description;
  int get defaultTimeLimitMs;

  GoMove chooseMove(GoGame game, {Duration? timeLimit});

  static GoAi forId(String id) => switch (id) {
        'easy' => EasyAi(),
        'medium' => MediumAi(),
        'hard' => HardAi(),
        'expert' => ExpertAi(),
        _ => MediumAi(),
      };

  static List<GoAi> all() => [EasyAi(), MediumAi(), HardAi(), ExpertAi()];
}

/// Candidate move generation shared by all AIs: empty points near stones,
/// plus star points when the board is (nearly) empty.
List<GoMove> candidateMoves(GoGame game, Stone color, {int max = 48}) {
  final size = game.size;
  final near = <Pt>{};
  var stones = 0;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      if (game.board[y][x] != Stone.empty) {
        stones++;
        for (var dy = -2; dy <= 2; dy++) {
          for (var dx = -2; dx <= 2; dx++) {
            final nx = x + dx, ny = y + dy;
            if (game.onBoard(nx, ny) && game.board[ny][nx] == Stone.empty) {
              near.add((nx, ny));
            }
          }
        }
      }
    }
  }
  if (stones < 3) {
    for (final p in GoGame.starPoints(size)) {
      if (game.board[p.$2][p.$1] == Stone.empty) near.add(p);
    }
    near.add((size ~/ 2, size ~/ 2));
  }
  final legal = <GoMove>[];
  for (final (x, y) in near) {
    if (game.legality(color, x, y) == null) legal.add(GoMove(x, y));
  }
  // Prefer points close to the last move (locality) for speed.
  if (game.history.isNotEmpty && !game.history.last.isPass) {
    final last = game.history.last;
    legal.sort((a, b) {
      final da = (a.x - last.x).abs() + (a.y - last.y).abs();
      final db = (b.x - last.x).abs() + (b.y - last.y).abs();
      return da.compareTo(db);
    });
  }
  if (legal.length > max) return legal.sublist(0, max);
  return legal;
}

/// Static evaluation from [me]'s perspective. Cheap: material, liberties,
/// capture threats and a light center bias.
double evaluatePosition(GoGame g, Stone me) {
  final opp = opposite(me);
  var score = 0.0;
  final counted = List.generate(
      g.size, (_) => List.filled(g.size, false, growable: false),
      growable: false);
  for (var y = 0; y < g.size; y++) {
    for (var x = 0; x < g.size; x++) {
      final s = g.board[y][x];
      if (s == Stone.empty || counted[y][x]) continue;
      final group = GoGame.groupOn(g.board, x, y);
      for (final (gx, gy) in group) {
        counted[gy][gx] = true;
      }
      final libs = GoGame.libertiesOf(g.board, group).length;
      final sign = s == opp ? -1.0 : 1.0;
      score += sign * group.length * 2.0;
      score += sign * libs * 0.35;
      if (libs == 1) score -= sign * 6.0; // in atari: urgent
      if (libs == 2) score -= sign * 1.5;
    }
  }
  final myCap = me == Stone.black ? g.blackCaptures : g.whiteCaptures;
  final opCap = me == Stone.black ? g.whiteCaptures : g.blackCaptures;
  score += (myCap - opCap) * 3.0;
  return score;
}

/// Pattern helpers used by Hard/Expert.
class Patterns {
  /// True when playing at (x,y) leaves the new group with exactly 1 liberty
  /// while capturing nothing (a self-atari blunder).
  static bool isSelfAtari(GoGame g, Stone color, int x, int y) {
    final sim = g.clone();
    try {
      final captured = sim.play(GoMove(x, y));
      if (captured > 0) return false;
      return sim.libertiesAt(x, y).length == 1;
    } catch (_) {
      return true;
    }
  }

  /// Number of opponent groups put into atari by playing (x, y).
  static int atariGiven(GoGame g, Stone color, int x, int y) {
    final sim = g.clone();
    try {
      sim.play(GoMove(x, y));
    } catch (_) {
      return 0;
    }
    final opp = opposite(color);
    var n = 0;
    final seen = <int>{};
    for (final (nx, ny) in sim.neighborsOf(x, y)) {
      if (sim.board[ny][nx] == opp) {
        final key = nx * 64 + ny;
        if (seen.add(key)) {
          final grp = sim.groupAt(nx, ny);
          if (sim.libertiesAt(nx, ny).length == 1) n += grp.length;
        }
      }
    }
    return n;
  }

  /// Opening bonus: star points / 3-4 points early, avoid 1st/2nd line.
  static double openingBonus(GoGame g, int x, int y) {
    if (g.history.length > 12) return 0.0;
    var b = 0.0;
    if (GoGame.starPoints(g.size).contains((x, y))) b += 1.5;
    if (x == 0 || y == 0 || x == g.size - 1 || y == g.size - 1) b -= 3.0;
    if (x == 1 || y == 1 || x == g.size - 2 || y == g.size - 2) b -= 1.0;
    final c = g.size ~/ 2;
    final distC = (x - c).abs() + (y - c).abs();
    if (distC <= 2 && g.history.length < 4) b += 1.0; // tengen-ish opening
    return b;
  }
}

class EasyAi implements GoAi {
  final Random _rng = Random();
  @override
  String get id => 'easy';
  @override
  String get name => 'Easy';
  @override
  String get description => 'Learning the ropes. Plays natural, casual moves.';
  @override
  int get defaultTimeLimitMs => 120;

  @override
  GoMove chooseMove(GoGame game, {Duration? timeLimit}) {
    final color = game.turn;
    final cands = candidateMoves(game, color, max: 60);
    if (cands.isEmpty) return const GoMove.pass();
    // Slight preference for captures when obvious.
    for (final m in cands) {
      final sim = game.clone();
      try {
        if (sim.play(m) > 0 && _rng.nextDouble() < 0.7) return m;
      } catch (_) {}
    }
    return cands[_rng.nextInt(cands.length)];
  }
}

class MediumAi implements GoAi {
  final Random _rng = Random();
  @override
  String get id => 'medium';
  @override
  String get name => 'Medium';
  @override
  String get description =>
      'A solid club player. Greedy tactics, avoids basic blunders.';
  @override
  int get defaultTimeLimitMs => 350;

  double _scoreMove(GoGame game, Stone color, GoMove m) {
    final sim = game.clone();
    int captured = 0;
    try {
      captured = sim.play(m);
    } catch (_) {
      return -1e9;
    }
    var v = evaluatePosition(sim, color);
    v += captured * 12.0;
    if (Patterns.isSelfAtari(game, color, m.x, m.y)) v -= 25.0;
    v += Patterns.atariGiven(game, color, m.x, m.y) * 4.0;
    v += Patterns.openingBonus(game, m.x, m.y);
    v += _rng.nextDouble() * 2.0;
    return v;
  }

  @override
  GoMove chooseMove(GoGame game, {Duration? timeLimit}) {
    final limit =
        timeLimit ?? Duration(milliseconds: defaultTimeLimitMs);
    final deadline = DateTime.now().add(limit);
    final color = game.turn;
    final cands = candidateMoves(game, color);
    if (cands.isEmpty) return const GoMove.pass();
    GoMove best = cands.first;
    var bestV = -1e18;
    for (final m in cands) {
      if (DateTime.now().isAfter(deadline)) break;
      final v = _scoreMove(game, color, m);
      if (v > bestV) {
        bestV = v;
        best = m;
      }
    }
    return best;
  }
}

class HardAi implements GoAi {
  final Random _rng = Random();
  @override
  String get id => 'hard';
  @override
  String get name => 'Hard';
  @override
  String get description =>
      'Tournament strength. Reads two ply deep with shape knowledge.';
  @override
  int get defaultTimeLimitMs => 800;

  double _static(GoGame game, Stone color, GoMove m) {
    final sim = game.clone();
    int captured = 0;
    try {
      captured = sim.play(m);
    } catch (_) {
      return -1e9;
    }
    var v = evaluatePosition(sim, color);
    v += captured * 12.0;
    if (Patterns.isSelfAtari(game, color, m.x, m.y)) v -= 25.0;
    v += Patterns.atariGiven(game, color, m.x, m.y) * 4.0;
    v += Patterns.openingBonus(game, m.x, m.y);
    return v;
  }

  @override
  GoMove chooseMove(GoGame game, {Duration? timeLimit}) {
    final limit =
        timeLimit ?? Duration(milliseconds: defaultTimeLimitMs);
    final deadline = DateTime.now().add(limit);
    final color = game.turn;
    final opp = opposite(color);
    final cands = candidateMoves(game, color);
    if (cands.isEmpty) return const GoMove.pass();
    // Order by static score, keep top 12 for the 2-ply search.
    final scored = <(GoMove, double)>[];
    for (final m in cands) {
      if (DateTime.now().isAfter(deadline)) break;
      scored.add((m, _static(game, color, m) + _rng.nextDouble()));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final shortlist =
        scored.take(12).map((e) => e.$1).toList(growable: false);
    GoMove best = shortlist.isNotEmpty ? shortlist.first : cands.first;
    var bestV = -1e18;
    for (final m in shortlist) {
      if (DateTime.now().isAfter(deadline)) break;
      final sim = game.clone();
      try {
        sim.play(m);
      } catch (_) {
        continue;
      }
      // Opponent's best reply (greedy).
      var reply = 1e18;
      final replies = candidateMoves(sim, opp, max: 24);
      for (final r in replies) {
        if (DateTime.now().isAfter(deadline)) break;
        final s2 = sim.clone();
        try {
          final cap = s2.play(r);
          var v = evaluatePosition(s2, color) + cap * -12.0;
          if (v < reply) reply = v;
        } catch (_) {}
      }
      if (replies.isEmpty) reply = evaluatePosition(sim, color);
      final v = reply + _rng.nextDouble() * 1.5;
      if (v > bestV) {
        bestV = v;
        best = m;
      }
    }
    return best;
  }
}

class ExpertAi implements GoAi {
  final Random _rng = Random();
  @override
  String get id => 'expert';
  @override
  String get name => 'Expert';
  @override
  String get description =>
      'Dan-level reading. Pattern play plus Monte Carlo playouts.';
  @override
  int get defaultTimeLimitMs => 1800;

  double _static(GoGame game, Stone color, GoMove m) {
    final sim = game.clone();
    int captured = 0;
    try {
      captured = sim.play(m);
    } catch (_) {
      return -1e9;
    }
    var v = evaluatePosition(sim, color);
    v += captured * 14.0;
    if (Patterns.isSelfAtari(game, color, m.x, m.y)) v -= 30.0;
    v += Patterns.atariGiven(game, color, m.x, m.y) * 5.0;
    v += Patterns.openingBonus(game, m.x, m.y);
    // Connection/shape bonus: friendly neighbors.
    var friends = 0;
    for (final (nx, ny) in game.neighborsOf(m.x, m.y)) {
      if (game.board[ny][nx] == color) friends++;
    }
    v += friends * 0.8;
    return v;
  }

  /// Random playout to the end. Returns 1.0 win / 0.5 draw / 0.0 loss for [me].
  double _playout(GoGame game, Stone me, DateTime deadline, Random rng) {
    final sim = game.clone();
    final maxMoves = sim.size * sim.size * 2;
    var moves = 0;
    while (!sim.finished && moves < maxMoves) {
      if (DateTime.now().isAfter(deadline)) break;
      final cands = candidateMoves(sim, sim.turn, max: 32);
      if (cands.isEmpty || rng.nextDouble() < 0.04) {
        sim.play(const GoMove.pass());
      } else {
        // Biased random: prefer captures.
        GoMove? pick;
        for (var i = 0; i < 4 && pick == null; i++) {
          final m = cands[rng.nextInt(cands.length)];
          final s = sim.clone();
          try {
            if (s.play(m) > 0) pick = m;
          } catch (_) {}
        }
        pick ??= cands[rng.nextInt(cands.length)];
        try {
          sim.play(pick);
        } catch (_) {
          sim.play(const GoMove.pass());
        }
      }
      moves++;
    }
    final s = sim.score();
    final mine = me == Stone.black ? s.blackScore : s.whiteScore;
    final theirs = me == Stone.black ? s.whiteScore : s.blackScore;
    if ((mine - theirs).abs() < 0.01) return 0.5;
    return mine > theirs ? 1.0 : 0.0;
  }

  @override
  GoMove chooseMove(GoGame game, {Duration? timeLimit}) {
    final limit =
        timeLimit ?? Duration(milliseconds: defaultTimeLimitMs);
    final deadline = DateTime.now().add(limit);
    final color = game.turn;
    final cands = candidateMoves(game, color);
    if (cands.isEmpty) return const GoMove.pass();
    // Static ordering first.
    final scored = <(GoMove, double)>[];
    for (final m in cands) {
      if (DateTime.now().isAfter(deadline)) break;
      scored.add((m, _static(game, color, m)));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final shortlist =
        scored.take(8).map((e) => e.$1).toList(growable: false);
    if (shortlist.isEmpty) return const GoMove.pass();
    // Monte Carlo-lite: split remaining time across the shortlist.
    final wins = List.filled(shortlist.length, 0.0);
    final visits = List.filled(shortlist.length, 0);
    var idx = 0;
    while (DateTime.now().isBefore(deadline)) {
      final i = idx % shortlist.length;
      final sim = game.clone();
      try {
        sim.play(shortlist[i]);
      } catch (_) {
        idx++;
        continue;
      }
      wins[i] += _playout(sim, color, deadline, _rng);
      visits[i]++;
      idx++;
      if (visits.every((v) => v >= 40)) break; // enough data
    }
    var bestIdx = 0;
    var bestRate = -1.0;
    for (var i = 0; i < shortlist.length; i++) {
      if (visits[i] == 0) continue;
      // UCB-lite blend: win rate plus a touch of the static prior.
      final rate = wins[i] / visits[i] + scored[i].$2 * 0.001;
      if (rate > bestRate) {
        bestRate = rate;
        bestIdx = i;
      }
    }
    return shortlist[bestIdx];
  }
}
