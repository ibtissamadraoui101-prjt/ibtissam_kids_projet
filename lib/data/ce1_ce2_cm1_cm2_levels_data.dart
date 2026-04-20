import '../models/game_models.dart';

// ============== CE1 DATA PROVIDER ==============
class CE1LevelsProvider {
  static List<GameLevelData> getAllCE1Levels() {
    return [
      getTrimestre1Animals(),
      getTrimestre2Family(),
      getTrimestre3Weather(),
    ];
  }

  static GameLevelData getTrimestre1Animals() {
    return GameLevelData(
      id: 'ce1-t1-animals',
      title: 'Animaux & Nourriture',
      description: 'Apprends les animaux et la nourriture!',
      level: GameLevel.ce1,
      progression: 1,
      vocabulary: _getAnimalsFoodWords(),
      difficulty: Difficulty.medium,
      estimatedDuration: 25,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'Animaux & Nourriture',
    );
  }

  static GameLevelData getTrimestre2Family() {
    return GameLevelData(
      id: 'ce1-t2-family',
      title: 'Famille & Jours',
      description: 'Découvre ta famille et les jours!',
      level: GameLevel.ce1,
      progression: 2,
      vocabulary: _getFamilyDaysWords(),
      difficulty: Difficulty.medium,
      estimatedDuration: 25,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'Famille & Jours',
    );
  }

  static GameLevelData getTrimestre3Weather() {
    return GameLevelData(
      id: 'ce1-t3-weather',
      title: 'Météo & Révision',
      description: 'Apprends la météo et révise!',
      level: GameLevel.ce1,
      progression: 3,
      vocabulary: _getWeatherWords(),
      difficulty: Difficulty.medium,
      estimatedDuration: 25,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'Météo',
    );
  }

  static List<Word> _getAnimalsFoodWords() {
    return [
      Word(id: 1, word: 'Pomme', imagePath: 'assets/images/ce1/apple.png', audioPath: 'assets/audios/ce1/apple.mp3', traductionArabic: 'تفاحة'),
      Word(id: 2, word: 'Pain', imagePath: 'assets/images/ce1/bread.png', audioPath: 'assets/audios/ce1/bread.mp3', traductionArabic: 'خبز'),
      Word(id: 3, word: 'Lait', imagePath: 'assets/images/ce1/milk.png', audioPath: 'assets/audios/ce1/milk.mp3', traductionArabic: 'حليب'),
      Word(id: 4, word: 'Fromage', imagePath: 'assets/images/ce1/cheese.png', audioPath: 'assets/audios/ce1/cheese.mp3', traductionArabic: 'جبن'),
      Word(id: 5, word: 'Oeuf', imagePath: 'assets/images/ce1/egg.png', audioPath: 'assets/audios/ce1/egg.mp3', traductionArabic: 'بيضة'),
      Word(id: 6, word: 'Viande', imagePath: 'assets/images/ce1/meat.png', audioPath: 'assets/audios/ce1/meat.mp3', traductionArabic: 'لحم'),
      Word(id: 7, word: 'Poisson', imagePath: 'assets/images/ce1/fish.png', audioPath: 'assets/audios/ce1/fish.mp3', traductionArabic: 'سمك'),
      Word(id: 8, word: 'Fruits', imagePath: 'assets/images/ce1/fruits.png', audioPath: 'assets/audios/ce1/fruits.mp3', traductionArabic: 'فواكه'),
    ];
  }

