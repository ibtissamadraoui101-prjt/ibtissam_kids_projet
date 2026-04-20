// lib/services/adaptive_engine.dart
// Algorithme SM-2 + sélection adaptative des mots
// IMPORTANT : importe les vrais modèles, ne redéfinit rien

import '../models/game_models.dart';   // Word, GameLevelData (tes fichiers existants)
import 'progress_service.dart';

/// Niveau de difficulté calculé automatiquement
enum AdaptiveTier { easy, medium, hard }

class AdaptiveEngine {
  // Singleton
  static final AdaptiveEngine _instance = AdaptiveEngine._internal();
  factory AdaptiveEngine() => _instance;
  AdaptiveEngine._internal();

  final _progress = ProgressService();

  // ─────────────────────────────────────────────
  // SÉLECTION DES MOTS
  // Prioritise les mots faibles + ceux à réviser
  // ─────────────────────────────────────────────
  List<Word> selectWords(List<Word> pool, {int count = 8}) {
    final dueIds = Set<int>.from(_progress.dueWordIds());

    // Mots à réviser aujourd'hui (SM-2)
    final due = pool.where((w) => dueIds.contains(w.id)).toList();
    // Nouveaux mots
    final fresh = pool.where((w) => !dueIds.contains(w.id)).toList()
      ..shuffle();

    // Trier par taux de réussite (les plus faibles en premier)
    due.sort((a, b) {
      final sa = _progress.wordStatFor(a.id).successRate;
      final sb = _progress.wordStatFor(b.id).successRate;
      return sa.compareTo(sb);
    });

    // Combiner : révision d'abord, nouveaux ensuite
    final selected = [...due, ...fresh].take(count).toList()..shuffle();
    return selected;
  }

  // ─────────────────────────────────────────────
  // CALCULER LE NIVEAU DE DIFFICULTÉ
  // Basé sur les 3 dernières parties du même niveau
  // ─────────────────────────────────────────────
  AdaptiveTier tierForLevel(String levelId) {
    final recent = _progress.allScores
        .where((s) => s.levelId == levelId)
        .toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

    if (recent.isEmpty) return AdaptiveTier.easy;

    final last3 = recent.take(3).toList();
    final avgPct =
        last3.map((s) => s.percentage).reduce((a, b) => a + b) / last3.length;

    if (avgPct >= 80) return AdaptiveTier.hard;
    if (avgPct >= 55) return AdaptiveTier.medium;
    return AdaptiveTier.easy;
  }

  // ─────────────────────────────────────────────
  // PARAMÈTRES SELON LA DIFFICULTÉ
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  // QUALITÉ SM-2 depuis un événement de jeu
  // ─────────────────────────────────────────────

  /// Convertit une réponse en score qualité pour SM-2
  /// quality 0=échec complet, 5=parfait
  int computeQuality({
    required bool isCorrect,
    required double responseTimeSeconds,
  }) {
    if (!isCorrect) {
      return responseTimeSeconds < 4 ? 2 : 1;
    }
    if (responseTimeSeconds <= 3) return 5;
    if (responseTimeSeconds <= 7) return 4;
    return 3;
  }

  /// Faut-il afficher un indice pour ce mot ?
  bool shouldShowHint(int wordId) {
    final stat = _progress.wordStatFor(wordId);
    return stat.attempts >= 3 && stat.successRate < 0.4;
  }

  /// Message d'encouragement adapté au score (0-100)
  String encouragementMessage(int percentage) {
    if (percentage >= 90) return '🌟 Excellent ! Tu es champion !';
    if (percentage >= 75) return '🎉 Très bien ! Continue comme ça !';
    if (percentage >= 60) return '👍 Bien joué ! Tu progresses !';
    if (percentage >= 40) return '💪 Courage ! Tu vas t\'améliorer !';
    return '😊 C\'est difficile, mais tu vas y arriver !';
  }
}