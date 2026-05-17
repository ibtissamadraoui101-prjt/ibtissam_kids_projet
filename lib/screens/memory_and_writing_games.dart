import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../services/tts_service.dart';
import '../widgets/blob_mascot.dart';

// ════════════════════════════════════════════════════════════
// MEMORY GAME - Matching letter ↔ image pairs
// ════════════════════════════════════════════════════════════
class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({Key? key}) : super(key: key);

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with TickerProviderStateMixin {
  static const List<_MemoryCard> cards = [
    _MemoryCard(letter: 'A', emoji: '✈️', word: 'Avion', pairId: 0),
    _MemoryCard(letter: 'A', emoji: '✈️', word: 'Avion', pairId: 0),
    _MemoryCard(letter: 'B', emoji: '🎈', word: 'Ballon', pairId: 1),
    _MemoryCard(letter: 'B', emoji: '🎈', word: 'Ballon', pairId: 1),
    _MemoryCard(letter: 'C', emoji: '🐱', word: 'Chat', pairId: 2),
    _MemoryCard(letter: 'C', emoji: '🐱', word: 'Chat', pairId: 2),
  ];

  late List<_MemoryCardState> cardStates;
  int? firstFlipped;
  int? secondFlipped;
  bool _isChecking = false;
  int _matched = 0;
  int _moves = 0;
  late AnimationController _matchCtrl;

  @override
  void initState() {
    super.initState();
    _matchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Shuffle and initialize cards
    final shuffled = List<_MemoryCard>.from(cards);
    shuffled.shuffle(Random());

    cardStates = shuffled
        .map((card) => _MemoryCardState(card: card, flipped: false))
        .toList();

    TtsService().speak('Trouve les paires ! Touche les cartes.');
  }

  @override
  void dispose() {
    _matchCtrl.dispose();
    super.dispose();
  }

  void _onCardTap(int index) {
    if (_isChecking || cardStates[index].matched) return;

    HapticFeedback.lightImpact();

    if (firstFlipped == null) {
      setState(() {
        firstFlipped = index;
        cardStates[index].flipped = true;
      });
    } else if (secondFlipped == null && index != firstFlipped) {
      setState(() {
        secondFlipped = index;
        cardStates[index].flipped = true;
      });

      _isChecking = true;
      _moves++;

      Future.delayed(const Duration(milliseconds: 600), () {
        final match = cardStates[firstFlipped!].card.pairId ==
            cardStates[secondFlipped!].card.pairId;

        if (match) {
          HapticFeedback.mediumImpact();
          TtsService().speak('Excellent ! Tu as trouvé une paire !');
          setState(() {
            cardStates[firstFlipped!].matched = true;
            cardStates[secondFlipped!].matched = true;
            _matched++;
          });

          if (_matched == 3) {
            // All matched!
            Future.delayed(const Duration(milliseconds: 800), () {
              _showGameComplete();
            });
          }
        } else {
          HapticFeedback.lightImpact();
          TtsService().speak('Pas celle-ci, essaie encore !');
          setState(() {
            cardStates[firstFlipped!].flipped = false;
            cardStates[secondFlipped!].flipped = false;
          });
        }

        setState(() {
          firstFlipped = null;
          secondFlipped = null;
          _isChecking = false;
        });
      });
    }
  }

  void _showGameComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GameCompleteDialog(
        moves: _moves,
        onNext: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const WritingGameScreen(),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 28),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Paires: $_matched/3 | Coups: $_moves',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BlobMascot(size: 80, animate: true),
                      const SizedBox(height: 16),
                      const Text(
                        'Trouve les paires !',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Card grid 2x3
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: GridView.builder(
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                          itemCount: cardStates.length,
                          itemBuilder: (_, i) => _MemoryCardWidget(
                            cardState: cardStates[i],
                            onTap: () => _onCardTap(i),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryCardWidget extends StatefulWidget {
  final _MemoryCardState cardState;
  final VoidCallback onTap;

  const _MemoryCardWidget({
    required this.cardState,
    required this.onTap,
  });

  @override
  State<_MemoryCardWidget> createState() => _MemoryCardWidgetState();
}

class _MemoryCardWidgetState extends State<_MemoryCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_MemoryCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cardState.flipped != oldWidget.cardState.flipped) {
      if (widget.cardState.flipped) {
        _flipCtrl.forward();
      } else {
        _flipCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.cardState.matched ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (_, __) {
          final isBack = _flipAnim.value < 0.5;
          final angle = _flipAnim.value * pi;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Container(
              decoration: BoxDecoration(
                color: isBack ? const Color(0xFF2196F3) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
                border: widget.cardState.matched
                    ? Border.all(
                        color: const Color(0xFF4CAF50),
                        width: 3,
                      )
                    : null,
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(angle > pi / 2 ? pi : 0),
                child: isBack
                    ? Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('?',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                )),
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.cardState.card.emoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.cardState.card.letter,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MemoryCard {
  final String letter;
  final String emoji;
  final String word;
  final int pairId;

  const _MemoryCard({
    required this.letter,
    required this.emoji,
    required this.word,
    required this.pairId,
  });
}

class _MemoryCardState {
  final _MemoryCard card;
  bool flipped;
  bool matched;

  _MemoryCardState({
    required this.card,
    required this.flipped,
    this.matched = false,
  });
}

class _GameCompleteDialog extends StatelessWidget {
  final int moves;
  final VoidCallback onNext;

  const _GameCompleteDialog({
    required this.moves,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
            )
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BlobMascot(size: 100, animate: true),
            const SizedBox(height: 16),
            const Text(
              'Bravo ! 🎉',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu as trouvé toutes les paires en $moves coups !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Prochain Jeu →',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// WRITING GAME - Trace letter with finger
// ════════════════════════════════════════════════════════════
class WritingGameScreen extends StatefulWidget {
  const WritingGameScreen({Key? key}) : super(key: key);

  @override
  State<WritingGameScreen> createState() => _WritingGameScreenState();
}

class _WritingGameScreenState extends State<WritingGameScreen>
    with TickerProviderStateMixin {
  static const List<String> letters = ['A', 'B', 'C'];
  int _currentLetterIndex = 0;
  final List<Offset?> _strokes = [];
  bool _showGuide = true;
  bool _completed = false;
  late AnimationController _completeCtrl;

  @override
  void initState() {
    super.initState();
    _completeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    TtsService().speak('Écris la lettre ${letters[_currentLetterIndex]} !');
  }

  @override
  void dispose() {
    _completeCtrl.dispose();
    super.dispose();
  }

  void _clearStrokes() {
    setState(() {
      _strokes.clear();
      _completed = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _strokes.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Simple heuristic: if enough strokes were made, consider it complete
    if (_strokes.length > 20) {
      setState(() => _completed = true);
      HapticFeedback.heavyImpact();
      _completeCtrl.forward();
      TtsService().speak('Bravo ! Excellente écriture !');

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_currentLetterIndex < letters.length - 1) {
          setState(() {
            _currentLetterIndex++;
            _strokes.clear();
            _completed = false;
            _completeCtrl.reset();
          });
          TtsService()
              .speak('Écris la lettre ${letters[_currentLetterIndex]} !');
        } else {
          _showCompletion();
        }
      });
    }
  }

  void _showCompletion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompletionDialog(
        onContinue: () {
          Navigator.pop(context);
          Navigator.pop(context); // Back to previous screen
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 28),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentLetterIndex + 1}/${letters.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BlobMascot(size: 80, animate: true),
                    const SizedBox(height: 16),
                    Text(
                      'Écris la lettre ${letters[_currentLetterIndex]}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Drawing canvas
                    GestureDetector(
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: Container(
                        width: size.width * 0.85,
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF9800),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Guide letter (faint)
                            if (_showGuide)
                              Center(
                                child: Text(
                                  letters[_currentLetterIndex],
                                  style: TextStyle(
                                    fontSize: 200,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey.withOpacity(0.1),
                                  ),
                                ),
                              ),
                            // User strokes
                            CustomPaint(
                              painter: _StrokePainter(_strokes),
                              size: Size(size.width * 0.85, 280),
                            ),
                            // Success checkmark
                            if (_completed)
                              Center(
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0, end: 1)
                                      .animate(_completeCtrl),
                                  child: const Text(
                                    '✅',
                                    style: TextStyle(fontSize: 80),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _clearStrokes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Effacer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _showGuide = !_showGuide),
                          icon: Icon(_showGuide
                              ? Icons.visibility
                              : Icons.visibility_off),
                          label: Text(_showGuide ? 'Masquer' : 'Afficher'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<Offset?> strokes;

  _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < strokes.length - 1; i++) {
      if (strokes[i] != null && strokes[i + 1] != null) {
        canvas.drawLine(strokes[i]!, strokes[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length;
  }
}

class _CompletionDialog extends StatelessWidget {
  final VoidCallback onContinue;

  const _CompletionDialog({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
            )
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BlobMascot(size: 100, animate: true),
            const SizedBox(height: 16),
            const Text(
              'Fantastique ! 🌟',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu as terminé toutes les leçons du jour !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⭐ +30 Points',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF9800),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Reviens Demain ! 🏝️',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
