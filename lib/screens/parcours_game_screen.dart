// lib/screens/parcours_game_screen.dart
// Parcours festif pour enfants :
// - Plateau avec cases numérotées style jeu de plateau
// - Personnage animé qui avance sur les cases
// - QCM avec vraies images
// - Effets visuels (succès/échec)
// - Sauvegarde automatique dans ProgressService

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../services/tts_service.dart';
import '../services/progress_service.dart';

class ParcourGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const ParcourGameScreen({super.key, required this.levelData});
  @override
  State<ParcourGameScreen> createState() => _ParcourGameScreenState();
}

class _ParcourGameScreenState extends State<ParcourGameScreen>
    with TickerProviderStateMixin {
  late List<_Challenge> _challenges;
  int _currentIndex = 0;
  int _score = 0;
  int _errors = 0;
  String? _selectedId;
  bool _answered = false;
  bool _gameOver = false;
  late Stopwatch _sw;
  final _tts = TtsService();

  // Animations
  late AnimationController _playerCtrl;
  late Animation<double> _playerAnim;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _confettiCtrl;
  late Animation<double> _confettiAnim;
  late AnimationController _cardCtrl;
  late Animation<double> _cardAnim;

  // Position du joueur (0 → nombre de cases)
  double _playerPosition = 0;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();

    _playerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _playerAnim = CurvedAnimation(
        parent: _playerCtrl, curve: Curves.easeInOut);

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -5, end: 5).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut));

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _confettiAnim = Tween<double>(begin: 0, end: 1).animate(_confettiCtrl);

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _cardAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);

    _buildChallenges();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && !_gameOver) _announceChallenge();
    });
  }

  @override
  void dispose() {
    _gameOver = true;
    _playerCtrl.dispose();
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    _confettiCtrl.dispose();
    _cardCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  void _buildChallenges() {
    final vocab = [...widget.levelData.vocabulary]..shuffle();
    final count = math.min(vocab.length, 10);
    final all = widget.levelData.vocabulary;
    final rng = math.Random();

    _challenges = List.generate(count, (i) {
      final correct = vocab[i];
      // Mode alterne : image→mot ou mot→image
      final showImage = i % 2 == 0;

      final others = all.where((w) => w.id != correct.id).toList()
        ..shuffle(rng);
      final opts = <_Option>[
        _Option(id: 'correct', word: correct, isCorrect: true),
        ...others.take(3).map((w) => _Option(id: w.id.toString(), word: w)),
      ]..shuffle(rng);

      return _Challenge(
        index: i,
        correct: correct,
        options: opts,
        showImage: showImage,
      );
    });
  }

  void _announceChallenge() {
    if (!mounted || _gameOver || _currentIndex >= _challenges.length) return;
    final ch = _challenges[_currentIndex];
    if (ch.showImage) {
      _tts.speak('Quel est ce mot ?');
    } else {
      _tts.speak(ch.correct.word);
    }
  }

  void _onAnswer(String optId, _Option opt) {
    if (_answered || _gameOver) return;

    final isCorrect = opt.isCorrect;
    setState(() {
      _selectedId = optId;
      _answered = true;
    });

    if (isCorrect) {
      _score += 10;
      _bounceCtrl.stop();
      _tts.speak('Bravo ! ${opt.word.word}');
      _bounceCtrl.reset();
      _bounceCtrl.repeat(reverse: true);
    } else {
      _errors++;
      _shakeCtrl.forward(from: 0);
      _tts.speak('La réponse est ${_challenges[_currentIndex].correct.word}');
    }

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted || _gameOver) return;
      _advance(isCorrect);
    });
  }

  void _advance(bool wasCorrect) {
    if (_currentIndex >= _challenges.length - 1) {
      _finish();
      return;
    }

    // Animer le joueur qui avance
    final targetPos = (_currentIndex + 1).toDouble();
    _playerAnim = Tween<double>(
      begin: _playerPosition,
      end: targetPos,
    ).animate(CurvedAnimation(parent: _playerCtrl, curve: Curves.easeInOut));

    _playerCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _playerPosition = targetPos);
    });

    _cardCtrl.reset();
    setState(() {
      _currentIndex++;
      _selectedId = null;
      _answered = false;
    });
    _cardCtrl.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_gameOver) _announceChallenge();
    });
  }

  void _finish() {
    if (_gameOver) return;
    _gameOver = true;
    _sw.stop();

    ProgressService().recordScore(
      levelId: widget.levelData.id,
      gameType: 'parcours',
      score: _score,
      maxScore: _challenges.length * 10,
      durationSeconds: _sw.elapsed.inSeconds,
      errorsCount: _errors,
    );

    _confettiCtrl.forward();
    _tts.speak('Parcours terminé ! Félicitations !');

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _showVictoryDialog();
    });
  }

  void _showVictoryDialog() {
    if (!mounted) return;
    final pct = (_score * 100 ~/ (_challenges.length * 10));
    final stars = pct >= 80 ? 3 : pct >= 60 ? 2 : 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFBF360C), Color(0xFFE64A19)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: Colors.amber.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏁', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 4),
              const Text('Parcours terminé !',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    3,
                    (i) => Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            i < stars
                                ? Icons.star
                                : Icons.star_border,
                            color: i < stars
                                ? Colors.amber
                                : Colors.white.withOpacity(0.3),
                            size: 44,
                          ),
                        )),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('🏆', '$_score', 'pts'),
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
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Continuer l\'aventure ! 🚀',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String emoji, String val, String label) => Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      );

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_gameOver) return true;
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('Quitter le Parcours ?'),
                content: const Text('Ta progression sera perdue.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Continuer')),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Quitter',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ) ??
            false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A0A0A),
                    Color(0xFFBF360C),
                    Color(0xFFE64A19),
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
                  _buildBoard(),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _cardAnim,
                      builder: (_, child) => FadeTransition(
                        opacity: _cardAnim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(_cardAnim),
                          child: child,
                        ),
                      ),
                      child: _currentIndex < _challenges.length
                          ? _buildChallenge(_challenges[_currentIndex])
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _confettiAnim,
              builder: (_, __) =>
                  _ConfettiLayer(progress: _confettiAnim.value),
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
                const Text('🏆  Parcours',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                Text(widget.levelData.title,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Text('$_score pts',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Case ${_currentIndex + 1}/${_challenges.length}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Plateau de jeu ────────────────────────────
  Widget _buildBoard() {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _challenges.isEmpty
                  ? 0
                  : (_currentIndex + 1) / _challenges.length,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(height: 8),
          // Cases du plateau
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _challenges.length,
              itemBuilder: (_, i) {
                final isDone = i < _currentIndex;
                final isCurrent = i == _currentIndex;
                final isNext = i == _currentIndex + 1;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AnimatedBuilder(
                    animation: _bounceAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, isCurrent ? _bounceAnim.value : 0),
                      child: child,
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: isDone
                            ? const LinearGradient(colors: [
                                Color(0xFF1B5E20),
                                Color(0xFF2E7D32)
                              ])
                            : isCurrent
                                ? const LinearGradient(colors: [
                                    Colors.amber,
                                    Color(0xFFFF8F00)
                                  ])
                                : null,
                        color: (!isDone && !isCurrent)
                            ? Colors.white.withOpacity(
                                isNext ? 0.2 : 0.08)
                            : null,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent
                              ? Colors.white
                              : isDone
                                  ? Colors.green.shade400
                                  : Colors.white.withOpacity(0.2),
                          width: isCurrent ? 2.5 : 1,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.6),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : isCurrent
                                ? const Text('🦸',
                                    style: TextStyle(fontSize: 18))
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: isNext
                                          ? Colors.white
                                          : Colors.white
                                              .withOpacity(0.4),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Défi courant ──────────────────────────────
  Widget _buildChallenge(_Challenge ch) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          _buildChallengeHeader(ch),
          const SizedBox(height: 12),
          _buildOptions(ch),
        ],
      ),
    );
  }

  Widget _buildChallengeHeader(_Challenge ch) {
    final hasImage = ch.correct.imagePath.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Numéro de case
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              ch.showImage
                  ? '🔍  Quel est ce mot ?'
                  : '🖼️  Trouve l\'image !',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          if (ch.showImage) ...[
            // Afficher image → trouver mot
            GestureDetector(
              onTap: () => _tts.speak(ch.correct.word),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: hasImage
                          ? Image.asset(
                              ch.correct.imagePath,
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(ch.correct.emoji,
                                    style: const TextStyle(fontSize: 72)),
                              ),
                            )
                          : Center(
                              child: Text(ch.correct.emoji,
                                  style:
                                      const TextStyle(fontSize: 72))),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.volume_up,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Afficher mot → trouver image
            GestureDetector(
              onTap: () => _tts.speak(ch.correct.word),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFF7043)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE65100).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(ch.correct.word,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    if (ch.correct.traductionArabic != null)
                      Text(ch.correct.traductionArabic!,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 18)),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up,
                            color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Écouter',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions(_Challenge ch) {
    if (ch.showImage) {
      // Options texte (trouver le mot)
      return Column(
        children: ch.options.map((opt) {
          final optId = opt.id;
          final isSel = _selectedId == optId;
          final isOk = opt.isCorrect;

          Color bg;
          Color border;

          if (!_answered) {
            bg = Colors.white.withOpacity(0.1);
            border = Colors.white.withOpacity(0.25);
          } else if (isSel && isOk) {
            bg = Colors.green.withOpacity(0.35);
            border = Colors.green;
          } else if (isSel && !isOk) {
            bg = Colors.red.withOpacity(0.35);
            border = Colors.red;
          } else if (isOk) {
            bg = Colors.green.withOpacity(0.2);
            border = Colors.green.withOpacity(0.6);
          } else {
            bg = Colors.white.withOpacity(0.05);
            border = Colors.white.withOpacity(0.1);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) {
                double offsetX = 0;
                if (isSel && !isOk && _answered) {
                  offsetX =
                      math.sin(_shakeAnim.value * math.pi * 5) * 8;
                }
                return Transform.translate(
                    offset: Offset(offsetX, 0), child: child!);
              },
              child: GestureDetector(
                onTap: _answered
                    ? null
                    : () => _onAnswer(optId, opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 18),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(opt.word.emoji,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt.word.word,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            if (opt.word.traductionArabic != null)
                              Text(opt.word.traductionArabic!,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12)),
                          ],
                        ),
                      ),
                      if (_answered)
                        Icon(
                          isSel && isOk
                              ? Icons.check_circle
                              : isSel
                                  ? Icons.cancel
                                  : isOk
                                      ? Icons.check_circle_outline
                                      : Icons.circle_outlined,
                          color: isOk ? Colors.green : Colors.red,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    } else {
      // Options image (trouver l'image) — grille 2×2
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
        children: ch.options.map((opt) {
          final optId = opt.id;
          final isSel = _selectedId == optId;
          final isOk = opt.isCorrect;
          final hasImage = opt.word.imagePath.isNotEmpty;

          Color border;
          if (!_answered) {
            border = Colors.white.withOpacity(0.25);
          } else if (isSel && isOk) {
            border = Colors.green;
          } else if (isSel) {
            border = Colors.red;
          } else if (isOk) {
            border = Colors.green.withOpacity(0.6);
          } else {
            border = Colors.white.withOpacity(0.1);
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
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: hasImage
                              ? Image.asset(opt.word.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(opt.word.emoji,
                                        style: const TextStyle(
                                            fontSize: 48)),
                                  ))
                              : Center(
                                  child: Text(opt.word.emoji,
                                      style: const TextStyle(
                                          fontSize: 48))),
                        ),
                        const SizedBox(height: 4),
                        Text(opt.word.word,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (_answered && (isSel || isOk))
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isOk ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOk ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 14,
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
}

// ─────────────────────────────────────────────────────────────
// Modèles internes
// ─────────────────────────────────────────────────────────────
class _Challenge {
  final int index;
  final Word correct;
  final List<_Option> options;
  final bool showImage; // true = image→mot, false = mot→image

  const _Challenge({
    required this.index,
    required this.correct,
    required this.options,
    required this.showImage,
  });
}

class _Option {
  final String id;
  final Word word;
  final bool isCorrect;

  const _Option({
    required this.id,
    required this.word,
    this.isCorrect = false,
  });
}

// ─────────────────────────────────────────────────────────────
// Widgets partagés
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
      [0.05, 0.03], [0.18, 0.01], [0.30, 0.06], [0.45, 0.02],
      [0.60, 0.05], [0.74, 0.01], [0.87, 0.07], [0.95, 0.03],
      [0.09, 0.13], [0.23, 0.16], [0.37, 0.11], [0.51, 0.15],
      [0.65, 0.10], [0.79, 0.14], [0.93, 0.12],
    ];
    for (final pt in pts) {
      canvas.drawCircle(
          Offset(size.width * pt[0], size.height * pt[1]), 1.3, p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

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
    Colors.red, Colors.blue, Colors.green, Colors.yellow,
    Colors.purple, Colors.orange, Colors.pink, Colors.cyan,
  ];
  const _ConfettiPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(33);
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y =
          -30 + (size.height + 60) * progress + rng.nextDouble() * 60;
      final sw = math.sin(progress * 10 + i * 0.5) * 40;
      final paint = Paint()
        ..color = _colors[i % _colors.length]
            .withOpacity((1.0 - progress * 0.8).clamp(0, 1));
      canvas.save();
      canvas.translate(x + sw, y);
      canvas.rotate(progress * 9 + i * 0.25);
      canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 7, height: 11),
          paint);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}