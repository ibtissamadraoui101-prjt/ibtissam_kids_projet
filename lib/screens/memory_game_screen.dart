import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import '../models/word_model.dart';
import '../data/mots_cp.dart';

class GameCard {
  final Word word;
  bool isFlipped;
  bool isMatched;
  int repetitionsSuccess;

  GameCard({
    required this.word,
    this.isFlipped = false,
    this.isMatched = false,
    this.repetitionsSuccess = 0,
  });
}

class MemoryGameScreen extends StatefulWidget {
  final String niveau;
  const MemoryGameScreen({super.key, required this.niveau});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late List<GameCard> cards;
  late stt.SpeechToText _speechToText;
  late List<Word> allWords;
  int score = 0;
  int moves = 0;
  GameCard? firstCard;
  GameCard? secondCard;
  bool isCheckingMatch = false;
  bool isSpeechInitialized = false;

  final List<String> encouragementMessages = [
    'Bravo !', 'Excellent !', 'Très bien !', 'Parfait !', 'Magnifique !', 'Super !',
  ];

  final List<String> finalEncouragementMessages = [
    'Tu as réussi ! La paire est gagnée !',
    'Bravo, tu maîtrises ce mot !',
    'Excellent travail !',
    'Tu progresses très bien !',
  ];

  @override
  void initState() {
    super.initState();
    allWords = getMotsCP();
    _initializeGame();
    _speechToText = stt.SpeechToText();
    _initializeSpeech();
  }

  void _initializeGame() {
    List<GameCard> tempCards = [];
    for (Word word in allWords) {
      tempCards.add(GameCard(word: word));
      tempCards.add(GameCard(word: word));
    }
    tempCards.shuffle();
    cards = tempCards;
  }

