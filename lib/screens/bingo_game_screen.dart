// lib/screens/bingo_game_screen.dart
// Bingo festif pour enfants :
// - Grille 3x3 avec vraies images
// - Annonce vocale du mot à trouver
// - Animation de surbrillance + confettis
// - Feedback visuel immédiat (vert/rouge)
// - Sauvegarde automatique dans ProgressService

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../services/tts_service.dart';
import '../services/progress_service.dart';

class BingoGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const BingoGameScreen({super.key, required this.levelData});
  @override
  State<BingoGameScreen> createState() => _BingoGameScreenState();
}

class _BingoGameScreenState extends State<BingoGameScreen>
    with TickerProviderStateMixin {
  // ── État du jeu ──────────────────────────────
  late List<Word> _grid;       // 9 cases de la grille
  late List<bool> _marked;     // cases cochées
  late List<int> _targets;     // indices des cases à trouver (ordre)
  int _targetIndex = 0;        // quelle cible on cherche maintenant
  int _score = 0;
  int _mistakes = 0;
  bool _announcing = false;    // TTS en cours → bloquer les taps
  bool _gameOver = false;
  late Stopwatch _sw;
  final _tts = TtsService();

  // ── Animations ───────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;
  late AnimationController _confettiCtrl;
  late Animation<double> _confettiAnim;
  late AnimationController _wrongCtrl;
  late Animation<double> _wrongAnim;
  int? _lastWrongIndex; // index de la dernière mauvaise réponse (shake)

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();

    // Pulsation de la carte cible
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Entrée animée de la grille
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    // Confettis
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _confettiAnim = Tween<double>(begin: 0, end: 1).animate(_confettiCtrl);

    // Shake mauvaise réponse
    _wrongCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _wrongAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _wrongCtrl, curve: Curves.elasticOut),
    );

    _initGame();
  }

  @override
  void dispose() {
    _gameOver = true;
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _confettiCtrl.dispose();
    _wrongCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  void _initGame() {
    final vocab = [...widget.levelData.vocabulary]..shuffle();
    _grid    = vocab.take(9).toList();
    _marked  = List.filled(9, false);

    // Choisir 5 à 7 cibles selon la taille du vocabulaire
    final targetCount = widget.levelData.vocabulary.length >= 7 ? 6 : 5;
    final indices = List.generate(9, (i) => i)..shuffle();
    _targets = indices.take(targetCount).toList();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && !_gameOver) _announceTarget();
    });
  }

  // ── Annoncer le mot à trouver ────────────────
  Future<void> _announceTarget() async {
    if (!mounted || _gameOver || _targetIndex >= _targets.length) return;
    setState(() => _announcing = true);

    final word = _grid[_targets[_targetIndex]];
    await _tts.speak('Trouve : ${word.word}');

    // Attendre que le TTS finisse (approximatif)
    final duration = 500 + word.word.length * 80;
    await Future.delayed(Duration(milliseconds: duration));

    if (mounted && !_gameOver) setState(() => _announcing = false);
  }

  // ── Tap sur une case ─────────────────────────
  void _onTap(int gridIndex) {
    if (_gameOver || _announcing || _marked[gridIndex]) return;

    final expectedIndex = _targets[_targetIndex];

    if (gridIndex == expectedIndex) {
      // ✅ Bonne réponse
      _tts.speak('Bravo ! ${_grid[gridIndex].word}');
      setState(() {
        _marked[gridIndex] = true;
        _score += 10;
        _targetIndex++;
      });

      if (_targetIndex >= _targets.length) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && !_gameOver) _finish();
        });
      } else {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted && !_gameOver) _announceTarget();
        });
      }
    } else {
      // ❌ Mauvaise réponse
      _mistakes++;
      _lastWrongIndex = gridIndex;
      _wrongCtrl.forward(from: 0);
      _tts.speak('Non ! Cherche encore !');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Text('❌ ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                'Ce n\'est pas ça ! Cherche : ${_grid[_targets[_targetIndex]].word}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ]),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _finish() {
    if (_gameOver) return;
    _gameOver = true;
    _sw.stop();

    ProgressService().recordScore(
      levelId: widget.levelData.id,
      gameType: 'bingo',
      score: _score,
      maxScore: _targets.length * 10,
      durationSeconds: _sw.elapsed.inSeconds,
      errorsCount: _mistakes,
    );

    _confettiCtrl.forward();
    _tts.speak('BINGO ! Félicitations !');

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _showVictoryDialog();
    });
  }

  void _showVictoryDialog() {
    if (!mounted) return;
    final pct = (_score * 100 ~/ (_targets.length * 10));
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
              colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border:
                Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 4),
              const Text(
                'BINGO !',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < stars ? Icons.star : Icons.star_border,
                      color: i < stars
                          ? Colors.amber
                          : Colors.white.withOpacity(0.3),
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('🎯', '${_targets.length}', 'trouvés'),
                    _statItem('❌', '$_mistakes', 'erreurs'),
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
                title: const Text('Quitter le Bingo ?'),
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
            // Fond dégradé violet festif
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A0A1A),
                    Color(0xFF4A148C),
                    Color(0xFF6A1B9A),
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
                  _buildTargetCard(),
                  Expanded(child: _buildGrid()),
                  _buildHint(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // Confettis
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

  // ── Barre du haut ─────────────────────────────
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
                const Text('🎯  Bingo',
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
          // Score
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text('$_score pts',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ]),
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
              '$_targetIndex/${_targets.length}',
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

  // ── Barre de progression ──────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: _targets.isEmpty
              ? 0
              : _targetIndex / _targets.length,
          minHeight: 10,
          backgroundColor: Colors.white.withOpacity(0.15),
          valueColor:
              const AlwaysStoppedAnimation<Color>(Colors.amber),
        ),
      ),
    );
  }

  // ── Carte du mot cible ────────────────────────
  Widget _buildTargetCard() {
    if (_targetIndex >= _targets.length) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎉', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Text('Tous les mots trouvés !',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final currentWord = _grid[_targets[_targetIndex]];
    final hasImage = currentWord.imagePath.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: _announcing ? _pulseAnim.value : 1.0,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6A1B9A).withOpacity(0.8),
                const Color(0xFFAB47BC).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _announcing
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              width: _announcing ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A1B9A).withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Bouton re-écouter
              GestureDetector(
                onTap: () => _tts.speak('Trouve : ${currentWord.word}'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.volume_up,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Image miniature
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: hasImage
                      ? Image.asset(
                          currentWord.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(currentWord.emoji,
                                style: const TextStyle(fontSize: 28)),
                          ),
                        )
                      : Center(
                          child: Text(currentWord.emoji,
                              style: const TextStyle(fontSize: 28))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trouve :',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    Text(
                      currentWord.word,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (currentWord.traductionArabic != null)
                      Text(
                        currentWord.traductionArabic!,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13),
                      ),
                  ],
                ),
              ),
              // Indicateur d'annonce
              if (_announcing)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withOpacity(0.7),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_targetIndex + 1}/${_targets.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Grille 3×3 ───────────────────────────────
  Widget _buildGrid() {
    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: 9,
          itemBuilder: (_, i) {
            final delay = i * 0.07;
            final v =
                ((_entryAnim.value - delay) / (1 - delay)).clamp(0.0, 1.0);

            return Transform.scale(
              scale: v,
              child: Opacity(
                opacity: v,
                child: _buildGridCell(i),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridCell(int i) {
    final word = _grid[i];
    final isMarked = _marked[i];
    final isTarget = !isMarked &&
        _targetIndex < _targets.length &&
        _targets[_targetIndex] == i;
    final isWrong = _lastWrongIndex == i;
    final hasImage = word.imagePath.isNotEmpty;

    return AnimatedBuilder(
      animation: _wrongAnim,
      builder: (_, child) {
        double offsetX = 0;
        if (isWrong && !isMarked) {
          offsetX = math.sin(_wrongAnim.value * math.pi * 5) * 8;
        }
        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: isMarked ? null : () => _onTap(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: isMarked
                ? const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMarked
                  ? Colors.green.shade400
                  : isTarget
                      ? Colors.amber
                      : Colors.white.withOpacity(0.2),
              width: isMarked || isTarget ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isMarked
                    ? Colors.green.withOpacity(0.4)
                    : isTarget
                        ? Colors.amber.withOpacity(0.3)
                        : Colors.black.withOpacity(0.15),
                blurRadius: isMarked || isTarget ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image ou emoji
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: hasImage
                            ? Image.asset(
                                word.imagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(word.emoji,
                                      style:
                                          const TextStyle(fontSize: 36)),
                                ),
                              )
                            : Center(
                                child: Text(word.emoji,
                                    style:
                                        const TextStyle(fontSize: 36))),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.word,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isMarked ? Colors.white : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Overlay "trouvé"
              if (isMarked)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle,
                        color: Colors.white, size: 44),
                  ),
                ),
              // Indicateur cible
              if (isTarget && !_announcing)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hint bas de page ─────────────────────────
  Widget _buildHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Text(
              _announcing
                  ? 'Écoute bien…'
                  : 'Appuie sur le mot annoncé !',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets communs
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
    final rng = math.Random(55);
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = -30 + (size.height + 60) * progress + rng.nextDouble() * 60;
      final sw = math.sin(progress * 10 + i * 0.5) * 40;
      final paint = Paint()
        ..color = _colors[i % _colors.length]
            .withOpacity((1.0 - progress * 0.8).clamp(0, 1));
      canvas.save();
      canvas.translate(x + sw, y);
      canvas.rotate(progress * 9 + i * 0.25);
      canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 7, height: 11), paint);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}