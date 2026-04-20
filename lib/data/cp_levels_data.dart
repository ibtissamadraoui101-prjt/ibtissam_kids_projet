// lib/data/cp_levels_data.dart
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class CPLevelsProvider {
  static List<GameLevelData> getAllCPLevels() => [
    getWeek1Alphabet(),
    getWeek2Numbers(),
    getWeek3Colors(),
    getWeek4Greetings(),
    getWeek5Animals1(),
    getWeek6Animals2(),
  ];

  static GameLevelData getWeek1Alphabet() => GameLevelData(
    id: 'cp-w1-alpha', title: "L'Alphabet", description: 'Apprends les lettres A à Z !',
    level: GameLevel.cp, progression: 1, difficulty: Difficulty.easy, estimatedDuration: 30,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Alphabet', vocabulary: _alphabet(),
  );

  static GameLevelData getWeek2Numbers() => GameLevelData(
    id: 'cp-w2-numbers', title: 'Les Chiffres 1-10', description: 'Compte de 1 à 10 !',
    level: GameLevel.cp, progression: 2, difficulty: Difficulty.easy, estimatedDuration: 25,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Chiffres', vocabulary: _numbers(),
  );

  static GameLevelData getWeek3Colors() => GameLevelData(
    id: 'cp-w3-colors', title: 'Les Couleurs', description: 'Découvre les couleurs !',
    level: GameLevel.cp, progression: 3, difficulty: Difficulty.easy, estimatedDuration: 25,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Couleurs', vocabulary: _colors(),
  );

  static GameLevelData getWeek4Greetings() => GameLevelData(
    id: 'cp-w4-greet', title: 'Les Salutations', description: 'Apprends à être poli !',
    level: GameLevel.cp, progression: 4, difficulty: Difficulty.easy, estimatedDuration: 20,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Salutations', vocabulary: _greetings(),
  );

  static GameLevelData getWeek5Animals1() => GameLevelData(
    id: 'cp-w5-animals1', title: 'Les Animaux (1)', description: 'Découvre les animaux !',
    level: GameLevel.cp, progression: 5, difficulty: Difficulty.medium, estimatedDuration: 30,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Animaux', vocabulary: _animals1(),
  );

  static GameLevelData getWeek6Animals2() => GameLevelData(
    id: 'cp-w6-animals2', title: 'Les Animaux (2)', description: 'Plus d\'animaux !',
    level: GameLevel.cp, progression: 6, difficulty: Difficulty.medium, estimatedDuration: 30,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Animaux', vocabulary: _animals2(),
  );

  // ── Données ──────────────────────────────────────────────────────────────
  static List<Word> _alphabet() {
    final data = [
      [1,  'A', '🔤', 'ا', 'Avion'],
      [2,  'B', '🔤', 'ب', 'Ballon'],
      [3,  'C', '🔤', 'ج', 'Chat'],
      [4,  'D', '🔤', 'د', 'Dent'],
      [5,  'E', '🔤', 'ه', 'Étoile'],
      [6,  'F', '🔤', 'ف', 'Fleur'],
      [7,  'G', '🔤', 'ج', 'Girafe'],
      [8,  'H', '🔤', 'ح', 'Hibou'],
      [9,  'I', '🔤', 'ي', 'Île'],
      [10, 'J', '🔤', 'ج', 'Jardin'],
      [11, 'K', '🔤', 'ك', 'Koala'],
      [12, 'L', '🔤', 'ل', 'Lion'],
    ];
    return data.map((d) => Word(
      id: d[0] as int, word: d[1] as String, emoji: d[2] as String,
      traductionArabic: d[3] as String, traductionDarija: d[4] as String,
    )).toList();
  }

  static List<Word> _numbers() => [
    Word(id: 101, word: 'Un',     emoji: '1️⃣', traductionArabic: 'واحد'),
    Word(id: 102, word: 'Deux',   emoji: '2️⃣', traductionArabic: 'اثنان'),
    Word(id: 103, word: 'Trois',  emoji: '3️⃣', traductionArabic: 'ثلاثة'),
    Word(id: 104, word: 'Quatre', emoji: '4️⃣', traductionArabic: 'أربعة'),
    Word(id: 105, word: 'Cinq',   emoji: '5️⃣', traductionArabic: 'خمسة'),
    Word(id: 106, word: 'Six',    emoji: '6️⃣', traductionArabic: 'ستة'),
    Word(id: 107, word: 'Sept',   emoji: '7️⃣', traductionArabic: 'سبعة'),
    Word(id: 108, word: 'Huit',   emoji: '8️⃣', traductionArabic: 'ثمانية'),
    Word(id: 109, word: 'Neuf',   emoji: '9️⃣', traductionArabic: 'تسعة'),
    Word(id: 110, word: 'Dix',    emoji: '🔟', traductionArabic: 'عشرة'),
  ];

  static List<Word> _colors() => [
    Word(id: 201, word: 'Rouge',  emoji: '🔴', traductionArabic: 'أحمر'),
    Word(id: 202, word: 'Bleu',   emoji: '🔵', traductionArabic: 'أزرق'),
    Word(id: 203, word: 'Jaune',  emoji: '🟡', traductionArabic: 'أصفر'),
    Word(id: 204, word: 'Vert',   emoji: '🟢', traductionArabic: 'أخضر'),
    Word(id: 205, word: 'Orange', emoji: '🟠', traductionArabic: 'برتقالي'),
    Word(id: 206, word: 'Rose',   emoji: '🌸', traductionArabic: 'وردي'),
    Word(id: 207, word: 'Noir',   emoji: '⚫', traductionArabic: 'أسود'),
    Word(id: 208, word: 'Blanc',  emoji: '⚪', traductionArabic: 'أبيض'),
    Word(id: 209, word: 'Gris',   emoji: '🩶', traductionArabic: 'رمادي'),
    Word(id: 210, word: 'Marron', emoji: '🟤', traductionArabic: 'بني'),
  ];

  static List<Word> _greetings() => [
    Word(id: 301, word: 'Bonjour',       emoji: '👋', traductionArabic: 'صباح الخير',  traductionDarija: 'السلام عليكم'),
    Word(id: 302, word: 'Bonsoir',        emoji: '🌙', traductionArabic: 'مساء الخير',  traductionDarija: 'مساء الخير'),
    Word(id: 303, word: 'Bonne nuit',     emoji: '😴', traductionArabic: 'تصبح على خير', traductionDarija: 'تصبح على خير'),
    Word(id: 304, word: 'Au revoir',      emoji: '👋', traductionArabic: 'مع السلامة',  traductionDarija: 'في الودع'),
    Word(id: 305, word: 'S\'il te plaît', emoji: '🙏', traductionArabic: 'من فضلك',     traductionDarija: 'من فضلك'),
    Word(id: 306, word: 'Merci',          emoji: '😊', traductionArabic: 'شكراً',       traductionDarija: 'شكرا'),
    Word(id: 307, word: 'De rien',        emoji: '😄', traductionArabic: 'عفواً',       traductionDarija: 'عادي'),
    Word(id: 308, word: 'Excusez-moi',    emoji: '🙇', traductionArabic: 'اعذرني',      traductionDarija: 'عفاك'),
  ];

  static List<Word> _animals1() => [
    Word(id: 401, word: 'Chat',   emoji: '🐱', traductionArabic: 'قطة',   traductionDarija: 'قط',    correctSounds: ['miaou', 'meow']),
    Word(id: 402, word: 'Chien',  emoji: '🐶', traductionArabic: 'كلب',   traductionDarija: 'كلب',   correctSounds: ['ouaf', 'woof']),
    Word(id: 403, word: 'Vache',  emoji: '🐮', traductionArabic: 'بقرة',  traductionDarija: 'بقرة',  correctSounds: ['meuh', 'moo']),
    Word(id: 404, word: 'Cheval', emoji: '🐴', traductionArabic: 'حصان',  traductionDarija: 'حصان',  correctSounds: ['hiiii', 'neigh']),
    Word(id: 405, word: 'Poule',  emoji: '🐔', traductionArabic: 'دجاجة', traductionDarija: 'دجاجة', correctSounds: ['cot cot', 'cluck']),
    Word(id: 406, word: 'Lapin',  emoji: '🐰', traductionArabic: 'أرنب',  traductionDarija: 'أرنب'),
  ];

  static List<Word> _animals2() => [
    Word(id: 407, word: 'Canard', emoji: '🦆', traductionArabic: 'بطة',   traductionDarija: 'بطة',   correctSounds: ['coin coin', 'quack']),
    Word(id: 408, word: 'Mouton', emoji: '🐑', traductionArabic: 'خروف',  traductionDarija: 'خروف',  correctSounds: ['bêê', 'baa']),
    Word(id: 409, word: 'Cochon', emoji: '🐷', traductionArabic: 'خنزير', traductionDarija: 'خنزير', correctSounds: ['oink', 'groin']),
    Word(id: 410, word: 'Âne',    emoji: '🫏', traductionArabic: 'حمار',  traductionDarija: 'حمار',  correctSounds: ['hi han', 'bray']),
    Word(id: 411, word: 'Coq',    emoji: '🐓', traductionArabic: 'ديك',   traductionDarija: 'ديك',   correctSounds: ['cocorico']),
    Word(id: 412, word: 'Ferme',  emoji: '🏡', traductionArabic: 'مزرعة', traductionDarija: 'مزرعة'),
  ];
}

class CPProgressionHelper {
  static Color getWeekColor(int week) {
    switch (week) {
      case 1: return const Color(0xFF1565C0);
      case 2: return const Color(0xFF2E7D32);
      case 3: return const Color(0xFFE65100);
      case 4: return const Color(0xFF6A1B9A);
      case 5: return const Color(0xFFC62828);
      case 6: return const Color(0xFFEF6C00);
      default: return Colors.grey;
    }
  }
}