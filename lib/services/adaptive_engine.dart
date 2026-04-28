// lib/services/adaptive_engine.dart
// 🤖 MOTEUR IA ADAPTATIF — SM-2 + sélection de mots + difficulté automatique
// Ce moteur est appelé par chaque jeu pour :
//   1. Choisir les bons mots (SM-2 : révise les mots faibles en priorité)
//   2. Adapter la difficulté (Easy/Medium/Hard selon performances passées)
//   3. Calculer la qualité SM-2 de chaque réponse
//   4. Déterminer si un indice doit être affiché
// Voir : Ebbinghaus (1885), Wozniak SM-2 (1987)

import '../models/game_models.dart';
import '../models/student_models.dart';
import 'progress_service.dart';

/// Niveau de difficulté calculé automatiquement par l'IA
enum AdaptiveTier { easy, medium, hard }

class AdaptiveEngine {
  // Singleton partagé dans tout l'app
  static final AdaptiveEngine _instance = AdaptiveEngine._internal();
  factory AdaptiveEngine() => _instance;
  AdaptiveEngine._internal();

  final _progress = ProgressService();

  // ─────────────────────────────────────────────────────────
  // 1. SÉLECTION ADAPTATIVE DES MOTS
  //    Priorité : mots à réviser (SM-2) → mots les plus faibles → nouveaux mots
  // ─────────────────────────────────────────────────────────
  List<Word> selectWords(List<Word> pool, {int count = 8}) {
    if (pool.isEmpty) return [];
    count = count.clamp(1, pool.length);

    final dueIds = Set<int>.from(_progress.dueWordIds());

    // Mots dus à la révision aujourd'hui (SM-2)
    final due = pool.where((w) => dueIds.contains(w.id)).toList();

    // Mots non encore dus — triés par taux de réussite croissant (les plus faibles en tête)
    final notDue = pool.where((w) => !dueIds.contains(w.id)).toList()
      ..sort((a, b) {
        final sa = _progress.wordStatFor(a.id).successRate;
        final sb = _progress.wordStatFor(b.id).successRate;
        return sa.compareTo(sb);
      });

    // Mélanger les mots dus entre eux (pour ne pas toujours commencer par le même)
    due.shuffle();

    // Construire la sélection : révision d'abord, nouveaux/faibles ensuite
    final selected = [...due, ...notDue].take(count).toList()..shuffle();
    return selected;
  }

  // ─────────────────────────────────────────────────────────
  // 2. CALCUL DU TIER DE DIFFICULTÉ
  //    Basé sur les 3 dernières parties du même niveau
  //    < 55% → Easy · 55-80% → Medium · > 80% → Hard
  // ─────────────────────────────────────────────────────────
  AdaptiveTier tierForLevel(String levelId) {
    final recent = _progress.allScores
        .where((s) => s.levelId == levelId)
        .toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

    if (recent.isEmpty) return AdaptiveTier.easy; // 1ère fois → facile

    final last3 = recent.take(3).toList();
    final avgPct = last3.map((s) => s.percentage).reduce((a, b) => a + b) / last3.length;

    if (avgPct >= 80) return AdaptiveTier.hard;
    if (avgPct >= 55) return AdaptiveTier.medium;
    return AdaptiveTier.easy;
  }

  // ─────────────────────────────────────────────────────────
  // 3. PARAMÈTRES PAR JEU × TIER
  // ─────────────────────────────────────────────────────────

