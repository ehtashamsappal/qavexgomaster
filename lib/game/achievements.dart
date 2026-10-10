/// Player statistics and the 56-achievement catalogue. Pure Dart.
library;

class PlayerStats {
  int gamesPlayed = 0;
  int gamesWon = 0;
  int gamesLost = 0;
  int wins9 = 0;
  int wins13 = 0;
  int wins19 = 0;
  int winsVsEasy = 0;
  int winsVsMedium = 0;
  int winsVsHard = 0;
  int winsVsExpert = 0;
  int totalCaptures = 0;
  int biggestCaptureGame = 0;
  int biggestCaptureMove = 0;
  int currentWinStreak = 0;
  int longestWinStreak = 0;
  int dailyStreak = 0;
  int bestDailyStreak = 0;
  int puzzlesSolved = 0;
  int totalCoinsEarned = 0;
  int blitzWins = 0;
  int timedWins = 0;
  int passPlayGames = 0;
  int handicapWins = 0;
  int bestMargin = 0;
  int fastestWinMoves = 0; // 0 = none yet
  int comebackWins = 0;
  int finished19 = 0;
  int themesOwned = 1;
  bool coffeeSupporter = false;
  bool kidsModeWin = false;
  bool playedLateNight = false;
  bool playedEarlyMorning = false;
  List<String> modesPlayed = [];

  double get winRate =>
      gamesPlayed == 0 ? 0.0 : gamesWon / gamesPlayed * 100.0;

  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'gamesLost': gamesLost,
        'wins9': wins9,
        'wins13': wins13,
        'wins19': wins19,
        'winsVsEasy': winsVsEasy,
        'winsVsMedium': winsVsMedium,
        'winsVsHard': winsVsHard,
        'winsVsExpert': winsVsExpert,
        'totalCaptures': totalCaptures,
        'biggestCaptureGame': biggestCaptureGame,
        'biggestCaptureMove': biggestCaptureMove,
        'currentWinStreak': currentWinStreak,
        'longestWinStreak': longestWinStreak,
        'dailyStreak': dailyStreak,
        'bestDailyStreak': bestDailyStreak,
        'puzzlesSolved': puzzlesSolved,
        'totalCoinsEarned': totalCoinsEarned,
        'blitzWins': blitzWins,
        'timedWins': timedWins,
        'passPlayGames': passPlayGames,
        'handicapWins': handicapWins,
        'bestMargin': bestMargin,
        'fastestWinMoves': fastestWinMoves,
        'comebackWins': comebackWins,
        'finished19': finished19,
        'themesOwned': themesOwned,
        'coffeeSupporter': coffeeSupporter,
        'kidsModeWin': kidsModeWin,
        'playedLateNight': playedLateNight,
        'playedEarlyMorning': playedEarlyMorning,
        'modesPlayed': modesPlayed,
      };

  static PlayerStats fromJson(Map<String, dynamic> j) {
    final s = PlayerStats();
    int v(String k) => (j[k] as num?)?.toInt() ?? 0;
    bool b(String k) => (j[k] as bool?) ?? false;
    s.gamesPlayed = v('gamesPlayed');
    s.gamesWon = v('gamesWon');
    s.gamesLost = v('gamesLost');
    s.wins9 = v('wins9');
    s.wins13 = v('wins13');
    s.wins19 = v('wins19');
    s.winsVsEasy = v('winsVsEasy');
    s.winsVsMedium = v('winsVsMedium');
    s.winsVsHard = v('winsVsHard');
    s.winsVsExpert = v('winsVsExpert');
    s.totalCaptures = v('totalCaptures');
    s.biggestCaptureGame = v('biggestCaptureGame');
    s.biggestCaptureMove = v('biggestCaptureMove');
    s.currentWinStreak = v('currentWinStreak');
    s.longestWinStreak = v('longestWinStreak');
    s.dailyStreak = v('dailyStreak');
    s.bestDailyStreak = v('bestDailyStreak');
    s.puzzlesSolved = v('puzzlesSolved');
    s.totalCoinsEarned = v('totalCoinsEarned');
    s.blitzWins = v('blitzWins');
    s.timedWins = v('timedWins');
    s.passPlayGames = v('passPlayGames');
    s.handicapWins = v('handicapWins');
    s.bestMargin = v('bestMargin');
    s.fastestWinMoves = v('fastestWinMoves');
    s.comebackWins = v('comebackWins');
    s.finished19 = v('finished19');
    s.themesOwned = v('themesOwned');
    s.coffeeSupporter = b('coffeeSupporter');
    s.kidsModeWin = b('kidsModeWin');
    s.playedLateNight = b('playedLateNight');
    s.playedEarlyMorning = b('playedEarlyMorning');
    final modes = j['modesPlayed'];
    if (modes is List) {
      s.modesPlayed = modes.map((e) => e.toString()).toList();
    }
    return s;
  }
}

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final int coins;
  final bool Function(PlayerStats s) test;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.coins,
    required this.test,
  });
}

