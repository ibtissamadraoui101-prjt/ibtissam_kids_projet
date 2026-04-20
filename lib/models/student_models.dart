// lib/models/student_models.dart
// Contient : Student, Teacher, Island, GameScore, WordStat
// Utilisé par : progress_service, firebase_service,
//               world_map_screen, teacher_dashboard

class Student {
  final String id;
  final String name;
  final String avatarEmoji;
  final int totalStars;
  final int currentStreak;
  final DateTime lastActivity;
  // levelId → étoiles (0-3)
  final Map<String, int> levelStars;
  // levelId → débloqué ?
  final Map<String, bool> levelUnlocked;
  // Identifiant de la classe (pour regrouper élèves d'un prof)
  final String? classCode;

  Student({
    required this.id,
    required this.name,
    this.avatarEmoji = '🦁',
    this.totalStars = 0,
    this.currentStreak = 0,
    required this.lastActivity,
    Map<String, int>? levelStars,
    Map<String, bool>? levelUnlocked,
    this.classCode,
  })  : levelStars = levelStars ?? {},
        levelUnlocked = levelUnlocked ?? {'cp-w1-alpha': true};

  Student copyWith({
    String? name,
    String? avatarEmoji,
    int? totalStars,
    int? currentStreak,
    DateTime? lastActivity,
    Map<String, int>? levelStars,
    Map<String, bool>? levelUnlocked,
    String? classCode,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      totalStars: totalStars ?? this.totalStars,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActivity: lastActivity ?? this.lastActivity,
      levelStars: levelStars ?? Map.from(this.levelStars),
      levelUnlocked: levelUnlocked ?? Map.from(this.levelUnlocked),
      classCode: classCode ?? this.classCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarEmoji': avatarEmoji,
        'totalStars': totalStars,
        'currentStreak': currentStreak,
        'lastActivity': lastActivity.toIso8601String(),
        'levelStars': levelStars,
        'levelUnlocked': levelUnlocked,
        'classCode': classCode,
      };

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'] as String,
        name: j['name'] as String,
        avatarEmoji: j['avatarEmoji'] as String? ?? '🦁',
        totalStars: (j['totalStars'] as num?)?.toInt() ?? 0,
        currentStreak: (j['currentStreak'] as num?)?.toInt() ?? 0,
        lastActivity: DateTime.parse(j['lastActivity'] as String),
        levelStars: (j['levelStars'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        levelUnlocked: (j['levelUnlocked'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as bool)),
        classCode: j['classCode'] as String?,
      );
}

// ─────────────────────────────────────────────
class Teacher {
  final String id;
  final String email;
  final String name;
  final String schoolName;
  // Code unique que les élèves entrent pour rejoindre la classe
  final String classCode;

  Teacher({
    required this.id,
    required this.email,
    required this.name,
    required this.schoolName,
    required this.classCode,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'schoolName': schoolName,
        'classCode': classCode,
      };

  factory Teacher.fromJson(Map<String, dynamic> j) => Teacher(
        id: j['id'] as String,
        email: j['email'] as String,
        name: j['name'] as String,
        schoolName: j['schoolName'] as String? ?? '',
        classCode: j['classCode'] as String,
      );
}

// ─────────────────────────────────────────────
class Island {
  final String id;
  final String label;
  final String emoji;
  final String tagline;
  final int totalLevels;
  final bool isUnlocked;
  final int starsEarned;
  final int starsToUnlock;

  Island({
    required this.id,
    required this.label,
    required this.emoji,
    required this.tagline,
    required this.totalLevels,
    required this.isUnlocked,
    required this.starsEarned,
    required this.starsToUnlock,
  });

  double get completionRate =>
      totalLevels == 0 ? 0 : (starsEarned / (totalLevels * 3)).clamp(0.0, 1.0);
}

// ─────────────────────────────────────────────
class GameScore {
  final String id;
  final String studentId;
  final String levelId;
  final String gameType; // 'memory','quiz','bingo','parcours'
  final int score;
  final int maxScore;
  final int durationSeconds;
  final int errorsCount;
  final DateTime playedAt;
  bool synced; // true = déjà envoyé à Firestore

  GameScore({
    required this.id,
    required this.studentId,
    required this.levelId,
    required this.gameType,
    required this.score,
    required this.maxScore,
    required this.durationSeconds,
    this.errorsCount = 0,
    required this.playedAt,
    this.synced = false,
  });

  double get percentage =>
      maxScore == 0 ? 0 : (score / maxScore * 100).clamp(0, 100);

  int get stars {
    final p = percentage;
    if (p >= 80) return 3;
    if (p >= 60) return 2;
    return 1;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'levelId': levelId,
        'gameType': gameType,
        'score': score,
        'maxScore': maxScore,
        'durationSeconds': durationSeconds,
        'errorsCount': errorsCount,
        'playedAt': playedAt.toIso8601String(),
        'synced': synced,
      };

  factory GameScore.fromJson(Map<String, dynamic> j) => GameScore(
        id: j['id'] as String,
        studentId: j['studentId'] as String? ?? '',
        levelId: j['levelId'] as String,
        gameType: j['gameType'] as String,
        score: (j['score'] as num).toInt(),
        maxScore: (j['maxScore'] as num).toInt(),
        durationSeconds: (j['durationSeconds'] as num?)?.toInt() ?? 0,
        errorsCount: (j['errorsCount'] as num?)?.toInt() ?? 0,
        playedAt: DateTime.parse(j['playedAt'] as String),
        synced: j['synced'] as bool? ?? false,
      );
}

// ─────────────────────────────────────────────
// Statistique par mot (pour l'algorithme SM-2)
class WordStat {
  final int wordId;
  int attempts;     // nombre total d'essais
  int successes;    // nombre de réussites
  double easeFactor; // SM-2 : commence à 2.5
  int interval;      // jours avant prochaine révision
  DateTime? nextReview;

  WordStat({
    required this.wordId,
    this.attempts = 0,
    this.successes = 0,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.nextReview,
  });

  double get successRate =>
      attempts == 0 ? 0.0 : successes / attempts;

  bool get isDue =>
      nextReview == null || DateTime.now().isAfter(nextReview!);

  // quality : 0=échec total, 3=correct avec effort, 5=parfait
  void updateSM2(int quality) {
    attempts++;
    if (quality >= 3) successes++;

    if (quality < 3) {
      interval = 1;
    } else {
      if (interval == 1) {
        interval = 1;
      } else if (interval == 2) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
    }

    easeFactor = (easeFactor +
            0.1 -
            (5 - quality) * (0.08 + (5 - quality) * 0.02))
        .clamp(1.3, 2.8);

    nextReview = DateTime.now().add(Duration(days: interval));
  }

  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'attempts': attempts,
        'successes': successes,
        'easeFactor': easeFactor,
        'interval': interval,
        'nextReview': nextReview?.toIso8601String(),
      };

  factory WordStat.fromJson(Map<String, dynamic> j) => WordStat(
        wordId: (j['wordId'] as num).toInt(),
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        successes: (j['successes'] as num?)?.toInt() ?? 0,
        easeFactor: (j['easeFactor'] as num?)?.toDouble() ?? 2.5,
        interval: (j['interval'] as num?)?.toInt() ?? 1,
        nextReview: j['nextReview'] != null
            ? DateTime.parse(j['nextReview'] as String)
            : null,
      );
}