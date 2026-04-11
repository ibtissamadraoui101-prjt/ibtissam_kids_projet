import '../models/word_model.dart'; 
List<Word> getMotsCP() {
  return [
    Word(
      id: 1,
      mot: 'chat',
      imagePath: 'assets/images/chat.png',
      audioPath: 'assets/audios/chat.mp3',
      traductionArabe: 'قط', // qitt (chat)
    ),
    Word(
      id: 2,
      mot: 'chien',
      imagePath: 'assets/images/chien.png',
      audioPath: 'assets/audios/chien.mp3',
      traductionArabe: 'كلب', // kalb (chien)
    ),
    Word(
      id: 3,
      mot: 'pomme',
      imagePath: 'assets/images/pomme.png',
      audioPath: 'assets/audios/pomme.mp3',
      traductionArabe: 'تفاحة', // tuffāḥa (pomme)
    ),
    Word(
      id: 4,
      mot: 'voiture',
      imagePath: 'assets/images/voiture.png',
      audioPath: 'assets/audios/voiture.mp3',
      traductionArabe: 'سيارة', // sayyāra (voiture)
    ),
    Word(
      id: 5,
      mot: 'école',
      imagePath: 'assets/images/ecole.png',
      audioPath: 'assets/audios/ecole.mp3',
      traductionArabe: 'مدرسة', // madrasa (école)
    ),
    Word(
      id: 6,
      mot: 'papa',
      imagePath: 'assets/images/papa.png',
      audioPath: 'assets/audios/papa.mp3',
      traductionArabe: 'أب', // ab (père)
    ),
  ];
}

// Fonction pour récupérer les données filtrées par niveau si besoin
List<Word> getMotsByNiveau(String niveau) {
  // Pour l'instant, on retourne tous les mots pour CP
  // À étendre pour CE1, CE2, CM1, CM2
  if (niveau == 'CP') {
    return getMotsCP();
  }
  return getMotsCP(); // Retour par défaut
}