// lib/screens/memory_game_screen.dart
// Memory game redesigné pour enfants :
// - Vraies images des assets
// - Fond festif coloré
// - Dos de cartes colorés avec étoile
// - Animation flip 3D
// - Confettis à la victoire
// - Répétition vocale conservée

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../services/tts_service.dart';
import '../services/progress_service.dart';

// ─────────────────────────────────────────────────────────────
// Modèle d'une carte
// ─────────────────────────────────────────────────────────────
class MemCard {
  final Word word;
  bool isFlipped;
  bool isMatched;

  MemCard({
    required this.word,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

// Couleurs des dos de cartes (une couleur par paire)
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

// ─────────────────────────────────────────────────────────────
// Écran principal
// ─────────────────────────────────────────────────────────────
class MemoryGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const MemoryGameScreen({super.key, required this.levelData});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with TickerProviderStateMixin {
  late List<MemCard> cards;
  // index → couleur du dos (pour que les 2 cartes d'une paire aient la même couleur)
  late Map<int, List<Color>> cardColors;

  int score = 0;
  int moves = 0;
  MemCard? firstCard;
  MemCard? secondCard;
  bool checking = false;

  late stt.SpeechToText _stt;
  bool sttReady = false;
  final _tts = TtsService();

  // Animation entrée des cartes
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  // Animation confettis victoire
  late AnimationController _confettiCtrl;
  late Animation<double> _confettiAnim;

  // Stopwatch
  late Stopwatch _sw;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _confettiAnim =
        Tween<double>(begin: 0, end: 1).animate(_confettiCtrl);

    _buildCards();

    _stt = stt.SpeechToText();
    _initStt();

    // Présenter le premier mot après 1s
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _tts.speak(
          'Trouve les paires ! ${widget.levelData.title}',
        );
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _confettiCtrl.dispose();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  void _buildCards() {
    // Prendre 6 mots (adaptatif ou premiers 6)
    final words = widget.levelData.vocabulary.take(6).toList()..shuffle();

    // Créer 2 cartes par mot (paire)
    final temp = <MemCard>[];
    for (final w in words) {
      temp.add(MemCard(word: w));
      temp.add(MemCard(word: w));
    }
    temp.shuffle();
    cards = temp;

    // Assigner une couleur à chaque paire (même couleur pour les 2 cartes de la paire)
    final wordColors = <int, List<Color>>{};
    var colorIdx = 0;
    for (final w in words) {
      wordColors[w.id] = _cardBackColors[colorIdx % _cardBackColors.length];
      colorIdx++;
    }
    cardColors = {
      for (int i = 0; i < cards.length; i++)
        i: wordColors[cards[i].word.id] ??
            [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
    };
  }

  Future<void> _initStt() async {
    try {
      final ok = await _stt.initialize(
        onError: (e) => debugPrint('STT: $e'),
        onStatus: (s) => debugPrint('STT: $s'),
      );
      if (mounted) setState(() => sttReady = ok);
    } catch (_) {}
  }

  // ──────────────────────────────────────────────
  // Logique de jeu
  // ──────────────────────────────────────────────
  void _onTap(int index) {
    if (checking) return;
    if (cards[index].isMatched) return;
    if (cards[index].isFlipped) return;
    if (secondCard != null) return;

    setState(() => cards[index].isFlipped = true);
    _tts.speak(cards[index].word.word);

    if (firstCard == null) {
      firstCard = cards[index];
    } else {
      secondCard = cards[index];
      checking = true;
      moves++;
      Future.delayed(const Duration(milliseconds: 800), _check);
    }
  }

  void _check() {
    if (firstCard!.word.id == secondCard!.word.id) {
      // Paire trouvée !
      _showMatchDialog(firstCard!.word);
    } else {
      // Pas une paire
      setState(() {
        for (final c in cards) {
          if (c == firstCard || c == secondCard) {
            c.isFlipped = false;
          }
        }
        firstCard = null;
        secondCard = null;
        checking = false;
      });
      _tts.speak('Essaie encore !');
    }
  }

  void _showMatchDialog(Word word) {
    _tts.speak('Bravo ! ${word.word}');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MatchDialog(
        word: word,
        tts: _tts,
        onStart: () {
          Navigator.pop(context);
          _startRepetition(word, 1);
        },
      ),
    );
  }

  void _startRepetition(Word word, int repetition) {
    if (repetition > 3) {
      _markMatched(word);
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RepetitionDialog(
        word: word,
        repetitionNumber: repetition,
        speechToText: _stt,
        flutterTts: _tts.raw,
        sttReady: sttReady,
        ttsAvail: _tts.isAvailable,
        onSuccess: () {
          Navigator.pop(ctx);
          _startRepetition(word, repetition + 1);
        },
        onRetry: () {
          Navigator.pop(ctx);
          _startRepetition(word, repetition);
        },
      ),
    );
  }

  void _markMatched(Word word) {
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
      Future.delayed(const Duration(milliseconds: 400), _finish);
    }
  }

  void _finish() {
    _sw.stop();

    // Enregistrer le résultat
    ProgressService().recordScore(
      levelId: widget.levelData.id,
      gameType: 'memory',
      score: score,
      maxScore: cards.length ~/ 2,
      durationSeconds: _sw.elapsed.inSeconds,
    );

    // Lancer les confettis
    _confettiCtrl.forward();
    _tts.speak('Félicitations ! Tu as gagné !');

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _showVictoryDialog();
    });
  }

