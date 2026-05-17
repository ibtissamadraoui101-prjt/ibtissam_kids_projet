import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/tts_service.dart';
import '../services/progress_service.dart';
import '../widgets/blob_mascot.dart';
import '../widgets/toy_button.dart';
import 'memory_and_writing_games.dart';

class DailyLearningScreen extends StatefulWidget {
  const DailyLearningScreen({Key? key}) : super(key: key);

  @override
  State<DailyLearningScreen> createState() => _DailyLearningScreenState();
}

class _DailyLearningScreenState extends State<DailyLearningScreen>
    with TickerProviderStateMixin {
  // Today's 3 letters (hardcoded for now, will be dynamic)
  static const List<_LetterData> todaysLetters = [
    _LetterData(
      letter: 'A',
      word: 'Avion',
      wordEn: 'Airplane',
      emoji: '✈️',
    ),
    _LetterData(
      letter: 'B',
      word: 'Ballon',
      wordEn: 'Balloon',
      emoji: '🎈',
    ),
    _LetterData(
      letter: 'C',
      word: 'Chat',
      wordEn: 'Cat',
      emoji: '🐱',
    ),
  ];

  int _currentLetterIndex = 0;
  late AnimationController _letterCtrl;
  late Animation<double> _letterScale;
  late Animation<double> _letterOpacity;
  bool _autoPlayAudio = true;

  @override
  void initState() {
    super.initState();
    _letterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _letterScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _letterCtrl, curve: Curves.elasticOut),
    );

    _letterOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _letterCtrl, curve: Curves.easeIn),
    );

    _letterCtrl.forward();
    _playLetterAudio();
  }

  @override
  void dispose() {
    _letterCtrl.dispose();
    super.dispose();
  }

  void _playLetterAudio() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      final data = todaysLetters[_currentLetterIndex];
      TtsService().speak(data.letter);
    }
  }

  void _nextLetter() {
    if (_currentLetterIndex < todaysLetters.length - 1) {
      HapticFeedback.mediumImpact();
      setState(() => _currentLetterIndex++);
      _letterCtrl.reset();
      _letterCtrl.forward();
      _playLetterAudio();
    } else {
      // All 3 letters shown, move to recognition game
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const RecognitionGameScreen(),
        ),
      );
    }
  }

  void _prevLetter() {
    if (_currentLetterIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentLetterIndex--);
      _letterCtrl.reset();
      _letterCtrl.forward();
      _playLetterAudio();
    }
  }

  void _repeatSound() {
    HapticFeedback.lightImpact();
    _playLetterAudio();
  }

  @override
  Widget build(BuildContext context) {
    final data = todaysLetters[_currentLetterIndex];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFF8E1),
              const Color(0xFFFFE0B2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── TOP: Progress & Blob ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          size: 28, color: Color(0xFF333)),
                    ),
                    // Day progress
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Text(
                        '${_currentLetterIndex + 1}/${todaysLetters.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // balance
                  ],
                ),
              ),

              // ── MIDDLE: Large Letter + Word ──
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Letter itself - HUGE
                      ScaleTransition(
                        scale: _letterScale,
                        child: FadeTransition(
                          opacity: _letterOpacity,
                          child: Text(
                            data.letter,
                            style: const TextStyle(
                              fontSize: 180,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1565C0),
                              height: 0.8,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Word + Emoji
                      Column(
                        children: [
                          Text(
                            data.emoji,
                            style: const TextStyle(fontSize: 72),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            data.word,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF333),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.wordEn,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── BOTTOM: Blob Guide + Actions ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Blob mascot mini
                    const BlobMascot(size: 80, animate: true),
                    const SizedBox(height: 12),

                    // Speech bubble
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Écoute et répète ! 🎤',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1565C0),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Repeat sound
                        _ActionButton(
                          icon: '🔊',
                          label: 'Rejouer',
                          onPressed: _repeatSound,
                          color: const Color(0xFFFFC107),
                        ),

                        // Previous
                        if (_currentLetterIndex > 0)
                          _ActionButton(
                            icon: '⬅️',
                            label: 'Précédent',
                            onPressed: _prevLetter,
                            color: const Color(0xFF9C27B0),
                          ),

                        // Next / Continue
                        _ActionButton(
                          icon: _currentLetterIndex < todaysLetters.length - 1
                              ? '➡️'
                              : '✅',
                          label: _currentLetterIndex < todaysLetters.length - 1
                              ? 'Suivant'
                              : 'Continuer',
                          onPressed: _nextLetter,
                          color: const Color(0xFF4CAF50),
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

class _ActionButton extends StatefulWidget {
  final String icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Text(widget.icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterData {
  final String letter;
  final String word;
  final String wordEn;
  final String emoji;

  const _LetterData({
    required this.letter,
    required this.word,
    required this.wordEn,
    required this.emoji,
  });
}

// ════════════════════════════════════════════════════════════
// RECOGNITION GAME - choose correct letter
// ════════════════════════════════════════════════════════════
class RecognitionGameScreen extends StatefulWidget {
  const RecognitionGameScreen({Key? key}) : super(key: key);

  @override
  State<RecognitionGameScreen> createState() => _RecognitionGameScreenState();
}

class _RecognitionGameScreenState extends State<RecognitionGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _feedbackCtrl;
  bool _answered = false;
  int _score = 0;
  int _round = 0;
  static const int totalRounds = 3;

  final List<_RecognitionRound> rounds = [
    _RecognitionRound(
      prompt: 'Où est le A ?',
      options: ['A', 'B', 'C'],
      correct: 0,
    ),
    _RecognitionRound(
      prompt: 'Où est le B ?',
      options: ['C', 'B', 'A'],
      correct: 1,
    ),
    _RecognitionRound(
      prompt: 'Où est le C ?',
      options: ['B', 'A', 'C'],
      correct: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    if (_answered) return;

    HapticFeedback.mediumImpact();
    _answered = true;

    final isCorrect = index == rounds[_round].correct;
    if (isCorrect) {
      _score++;
      TtsService().speak('Bravo ! Excellent !');
    } else {
      TtsService().speak(
          'Pas grave, essaie encore ! La réponse est ${rounds[_round].options[rounds[_round].correct]}');
    }

    _feedbackCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          if (_round < totalRounds - 1) {
            setState(() {
              _round++;
              _answered = false;
              _feedbackCtrl.reset();
            });
          } else {
            // Game complete - navigate to memory game
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const MemoryGameScreen(),
              ),
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final round = rounds[_round];
    const btnColors = [
      Color(0xFFFF5252),
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
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
                    Text(
                      '${_round + 1}/$totalRounds',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '⭐ $_score',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7A4F00),
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
                      const BlobMascot(size: 100, animate: true),
                      const SizedBox(height: 20),
                      Text(
                        round.prompt,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          round.options.length,
                          (i) => GestureDetector(
                            onTap: () => _selectOption(i),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: btnColors[i],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: btnColors[i].withOpacity(0.4),
                                      blurRadius: 10,
                                    )
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    round.options[i],
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
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

class _RecognitionRound {
  final String prompt;
  final List<String> options;
  final int correct;

  _RecognitionRound({
    required this.prompt,
    required this.options,
    required this.correct,
  });
}
