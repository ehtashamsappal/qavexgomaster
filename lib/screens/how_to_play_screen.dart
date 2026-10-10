/// How to Play: a 6-page illustrated rules tutorial.
library;

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/app_themes.dart';
import '../widgets/profile_scope.dart';
import '../widgets/ui_kit.dart';

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _Page {
  final String emoji;
  final String title;
  final List<String> body;
  const _Page(this.emoji, this.title, this.body);
}

const _pages = [
  _Page('🎯', 'The Goal', [
    'Go is a 4,000-year-old game of territory.',
    'Black and White take turns placing stones on the board intersections.',
    'When the game ends, the player with the most territory + stones wins.',
    'Qavex Go Master uses Chinese (area) scoring: stones on the board plus empty points you surround.',
  ]),
  _Page('⬤', 'Placing Stones', [
    'Tap any empty intersection to place a stone of your color.',
    'Black always plays first (unless handicap stones are given).',
    'Stones never move — but they can be captured and removed.',
    'Once placed, a stone stays until captured.',
  ]),
  _Page('💨', 'Liberties & Capture', [
    'Liberties are the empty points directly next to a stone.',
    'Connected stones of the same color share their liberties.',
    'Remove ALL liberties of an enemy group and it is captured — lifted off the board.',
    'Captured stones count toward your score and earn achievements!',
  ]),
  _Page('🔁', 'The Ko Rule', [
    'Without a special rule, players could capture back and forth forever.',
    'The ko rule: you may not immediately recreate the previous board position.',
    'Play somewhere else first ("ko threat"), then you may recapture.',
    'The app enforces this automatically and tells you when ko applies.',
  ]),
  _Page('🏁', 'Passing & Scoring', [
    'When you see no useful move, tap Pass.',
    'Two passes in a row end the game — then territory is counted.',
    'Empty points fully surrounded by one color are that color\u2019s territory.',
    'White gets komi (7.5 points) for moving second. With handicap stones, komi is 0.5.',
  ]),
  _Page('🎓', 'Handicap & Tips', [
    'Handicap stones let a weaker player start with extra stones — great for learning games.',
    'Corners first, then sides, then the center — that\u2019s the classic opening order.',
    'Don\u2019t fill your own eyes: groups need two separate "eyes" (inner liberties) to live.',
    'Stuck? Use the 💡 Hint button during a game.',
  ]),
];

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = effectiveTheme(themeById(profile.activeThemeId),
        highContrast: profile.highContrast);
    final text = theme.onBackground;

    return QgmScaffold(
      title: 'How to Play',
      theme: theme,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _pages.length,
              onPageChanged: (i) {
                AudioService.instance.playSfx('button');
                setState(() => _page = i);
              },
              itemBuilder: (c, i) {
                final p = _pages[i];
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                        child: Text(p.emoji,
                            style:
                                const TextStyle(fontSize: 72))),
                    const SizedBox(height: 16),
                    Text(p.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: text,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 20),
                    for (final line in p.body)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 12),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('•  ',
                                style: TextStyle(
                                    color: theme.accent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(line,
                                  style: TextStyle(
                                      color: text.withValues(
                                          alpha: 0.85),
                                      fontSize: 15,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _pages.length; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page
                        ? theme.accent
                        : text.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: QgmButton(
              label: _page == _pages.length - 1
                  ? 'Start Playing!'
                  : 'Next',
              theme: theme,
              onPressed: () {
                AudioService.instance.playSfx('button');
                if (_page == _pages.length - 1) {
                  Navigator.pushNamed(context, '/modes');
                } else {
                  _ctrl.nextPage(
                      duration:
                          const Duration(milliseconds: 300),
                      curve: Curves.easeOut);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
