// lib/screens/memory_game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../services/tts_service.dart';
import '../services/progress_service.dart';

class MemCard {
  final Word word;
  bool isFlipped;
  bool isMatched;
  MemCard({required this.word, this.isFlipped = false, this.isMatched = false});
}

const _cardBackColors = [
  [Color(0xFF1565C0), Color(0xFF42A5F5)],
  [Color(0xFF2E7D32), Color(0xFF66BB6A)],
  [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
  [Color(0xFFE65100), Color(0xFFFF7043)],
  [Color(0xFFC62828), Color(0xFFEF5350)],
  [Color(0xFF00695C), Color(0xFF26A69A)],
  [Color(0xFF4527A0), Color(0xFF7E57C2)],
  [Color(0xFF6D4C41), Color(0xFFA1887F)],
];

class MemoryGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const MemoryGameScreen({super.key, required this.levelData});
  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with TickerProviderStateMixin {
  late List<MemCard> cards;
  late Map<int, List<Color>> cardColors;
  int score = 0, moves = 0;
  MemCard? firstCard, secondCard;
  bool checking = false;
  bool _gameOver = false;
  bool _audioUnlocked = false; // déverrouillage Chrome

  late stt.SpeechToText _stt;
  bool sttReady = false;
  final _tts = TtsService();

  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;
  late AnimationController _confettiCtrl;
  late Animation<double> _confettiAnim;
  late Stopwatch _sw;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();

    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    )..forward();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _confettiCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    );
    _confettiAnim = Tween<double>(begin: 0, end: 1).animate(_confettiCtrl);

    _buildCards();
    _initStt();
  }

  @override
  void dispose() {
    _gameOver = true;
    _entryCtrl.dispose();
    _confettiCtrl.dispose();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  // ── Déverrouiller le son au 1er tap ──────────
  void _ensureAudioUnlocked() {
    if (_audioUnlocked) return;
    _audioUnlocked = true;
    _tts.unlockAudio();
    // Annoncer le jeu après déverrouillage
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _tts.speak('Trouve les paires !');
    });
  }

  void _buildCards() {
    final words = widget.levelData.vocabulary.take(6).toList()..shuffle();
    final temp = <MemCard>[];
    for (final w in words) {
      temp.add(MemCard(word: w));
      temp.add(MemCard(word: w));
    }
    temp.shuffle();
    cards = temp;

    final wordColors = <int, List<Color>>{};
    var ci = 0;
    for (final w in words) {
      wordColors[w.id] = _cardBackColors[ci % _cardBackColors.length];
      ci++;
    }
    cardColors = {
      for (int i = 0; i < cards.length; i++)
        i: wordColors[cards[i].word.id] ??
            [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
    };
  }

  Future<void> _initStt() async {
    if (kIsWeb) return;
    try {
      final ok = await _stt.initialize();
      if (mounted) setState(() => sttReady = ok);
    } catch (_) {}
  }

  void _onTap(int index) {
    // Déverrouiller l'audio au 1er tap (obligatoire Chrome)
    _ensureAudioUnlocked();

    if (_gameOver || checking) return;
    if (cards[index].isMatched || cards[index].isFlipped) return;
    if (secondCard != null) return;

    setState(() => cards[index].isFlipped = true);

    // Prononcer le mot retourné
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _tts.speak(cards[index].word.word);
    });

    if (firstCard == null) {
      firstCard = cards[index];
    } else {
      secondCard = cards[index];
      checking = true;
      moves++;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && !_gameOver) _check();
      });
    }
  }

  void _check() {
    if (!mounted || _gameOver) return;
    if (firstCard!.word.id == secondCard!.word.id) {
      // ✅ Paire trouvée
      final matchedWord = firstCard!.word;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _tts.speak('Bravo ! ${matchedWord.word}');
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_gameOver) _showMatchDialog(matchedWord);
      });
    } else {
      // ❌ Pas une paire
      if (mounted) {
        setState(() {
          for (final c in cards) {
            if (c == firstCard || c == secondCard) c.isFlipped = false;
          }
          firstCard = null;
          secondCard = null;
          checking = false;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _tts.speak('Essaie encore !');
        });
      }
    }
  }

  void _showMatchDialog(Word word) {
    if (!mounted || _gameOver) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MatchDialog(
        word: word,
        tts: _tts,
        onContinue: () {
          if (mounted) Navigator.of(context).pop();
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && !_gameOver) {
              // Sur mobile avec STT → répétition
              // Sur web → marquer directement
              if (!kIsWeb && sttReady) {
                _startRepetition(word, 1);
              } else {
                _markMatched(word);
              }
            }
          });
        },
      ),
    );
  }

  void _startRepetition(Word word, int rep) {
    if (!mounted || _gameOver) return;
    if (rep > 3) { _markMatched(word); return; }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RepetitionDialog(
        word: word,
        repetitionNumber: rep,
        speechToText: _stt,
        flutterTts: _tts.raw,
        sttReady: sttReady,
        ttsAvail: true,
        onSuccess: () {
          if (ctx.mounted) Navigator.of(ctx).pop();
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && !_gameOver) _startRepetition(word, rep + 1);
          });
        },
        onRetry: () {
          if (ctx.mounted) Navigator.of(ctx).pop();
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && !_gameOver) _startRepetition(word, rep);
          });
        },
      ),
    );
  }

  void _markMatched(Word word) {
    if (!mounted || _gameOver) return;
    setState(() {
      for (final c in cards) {
        if (c.word.id == word.id) {
          c.isMatched = true;
          c.isFlipped = false;
        }
      }
      score++;
      firstCard = null;
      secondCard = null;
      checking = false;
    });
    if (cards.every((c) => c.isMatched)) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !_gameOver) _finish();
      });
    }
  }

  void _finish() {
    if (_gameOver) return;
    _gameOver = true;
    _sw.stop();

    ProgressService().recordScore(
      levelId: widget.levelData.id,
      gameType: 'memory',
      score: score,
      maxScore: cards.length ~/ 2,
      durationSeconds: _sw.elapsed.inSeconds,
    );

    _confettiCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _tts.speak('Félicitations ! Tu as gagné !');
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _showVictoryDialog();
    });
  }

  void _showVictoryDialog() {
    if (!mounted) return;
    final pct = (score / (cards.length ~/ 2) * 100).round();
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
              colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
            boxShadow: [BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 30, offset: const Offset(0, 10),
            )],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              const Text('Memory terminé !',
                  style: TextStyle(color: Colors.white, fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: i < stars ? Colors.amber : Colors.white.withOpacity(0.3),
                    size: 44,
                  ),
                )),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('🃏', '$score', 'paires'),
                    _statItem('🔄', '$moves', 'coups'),
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
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
          Text(value, style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(
              color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final total = cards.length ~/ 2;
    return WillPopScope(
      onWillPop: () async {
        if (_gameOver) return true;
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Quitter le jeu ?'),
            content: const Text('Ta progression sera perdue.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Continuer')),
              TextButton(onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Quitter',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A1628), Color(0xFF0D47A1), Color(0xFF1565C0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const _BgStars(),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(total),
                  _buildProgressBar(total),
                  // Bandeau "Appuie pour activer le son" si pas encore déverrouillé
                  if (!_audioUnlocked)
                    GestureDetector(
                      onTap: _ensureAudioUnlocked,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volume_up, color: Colors.amber, size: 16),
                            SizedBox(width: 8),
                            Text(
                              '🔊 Appuie ici pour activer le son !',
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(child: _buildGrid()),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _confettiAnim,
              builder: (_, __) => _ConfettiLayer(progress: _confettiAnim.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38, height: 38,
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
                const Text('🃏  Memory', style: TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w900)),
                Text(widget.levelData.title, style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.favorite, color: Colors.red, size: 14),
              const SizedBox(width: 4),
              Text('$score / $total', style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('$moves 🔄', style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : score / total,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(height: 4),
          Text('$score paire${score > 1 ? 's' : ''} sur $total',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (_, __) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final delay = i * 0.06;
          final v = ((_entryAnim.value - delay) / (1 - delay)).clamp(0.0, 1.0);
          return Transform.scale(
            scale: v,
            child: Opacity(
              opacity: v,
              child: _MemCardWidget(
                card: cards[i],
                backColors: cardColors[i] ??
                    [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                onTap: () => _onTap(i),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _MemCardWidget extends StatelessWidget {
  final MemCard card;
  final List<Color> backColors;
  final VoidCallback onTap;
  const _MemCardWidget({required this.card, required this.backColors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: card.isMatched ? null : onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (card.isFlipped || card.isMatched) ? 1 : 0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        builder: (_, value, __) {
          final angle = value * math.pi;
          final showFront = angle > math.pi / 2;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(showFront ? angle - math.pi : angle),
            alignment: Alignment.center,
            child: showFront ? _buildFront() : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: backColors, begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: backColors[0].withOpacity(0.4),
            blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _CardPatternPainter())),
        const Center(child: Text('⭐', style: TextStyle(fontSize: 36))),
        Positioned(top: 6, left: 6, child: Text('✨',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)))),
        Positioned(bottom: 6, right: 6, child: Text('✨',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)))),
      ]),
    );
  }

  Widget _buildFront() {
    final hasImage = card.word.imagePath.isNotEmpty;
    final isMatched = card.isMatched;
    return Container(
      decoration: BoxDecoration(
        color: isMatched ? const Color(0xFF1B5E20) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMatched ? Colors.green.shade400 : backColors[0].withOpacity(0.6),
          width: isMatched ? 2.5 : 1.5,
        ),
        boxShadow: [BoxShadow(
          color: (isMatched ? Colors.green : backColors[0]).withOpacity(0.3),
          blurRadius: 8, offset: const Offset(0, 3),
        )],
      ),
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: hasImage
                      ? Image.asset(card.word.imagePath, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(card.word.emoji,
                                style: const TextStyle(fontSize: 44))))
                      : Center(child: Text(card.word.emoji,
                          style: const TextStyle(fontSize: 44))),
                ),
              ),
              const SizedBox(height: 6),
              Text(card.word.word, textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13,
                      color: isMatched ? Colors.white : Colors.black87),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (card.word.traductionArabic != null)
                Text(card.word.traductionArabic!, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11,
                        color: isMatched
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey[600])),
            ],
          ),
        ),
        if (isMatched)
          Positioned(top: 4, right: 4,
            child: Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                  color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double r = 15; r < size.width * 1.5; r += 15) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), r, p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
