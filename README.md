# Qavex Go Master

**Game ID:** `qavexgomaster` · **Package:** `com.qavex.qavexgomaster` ·
**Version:** 1.0.0+1 · **Category:** Board

The ancient game of Go (Weiqi/Baduk), beautifully simple. Fully offline,
no ads, no accounts, no tracking.

## Features

- **7 game modes**: 9×9 Blitz (5-min clock), 13×13, 19×19, custom Vs AI,
  Pass & Play, 8 Tsumego puzzles, Timed (10-min clock)
- **4 AI opponents**: Easy → Medium → Hard → Expert (pattern play +
  Monte Carlo-lite playouts, all time-capped)
- **Real rules**: liberties, captures, suicide prevention, ko rule,
  handicap stones (0–9), Chinese area scoring with komi
- **8 board themes** incl. signature Kaya Wood; Stone Coins earned by
  playing buy cosmetic themes — never pay-to-win
- **56 achievements**, lifetime stats, daily streaks
- **Kids Mode**, larger text, high-contrast board, reduce motion, haptics
- **How to Play** 6-page tutorial, live score estimator, move hints, undo
- **One IAP**: "Buy Me a Coffee" $0.99 (`qavexgomastercoffee`)
- 2 generated BGM loops + 10 synthesized SFX (numpy WAVs)

## Project layout

```
lib/
  game/            pure-Dart core (no Flutter): engine, AI, tsumego,
                   achievements, game config
  theme/           8 six-color palettes
  services/        profile (coins/stats/settings), audio, IAP
  screens/         12 screens
  widgets/         board painter, UI kit, profile scope
assets/            icon, images (goban/stone renders, splash), audio WAVs
store/             STORE_LISTING.txt, SEO_AEO_GEO.txt, PRIVACY_POLICY.txt
store_art/         feature graphic + 8 screenshots
test/              go_engine_test.dart (43 unit tests, `dart test`)
tools/             make_art.py (Pillow), make_audio.py (numpy)
android/keystore/  unique release keystore (git-ignored)
```

## Commands (allowed)

```bash
export PATH=~/sdks/flutter/bin:$PATH
flutter create --org com.qavex --project-name qavexgomaster qavexgomaster
flutter pub get
flutter analyze        # must be clean
dart test test/go_engine_test.dart   # 43 pure-Dart unit tests
```

Do **not** run `flutter build`, `./gradlew` or `flutter run` in this
environment (per project constraints).

## Regenerating assets

```bash
python3 tools/make_art.py    # Pillow: icon, splash, gobans, stones,
                             # feature graphic, 8 screenshots
python3 tools/make_audio.py   # numpy: 2 BGM + 10 SFX WAVs
```

## Signing

Unique keystore: `android/keystore/qavexgomaster.jks` (RSA-2048, 30y,
CN=muhammad ehtasham/OU=QAVEX). Passwords in
`../KEYSTORE_NOTES.txt` (chmod 600, **never commit**). `.gitignore`
covers `key.properties` and `*.jks`.

## Developer

muhammad ehtasham (QAVEX) — https://www.qavex.company/ —
games@qavex.company — +923375621550
