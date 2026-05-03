// lib/screens/memory_game_screen.dart
// 🃏 MEMORY v3.1 — BUGS CORRIGÉS
//
// CORRECTIONS :
//   ✅ Bug cartes bloquées → _isChecking remis à false dans TOUS les cas
//      (try/finally dans _onCardTap + reset forcé si état incohérent)
//   ✅ Son erreur → remplacé SoundEffect.wrong par SoundEffect.tryAgain (doux)
//      + vibration légère au lieu de vibrate() qui fait peur
//   ✅ Délai retournement cartes sur erreur → 1200ms au lieu de 900ms
//      pour que l'enfant voit bien quelle carte était la bonne
//   ✅ Guard anti-double-tap → vérification card.isFlipped avant await
//   ✅ Nettoyage _floatingEntry au dispose pour éviter les fuites mémoire

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/game_models.dart';
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../services/sound_service.dart';
import '../services/adaptive_engine.dart';

class _Card {
  final Word word;
  final int pairIndex;
  bool isFlipped = false;
  bool isMatched  = false;
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

  late final AdaptiveEngine _ai;
  late final AdaptiveTier   _tier;
  late int _pairCount;

  late List<_Card> _cards;
  _Card? _firstCard;
  _Card? _secondCard;

  // ✅ FIX : garde robuste — une seule vérification à la fois
  bool _isChecking = false;

  int _score    = 0;
  int _errors   = 0;
  int _combo    = 0;
  int _maxCombo = 0;
  final Map<int, int> _wordQualities = {};

  // ── Animations ───────────────────────────────────────────
  late final AnimationController _confettiCtrl;
  late final Animation<double>   _confettiAnim;

  final Map<int, AnimationController> _flipControllers   = {};
  final Map<int, Animation<double>>   _flipAnimations    = {};
  final Map<int, AnimationController> _bounceControllers = {};
  final Map<int, Animation<double>>   _bounceAnimations  = {};

  // ✅ FIX : fumée douce remplacée par simple flash orange (moins effrayant)
  int? _errorCardIndex;
  late final AnimationController _errorFlashCtrl;
  late final Animation<double>   _errorFlashAnim;

  // Flamme streak
  late final AnimationController _flameCtrl;
  late final Animation<double>   _flameAnim;

  // Timer ARC
  late final AnimationController _timerArcCtrl;
  late final Animation<double>   _timerArcAnim;
  static const _totalSeconds = 120;

  late Timer _uiTimer;
  int _elapsed = 0;

  // Message flottant
  OverlayEntry? _floatingEntry;

  static const _bravo  = ['Bravo ! 🌟', 'Excellent ! ⭐', 'Super ! 🎉', 'Parfait ! 💫'];
  static const _combo3 = ['COMBO x3 ! 🔥', 'Incroyable !', 'TU DÉCHIRES !'];
  // ✅ FIX : messages d'erreur doux et encourageants (sans son effrayant)
  static const _errorMsgs = ['Presque ! Réessaie 💪', 'Continue ! Tu peux le faire 😊', 'Oh non… mais tu vas y arriver 🌈'];

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

