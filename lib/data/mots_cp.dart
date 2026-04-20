// lib/data/ce1_ce2_cm1_cm2_levels_data.dart
import '../models/game_models.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CE1
// ══════════════════════════════════════════════════════════════════════════════
class CE1LevelsProvider {
  static List<GameLevelData> getAllCE1Levels() => [t1(), t2(), t3()];

  static GameLevelData t1() => GameLevelData(
    id: 'ce1-t1', title: 'Animaux & Nourriture', description: 'La nourriture et les animaux !',
    level: GameLevel.ce1, progression: 1, difficulty: Difficulty.medium, estimatedDuration: 25,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Nourriture', vocabulary: _food(),
  );

  static GameLevelData t2() => GameLevelData(
    id: 'ce1-t2', title: 'Famille & Jours', description: 'La famille et les jours de la semaine !',
    level: GameLevel.ce1, progression: 2, difficulty: Difficulty.medium, estimatedDuration: 25,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Famille', vocabulary: _family(),
  );

  static GameLevelData t3() => GameLevelData(
    id: 'ce1-t3', title: 'La Météo', description: 'Le temps qu\'il fait !',
    level: GameLevel.ce1, progression: 3, difficulty: Difficulty.medium, estimatedDuration: 25,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Météo', vocabulary: _weather(),
  );

  static List<Word> _food() => [
    Word(id: 1,  word: 'Pomme',   emoji: '🍎', traductionArabic: 'تفاحة'),
    Word(id: 2,  word: 'Pain',    emoji: '🍞', traductionArabic: 'خبز'),
    Word(id: 3,  word: 'Lait',    emoji: '🥛', traductionArabic: 'حليب'),
    Word(id: 4,  word: 'Fromage', emoji: '🧀', traductionArabic: 'جبن'),
    Word(id: 5,  word: 'Œuf',     emoji: '🥚', traductionArabic: 'بيضة'),
    Word(id: 6,  word: 'Viande',  emoji: '🥩', traductionArabic: 'لحم'),
    Word(id: 7,  word: 'Poisson', emoji: '🐟', traductionArabic: 'سمك'),
    Word(id: 8,  word: 'Orange',  emoji: '🍊', traductionArabic: 'برتقالة'),
  ];

  static List<Word> _family() => [
    Word(id: 9,  word: 'Maman',    emoji: '👩', traductionArabic: 'أم'),
    Word(id: 10, word: 'Papa',     emoji: '👨', traductionArabic: 'أب'),
    Word(id: 11, word: 'Frère',    emoji: '👦', traductionArabic: 'أخ'),
    Word(id: 12, word: 'Sœur',     emoji: '👧', traductionArabic: 'أخت'),
    Word(id: 13, word: 'Lundi',    emoji: '📅', traductionArabic: 'الاثنين'),
    Word(id: 14, word: 'Mardi',    emoji: '📅', traductionArabic: 'الثلاثاء'),
    Word(id: 15, word: 'Mercredi', emoji: '📅', traductionArabic: 'الأربعاء'),
    Word(id: 16, word: 'Samedi',   emoji: '📅', traductionArabic: 'السبت'),
  ];

  static List<Word> _weather() => [
    Word(id: 17, word: 'Soleil',      emoji: '☀️',  traductionArabic: 'شمس'),
    Word(id: 18, word: 'Pluie',       emoji: '🌧️',  traductionArabic: 'مطر'),
    Word(id: 19, word: 'Nuage',       emoji: '☁️',  traductionArabic: 'سحابة'),
    Word(id: 20, word: 'Vent',        emoji: '💨',  traductionArabic: 'ريح'),
    Word(id: 21, word: 'Neige',       emoji: '❄️',  traductionArabic: 'ثلج'),
    Word(id: 22, word: 'Froid',       emoji: '🥶',  traductionArabic: 'بارد'),
    Word(id: 23, word: 'Chaud',       emoji: '🌡️',  traductionArabic: 'حار'),
    Word(id: 24, word: 'Arc-en-ciel', emoji: '🌈',  traductionArabic: 'قوس قزح'),
  ];
}

