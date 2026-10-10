/// Game mode catalogue and per-game configuration.
library;

import 'go_engine.dart';
import 'tsumego.dart';

enum GameModeId { blitz, quick13, quick19, vsAi, passPlay, tsumego, timed }

extension GameModeInfo on GameModeId {
  String get title => switch (this) {
        GameModeId.blitz => '9x9 Blitz',
        GameModeId.quick13 => '13x13 Battle',
        GameModeId.quick19 => '19x19 Classic',
        GameModeId.vsAi => 'Vs AI',
        GameModeId.passPlay => 'Pass & Play',
        GameModeId.tsumego => 'Tsumego Puzzles',
        GameModeId.timed => 'Timed',
      };

  String get subtitle => switch (this) {
        GameModeId.blitz => 'Lightning 9x9 on the clock',
        GameModeId.quick13 => 'The perfect middle ground',
        GameModeId.quick19 => 'The full-size classic',
        GameModeId.vsAi => 'Custom match vs the computer',
        GameModeId.passPlay => 'Two players, one device',
        GameModeId.tsumego => 'Solve life-and-death problems',
        GameModeId.timed => 'Every second counts',
      };

  String get icon => switch (this) {
        GameModeId.blitz => '⚡',
        GameModeId.quick13 => '◐',
        GameModeId.quick19 => '⬛',
        GameModeId.vsAi => '🤖',
        GameModeId.passPlay => '👥',
        GameModeId.tsumego => '🧩',
        GameModeId.timed => '⏱',
      };

  int get defaultBoardSize => switch (this) {
        GameModeId.blitz => 9,
        GameModeId.quick13 => 13,
        GameModeId.quick19 => 19,
        GameModeId.vsAi => 9,
        GameModeId.passPlay => 9,
        GameModeId.tsumego => 9,
        GameModeId.timed => 13,
      };

  int get defaultTimeSeconds => switch (this) {
        GameModeId.blitz => 300,
        GameModeId.timed => 600,
        _ => 0,
      };

  bool get usesAi =>
      this != GameModeId.passPlay && this != GameModeId.tsumego;

  bool get fixedBoardSize =>
      this == GameModeId.blitz ||
      this == GameModeId.quick13 ||
      this == GameModeId.quick19;
}

class GameConfig {
  final GameModeId mode;
  final int boardSize;
  final String aiId;
  final int handicap;
  final Stone humanColor;
  final int timeSeconds;
  final TsumegoPuzzle? puzzle;

  const GameConfig({
    required this.mode,
    required this.boardSize,
    this.aiId = 'medium',
    this.handicap = 0,
    this.humanColor = Stone.black,
    this.timeSeconds = 0,
    this.puzzle,
  });

  Stone get aiColor => opposite(humanColor);
}