// Dialog paire trouvée — simplifié pour web
// ─────────────────────────────────────────────────────────────
class _MatchDialog extends StatelessWidget {
  final Word word;
  final TtsService tts;
  final VoidCallback onContinue;

  const _MatchDialog({
    required this.word, required this.tts, required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = word.imagePath.isNotEmpty;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4),
              blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉 Bonne paire !', style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasImage
                    ? Image.asset(word.imagePath, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(word.emoji, style: const TextStyle(fontSize: 64))))
                    : Center(child: Text(word.emoji,
                        style: const TextStyle(fontSize: 64))),
              ),
            ),
            const SizedBox(height: 12),
            Text(word.word, style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
            if (word.traductionArabic != null)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(word.traductionArabic!, style: const TextStyle(
                    color: Colors.white, fontSize: 20)),
              ),
            const SizedBox(height: 10),
            // Bouton écouter
            GestureDetector(
              onTap: () => tts.speak(word.word),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.volume_up, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('🔊 Écouter le mot', style: TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  kIsWeb ? 'Continuer ! →' : '🎤 Répéter le mot',
                  style: const TextStyle(color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dialog répétition vocale (mobile uniquement)
// ─────────────────────────────────────────────────────────────
class _RepetitionDialog extends StatefulWidget {
  final Word word;
  final int repetitionNumber;
  final stt.SpeechToText speechToText;
  final FlutterTts flutterTts;
  final bool sttReady, ttsAvail;
  final VoidCallback onSuccess, onRetry;
  const _RepetitionDialog({
    required this.word, required this.repetitionNumber,
    required this.speechToText, required this.flutterTts,
    required this.sttReady, required this.ttsAvail,
    required this.onSuccess, required this.onRetry,
  });
  @override
  State<_RepetitionDialog> createState() => _RepetitionDialogState();
}

class _RepetitionDialogState extends State<_RepetitionDialog>
    with SingleTickerProviderStateMixin {
  bool ttsOn = false, ready = false, listening = false;
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _playTts());
  }

  @override
  void dispose() {
    _pulse.dispose();
    try { widget.speechToText.stop(); } catch (_) {}
    super.dispose();
  }

  Future<void> _playTts() async {
    if (!widget.ttsAvail) {
      if (mounted) setState(() { ttsOn = false; ready = true; });
      return;
    }
    if (mounted) setState(() { ttsOn = true; ready = false; });
    widget.flutterTts.setCompletionHandler(() {
      if (mounted) setState(() { ttsOn = false; ready = true; });
    });
    widget.flutterTts.setErrorHandler((_) {
      if (mounted) setState(() { ttsOn = false; ready = true; });
    });
    try {
      await widget.flutterTts.stop();
      await widget.flutterTts.speak(
          widget.repetitionNumber == 1
              ? 'Répète : ${widget.word.word}' : widget.word.word);
    } catch (_) {
      if (mounted) setState(() { ttsOn = false; ready = true; });
    }
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && ttsOn) setState(() { ttsOn = false; ready = true; });
    });
  }

  Future<void> _listen() async {
    if (!widget.sttReady || listening || ttsOn || !ready) return;
    if (mounted) setState(() => listening = true);
    try {
      await widget.speechToText.listen(
        onResult: (r) {
          if (r.finalResult && mounted) {
            widget.speechToText.stop();
            if (mounted) setState(() => listening = false);
            final rec = r.recognizedWords.toLowerCase().trim();
            final ok = _match(rec, widget.word.word.toLowerCase());
            _snack(ok ? '✅ ${widget.repetitionNumber}/3 !' : '❌ Réessaie !',
                ok ? Colors.green : Colors.orange);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) { if (ok) widget.onSuccess(); else widget.onRetry(); }
            });
          }
        },
        localeId: 'fr-FR',
        listenFor: const Duration(seconds: 6),
        pauseFor: const Duration(seconds: 2),
        partialResults: false,
        cancelOnError: false,
      );
    } catch (_) {
      if (mounted) setState(() => listening = false);
      widget.onRetry();
    }
  }

  bool _match(String a, String b) {
    final na = _norm(a), nb = _norm(b);
    return na.contains(nb) || nb.contains(na) || _lev(na, nb) <= 2;
  }

  String _norm(String s) {
    const f = 'àâäæçéèêëìîïòôöœùûüñ';
    const t = 'aaaaaaceeeeiioooeuuun';
    var r = s.toLowerCase();
    for (int i = 0; i < f.length; i++) r = r.replaceAll(f[i], t[i]);
    return r.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  int _lev(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    List<int> p = List.generate(b.length + 1, (i) => i);
    for (int i = 0; i < a.length; i++) {
      List<int> c = [i + 1, ...List.filled(b.length, 0)];
      for (int j = 0; j < b.length; j++) {
        c[j+1] = a[i]==b[j] ? p[j] : 1+[p[j],p[j+1],c[j]].reduce((x,y)=>x<y?x:y);
      }
      p = c;
    }
    return p[b.length];
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 15)),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.word.imagePath.isNotEmpty;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur progression 1/3 2/3 3/3
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final done = i < widget.repetitionNumber - 1;
                final cur  = i == widget.repetitionNumber - 1;
                return Container(
                  width: 32, height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: done ? Colors.green : cur ? Colors.amber
                        : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text('${i+1}', style: TextStyle(
                            color: cur ? Colors.white : Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text('Répétition ${widget.repetitionNumber} / 3',
                style: const TextStyle(color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasImage
                    ? Image.asset(widget.word.imagePath, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(widget.word.emoji,
                              style: const TextStyle(fontSize: 52))))
                    : Center(child: Text(widget.word.emoji,
                        style: const TextStyle(fontSize: 52))),
              ),
            ),
            const SizedBox(height: 10),
            Text(widget.word.word, style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
            if (widget.word.traductionArabic != null)
              Text(widget.word.traductionArabic!, style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 18)),
            const SizedBox(height: 14),
            // Statut animé
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (ttsOn ? Colors.purple : listening ? Colors.red
                      : ready ? Colors.green : Colors.grey).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Transform.scale(
                    scale: (ttsOn || listening) ? _pulseAnim.value : 1.0,
                    child: Icon(
                      ttsOn ? Icons.volume_up : listening ? Icons.mic
                          : ready ? Icons.mic : Icons.hourglass_empty,
                      color: Colors.white, size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ttsOn ? 'Écoute bien…'
                        : listening ? 'Je t\'écoute…'
                        : ready ? 'Appuie et parle !'
                        : 'Préparation…',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (ttsOn || !ready) ? null
                    : listening ? () async {
                        await widget.speechToText.stop();
                        if (mounted) setState(() => listening = false);
                      }
                    : _listen,
                icon: Icon(listening ? Icons.stop : Icons.mic, color: Colors.white),
                label: Text(
                  ttsOn ? 'Écoute…' : listening ? 'Arrêter'
                      : ready ? '🎤  Parler !' : 'Patiente…',
                  style: const TextStyle(color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: listening ? Colors.red : Colors.amber[700],
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      [0.05,0.03],[0.18,0.01],[0.30,0.06],[0.45,0.02],[0.60,0.05],
      [0.74,0.01],[0.87,0.07],[0.95,0.03],[0.09,0.13],[0.23,0.16],
      [0.37,0.11],[0.51,0.15],[0.65,0.10],[0.79,0.14],[0.93,0.12],
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
    final rng = math.Random(99);
    for (int i = 0; i < 80; i++) {
      final x   = rng.nextDouble() * size.width;
      final y   = -30 + (size.height + 60) * progress + rng.nextDouble() * 60;
      final sw  = math.sin(progress * 10 + i * 0.5) * 40;
      final paint = Paint()
        ..color = _colors[i % _colors.length]
            .withOpacity((1.0 - progress * 0.8).clamp(0, 1));
      canvas.save();
      canvas.translate(x + sw, y);
      canvas.rotate(progress * 9 + i * 0.25);
      canvas.drawRect(Rect.fromCenter(
          center: Offset.zero, width: 7, height: 11), paint);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}