  static List<Word> _getFamilyDaysWords() {
    return [
      Word(id: 9, word: 'Maman', imagePath: 'assets/images/ce1/mother.png', audioPath: 'assets/audios/ce1/mother.mp3', traductionArabic: 'أم'),
      Word(id: 10, word: 'Papa', imagePath: 'assets/images/ce1/father.png', audioPath: 'assets/audios/ce1/father.mp3', traductionArabic: 'أب'),
      Word(id: 11, word: 'Frère', imagePath: 'assets/images/ce1/brother.png', audioPath: 'assets/audios/ce1/brother.mp3', traductionArabic: 'أخ'),
      Word(id: 12, word: 'Soeur', imagePath: 'assets/images/ce1/sister.png', audioPath: 'assets/audios/ce1/sister.mp3', traductionArabic: 'أخت'),
      Word(id: 13, word: 'Lundi', imagePath: 'assets/images/ce1/monday.png', audioPath: 'assets/audios/ce1/monday.mp3', traductionArabic: 'الاثنين'),
      Word(id: 14, word: 'Mardi', imagePath: 'assets/images/ce1/tuesday.png', audioPath: 'assets/audios/ce1/tuesday.mp3', traductionArabic: 'الثلاثاء'),
      Word(id: 15, word: 'Mercredi', imagePath: 'assets/images/ce1/wednesday.png', audioPath: 'assets/audios/ce1/wednesday.mp3', traductionArabic: 'الأربعاء'),
      Word(id: 16, word: 'Samedi', imagePath: 'assets/images/ce1/saturday.png', audioPath: 'assets/audios/ce1/saturday.mp3', traductionArabic: 'السبت'),
    ];
  }

  static List<Word> _getWeatherWords() {
    return [
      Word(id: 17, word: 'Soleil', imagePath: 'assets/images/ce1/sun.png', audioPath: 'assets/audios/ce1/sun.mp3', traductionArabic: 'شمس'),
      Word(id: 18, word: 'Pluie', imagePath: 'assets/images/ce1/rain.png', audioPath: 'assets/audios/ce1/rain.mp3', traductionArabic: 'مطر'),
      Word(id: 19, word: 'Nuage', imagePath: 'assets/images/ce1/cloud.png', audioPath: 'assets/audios/ce1/cloud.mp3', traductionArabic: 'سحابة'),
      Word(id: 20, word: 'Vent', imagePath: 'assets/images/ce1/wind.png', audioPath: 'assets/audios/ce1/wind.mp3', traductionArabic: 'ريح'),
      Word(id: 21, word: 'Neige', imagePath: 'assets/images/ce1/snow.png', audioPath: 'assets/audios/ce1/snow.mp3', traductionArabic: 'ثلج'),
      Word(id: 22, word: 'Froid', imagePath: 'assets/images/ce1/cold.png', audioPath: 'assets/audios/ce1/cold.mp3', traductionArabic: 'بارد'),
      Word(id: 23, word: 'Chaud', imagePath: 'assets/images/ce1/hot.png', audioPath: 'assets/audios/ce1/hot.mp3', traductionArabic: 'حار'),
      Word(id: 24, word: 'Arc-en-ciel', imagePath: 'assets/images/ce1/rainbow.png', audioPath: 'assets/audios/ce1/rainbow.mp3', traductionArabic: 'قوس قزح'),
    ];
  }
}

// ============== CE2 DATA PROVIDER ==============
class CE2LevelsProvider {
  static List<GameLevelData> getAllCE2Levels() {
    return [
      getTrimestre1School(),
      getTrimestre2Clothes(),
      getTrimestre3Verbs(),
    ];
  }

  static GameLevelData getTrimestre1School() {
    return GameLevelData(
      id: 'ce2-t1-school',
      title: 'École & Vêtements',
      description: 'Apprends les mots de l\'école!',
      level: GameLevel.ce2,
      progression: 1,
      vocabulary: _getSchoolClothesWords(),
      difficulty: Difficulty.medium,
      estimatedDuration: 30,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'École & Vêtements',
    );
  }

  static GameLevelData getTrimestre2Clothes() {
    return GameLevelData(
      id: 'ce2-t2-clothes',
      title: 'Maison & Pièces',
      description: 'Découvre les pièces de la maison!',
      level: GameLevel.ce2,
      progression: 2,
      vocabulary: _getHouseRoomsWords(),
      difficulty: Difficulty.medium,
      estimatedDuration: 30,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'Maison',
    );
  }

  static GameLevelData getTrimestre3Verbs() {
    return GameLevelData(
      id: 'ce2-t3-verbs',
      title: 'Être & Avoir',
      description: 'Apprends les verbes être et avoir!',
      level: GameLevel.ce2,
      progression: 3,
      vocabulary: _getVerbsWords(),
      difficulty: Difficulty.hard,
      estimatedDuration: 30,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'Verbes',
    );
  }