  Future<void> _initializeSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (error) => print('Erreur speech: $error'),
        onStatus: (status) => print('Statut: $status'),
      );
      if (available && mounted) {
        setState(() => isSpeechInitialized = true);
        print('✅ Reconnaissance vocale disponible');
      } else if (mounted) {
        _showErrorDialog(
          'Microphone non disponible',
          'La reconnaissance vocale n\'est pas disponible sur cet appareil.',
        );
      }
    } catch (e) {
      print('Erreur initialisation: $e');
      if (mounted) {
        _showErrorDialog('Erreur', 'Impossible d\'initialiser le microphone.');
      }
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  void _onCardTapped(int index) {
    if (isCheckingMatch || cards[index].isMatched || cards[index].isFlipped) return;

    setState(() => cards[index].isFlipped = true);

    if (firstCard == null) {
      firstCard = cards[index];
    } else if (secondCard == null && cards[index] != firstCard) {
      secondCard = cards[index];
      isCheckingMatch = true;
      moves++;
      Future.delayed(const Duration(milliseconds: 500), () => _checkMatch());
    }
  }

  void _checkMatch() {
    if (firstCard == null || secondCard == null) return;
    if (firstCard!.word.id == secondCard!.word.id) {
      _showMatchDialog(firstCard!.word);
    } else {
      setState(() {
        cards[cards.indexOf(firstCard!)].isFlipped = false;
        cards[cards.indexOf(secondCard!)].isFlipped = false;
        firstCard = null;
        secondCard = null;
        isCheckingMatch = false;
      });
    }
  }

  void _showMatchDialog(Word word) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.green[50],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text('Bravo !', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[700])),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!, width: 2),
              ),
              child: Image.asset(word.imagePath, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text('C\'est un ${word.mot}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  const Text('En arabe :', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(word.traductionArabe, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Maintenant, répète le mot 3 fois pour valider !',
                style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startVoiceValidation(word);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
            child: const Text('Commencer la répétition', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _startVoiceValidation(Word word) async {
    if (!isSpeechInitialized) {
      _showErrorDialog('Erreur', 'Microphone non disponible');
      return;
    }
    _showRepetitionDialog(word, 1);
  }

  void _showRepetitionDialog(Word word, int repetitionNumber) {
    if (repetitionNumber > 3) {
      _completeWordValidation(word);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RepetitionDialog(
        word: word,
        repetitionNumber: repetitionNumber,
        speechToText: _speechToText,
        isSpeechInitialized: isSpeechInitialized,
        onSuccess: () {
          Navigator.pop(dialogContext);
          _showRepetitionDialog(word, repetitionNumber + 1);
        },
        onRetry: () {
          Navigator.pop(dialogContext);
          _showRepetitionDialog(word, repetitionNumber);
        },
        onError: (message) {
          Navigator.pop(dialogContext);
          _showErrorDialog('Erreur', message);
        },
      ),
    );
  }

  void _completeWordValidation(Word word) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.green[100],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 32),
            const SizedBox(width: 8),
            Text('Paire validée !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[700])),
          ],
        ),
        content: Text(
          '${finalEncouragementMessages[DateTime.now().millisecond % finalEncouragementMessages.length]}\n\nTu as maîtrisé : ${word.mot} (${word.traductionArabe})',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markCardAsMatched(word);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
            child: const Text('Continuer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _markCardAsMatched(Word word) {
    setState(() {
      for (var card in cards) {
        if (card.word.id == word.id) {
          card.isMatched = true;
          card.isFlipped = false;
          card.repetitionsSuccess = 3;
        }
      }
      score++;
      firstCard = null;
      secondCard = null;
      isCheckingMatch = false;
    });
    if (cards.every((card) => card.isMatched)) _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.amber[50],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, color: Colors.amber[700], size: 32),
            const SizedBox(width: 8),
            Text('Félicitations !', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber[700])),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tu as terminé le jeu !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Points : $score', style: const TextStyle(fontSize: 16)),
            Text('Coups : $moves', style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
            child: const Text('Retour', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory - ${widget.niveau}'),
        backgroundColor: Colors.blue[600],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('Points: $score   Coups: $moves')),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) => _buildCard(cards[index], index),
      ),
    );
  }

  Widget _buildCard(GameCard card, int index) {
    return GestureDetector(
      onTap: () => _onCardTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isMatched ? Colors.green[200] : (card.isFlipped ? Colors.blue[200] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: card.isMatched ? Colors.green[600]! : Colors.grey[400]!, width: 2),
        ),
        child: AnimatedOpacity(
          opacity: (card.isFlipped || card.isMatched) ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: (card.isFlipped || card.isMatched)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(card.word.imagePath, fit: BoxFit.cover),
                )
              : Center(child: Icon(Icons.help_outline, size: 40, color: Colors.grey[600])),
        ),
      ),
    );
  }
}

// ===================== DIALOGUE DE RÉPÉTITION INDÉPENDANT (CORRIGÉ) =====================
class _RepetitionDialog extends StatefulWidget {
  final Word word;
  final int repetitionNumber;
  final stt.SpeechToText speechToText;
  final bool isSpeechInitialized;
  final VoidCallback onSuccess;
  final VoidCallback onRetry;
  final Function(String) onError;

  const _RepetitionDialog({
    required this.word,
    required this.repetitionNumber,
    required this.speechToText,
    required this.isSpeechInitialized,
    required this.onSuccess,
    required this.onRetry,
    required this.onError,
  });

  @override
  State<_RepetitionDialog> createState() => _RepetitionDialogState();
}

class _RepetitionDialogState extends State<_RepetitionDialog> {
  bool isListening = false;
  Timer? _listenTimer;

  final List<String> retryMessages = [
    'Ce n\'est pas grave, réessaie !',
    'Presque ! Écoute bien et réessaie.',
    'On réessaie ? Tu vas y arriver !',
    'Pas tout à fait, on y va une autre fois !',
    'Ne te décourage pas, réessaie !',
  ];

