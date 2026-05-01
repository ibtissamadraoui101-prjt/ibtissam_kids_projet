// lib/screens/phrase_order_game_screen.dart
// 🔀 JEU "REMETS DANS L'ORDRE" — Communication écrite
//
// POURQUOI ?
//   Les élèves CP ne comprennent pas la structure d'une phrase française.
//   Ce jeu entraîne la logique syntaxique : sujet + verbe + complément.
//
// FONCTIONNEMENT :
//   • Les mots d'une phrase courte sont mélangés
//   • L'enfant les tape dans l'ordre (DraggableChip → zone de dépôt)
//   • Validation progressive : chaque mot cliqué va dans la zone
//   • TTS lit la phrase complète quand c'est juste
//   • Indice : la première lettre du premier mot est révélée si l'enfant bloque

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../services/sound_service.dart';
import '../services/adaptive_engine.dart';

// ─────────────────────────────────────────────
// Phrases statiques pour CP (à enrichir depuis Firestore)
// Structure : {mots mélangés} → {phrase correcte} + {image associée}
// ─────────────────────────────────────────────
class _Phrase {
  final List<String> words;     // mots dans l'ordre correct
  final String sentence;        // phrase complète pour TTS
  final String emoji;           // image/emoji de la phrase
  final String hint;            // indice en darija
  const _Phrase({
    required this.words,
    required this.sentence,
    required this.emoji,
    required this.hint,
  });
}

const _phrasesCP = [
  _Phrase(words: ['Le', 'chat', 'dort'], sentence: 'Le chat dort.', emoji: '🐱😴', hint: 'القط كيناس'),
  _Phrase(words: ['Je', 'mange', 'une', 'pomme'], sentence: 'Je mange une pomme.', emoji: '🍎', hint: 'كناكل تفاحة'),
  _Phrase(words: ['Le', 'chien', 'court'], sentence: 'Le chien court.', emoji: '🐶🏃', hint: 'الكلب كيجري'),
  _Phrase(words: ['Il', 'fait', 'beau'], sentence: 'Il fait beau.', emoji: '☀️', hint: 'الجو زوين'),
  _Phrase(words: ['La', 'fleur', 'est', 'rouge'], sentence: 'La fleur est rouge.', emoji: '🌹', hint: 'الوردة حمرا'),
  _Phrase(words: ['Maman', 'cuisine', 'le', 'dîner'], sentence: 'Maman cuisine le dîner.', emoji: '👩‍🍳', hint: 'ماما كتطيب العشا'),
  _Phrase(words: ['Le', 'soleil', 'brille'], sentence: 'Le soleil brille.', emoji: '🌟', hint: 'الشمس كتضوي'),
  _Phrase(words: ['Je', 'vais', 'à', "l'école"], sentence: "Je vais à l'école.", emoji: '🏫', hint: 'كنمشي للمدرسة'),
  _Phrase(words: ['Les', 'oiseaux', 'chantent'], sentence: 'Les oiseaux chantent.', emoji: '🐦🎵', hint: 'الطيور كيغنيو'),
  _Phrase(words: ['Papa', 'lit', 'le', 'journal'], sentence: 'Papa lit le journal.', emoji: '📰', hint: 'بابا كيقرا الجريدة'),
];

class PhraseOrderGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const PhraseOrderGameScreen({super.key, required this.levelData});
  @override
  State<PhraseOrderGameScreen> createState() => _PhraseOrderGameScreenState();
}