  void _showVictoryDialog() {
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
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              const Text(
                'Memory terminé !',
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
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < stars ? Icons.star : Icons.star_border,
                      color:
                          i < stars ? Colors.amber : Colors.white.withOpacity(0.3),
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Stats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('🃏', '$score', 'paires'),
                    _statItem('🔄', '$moves', 'coups'),
                    _statItem(
                        '⏱', '${_sw.elapsed.inSeconds}s', 'temps'),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      );

  // ──────────────────────────────────────────────
  // Build UI
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final total = cards.length ~/ 2;

    return WillPopScope(
      onWillPop: () async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('Quitter le jeu ?'),
                content: const Text(
                    'Ta progression sera perdue.'),
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
            // Fond dégradé
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A1628),
                    Color(0xFF0D47A1),
                    Color(0xFF1565C0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Étoiles décoratives
            const _BgStars(),
            // Contenu
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(total),
                  _buildProgressBar(total),
                  Expanded(child: _buildGrid()),
                ],
              ),
            ),
            // Confettis victoire
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
          // Retour
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
                const Text(
                  '🃏  Memory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  widget.levelData.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$score / $total',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$moves 🔄',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score paire${score > 1 ? 's' : ''} trouvée${score > 1 ? 's' : ''} sur $total',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
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
          final animValue = ((_entryAnim.value - delay) / (1 - delay))
              .clamp(0.0, 1.0);
          return Transform.scale(
            scale: animValue,
            child: Opacity(
              opacity: animValue,
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
// Widget d'une seule carte avec animation flip 3D
// ─────────────────────────────────────────────────────────────
class _MemCardWidget extends StatelessWidget {
  final MemCard card;
  final List<Color> backColors;
  final VoidCallback onTap;

  const _MemCardWidget({
    required this.card,
    required this.backColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: card.isMatched ? null : onTap,
      child: TweenAnimationBuilder<double>(
        tween:
            Tween(begin: 0, end: (card.isFlipped || card.isMatched) ? 1 : 0),
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
            child: showFront
                ? _buildFront()
                : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: backColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backColors[0].withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Motif décoratif
          Positioned.fill(
            child: CustomPaint(painter: _CardPatternPainter()),
          ),
          // Étoile centrale
          const Center(
            child: Text('⭐', style: TextStyle(fontSize: 36)),
          ),
          // Coins décoratifs
          Positioned(
            top: 6,
            left: 6,
            child: Text('✨',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5))),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Text('✨',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5))),
          ),
        ],
      ),
    );
  }

  Widget _buildFront() {
    final hasImage = card.word.imagePath.isNotEmpty;
    final isMatched = card.isMatched;

    return Container(
      decoration: BoxDecoration(
        color: isMatched
            ? const Color(0xFF1B5E20)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMatched
              ? Colors.green.shade400
              : backColors[0].withOpacity(0.6),
          width: isMatched ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isMatched ? Colors.green : backColors[0])
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                            card.word.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                card.word.emoji,
                                style: const TextStyle(fontSize: 44),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              card.word.emoji,
                              style: const TextStyle(fontSize: 44),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                // Mot en français
                Text(
                  card.word.word,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isMatched ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Traduction arabe
                if (card.word.traductionArabic != null)
                  Text(
                    card.word.traductionArabic!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMatched
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          // Badge "matched"
          if (isMatched)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Motif décoratif sur le dos des cartes
// ─────────────────────────────────────────────────────────────
class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    // Cercles concentriques décoratifs
    for (double r = 20; r < size.width * 1.5; r += 18) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        r,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
// Dialog : paire trouvée !
// ─────────────────────────────────────────────────────────────
class _MatchDialog extends StatelessWidget {
  final Word word;
  final TtsService tts;
  final VoidCallback onStart;

  const _MatchDialog({
    required this.word,
    required this.tts,
    required this.onStart,
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉 Bonne paire !',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Image du mot
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasImage
                    ? Image.asset(
                        word.imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(word.emoji,
                              style: const TextStyle(fontSize: 64)),
                        ),
                      )
                    : Center(
                        child: Text(word.emoji,
                            style: const TextStyle(fontSize: 64))),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              word.word,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (word.traductionArabic != null)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  word.traductionArabic!,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20),
                ),
              ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => tts.speak(word.word),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_up, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Écouter encore',
                        style: TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Répète le mot 3 fois pour valider !',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.mic, color: Colors.white),
                label: const Text('Commencer la répétition',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
// Dialog : répétition vocale (1/3, 2/3, 3/3)
// ─────────────────────────────────────────────────────────────
class _RepetitionDialog extends StatefulWidget {
  final Word word;
  final int repetitionNumber;
  final stt.SpeechToText speechToText;
  final FlutterTts flutterTts;
  final bool sttReady;
  final bool ttsAvail;
  final VoidCallback onSuccess;
  final VoidCallback onRetry;

  const _RepetitionDialog({
    required this.word,
    required this.repetitionNumber,
    required this.speechToText,
    required this.flutterTts,
    required this.sttReady,
    required this.ttsAvail,
    required this.onSuccess,
    required this.onRetry,
  });

  @override
  State<_RepetitionDialog> createState() => _RepetitionDialogState();
}

class _RepetitionDialogState extends State<_RepetitionDialog>
    with SingleTickerProviderStateMixin {
  bool ttsOn = false;
  bool ready = false;
  bool listening = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _playTts());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    widget.speechToText.stop();
    super.dispose();
  }

  Future<void> _playTts() async {
    if (!widget.ttsAvail) {
      if (mounted) setState(() { ttsOn = false; ready = true; });
      return;
    }
    setState(() { ttsOn = true; ready = false; });
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
            ? 'Répète ce mot : ${widget.word.word}'
            : widget.word.word,
      );
    } catch (_) {
      if (mounted) setState(() { ttsOn = false; ready = true; });
    }
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && ttsOn) setState(() { ttsOn = false; ready = true; });
    });
  }

  Future<void> _listen() async {
    if (!widget.sttReady || listening || ttsOn || !ready) return;
    setState(() => listening = true);
    await widget.flutterTts.stop();
    try {
      await widget.speechToText.listen(
        onResult: (r) {
          if (r.finalResult && mounted) {
            widget.speechToText.stop();
            setState(() => listening = false);
            final rec = r.recognizedWords.toLowerCase().trim();
            if (_match(rec, widget.word.word.toLowerCase())) {
              _snack('✅ Bravo ! Répétition ${widget.repetitionNumber}/3', Colors.green);
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 400), widget.onSuccess);
            } else {
              _snack('❌ Réessaie !', Colors.orange);
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 400), widget.onRetry);
            }
          }
        },
        localeId: 'fr-FR',
        listenFor: const Duration(seconds: 6),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: false,
      );
    } catch (_) {
      setState(() => listening = false);
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
    for (int i = 0; i < f.length; i++) {
      r = r.replaceAll(f[i], t[i]);
    }
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
        c[j + 1] = a[i] == b[j]
            ? p[j]
            : 1 + [p[j], p[j + 1], c[j]].reduce((x, y) => x < y ? x : y);
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur de progression
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final done = i < widget.repetitionNumber - 1;
                final cur  = i == widget.repetitionNumber - 1;
                return Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: done
                        ? Colors.green
                        : cur
                            ? Colors.amber
                            : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cur ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: cur
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              'Répétition ${widget.repetitionNumber} / 3',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasImage
                    ? Image.asset(
                        widget.word.imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(widget.word.emoji,
                              style: const TextStyle(fontSize: 52)),
                        ),
                      )
                    : Center(
                        child: Text(widget.word.emoji,
                            style: const TextStyle(fontSize: 52))),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.word.word,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            if (widget.word.traductionArabic != null)
              Text(
                widget.word.traductionArabic!,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 18),
              ),
            const SizedBox(height: 14),
            // Indicateur d'état
            _buildStatusWidget(),
            const SizedBox(height: 12),
            // Bouton action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _actionCallback(),
                icon: Icon(_actionIcon(), color: Colors.white),
                label: Text(
                  _actionLabel(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _actionColor(),
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

  Widget _buildStatusWidget() {
    if (ttsOn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.purple.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: const Icon(Icons.volume_up,
                    color: Colors.purple, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Écoute bien…',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      );
    }
    if (listening) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: const Icon(Icons.mic, color: Colors.red, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Je t\'écoute… parle !',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      );
    }
    if (ready) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            const Text('Appuie et parle !',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white.withOpacity(0.5)),
        ),
        const SizedBox(width: 8),
        Text('Préparation…',
            style:
                TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
      ],
    );
  }

  VoidCallback? _actionCallback() {
    if (ttsOn || !ready) return null;
    if (listening) return () async {
      await widget.speechToText.stop();
      setState(() => listening = false);
    };
    return _listen;
  }

  IconData _actionIcon() {
    if (listening) return Icons.stop;
    return Icons.mic;
  }

  String _actionLabel() {
    if (ttsOn)     return 'Écoute…';
    if (listening) return 'Arrêter';
    if (ready)     return '🎤  Parler maintenant !';
    return 'Patiente…';
  }

  Color _actionColor() {
    if (listening) return Colors.red;
    if (ready)     return Colors.amber[700]!;
    return Colors.grey;
  }
}

