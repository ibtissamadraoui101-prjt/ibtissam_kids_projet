import 'package:flutter/material.dart';

class SpeechService {
  // Pour l'instant, on simule la reconnaissance vocale avec une boîte de dialogue.
  // Plus tard, on remplacera par Google Speech-to-Text.
  static Future<bool> askToRepeatWord(BuildContext context, String word, String translationArabic) async {
    // Étape 1 : Dire "Très bien !"
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Très bien !'), duration: Duration(seconds: 1)),
    );
    await Future.delayed(const Duration(seconds: 1));

    // Étape 2 : Dire "c'est un chien" par exemple
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('C\'est un $word'), duration: const Duration(seconds: 2)),
    );
    await Future.delayed(const Duration(seconds: 2));

    // Étape 3 : Traduction en arabe
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('بالعربية : $translationArabic'), duration: const Duration(seconds: 2)),
    );
    await Future.delayed(const Duration(seconds: 2));

    // Étape 4 : Demander de répéter le mot
    bool success = false;
    int attempts = 0;
    while (!success && attempts < 3) {
      attempts++;
      final shouldRepeat = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Répète : $word'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic, size: 50),
              const SizedBox(height: 10),
              Text('Tente $attempts/3'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Je n\'y arrive pas'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('J\'ai dit !'),
            ),
          ],
        ),
      );
      if (shouldRepeat == true) {
        // Simuler une vérification aléatoire (à remplacer par vraie reconnaissance)
        final isCorrect = await _simulateRecognition(word);
        if (isCorrect) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Très bien !'), duration: Duration(seconds: 1)),
          );
          success = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Presque ! Réessaie gentiment'), duration: Duration(seconds: 2)),
          );
        }
      } else {
        // L'enfant a dit qu'il n'arrivait pas, on lui montre le mot et on réessaie
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Écoute : $word'), duration: const Duration(seconds: 2)),
        );
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    return success;
  }

  // Simulation de reconnaissance (à remplacer par API)
  static Future<bool> _simulateRecognition(String expectedWord) async {
    // Simuler une réussite 80% du temps pour le test
    await Future.delayed(const Duration(milliseconds: 500));
    return DateTime.now().millisecondsSinceEpoch % 5 != 0; // 80% de chances
  }
}