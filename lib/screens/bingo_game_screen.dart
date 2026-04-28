// lib/screens/bingo_game_screen.dart
// 🎮 BINGO 2.0 — TTS automatique, grille 3×3 ou 4×4, explosion BINGO, IA adaptative

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/game_models.dart';
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../services/adaptive_engine.dart';

class BingoGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const BingoGameScreen({super.key, required this.levelData});
  @override
  State<BingoGameScreen> createState() => _BingoGameScreenState();
}

class _BingoGameScreenState extends State<BingoGameScreen>
    with TickerProviderStateMixin {

  // ── IA Adaptative ────────────────────────────────────────
  late final AdaptiveEngine _ai;
  late final AdaptiveTier _tier;
  late int _targetCount; // 4, 6 ou 9 cibles à trouver

  // ── Jeu ──────────────────────────────────────────────────
  late List<Word> _grid;     // 9 mots sur la grille
  late List<int> _targets;   // indices des cases à trouver dans l'ordre
  int _targetIdx = 0;        // index courant dans _targets
  final Set<int> _markedOk  = {};  // cases correctement cochées
  final Set<int> _markedErr = {};  // cases incorrectement cochées (flash rouge)
  int _score = 0;
  int _errors = 0;
  late Stopwatch _stopwatch;
  late Timer _uiTimer;
  int _elapsed = 0;
  bool _gameOver = false;

  // ── Animations ───────────────────────────────────────────
  late final AnimationController _bingoCtrl;
  late final Animation<double> _bingoAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  int? _lastMarked;  // pour animer la dernière carte cochée

  // ── Couleur ──────────────────────────────────────────────
  Color get _c {
    switch (widget.levelData.level) {
      case GameLevel.cp:  return const Color(0xFF1565C0);
      case GameLevel.ce1: return const Color(0xFF2E7D32);
      case GameLevel.ce2: return const Color(0xFFE65100);
      case GameLevel.cm1: return const Color(0xFF6A1B9A);
      case GameLevel.cm2: return const Color(0xFFC62828);
      default:            return const Color(0xFF6A1B9A);
    }
  }

  @override
  void initState() {
    super.initState();
    _ai          = AdaptiveEngine();
    _tier        = _ai.tierForLevel(widget.levelData.id);
    _targetCount = _ai.bingoTargets(_tier);

    // Explosion BINGO
    _bingoCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _bingoAnim = CurvedAnimation(parent: _bingoCtrl, curve: Curves.easeOut);

    // Pulse sur la carte cible courante
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _stopwatch = Stopwatch()..start();
    _uiTimer   = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });

    _buildGame();
    _announceNext();
  }

  void _buildGame() {
    final words = _ai.selectWords(widget.levelData.vocabulary, count: 9);
    _grid    = words.take(9).toList()..shuffle(math.Random());
    final positions = List.generate(9, (i) => i)..shuffle(math.Random());
    _targets = positions.take(_targetCount).toList();
  }

  // ── TTS annonce la prochaine cible ──────────────────────
  void _announceNext({bool delay = true}) {
    if (_targetIdx >= _targets.length) return;
    final word = _grid[_targets[_targetIdx]];

    Future.delayed(delay ? const Duration(milliseconds: 800) : Duration.zero, () {
      if (!mounted) return;
      TtsService().speak('Trouve : ${word.word}');
    });
  }

  // ── Tap sur une case ────────────────────────────────────
  void _onCellTap(int idx) {
    if (_gameOver) return;
    if (_markedOk.contains(idx)) return;

    final expected = _targets[_targetIdx];

    if (idx == expected) {
      // ✅ CORRECT
      HapticFeedback.mediumImpact();
      final word = _grid[idx];
      _score += 10;

      setState(() {
        _markedOk.add(idx);
        _markedErr.remove(idx);
        _lastMarked = idx;
        _targetIdx++;
      });

      TtsService().speak('Bravo ! ${word.word} !');

      if (_targetIdx >= _targets.length) {
        _finishGame();
      } else {
        Future.delayed(const Duration(milliseconds: 600), () {
          _announceNext();
        });
      }
    } else {
      // ❌ ERREUR
      HapticFeedback.vibrate();
      _errors++;
      setState(() => _markedErr.add(idx));

      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _markedErr.remove(idx));
      });

      TtsService().speak('Non ! Continue !');
    }
  }

  void _finishGame() {
    _gameOver = true;
    _stopwatch.stop();
    _uiTimer.cancel();
    _bingoCtrl.forward();
    TtsService().speak('BINGO ! Bravo, tu as tout trouvé !');

    ProgressService().recordScore(
      levelId:         widget.levelData.id,
      gameType:        'bingo',
      score:           _score,
      maxScore:        _targetCount * 10,
      durationSeconds: _elapsed,
      errorsCount:     _errors,
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _showResultDialog();
    });
  }

  void _showResultDialog() {
    final pct   = (_score / (_targetCount * 10) * 100).clamp(0, 100).round();
    final stars = pct >= 80 ? 3 : pct >= 60 ? 2 : 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_c, _c.withOpacity(0.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: _c.withOpacity(0.5), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎯', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            const Text('BINGO ! 🎉',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3,
              (i) => Icon(i < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 38))),
            const SizedBox(height: 16),
            _row('🎯', 'Score',    '$_score / ${_targetCount * 10}'),
            _row('❌', 'Erreurs',  '$_errors'),
            _row('⏱', 'Temps',    '${_elapsed}s'),
            _row(
              _tier == AdaptiveTier.easy ? '🟢' : _tier == AdaptiveTier.medium ? '🟡' : '🔴',
              'Niveau IA',
              '$_targetCount cibles',
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retour'),
              ),
              ElevatedButton(
                onPressed: () { Navigator.pop(context); _restart(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _c,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Rejouer'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _row(String e, String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(e, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 8),
      Text(l, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      const Spacer(),
      Text(v, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
    ]),
  );

  void _restart() {
    setState(() {
      _targetIdx = 0; _score = 0; _errors = 0; _elapsed = 0;
      _markedOk.clear(); _markedErr.clear();
      _gameOver = false; _lastMarked = null;
      _buildGame();
    });
    _stopwatch.reset(); _stopwatch.start();
    _uiTimer.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
    _bingoCtrl.reset();
    _announceNext(delay: true);
  }

  @override
  void dispose() {
    _bingoCtrl.dispose(); _pulseCtrl.dispose();
    _uiTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTarget = _targetIdx < _targets.length ? _targets[_targetIdx] : -1;
    final currentWord   = currentTarget >= 0 ? _grid[currentTarget] : null;

    return Scaffold(
      body: Stack(children: [
        // Fond
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF0A1628), _c.withOpacity(0.7), const Color(0xFF0A1628)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),

        SafeArea(child: Column(children: [
          // ── Header ──
          _buildHeader(),
          const SizedBox(height: 8),

          // ── Carte cible à trouver ──
          if (currentWord != null) _buildTargetCard(currentWord),
          const SizedBox(height: 12),

          // ── Progression ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('$_targetIdx / $_targetCount trouvés',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('$_errors erreur${_errors > 1 ? 's' : ''}',
                    style: TextStyle(color: _errors > 0 ? Colors.orange : Colors.white30, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _targetIdx / _targetCount,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(Colors.amber),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Grille Bingo 3×3 ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: 9,
                itemBuilder: (_, i) => _buildCell(i, currentTarget),
              ),
            ),
          ),

          const SizedBox(height: 12),
          // ── Bouton rejouer le son ──
          if (currentWord != null && !_gameOver)
            GestureDetector(
              onTap: () => TtsService().speak('Trouve : ${currentWord.word}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.volume_up, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Réécouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
        ])),

        // ── Explosion BINGO ──
        if (_gameOver)
          AnimatedBuilder(
            animation: _bingoAnim,
            builder: (_, __) => Stack(children: [
              _ConfettiOverlay(progress: _bingoAnim.value),
              if (_bingoAnim.value < 0.6)
                Center(
                  child: Transform.scale(
                    scale: 0.5 + _bingoAnim.value * 1.5,
                    child: Opacity(
                      opacity: (1 - _bingoAnim.value * 1.5).clamp(0, 1),
                      child: const Text('BINGO!',
                        style: TextStyle(
                          fontSize: 72, fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          shadows: [Shadow(color: Colors.orange, blurRadius: 20)],
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
      ),
      const SizedBox(width: 12),
      Text('🎯 Bingo', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.timer, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text('${_elapsed}s', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    ]),
  );

  Widget _buildTargetCard(Word word) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.6), width: 2),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 16)],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.search, color: Colors.amber, size: 22),
        const SizedBox(width: 12),
        Text('Trouve : ', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
        Text(word.word,
          style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _buildCell(int idx, int currentTarget) {
    final word    = _grid[idx];
    final isOk    = _markedOk.contains(idx);
    final isErr   = _markedErr.contains(idx);
    final isTarget = idx == currentTarget && !isOk;

    Widget cell = GestureDetector(
      onTap: () => _onCellTap(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: isOk
              ? const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF388E3C)])
              : isErr
                  ? const LinearGradient(colors: [Color(0xFFC62828), Color(0xFFE53935)])
                  : LinearGradient(colors: [_c.withOpacity(0.5), _c.withOpacity(0.2)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOk ? Colors.green.shade300 : isErr ? Colors.red.shade300 : Colors.white.withOpacity(0.2),
            width: isOk || isErr ? 2 : 1,
          ),
          boxShadow: isOk
              ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 12)]
              : isErr
                  ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 12)]
                  : [],
        ),
        child: Stack(fit: StackFit.expand, children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(word.imagePath, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(word.word[0],
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                    color: isOk ? Colors.white : Colors.white70)),
              ),
            ),
          ),
          // Overlay correct
          if (isOk)
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 38)),
            ),
          // Overlay erreur
          if (isErr)
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Icon(Icons.close, color: Colors.white, size: 38)),
            ),
          // Nom du mot
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: isOk ? Colors.green.withOpacity(0.8) : Colors.black.withOpacity(0.55),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Text(
                word.word,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ]),
      ),
    );

    // Pulse sur la carte cible courante
    if (isTarget) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
        child: cell,
      );
    }

    return cell;
  }
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
        painter: _ConfettiP(progress: progress),
      ),
    );
  }
}

class _ConfettiP extends CustomPainter {
  final double progress;
  static const _cols = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange];
  const _ConfettiP({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final rng = math.Random(7);
    for (int i = 0; i < 70; i++) {
      final x = rng.nextDouble() * size.width;
      final y = -20.0 + (size.height + 40) * progress + math.sin(progress * 7 + i) * 35;
      final p = Paint()..color = _cols[i % _cols.length].withOpacity((1 - progress).clamp(0, 1));
      final r = Rect.fromCenter(center: Offset(x + math.sin(progress * 4 + i) * 20, y), width: 9, height: 13);
      canvas.save();
      canvas.translate(r.center.dx, r.center.dy);
      canvas.rotate(progress * 9 + i.toDouble());
      canvas.translate(-r.center.dx, -r.center.dy);
      canvas.drawRect(r, p);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _ConfettiP o) => o.progress != progress;
}