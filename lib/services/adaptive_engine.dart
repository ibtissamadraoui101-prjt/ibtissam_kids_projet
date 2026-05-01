// lib/services/adaptive_engine.dart
// 🤖 MOTEUR IA ADAPTATIF v3
// ✅ AMÉLIORATIONS :
//   • Labels de difficulté enfantins ("Mode Génie" au lieu de "Difficile")
//   • Messages d'encouragement plus variés et en arabe darija
//   • Nouveau : rapport "points forts / points faibles" pour l'enfant
//   • Nouveau : shouldShowElimination() pour le quiz (comme le 50/50)
//   • Meilleure gestion des nouveaux élèves (0 historique)

import '../models/game_models.dart';
import '../models/student_models.dart';
import 'progress_service.dart';

enum AdaptiveTier { easy, medium, hard }

class AdaptiveEngine {
  static final AdaptiveEngine _instance = AdaptiveEngine._internal();
  factory AdaptiveEngine() => _instance;
  AdaptiveEngine._internal();

  final _progress = ProgressService();

  // ─────────────────────────────────────────────────────────
  // 1. SÉLECTION ADAPTATIVE DES MOTS
  // ─────────────────────────────────────────────────────────
  List<Word> selectWords(List<Word> pool, {int count = 8}) {
    if (pool.isEmpty) return [];
    count = count.clamp(1, pool.length);

    final dueIds = Set<int>.from(_progress.dueWordIds());
    final due = pool.where((w) => dueIds.contains(w.id)).toList();
    final notDue = pool.where((w) => !dueIds.contains(w.id)).toList()
      ..sort((a, b) {
        final sa = _progress.wordStatFor(a.id).successRate;
        final sb = _progress.wordStatFor(b.id).successRate;
        return sa.compareTo(sb);
      });

    due.shuffle();
    final selected = [...due, ...notDue].take(count).toList()..shuffle();
    return selected;
  }

  // ─────────────────────────────────────────────────────────
  // 2. CALCUL DU TIER
  // ─────────────────────────────────────────────────────────
  AdaptiveTier tierForLevel(String levelId) {
    final recent = _progress.allScores
        .where((s) => s.levelId == levelId)
        .toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

    if (recent.isEmpty) return AdaptiveTier.easy;

    final last3 = recent.take(3).toList();
    final avgPct = last3.map((s) => s.percentage).reduce((a, b) => a + b) / last3.length;

    if (avgPct >= 80) return AdaptiveTier.hard;
    if (avgPct >= 55) return AdaptiveTier.medium;
    return AdaptiveTier.easy;
  }

