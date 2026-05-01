// lib/screens/quiz_game_screen.dart
// 🔊 Sons intégrés : click, correct, wrong, timeout, levelDone, star

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/game_models.dart';
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../services/sound_service.dart';   // ✅
import '../services/adaptive_engine.dart';

class QuizGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const QuizGameScreen({super.key, required this.levelData});
  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen>
    with TickerProviderStateMixin {

  late final AdaptiveEngine _ai;
  late final AdaptiveTier   _tier;
  late int _optionCount;

  late List<_QuizQ> _questions;
  int  _currentIndex = 0;
  int  _score        = 0;
  int  _errors       = 0;
  int? _selectedId;
  bool _isAnswered = false;
  final Map<int, int> _wordQualities = {};

  late AnimationController _timerCtrl;
  late Animation<double>   _timerAnim;
  Timer? _autoNext;
  static const _timeSec = 15;
  double _timeLeft = _timeSec.toDouble();

  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;
  late AnimationController _shakeCtrl;
  late Animation<Offset>   _shakeAnim;

  Color get _lc {
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
    _ai          = AdaptiveEngine();
    _tier        = _ai.tierForLevel(widget.levelData.id);
    _optionCount = _ai.quizOptions(_tier);

    _timerCtrl = AnimationController(vsync: this, duration: Duration(seconds: _timeSec));
    _timerAnim = Tween<double>(begin: 1, end: 0).animate(_timerCtrl)
      ..addListener(() {
        if (mounted) setState(() => _timeLeft = _timerAnim.value * _timeSec);
      });

    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _slideAnim = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.04, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.04, 0), end: const Offset(0.04, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.04, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _buildQuestions();

    // ✅ Musique Quiz + son démarrage
    SoundService().switchMusic('quiz');
    Future.delayed(const Duration(milliseconds: 300), () {
      SoundService().play(SoundEffect.gameStart);
    });

    _startQ();
  }

  void _buildQuestions() {
    final words = _ai.selectWords(widget.levelData.vocabulary, count: 10);
    _questions = words.map((correct) {
      final others = widget.levelData.vocabulary
          .where((w) => w.id != correct.id).toList()..shuffle();
      final opts = [correct, ...others.take(_optionCount - 1)]..shuffle();
      return _QuizQ(correct: correct, options: opts);
    }).toList();
  }

  void _startQ() {
    _selectedId = null;
    _isAnswered = false;
    _timeLeft   = _timeSec.toDouble();
    _timerCtrl.reset();
    _slideCtrl.forward(from: 0);
    _timerCtrl.removeStatusListener(_onTimerDone);
    _timerCtrl.addStatusListener(_onTimerDone);
    _timerCtrl.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) TtsService().speak(_questions[_currentIndex].correct.word);
    });
  }

  void _onTimerDone(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_isAnswered) {
      _timerCtrl.removeStatusListener(_onTimerDone);
      SoundService().play(SoundEffect.timeout); // ✅
      _onAnswer(null);
    }
  }

  void _onAnswer(int? id) {
    if (_isAnswered) return;
    _autoNext?.cancel();
    _timerCtrl.stop();
    _timerCtrl.removeStatusListener(_onTimerDone);
    HapticFeedback.lightImpact();

    final q       = _questions[_currentIndex];
    final correct = id == q.correct.id;
    final quality = _ai.computeQuality(
        isCorrect: correct, responseTimeSeconds: _timeSec - _timeLeft);
    _wordQualities[q.correct.id] = quality;

    setState(() { _selectedId = id; _isAnswered = true; });

    if (correct) {
      _score += 10 + (_timeLeft > 10 ? 5 : 0);
      HapticFeedback.mediumImpact();
      SoundService().correct(); // ✅
      TtsService().speak('Bravo ! ${q.correct.word} !');
    } else {
      _errors++;
      HapticFeedback.vibrate();
      SoundService().wrong(); // ✅
      _shakeCtrl.forward(from: 0);
      TtsService().speak('La réponse est ${q.correct.word}.');
    }

    _autoNext = Timer(const Duration(seconds: 2), _nextQ);
  }

  void _nextQ() {
    _autoNext?.cancel();
    if (_currentIndex < _questions.length - 1) {
      SoundService().click(); // ✅ son navigation
      setState(() => _currentIndex++);
      _startQ();
    } else {
      _finish();
    }
  }

  void _finish() {
    ProgressService().recordScore(
      levelId:         widget.levelData.id,
      gameType:        'quiz',
      score:           _score,
      maxScore:        _questions.length * 10,
      durationSeconds: 0,
      errorsCount:     _errors,
      wordQualities:   _wordQualities,
    );
    final pct = (_score / (_questions.length * 10) * 100).round();

    // ✅ Sons de fin
    SoundService().star();
    Future.delayed(const Duration(milliseconds: 500), () {
      SoundService().levelDone();
    });

    TtsService().speak(_ai.encouragementMessage(pct));
    _showResult();
  }

  void _showResult() {
    final pct   = (_score / (_questions.length * 10) * 100).clamp(0, 100).round();
    final stars = pct >= 80 ? 3 : pct >= 60 ? 2 : 1;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_lc, _lc.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _lc.withValues(alpha: 0.5), blurRadius: 24)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('❓', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 6),
            const Text('Quiz terminé !',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Icon(
                i < stars ? Icons.star : Icons.star_border,
                color: Colors.amber, size: 34))),
            const SizedBox(height: 14),
            _dRow('🎯', 'Score',     '$_score / ${_questions.length * 10}'),
            _dRow('✅', 'Correctes', '${_questions.length - _errors} / ${_questions.length}'),
            _dRow('❌', 'Erreurs',   '$_errors'),
            _dRow('⚡', 'Exactitude','$pct%'),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _dlgBtn('Retour', Colors.white.withValues(alpha: 0.25), Colors.white, () {
                SoundService().click();
                Navigator.pop(context);
                Navigator.pop(context);
              }),
              _dlgBtn('Rejouer', Colors.white, _lc, () {
                SoundService().click();
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 0; _score = 0; _errors = 0;
                  _wordQualities.clear(); _buildQuestions();
                });
                _startQ();
              }),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _dRow(String e, String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(e, style: const TextStyle(fontSize: 15)),
      const SizedBox(width: 8),
      Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
      const Spacer(),
      Text(v, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _dlgBtn(String t, Color bg, Color fg, VoidCallback fn) => ElevatedButton(
    onPressed: fn,
    style: ElevatedButton.styleFrom(
      backgroundColor: bg, foregroundColor: fg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  @override
  void dispose() {
    _timerCtrl.dispose();
    _slideCtrl.dispose();
    _shakeCtrl.dispose();
    _autoNext?.cancel();
    SoundService().switchMusic('world_map'); // ✅ retour musique monde
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = _questions[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF0A1628), _lc.withValues(alpha: 0.75), const Color(0xFF0A1628)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  _buildTimerRow(),
                  const SizedBox(height: 14),
                  _buildQuestionImage(q),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Quel mot correspond à cette image ?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildOptions(q),
                  if (_isAnswered) ...[
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      onPressed: _nextQ,
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      label: Text(
                        _currentIndex == _questions.length - 1 ? 'Terminer !' : 'Question suivante →',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(children: [
    GestureDetector(
      onTap: () { SoundService().click(); Navigator.pop(context); },
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(child: Text('❓ Quiz — ${widget.levelData.title}',
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
      overflow: TextOverflow.ellipsis)),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Text('🎯 $_score pts',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    ),
  ]);

  Widget _buildTimerRow() => Row(children: [
    AnimatedBuilder(
      animation: _timerAnim,
      builder: (_, __) {
        final frac  = _timerAnim.value;
        final color = frac > 0.5 ? Colors.green : frac > 0.25 ? Colors.orange : Colors.red;
        return SizedBox(
          width: 44, height: 44,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: frac, strokeWidth: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
            Text(_timeLeft.ceil().toString(),
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
        );
      },
    ),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Q ${_currentIndex + 1} / ${_questions.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _tier == AdaptiveTier.easy ? '🟢 Facile'
                : _tier == AdaptiveTier.medium ? '🟡 Moyen' : '🔴 Difficile',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (_currentIndex + 1) / _questions.length,
          minHeight: 5,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation(Colors.amber),
        ),
      ),
    ])),
  ]);

  Widget _buildQuestionImage(_QuizQ q) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) =>
          FractionalTranslation(translation: _shakeAnim.value, child: child),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(q.correct.imagePath, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(q.correct.word[0].toUpperCase(),
                      style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: _lc)),
                  Text(q.correct.word,
                      style: const TextStyle(fontSize: 16, color: Colors.white70)),
                ])),
            ),
            if (_isAnswered)
              Container(
                color: (_selectedId == q.correct.id ? Colors.green : Colors.red)
                    .withValues(alpha: 0.4),
                child: Center(child: Icon(
                  _selectedId == q.correct.id ? Icons.check_circle : Icons.cancel,
                  color: Colors.white, size: 56,
                )),
              ),
            // Bouton TTS
            Positioned(top: 8, right: 8,
              child: GestureDetector(
                onTap: () {
                  SoundService().click(); // ✅
                  TtsService().speak(q.correct.word);
                },
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volume_up, color: Colors.white, size: 18),
                ),
              ),
            ),
            if (_isAnswered)
              Positioned(bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Text(q.correct.word, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildOptions(_QuizQ q) {
    if (_optionCount <= 2) {
      return Column(children: q.options.map((opt) => _optionBtn(opt, q)).toList());
    }
    final rows = <Widget>[];
    for (int i = 0; i < q.options.length; i += 2) {
      rows.add(Row(children: [
        Expanded(child: _optionBtn(q.options[i], q)),
        const SizedBox(width: 10),
        i + 1 < q.options.length
            ? Expanded(child: _optionBtn(q.options[i + 1], q))
            : const Expanded(child: SizedBox()),
      ]));
      if (i + 2 < q.options.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  Widget _optionBtn(Word opt, _QuizQ q) {
    final isSelected = _selectedId == opt.id;
    final isCorrect  = opt.id == q.correct.id;
    Color bg     = Colors.white.withValues(alpha: 0.12);
    Color border = Colors.white.withValues(alpha: 0.22);
    if (_isAnswered) {
      if (isCorrect) { bg = Colors.green.withValues(alpha: 0.75); border = Colors.green.shade300; }
      else if (isSelected) { bg = Colors.red.withValues(alpha: 0.70); border = Colors.red.shade300; }
    }
    final letter = String.fromCharCode(65 + q.options.indexOf(opt));

    return GestureDetector(
      onTap: _isAnswered ? null : () => _onAnswer(opt.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: border, width: 1.5),
          boxShadow: isCorrect && _isAnswered
              ? [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 10)]
              : [],
        ),
        child: Row(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isAnswered
                  ? (isCorrect ? Colors.green.shade300
                      : isSelected ? Colors.red.shade300
                          : Colors.white.withValues(alpha: 0.1))
                  : Colors.white.withValues(alpha: 0.18),
            ),
            child: Center(child: _isAnswered
                ? Icon(isCorrect ? Icons.check : (isSelected ? Icons.close : null),
                    color: Colors.white, size: 14)
                : Text(letter, style: const TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(opt.word,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 2, overflow: TextOverflow.ellipsis)),
          if (_isAnswered && isCorrect &&
              (opt.traductionArabic ?? opt.traductionDarija) != null)
            Padding(padding: const EdgeInsets.only(left: 6),
              child: Text(opt.traductionArabic ?? opt.traductionDarija ?? '',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11))),
        ]),
      ),
    );
  }
}

class _QuizQ {
  final Word correct;
  final List<Word> options;
  _QuizQ({required this.correct, required this.options});
}