  static List<Word> _getSchoolClothesWords() {
    return List.generate(10, (i) => Word(
      id: 100 + i,
      word: ['Cahier', 'Stylo', 'Livre', 'Crayon', 'Gomme', 'Régle', 'Table', 'Chaise', 'Tableau', 'Classe'][i],
      imagePath: 'assets/images/ce2/school_${i}.png',
      audioPath: 'assets/audios/ce2/school_${i}.mp3',
      traductionArabic: 'كلمة',
    ));
  }

  static List<Word> _getHouseRoomsWords() {
    return List.generate(10, (i) => Word(
      id: 110 + i,
      word: ['Chambre', 'Cuisine', 'Salle à manger', 'Salon', 'Salle de bains', 'Escalier', 'Porte', 'Fenêtre', 'Mur', 'Toit'][i],
      imagePath: 'assets/images/ce2/house_${i}.png',
      audioPath: 'assets/audios/ce2/house_${i}.mp3',
      traductionArabic: 'كلمة',
    ));
  }

  static List<Word> _getVerbsWords() {
    return [
      Word(id: 120, word: 'Être', imagePath: 'assets/images/ce2/verb_be.png', audioPath: 'assets/audios/ce2/verb_be.mp3', traductionArabic: 'أن يكون'),
      Word(id: 121, word: 'Avoir', imagePath: 'assets/images/ce2/verb_have.png', audioPath: 'assets/audios/ce2/verb_have.mp3', traductionArabic: 'أن يملك'),
      Word(id: 122, word: 'Aller', imagePath: 'assets/images/ce2/verb_go.png', audioPath: 'assets/audios/ce2/verb_go.mp3', traductionArabic: 'أن يذهب'),
      Word(id: 123, word: 'Faire', imagePath: 'assets/images/ce2/verb_do.png', audioPath: 'assets/audios/ce2/verb_do.mp3', traductionArabic: 'أن يفعل'),
      Word(id: 124, word: 'Vouloir', imagePath: 'assets/images/ce2/verb_want.png', audioPath: 'assets/audios/ce2/verb_want.mp3', traductionArabic: 'أن يريد'),
      Word(id: 125, word: 'Pouvoir', imagePath: 'assets/images/ce2/verb_can.png', audioPath: 'assets/audios/ce2/verb_can.mp3', traductionArabic: 'أن يستطيع'),
      Word(id: 126, word: 'Devoir', imagePath: 'assets/images/ce2/verb_must.png', audioPath: 'assets/audios/ce2/verb_must.mp3', traductionArabic: 'أن يجب'),
      Word(id: 127, word: 'Savoir', imagePath: 'assets/images/ce2/verb_know.png', audioPath: 'assets/audios/ce2/verb_know.mp3', traductionArabic: 'أن يعرف'),
    ];
  }
}

// ============== CM1 DATA PROVIDER ==============
class CM1LevelsProvider {
  static List<GameLevelData> getAllCM1Levels() {
    return [
      getTrimestre1Description(),
      getTrimestre2Emotions(),
      getTrimestre3Jobs(),
    ];
  }

  static GameLevelData getTrimestre1Description() {
    return GameLevelData(
      id: 'cm1-t1-description',
      title: 'Description Physique',
      description: 'Apprends à décrire!',
      level: GameLevel.cm1,
      progression: 1,
      vocabulary: _getDescriptionWords(),
      difficulty: Difficulty.hard,
      estimatedDuration: 35,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'Description',
    );
  }

  static GameLevelData getTrimestre2Emotions() {
    return GameLevelData(
      id: 'cm1-t2-emotions',
      title: 'Émotions & Sentiments',
      description: 'Exprime tes émotions!',
      level: GameLevel.cm1,
      progression: 2,
      vocabulary: _getEmotionsWords(),
      difficulty: Difficulty.hard,
      estimatedDuration: 35,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'Émotions',
    );
  }