class _PhraseOrderGameScreenState extends State<PhraseOrderGameScreen>
    with TickerProviderStateMixin {

  late List<_Phrase> _phrases;
  int _currentIndex = 0;
  int _score = 0;
  int _errors = 0;
  int _hintUsed = 0;

  // État du jeu courant
  late List<String> _shuffled;      // mots mélangés disponibles
  late List<String?> _placed;       // mots placés dans la zone (null = vide)
  bool _isValidated = false;
  bool _isCorrect = false;

  // Animations
  late final AnimationController _successCtrl;
  late final Animation<double> _successAnim;
  late final AnimationController _shakeCtrl;
  late final Animation<Offset> _shakeAnim;

  Color get _lc => const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();

    _phrases = List.from(_phrasesCP)..shuffle(math.Random());

    _successCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _successAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.easeOutBack);

    _shakeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.02, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.02, 0), end: const Offset(0.02, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.02, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _initPhrase();
  }

  void _initPhrase() {
    final phrase = _phrases[_currentIndex];
    _shuffled = List.from(phrase.words)..shuffle(math.Random());
    _placed = List.filled(phrase.words.length, null);
    _isValidated = false;
    _isCorrect = false;
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Placer un mot dans la zone
  // ─────────────────────────────────────────────
  void _placeWord(String word) {
    if (_isValidated) return;

    // Trouver le premier emplacement vide
    final emptyIdx = _placed.indexWhere((w) => w == null);
    if (emptyIdx == -1) return;

    HapticFeedback.selectionClick();
    SoundService().play(SoundEffect.click);

    setState(() {
      _placed[emptyIdx] = word;
      _shuffled.remove(word);
    });

    // Vérifier automatiquement si tous les mots sont placés
    if (_placed.every((w) => w != null)) {
      Future.delayed(const Duration(milliseconds: 200), _validate);
    }
  }

  // Retirer un mot placé (remettre dans les disponibles)
  void _removeWord(int placedIdx) {
    if (_isValidated) return;
    final word = _placed[placedIdx];
    if (word == null) return;

    HapticFeedback.selectionClick();
    setState(() {
      _placed[placedIdx] = null;
      _shuffled.add(word);
      _shuffled.shuffle(math.Random());
    });
  }

  // ─────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────
  void _validate() {
    final phrase = _phrases[_currentIndex];
    final correct = _placed
        .asMap()
        .entries
        .every((e) => e.value == phrase.words[e.key]);

    setState(() {
      _isValidated = true;
      _isCorrect = correct;
    });

    if (correct) {
      HapticFeedback.mediumImpact();
      SoundService().play(SoundEffect.correct);
      _score += 10 - _hintUsed * 3;
      _successCtrl.forward(from: 0);
      TtsService().speak(phrase.sentence);
    } else {
      _errors++;
      HapticFeedback.vibrate();
      SoundService().play(SoundEffect.wrong);
      _shakeCtrl.forward(from: 0);
      TtsService().speak('Pas tout à fait ! Essaie encore.');
      // Remettre tous les mots pour réessayer
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _shuffled = List.from(phrase.words)..shuffle(math.Random());
            _placed = List.filled(phrase.words.length, null);
            _isValidated = false;
          });
        }
      });
    }
  }

  // ─────────────────────────────────────────────
  // Indice : révéler le premier mot
  // ─────────────────────────────────────────────
  void _showHint() {
    if (_isValidated) return;
    final phrase = _phrases[_currentIndex];
    final firstWord = phrase.words[0];

    HapticFeedback.selectionClick();
    _hintUsed++;

    // Placer automatiquement le premier mot correct
    if (_placed[0] == null) {
      setState(() {
        _placed[0] = firstWord;
        _shuffled.remove(firstWord);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('💡 Indice : commence par "$firstWord"'),
        backgroundColor: Colors.amber.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _nextPhrase() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _phrases.length;
      _hintUsed = 0;
    });
    _successCtrl.reset();
    _initPhrase();
  }

  @override
  Widget build(BuildContext context) {
    final phrase = _phrases[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF0A1628), _lc.withOpacity(0.8), const Color(0xFF0A1628)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(child: Column(children: [
          _buildHeader(),
          const SizedBox(height: 12),
          // Progression
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _phrases.length,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
              )),
          ),
          const SizedBox(height: 20),
          // Emoji + traduction darija
          Text(phrase.emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 6),
          Text(phrase.hint,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 20),

          // ── Zone de dépôt ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Mets les mots dans le bon ordre :',
                style: TextStyle(color: Colors.white70, fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),

          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) => FractionalTranslation(
                translation: _shakeAnim.value, child: child),
            child: _buildDropZone(phrase),
          ),

          const SizedBox(height: 24),

          // ── Mots disponibles ──
          if (!_isValidated || !_isCorrect)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 10, runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _shuffled.map((word) => _buildWordChip(word)).toList(),
              ),
            ),

          const Spacer(),

          // ── Boutons bas ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(children: [
              // Indice
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isValidated ? null : _showHint,
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: const Text('Indice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: BorderSide(color: Colors.amber.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Réécouter / Suivant
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCorrect
                      ? _nextPhrase
                      : () => TtsService().speak(phrase.sentence),
                  icon: Icon(_isCorrect ? Icons.arrow_forward : Icons.volume_up,
                      size: 18),
                  label: Text(_isCorrect ? 'Phrase suivante' : 'Écouter la phrase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCorrect ? Colors.green : Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ),
            ]),
          ),
        ])),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Text('🔀 Remets dans l\'ordre',
          style: TextStyle(color: Colors.white, fontSize: 16,
              fontWeight: FontWeight.w900),
          overflow: TextOverflow.ellipsis)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: Text('🎯 $_score pts',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    ]),
  );

  Widget _buildDropZone(_Phrase phrase) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isValidated
              ? (_isCorrect ? Colors.green.withOpacity(0.7)
              : Colors.orange.withOpacity(0.5))
              : Colors.white.withOpacity(0.2),
          width: _isValidated ? 2 : 1,
        ),
      ),
      child: Column(children: [
        // Slots de placement
        Wrap(
          spacing: 8, runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(phrase.words.length, (i) {
            final placedWord = _placed[i];
            return GestureDetector(
              onTap: placedWord != null ? () => _removeWord(i) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minWidth: 60, minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: placedWord != null
                      ? (_isValidated
                      ? (_isCorrect
                      ? Colors.green.withOpacity(0.3)
                      : (placedWord == phrase.words[i]
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2)))
                      : Colors.white.withOpacity(0.2))
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: placedWord != null
                        ? Colors.white.withOpacity(0.4)
                        : Colors.white.withOpacity(0.15),
                    width: placedWord != null ? 1.5 : 1,
                  ),
                ),
                child: Center(child: Text(
                  placedWord ?? '_____',
                  style: TextStyle(
                    color: placedWord != null ? Colors.white : Colors.white30,
                    fontSize: 16, fontWeight: FontWeight.bold,
                  ),
                )),
              ),
            );
          }),
        ),

        // Feedback
        if (_isValidated) ...[
          const SizedBox(height: 12),
          ScaleTransition(
            scale: _successAnim,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_isCorrect ? Icons.check_circle : Icons.info_outline,
                  color: _isCorrect ? Colors.greenAccent : Colors.orangeAccent,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                _isCorrect
                    ? '✅ Parfait ! "${phrase.sentence}"'
                    : '❌ La bonne phrase est : "${phrase.sentence}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isCorrect ? Colors.greenAccent : Colors.orangeAccent,
                  fontSize: 13, fontWeight: FontWeight.bold,
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildWordChip(String word) {
    return GestureDetector(
      onTap: () => _placeWord(word),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.4),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Text(word,
            style: const TextStyle(color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}