// ─────────────────────────────────────────────────────────────
// Étoiles décoratives de fond
// ─────────────────────────────────────────────────────────────
class _BgStars extends StatelessWidget {
  const _BgStars();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _BgStarPainter());
}

class _BgStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.3);
    const pts = [
      [0.05, 0.03], [0.18, 0.01], [0.30, 0.06], [0.45, 0.02],
      [0.58, 0.05], [0.72, 0.01], [0.85, 0.07], [0.93, 0.03],
      [0.08, 0.12], [0.22, 0.15], [0.36, 0.10], [0.50, 0.14],
      [0.64, 0.09], [0.78, 0.13], [0.91, 0.11],
    ];
    for (final pt in pts) {
      canvas.drawCircle(
          Offset(size.width * pt[0], size.height * pt[1]), 1.3, p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
// Confettis de victoire
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
    final rng = math.Random(99);
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final yBase = -30 + rng.nextDouble() * 50;
      final yEnd  = size.height + 30;
      final y     = yBase + (yEnd - yBase) * progress;
      final swing = math.sin(progress * 10 + i * 0.5) * 40;

      final paint = Paint()
        ..color = _colors[i % _colors.length].withOpacity(
          (1.0 - progress * 0.8).clamp(0, 1),
        );

      final cx = x + swing;
      final cy = y;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(progress * 8 + i * 0.2);
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