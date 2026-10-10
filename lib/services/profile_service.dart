/// Central player profile: Stone Coins, stats, achievements, themes,
/// settings and daily streak. Persisted with shared_preferences.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/achievements.dart';

class GameResult {
  final bool won;
  final int boardSize;
  final String mode; // blitz, quick13, quick19, vs_ai, pass_play, timed
  final String? aiLevel; // easy, medium, hard, expert
  final int capturesMade;
  final int biggestMoveCapture;
  final int stonesLost;
  final int movesPlayed;
  final double margin;
  final bool byResign;
  final bool handicapGiven;
  final bool kidsMode;

  const GameResult({
    required this.won,
    required this.boardSize,
    required this.mode,
    this.aiLevel,
    this.capturesMade = 0,
    this.biggestMoveCapture = 0,
    this.stonesLost = 0,
    this.movesPlayed = 0,
    this.margin = 0,
    this.byResign = false,
    this.handicapGiven = false,
    this.kidsMode = false,
  });
}

class GameRewards {
  final int coinsEarned;
  final List<AchievementDef> newAchievements;
  const GameRewards(this.coinsEarned, this.newAchievements);
}

class ProfileService extends ChangeNotifier {
  static const _prefsKey = 'qgm_profile_v1';

  String playerName = 'Go Player';
  int coins = 0;
  PlayerStats stats = PlayerStats();
  Set<String> ownedAchievements = {};
  Set<String> solvedPuzzles = {};
  Set<String> ownedThemes = {'kaya', 'mono'};
  String activeThemeId = 'kaya';
  String? lastPlayDate; // yyyy-MM-dd

  // Settings
  bool soundOn = true;
  bool musicOn = true;
  bool hapticsOn = true;
  bool kidsMode = false;
  bool largeText = false;
  bool highContrast = false;
  bool reduceMotion = false;

  bool _loaded = false;
  bool get loaded => _loaded;

  final List<AchievementDef> _achievements = buildAchievements();
  List<AchievementDef> get achievements => _achievements;

  int get unlockedCount => ownedAchievements.length;

