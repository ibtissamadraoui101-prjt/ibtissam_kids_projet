class Word {
  final int id;
  final String mot;
  final String imagePath;
  final String audioPath;
  final String traductionArabe; // Traduction en arabe littéral (au lieu de darija)

  Word({
    required this.id,
    required this.mot,
    required this.imagePath,
    required this.audioPath,
    required this.traductionArabe,
  });

  // Constructeur pour copier l'objet et modifier certains champs
  Word copyWith({
    int? id,
    String? mot,
    String? imagePath,
    String? audioPath,
    String? traductionArabe,
  }) {
    return Word(
      id: id ?? this.id,
      mot: mot ?? this.mot,
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      traductionArabe: traductionArabe ?? this.traductionArabe,
    );
  }

  @override
  String toString() {
    return 'Word(id: $id, mot: $mot, arabe: $traductionArabe)';
  }
}