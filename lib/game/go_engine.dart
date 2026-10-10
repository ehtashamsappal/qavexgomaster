/// Pure-Dart Go (Weiqi/Baduk) engine.
///
/// Implements the board, liberties, captures, suicide prevention, simple ko,
/// handicap placement, move legality, and Chinese (area) scoring. No Flutter
/// dependency so it can be unit tested with `dart test`.
library;

enum Stone { empty, black, white }

Stone opposite(Stone s) => switch (s) {
      Stone.black => Stone.white,
      Stone.white => Stone.black,
      Stone.empty => Stone.empty,
    };

/// A point on the board as an (x, y) record. x = column, y = row, 0-indexed.
typedef Pt = (int, int);

class GoMove {
  final int x;
  final int y;
  final bool isPass;

  const GoMove(this.x, this.y) : isPass = false;
  const GoMove.pass()
      : x = -1,
        y = -1,
        isPass = true;

  @override
  String toString() => isPass ? 'pass' : '($x,$y)';
}

class IllegalMoveException implements Exception {
  final String reason;
  const IllegalMoveException(this.reason);
  @override
  String toString() => 'IllegalMoveException: $reason';
}

class ScoreResult {
  final int blackStones;
  final int whiteStones;
  final int blackTerritory;
  final int whiteTerritory;
  final double komi;

  const ScoreResult({
    required this.blackStones,
    required this.whiteStones,
    required this.blackTerritory,
    required this.whiteTerritory,
    required this.komi,
  });

  double get blackScore => (blackStones + blackTerritory).toDouble();
  double get whiteScore => (whiteStones + whiteTerritory).toDouble() + komi;
  double get margin => (blackScore - whiteScore).abs();

  Stone get winner {
    if (blackScore > whiteScore) return Stone.black;
    if (whiteScore > blackScore) return Stone.white;
    return Stone.empty; // jigo (draw)
  }

  @override
  String toString() =>
      'B $blackScore (stones $blackStones + terr $blackTerritory) vs '
      'W $whiteScore (stones $whiteStones + terr $whiteTerritory + komi $komi)';
}

class GoGame {
  final int size;
  final List<List<Stone>> board;
  Stone turn = Stone.black;
  int blackCaptures = 0; // white stones captured BY black
  int whiteCaptures = 0; // black stones captured BY white
  int consecutivePasses = 0;
  bool finished = false;
  Stone? resigned; // color that resigned, if any
  int handicapStones = 0;
  double komi = 7.5;
  final List<GoMove> history = [];
  final List<String> _positions = [];

  GoGame(this.size)
      : board = List.generate(
            size, (_) => List.filled(size, Stone.empty, growable: false),
            growable: false) {
    _positions.add(_hashBoard(board));
  }

  bool onBoard(int x, int y) => x >= 0 && y >= 0 && x < size && y < size;

  List<Pt> neighborsOf(int x, int y) {
    const d = [(1, 0), (-1, 0), (0, 1), (0, -1)];
    final out = <Pt>[];
    for (final (dx, dy) in d) {
      final nx = x + dx, ny = y + dy;
      if (onBoard(nx, ny)) out.add((nx, ny));
    }
    return out;
  }

  static String _hashBoard(List<List<Stone>> b) {
    final sb = StringBuffer();
    for (final row in b) {
      for (final s in row) {
        sb.write(s == Stone.black ? 'X' : s == Stone.white ? 'O' : '.');
      }
    }
    return sb.toString();
  }

  String get positionHash => _hashBoard(board);