  static GameLevelData getTrimestre3Jobs() {
    return GameLevelData(
      id: 'cm1-t3-jobs',
      title: 'Métiers & Heure',
      description: 'Découvre les métiers!',
      level: GameLevel.cm1,
      progression: 3,
      vocabulary: _getJobsTimeWords(),
      difficulty: Difficulty.hard,
      estimatedDuration: 35,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'Métiers',
    );
  }

  static List<Word> _getDescriptionWords() {
    return List.generate(12, (i) => Word(
      id: 200 + i,
      word: ['Grand', 'Petit', 'Blond', 'Brun', 'Roux', 'Yeux bleus', 'Yeux verts', 'Cheveux longs', 'Cheveux courts', 'Mince', 'Gros', 'Fort'][i],
      imagePath: 'assets/images/cm1/description_${i}.png',
      audioPath: 'assets/audios/cm1/description_${i}.mp3',
      traductionArabic: 'كلمة',
    ));
  }

  static List<Word> _getEmotionsWords() {
    return List.generate(12, (i) => Word(
      id: 212 + i,
      word: ['Heureux', 'Triste', 'Fâché', 'Peur', 'Jaloux', 'Gêné', 'Surpris', 'Confus', 'Excité', 'Calme', 'Énervé', 'Amoureux'][i],
      imagePath: 'assets/images/cm1/emotions_${i}.png',
      audioPath: 'assets/audios/cm1/emotions_${i}.mp3',
      traductionArabic: 'كلمة',
    ));
  }

  static List<Word> _getJobsTimeWords() {
    return List.generate(12, (i) => Word(
      id: 224 + i,
      word: ['Docteur', 'Infirmier', 'Enseignant', 'Avocat', 'Ingénieur', 'Cuisinier', 'Pompier', 'Policier', 'Fermier', 'Pilote', 'Minuit', 'Midi'][i],
      imagePath: 'assets/images/cm1/jobs_${i}.png',
      audioPath: 'assets/audios/cm1/jobs_${i}.mp3',
      traductionArabic: 'كلمة',
    ));
  }
}

// ============== CM2 DATA PROVIDER ==============
class CM2LevelsProvider {
  static List<GameLevelData> getAllCM2Levels() {
    return [
      getTrimestre1PastTense(),
      getTrimestre2FutureTense(),
      getTrimestre3Expressions(),
    ];
  }

  static GameLevelData getTrimestre1PastTense() {
    return GameLevelData(
      id: 'cm2-t1-past',
      title: 'Passé Composé',
      description: 'Apprends le passé!',
      level: GameLevel.cm2,
      progression: 1,
      vocabulary: _getPastTenseWords(),
      difficulty: Difficulty.hard,
      estimatedDuration: 40,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'Passé Composé',
    );
  }

  static GameLevelData getTrimestre2FutureTense() {
    return GameLevelData(
      id: 'cm2-t2-future',
      title: 'Futur Proche',
      description: 'Parle de l\'avenir!',
      level: GameLevel.cm2,
      progression: 2,
      vocabulary: _getFutureTenseWords(),
      difficulty: Difficulty.hard,
      estimatedDuration: 40,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'Futur Proche',
    );
  }

  static GameLevelData getTrimestre3Expressions() {
    return GameLevelData(
      id: 'cm2-t3-expressions',
      title: 'Expressions Courantes',
      description: 'Expressions utiles!',
      level: GameLevel.cm2,
      progression: 3,
      vocabulary: _getCommonExpressionsWords(),
      difficulty: Difficulty.hard,
      estimatedDuration: 40,
      availableGames: [GameType.memory, GameType.quiz, GameType.bingo, GameType.parcours],
      theme: 'Expressions',
    );
  }

  static List<Word> _getPastTenseWords() {
    return List.generate(14, (i) => Word(
      id: 300 + i,
      word: ['J\'ai mangé', 'J\'ai joué', 'Je suis allé', 'J\'ai dormi', 'J\'ai lu', 'J\'ai écrit', 'J\'ai parlé', 'J\'ai travaillé', 'J\'ai étudié', 'J\'ai regardé', 'J\'ai écouté', 'J\'ai dansé', 'J\'ai chanté', 'J\'ai dessiné'][i],
      imagePath: 'assets/images/cm2/past_${i}.png',
      audioPath: 'assets/audios/cm2/past_${i}.mp3',
      traductionArabic: 'كلمة',
    ));
  }