  Future<void> load() async {
    try {
      final prefs = SharedPreferencesAsync();
      final raw = await prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) return;
        final j = decoded;
        playerName = (j['name'] as String?) ?? 'Go Player';
        coins = (j['coins'] as num?)?.toInt() ?? 0;
        final st = j['stats'];
        if (st is Map<String, dynamic>) stats = PlayerStats.fromJson(st);
        ownedAchievements =
            _strList(j['achievements']).toSet();
        solvedPuzzles = _strList(j['solvedPuzzles']).toSet();
        final themes = _strList(j['ownedThemes']);
        ownedThemes = themes.isEmpty ? {'kaya', 'mono'} : themes.toSet();
        activeThemeId = (j['activeTheme'] as String?) ?? 'kaya';
        lastPlayDate = j['lastPlayDate'] as String?;
        final set = j['settings'];
        if (set is Map<String, dynamic>) {
          soundOn = _b(set, 'sound', true);
          musicOn = _b(set, 'music', true);
          hapticsOn = _b(set, 'haptics', true);
          kidsMode = _b(set, 'kids', false);
          largeText = _b(set, 'largeText', false);
          highContrast = _b(set, 'highContrast', false);
          reduceMotion = _b(set, 'reduceMotion', false);
        }
      }
    } catch (_) {
      // Corrupt prefs -> start fresh.
    }
    _loaded = true;
    notifyListeners();
  }

  List<String> _strList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  bool _b(Map<String, dynamic> m, String k, bool d) =>
      m[k] is bool ? m[k] as bool : d;

  Future<void> save() async {
    try {
      final prefs = SharedPreferencesAsync();
      final j = <String, dynamic>{
        'name': playerName,
        'coins': coins,
        'stats': stats.toJson(),
        'achievements': ownedAchievements.toList(),
        'solvedPuzzles': solvedPuzzles.toList(),
        'ownedThemes': ownedThemes.toList(),
        'activeTheme': activeThemeId,
        'lastPlayDate': lastPlayDate,
        'settings': {
          'sound': soundOn,
          'music': musicOn,
          'haptics': hapticsOn,
          'kids': kidsMode,
          'largeText': largeText,
          'highContrast': highContrast,
          'reduceMotion': reduceMotion,
        },
      };
      await prefs.setString(_prefsKey, jsonEncode(j));
    } catch (_) {}
  }

  void _addCoins(int n) {
    if (n <= 0) return;
    coins += n;
    stats.totalCoinsEarned += n;
  }

  List<AchievementDef> _checkAchievements() {
    final fresh = newlyUnlocked(stats, ownedAchievements, _achievements);
    for (final a in fresh) {
      ownedAchievements.add(a.id);
      _addCoins(a.coins);
    }
    return fresh;
  }

  /// Call once per app start. Returns login coins earned (0 if already today).
  Future<int> recordDailyLogin() async {
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (lastPlayDate == key) return 0;
    final yesterday = today.subtract(const Duration(days: 1));
    final yKey =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    if (lastPlayDate == yKey) {
      stats.dailyStreak += 1;
    } else {
      stats.dailyStreak = 1;
    }
    if (stats.dailyStreak > stats.bestDailyStreak) {
      stats.bestDailyStreak = stats.dailyStreak;
    }
    lastPlayDate = key;
    _addCoins(15);
    final fresh = _checkAchievements();
    await save();
    notifyListeners();
    return 15 + fresh.fold(0, (p, a) => p + a.coins);
  }

  Future<GameRewards> recordGame(GameResult r) async {
    final s = stats;
    s.gamesPlayed++;
    if (r.won) {
      s.gamesWon++;
      s.currentWinStreak++;
      if (s.currentWinStreak > s.longestWinStreak) {
        s.longestWinStreak = s.currentWinStreak;
      }
    } else {
      s.gamesLost++;
      s.currentWinStreak = 0;
    }
    if (r.won) {
      switch (r.boardSize) {
        case 9:
          s.wins9++;
          break;
        case 13:
          s.wins13++;
          break;
        case 19:
          s.wins19++;
          break;
      }
      if (r.mode != 'pass_play' && r.aiLevel != null) {
        switch (r.aiLevel) {
          case 'easy':
            s.winsVsEasy++;
            break;
          case 'medium':
            s.winsVsMedium++;
            break;
          case 'hard':
            s.winsVsHard++;
            break;
          case 'expert':
            s.winsVsExpert++;
            break;
        }
      }
      if (r.mode == 'blitz') s.blitzWins++;
      if (r.mode == 'timed') s.timedWins++;
      if (r.handicapGiven) s.handicapWins++;
      if (r.stonesLost >= 10) s.comebackWins++;
      if (r.kidsMode) s.kidsModeWin = true;
      final m = r.margin.round();
      if (m > s.bestMargin) s.bestMargin = m;
      if (r.boardSize == 9 &&
          (s.fastestWinMoves == 0 || r.movesPlayed < s.fastestWinMoves)) {
        s.fastestWinMoves = r.movesPlayed;
      }
    }
    if (r.mode == 'pass_play') s.passPlayGames++;
    if (r.boardSize == 19) s.finished19++;
    s.totalCaptures += r.capturesMade;
    if (r.capturesMade > s.biggestCaptureGame) {
      s.biggestCaptureGame = r.capturesMade;
    }
    if (r.biggestMoveCapture > s.biggestCaptureMove) {
      s.biggestCaptureMove = r.biggestMoveCapture;
    }
    if (!s.modesPlayed.contains(r.mode)) s.modesPlayed.add(r.mode);
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 5) s.playedLateNight = true;
    if (hour >= 5 && hour < 8) s.playedEarlyMorning = true;

    var earned = 0;
    if (r.won) {
      earned = switch (r.boardSize) {
        9 => 40,
        13 => 60,
        19 => 100,
        _ => 40,
      };
      if (r.mode == 'blitz') earned += 20;
      if (r.mode == 'timed') earned += 20;
    } else {
      earned = 10;
    }
    if (r.mode == 'pass_play') earned = r.won ? 30 : 15;
    _addCoins(earned);

    final fresh = _checkAchievements();
    await save();
    notifyListeners();
    return GameRewards(earned, fresh);
  }

  Future<GameRewards> recordPuzzleSolved(
      String puzzleId, int rewardCoins) async {
    final isNew = solvedPuzzles.add(puzzleId);
    var earned = 0;
    if (isNew) {
      stats.puzzlesSolved++;
      earned = rewardCoins;
      _addCoins(earned);
    }
    final fresh = _checkAchievements();
    await save();
    notifyListeners();
    return GameRewards(earned, fresh);
  }

  Future<GameRewards> markCoffeeSupporter() async {
    stats.coffeeSupporter = true;
    _addCoins(100);
    final fresh = _checkAchievements();
    await save();
    notifyListeners();
    return GameRewards(100, fresh);
  }

  bool unlockTheme(String id, int price) {
    if (ownedThemes.contains(id)) return true;
    if (coins < price) return false;
    coins -= price;
    ownedThemes.add(id);
    stats.themesOwned = ownedThemes.length;
    _checkAchievements();
    save();
    notifyListeners();
    return true;
  }

  void setTheme(String id) {
    if (!ownedThemes.contains(id)) return;
    activeThemeId = id;
    save();
    notifyListeners();
  }

  void setName(String name) {
    playerName = name.trim().isEmpty ? 'Go Player' : name.trim();
    save();
    notifyListeners();
  }

  void updateSetting(String key, bool value) {
    switch (key) {
      case 'sound':
        soundOn = value;
        break;
      case 'music':
        musicOn = value;
        break;
      case 'haptics':
        hapticsOn = value;
        break;
      case 'kids':
        kidsMode = value;
        break;
      case 'largeText':
        largeText = value;
        break;
      case 'highContrast':
        highContrast = value;
        break;
      case 'reduceMotion':
        reduceMotion = value;
        break;
    }
    save();
    notifyListeners();
  }

  Future<void> resetProgress() async {
    coins = 0;
    stats = PlayerStats();
    ownedAchievements = {};
    solvedPuzzles = {};
    ownedThemes = {'kaya', 'mono'};
    activeThemeId = 'kaya';
    lastPlayDate = null;
    await save();
    notifyListeners();
  }
}
