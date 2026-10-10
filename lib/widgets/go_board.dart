/// The Go board widget: custom-painted goban, stones, markers and tap input.
library;

import 'package:flutter/material.dart';
import '../game/go_engine.dart';
import '../theme/app_themes.dart';

class GoBoardWidget extends StatelessWidget {
  final GoGame game;
  final GoTheme theme;
  final void Function(int x, int y) onTapPoint;
  final (int, int)? hintPoint;
  final bool showCoordinates;
  final bool showEstimate;
  final bool highContrast;

  const GoBoardWidget({
    super.key,
    required this.game,
    required this.theme,
    required this.onTapPoint,
    this.hintPoint,
    this.showCoordinates = true,
    this.showEstimate = false,
    this.highContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        return SizedBox(
          width: side,
          height: side,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final cell = side / game.size;
              final x = (d.localPosition.dx / cell).floor();
              final y = (d.localPosition.dy / cell).floor();
              if (game.onBoard(x, y)) onTapPoint(x, y);
            },
            child: Semantics(
              label:
                  'Go board, ${game.size} by ${game.size}. ${game.turn == Stone.black ? 'Black' : 'White'} to play.',
              child: CustomPaint(
                painter: _GoBoardPainter(
                  game: game,
                  theme: theme,
                  hintPoint: hintPoint,
                  showCoordinates: showCoordinates,
                  showEstimate: showEstimate,
                  highContrast: highContrast,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GoBoardPainter extends CustomPainter {
  final GoGame game;
  final GoTheme theme;
  final (int, int)? hintPoint;
  final bool showCoordinates;
  final bool showEstimate;
  final bool highContrast;

  _GoBoardPainter({
    required this.game,
    required this.theme,
    required this.hintPoint,
    required this.showCoordinates,
    required this.showEstimate,
    required this.highContrast,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = game.size;
    final cell = size.width / n;
    final board = theme.board;
    final line = highContrast ? Colors.black : theme.line;

    // Board background with subtle border.
    final bgPaint = Paint()..color = board;
    canvas.drawRect(Offset.zero & size, bgPaint);
    final borderPaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(Offset.zero & size, borderPaint);

    // Grid lines (centers of cells).
    final gridPaint = Paint()
      ..color = line
      ..strokeWidth = (cell * 0.035).clamp(1.0, 2.5);
    final o = cell / 2;
    for (var i = 0; i < n; i++) {
      final p = o + i * cell;
      canvas.drawLine(Offset(o, p), Offset(size.width - o, p), gridPaint);
      canvas.drawLine(Offset(p, o), Offset(p, size.height - o), gridPaint);
    }

    // Star points.
    final starPaint = Paint()..color = line;
    for (final (x, y) in GoGame.starPoints(n)) {
      canvas.drawCircle(
          Offset(o + x * cell, o + y * cell), (cell * 0.09).clamp(2.0, 6.0), starPaint);
    }

    // Coordinates.
    if (showCoordinates && cell > 22) {
      const letters = 'ABCDEFGHJKLMNOPQRST';
      final tp = TextPainter(textDirection: TextDirection.ltr);
      for (var i = 0; i < n; i++) {
        tp.text = TextSpan(
          text: letters[i],
          style: TextStyle(
              color: theme.onBoard.withValues(alpha: 0.75),
              fontSize: cell * 0.28),
        );
        tp.layout();
        tp.paint(
            canvas,
            Offset(o + i * cell - tp.width / 2,
                size.height - cell * 0.32 - tp.height / 2));
        tp.text = TextSpan(
          text: '${n - i}',
          style: TextStyle(
              color: theme.onBoard.withValues(alpha: 0.75),
              fontSize: cell * 0.28),
        );
        tp.layout();
        tp.paint(
            canvas, Offset(cell * 0.32 - tp.width / 2, o + i * cell - tp.height / 2));
      }
    }

    // Territory estimate overlay (cheap local heuristic: an empty point
    // ringed only by one color is likely that color's territory).
    if (showEstimate) {
      final estPaint = Paint();
      for (var y = 0; y < n; y++) {
        for (var x = 0; x < n; x++) {
          if (game.board[y][x] != Stone.empty) continue;
          // Attribute via a scratch score of single-point regions is
          // expensive; use a cheap local heuristic instead.
          final counts = _borderColors(x, y);
          if (counts[Stone.black]! > 0 && counts[Stone.white] == 0) {
            estPaint.color = theme.blackStone.withValues(alpha: 0.35);
          } else if (counts[Stone.white]! > 0 && counts[Stone.black] == 0) {
            estPaint.color = theme.whiteStone.withValues(alpha: 0.45);
          } else {
            continue;
          }
          final c = Offset(o + x * cell, o + y * cell);
          canvas.drawRect(
              Rect.fromCenter(center: c, width: cell * 0.22, height: cell * 0.22),
              estPaint);
        }
      }
    }

    // Stones.
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final st = game.board[y][x];
        if (st == Stone.empty) continue;
        _drawStone(canvas, Offset(o + x * cell, o + y * cell), cell * 0.46,
            st == Stone.black ? theme.blackStone : theme.whiteStone);
      }
    }

    // Hint marker.
    if (hintPoint != null) {
      final (hx, hy) = hintPoint!;
      final c = Offset(o + hx * cell, o + hy * cell);
      final p = Paint()
        ..color = theme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(c, cell * 0.42, p);
    }

    // Last-move marker.
    if (game.history.isNotEmpty && !game.history.last.isPass) {
      final last = game.history.last;
      final c = Offset(o + last.x * cell, o + last.y * cell);
      final p = Paint()
        ..color = game.board[last.y][last.x] == Stone.black
            ? theme.whiteStone
            : theme.blackStone
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      final r = cell * 0.18;
      canvas.drawLine(c + Offset(-r, 0), c + Offset(r, 0), p);
      canvas.drawLine(c + Offset(0, -r), c + Offset(0, r), p);
    }
  }

  Map<Stone, int> _borderColors(int x, int y) {
    final m = {Stone.black: 0, Stone.white: 0};
    const d = [(1, 0), (-1, 0), (0, 1), (0, -1)];
    for (final (dx, dy) in d) {
      final nx = x + dx, ny = y + dy;
      if (game.onBoard(nx, ny)) {
        final s = game.board[ny][nx];
        if (s != Stone.empty) m[s] = m[s]! + 1;
      }
    }
    return m;
  }

  void _drawStone(Canvas canvas, Offset c, double r, Color color) {
    // Soft shadow.
    canvas.drawCircle(
        c + Offset(r * 0.08, r * 0.12),
        r,
        Paint()..color = Colors.black.withValues(alpha: 0.28));
    // Body with radial highlight.
    final shader = RadialGradient(
      center: const Alignment(-0.35, -0.4),
      radius: 1.1,
      colors: [
        Color.lerp(color, Colors.white, 0.35)!,
        color,
        Color.lerp(color, Colors.black, 0.35)!,
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, Paint()..shader = shader);
    // Rim.
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _GoBoardPainter old) =>
      old.game != game ||
      old.hintPoint != hintPoint ||
      old.showEstimate != showEstimate ||
      old.theme != theme;
}