  static Set<Pt> _groupOn(List<List<Stone>> b, int x, int y) {
    final color = b[y][x];
    final group = <Pt>{};
    if (color == Stone.empty) return group;
    final stack = <Pt>[(x, y)];
    final n = b.length;
    while (stack.isNotEmpty) {
      final (cx, cy) = stack.removeLast();
      if (!group.add((cx, cy))) continue;
      for (final (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = cx + dx, ny = cy + dy;
        if (nx >= 0 && ny >= 0 && nx < n && ny < n && b[ny][nx] == color) {
          stack.add((nx, ny));
        }
      }
    }
    return group;
  }

  static Set<Pt> _libertiesOn(List<List<Stone>> b, Set<Pt> group) {
    final libs = <Pt>{};
    final n = b.length;
    for (final (x, y) in group) {
      for (final (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = x + dx, ny = y + dy;
        if (nx >= 0 && ny >= 0 && nx < n && ny < n && b[ny][nx] == Stone.empty) {
          libs.add((nx, ny));
        }
      }
    }
    return libs;
  }

  /// Flood-fill group on the live board.
  Set<Pt> groupAt(int x, int y) => _groupOn(board, x, y);

  /// Group flood-fill on any board matrix (public for AI use).
  static Set<Pt> groupOn(List<List<Stone>> b, int x, int y) =>
      _groupOn(b, x, y);

  /// Liberties of a group on any board matrix (public for AI use).
  static Set<Pt> libertiesOf(List<List<Stone>> b, Set<Pt> group) =>
      _libertiesOn(b, group);

  /// Liberties of the group containing (x, y) on the live board.
  Set<Pt> libertiesAt(int x, int y) => _libertiesOn(board, groupAt(x, y));

  int stoneCount(Stone color) {
    var c = 0;
    for (final row in board) {
      for (final s in row) {
        if (s == color) c++;
      }
    }
    return c;
  }

  /// Returns null when the move is legal, otherwise a human-readable reason.
  String? legality(Stone color, int x, int y) {
    if (finished) return 'The game is over.';
    if (!onBoard(x, y)) return 'That point is off the board.';
    if (board[y][x] != Stone.empty) return 'That point is already occupied.';
    // Simulate on a scratch board.
    final sim = [for (final row in board) [...row]];
    sim[y][x] = color;
    final opp = opposite(color);
    final seenRoots = <int>{};
    for (final (nx, ny) in neighborsOf(x, y)) {
      if (sim[ny][nx] == opp) {
        final g = _groupOn(sim, nx, ny);
        final root = g.first.$1 * 64 + g.first.$2;
        if (seenRoots.add(root) && _libertiesOn(sim, g).isEmpty) {
          for (final (gx, gy) in g) {
            sim[gy][gx] = Stone.empty;
          }
        }
      }
    }
    if (_libertiesOn(sim, _groupOn(sim, x, y)).isEmpty) {
      return 'Suicide move: the stone would have no liberties.';
    }
    final h = _hashBoard(sim);
    if (_positions.length >= 2 && h == _positions[_positions.length - 2]) {
      return 'Ko: play somewhere else first, then you may recapture.';
    }
    return null;
  }

  /// All legal non-pass moves for [color].
  List<GoMove> legalMoves(Stone color) {
    final moves = <GoMove>[];
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (board[y][x] == Stone.empty && legality(color, x, y) == null) {
          moves.add(GoMove(x, y));
        }
      }
    }
    return moves;
  }

  /// Plays a move for the side to move. Returns stones captured by the move.
  /// Throws [IllegalMoveException] when illegal.
  int play(GoMove m) {
    if (finished) throw const IllegalMoveException('The game is over.');
    if (m.isPass) {
      consecutivePasses++;
      history.add(m);
      _positions.add(positionHash);
      turn = opposite(turn);
      if (consecutivePasses >= 2) finished = true;
      return 0;
    }
    final reason = legality(turn, m.x, m.y);
    if (reason != null) throw IllegalMoveException(reason);
    final color = turn;
    board[m.y][m.x] = color;
    final opp = opposite(color);
    var captured = 0;
    final seenRoots = <int>{};
    for (final (nx, ny) in neighborsOf(m.x, m.y)) {
      if (board[ny][nx] == opp) {
        final g = groupAt(nx, ny);
        final root = g.first.$1 * 64 + g.first.$2;
        if (seenRoots.add(root) && libertiesAt(nx, ny).isEmpty) {
          for (final (gx, gy) in g) {
            board[gy][gx] = Stone.empty;
          }
          captured += g.length;
        }
      }
    }
    if (color == Stone.black) {
      blackCaptures += captured;
    } else {
      whiteCaptures += captured;
    }
    consecutivePasses = 0;
    history.add(m);
    _positions.add(positionHash);
    turn = opp;
    return captured;
  }