// ══════════════════════════════════════════════════════════════════════════════
// CE2
// ══════════════════════════════════════════════════════════════════════════════
class CE2LevelsProvider {
  static List<GameLevelData> getAllCE2Levels() => [t1(), t2(), t3()];

  static GameLevelData t1() => GameLevelData(
    id: 'ce2-t1', title: "L'École", description: 'Le vocabulaire de la classe !',
    level: GameLevel.ce2, progression: 1, difficulty: Difficulty.medium, estimatedDuration: 30,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'École', vocabulary: _school(),
  );

  static GameLevelData t2() => GameLevelData(
    id: 'ce2-t2', title: 'La Maison', description: 'Les pièces de la maison !',
    level: GameLevel.ce2, progression: 2, difficulty: Difficulty.medium, estimatedDuration: 30,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Maison', vocabulary: _house(),
  );

  static GameLevelData t3() => GameLevelData(
    id: 'ce2-t3', title: 'Être & Avoir', description: 'Les verbes essentiels !',
    level: GameLevel.ce2, progression: 3, difficulty: Difficulty.hard, estimatedDuration: 30,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Verbes', vocabulary: _verbs(),
  );

  static List<Word> _school() => [
    Word(id: 100, word: 'Cahier',  emoji: '📓', traductionArabic: 'دفتر'),
    Word(id: 101, word: 'Stylo',   emoji: '🖊️', traductionArabic: 'قلم'),
    Word(id: 102, word: 'Livre',   emoji: '📚', traductionArabic: 'كتاب'),
    Word(id: 103, word: 'Crayon',  emoji: '✏️', traductionArabic: 'قلم رصاص'),
    Word(id: 104, word: 'Gomme',   emoji: '🟥', traductionArabic: 'ممحاة'),
    Word(id: 105, word: 'Règle',   emoji: '📏', traductionArabic: 'مسطرة'),
    Word(id: 106, word: 'Table',   emoji: '🪑', traductionArabic: 'طاولة'),
    Word(id: 107, word: 'Tableau', emoji: '🖥️', traductionArabic: 'لوحة'),
  ];

  static List<Word> _house() => [
    Word(id: 110, word: 'Chambre',       emoji: '🛏️', traductionArabic: 'غرفة النوم'),
    Word(id: 111, word: 'Cuisine',       emoji: '🍳', traductionArabic: 'مطبخ'),
    Word(id: 112, word: 'Salon',         emoji: '🛋️', traductionArabic: 'صالون'),
    Word(id: 113, word: 'Salle de bain', emoji: '🚿', traductionArabic: 'حمام'),
    Word(id: 114, word: 'Porte',         emoji: '🚪', traductionArabic: 'باب'),
    Word(id: 115, word: 'Fenêtre',       emoji: '🪟', traductionArabic: 'نافذة'),
    Word(id: 116, word: 'Escalier',      emoji: '🪜', traductionArabic: 'درج'),
    Word(id: 117, word: 'Jardin',        emoji: '🌳', traductionArabic: 'حديقة'),
  ];

  static List<Word> _verbs() => [
    Word(id: 120, word: 'Être',    emoji: '🧍', traductionArabic: 'أن يكون'),
    Word(id: 121, word: 'Avoir',   emoji: '🤲', traductionArabic: 'أن يملك'),
    Word(id: 122, word: 'Aller',   emoji: '🚶', traductionArabic: 'أن يذهب'),
    Word(id: 123, word: 'Faire',   emoji: '🛠️', traductionArabic: 'أن يفعل'),
    Word(id: 124, word: 'Vouloir', emoji: '💭', traductionArabic: 'أن يريد'),
    Word(id: 125, word: 'Pouvoir', emoji: '💪', traductionArabic: 'أن يستطيع'),
    Word(id: 126, word: 'Devoir',  emoji: '📋', traductionArabic: 'يجب'),
    Word(id: 127, word: 'Savoir',  emoji: '🧠', traductionArabic: 'أن يعرف'),
  ];
}

// ══════════════════════════════════════════════════════════════════════════════
// CM1
// ══════════════════════════════════════════════════════════════════════════════
class CM1LevelsProvider {
  static List<GameLevelData> getAllCM1Levels() => [t1(), t2(), t3()];