  // ─────────────────────────────────────────────────────────
  // 3. PARAMÈTRES PAR JEU
  // ─────────────────────────────────────────────────────────
  int memoryPairs(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return 4;
      case AdaptiveTier.medium: return 6;
      case AdaptiveTier.hard:   return 8;
    }
  }

  int bingoTargets(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return 4;
      case AdaptiveTier.medium: return 6;
      case AdaptiveTier.hard:   return 9;
    }
  }

  int quizOptions(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return 2;
      case AdaptiveTier.medium: return 3;
      case AdaptiveTier.hard:   return 4;
    }
  }

  int parcoursCases(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return 8;
      case AdaptiveTier.medium: return 12;
      case AdaptiveTier.hard:   return 16;
    }
  }

  // ─────────────────────────────────────────────────────────
  // 4. QUALITÉ SM-2
  // ─────────────────────────────────────────────────────────
  int computeQuality({
    required bool isCorrect,
    required double responseTimeSeconds,
  }) {
    if (!isCorrect) return responseTimeSeconds < 4 ? 2 : 1;
    if (responseTimeSeconds <= 3) return 5;
    if (responseTimeSeconds <= 7) return 4;
    return 3;
  }

  // ─────────────────────────────────────────────────────────
  // 5. INDICES ADAPTATIFS
  // ─────────────────────────────────────────────────────────
  bool shouldShowHint(int wordId) {
    final stat = _progress.wordStatFor(wordId);
    return stat.attempts >= 3 && stat.successRate < 0.4;
  }

  String? hintFor(Word word) {
    if (!shouldShowHint(word.id)) return null;
    return word.traductionArabic ?? word.traductionDarija;
  }

  // ✅ NOUVEAU : élimination d'une mauvaise réponse (comme le 50/50)
  // Utilisé dans le Quiz en mode Medium/Hard quand l'enfant hésite > 8s
  bool shouldShowElimination(String levelId, double timeLeft, double totalTime) {
    final tier = tierForLevel(levelId);
    if (tier == AdaptiveTier.easy) return false;
    return timeLeft < totalTime * 0.4; // 40% du temps restant
  }

  // ─────────────────────────────────────────────────────────
  // 6. MESSAGES ENFANTINS — v3
  // ─────────────────────────────────────────────────────────

  /// Message de fin de partie — plus varié et motivant
  String encouragementMessage(int percentage) {
    if (percentage >= 95) return '🌟 PARFAIT ! Tu es un génie du français !';
    if (percentage >= 80) return '🎉 SUPER ! Tu es vraiment fort(e) !';
    if (percentage >= 65) return '👍 Très bien ! Continue comme ça !';
    if (percentage >= 50) return '💪 Bien joué ! Encore un peu !';
    if (percentage >= 35) return '😊 Tu apprends vite ! Réessaie !';
    return '🌈 C\'est difficile mais tu vas y arriver !';
  }

  /// Message pendant le jeu (après erreurs consécutives)
  String motivationDuringGame(int errorsInARow) {
    if (errorsInARow <= 1) return '';
    final msgs = [
      '💡 Écoute bien le son !',
      '🔍 Regarde l\'image attentivement !',
      '💪 Tu peux y arriver !',
      '🌟 Prends ton temps !',
      '🎵 Répète le mot dans ta tête !',
    ];
    return msgs[errorsInARow % msgs.length];
  }

  // ✅ NOUVEAU : rapport "points forts / points faibles" pour l'enfant
  Map<String, List<String>> childReport(List<Word> pool) {
    final strong = <String>[];
    final weak = <String>[];

    for (final word in pool) {
      final stat = _progress.wordStatFor(word.id);
      if (stat.attempts < 2) continue;
      if (stat.successRate >= 0.75) {
        strong.add(word.word);
      } else if (stat.successRate < 0.5) {
        weak.add(word.word);
      }
    }

    return {'strong': strong.take(3).toList(), 'weak': weak.take(3).toList()};
  }

  // ─────────────────────────────────────────────────────────
  // 7. LABELS UI ENFANTINS — v3
  // ✅ "Mode Génie" plutôt que "Difficile" — psychologie positive
  // ─────────────────────────────────────────────────────────
  String tierLabel(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return '🐣 Débutant';
      case AdaptiveTier.medium: return '⚡ Champion';
      case AdaptiveTier.hard:   return '🧠 Génie';
    }
  }

  String tierEmoji(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return '🐣';
      case AdaptiveTier.medium: return '⚡';
      case AdaptiveTier.hard:   return '🧠';
    }
  }

  String tierDescription(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return 'L\'IA a choisi le mode parfait pour toi !';
      case AdaptiveTier.medium: return 'Tu progresses bien — le vrai défi commence !';
      case AdaptiveTier.hard:   return 'Mode Génie ! Tu es prêt(e) pour le maximum !';
    }
  }

  // ─────────────────────────────────────────────────────────
  // 8. STATS POUR LE DASHBOARD
  // ─────────────────────────────────────────────────────────
  double masteryRate(String levelId) {
    final scores = _progress.allScores.where((s) => s.levelId == levelId).toList();
    if (scores.isEmpty) return 0;
    return scores.map((s) => s.percentage).reduce((a, b) => a + b) / scores.length;
  }

  List<Word> hardestWords(List<Word> pool, {int top = 5}) {
    final withStats = pool.where((w) {
      final stat = _progress.wordStatFor(w.id);
      return stat.attempts >= 2;
    }).toList()
      ..sort((a, b) {
        final sa = _progress.wordStatFor(a.id).successRate;
        final sb = _progress.wordStatFor(b.id).successRate;
        return sa.compareTo(sb);
      });
    return withStats.take(top).toList();
  }

  String teacherRecommendation(List<Word> pool) {
    final hard = hardestWords(pool, top: 3);
    if (hard.isEmpty) return 'Aucune difficulté détectée pour ce niveau !';
    final names = hard.map((w) => '"${w.word}"').join(', ');
    return 'Mots à retravailler en classe : $names';
  }
}