  final List<String> encouragementMessages = [
    'Bravo !', 'Excellent !', 'Très bien !', 'Parfait !', 'Magnifique !', 'Super !',
  ];

  @override
  void dispose() {
    _listenTimer?.cancel();
    widget.speechToText.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!widget.isSpeechInitialized || isListening) return;

    setState(() => isListening = true);
    print('🎤 Début écoute pour: ${widget.word.mot}');

    // Timeout global de 8 secondes
    _listenTimer = Timer(const Duration(seconds: 8), () async {
      if (isListening) {
        print('⏱️ Timeout');
        await _stopListening();
        _showMessage('Le délai est dépassé, réessaie !', Colors.orange);
        widget.onRetry();
      }
    });

    try {
      await widget.speechToText.listen(
        onResult: (result) {
          print('📢 Résultat brut: "${result.recognizedWords}" (final: ${result.finalResult})');
          if (result.finalResult && mounted) {
            _stopListening();
            String recognized = result.recognizedWords.toLowerCase().trim();
            print('🎤 Mot reconnu: "$recognized" attendu: "${widget.word.mot}"');

            if (_compareWords(recognized, widget.word.mot.toLowerCase())) {
              String msg = encouragementMessages[DateTime.now().millisecond % encouragementMessages.length];
              _showMessage('$msg Tu as réussi la répétition ${widget.repetitionNumber}/3 !', Colors.green);
              Navigator.pop(context);
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) widget.onSuccess();
              });
            } else {
              String msg = retryMessages[DateTime.now().millisecond % retryMessages.length];
              _showMessage(msg, Colors.orange);
              Navigator.pop(context);
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) widget.onRetry();
              });
            }
          }
        },
        onSoundLevelChange: (level) {
          print('🎙️ Niveau sonore: $level');
        },
        localeId: 'fr',      // Chrome accepte 'fr' mieux que 'fr_FR'
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: false,
      );
    } catch (e) {
      print('❌ Erreur listen: $e');
      _stopListening();
      widget.onError('Problème technique, réessaie');
      widget.onRetry();
    }
  }

  Future<void> _stopListening() async {
    _listenTimer?.cancel();
    if (isListening) {
      await widget.speechToText.stop();
      if (mounted) setState(() => isListening = false);
      print('🛑 Écoute arrêtée');
    }
  }

  void _showMessage(String msg, Color color) {
    if (mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
        );
      } catch (e) {
        print('⚠️ Cannot show message: $e');
      }
    }
  }

  bool _compareWords(String recognized, String expected) {
    String norm1 = _normalizeString(recognized);
    String norm2 = _normalizeString(expected);
    bool match = norm1.contains(norm2) || norm2.contains(norm1);
    print('Comparaison: "$norm1" vs "$norm2" => $match');
    return match;
  }

  String _normalizeString(String str) {
    const accents = 'àâäæçéèêëìîïòôöœùûüñ';
    const base = 'aaaaaaceeeeiioooeuuun';
    String result = str.toLowerCase();
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], base[i]);
    }
    return result.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.blue[50],
      title: Text('Répétition ${widget.repetitionNumber}/3',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[700])),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(12)),
            child: Text(widget.word.mot, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          const SizedBox(height: 20),
          Text(
            isListening ? '🎙️ J\'écoute... Parle maintenant !' : 'Appuie sur le bouton et dis le mot !',
            style: TextStyle(fontSize: 14, color: isListening ? Colors.red[600] : Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          if (isListening)
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 6,
                  height: (i * 8 + 20).toDouble(),
                  decoration: BoxDecoration(color: Colors.red[600], borderRadius: BorderRadius.circular(3)),
                )),
              ),
            ),
        ],
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: isListening ? _stopListening : _startListening,
          icon: Icon(isListening ? Icons.stop : Icons.mic),
          label: Text(isListening ? 'Arrêter' : 'Écouter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isListening ? Colors.red[600] : Colors.blue[600],
          ),
        ),
      ],
    );
  }
}