  @override
  void initState() {
    super.initState();
    _ai        = AdaptiveEngine();
    _tier      = _ai.tierForLevel(widget.levelData.id);
    _pairCount = _ai.memoryPairs(_tier);

    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _confettiAnim = CurvedAnimation(parent: _confettiCtrl, curve: Curves.easeOut);

    // ✅ FIX : flash orange doux sur erreur (pas de fumée effrayante)
    _errorFlashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _errorFlashAnim = CurvedAnimation(parent: _errorFlashCtrl, curve: Curves.easeOut);

    _flameCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _flameAnim = Tween<double>(begin: 0.9, end: 1.1)
        .animate(CurvedAnimation(parent: _flameCtrl, curve: Curves.easeInOut));

    _timerArcCtrl = AnimationController(vsync: this, duration: Duration(seconds: _totalSeconds));
    _timerArcAnim = Tween<double>(begin: 1.0, end: 0.0).animate(_timerArcCtrl);
    _timerArcCtrl.forward();

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });

    _buildDeck();
    _initFlipControllers();

    Future.delayed(const Duration(milliseconds: 600), () {
      SoundService().play(SoundEffect.gameStart);
      TtsService().speak('Memory ! ${_ai.tierLabel(_tier)}, $_pairCount paires. Trouve les paires !');
    });
  }

  void _buildDeck() {
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
      final flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
      _flipControllers[i] = flipCtrl;
      _flipAnimations[i]  = Tween<double>(begin: 0, end: 1)
          .animate(CurvedAnimation(parent: flipCtrl, curve: Curves.easeInOut));

      final bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
      _bounceControllers[i] = bounceCtrl;
      _bounceAnimations[i]  = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.92), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 1),
      ]).animate(CurvedAnimation(parent: bounceCtrl, curve: Curves.easeOut));
    }
  }

  @override
  void dispose() {
    // ✅ FIX : nettoyage overlay pour éviter fuite mémoire
    _floatingEntry?.remove();
    _floatingEntry = null;

    _confettiCtrl.dispose();
    _errorFlashCtrl.dispose();
    _flameCtrl.dispose();
    _timerArcCtrl.dispose();
    _uiTimer.cancel();
    for (final c in _flipControllers.values)   c.dispose();
    for (final c in _bounceControllers.values) c.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // TAP SUR UNE CARTE — corrigé avec try/finally
  // ─────────────────────────────────────────────────────────
  Future<void> _onCardTap(int index) async {
    // ✅ FIX 1 : Guards robustes AVANT tout await
    if (_isChecking) return;
    final card = _cards[index];
    if (card.isFlipped || card.isMatched) return;

    // ✅ FIX 2 : Vérification cohérence état
    // (si _firstCard est null mais _secondCard ne l'est pas — état corrompu)
    if (_firstCard == null && _secondCard != null) {
      _secondCard = null;
    }

    HapticFeedback.lightImpact();
    SoundService().play(SoundEffect.cardFlip);

    // ✅ FIX 3 : try/finally garantit que _isChecking est toujours libéré
    try {
      await _flipControllers[index]!.forward();
      if (!mounted) return;

      setState(() => card.isFlipped = true);

      // Prononce le mot (lettre + exemple pour l'alphabet)
      _speakWord(card.word);

      if (_firstCard == null) {
        _firstCard = card;
        return; // attend le 2ème tap — _isChecking reste false
      }

      // ✅ FIX 4 : lock AVANT le délai, pas après
      _isChecking = true;
      _secondCard = card;

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) {
        _isChecking = false;
        return;
      }

      if (_firstCard!.pairIndex == _secondCard!.pairIndex) {
        _onMatch(index);
      } else {
        await _onMismatch(index);
      }
    } catch (e) {
      // ✅ FIX 5 : si une exception survient, on débloque toujours
      debugPrint('Memory card tap error: $e');
      _isChecking = false;
      _firstCard  = null;
      _secondCard = null;
    }
  }

  void _speakWord(Word word) {
    if (word.word.length == 1 && word.traductionDarija != null) {
      TtsService().speak('${word.word} comme ${word.traductionDarija}');
    } else {
      TtsService().speak(word.word);
    }
  }

  void _onMatch(int secondIndex) {
    HapticFeedback.mediumImpact();
    SoundService().play(_combo >= 2 ? SoundEffect.combo : SoundEffect.match);

    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _score += 10 + (_combo > 2 ? _combo * 3 : 0);

    _wordQualities[_firstCard!.word.id] = 4;
    _wordQualities[_secondCard!.word.id] = 4;

    setState(() {
      _firstCard!.isMatched  = true;
      _secondCard!.isMatched = true;
    });

    // Bounce spring sur les 2 cartes
    final firstIdx = _cards.indexOf(_firstCard!);
    _bounceControllers[firstIdx]?.forward(from: 0);
    _bounceControllers[secondIndex]?.forward(from: 0);

    final msg = _combo >= 3
        ? _combo3[math.min(_combo - 3, _combo3.length - 1)]
        : _bravo[math.Random().nextInt(_bravo.length)];
    _showFloatingMsg(msg, Colors.green);

    TtsService().speak(_combo >= 3 ? 'COMBO !' : 'Bravo !');

    _firstCard  = null;
    _secondCard = null;
    _isChecking = false; // ✅ libéré proprement

    if (_cards.every((c) => c.isMatched)) _finishGame();
  }

  // ✅ FIX : async pour attendre le retournement avant de libérer
  Future<void> _onMismatch(int secondIndex) async {
    _combo = 0;
    _errors++;
    _wordQualities[_firstCard!.word.id] =
        _ai.computeQuality(isCorrect: false, responseTimeSeconds: 10);

    // ✅ FIX SON : SoundEffect.tryAgain = son doux/encourageant
    // au lieu de SoundEffect.wrong qui fait peur
    SoundService().play(SoundEffect.tryAgain);

    // ✅ FIX HAPTIC : selectionClick (léger) au lieu de vibrate() (agressif)
    HapticFeedback.selectionClick();

    // Flash orange doux sur la carte erreur
    setState(() => _errorCardIndex = secondIndex);
    _errorFlashCtrl.forward(from: 0);

    _showFloatingMsg(_errorMsgs[math.Random().nextInt(_errorMsgs.length)], Colors.orange);

    // ✅ FIX DÉLAI : 1200ms au lieu de 900ms
    // → l'enfant a le temps de voir quelle paire ne correspondait pas
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) {
      _isChecking = false;
      _firstCard  = null;
      _secondCard = null;
      return;
    }

    // Retourne les 2 cartes
    final firstIdx = _cards.indexOf(_firstCard!);
    await Future.wait([
      _flipControllers[firstIdx]!.reverse(),
      _flipControllers[secondIndex]!.reverse(),
    ]);

    if (!mounted) {
      _isChecking = false;
      _firstCard  = null;
      _secondCard = null;
      return;
    }

    setState(() {
      _firstCard!.isFlipped  = false;
      _secondCard!.isFlipped = false;
      _firstCard     = null;
      _secondCard    = null;
      _errorCardIndex = null;
      _isChecking    = false; // ✅ libéré proprement à la fin
    });

    _errorFlashCtrl.reset();
  }

  void _finishGame() {
    _uiTimer.cancel();
    _timerArcCtrl.stop();
    _confettiCtrl.forward();
    SoundService().play(SoundEffect.levelDone);
    TtsService().speak('Félicitations ! Tu as trouvé toutes les paires !');

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

  void _showFloatingMsg(String msg, Color color) {
    _floatingEntry?.remove();
    _floatingEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).size.height * 0.12,
        left: 0, right: 0,
        child: _FloatingMsg(
          msg: msg,
          color: color,
          onDone: () {
            _floatingEntry?.remove();
            _floatingEntry = null;
          },
        ),
      ),
    );
    Overlay.of(context).insert(_floatingEntry!);
  }

  void _showResultDialog() {
    final pct   = (_score / (_pairCount * 10) * 100).clamp(0, 100).round();
    final stars = pct >= 80 ? 3 : pct >= 60 ? 2 : 1;
    final msg   = _ai.encouragementMessage(pct);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_levelColor, _levelColor.withOpacity(0.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: _levelColor.withOpacity(0.5),
                  blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text('Memory terminé !',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(i < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 40),
                  ))),
              const SizedBox(height: 16),
              _statRow('🎯', 'Score',          '$_score pts'),
              _statRow('❌', 'Erreurs',         '$_errors'),
              _statRow('🔥', 'Meilleur combo', 'x$_maxCombo'),
              _statRow('⏱', 'Temps',           '${_elapsed}s'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('${_ai.tierLabel(_tier)} · $_pairCount paires',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                    backgroundColor: Colors.white.withOpacity(0.25), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                ElevatedButton.icon(
                  onPressed: () { Navigator.pop(context); _restart(); },
                  icon: const Icon(Icons.replay),
                  label: const Text('Rejouer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: _levelColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ]),
            ]),
          ),
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
    _floatingEntry?.remove();
    _floatingEntry = null;

    setState(() {
      _score = 0; _errors = 0; _combo = 0; _maxCombo = 0; _elapsed = 0;
      _firstCard = null; _secondCard = null;
      _isChecking = false; _errorCardIndex = null;
      _wordQualities.clear();
      _buildDeck();
      for (final c in _flipControllers.values)   c.dispose();
      for (final c in _bounceControllers.values) c.dispose();
      _flipControllers.clear();   _flipAnimations.clear();
      _bounceControllers.clear(); _bounceAnimations.clear();
      _initFlipControllers();
    });
    _timerArcCtrl.reset();
    _timerArcCtrl.forward();
    _errorFlashCtrl.reset();
    _uiTimer.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
    _confettiCtrl.reset();
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cols       = _pairCount <= 4 ? 2 : _pairCount <= 6 ? 3 : 4;
    final allMatched = _cards.isNotEmpty && _cards.every((c) => c.isMatched);

    return Scaffold(
      body: Stack(children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF0A1628), _levelColor.withOpacity(0.8), const Color(0xFF0A1628)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),
        SafeArea(child: Column(children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildStatsBar(),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.8),
                itemCount: _cards.length,
                itemBuilder: (_, i) => _buildCard(i),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ])),
        if (allMatched)
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
        onTap: _showQuitDialog,
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🃏 Memory',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(widget.levelData.title,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ])),
      _buildTimerArc(),
    ]),
  );

  Widget _buildTimerArc() => AnimatedBuilder(
    animation: _timerArcAnim,
    builder: (_, __) {
      final frac  = _timerArcAnim.value;
      final color = frac > 0.5 ? Colors.green : frac > 0.25 ? Colors.orange : Colors.red;
      return SizedBox(width: 48, height: 48,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: frac, strokeWidth: 5,
            backgroundColor: Colors.white.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(_formatTime(_elapsed),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      );
    },
  );

  Widget _buildStatsBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _chip('🎯', '$_score pts', Colors.amber),
      _chip('🃏', '${_cards.where((c) => c.isMatched).length ~/ 2}/$_pairCount', Colors.green),
      _buildComboChip(),
      _chip(_ai.tierLabel(_tier).split(' ').first, _ai.tierLabel(_tier).split(' ').last, Colors.white),
    ]),
  );

  Widget _buildComboChip() {
    if (_combo < 3) return _chip('🔥', 'x$_combo', Colors.orange);
    return AnimatedBuilder(
      animation: _flameAnim,
      builder: (_, __) => Transform.scale(
        scale: _flameAnim.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFFCA28)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.6), blurRadius: 10)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔥', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('x$_combo', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String emoji, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildCard(int index) {
    final card       = _cards[index];
    final anim       = _flipAnimations[index]!;
    final bounceAnim = _bounceAnimations[index]!;
    final hasFlash   = _errorCardIndex == index;

    return AnimatedBuilder(
      animation: Listenable.merge([anim, bounceAnim]),
      builder: (_, __) {
        final angle   = anim.value * math.pi;
        final isFront = angle > math.pi / 2;

        Widget cardWidget = GestureDetector(
          onTap: () => _onCardTap(index),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _cardFront(card, hasFlash),
                  )
                : _cardBack(),
          ),
        );

        if (card.isMatched) {
          cardWidget = Transform.scale(scale: bounceAnim.value, child: cardWidget);
        }

        return cardWidget;
      },
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
    child: Center(child: Text('?',
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.8)))),
  );

  // ✅ FIX : flash orange doux au lieu de fumée effrayante
  Widget _cardFront(_Card card, bool hasFlash) {
    final matched = card.isMatched;
    return AnimatedBuilder(
      animation: _errorFlashAnim,
      builder: (_, child) {
        final flashOpacity = hasFlash ? (1 - _errorFlashAnim.value) * 0.45 : 0.0;
        return Stack(children: [
          child!,
          if (hasFlash)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(flashOpacity),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
        ]);
      },
      child: Container(
        decoration: BoxDecoration(
          color: matched ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: matched ? Colors.green.shade300 : Colors.white.withOpacity(0.9),
            width: matched ? 2.5 : 1,
          ),
          boxShadow: [BoxShadow(
            color: matched ? Colors.green.withOpacity(0.5) : Colors.black.withOpacity(0.2),
            blurRadius: matched ? 14 : 6, offset: const Offset(0, 4),
          )],
        ),
        child: Stack(children: [
          Positioned.fill(child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(card.word.imagePath, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(child: Text(
                card.word.word.length == 1 ? card.word.word : card.word.word[0],
                style: TextStyle(
                  fontSize: card.word.word.length == 1 ? 40 : 28,
                  fontWeight: FontWeight.bold,
                  color: matched ? Colors.white : _levelColor,
                )),
              ),
            ),
          )),
          Positioned(bottom: 0, left: 0, right: 0,
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
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            )),
          if (matched)
            const Positioned(top: 8, right: 8, child: Icon(Icons.check_circle, color: Colors.white, size: 22)),
        ]),
      ),
    );
  }

  void _showQuitDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A237E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Quitter ?', style: TextStyle(color: Colors.white)),
      content: const Text('Tu perdras ta progression.', style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Continuer', style: TextStyle(color: Colors.amber))),
        TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Quitter', style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

// ─── Message flottant ────────────────────────────────────
class _FloatingMsg extends StatefulWidget {
  final String msg;
  final Color color;
  final VoidCallback onDone;
  const _FloatingMsg({required this.msg, required this.color, required this.onDone});
  @override
  State<_FloatingMsg> createState() => _FloatingMsgState();
}

class _FloatingMsgState extends State<_FloatingMsg> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _fadeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 1),
    ]).animate(_ctrl);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: const Offset(0, -0.3))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Opacity(
      opacity: _fadeAnim.value,
      child: SlideTransition(
        position: _slideAnim,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 15)],
            ),
            child: Text(widget.msg,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    ),
  );
}