  /// [color] resigns. The opponent wins.
  void resign(Stone color) {
    finished = true;
    resigned = color;
  }

  Stone? get winnerByResign =>
      resigned == null ? null : opposite(resigned!);

  /// Standard handicap / star-point order for supported board sizes.
  static List<Pt> starPoints(int size) {
    switch (size) {
      case 19:
        return const [
          (3, 3), (15, 15), (15, 3), (3, 15), (9, 9),
          (3, 9), (15, 9), (9, 3), (9, 15),
        ];
      case 13:
        return const [
          (3, 3), (9, 9), (9, 3), (3, 9), (6, 6),
          (3, 6), (9, 6), (6, 3), (6, 9),
        ];
      default: // 9x9 and others
        return const [
          (2, 2), (6, 6), (6, 2), (2, 6), (4, 4),
          (2, 4), (6, 4), (4, 2), (4, 6),
        ];
    }
  }

  /// Places [n] handicap stones for black. White moves first afterwards.
  /// With handicap, komi drops to 0.5 (Chinese convention).
  void placeHandicap(int n) {
    if (history.isNotEmpty) {
      throw StateError('Handicap must be placed before any move.');
    }
    final pts = starPoints(size).take(n.clamp(0, 9)).toList();
    for (final (x, y) in pts) {
      board[y][x] = Stone.black;
    }
    handicapStones = pts.length;
    if (pts.isNotEmpty) {
      komi = 0.5;
      turn = Stone.white;
    }
    _positions.add(positionHash);
  }

  /// Chinese (area) scoring: stones on board + surrounded territory + komi.
  /// Empty regions touching both colors (dame/neutral) count for nobody.
  ScoreResult score() {
    var bStones = 0, wStones = 0;
    for (final row in board) {
      for (final s in row) {
        if (s == Stone.black) bStones++;
        if (s == Stone.white) wStones++;
      }
    }
    var bTerr = 0, wTerr = 0;
    final visited = List.generate(
        size, (_) => List.filled(size, false, growable: false),
        growable: false);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (board[y][x] != Stone.empty || visited[y][x]) continue;
        // Flood-fill this empty region.
        final region = <Pt>[];
        final borders = <Stone>{};
        final stack = <Pt>[(x, y)];
        while (stack.isNotEmpty) {
          final (cx, cy) = stack.removeLast();
          if (visited[cy][cx]) continue;
          visited[cy][cx] = true;
          region.add((cx, cy));
          for (final (nx, ny) in neighborsOf(cx, cy)) {
            final s = board[ny][nx];
            if (s == Stone.empty) {
              if (!visited[ny][nx]) stack.add((nx, ny));
            } else {
              borders.add(s);
            }
          }
        }
        if (borders.length == 1) {
          if (borders.first == Stone.black) {
            bTerr += region.length;
          } else {
            wTerr += region.length;
          }
        }
      }
    }
    return ScoreResult(
      blackStones: bStones,
      whiteStones: wStones,
      blackTerritory: bTerr,
      whiteTerritory: wTerr,
      komi: komi,
    );
  }

  /// Quick live estimate shown during play (same as final scoring).
  ScoreResult estimate() => score();

  GoGame clone() {
    final g = GoGame(size);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        g.board[y][x] = board[y][x];
      }
    }
    g.turn = turn;
    g.blackCaptures = blackCaptures;
    g.whiteCaptures = whiteCaptures;
    g.consecutivePasses = consecutivePasses;
    g.finished = finished;
    g.resigned = resigned;
    g.handicapStones = handicapStones;
    g.komi = komi;
    g.history.addAll(history);
    g._positions
      ..clear()
      ..addAll(_positions);
    return g;
  }
}
