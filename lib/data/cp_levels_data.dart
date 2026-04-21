// lib/data/cp_levels_data.dart
// TOUTES les images CP liées aux vrais fichiers dans assets/images/cp/
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
    id: 'cp-w1-alpha',
    title: "L'Alphabet",
    description: 'Apprends les lettres A à L !',
    level: GameLevel.cp,
    progression: 1,
    difficulty: Difficulty.easy,
    estimatedDuration: 30,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Alphabet',
    vocabulary: _alphabet(),
  );

  static GameLevelData getWeek2Numbers() => GameLevelData(
    id: 'cp-w2-numbers',
    title: 'Les Chiffres 1-10',
    description: 'Compte de 1 à 10 !',
    level: GameLevel.cp,
    progression: 2,
    difficulty: Difficulty.easy,
    estimatedDuration: 25,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Chiffres',
    vocabulary: _numbers(),
  );

  static GameLevelData getWeek3Colors() => GameLevelData(
    id: 'cp-w3-colors',
    title: 'Les Couleurs',
    description: 'Découvre toutes les couleurs !',
    level: GameLevel.cp,
    progression: 3,
    difficulty: Difficulty.easy,
    estimatedDuration: 25,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Couleurs',
    vocabulary: _colors(),
  );

  static GameLevelData getWeek4Greetings() => GameLevelData(
    id: 'cp-w4-greet',
    title: 'Les Salutations',
    description: 'Apprends à être poli !',
    level: GameLevel.cp,
    progression: 4,
    difficulty: Difficulty.easy,
    estimatedDuration: 20,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Salutations',
    vocabulary: _greetings(),
  );

  static GameLevelData getWeek5Animals1() => GameLevelData(
    id: 'cp-w5-animals1',
    title: 'Les Animaux (1)',
    description: 'Les animaux de la ferme !',
    level: GameLevel.cp,
    progression: 5,
    difficulty: Difficulty.medium,
    estimatedDuration: 30,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Animaux',
    vocabulary: _animals1(),
  );

  static GameLevelData getWeek6Animals2() => GameLevelData(
    id: 'cp-w6-animals2',
    title: 'Les Animaux (2)',
    description: 'Encore plus d\'animaux !',
    level: GameLevel.cp,
    progression: 6,
    difficulty: Difficulty.medium,
    estimatedDuration: 30,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Animaux',
    vocabulary: _animals2(),
  );

  // ────────────────────────────────────────────────
  // VOCABULAIRE avec imagePath réels
  // ────────────────────────────────────────────────

  static List<Word> _alphabet() => [
    Word(id: 1,  word: 'A', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_a.png',
         traductionArabic: 'ا', traductionDarija: 'Avion'),
    Word(id: 2,  word: 'B', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_b.png',
         traductionArabic: 'ب', traductionDarija: 'Ballon'),
    Word(id: 3,  word: 'C', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_c.png',
         traductionArabic: 'ج', traductionDarija: 'Chat'),
    Word(id: 4,  word: 'D', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_d.png',
         traductionArabic: 'د', traductionDarija: 'Dent'),
    Word(id: 5,  word: 'E', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_e.png',
         traductionArabic: 'ه', traductionDarija: 'Étoile'),
    Word(id: 6,  word: 'F', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_f.png',
         traductionArabic: 'ف', traductionDarija: 'Fleur'),
    Word(id: 7,  word: 'G', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_g.png',
         traductionArabic: 'ج', traductionDarija: 'Girafe'),
    Word(id: 8,  word: 'H', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_h.png',
         traductionArabic: 'ح', traductionDarija: 'Hibou'),
    Word(id: 9,  word: 'I', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_i.png',
         traductionArabic: 'ي', traductionDarija: 'Île'),
    Word(id: 10, word: 'J', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_j.png',
         traductionArabic: 'ج', traductionDarija: 'Jardin'),
    Word(id: 11, word: 'K', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_k.png',
         traductionArabic: 'ك', traductionDarija: 'Koala'),
    Word(id: 12, word: 'L', emoji: '🔤',
         imagePath: 'assets/images/cp/alphabet_l.png',
         traductionArabic: 'ل', traductionDarija: 'Lion'),
  ];

  static List<Word> _numbers() => [
    Word(id: 101, word: 'Un',     emoji: '1️⃣',
         imagePath: 'assets/images/cp/number_1.png',
         traductionArabic: 'واحد'),
    Word(id: 102, word: 'Deux',   emoji: '2️⃣',
         imagePath: 'assets/images/cp/number_2.png',
         traductionArabic: 'اثنان'),
    Word(id: 103, word: 'Trois',  emoji: '3️⃣',
         imagePath: 'assets/images/cp/number_3.png',
         traductionArabic: 'ثلاثة'),
    Word(id: 104, word: 'Quatre', emoji: '4️⃣',
         imagePath: 'assets/images/cp/number_4.png',
         traductionArabic: 'أربعة'),
    Word(id: 105, word: 'Cinq',   emoji: '5️⃣',
         imagePath: 'assets/images/cp/number_5.png',
         traductionArabic: 'خمسة'),
    Word(id: 106, word: 'Six',    emoji: '6️⃣',
         imagePath: 'assets/images/cp/number_6.png',
         traductionArabic: 'ستة'),
    Word(id: 107, word: 'Sept',   emoji: '7️⃣',
         imagePath: 'assets/images/cp/number_7.png',
         traductionArabic: 'سبعة'),
    Word(id: 108, word: 'Huit',   emoji: '8️⃣',
         imagePath: 'assets/images/cp/number_8.png',
         traductionArabic: 'ثمانية'),
    Word(id: 109, word: 'Neuf',   emoji: '9️⃣',
         imagePath: 'assets/images/cp/number_9.png',
         traductionArabic: 'تسعة'),
    Word(id: 110, word: 'Dix',    emoji: '🔟',
         imagePath: 'assets/images/cp/number_10.png',
         traductionArabic: 'عشرة'),
  ];

  static List<Word> _colors() => [
    Word(id: 201, word: 'Rouge',  emoji: '🔴',
         imagePath: 'assets/images/cp/color_red.png',
         traductionArabic: 'أحمر'),
    Word(id: 202, word: 'Bleu',   emoji: '🔵',
         imagePath: 'assets/images/cp/color_blue.png',
         traductionArabic: 'أزرق'),
    Word(id: 203, word: 'Jaune',  emoji: '🟡',
         imagePath: 'assets/images/cp/color_yellow.png',
         traductionArabic: 'أصفر'),
    Word(id: 204, word: 'Vert',   emoji: '🟢',
         imagePath: 'assets/images/cp/color_green.png',
         traductionArabic: 'أخضر'),
    Word(id: 205, word: 'Orange', emoji: '🟠',
         imagePath: 'assets/images/cp/color_orange.png',
         traductionArabic: 'برتقالي'),
    Word(id: 206, word: 'Rose',   emoji: '🌸',
         imagePath: 'assets/images/cp/color_pink.png',
         traductionArabic: 'وردي'),
    Word(id: 207, word: 'Noir',   emoji: '⚫',
         imagePath: 'assets/images/cp/color_black.png',
         traductionArabic: 'أسود'),
    Word(id: 208, word: 'Blanc',  emoji: '⚪',
         imagePath: 'assets/images/cp/color_white.png',
         traductionArabic: 'أبيض'),
    Word(id: 209, word: 'Gris',   emoji: '🩶',
         imagePath: 'assets/images/cp/color_gray.png',
         traductionArabic: 'رمادي'),
    Word(id: 210, word: 'Marron', emoji: '🟤',
         imagePath: 'assets/images/cp/color_brown.png',
         traductionArabic: 'بني'),
  ];

  static List<Word> _greetings() => [
    Word(id: 301, word: 'Bonjour',        emoji: '👋',
         imagePath: 'assets/images/cp/greeting_hello.png',
         traductionArabic: 'صباح الخير',
         traductionDarija: 'السلام عليكم'),
    Word(id: 302, word: 'Bonsoir',        emoji: '🌙',
         imagePath: 'assets/images/cp/greeting_evening.png',
         traductionArabic: 'مساء الخير',
         traductionDarija: 'مساء الخير'),
    Word(id: 303, word: 'Bonne nuit',     emoji: '😴',
         imagePath: 'assets/images/cp/greeting_goodnight.png',
         traductionArabic: 'تصبح على خير',
         traductionDarija: 'تصبح على خير'),
    Word(id: 304, word: 'Au revoir',      emoji: '🤚',
         imagePath: 'assets/images/cp/greeting_goodbye.png',
         traductionArabic: 'مع السلامة',
         traductionDarija: 'في الودع'),
    Word(id: 305, word: "S'il te plaît",  emoji: '🙏',
         imagePath: 'assets/images/cp/greeting_please.png',
         traductionArabic: 'من فضلك',
         traductionDarija: 'من فضلك'),
    Word(id: 306, word: 'Merci',          emoji: '😊',
         imagePath: 'assets/images/cp/greeting_thanks.png',
         traductionArabic: 'شكراً',
         traductionDarija: 'شكرا'),
    Word(id: 307, word: 'De rien',        emoji: '😄',
         imagePath: 'assets/images/cp/greeting_welcome.png',
         traductionArabic: 'عفواً',
         traductionDarija: 'عادي'),
    Word(id: 308, word: 'Excusez-moi',    emoji: '🙇',
         imagePath: 'assets/images/cp/greeting_sorry.png',
         traductionArabic: 'اعذرني',
         traductionDarija: 'عفاك'),
  ];

  static List<Word> _animals1() => [
    Word(id: 401, word: 'Chat',   emoji: '🐱',
         imagePath: 'assets/images/cp/animal_cat.png',
         traductionArabic: 'قطة',   traductionDarija: 'قط',
         correctSounds: ['miaou', 'meow']),
    Word(id: 402, word: 'Chien',  emoji: '🐶',
         imagePath: 'assets/images/cp/animal_dog.png',
         traductionArabic: 'كلب',   traductionDarija: 'كلب',
         correctSounds: ['ouaf', 'woof']),
    Word(id: 403, word: 'Vache',  emoji: '🐮',
         imagePath: 'assets/images/cp/animal_cow.png',
         traductionArabic: 'بقرة',  traductionDarija: 'بقرة',
         correctSounds: ['meuh', 'moo']),
    Word(id: 404, word: 'Cheval', emoji: '🐴',
         imagePath: 'assets/images/cp/animal_horse.png',
         traductionArabic: 'حصان',  traductionDarija: 'حصان',
         correctSounds: ['hiiii', 'neigh']),
    Word(id: 405, word: 'Poule',  emoji: '🐔',
         imagePath: 'assets/images/cp/animal_chicken.png',
         traductionArabic: 'دجاجة', traductionDarija: 'دجاجة',
         correctSounds: ['cot cot', 'cluck']),
    Word(id: 406, word: 'Lapin',  emoji: '🐰',
         imagePath: 'assets/images/cp/animal_rabbit.png',
         traductionArabic: 'أرنب',  traductionDarija: 'أرنب'),
  ];

  static List<Word> _animals2() => [
    Word(id: 407, word: 'Canard', emoji: '🦆',
         imagePath: 'assets/images/cp/animal_duck.png',
         traductionArabic: 'بطة',   traductionDarija: 'بطة',
         correctSounds: ['coin coin', 'quack']),
    Word(id: 408, word: 'Mouton', emoji: '🐑',
         imagePath: 'assets/images/cp/animal_sheep.png',
         traductionArabic: 'خروف',  traductionDarija: 'خروف',
         correctSounds: ['bêê', 'baa']),
    Word(id: 409, word: 'Cochon', emoji: '🐷',
         imagePath: 'assets/images/cp/animal_pig.png',
         traductionArabic: 'خنزير', traductionDarija: 'خنزير',
         correctSounds: ['oink', 'groin']),
    Word(id: 410, word: 'Âne',    emoji: '🫏',
         imagePath: 'assets/images/cp/animal_donkey.png',
         traductionArabic: 'حمار',  traductionDarija: 'حمار',
         correctSounds: ['hi han', 'bray']),
    Word(id: 411, word: 'Coq',    emoji: '🐓',
         imagePath: 'assets/images/cp/animal_rooster.png',
         traductionArabic: 'ديك',   traductionDarija: 'ديك',
         correctSounds: ['cocorico']),
    Word(id: 412, word: 'Ferme',  emoji: '🏡',
         imagePath: 'assets/images/cp/farm.png',
         traductionArabic: 'مزرعة', traductionDarija: 'مزرعة'),
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