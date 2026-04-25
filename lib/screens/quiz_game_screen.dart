// lib/screens/quiz_game_screen.dart
// Quiz game redesigné pour enfants :
// — 3 modes selon la difficulté adaptative
//   • Facile  : grande image → 2 choix texte
//   • Moyen   : mot+arabe  → 4 images à choisir
//   • Difficile: image+son → 4 choix texte
// — Animations d'entrée, feedback visuel immédiat
// — Vraies images depuis assets, emoji en fallback
// — Confettis à la victoire
// — Sauvegarde automatique dans ProgressService

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../services/tts_service.dart';
import '../services/progress_service.dart';
import '../services/adaptive_engine.dart';

// ─────────────────────────────────────────────────────────────
// Modèle d'une question
// ─────────────────────────────────────────────────────────────
class _Question {
  final Word correctWord;
  final List<Word> options; // mélangées, inclut correctWord
  final _QuizMode mode;

  const _Question({
    required this.correctWord,
    required this.options,
    required this.mode,
  });
}

enum _QuizMode { imageToWord, wordToImage, soundToWord }

// ─────────────────────────────────────────────────────────────
// Écran principal
// ─────────────────────────────────────────────────────────────
class QuizGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const QuizGameScreen({super.key, required this.levelData});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen>
    with TickerProviderStateMixin {
  late List<_Question> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int _errors = 0;
  String? _selectedId;
  bool _answered = false;
  late Stopwatch _sw;
  final _tts = TtsService();

  // Animations
  late AnimationController _cardCtrl;
  late Animation<double> _cardAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late AnimationController _confettiCtrl;
  late Animation<double> _confettiAnim;

  // Chrono par question
  late Stopwatch _questionSw;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();
    _questionSw = Stopwatch()..start();

    // Animation d'entrée de la carte
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _cardAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);

    // Animation de shake (mauvaise réponse)
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );

    // Animation de bounce (bonne réponse)
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut),
    );

    // Confettis victoire
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _confettiAnim = Tween<double>(begin: 0, end: 1).animate(_confettiCtrl);

    _buildQuestions();

    // Lire le premier mot après 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _announceCurrentQuestion();
    });
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _shakeCtrl.dispose();
    _bounceCtrl.dispose();
    _confettiCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  // ────────────────────────────────────────────────
  // Construction des questions
  // ────────────────────────────────────────────────
  void _buildQuestions() {
    final tier = AdaptiveEngine().tierForLevel(widget.levelData.id);
    final optionCount = AdaptiveEngine().quizOptions(tier);
    final vocab = AdaptiveEngine()
        .selectWords(widget.levelData.vocabulary, count: 10);

    final rng = math.Random();
    final all = widget.levelData.vocabulary;

    _questions = vocab.asMap().entries.map((entry) {
      final i = entry.key;
      final correct = entry.value;

      // Mode qui alterne : imageToWord → wordToImage → soundToWord
      _QuizMode mode;
      switch (tier) {
        case AdaptiveTier.easy:
          mode = _QuizMode.imageToWord;
          break;
        case AdaptiveTier.medium:
          mode = i % 2 == 0
              ? _QuizMode.imageToWord
              : _QuizMode.wordToImage;
          break;
        case AdaptiveTier.hard:
          final modes = _QuizMode.values;
          mode = modes[i % modes.length];
          break;
      }

      // Construire les options (correct + faux)
      final others = all
          .where((w) => w.id != correct.id)
          .toList()
        ..shuffle(rng);
      final opts = <Word>[correct, ...others.take(optionCount - 1)]
        ..shuffle(rng);

      return _Question(
        correctWord: correct,
        options: opts,
        mode: mode,
      );
    }).toList();
  }

  // ────────────────────────────────────────────────
  // Annonce vocale de la question
  // ────────────────────────────────────────────────
  void _announceCurrentQuestion() {
    if (_currentIndex >= _questions.length) return;
    final q = _questions[_currentIndex];
    switch (q.mode) {
      case _QuizMode.imageToWord:
        _tts.speak('Quel est ce mot ?');
        break;
      case _QuizMode.wordToImage:
        _tts.speak('Trouve l\'image pour : ${q.correctWord.word}');
        break;
      case _QuizMode.soundToWord:
        Future.delayed(const Duration(milliseconds: 400), () {
          _tts.speak(q.correctWord.word);
        });
        break;
    }
  }

  // ────────────────────────────────────────────────
  // Répondre
  // ────────────────────────────────────────────────
  void _onAnswer(String optionId, Word selectedWord) {
    if (_answered) return;

    final q = _questions[_currentIndex];
    final isCorrect = selectedWord.id == q.correctWord.id;
    final responseTime = _questionSw.elapsed.inMilliseconds / 1000.0;

    // Qualité SM-2
    final quality = AdaptiveEngine().computeQuality(
      isCorrect: isCorrect,
      responseTimeSeconds: responseTime,
    );

    setState(() {
      _selectedId = optionId;
      _answered = true;
      if (isCorrect) {
        _score += 10;
        _bounceCtrl.forward(from: 0);
        _tts.speak('Bravo ! ${q.correctWord.word}');
      } else {
        _errors++;
        _shakeCtrl.forward(from: 0);
        _tts.speak('La réponse est ${q.correctWord.word}');
      }
    });

    // Passer à la question suivante après 1.8s
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        _nextQuestion();
      } else {
        _finish(quality);
      }
    });
  }

  void _nextQuestion() {
    _cardCtrl.reset();
    setState(() {
      _currentIndex++;
      _selectedId = null;
      _answered = false;
      _questionSw.reset();
      _questionSw.start();
    });
    _cardCtrl.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _announceCurrentQuestion();
    });
  }

  void _finish(int lastQuality) {
    _sw.stop();

    ProgressService().recordScore(
      levelId: widget.levelData.id,
      gameType: 'quiz',
      score: _score,
      maxScore: _questions.length * 10,
      durationSeconds: _sw.elapsed.inSeconds,
      errorsCount: _errors,
    );

    _confettiCtrl.forward();
    _tts.speak(AdaptiveEngine().encouragementMessage(
      (_score * 100 ~/ (_questions.length * 10)),
    ));

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showVictoryDialog();
    });
  }

  void _showVictoryDialog() {
    final pct = (_score * 100 ~/ (_questions.length * 10));
    final stars = pct >= 80 ? 3 : pct >= 60 ? 2 : 1;
    final msg = AdaptiveEngine().encouragementMessage(pct);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 8),
              const Text(
                'Quiz terminé !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              // Étoiles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: i < stars
                        ? Colors.amber
                        : Colors.white.withOpacity(0.3),
                    size: 44,
                  ),
                )),
              ),
              const SizedBox(height: 16),
              // Message
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
              // Stats
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('✅', '$_score', 'pts'),
                    _statItem('❌', '$_errors', 'erreurs'),
                    _statItem('⏱', '${_sw.elapsed.inSeconds}s', 'temps'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continuer l\'aventure ! 🚀',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) => Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      );

  // ────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final q = _questions[_currentIndex];

    return WillPopScope(
      onWillPop: () async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('Quitter le quiz ?'),
                content: const Text('Ta progression sera perdue.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Continuer'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Quitter',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Fond dégradé festif vert
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A1628),
                    Color(0xFF1B5E20),
                    Color(0xFF2E7D32),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const _BgStars(),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildProgressBar(),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _cardAnim,
                      builder: (_, child) => FadeTransition(
                        opacity: _cardAnim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.3, 0),
                            end: Offset.zero,
                          ).animate(_cardAnim),
                          child: child,
                        ),
                      ),
                      child: _buildQuestion(q),
                    ),
                  ),
                ],
              ),
            ),
            // Confettis
            AnimatedBuilder(
              animation: _confettiAnim,
              builder: (_, __) => _ConfettiLayer(
                progress: _confettiAnim.value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 17),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('❓  Quiz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    )),
                Text(
                  widget.levelData.title,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
          // Score
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$_score pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Question N/total
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentIndex + 1}/${_questions.length}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _questions.isEmpty
                  ? 0
                  : (_currentIndex + 1) / _questions.length,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Question ${_currentIndex + 1} sur ${_questions.length}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 11),
              ),
              const Spacer(),
              if (_errors > 0)
                Text(
                  '$_errors ❌',
                  style: TextStyle(
                      color: Colors.red.shade300, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(_Question q) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Zone de la question (image ou mot)
          _buildQuestionZone(q),
          const SizedBox(height: 16),
          // Options de réponse
          _buildOptions(q),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // Zone de la question
  // ────────────────────────────────────────────────
  Widget _buildQuestionZone(_Question q) {
    switch (q.mode) {
      case _QuizMode.imageToWord:
        return _buildImageQuestion(q);
      case _QuizMode.wordToImage:
        return _buildWordQuestion(q);
      case _QuizMode.soundToWord:
        return _buildSoundQuestion(q);
    }
  }

  Widget _buildImageQuestion(_Question q) {
    final hasImage = q.correctWord.imagePath.isNotEmpty;
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (_, child) => Transform.scale(
        scale: _answered && _selectedId != null
            ? _bounceAnim.value
            : 1.0,
        child: child,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            // Instruction
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '🔍  Quel est ce mot ?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Grande image
            GestureDetector(
              onTap: () => _tts.speak(q.correctWord.word),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: hasImage
                          ? Image.asset(
                              q.correctWord.imagePath,
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(q.correctWord.emoji,
                                    style: const TextStyle(fontSize: 90)),
                              ),
                            )
                          : Center(
                              child: Text(q.correctWord.emoji,
                                  style:
                                      const TextStyle(fontSize: 90))),
                    ),
                    // Bouton son
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.volume_up,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordQuestion(_Question q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '🖼️  Trouve l\'image !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _tts.speak(q.correctWord.word),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    q.correctWord.word,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (q.correctWord.traductionArabic != null)
                    Text(
                      q.correctWord.traductionArabic!,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 18),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.volume_up,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text('Écouter',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundQuestion(_Question q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '👂  Écoute et réponds !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Gros bouton son
          GestureDetector(
            onTap: () => _tts.speak(q.correctWord.word),
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A1B9A).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up, color: Colors.white, size: 50),
                  SizedBox(height: 4),
                  Text('Écouter',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuie pour entendre le mot',
            style: TextStyle(
                color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // Options de réponse
  // ────────────────────────────────────────────────
  Widget _buildOptions(_Question q) {
    if (q.mode == _QuizMode.wordToImage) {
      return _buildImageOptions(q);
    }
    return _buildTextOptions(q);
  }

  // Options texte (mode imageToWord et soundToWord)
  Widget _buildTextOptions(_Question q) {
    return Column(
      children: q.options.map((opt) {
        final optId = opt.id.toString();
        final isSelected = _selectedId == optId;
        final isCorrect = opt.id == q.correctWord.id;

        Color bg;
        Color border;
        IconData? icon;

        if (!_answered) {
          bg = Colors.white.withOpacity(0.1);
          border = Colors.white.withOpacity(0.25);
          icon = null;
        } else if (isSelected && isCorrect) {
          bg = Colors.green.withOpacity(0.35);
          border = Colors.green;
          icon = Icons.check_circle;
        } else if (isSelected && !isCorrect) {
          bg = Colors.red.withOpacity(0.35);
          border = Colors.red;
          icon = Icons.cancel;
        } else if (isCorrect) {
          bg = Colors.green.withOpacity(0.2);
          border = Colors.green.withOpacity(0.6);
          icon = Icons.check_circle_outline;
        } else {
          bg = Colors.white.withOpacity(0.05);
          border = Colors.white.withOpacity(0.1);
          icon = null;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) {
              double offset = 0;
              if (isSelected && !isCorrect && _answered) {
                offset = math.sin(_shakeAnim.value * math.pi * 5) * 8;
              }
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: _answered ? null : () => _onAnswer(optId, opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 18),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: 1.5),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isCorrect ? Colors.green : Colors.red)
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    // Emoji du mot
                    Text(opt.emoji,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.word,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (opt.traductionArabic != null)
                            Text(
                              opt.traductionArabic!,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    if (icon != null)
                      Icon(icon,
                          color:
                              isCorrect ? Colors.green : Colors.red,
                          size: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Options image (mode wordToImage) — grille 2x2
  Widget _buildImageOptions(_Question q) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: q.options.map((opt) {
        final optId = opt.id.toString();
        final isSelected = _selectedId == optId;
        final isCorrect = opt.id == q.correctWord.id;
        final hasImage = opt.imagePath.isNotEmpty;

        Color border;
        Color overlay;

        if (!_answered) {
          border = Colors.white.withOpacity(0.25);
          overlay = Colors.transparent;
        } else if (isSelected && isCorrect) {
          border = Colors.green;
          overlay = Colors.green.withOpacity(0.25);
        } else if (isSelected && !isCorrect) {
          border = Colors.red;
          overlay = Colors.red.withOpacity(0.25);
        } else if (isCorrect) {
          border = Colors.green.withOpacity(0.6);
          overlay = Colors.green.withOpacity(0.1);
        } else {
          border = Colors.white.withOpacity(0.1);
          overlay = Colors.transparent;
        }

        return GestureDetector(
          onTap: _answered ? null : () => _onAnswer(optId, opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 2),
            ),
            child: Stack(
              children: [
                // Image ou emoji
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: hasImage
                              ? Image.asset(
                                  opt.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(opt.emoji,
                                        style: const TextStyle(
                                            fontSize: 52)),
                                  ),
                                )
                              : Center(
                                  child: Text(opt.emoji,
                                      style: const TextStyle(
                                          fontSize: 52))),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opt.word,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                // Overlay coloré
                if (overlay != Colors.transparent)
                  Container(
                    decoration: BoxDecoration(
                      color: overlay,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                // Icône résultat
                if (_answered && (isSelected || isCorrect))
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCorrect ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Étoiles de fond
// ─────────────────────────────────────────────────────────────
class _BgStars extends StatelessWidget {
  const _BgStars();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _StarPainter());
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.3);
    const pts = [
      [0.05, 0.03], [0.18, 0.01], [0.32, 0.06], [0.46, 0.02],
      [0.60, 0.05], [0.74, 0.01], [0.87, 0.07], [0.95, 0.03],
      [0.09, 0.13], [0.23, 0.16], [0.37, 0.11], [0.51, 0.15],
      [0.65, 0.10], [0.79, 0.14], [0.93, 0.12],
    ];
    for (final pt in pts) {
      canvas.drawCircle(
        Offset(size.width * pt[0], size.height * pt[1]),
        1.3,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
// Confettis
// ─────────────────────────────────────────────────────────────
class _ConfettiLayer extends StatelessWidget {
  final double progress;
  const _ConfettiLayer({required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _ConfettiPainter(progress: progress),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static const _colors = [
    Colors.red, Colors.blue, Colors.green,
    Colors.yellow, Colors.purple, Colors.orange,
    Colors.pink, Colors.cyan,
  ];

  const _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(77);
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final yBase = -30 + rng.nextDouble() * 40;
      final yEnd = size.height + 30;
      final y = yBase + (yEnd - yBase) * progress;
      final swing = math.sin(progress * 10 + i * 0.5) * 45;

      final paint = Paint()
        ..color = _colors[i % _colors.length]
            .withOpacity((1.0 - progress * 0.8).clamp(0, 1));

      canvas.save();
      canvas.translate(x + swing, y);
      canvas.rotate(progress * 9 + i * 0.25);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 11),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}