  /// Memory — nombre de paires à trouver
  int memoryPairs(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return 4;   // 8 cartes  → 4×4 petite grille
      case AdaptiveTier.medium: return 6;   // 12 cartes → 3×4
      case AdaptiveTier.hard:   return 8;   // 16 cartes → 4×4 grande grille
    }
  }

  /// Bingo — nombre de cibles à trouver (sur une grille 3×3 = 9 cases)
  int bingoTargets(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return 4;
      case AdaptiveTier.medium: return 6;
      case AdaptiveTier.hard:   return 9; // toute la grille
    }
  }

  /// Quiz — nombre d'options de réponse
  int quizOptions(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return 2; // choix binaire
      case AdaptiveTier.medium: return 3;
      case AdaptiveTier.hard:   return 4;
    }
  }

  /// Parcours — nombre de cases sur le plateau
  int parcoursCases(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return 8;
      case AdaptiveTier.medium: return 12;
      case AdaptiveTier.hard:   return 16;
    }
  }

  // ─────────────────────────────────────────────────────────
  // 4. QUALITÉ SM-2 — convertit une réponse en score 0-5
  //    quality < 3 → le mot est vu comme non maîtrisé (intervalle reset)
  //    quality ≥ 3 → maîtrisé (intervalle augmente)
  // ─────────────────────────────────────────────────────────
  int computeQuality({
    required bool isCorrect,
    required double responseTimeSeconds,
  }) {
    if (!isCorrect) {
      // Erreur rapide = mauvaise prise de décision (qualité 2)
      // Erreur lente = l'enfant a cherché mais pas trouvé (qualité 1)
      return responseTimeSeconds < 4 ? 2 : 1;
    }
    // Succès rapide = parfaitement maîtrisé
    if (responseTimeSeconds <= 3)  return 5;
    if (responseTimeSeconds <= 7)  return 4;
    return 3; // succès mais lent
  }

  // ─────────────────────────────────────────────────────────
  // 5. INDICE ADAPTATIF
  //    Affiche un indice si le mot a été raté plusieurs fois
  // ─────────────────────────────────────────────────────────
  bool shouldShowHint(int wordId) {
    final stat = _progress.wordStatFor(wordId);
    return stat.attempts >= 3 && stat.successRate < 0.4;
  }

  /// Retourne la traduction arabe comme indice (si disponible)
  String? hintFor(Word word) {
    if (!shouldShowHint(word.id)) return null;
    return word.traductionArabic ?? word.traductionDarija;
  }

  // ─────────────────────────────────────────────────────────
  // 6. MESSAGES ENCOURAGEMENT ADAPTATIFS
  // ─────────────────────────────────────────────────────────
  String encouragementMessage(int percentage) {
    if (percentage >= 95) return '🌟 PARFAIT ! Tu es une superstar du français !';
    if (percentage >= 80) return '🎉 Excellent travail ! Continue comme ça !';
    if (percentage >= 65) return '👍 Très bien ! Tu progresses vraiment bien !';
    if (percentage >= 50) return '💪 Bien joué ! Encore un peu d\'entraînement !';
    if (percentage >= 35) return '😊 Tu apprends ! Chaque essai compte !';
    return '🌈 C\'est difficile, mais tu vas y arriver ! Réessaie !';
  }

  /// Message motivant pendant le jeu (après 3+ erreurs consécutives)
  String motivationDuringGame(int errorsInARow) {
    if (errorsInARow <= 2) return '';
    final msgs = [
      '💡 Écoute bien le son du mot !',
      '🔍 Regarde les images attentivement !',
      '💪 Tu peux y arriver, continue !',
      '🌟 Prends ton temps, ce n\'est pas une course !',
    ];
    return msgs[errorsInARow % msgs.length];
  }

  // ─────────────────────────────────────────────────────────
  // 7. STATISTIQUES UTILES POUR LE DASHBOARD
  // ─────────────────────────────────────────────────────────

  /// Pourcentage global de maîtrise pour un niveau donné
  double masteryRate(String levelId) {
    final scores = _progress.allScores.where((s) => s.levelId == levelId).toList();
    if (scores.isEmpty) return 0;
    return scores.map((s) => s.percentage).reduce((a, b) => a + b) / scores.length;
  }

  /// Les N mots les plus difficiles de ce pool
  List<Word> hardestWords(List<Word> pool, {int top = 5}) {
    final withStats = pool.where((w) {
      final stat = _progress.wordStatFor(w.id);
      return stat.attempts >= 2;
    }).toList()
      ..sort((a, b) {
        final sa = _progress.wordStatFor(a.id).successRate;
        final sb = _progress.wordStatFor(b.id).successRate;
        return sa.compareTo(sb); // les plus faibles en premier
      });
    return withStats.take(top).toList();
  }

  /// Recommandation pour l'enseignant : "ces mots nécessitent de l'attention"
  String teacherRecommendation(List<Word> pool) {
    final hard = hardestWords(pool, top: 3);
    if (hard.isEmpty) return 'Aucune difficulté détectée pour ce niveau !';
    final names = hard.map((w) => '"${w.word}"').join(', ');
    return 'Mots à retravailler en classe : $names';
  }

  // ─────────────────────────────────────────────────────────
  // 8. TIER EN TEXTE (pour l'UI)
  // ─────────────────────────────────────────────────────────
  String tierLabel(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return '🟢 Facile';
      case AdaptiveTier.medium: return '🟡 Moyen';
      case AdaptiveTier.hard:   return '🔴 Difficile';
    }
  }

  String tierDescription(AdaptiveTier tier) {
    switch (tier) {
      case AdaptiveTier.easy:   return 'Moins de mots, plus de temps — l\'IA adapte pour toi !';
      case AdaptiveTier.medium: return 'Un bon équilibre — tu progresses bien !';
      case AdaptiveTier.hard:   return 'Le maximum ! Tu es vraiment doué(e) !';
    }
  }
}