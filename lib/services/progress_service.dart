// lib/services/progress_service.dart
// ✅ v3.2 — CORRECTION DÉBLOCAGE JEUX VOCAL & PHRASES
//
// PROBLÈME : gameOrder ne contenait que 4 jeux (memory/quiz/bingo/parcours).
// vocal et phrases avaient idx == -1 → isGameUnlocked retournait false → boutons verrouillés.
//
// SOLUTION :
//   • coreGameOrder   = les 4 jeux qui comptent pour les étoiles et débloquer le niveau suivant
//   • extraGameOrder  = vocal + phrases, déblocables séparément (après parcours)
//   • gameOrder       = les 6 ensemble (pour isGameUnlocked)
//   • allGamesDone    n'attend plus que les 6 — seulement les 4 cœurs

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/student_models.dart';
import 'firebase_service.dart';

class ProgressService extends ChangeNotifier {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  static const String _keyStudent   = 'student_v2';
  static const String _keyScores    = 'scores_v2';
  static const String _keyWordStats = 'word_stats_v2';

  // ──────────────────────────────────────────────────────
  // ✅ SÉPARATION : jeux principaux vs jeux communication
  // ──────────────────────────────────────────────────────

  /// Les 4 jeux PRINCIPAUX — comptent pour les étoiles et le déblocage du niveau suivant
  static const List<String> coreGameOrder = [
    'memory',
    'quiz',
    'bingo',
    'parcours',
  ];

  /// Les 2 jeux COMMUNICATION — débloqués après parcours, bonus
  /// Ne bloquent PAS les étoiles ni le niveau suivant
  static const List<String> extraGameOrder = [
    'vocal',    // débloqué quand parcours est terminé
    'phrases',  // débloqué quand vocal est terminé
  ];

  /// Tous les jeux dans l'ordre (utilisé par isGameUnlocked)
  static const List<String> gameOrder = [
    'memory', 'quiz', 'bingo', 'parcours',
    'vocal',  'phrases',
  ];

  Student?                 _student;
  final List<GameScore>    _scores    = [];
  final Map<int, WordStat> _wordStats = {};

  Student?        get student    => _student;
  bool            get hasStudent => _student != null;
  List<GameScore> get allScores  => List.unmodifiable(_scores);

  // ═══════════════════════════════════════════════════
  // INIT
  // ═══════════════════════════════════════════════════
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final sJson = prefs.getString(_keyStudent);
    if (sJson != null) {
      try { _student = Student.fromJson(jsonDecode(sJson)); }
      catch (e) { debugPrint('ProgressService init student: $e'); }
    }

    final scJson = prefs.getString(_keyScores);
    if (scJson != null) {
      try {
        final list = jsonDecode(scJson) as List;
        _scores.addAll(list.map((j) => GameScore.fromJson(j)));
      } catch (e) { debugPrint('ProgressService init scores: $e'); }
    }

    final wsJson = prefs.getString(_keyWordStats);
    if (wsJson != null) {
      try {
        final map = jsonDecode(wsJson) as Map<String, dynamic>;
        map.forEach((k, v) {
          _wordStats[int.parse(k)] = WordStat.fromJson(v as Map<String, dynamic>);
        });
      } catch (e) { debugPrint('ProgressService init wordStats: $e'); }
    }

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // CRÉER / MODIFIER ÉLÈVE
  // ═══════════════════════════════════════════════════
  Future<void> createStudent(String name, {String emoji = '🦁', String? classCode}) async {
    _student = Student(
      id:            const Uuid().v4(),
      name:          name,
      avatarEmoji:   emoji,
      lastActivity:  DateTime.now(),
      levelUnlocked: {'cp-w1-alpha': true},
      classCode:     classCode,
    );
    await _saveAll();
    _trySyncStudent();
    notifyListeners();
  }

  Future<void> updateProfile(String name, String avatarEmoji) async {
    if (_student == null) return;
    _student = _student!.copyWith(name: name, avatarEmoji: avatarEmoji);
    await _saveAll();
    _trySyncStudent();
    notifyListeners();
  }