  static GameLevelData t1() => GameLevelData(
    id: 'cm1-t1', title: 'Description Physique', description: 'Décris les personnes !',
    level: GameLevel.cm1, progression: 1, difficulty: Difficulty.hard, estimatedDuration: 35,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Description', vocabulary: _description(),
  );

  static GameLevelData t2() => GameLevelData(
    id: 'cm1-t2', title: 'Émotions', description: 'Exprime tes émotions !',
    level: GameLevel.cm1, progression: 2, difficulty: Difficulty.hard, estimatedDuration: 35,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Émotions', vocabulary: _emotions(),
  );

  static GameLevelData t3() => GameLevelData(
    id: 'cm1-t3', title: 'Les Métiers', description: 'Découvre les métiers !',
    level: GameLevel.cm1, progression: 3, difficulty: Difficulty.hard, estimatedDuration: 35,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Métiers', vocabulary: _jobs(),
  );

  static List<Word> _description() => [
    Word(id: 200, word: 'Grand',        emoji: '📏', traductionArabic: 'طويل'),
    Word(id: 201, word: 'Petit',        emoji: '🤏', traductionArabic: 'صغير'),
    Word(id: 202, word: 'Blond',        emoji: '👱', traductionArabic: 'أشقر'),
    Word(id: 203, word: 'Brun',         emoji: '🧑', traductionArabic: 'بني الشعر'),
    Word(id: 204, word: 'Mince',        emoji: '🧍', traductionArabic: 'نحيل'),
    Word(id: 205, word: 'Gros',         emoji: '🪆', traductionArabic: 'سمين'),
    Word(id: 206, word: 'Jeune',        emoji: '👶', traductionArabic: 'شاب'),
    Word(id: 207, word: 'Vieux',        emoji: '👴', traductionArabic: 'كبير السن'),
    Word(id: 208, word: 'Cheveux longs',emoji: '👩‍🦱', traductionArabic: 'شعر طويل'),
    Word(id: 209, word: 'Yeux bleus',   emoji: '👁️',  traductionArabic: 'عيون زرقاء'),
  ];

  static List<Word> _emotions() => [
    Word(id: 210, word: 'Heureux',  emoji: '😊', traductionArabic: 'سعيد'),
    Word(id: 211, word: 'Triste',   emoji: '😢', traductionArabic: 'حزين'),
    Word(id: 212, word: 'Fâché',    emoji: '😡', traductionArabic: 'غاضب'),
    Word(id: 213, word: 'Peur',     emoji: '😱', traductionArabic: 'خائف'),
    Word(id: 214, word: 'Surpris',  emoji: '😮', traductionArabic: 'متفاجئ'),
    Word(id: 215, word: 'Calme',    emoji: '😌', traductionArabic: 'هادئ'),
    Word(id: 216, word: 'Excité',   emoji: '🤩', traductionArabic: 'متحمس'),
    Word(id: 217, word: 'Jaloux',   emoji: '😒', traductionArabic: 'غيور'),
    Word(id: 218, word: 'Confus',   emoji: '😕', traductionArabic: 'مرتبك'),
    Word(id: 219, word: 'Amoureux', emoji: '🥰', traductionArabic: 'عاشق'),
  ];

  static List<Word> _jobs() => [
    Word(id: 220, word: 'Docteur',    emoji: '👨‍⚕️', traductionArabic: 'طبيب'),
    Word(id: 221, word: 'Enseignant', emoji: '👨‍🏫', traductionArabic: 'أستاذ'),
    Word(id: 222, word: 'Avocat',     emoji: '⚖️',  traductionArabic: 'محامي'),
    Word(id: 223, word: 'Ingénieur',  emoji: '👷',  traductionArabic: 'مهندس'),
    Word(id: 224, word: 'Cuisinier',  emoji: '👨‍🍳', traductionArabic: 'طباخ'),
    Word(id: 225, word: 'Pompier',    emoji: '🚒',  traductionArabic: 'رجل إطفاء'),
    Word(id: 226, word: 'Policier',   emoji: '👮',  traductionArabic: 'شرطي'),
    Word(id: 227, word: 'Pilote',     emoji: '✈️',  traductionArabic: 'طيار'),
  ];
}

