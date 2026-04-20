// lib/models/game_models.dart

enum GameType { memory, quiz, bingo, parcours }
enum GameLevel { cp, ce1, ce2, cm1, cm2, revision }
enum Difficulty { easy, medium, hard }

class Word {
  final int id;
  final String word;
  final String emoji;
  final String imagePath;
  final String audioPath;
  final String? traductionDarija;
  final String? traductionArabic;
  final List<String>? correctSounds;

  Word({
    required this.id,
    required this.word,
    this.emoji = '📖',
    this.imagePath = '',
    this.audioPath = '',
    this.traductionDarija,
    this.traductionArabic,
    this.correctSounds,
  });
}

class GameLevelData {
  final String id;
  final String title;
  final String description;
  final GameLevel level;
  final int progression;
  final List<Word> vocabulary;
  final Difficulty difficulty;
  final int estimatedDuration;
  final List<GameType> availableGames;
  final String? theme;

  GameLevelData({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.progression,
    required this.vocabulary,
    required this.difficulty,
    required this.estimatedDuration,
    required this.availableGames,
    this.theme,
  });

  String getProgression() =>
      level == GameLevel.cp ? 'Semaine $progression' : 'Trimestre $progression';
}

class QuizQuestion {
  final int id;
  final String question;
  final String? imagePath;
  final String? emoji;
  final List<QuizOption> options;
  final String correctAnswerId;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    this.imagePath,
    this.emoji,
    required this.options,
    required this.correctAnswerId,
    this.explanation,
  });
}

class QuizOption {
  final String id;
  final String label;
  QuizOption({required this.id, required this.label});
}

class ParcoursChallenges {
  final int caseNumber;
  final String type;
  final String instruction;
  final Word? word;
  final QuizQuestion? question;
  final String? correctAnswer;

  ParcoursChallenges({
    required this.caseNumber,
    required this.type,
    required this.instruction,
    this.word,
    this.question,
    this.correctAnswer,
  });
}

class ParcourGame {
  final List<ParcoursChallenges> cases;
  int currentCase;
  int score;

  ParcourGame({required this.cases, this.currentCase = 0, this.score = 0});

  bool isFinished() => currentCase >= cases.length;

  ParcoursChallenges? getCurrentChallenge() =>
      currentCase < cases.length ? cases[currentCase] : null;

  void advance() {
    if (currentCase < cases.length - 1) {
      currentCase++;
    } else {
      currentCase = cases.length;
    }
  }
}

class GameResult {
  final GameType gameType;
  final GameLevelData levelData;
  final int score;
  final int maxScore;
  final Duration duration;
  final DateTime completedAt;
  final int? accuracy;

  GameResult({
    required this.gameType,
    required this.levelData,
    required this.score,
    required this.maxScore,
    required this.duration,
    required this.completedAt,
    this.accuracy,
  });

  double getPercentage() => maxScore == 0 ? 0 : (score / maxScore * 100).clamp(0, 100);

  int getStars() {
    final p = getPercentage();
    if (p >= 80) return 3;
    if (p >= 60) return 2;
    return 1;
  }
}