  Future<void> resetProgress() async {
    if (_student == null) return;
    _student = Student(
      id:            _student!.id,
      name:          _student!.name,
      avatarEmoji:   _student!.avatarEmoji,
      lastActivity:  DateTime.now(),
      levelUnlocked: {'cp-w1-alpha': true},
    );
    _scores.clear();
    _wordStats.clear();
    await _saveAll();
    _trySyncStudent();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // ✅ DÉBLOCAGE — LOGIQUE CORRIGÉE
  // ═══════════════════════════════════════════════════

  /// Retourne si un jeu est débloqué pour un niveau donné.
  ///
  /// Règles :
  ///   memory   → toujours ouvert (si le niveau est débloqué)
  ///   quiz     → memory terminé
  ///   bingo    → quiz terminé
  ///   parcours → bingo terminé
  ///   vocal    → parcours terminé   ✅ NOUVEAU
  ///   phrases  → vocal terminé      ✅ NOUVEAU
  bool isGameUnlocked(String levelId, String gameType) {
    if (_student == null)      return false;
    if (!isUnlocked(levelId)) return false;

    final idx = gameOrder.indexOf(gameType);
    if (idx == -1) return false;   // jeu inconnu
    if (idx == 0)  return true;    // memory toujours ouvert

    // Chaque jeu nécessite que le précédent soit terminé
    final prevGame = gameOrder[idx - 1];
    return hasCompletedGame(levelId, prevGame);
  }

  bool hasCompletedGame(String levelId, String gameType) {
    if (_student == null) return false;
    final games = _student!.completedGames[levelId] ?? [];
    return games.contains(gameType);
  }

  int completedGameCount(String levelId) {
    if (_student == null) return 0;
    return (_student!.completedGames[levelId] ?? []).length;
  }

  String? nextGameToPlay(String levelId) {
    for (final game in gameOrder) {
      if (!hasCompletedGame(levelId, game)) return game;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════
  // ENREGISTRER UN SCORE
  // ═══════════════════════════════════════════════════
  Future<void> recordScore({
    required String levelId,
    required String gameType,
    required int    score,
    required int    maxScore,
    int             durationSeconds = 0,
    int             errorsCount     = 0,
    Map<int, int>?  wordQualities,
  }) async {
    if (_student == null) return;

    final gameScore = GameScore(
      id:              const Uuid().v4(),
      studentId:       _student!.id,
      levelId:         levelId,
      gameType:        gameType,
      score:           score,
      maxScore:        maxScore,
      durationSeconds: durationSeconds,
      errorsCount:     errorsCount,
      playedAt:        DateTime.now(),
    );

    // 1. Historique local
    _scores.add(gameScore);
    if (_scores.length > 200) _scores.removeAt(0);

    // 2. SM-2
    if (wordQualities != null) {
      wordQualities.forEach((wordId, quality) {
        _wordStats.putIfAbsent(wordId, () => WordStat(wordId: wordId));
        _wordStats[wordId]!.updateSM2(quality);
      });
    }

    // 3. Marquer ce jeu comme terminé
    final updatedCompleted = Map<String, List<String>>.from(_student!.completedGames);
    final gamesForLevel    = List<String>.from(updatedCompleted[levelId] ?? []);
    if (!gamesForLevel.contains(gameType)) {
      gamesForLevel.add(gameType);
    }
    updatedCompleted[levelId] = gamesForLevel;

    // ✅ 4. Étoiles — seulement si les 4 jeux PRINCIPAUX sont terminés
    //    (vocal et phrases sont bonus, ne bloquent pas les étoiles)
    final coresDone = coreGameOrder.every((g) => gamesForLevel.contains(g));
    final newStars  = coresDone ? gameScore.stars : 0;
    final currentStars = _student!.levelStars[levelId] ?? 0;
    final bonusStars   = newStars > currentStars ? newStars - currentStars : 0;

    final updatedLevelStars = Map<String, int>.from(_student!.levelStars);
    if (newStars > currentStars) updatedLevelStars[levelId] = newStars;

    // ✅ 5. Débloquer le niveau suivant — seulement après les 4 jeux principaux
    final updatedUnlocked = Map<String, bool>.from(_student!.levelUnlocked);
    if (coresDone && newStars >= 2) {
      final next = _getNextLevelId(levelId);
      if (next != null) {
        updatedUnlocked[next] = true;
        debugPrint('ProgressService ✅ niveau débloqué → $next');
      }
    }

    // 6. Streak
    final now    = DateTime.now();
    final last   = _student!.lastActivity;
    final diff   = now.difference(last).inDays;
    final streak = diff <= 1 ? _student!.currentStreak + 1 : 1;

    _student = _student!.copyWith(
      totalStars:     _student!.totalStars + bonusStars,
      currentStreak:  streak,
      levelStars:     updatedLevelStars,
      levelUnlocked:  updatedUnlocked,
      lastActivity:   now,
      completedGames: updatedCompleted,
    );

    await _saveAll();
    _trySyncScore(gameScore);
    _trySyncStudent();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // ACCESSEURS
  // ═══════════════════════════════════════════════════
  bool isUnlocked(String levelId) {
    if (levelId == 'cp-w1-alpha') return true;
    return _student?.levelUnlocked[levelId] ?? false;
  }

  int starsFor(String levelId) => _student?.levelStars[levelId] ?? 0;

  WordStat wordStatFor(int wordId) =>
      _wordStats.putIfAbsent(wordId, () => WordStat(wordId: wordId));

  List<int> dueWordIds() =>
      _wordStats.values.where((s) => s.isDue).map((s) => s.wordId).toList();

  List<WordStat> weakestWords({int top = 10}) {
    final list = _wordStats.values.where((s) => s.attempts >= 2).toList()
      ..sort((a, b) => a.successRate.compareTo(b.successRate));
    return list.take(top).toList();
  }

  Map<String, double> avgScorePerLevel() {
    final map = <String, List<double>>{};
    for (final s in _scores) {
      map.putIfAbsent(s.levelId, () => []).add(s.percentage);
    }
    return map.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  List<GameScore> recentScores({int limit = 20}) =>
      _scores.reversed.take(limit).toList();

  // ═══════════════════════════════════════════════════
  // ÎLES
  // ═══════════════════════════════════════════════════
  List<Island> buildIslands() {
    final total = _student?.totalStars ?? 0;
    final configs = [
      (id:'cp',  label:'CP',  emoji:'🌱', tagline:'L\'alphabet, les couleurs, les animaux !',
        levels:6, needed:0,  ids:['cp-w1-alpha','cp-w2-numbers','cp-w3-colors','cp-w4-greet','cp-w5-animals1','cp-w6-animals2']),
      (id:'ce1', label:'CE1', emoji:'🌿', tagline:'La famille, la nourriture, la météo !',
        levels:3, needed:10, ids:['ce1-t1','ce1-t2','ce1-t3']),
      (id:'ce2', label:'CE2', emoji:'🌳', tagline:'L\'école, la maison, les verbes !',
        levels:3, needed:18, ids:['ce2-t1','ce2-t2','ce2-t3']),
      (id:'cm1', label:'CM1', emoji:'🦋', tagline:'Les émotions, les métiers !',
        levels:3, needed:27, ids:['cm1-t1','cm1-t2','cm1-t3']),
      (id:'cm2', label:'CM2', emoji:'🚀', tagline:'Maître du français !',
        levels:3, needed:36, ids:['cm2-t1','cm2-t2','cm2-t3']),
    ];

    return configs.map((c) {
      final earned = c.ids.fold(0, (sum, id) => sum + (_student?.levelStars[id] ?? 0));
      return Island(
        id:            c.id,
        label:         c.label,
        emoji:         c.emoji,
        tagline:       c.tagline,
        totalLevels:   c.levels,
        isUnlocked:    total >= c.needed || c.id == 'cp',
        starsEarned:   earned,
        starsToUnlock: c.needed,
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════
  // PRIVÉ
  // ═══════════════════════════════════════════════════
  static const _levelOrder = [
    'cp-w1-alpha','cp-w2-numbers','cp-w3-colors',
    'cp-w4-greet','cp-w5-animals1','cp-w6-animals2',
    'ce1-t1','ce1-t2','ce1-t3',
    'ce2-t1','ce2-t2','ce2-t3',
    'cm1-t1','cm1-t2','cm1-t3',
    'cm2-t1','cm2-t2','cm2-t3',
  ];

  String? _getNextLevelId(String current) {
    final i = _levelOrder.indexOf(current);
    if (i == -1 || i >= _levelOrder.length - 1) return null;
    return _levelOrder[i + 1];
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    if (_student != null) {
      await prefs.setString(_keyStudent, jsonEncode(_student!.toJson()));
    }
    await prefs.setString(_keyScores, jsonEncode(_scores.map((s) => s.toJson()).toList()));
    await prefs.setString(_keyWordStats,
        jsonEncode(_wordStats.map((k, v) => MapEntry(k.toString(), v.toJson()))));
  }

  Future<void> _trySyncScore(GameScore gs) async {
    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn.contains(ConnectivityResult.none)) return;
      final ok = await FirebaseService().syncScore(gs);
      if (ok) {
        final i = _scores.indexWhere((s) => s.id == gs.id);
        if (i != -1) _scores[i].synced = true;
        await _saveAll();
      }
    } catch (e) { debugPrint('ProgressService sync score: $e'); }
  }

  Future<void> _trySyncStudent() async {
    if (_student == null) return;
    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn.contains(ConnectivityResult.none)) return;
      await FirebaseService().syncStudent(_student!);
    } catch (e) { debugPrint('ProgressService sync student: $e'); }
  }
}