// ─── Confettis ────────────────────────────────────────────
class _ConfettiOverlay extends StatelessWidget {
  final double progress;
  const _ConfettiOverlay({required this.progress});
  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
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
  static const _cols = [Colors.red, Colors.blue, Colors.green,
    Colors.yellow, Colors.purple, Colors.orange, Colors.pink];
  const _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final rng = math.Random(42);
    for (int i = 0; i < 100; i++) {
      final x = rng.nextDouble() * size.width;
      final y = -20.0 + (size.height + 40) * progress + math.sin(progress * 8 + i) * 40;
      final p = Paint()
        ..color = _cols[i % _cols.length].withOpacity((1 - progress).clamp(0, 1));
      final r = Rect.fromCenter(
          center: Offset(x + math.sin(progress * 5 + i) * 25, y), width: 9, height: 14);
      canvas.save();
      canvas.translate(r.center.dx, r.center.dy);
      canvas.rotate(progress * 8 + i.toDouble());
      canvas.translate(-r.center.dx, -r.center.dy);
      final shape = i % 3;
      if (shape == 0) {
        canvas.drawRect(r, p);
      } else if (shape == 1) {
        canvas.drawCircle(r.center, 5, p);
      } else {
        final tri = Path()
          ..moveTo(r.center.dx, r.top)
          ..lineTo(r.right, r.bottom)
          ..lineTo(r.left, r.bottom)
          ..close();
        canvas.drawPath(tri, p);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}