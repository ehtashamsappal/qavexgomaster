/// Board themes: 8 six-color palettes. The signature theme is Kaya Wood.
library;

import 'package:flutter/material.dart';

class GoTheme {
  final String id;
  final String name;
  final String tagline;
  final int priceCoins; // 0 = free
  final Color board;
  final Color line;
  final Color blackStone;
  final Color whiteStone;
  final Color accent;
  final Color background;

  const GoTheme({
    required this.id,
    required this.name,
    required this.tagline,
    required this.priceCoins,
    required this.board,
    required this.line,
    required this.blackStone,
    required this.whiteStone,
    required this.accent,
    required this.background,
  });

  /// Bamboo green: the shared "success" color across themes.
  static const Color bamboo = Color(0xFF3E8E41);

  /// Ink: the shared dark text color.
  static const Color ink = Color(0xFF1A1A1A);

  /// Text color chosen for contrast on the theme background.
  Color get onBackground =>
      background.computeLuminance() > 0.4 ? ink : Colors.white;

  /// Text color chosen for contrast on the board.
  Color get onBoard => board.computeLuminance() > 0.4 ? ink : Colors.white;

  /// Card/surface color derived from the background.
  Color get surface => background.computeLuminance() > 0.4
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.75)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.08);
}

const List<GoTheme> goThemes = [
  GoTheme(
    id: 'kaya',
    name: 'Kaya Wood',
    tagline: 'The signature board — warm kaya wood, ink lines, vermillion seal.',
    priceCoins: 0,
    board: Color(0xFFE8C87A), // kaya
    line: Color(0xFF4A3418), // dark wood ink
    blackStone: Color(0xFF1A1A1A), // black slate
    whiteStone: Color(0xFFFAFAFA), // shell white
    accent: Color(0xFFD9381E), // vermillion
    background: Color(0xFF26221C), // ink
  ),
  GoTheme(
    id: 'midnight',
    name: 'Midnight',
    tagline: 'A late-night study board under deep blue.',
    priceCoins: 400,
    board: Color(0xFF1E2A4A),
    line: Color(0xFF8FA3D9),
    blackStone: Color(0xFF05070D),
    whiteStone: Color(0xFFEDEFF5),
    accent: Color(0xFF7C5CFF),
    background: Color(0xFF0B0E17),
  ),
  GoTheme(
    id: 'ocean',
    name: 'Ocean',
    tagline: 'Stones dropped into still water.',
    priceCoins: 400,
    board: Color(0xFF0F6E8C),
    line: Color(0xFFDFF3F7),
    blackStone: Color(0xFF06232E),
    whiteStone: Color(0xFFF4FBFD),
    accent: Color(0xFFFFB703),
    background: Color(0xFF06232E),
  ),
  GoTheme(
    id: 'slate',
    name: 'Slate',
    tagline: 'Cool stone minimalism for focused play.',
    priceCoins: 500,
    board: Color(0xFF5B6570),
    line: Color(0xFFE8EAED),
    blackStone: Color(0xFF20262B),
    whiteStone: Color(0xFFF5F7F8),
    accent: Color(0xFFFF6B35),
    background: Color(0xFF20262B),
  ),
  GoTheme(
    id: 'moss',
    name: 'Moss',
    tagline: 'A mossy garden board, calm and earthy.',
    priceCoins: 500,
    board: Color(0xFF6B8F5E),
    line: Color(0xFF2F3D2A),
    blackStone: Color(0xFF1C241A),
    whiteStone: Color(0xFFF7FAF3),
    accent: Color(0xFFD8A93F),
    background: Color(0xFF1C241A),
  ),
  GoTheme(
    id: 'royal',
    name: 'Royal',
    tagline: 'Imperial purple for championship games.',
    priceCoins: 800,
    board: Color(0xFF4A2E83),
    line: Color(0xFFD9C8FF),
    blackStone: Color(0xFF170F2B),
    whiteStone: Color(0xFFF6F1FF),
    accent: Color(0xFFFFC42E),
    background: Color(0xFF170F2B),
  ),
  GoTheme(
    id: 'mono',
    name: 'Mono',
    tagline: 'Pure black and white. Nothing else.',
    priceCoins: 0,
    board: Color(0xFFEDEDED),
    line: Color(0xFF111111),
    blackStone: Color(0xFF111111),
    whiteStone: Color(0xFFFFFFFF),
    accent: Color(0xFF6E6E6E),
    background: Color(0xFF111111),
  ),
  GoTheme(
    id: 'sunset',
    name: 'Sunset',
    tagline: 'Warm dusk tones for evening games.',
    priceCoins: 600,
    board: Color(0xFFE98A4B),
    line: Color(0xFF4A1F14),
    blackStone: Color(0xFF2A1410),
    whiteStone: Color(0xFFFFF6EC),
    accent: Color(0xFFB81E5B),
    background: Color(0xFF2A1410),
  ),
];

GoTheme themeById(String id) =>
    goThemes.firstWhere((t) => t.id == id, orElse: () => goThemes.first);
