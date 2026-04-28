// lib/screens/memory_game_screen.dart
// 🎮 MEMORY 2.0 — Design vrai jeu : flip 3D, TTS, IA adaptative, confettis
// L'AdaptiveEngine choisit 4/6/8 paires selon le niveau de l'enfant
// Le SM-2 est mis à jour à chaque réponse pour guider la révision future

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/game_models.dart';
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../services/adaptive_engine.dart';

// ─── Carte mémoire ──────────────────────────────────────────
class _Card {
  final Word word;
  final int pairIndex; // même index = même paire
  bool isFlipped = false;
  bool isMatched = false;
  _Card({required this.word, required this.pairIndex});
}

class MemoryGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const MemoryGameScreen({super.key, required this.levelData});
  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with TickerProviderStateMixin {

  // ── IA Adaptative ────────────────────────────────────────
  late final AdaptiveEngine _ai;
  late final AdaptiveTier _tier;
  late int _pairCount;

  // ── Jeu ──────────────────────────────────────────────────
  late List<_Card> _cards;
  _Card? _firstCard;
  _Card? _secondCard;
  bool _isChecking = false;
  int _score = 0;
  int _errors = 0;
  int _combo = 0;
  int _maxCombo = 0;
  late Stopwatch _stopwatch;

  // ── SM-2 tracking ────────────────────────────────────────
  final Map<int, int> _wordQualities = {}; // wordId → quality SM-2

  // ── Animations ───────────────────────────────────────────
  late final AnimationController _confettiCtrl;
  late final Animation<double> _confettiAnim;
  final Map<int, AnimationController> _flipControllers = {};
  final Map<int, Animation<double>> _flipAnimations = {};
  late final AnimationController _shakeCtrl;
  late final Animation<Offset> _shakeAnim;
  int? _shakeCardIndex;

  // ── Chrono UI ────────────────────────────────────────────
  late Timer _uiTimer;
  int _elapsed = 0;

  // ── Messages encouragement ───────────────────────────────
  static const _bravo  = ['Bravo ! 🌟', 'Excellent ! ⭐', 'Super ! 🎉', 'Parfait ! 💫', 'Génial ! 🚀'];
  static const _combo3 = ['COMBO x3 ! 🔥', 'Incroyable ! 🔥🔥', 'TU DÉCHIRES ! 🔥🔥🔥'];
  static const _error  = ['Oh non… 😅', 'Presque ! 💪', 'Continue ! 😊', 'Tu peux le faire ! 🌈'];

  // ── Couleur du niveau ────────────────────────────────────
  Color get _levelColor {
    switch (widget.levelData.level) {
      case GameLevel.cp:  return const Color(0xFF1565C0);
      case GameLevel.ce1: return const Color(0xFF2E7D32);
      case GameLevel.ce2: return const Color(0xFFE65100);
      case GameLevel.cm1: return const Color(0xFF6A1B9A);
      case GameLevel.cm2: return const Color(0xFFC62828);
      default:            return const Color(0xFF1565C0);
    }
  }

  // ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ai    = AdaptiveEngine();
    _tier  = _ai.tierForLevel(widget.levelData.id);
    _pairCount = _ai.memoryPairs(_tier);

    // Confettis
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _confettiAnim = CurvedAnimation(parent: _confettiCtrl, curve: Curves.easeOut);

    // Shake sur erreur
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.03, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.03, 0), end: const Offset(0.03, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.03, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _stopwatch = Stopwatch()..start();
    _uiTimer   = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });

    _buildDeck();
    _initFlipControllers();

    // TTS de bienvenue
    Future.delayed(const Duration(milliseconds: 600), () {
      final tierLabel = _tier == AdaptiveTier.easy ? 'facile' : _tier == AdaptiveTier.medium ? 'moyen' : 'difficile';
      TtsService().speak('Memory ! Niveau $tierLabel, $_pairCount paires. C\'est parti !');
    });
  }

  void _buildDeck() {
    // Sélection adaptative des mots via SM-2
    final selected = _ai.selectWords(widget.levelData.vocabulary, count: _pairCount);
    final pairs = <_Card>[];
    for (int i = 0; i < selected.length; i++) {
      pairs.add(_Card(word: selected[i], pairIndex: i));
      pairs.add(_Card(word: selected[i], pairIndex: i));
    }
    pairs.shuffle(math.Random());
    _cards = pairs;
  }

  void _initFlipControllers() {
    for (int i = 0; i < _cards.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      );
      _flipControllers[i] = ctrl;
      _flipAnimations[i]  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _shakeCtrl.dispose();
    _uiTimer.cancel();
    for (final c in _flipControllers.values) c.dispose();
    super.dispose();
  }

  // ─── Tap sur une carte ──────────────────────────────────
  Future<void> _onCardTap(int index) async {
    if (_isChecking) return;
    final card = _cards[index];
    if (card.isFlipped || card.isMatched) return;

    HapticFeedback.lightImpact();

    // Flip animation
    await _flipControllers[index]!.forward();
    setState(() => card.isFlipped = true);

    // TTS prononce le mot au premier retournement
    TtsService().speak(card.word.word);

    if (_firstCard == null) {
      _firstCard = card;
      return;
    }

    // Deuxième carte → vérification
    _isChecking = true;
    _secondCard = card;

    await Future.delayed(const Duration(milliseconds: 500));

    if (_firstCard!.pairIndex == _secondCard!.pairIndex) {
      _onMatch();
    } else {
      _onMismatch(index);
    }
  }

  void _onMatch() {
    HapticFeedback.mediumImpact();
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _score += 10 + (_combo > 2 ? _combo * 2 : 0);

    // SM-2 : succès rapide = qualité 5, normal = 4
    final q = _elapsed / _cards.length < 3 ? 5 : 4;
    _wordQualities[_firstCard!.word.id] = q;

    setState(() {
      _firstCard!.isMatched = true;
      _secondCard!.isMatched = true;
    });

    // Message combo
    String msg;
    if (_combo >= 3) {
      msg = _combo3[math.min(_combo - 3, _combo3.length - 1)];
    } else {
      msg = _bravo[math.Random().nextInt(_bravo.length)];
    }
    _showSnack(msg, Colors.green);
    TtsService().speak('Bravo !');

    _firstCard = null; _secondCard = null; _isChecking = false;

    // Fin de jeu ?
    if (_cards.every((c) => c.isMatched)) _finishGame();
  }

  void _onMismatch(int secondIndex) {
    _combo = 0;
    _errors++;

    // SM-2 : échec
    _wordQualities[_firstCard!.word.id] =
        _ai.computeQuality(isCorrect: false, responseTimeSeconds: 10);

    // Shake
    setState(() => _shakeCardIndex = secondIndex);
    _shakeCtrl.forward(from: 0);
    HapticFeedback.vibrate();

    _showSnack(_error[math.Random().nextInt(_error.length)], Colors.orange);

    Future.delayed(const Duration(milliseconds: 900), () {
      _flipControllers[_cards.indexOf(_firstCard!)]!.reverse();
      _flipControllers[secondIndex]!.reverse();
      setState(() {
        _firstCard!.isFlipped = false;
        _secondCard!.isFlipped = false;
        _firstCard = null; _secondCard = null;
        _shakeCardIndex = null;
        _isChecking = false;
      });
    });
  }

  void _finishGame() {
    _stopwatch.stop();
    _uiTimer.cancel();
    _confettiCtrl.forward();
    TtsService().speak('Félicitations ! Tu as trouvé toutes les paires !');

    // Enregistrer le score + SM-2
    ProgressService().recordScore(
      levelId:         widget.levelData.id,
      gameType:        'memory',
      score:           _score,
      maxScore:        _pairCount * 10,
      durationSeconds: _elapsed,
      errorsCount:     _errors,
      wordQualities:   _wordQualities,
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _showResultDialog();
    });
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      backgroundColor: color,
      duration: const Duration(milliseconds: 1500),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
    ));
  }

  // ─── Dialogue résultats ──────────────────────────────────
  void _showResultDialog() {
    final pct    = (_score / (_pairCount * 10) * 100).clamp(0, 100).round();
    final stars  = pct >= 80 ? 3 : pct >= 60 ? 2 : 1;
    final msg    = _ai.encouragementMessage(pct);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_levelColor, _levelColor.withOpacity(0.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: _levelColor.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            const Text('Memory terminé !',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            // Étoiles
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(i < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 40),
              ),
            )),
            const SizedBox(height: 16),
            // Stats
            _statRow('🎯', 'Score',        '$_score pts'),
            _statRow('❌', 'Erreurs',      '$_errors'),
            _statRow('🔥', 'Meilleur combo','x$_maxCombo'),
            _statRow('⏱', 'Temps',         '${_elapsed}s'),
            const SizedBox(height: 12),
            // Tier
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Niveau IA : ${_tier == AdaptiveTier.easy ? "🟢 Facile" : _tier == AdaptiveTier.medium ? "🟡 Moyen" : "🔴 Difficile"} · $_pairCount paires',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                icon: const Icon(Icons.home),
                label: const Text('Retour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _restart(); },
                icon: const Icon(Icons.replay),
                label: const Text('Rejouer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _levelColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _statRow(String emoji, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      const Spacer(),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ]),
  );

  void _restart() {
    setState(() {
      _score = 0; _errors = 0; _combo = 0; _maxCombo = 0; _elapsed = 0;
      _firstCard = null; _secondCard = null; _isChecking = false;
      _wordQualities.clear();
      _buildDeck();
      for (final c in _flipControllers.values) c.dispose();
      _flipControllers.clear(); _flipAnimations.clear();
      _initFlipControllers();
    });
    _stopwatch.reset(); _stopwatch.start();
    _uiTimer.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
    _confettiCtrl.reset();
  }

  // ─── UI ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Grille adaptée au nombre de paires
    final cols = _pairCount <= 4 ? 2 : _pairCount <= 6 ? 3 : 4;

    return Scaffold(
      body: Stack(children: [
        // Fond dégradé
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF0A1628), _levelColor.withOpacity(0.8), const Color(0xFF0A1628)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),

        SafeArea(child: Column(children: [
          // ── Header ──
          _buildHeader(),
          const SizedBox(height: 8),

          // ── Stats bar ──
          _buildStatsBar(),
          const SizedBox(height: 12),

          // ── Grille de cartes ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: _cards.length,
                itemBuilder: (_, i) => _buildCard(i),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ])),

        // ── Confettis ──
        if (_cards.every((c) => c.isMatched))
          AnimatedBuilder(
            animation: _confettiAnim,
            builder: (_, __) => _ConfettiOverlay(progress: _confettiAnim.value),
          ),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => _showQuitDialog(),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🃏 Memory', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(widget.levelData.title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ]),
      ),
      // Timer
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.timer, color: Colors.white70, size: 16),
          const SizedBox(width: 4),
          Text(_formatTime(_elapsed), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
      ),
    ]),
  );

  Widget _buildStatsBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _statChip('🎯', '$_score pts', Colors.amber),
      _statChip('🃏', '${_cards.where((c) => c.isMatched).length ~/ 2}/$_pairCount', Colors.green),
      _statChip('🔥', 'x$_combo', Colors.orange),
      _statChip(
        _tier == AdaptiveTier.easy ? '🟢' : _tier == AdaptiveTier.medium ? '🟡' : '🔴',
        _tier == AdaptiveTier.easy ? 'Facile' : _tier == AdaptiveTier.medium ? 'Moyen' : 'Difficile',
        Colors.white,
      ),
    ]),
  );

  Widget _statChip(String emoji, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildCard(int index) {
    final card  = _cards[index];
    final anim  = _flipAnimations[index]!;
    final shake = _shakeCardIndex == index;

    return AnimatedBuilder(
      animation: shake ? _shakeAnim : const AlwaysStoppedAnimation(Offset.zero),
      builder: (_, child) => FractionalTranslation(
        translation: shake ? _shakeAnim.value : Offset.zero,
        child: child,
      ),
      child: GestureDetector(
        onTap: () => _onCardTap(index),
        child: AnimatedBuilder(
          animation: anim,
          builder: (_, __) {
            final angle = anim.value * math.pi;
            final isFront = angle > math.pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isFront
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _cardFront(card),
                    )
                  : _cardBack(),
            );
          },
        ),
      ),
    );
  }

  Widget _cardBack() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_levelColor, _levelColor.withOpacity(0.6)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      boxShadow: [BoxShadow(color: _levelColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Center(
      child: Text('?', style: TextStyle(
        fontSize: 36, fontWeight: FontWeight.w900,
        color: Colors.white.withOpacity(0.8),
      )),
    ),
  );

  Widget _cardFront(_Card card) {
    final matched = card.isMatched;
    return Container(
      decoration: BoxDecoration(
        color: matched ? const Color(0xFF1B5E20) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: matched ? Colors.green.shade300 : Colors.white.withOpacity(0.9),
          width: matched ? 2.5 : 1,
        ),
        boxShadow: [BoxShadow(
          color: matched ? Colors.green.withOpacity(0.5) : Colors.black.withOpacity(0.2),
          blurRadius: matched ? 14 : 6,
          offset: const Offset(0, 4),
        )],
      ),
      child: Stack(children: [
        // Image
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(card.word.imagePath, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(card.word.word[0],
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                    color: matched ? Colors.white : _levelColor)),
              ),
            ),
          ),
        ),
        // Overlay nom du mot
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: matched ? Colors.green.withOpacity(0.85) : Colors.black.withOpacity(0.55),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Text(
              matched ? '✓ ${card.word.word}' : card.word.word,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Checkmark si appairée
        if (matched)
          const Positioned(
            top: 8, right: 8,
            child: Icon(Icons.check_circle, color: Colors.white, size: 22),
          ),
      ]),
    );
  }

  // ─── Quitter ────────────────────────────────────────────
  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quitter ?', style: TextStyle(color: Colors.white)),
        content: const Text('Tu perdras ta progression.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer', style: TextStyle(color: Colors.amber)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

// ─── Confettis ───────────────────────────────────────────
class _ConfettiOverlay extends StatelessWidget {
  final double progress;
  const _ConfettiOverlay({required this.progress});
  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
        painter: _ConfettiPainter(progress: progress),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static const _cols = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange, Colors.pink];
  const _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final rng = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = -20.0 + (size.height + 40) * progress + math.sin(progress * 8 + i) * 40;
      final p = Paint()..color = _cols[i % _cols.length].withOpacity((1 - progress).clamp(0, 1));
      final rect = Rect.fromCenter(center: Offset(x + math.sin(progress * 5 + i) * 25, y), width: 9, height: 14);
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(progress * 8 + i.toDouble());
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawRect(rect, p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}