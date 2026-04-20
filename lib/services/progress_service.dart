// lib/services/progress_service.dart
// Gère : sauvegarde locale + sync Firebase
// Utilisé par : main, tous les jeux, world_map_screen

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

  static const String _keyStudent = 'student_v2';
  static const String _keyScores = 'scores_v2';
  static const String _keyWordStats = 'word_stats_v2';

  Student? _student;
  final List<GameScore> _scores = [];
  final Map<int, WordStat> _wordStats = {};

  Student? get student => _student;
  bool get hasStudent => _student != null;
  List<GameScore> get allScores => List.unmodifiable(_scores);

  // ─────────────────────────────────────────────
  // INITIALISATION — appeler dans main()
  // ─────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Charger élève
    final sJson = prefs.getString(_keyStudent);
    if (sJson != null) {
      try {
        _student = Student.fromJson(jsonDecode(sJson));
      } catch (e) {
        debugPrint('ProgressService init student error: $e');
      }
    }

    // Charger scores
    final scJson = prefs.getString(_keyScores);
    if (scJson != null) {
      try {
        final list = jsonDecode(scJson) as List;
        _scores.addAll(list.map((j) => GameScore.fromJson(j)));
      } catch (e) {
        debugPrint('ProgressService init scores error: $e');
      }
    }

    // Charger stats de mots
    final wsJson = prefs.getString(_keyWordStats);
    if (wsJson != null) {
      try {
        final map = jsonDecode(wsJson) as Map<String, dynamic>;
        map.forEach((k, v) {
          final id = int.parse(k);
          _wordStats[id] = WordStat.fromJson(v as Map<String, dynamic>);
        });
      } catch (e) {
        debugPrint('ProgressService init wordStats error: $e');
      }
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // CRÉER ÉLÈVE
  // ─────────────────────────────────────────────
  Future<void> createStudent(
    String name, {
    String emoji = '🦁',
    String? classCode,
  }) async {
    _student = Student(
      id: const Uuid().v4(),
      name: name,
      avatarEmoji: emoji,
      lastActivity: DateTime.now(),
      levelUnlocked: {'cp-w1-alpha': true},
      classCode: classCode,
    );
    await _saveAll();

    // Sync Firestore en arrière-plan
    _trySyncStudent();
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // ENREGISTRER RÉSULTAT (appelé à la fin de chaque jeu)
  // ─────────────────────────────────────────────
  Future<void> recordScore({
    required String levelId,
    required String gameType,
    required int score,
    required int maxScore,
    int durationSeconds = 0,
    int errorsCount = 0,
    // wordResults : wordId → quality (0-5 SM-2)
    Map<int, int>? wordQualities,
  }) async {
    if (_student == null) return;

    final gameScore = GameScore(
      id: const Uuid().v4(),
      studentId: _student!.id,
      levelId: levelId,
      gameType: gameType,
      score: score,
      maxScore: maxScore,
      durationSeconds: durationSeconds,
      errorsCount: errorsCount,
      playedAt: DateTime.now(),
      synced: false,
    );

    // 1. Ajouter à l'historique local
    _scores.add(gameScore);
    if (_scores.length > 200) _scores.removeAt(0);

    // 2. Mettre à jour SM-2 pour chaque mot
    if (wordQualities != null) {
      wordQualities.forEach((wordId, quality) {
        _wordStats.putIfAbsent(wordId, () => WordStat(wordId: wordId));
        _wordStats[wordId]!.updateSM2(quality);
      });
    }

    // 3. Mettre à jour étoiles
    final newStars = gameScore.stars;
    final currentStars = _student!.levelStars[levelId] ?? 0;
    final bonusStars = newStars > currentStars ? newStars - currentStars : 0;

    final updatedLevelStars = Map<String, int>.from(_student!.levelStars);
    if (newStars > currentStars) {
      updatedLevelStars[levelId] = newStars;
    }

    // 4. Débloquer niveau suivant si >= 2 étoiles
    final updatedUnlocked = Map<String, bool>.from(_student!.levelUnlocked);
    if (newStars >= 2) {
      final next = _getNextLevelId(levelId);
      if (next != null) {
        updatedUnlocked[next] = true;
        debugPrint('ProgressService: débloqué → $next');
      }
    }

    // 5. Calculer streak
    final now = DateTime.now();
    final last = _student!.lastActivity;
    final diff = now.difference(last).inDays;
    final newStreak = diff <= 1 ? _student!.currentStreak + 1 : 1;

    // 6. Mettre à jour le Student
    _student = _student!.copyWith(
      totalStars: _student!.totalStars + bonusStars,
      currentStreak: newStreak,
      levelStars: updatedLevelStars,
      levelUnlocked: updatedUnlocked,
      lastActivity: now,
    );

    await _saveAll();

    // 7. Sync Firebase si connexion disponible
    _trySyncScore(gameScore);
    _trySyncStudent();

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // ACCESSEURS
  // ─────────────────────────────────────────────

  bool isUnlocked(String levelId) {
    if (levelId == 'cp-w1-alpha') return true;
    return _student?.levelUnlocked[levelId] ?? false;
  }

  int starsFor(String levelId) => _student?.levelStars[levelId] ?? 0;

  WordStat wordStatFor(int wordId) =>
      _wordStats.putIfAbsent(wordId, () => WordStat(wordId: wordId));

  /// Mots à réviser aujourd'hui (SM-2)
  List<int> dueWordIds() =>
      _wordStats.values.where((s) => s.isDue).map((s) => s.wordId).toList();

  /// Mots les plus difficiles (taux de succès le plus bas)
  List<WordStat> weakestWords({int top = 10}) {
    final list = _wordStats.values
        .where((s) => s.attempts >= 2)
        .toList()
      ..sort((a, b) => a.successRate.compareTo(b.successRate));
    return list.take(top).toList();
  }

  /// Score moyen par niveau (0-100)
  Map<String, double> avgScorePerLevel() {
    final map = <String, List<double>>{};
    for (final s in _scores) {
      map.putIfAbsent(s.levelId, () => []).add(s.percentage);
    }
    return map.map((k, v) =>
        MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  /// Dernières N parties
  List<GameScore> recentScores({int limit = 20}) =>
      _scores.reversed.take(limit).toList();

  // ─────────────────────────────────────────────
  // CONSTRUIRE LES ÎLES pour WorldMapScreen
  // ─────────────────────────────────────────────
  List<Island> buildIslands() {
    final total = _student?.totalStars ?? 0;

    final configs = [
      (
        id: 'cp',
        label: 'CP',
        emoji: '🌱',
        tagline: 'L\'alphabet, les couleurs, les animaux !',
        levels: 6,
        needed: 0,
        ids: [
          'cp-w1-alpha', 'cp-w2-numbers', 'cp-w3-colors',
          'cp-w4-greet', 'cp-w5-animals1', 'cp-w6-animals2',
        ],
      ),
      (
        id: 'ce1',
        label: 'CE1',
        emoji: '🌿',
        tagline: 'La famille, la nourriture, la météo !',
        levels: 3,
        needed: 10,
        ids: ['ce1-t1', 'ce1-t2', 'ce1-t3'],
      ),
      (
        id: 'ce2',
        label: 'CE2',
        emoji: '🌳',
        tagline: 'L\'école, la maison, les verbes !',
        levels: 3,
        needed: 18,
        ids: ['ce2-t1', 'ce2-t2', 'ce2-t3'],
      ),
      (
        id: 'cm1',
        label: 'CM1',
        emoji: '🦋',
        tagline: 'Les émotions, les métiers !',
        levels: 3,
        needed: 27,
        ids: ['cm1-t1', 'cm1-t2', 'cm1-t3'],
      ),
      (
        id: 'cm2',
        label: 'CM2',
        emoji: '🚀',
        tagline: 'Maître du français !',
        levels: 3,
        needed: 36,
        ids: ['cm2-t1', 'cm2-t2', 'cm2-t3'],
      ),
    ];

    return configs.map((c) {
      final earned = c.ids.fold(
        0,
        (sum, id) => sum + (_student?.levelStars[id] ?? 0),
      );
      return Island(
        id: c.id,
        label: c.label,
        emoji: c.emoji,
        tagline: c.tagline,
        totalLevels: c.levels,
        isUnlocked: total >= c.needed || c.id == 'cp',
        starsEarned: earned,
        starsToUnlock: c.needed,
      );
    }).toList();
  }

  // ─────────────────────────────────────────────
  // PRIVÉ
  // ─────────────────────────────────────────────

  static const _levelOrder = [
    'cp-w1-alpha', 'cp-w2-numbers', 'cp-w3-colors',
    'cp-w4-greet', 'cp-w5-animals1', 'cp-w6-animals2',
    'ce1-t1', 'ce1-t2', 'ce1-t3',
    'ce2-t1', 'ce2-t2', 'ce2-t3',
    'cm1-t1', 'cm1-t2', 'cm1-t3',
    'cm2-t1', 'cm2-t2', 'cm2-t3',
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
    await prefs.setString(
      _keyScores,
      jsonEncode(_scores.map((s) => s.toJson()).toList()),
    );
    await prefs.setString(
      _keyWordStats,
      jsonEncode(
        _wordStats.map((k, v) => MapEntry(k.toString(), v.toJson())),
      ),
    );
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
    } catch (e) {
      debugPrint('ProgressService: sync score fail: $e');
    }
  }

  Future<void> _trySyncStudent() async {
    if (_student == null) return;
    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn.contains(ConnectivityResult.none)) return;
      await FirebaseService().syncStudent(_student!);
    } catch (e) {
      debugPrint('ProgressService: sync student fail: $e');
    }
  }
}