  static List<Word> _getFutureTenseWords() {
    return List.generate(14, (i) => Word(
      id: 314 + i,
      word: ['Je vais manger', 'Je vais jouer', 'Je vais aller', 'Je vais dormir', 'Je vais lire', 'Je vais écrire', 'Je vais parler', 'Je vais travailler', 'Je vais étudier', 'Je vais regarder', 'Je vais écouter', 'Je vais danser', 'Je vais chanter', 'Je vais dessiner'][i],
      imagePath: 'assets/images/cm2/future_${i}.png',
      audioPath: 'assets/audios/cm2/future_${i}.mp3',
      traductionArabic: 'كلمة',
    ));
  }

  static List<Word> _getCommonExpressionsWords() {
    return [
      Word(id: 328, word: 'Comment allez-vous?', imagePath: 'assets/images/cm2/expr_1.png', audioPath: 'assets/audios/cm2/expr_1.mp3', traductionArabic: 'كيف حالك؟'),
      Word(id: 329, word: 'Je vais bien, merci', imagePath: 'assets/images/cm2/expr_2.png', audioPath: 'assets/audios/cm2/expr_2.mp3', traductionArabic: 'أنا بخير، شكراً'),
      Word(id: 330, word: 'Enchanté de vous rencontrer', imagePath: 'assets/images/cm2/expr_3.png', audioPath: 'assets/audios/cm2/expr_3.mp3', traductionArabic: 'يسعدني لقاؤك'),
      Word(id: 331, word: 'Je ne comprends pas', imagePath: 'assets/images/cm2/expr_4.png', audioPath: 'assets/audios/cm2/expr_4.mp3', traductionArabic: 'لا أفهم'),
      Word(id: 332, word: 'Pouvez-vous m\'aider?', imagePath: 'assets/images/cm2/expr_5.png', audioPath: 'assets/audios/cm2/expr_5.mp3', traductionArabic: 'هل يمكنك مساعدتي؟'),
      Word(id: 333, word: 'Excusez-moi', imagePath: 'assets/images/cm2/expr_6.png', audioPath: 'assets/audios/cm2/expr_6.mp3', traductionArabic: 'عفواً'),
      Word(id: 334, word: 'Où sont les toilettes?', imagePath: 'assets/images/cm2/expr_7.png', audioPath: 'assets/audios/cm2/expr_7.mp3', traductionArabic: 'أين الحمام؟'),
      Word(id: 335, word: 'Quel est votre nom?', imagePath: 'assets/images/cm2/expr_8.png', audioPath: 'assets/audios/cm2/expr_8.mp3', traductionArabic: 'ما اسمك؟'),
      Word(id: 336, word: 'Quelle heure est-il?', imagePath: 'assets/images/cm2/expr_9.png', audioPath: 'assets/audios/cm2/expr_9.mp3', traductionArabic: 'كم الساعة؟'),
      Word(id: 337, word: 'Je suis fatigué', imagePath: 'assets/images/cm2/expr_10.png', audioPath: 'assets/audios/cm2/expr_10.mp3', traductionArabic: 'أنا تعب'),
      Word(id: 338, word: 'Bonne journée!', imagePath: 'assets/images/cm2/expr_11.png', audioPath: 'assets/audios/cm2/expr_11.mp3', traductionArabic: 'يوم جميل!'),
      Word(id: 339, word: 'À bientôt!', imagePath: 'assets/images/cm2/expr_12.png', audioPath: 'assets/audios/cm2/expr_12.mp3', traductionArabic: 'إلى الحوار قريباً!'),
      Word(id: 340, word: 'Je suis content', imagePath: 'assets/images/cm2/expr_13.png', audioPath: 'assets/audios/cm2/expr_13.mp3', traductionArabic: 'أنا سعيد'),
      Word(id: 341, word: 'C\'est magnifique!', imagePath: 'assets/images/cm2/expr_14.png', audioPath: 'assets/audios/cm2/expr_14.mp3', traductionArabic: 'رائع جداً!'),
    ];
  }
}