List<AchievementDef> buildAchievements() => [
      // --- Getting started ---
      AchievementDef(
          id: 'first_steps',
          title: 'First Steps',
          description: 'Play your first game of Go.',
          coins: 20,
          test: (s) => s.gamesPlayed >= 1),
      AchievementDef(
          id: 'getting_serious',
          title: 'Getting Serious',
          description: 'Play 10 games.',
          coins: 30,
          test: (s) => s.gamesPlayed >= 10),
      AchievementDef(
          id: 'regular',
          title: 'Regular',
          description: 'Play 50 games.',
          coins: 60,
          test: (s) => s.gamesPlayed >= 50),
      AchievementDef(
          id: 'devotee',
          title: 'Devotee',
          description: 'Play 100 games.',
          coins: 120,
          test: (s) => s.gamesPlayed >= 100),
      AchievementDef(
          id: 'go_lifer',
          title: 'Go Lifer',
          description: 'Play 250 games.',
          coins: 250,
          test: (s) => s.gamesPlayed >= 250),
      // --- Wins ---
      AchievementDef(
          id: 'first_win',
          title: 'First Victory',
          description: 'Win your first game.',
          coins: 30,
          test: (s) => s.gamesWon >= 1),
      AchievementDef(
          id: 'winner_5',
          title: 'Winning Ways',
          description: 'Win 5 games.',
          coins: 40,
          test: (s) => s.gamesWon >= 5),
      AchievementDef(
          id: 'winner_25',
          title: 'Contender',
          description: 'Win 25 games.',
          coins: 80,
          test: (s) => s.gamesWon >= 25),
      AchievementDef(
          id: 'winner_50',
          title: 'Champion',
          description: 'Win 50 games.',
          coins: 150,
          test: (s) => s.gamesWon >= 50),
      AchievementDef(
          id: 'winner_100',
          title: 'Grandmaster',
          description: 'Win 100 games.',
          coins: 300,
          test: (s) => s.gamesWon >= 100),
      // --- Board sizes ---
      AchievementDef(
          id: 'small_board_king',
          title: '9x9 Specialist',
          description: 'Win a game on the 9x9 board.',
          coins: 25,
          test: (s) => s.wins9 >= 1),
      AchievementDef(
          id: 'mid_board',
          title: '13x13 Explorer',
          description: 'Win a game on the 13x13 board.',
          coins: 35,
          test: (s) => s.wins13 >= 1),
      AchievementDef(
          id: 'full_board',
          title: '19x19 Conqueror',
          description: 'Win a game on the full 19x19 board.',
          coins: 60,
          test: (s) => s.wins19 >= 1),
      AchievementDef(
          id: 'all_boards',
          title: 'Board Master',
          description: 'Win on all three board sizes.',
          coins: 100,
          test: (s) => s.wins9 >= 1 && s.wins13 >= 1 && s.wins19 >= 1),
      AchievementDef(
          id: 'marathon',
          title: 'Marathon',
          description: 'Finish a full 19x19 game.',
          coins: 40,
          test: (s) => s.finished19 >= 1),
      // --- AI conquests ---
      AchievementDef(
          id: 'beat_easy',
          title: 'Warm-Up',
          description: 'Beat the Easy AI.',
          coins: 20,
          test: (s) => s.winsVsEasy >= 1),
      AchievementDef(
          id: 'beat_medium',
          title: 'Club Player',
          description: 'Beat the Medium AI.',
          coins: 30,
          test: (s) => s.winsVsMedium >= 1),
      AchievementDef(
          id: 'beat_hard',
          title: 'Tournament Ready',
          description: 'Beat the Hard AI.',
          coins: 60,
          test: (s) => s.winsVsHard >= 1),
      AchievementDef(
          id: 'beat_expert',
          title: 'Dan Slayer',
          description: 'Beat the Expert AI.',
          coins: 120,
          test: (s) => s.winsVsExpert >= 1),
      AchievementDef(
          id: 'beat_all_ai',
          title: 'AI Whisperer',
          description: 'Beat every AI difficulty.',
          coins: 150,
          test: (s) =>
              s.winsVsEasy >= 1 &&
              s.winsVsMedium >= 1 &&
              s.winsVsHard >= 1 &&
              s.winsVsExpert >= 1),
      // --- Captures ---
      AchievementDef(
          id: 'first_blood',
          title: 'First Blood',
          description: 'Capture your first stone.',
          coins: 15,
          test: (s) => s.totalCaptures >= 1),
      AchievementDef(
          id: 'cap_10',
          title: 'Sharp Tactics',
          description: 'Capture 10+ stones in a single game.',
          coins: 25,
          test: (s) => s.biggestCaptureGame >= 10),
      AchievementDef(
          id: 'cap_20',
          title: 'Relentless',
          description: 'Capture 20+ stones in a single game.',
          coins: 50,
          test: (s) => s.biggestCaptureGame >= 20),
      AchievementDef(
          id: 'cap_30',
          title: 'Annihilator',
          description: 'Capture 30+ stones in a single game.',
          coins: 100,
          test: (s) => s.biggestCaptureGame >= 30),
      AchievementDef(
          id: 'big_eater',
          title: 'Big Eater',
          description: 'Capture 5+ stones with a single move.',
          coins: 40,
          test: (s) => s.biggestCaptureMove >= 5),
      AchievementDef(
          id: 'cap_total_100',
          title: 'Stone Collector',
          description: 'Capture 100 stones in total.',
          coins: 40,
          test: (s) => s.totalCaptures >= 100),
      AchievementDef(
          id: 'cap_total_500',
          title: 'Stone Hoarder',
          description: 'Capture 500 stones in total.',
          coins: 100,
          test: (s) => s.totalCaptures >= 500),
      AchievementDef(
          id: 'cap_total_1000',
          title: 'Capture Legend',
          description: 'Capture 1,000 stones in total.',
          coins: 200,
          test: (s) => s.totalCaptures >= 1000),
      // --- Streaks ---
      AchievementDef(
          id: 'streak_3',
          title: 'On a Roll',
          description: 'Win 3 games in a row.',
          coins: 30,
          test: (s) => s.longestWinStreak >= 3),
      AchievementDef(
          id: 'streak_5',
          title: 'Unstoppable',
          description: 'Win 5 games in a row.',
          coins: 60,
          test: (s) => s.longestWinStreak >= 5),
      AchievementDef(
          id: 'streak_10',
          title: 'Invincible',
          description: 'Win 10 games in a row.',
          coins: 150,
          test: (s) => s.longestWinStreak >= 10),
      AchievementDef(
          id: 'daily_3',
          title: 'Habit Forming',
          description: 'Play on 3 consecutive days.',
          coins: 30,
          test: (s) => s.bestDailyStreak >= 3),
      AchievementDef(
          id: 'daily_7',
          title: 'Weekly Warrior',
          description: 'Play on 7 consecutive days.',
          coins: 70,
          test: (s) => s.bestDailyStreak >= 7),
      AchievementDef(
          id: 'daily_30',
          title: 'Monthly Master',
          description: 'Play on 30 consecutive days.',
          coins: 200,
          test: (s) => s.bestDailyStreak >= 30),
      // --- Puzzles ---
      AchievementDef(
          id: 'puzzle_1',
          title: 'Problem Solver',
          description: 'Solve your first tsumego puzzle.',
          coins: 20,
          test: (s) => s.puzzlesSolved >= 1),
      AchievementDef(
          id: 'puzzle_5',
          title: 'Tactician',
          description: 'Solve 5 tsumego puzzles.',
          coins: 40,
          test: (s) => s.puzzlesSolved >= 5),
      AchievementDef(
          id: 'puzzle_all',
          title: 'Life & Death Ace',
          description: 'Solve all 8 tsumego puzzles.',
          coins: 120,
          test: (s) => s.puzzlesSolved >= 8),
      // --- Modes ---
      AchievementDef(
          id: 'blitz_1',
          title: 'Blitz Winner',
          description: 'Win a 9x9 Blitz game.',
          coins: 30,
          test: (s) => s.blitzWins >= 1),
      AchievementDef(
          id: 'blitz_5',
          title: 'Speed Demon',
          description: 'Win 5 Blitz games.',
          coins: 80,
          test: (s) => s.blitzWins >= 5),
      AchievementDef(
          id: 'timed_1',
          title: 'Against the Clock',
          description: 'Win a Timed game.',
          coins: 40,
          test: (s) => s.timedWins >= 1),
      AchievementDef(
          id: 'pass_play',
          title: 'Friendly Match',
          description: 'Finish a Pass & Play game.',
          coins: 25,
          test: (s) => s.passPlayGames >= 1),
      AchievementDef(
          id: 'handicap_hero',
          title: 'Underdog',
          description: 'Win a game while giving handicap stones.',
          coins: 60,
          test: (s) => s.handicapWins >= 1),
      AchievementDef(
          id: 'explorer',
          title: 'Explorer',
          description: 'Try all 7 game modes.',
          coins: 80,
          test: (s) => s.modesPlayed.length >= 7),
      // --- Coins & style ---
      AchievementDef(
          id: 'coin_500',
          title: 'Stone Rich',
          description: 'Earn 500 Stone Coins in total.',
          coins: 25,
          test: (s) => s.totalCoinsEarned >= 500),
      AchievementDef(
          id: 'coin_2000',
          title: 'Stone Tycoon',
          description: 'Earn 2,000 Stone Coins in total.',
          coins: 50,
          test: (s) => s.totalCoinsEarned >= 2000),
      AchievementDef(
          id: 'coin_5000',
          title: 'Stone Magnate',
          description: 'Earn 5,000 Stone Coins in total.',
          coins: 100,
          test: (s) => s.totalCoinsEarned >= 5000),
      AchievementDef(
          id: 'margin_15',
          title: 'Decisive',
          description: 'Win a game by 15+ points.',
          coins: 40,
          test: (s) => s.bestMargin >= 15),
      AchievementDef(
          id: 'margin_30',
          title: 'Landslide',
          description: 'Win a game by 30+ points.',
          coins: 80,
          test: (s) => s.bestMargin >= 30),
      AchievementDef(
          id: 'fast_win',
          title: 'Blitzkrieg',
          description: 'Win a 9x9 game in under 40 moves.',
          coins: 50,
          test: (s) => s.fastestWinMoves > 0 && s.fastestWinMoves <= 40),
      AchievementDef(
          id: 'comeback',
          title: 'Comeback King',
          description: 'Win a game after losing 10+ stones.',
          coins: 70,
          test: (s) => s.comebackWins >= 1),
      // --- Collection & fun ---
      AchievementDef(
          id: 'theme_3',
          title: 'Decorator',
          description: 'Own 3 board themes.',
          coins: 30,
          test: (s) => s.themesOwned >= 3),
      AchievementDef(
          id: 'theme_all',
          title: 'Connoisseur',
          description: 'Own all 8 board themes.',
          coins: 150,
          test: (s) => s.themesOwned >= 8),
      AchievementDef(
          id: 'supporter',
          title: 'Supporter',
          description: 'Buy the developer a coffee.',
          coins: 100,
          test: (s) => s.coffeeSupporter),
      AchievementDef(
          id: 'kids_win',
          title: 'Little Master',
          description: 'Win a game with Kids Mode on.',
          coins: 30,
          test: (s) => s.kidsModeWin),
      AchievementDef(
          id: 'night_owl',
          title: 'Night Owl',
          description: 'Play a game between 10pm and 5am.',
          coins: 20,
          test: (s) => s.playedLateNight),
      AchievementDef(
          id: 'early_bird',
          title: 'Early Bird',
          description: 'Play a game between 5am and 8am.',
          coins: 20,
          test: (s) => s.playedEarlyMorning),
    ];

/// Returns the defs newly unlocked given [stats] and already-[owned] ids.
List<AchievementDef> newlyUnlocked(
    PlayerStats stats, Set<String> owned, List<AchievementDef> all) {
  return all.where((a) => !owned.contains(a.id) && a.test(stats)).toList();
}
