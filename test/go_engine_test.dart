/// Unit tests for the pure-Dart Go engine, AI, tsumego and achievements.
/// Run with: dart test
library;

import 'package:test/test.dart';
import 'package:qavexgomaster/game/go_engine.dart';
import 'package:qavexgomaster/game/go_ai.dart';
import 'package:qavexgomaster/game/tsumego.dart';
import 'package:qavexgomaster/game/achievements.dart';

void main() {
  group('liberties', () {
    test('center stone has 4 liberties', () {
      final g = GoGame(9);
      g.board[4][4] = Stone.black;
      expect(g.libertiesAt(4, 4).length, 4);
    });
    test('corner stone has 2 liberties', () {
      final g = GoGame(9);
      g.board[0][0] = Stone.black;
      expect(g.libertiesAt(0, 0).length, 2);
    });
    test('edge stone has 3 liberties', () {
      final g = GoGame(9);
      g.board[0][4] = Stone.black;
      expect(g.libertiesAt(4, 0).length, 3);
    });
    test('connected group shares liberties', () {
      final g = GoGame(9);
      g.board[4][4] = Stone.black;
      g.board[4][5] = Stone.black;
      expect(g.groupAt(4, 4).length, 2);
      expect(g.libertiesAt(4, 4).length, 6);
    });
  });

  group('captures', () {
    test('surrounding captures a single stone', () {
      final g = GoGame(9);
      // White stone at (4,4); black surrounds on 3 sides.
      g.board[4][4] = Stone.white;
      g.board[4][3] = Stone.black;
      g.board[3][4] = Stone.black;
      g.board[4][5] = Stone.black;
      g.turn = Stone.black;
      final captured = g.play(const GoMove(4, 5));
      expect(captured, 1);
      expect(g.board[4][4], Stone.empty);
      expect(g.blackCaptures, 1);
    });

    test('multi-stone group capture', () {
      final g = GoGame(9);
      g.board[4][4] = Stone.white;
      g.board[4][5] = Stone.white;
      g.board[4][3] = Stone.black;
      g.board[3][4] = Stone.black;
      g.board[3][5] = Stone.black;
      g.board[5][4] = Stone.black;
      g.board[5][5] = Stone.black;
      g.turn = Stone.black;
      final captured = g.play(const GoMove(6, 4));
      expect(captured, 2);
      expect(g.blackCaptures, 2);
    });

    test('suicide move is illegal', () {
      final g = GoGame(9);
      g.board[0][1] = Stone.black;
      g.board[1][0] = Stone.black;
      g.turn = Stone.white;
      expect(g.legality(Stone.white, 0, 0), isNotNull);
      expect(
        () => g.play(const GoMove(0, 0)),
        throwsA(isA<IllegalMoveException>()),
      );
    });

    test('occupied point is illegal', () {
      final g = GoGame(9);
      g.turn = Stone.black;
      g.play(const GoMove(3, 3));
      expect(g.legality(Stone.white, 3, 3), isNotNull);
    });
  });

  group('ko rule', () {
    // Builds the classic ko shape through legal play so the ko history
    // is realistic. After setup it is black to move.
    GoGame koPosition() {
      final g = GoGame(9);
      final seq = [
        const GoMove(0, 1), // B
        const GoMove(2, 2), // W
        const GoMove(1, 0), // B
        const GoMove(3, 1), // W
        const GoMove(1, 2), // B
        const GoMove(2, 0), // W
        const GoMove(8, 8), // B (tempo)
        const GoMove(1, 1), // W: single liberty at (2,1)
      ];
      for (final m in seq) {
        g.play(m);
      }
      return g;
    }

    test('ko recapture is illegal immediately', () {
      final g = koPosition();
      final captured = g.play(const GoMove(2, 1));
      expect(captured, 1);
      // White to move: recapturing at (1,1) repeats the position -> ko.
      expect(g.legality(Stone.white, 1, 1), isNotNull);
    });

    test('ko can be resolved after a ko threat elsewhere', () {
      final g = koPosition();
      g.play(const GoMove(2, 1)); // black captures
      g.play(const GoMove(0, 8)); // white ko threat elsewhere
      g.play(const GoMove(1, 8)); // black answers
      // Now white may recapture.
      expect(g.legality(Stone.white, 1, 1), isNull);
    });
  });

  group('handicap', () {
    test('handicap places stones and gives white the move', () {
      final g = GoGame(9);
      g.placeHandicap(4);
      expect(g.stoneCount(Stone.black), 4);
      expect(g.turn, Stone.white);
      expect(g.handicapStones, 4);
      expect(g.komi, 0.5);
    });

    test('star points exist for all sizes', () {
      expect(GoGame.starPoints(9).length, 9);
      expect(GoGame.starPoints(13).length, 9);
      expect(GoGame.starPoints(19).length, 9);
    });
  });

  group('scoring (Chinese area)', () {
    test('empty board: only komi', () {
      final g = GoGame(9);
      final s = g.score();
      expect(s.blackScore, 0);
      expect(s.whiteScore, 7.5);
      expect(s.winner, Stone.white);
    });

    test('enclosed territory counts', () {
      final g = GoGame(3);
      // Black ring around the center point.
      for (final (x, y) in [
        (0, 0), (1, 0), (2, 0),
        (0, 1), (2, 1),
        (0, 2), (1, 2), (2, 2),
      ]) {
        g.board[y][x] = Stone.black;
      }
      final s = g.score();
      expect(s.blackStones, 8);
      expect(s.blackTerritory, 1);
      expect(s.blackScore, 9);
      expect(s.winner, Stone.black);
      expect(s.margin, 1.5);
    });

    test('neutral dame counts for nobody', () {
      final g = GoGame(3);
      g.board[0][0] = Stone.black;
      g.board[2][2] = Stone.white;
      final s = g.score();
      // The big empty region touches both colors -> neutral.
      expect(s.blackTerritory, 0);
      expect(s.whiteTerritory, 0);
    });
  });

  group('game flow', () {
    test('two passes end the game', () {
      final g = GoGame(9);
      g.play(const GoMove.pass());
      expect(g.finished, isFalse);
      g.play(const GoMove.pass());
      expect(g.finished, isTrue);
    });

    test('resign declares the opponent winner', () {
      final g = GoGame(9);
      g.resign(Stone.black);
      expect(g.finished, isTrue);
      expect(g.winnerByResign, Stone.white);
    });

    test('all first moves on empty board are legal', () {
      final g = GoGame(9);
      expect(g.legalMoves(Stone.black).length, 81);
    });

    test('clone is independent', () {
      final g = GoGame(9);
      g.play(const GoMove(3, 3));
      final c = g.clone();
      c.play(const GoMove(4, 4));
      expect(g.board[4][4], Stone.empty);
      expect(c.board[4][4], Stone.white);
    });

    test('turn alternates', () {
      final g = GoGame(9);
      expect(g.turn, Stone.black);
      g.play(const GoMove(3, 3));
      expect(g.turn, Stone.white);
    });
  });

  group('AI', () {
    for (final ai in GoAi.all()) {
      test('${ai.name} returns a legal move quickly', () {
        final g = GoGame(9);
        final move = ai.chooseMove(g,
            timeLimit: Duration(
                milliseconds: ai.id == 'expert' ? 400 : 200));
        if (!move.isPass) {
          expect(g.legality(g.turn, move.x, move.y), isNull,
              reason: '${ai.name} played illegally at $move');
        }
      });

      test('${ai.name} captures when obvious', () {
        final g = GoGame(9);
        g.board[4][4] = Stone.white;
        g.board[4][3] = Stone.black;
        g.board[3][4] = Stone.black;
        g.board[5][4] = Stone.black;
        g.turn = Stone.black;
        final move = ai.chooseMove(g,
            timeLimit: Duration(
                milliseconds: ai.id == 'expert' ? 500 : 300));
        // Not strictly required for Easy, but must be legal regardless.
        if (!move.isPass) {
          expect(g.legality(Stone.black, move.x, move.y), isNull);
        }
      });
    }

    test('Medium takes the obvious capture', () {
      final g = GoGame(9);
      g.board[4][4] = Stone.white;
      g.board[4][3] = Stone.black;
      g.board[3][4] = Stone.black;
      g.board[5][4] = Stone.black;
      g.turn = Stone.black;
      final move = MediumAi().chooseMove(g);
      expect((move.x, move.y), (5, 4));
    });

    test('AI passes when no legal moves exist', () {
      final g = GoGame(3);
      // Fill the board with an alternating pattern; only passes remain.
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          g.board[y][x] = (x + y).isEven ? Stone.black : Stone.white;
        }
      }
      final move = EasyAi().chooseMove(g);
      expect(move.isPass, isTrue);
    });
  });

  group('tsumego', () {
    test('8 puzzles defined', () {
      expect(tsumegoPuzzles.length, 8);
    });

    for (final p in tsumegoPuzzles) {
      test('${p.id} ${p.title}: winning move is legal and captures', () {
        final g = p.toGame();
        final (wx, wy) = p.winningMoves.first;
        expect(g.legality(p.toPlay, wx, wy), isNull,
            reason: 'winning move illegal in ${p.id}');
        final captured = g.play(GoMove(wx, wy));
        expect(captured, greaterThan(0),
            reason: 'winning move captures nothing in ${p.id}');
      });
    }
  });

  group('achievements', () {
    test('catalogue has 56 achievements', () {
      expect(buildAchievements().length, 56);
    });

    test('ids are unique', () {
      final ids = buildAchievements().map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('newlyUnlocked detects fresh unlocks', () {
      final all = buildAchievements();
      final s = PlayerStats()
        ..gamesPlayed = 1
        ..gamesWon = 1
        ..totalCaptures = 1;
      final fresh = newlyUnlocked(s, {}, all);
      final ids = fresh.map((a) => a.id).toSet();
      expect(ids, containsAll(['first_steps', 'first_win', 'first_blood']));
      // Already-owned ones are not reported again.
      final again = newlyUnlocked(s, ids, all);
      expect(again, isEmpty);
    });

    test('stats JSON round-trips', () {
      final s = PlayerStats()
        ..gamesWon = 7
        ..dailyStreak = 4
        ..modesPlayed = ['blitz', 'tsumego']
        ..coffeeSupporter = true;
      final back = PlayerStats.fromJson(s.toJson());
      expect(back.gamesWon, 7);
      expect(back.dailyStreak, 4);
      expect(back.modesPlayed, ['blitz', 'tsumego']);
      expect(back.coffeeSupporter, isTrue);
    });
  });
}
