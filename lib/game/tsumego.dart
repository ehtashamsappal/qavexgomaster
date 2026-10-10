/// Tsumego (life-and-death / capturing) puzzles. Pure Dart.
library;

import 'go_engine.dart';

class TsumegoPuzzle {
  final String id;
  final String title;
  final String theme;
  final String description;
  final String hint;
  final int difficulty; // 1..3 stars
  final int size;
  final List<Pt> black;
  final List<Pt> white;
  final Stone toPlay;
  final List<Pt> winningMoves;
  final int rewardCoins;

  const TsumegoPuzzle({
    required this.id,
    required this.title,
    required this.theme,
    required this.description,
    required this.hint,
    required this.difficulty,
    required this.size,
    required this.black,
    required this.white,
    required this.toPlay,
    required this.winningMoves,
    this.rewardCoins = 25,
  });

  /// Builds the puzzle position as a playable game.
  GoGame toGame() {
    final g = GoGame(size);
    for (final (x, y) in black) {
      g.board[y][x] = Stone.black;
    }
    for (final (x, y) in white) {
      g.board[y][x] = Stone.white;
    }
    g.turn = toPlay;
    return g;
  }
}

const List<TsumegoPuzzle> tsumegoPuzzles = [
  TsumegoPuzzle(
    id: 'p1',
    title: 'First Blood',
    theme: 'Capture',
    description:
        'Two white stones are down to their last liberty. Find the move that captures them.',
    hint: 'Look for the single empty point touching the white stones.',
    difficulty: 1,
    size: 9,
    black: [(3, 4), (4, 3), (5, 3), (4, 5), (5, 5)],
    white: [(4, 4), (5, 4)],
    toPlay: Stone.black,
    winningMoves: [(6, 4)],
  ),
  TsumegoPuzzle(
    id: 'p2',
    title: 'Corner Pocket',
    theme: 'Capture',
    description:
        'White has crawled into the corner. One liberty remains — take it.',
    hint: 'The corner stones breathe through a single point.',
    difficulty: 1,
    size: 9,
    black: [(0, 1), (1, 0), (2, 2), (0, 2), (2, 0), (3, 1)],
    white: [(1, 1), (1, 2), (2, 1)],
    toPlay: Stone.black,
    winningMoves: [(1, 3)],
  ),
  TsumegoPuzzle(
    id: 'p3',
    title: 'Edge Trap',
    theme: 'Capture',
    description:
        'White is pinned against the edge of the board. Close the trap.',
    hint: 'The edge is already a wall — you only need one more stone.',
    difficulty: 1,
    size: 9,
    black: [(6, 4), (6, 5), (7, 3), (8, 4), (8, 5)],
    white: [(7, 4), (7, 5)],
    toPlay: Stone.black,
    winningMoves: [(7, 6)],
  ),
  TsumegoPuzzle(
    id: 'p4',
    title: 'The Net',
    theme: 'Capture',
    description:
        'Four white stones are caught in your net with a single hole left open.',
    hint: 'Find the hole in the net and fill it.',
    difficulty: 2,
    size: 9,
    black: [(3, 4), (3, 5), (4, 3), (5, 3), (6, 4), (6, 5), (5, 6)],
    white: [(4, 4), (4, 5), (5, 4), (5, 5)],
    toPlay: Stone.black,
    winningMoves: [(4, 6)],
  ),
  TsumegoPuzzle(
    id: 'p5',
    title: 'Cut Down',
    theme: 'Capture',
    description:
        'A three-stone white line is almost surrounded. Finish the job.',
    hint: 'One empty point below the middle stone is all that remains.',
    difficulty: 2,
    size: 9,
    black: [(2, 3), (6, 3), (3, 2), (4, 2), (5, 2), (3, 4), (5, 4)],
    white: [(3, 3), (4, 3), (5, 3)],
    toPlay: Stone.black,
    winningMoves: [(4, 4)],
  ),
  TsumegoPuzzle(
    id: 'p6',
    title: 'Bamboo Break',
    theme: 'Capture',
    description:
        'White built a bamboo-like shape, but it has exactly one liberty.',
    hint: 'Strike at the shape\u2019s only breathing point.',
    difficulty: 2,
    size: 9,
    black: [(1, 5), (5, 5), (2, 4), (4, 4), (2, 6), (4, 6), (3, 3)],
    white: [(2, 5), (3, 5), (4, 5), (3, 4)],
    toPlay: Stone.black,
    winningMoves: [(3, 6)],
  ),
  TsumegoPuzzle(
    id: 'p7',
    title: 'Surround Sound',
    theme: 'Capture',
    description:
        'Six white stones encircle the center but forgot one exit. Seal it for a big capture.',
    hint: 'The ring has a gap on its right side.',
    difficulty: 3,
    size: 9,
    black: [
      (2, 3), (2, 4), (2, 5),
      (3, 2), (4, 2), (5, 2),
      (6, 3), (6, 4), (6, 5),
      (3, 6), (4, 6), (5, 6),
      (4, 4), (5, 5),
    ],
    white: [(3, 3), (3, 4), (3, 5), (4, 3), (4, 5), (5, 4)],
    toPlay: Stone.black,
    winningMoves: [(5, 3)],
    rewardCoins: 40,
  ),
  TsumegoPuzzle(
    id: 'p8',
    title: 'The Dragon',
    theme: 'Capture',
    description:
        'An eight-stone white dragon coils around the center with a single liberty. Slay it.',
    hint: 'There is exactly one empty point touching the dragon.',
    difficulty: 3,
    size: 9,
    black: [
      (2, 3), (2, 4), (2, 5),
      (3, 2), (4, 2), (5, 2),
      (6, 3), (6, 4), (6, 5),
      (3, 6), (5, 6),
      (4, 4),
    ],
    white: [
      (3, 3), (3, 4), (3, 5),
      (4, 3), (4, 5),
      (5, 3), (5, 4), (5, 5),
    ],
    toPlay: Stone.black,
    winningMoves: [(4, 6)],
    rewardCoins: 50,
  ),
];