// ══════════════════════════════════════════════════════════════════════════════
// CM2
// ══════════════════════════════════════════════════════════════════════════════
class CM2LevelsProvider {
  static List<GameLevelData> getAllCM2Levels() => [t1(), t2(), t3()];

  static GameLevelData t1() => GameLevelData(
    id: 'cm2-t1', title: 'Passé Composé', description: 'Parle du passé !',
    level: GameLevel.cm2, progression: 1, difficulty: Difficulty.hard, estimatedDuration: 40,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Passé', vocabulary: _past(),
  );

  static GameLevelData t2() => GameLevelData(
    id: 'cm2-t2', title: 'Futur Proche', description: 'Parle de l\'avenir !',
    level: GameLevel.cm2, progression: 2, difficulty: Difficulty.hard, estimatedDuration: 40,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Futur', vocabulary: _future(),
  );

  static GameLevelData t3() => GameLevelData(
    id: 'cm2-t3', title: 'Expressions Courantes', description: 'Expressions du quotidien !',
    level: GameLevel.cm2, progression: 3, difficulty: Difficulty.hard, estimatedDuration: 40,
    availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
    theme: 'Expressions', vocabulary: _expressions(),
  );

  static List<Word> _past() => [
    Word(id: 300, word: "J'ai mangé",    emoji: '🍽️', traductionArabic: 'أكلت'),
    Word(id: 301, word: "J'ai joué",     emoji: '🎮', traductionArabic: 'لعبت'),
    Word(id: 302, word: "Je suis allé",  emoji: '🚶', traductionArabic: 'ذهبت'),
    Word(id: 303, word: "J'ai dormi",    emoji: '😴', traductionArabic: 'نمت'),
    Word(id: 304, word: "J'ai lu",       emoji: '📖', traductionArabic: 'قرأت'),
    Word(id: 305, word: "J'ai écrit",    emoji: '✍️', traductionArabic: 'كتبت'),
    Word(id: 306, word: "J'ai parlé",    emoji: '💬', traductionArabic: 'تكلمت'),
    Word(id: 307, word: "J'ai travaillé",emoji: '💼', traductionArabic: 'عملت'),
  ];

  static List<Word> _future() => [
    Word(id: 310, word: 'Je vais manger',    emoji: '🍽️', traductionArabic: 'سآكل'),
    Word(id: 311, word: 'Je vais jouer',     emoji: '🎮', traductionArabic: 'سألعب'),
    Word(id: 312, word: 'Je vais aller',     emoji: '🚶', traductionArabic: 'سأذهب'),
    Word(id: 313, word: 'Je vais dormir',    emoji: '😴', traductionArabic: 'سأنام'),
    Word(id: 314, word: 'Je vais lire',      emoji: '📖', traductionArabic: 'سأقرأ'),
    Word(id: 315, word: 'Je vais écrire',    emoji: '✍️', traductionArabic: 'سأكتب'),
    Word(id: 316, word: 'Je vais travailler',emoji: '💼', traductionArabic: 'سأعمل'),
    Word(id: 317, word: 'Je vais étudier',   emoji: '📚', traductionArabic: 'سأدرس'),
  ];

  static List<Word> _expressions() => [
    Word(id: 320, word: 'Comment allez-vous ?',       emoji: '🤝', traductionArabic: 'كيف حالك؟'),
    Word(id: 321, word: 'Je vais bien, merci',         emoji: '😊', traductionArabic: 'أنا بخير، شكراً'),
    Word(id: 322, word: 'Je ne comprends pas',         emoji: '❓', traductionArabic: 'لا أفهم'),
    Word(id: 323, word: 'Pouvez-vous m\'aider ?',      emoji: '🙋', traductionArabic: 'هل يمكنك مساعدتي؟'),
    Word(id: 324, word: 'Quelle heure est-il ?',       emoji: '⏰', traductionArabic: 'كم الساعة؟'),
    Word(id: 325, word: 'Bonne journée !',              emoji: '🌟', traductionArabic: 'يوم جميل!'),
    Word(id: 326, word: 'Enchanté !',                  emoji: '🤝', traductionArabic: 'يسعدني لقاؤك'),
    Word(id: 327, word: "C'est magnifique !",          emoji: '😍', traductionArabic: 'رائع جداً!'),
  ];
}