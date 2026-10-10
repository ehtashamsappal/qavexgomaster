# DESIGN BRIEF — Qavex Go Master (`qavexgomaster`)

## 1. Product vision
A beautiful, fully-offline Go (Weiqi/Baduk) game for phones. True to the
ancient game — 9×9/13×13/19×19, Chinese area scoring, ko, handicap —
wrapped in a warm, modern shell: kaya-wood signature theme, gentle
generated audio, play-earned Stone Coins, and zero ads, accounts or
tracking.

## 2. Audience
- **Newcomers**: interactive tutorial, hints, score estimator, Kids Mode.
- **Casual players**: blitz/timed modes, 4 AI levels, daily streaks.
- **Students of the game**: 8 tsumego puzzles, handicap games, 19×19.

## 3. Visual identity
- **Signature theme "Kaya Wood"**: kaya `#E8C87A` board, ink `#1A1A1A` /
  `#26221C` background, shell-white `#FAFAFA` stones, bamboo green
  `#3E8E41` (success), vermillion `#D9381E` (accent/seal).
- 7 more six-color palettes: **Midnight, Ocean, Slate, Moss, Royal,
  Mono, Sunset** — each with board/line/black-stone/white-stone/accent/
  background.
- Stones rendered with radial highlight + soft shadow (custom painter);
  boards show star points and A–T/1–19 coordinates.
- Typography: system default (DejaVu in store art), bold display titles,
  generous spacing, 14dp+ touch targets.

## 4. Audio identity
All audio synthesized from scratch (numpy), 16-bit WAV:
- **2 BGM loops**: `bgm_calm` (Am–F–C–G pads + pentatonic plucks, home),
  `bgm_focus` (soft pulse + koto-like runs, in game).
- **10 SFX**: stone_place (wooden thock), capture (deep thud+sweep),
  pass, button, win (rising arpeggio), lose (descending), coin,
  achievement (fanfare), tick (clock), error (soft buzz).
- Respects sound/music toggles; haptics on captures.

## 5. Information architecture (12 screens)
1. **Splash** — branding, boot, daily-login coin bonus.
2. **Home** — profile header, coins, streak, Play hero, 8-tile menu.
3. **Mode Select** — 7 modes (Blitz / 13×13 / 19×19 / Vs AI / Pass & Play /
   Tsumego / Timed).
4. **Level Select** — board size, AI difficulty (Easy→Expert), handicap
   0–9, color choice; or the tsumego puzzle list.
5. **Game** — board, clocks, captures, pass/hint/resign/undo, live score
   estimate, result + rewards dialog.
6. **Shop** — themes for Stone Coins; the single IAP (coffee, $0.99).
7. **Settings** — audio, haptics, Kids Mode, large text, high contrast,
   reduce motion, reset.
8. **Themes** — 8-palette gallery with mini-board previews.
9. **Profile** — name, supporter badge, lifetime stats.
10. **Stats/Achievements** — stat tiles + 56-achievement catalogue.
11. **How to Play** — 6-page tutorial (goal, placing, liberties/capture,
    ko, passing/scoring, handicap/tips).
12. **About/Privacy** — developer, contact, full privacy policy.

## 6. Game systems
- **Rules engine** (`lib/game/go_engine.dart`, pure Dart): liberties,
  captures, suicide prevention, simple ko, handicap placement, Chinese
  area scoring, estimator.
- **AI** (`lib/game/go_ai.dart`): Easy (natural random), Medium (1-ply
  greedy + blunder avoidance), Hard (2-ply + shape patterns), Expert
  (patterns + Monte Carlo-lite playouts). All time-capped.
- **Economy**: Stone Coins earned by playing (win 40/60/100 by board
  size, loss 10, puzzles 25+, daily login 15, achievement bonuses).
  Spent only on cosmetic themes. No pay-to-win.
- **Progression**: 56 achievements, lifetime stats, daily streak with
  best-streak tracking, per-board and per-AI win records.
- **IAP**: exactly one product — `qavexgomastercoffee`, $0.99,
  "Buy Me a Coffee" (consumable tip → Supporter badge + 100 coins).

## 7. Accessibility & kids
- Larger-text mode (1.25× text scaler), high-contrast board override,
  reduce-motion setting, haptics toggle, Semantics labels on the board.
- Kids Mode: friendly copy, unlimited hints, encouraging result dialogs.

## 8. Technical
- Flutter 3.47.7, Dart 3.13, SDK 36 / min 24, offline-first.
- Deps: `audioplayers` (WAV playback), `in_app_purchase` (coffee),
  `shared_preferences` (profile persistence).
- Pure-Dart game core → unit-tested with `dart test` (43 tests).
- `flutter analyze` clean; no build artifacts committed; signing via a
  unique keystore (`android/keystore/`, git-ignored with `key.properties`).

## 9. Store assets
- Launcher icon (1024), splash (1080×1920), 3 goban renders, 2 stone
  renders, feature graphic (1024×500), 8 phone screenshots — all
  generated with Pillow in `tools/make_art.py`.
- `store/`: listing, SEO/AEO/GEO, privacy policy.
