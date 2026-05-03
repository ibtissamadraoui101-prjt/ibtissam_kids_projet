// lib/screens/quiz_game_screen.dart
// ❓ QUIZ v3.2 — CORRECTIONS AFFICHAGE ALPHABET
//
// BUGS CORRIGÉS :
//   ✅ Image vide → affiche l'image du mot-exemple (ex: Girafe pour G) + lettre en overlay
//   ✅ Question adaptée → "Quelle est cette lettre ?" pour l'alphabet
//   ✅ Options enrichies → "G — Girafe" au lieu de juste "G"
//   ✅ TTS → "G comme Girafe" au lieu de juste "G"
//   ✅ Moitié noire → Column + Expanded correct, fini le SingleChildScrollView global
//   ✅ Son erreur → tryAgain (doux) au lieu de wrong (effrayant)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/game_models.dart';
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../services/sound_service.dart';
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
  int      _currentIndex  = 0;
  int      _score         = 0;
  int      _errors        = 0;
  int      _xp            = 0;
  int      _streak        = 0;
  int?     _selectedId;
  bool     _isAnswered    = false;
  Set<int> _eliminatedIds = {};
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
  late AnimationController _bounceCtrl;
  late Animation<double>   _bounceAnim;

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
        if (!_isAnswered && _timerAnim.value < 0.4 && _eliminatedIds.isEmpty && _optionCount >= 3) {
          _eliminateWrongAnswer();
        }
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

    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));

    _buildQuestions();
    _startQ();
  }

  void _buildQuestions() {
    final words = _ai.selectWords(widget.levelData.vocabulary, count: 10);
    _questions  = words.map((correct) {
      final others = widget.levelData.vocabulary
          .where((w) => w.id != correct.id).toList()..shuffle();
      final opts = [correct, ...others.take(_optionCount - 1)]..shuffle();
      return _QuizQ(correct: correct, options: opts);
    }).toList();
  }

  void _startQ() {
    _selectedId    = null;
    _isAnswered    = false;
    _eliminatedIds = {};
    _timeLeft      = _timeSec.toDouble();
    _timerCtrl.reset();
    _slideCtrl.forward(from: 0);
    _timerCtrl.removeStatusListener(_onTimerDone);
    _timerCtrl.addStatusListener(_onTimerDone);
    _timerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _speakWord(_questions[_currentIndex].correct);
    });
  }

  void _speakWord(Word word) {
    if (word.word.length == 1 && word.traductionDarija != null) {
      TtsService().speak('${word.word} comme ${word.traductionDarija}');
    } else {
      TtsService().speak(word.word);
    }
  }

  void _onTimerDone(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_isAnswered) {
      _timerCtrl.removeStatusListener(_onTimerDone);
      _onAnswer(null);
    }
  }

  void _eliminateWrongAnswer() {
    if (_isAnswered) return;
    final q = _questions[_currentIndex];
    final wrongs = q.options
        .where((o) => o.id != q.correct.id && !_eliminatedIds.contains(o.id))
        .toList()..shuffle();
    if (wrongs.isEmpty) return;
    setState(() => _eliminatedIds.add(wrongs.first.id));
    HapticFeedback.selectionClick();
  }

  void _onAnswer(int? id) {
    if (_isAnswered) return;
    if (id != null && _eliminatedIds.contains(id)) return;
    _autoNext?.cancel();
    _timerCtrl.stop();
    _timerCtrl.removeStatusListener(_onTimerDone);
    HapticFeedback.lightImpact();

    final q       = _questions[_currentIndex];
    final correct = id == q.correct.id;
    final quality = _ai.computeQuality(isCorrect: correct, responseTimeSeconds: _timeSec - _timeLeft);
    _wordQualities[q.correct.id] = quality;

    setState(() { _selectedId = id; _isAnswered = true; });

    if (correct) {
      _streak++;
      final bonus      = _timeLeft > 10 ? 5 : 0;
      final comboBonus = _streak >= 3 ? _streak * 2 : 0;
      final gained     = 10 + bonus + comboBonus;
      _score += gained;
      _xp    += gained;
      HapticFeedback.mediumImpact();
      SoundService().play(_streak >= 3 ? SoundEffect.combo : SoundEffect.correct);
      _bounceCtrl.forward(from: 0);
      if (q.correct.word.length == 1 && q.correct.traductionDarija != null) {
        TtsService().speak('Bravo ! ${q.correct.word} comme ${q.correct.traductionDarija} !');
      } else {
        TtsService().speak(_streak >= 3 ? 'COMBO ! ${q.correct.word} !' : 'Bravo ! ${q.correct.word} !');
      }
    } else {
      _streak = 0;
      _errors++;
      HapticFeedback.selectionClick();
      SoundService().play(SoundEffect.tryAgain);
      _shakeCtrl.forward(from: 0);
      if (q.correct.word.length == 1 && q.correct.traductionDarija != null) {
        TtsService().speak('La réponse est ${q.correct.word} comme ${q.correct.traductionDarija}.');
      } else {
        TtsService().speak('La réponse est ${q.correct.word}.');
      }
    }
    _autoNext = Timer(const Duration(seconds: 2), _nextQ);
  }

  void _nextQ() {
    _autoNext?.cancel();
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      _startQ();
    } else {
      _finish();
    }
  }

  void _finish() {
    final pct = (_score / (_questions.length * 10) * 100).round();
    SoundService().play(SoundEffect.levelDone);
    ProgressService().recordScore(
      levelId: widget.levelData.id, gameType: 'quiz',
      score: _score, maxScore: _questions.length * 10,
      durationSeconds: 0, errorsCount: _errors, wordQualities: _wordQualities,
    );
    TtsService().speak(_ai.encouragementMessage(pct));
    _showResult();
  }

  void _showResult() {
    final pct   = (_score / (_questions.length * 10) * 100).clamp(0, 100).round();
    final stars = pct >= 80 ? 3 : pct >= 60 ? 2 : 1;
    final report = _ai.childReport(widget.levelData.vocabulary);
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_lc, _lc.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _lc.withOpacity(0.5), blurRadius: 24)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('❓', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 6),
            const Text('Quiz terminé !',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Icon(
                    i < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 34))),
            const SizedBox(height: 14),
            _dRow('🎯', 'Score',      '$_score / ${_questions.length * 10}'),
            _dRow('✅', 'Correctes',  '${_questions.length - _errors} / ${_questions.length}'),
            _dRow('❌', 'Erreurs',    '$_errors'),
            _dRow('⚡', 'Exactitude', '$pct%'),
            if (report['strong']!.isNotEmpty || report['weak']!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  if (report['strong']!.isNotEmpty)
                    Text('Tu connais bien : ${report['strong']!.join(', ')} ✅',
                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  if (report['weak']!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('À réviser : ${report['weak']!.join(', ')} 📚',
                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                  ],
                ]),
              ),
            ],
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _dlgBtn('Retour', Colors.white.withOpacity(0.25), Colors.white,
                  () { Navigator.pop(context); Navigator.pop(context); }),
              _dlgBtn('Rejouer', Colors.white, _lc, () {
                Navigator.pop(context);
                setState(() { _currentIndex = 0; _score = 0; _errors = 0; _xp = 0; _streak = 0; _wordQualities.clear(); _buildQuestions(); });
                _startQ();
              }),
            ]),
          ]),
        )),
      ),
    );
  }

  Widget _dRow(String e, String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(e, style: const TextStyle(fontSize: 15)),
      const SizedBox(width: 8),
      Text(l, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
      const Spacer(),
      Text(v, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _dlgBtn(String t, Color bg, Color fg, VoidCallback fn) =>
      ElevatedButton(onPressed: fn,
        style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)));

  @override
  void dispose() {
    _timerCtrl.dispose(); _slideCtrl.dispose(); _shakeCtrl.dispose(); _bounceCtrl.dispose();
    _autoNext?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final q       = _questions[_currentIndex];
    final maxXp   = _questions.length * 15;
    final isAlpha = q.correct.word.length == 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF0A1628), _lc.withOpacity(0.75), const Color(0xFF0A1628)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        // ✅ FIX MOITIÉ NOIRE : Column + Expanded au lieu de SingleChildScrollView global
        child: SafeArea(
          child: Column(children: [

            // ── Partie haute fixe (header + XP + timer) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SlideTransition(
                position: _slideAnim,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _buildHeader(),
                  const SizedBox(height: 6),
                  _buildXPBar(maxXp),
                  const SizedBox(height: 6),
                  _buildTimerRow(),
                ]),
              ),
            ),

            // ── Partie scrollable (image + options) ──────
            Expanded(
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _buildQuestionImage(q),
                    const SizedBox(height: 10),
                    _buildQuestionLabel(isAlpha),
                    const SizedBox(height: 12),
                    _buildOptions(q),
                    if (_isAnswered) ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _nextQ,
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        label: Text(_currentIndex == _questions.length - 1 ? 'Terminer !' : 'Question suivante →',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber, foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 4),
                      ),
                    ],
                    if (_eliminatedIds.isNotEmpty && !_isAnswered)
                      Padding(padding: const EdgeInsets.only(top: 8),
                        child: Center(child: Text('💡 L\'IA a éliminé une mauvaise réponse !',
                            style: TextStyle(color: Colors.amber.withOpacity(0.8), fontSize: 11)))),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(children: [
    GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)),
    ),
    const SizedBox(width: 10),
    Expanded(child: Text('❓ Quiz — ${widget.levelData.title}',
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
        overflow: TextOverflow.ellipsis)),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.25), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.5))),
      child: Text('🎯 $_score pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    ),
  ]);

  Widget _buildXPBar(int maxXp) => Row(children: [
    const Text('⚡ XP : ', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
    Text('$_xp', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900)),
    const SizedBox(width: 8),
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: maxXp > 0 ? (_xp / maxXp).clamp(0, 1) : 0, minHeight: 6,
        backgroundColor: Colors.white.withOpacity(0.15),
        valueColor: const AlwaysStoppedAnimation(Colors.amber)))),
  ]);

  Widget _buildTimerRow() => Row(children: [
    AnimatedBuilder(animation: _timerAnim, builder: (_, __) {
      final frac  = _timerAnim.value;
      final color = frac > 0.5 ? Colors.green : frac > 0.25 ? Colors.orange : Colors.red;
      return SizedBox(width: 44, height: 44,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(value: frac, strokeWidth: 4,
            backgroundColor: Colors.white.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color)),
          Text(_timeLeft.ceil().toString(),
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ]));
    }),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Q ${_currentIndex + 1} / ${_questions.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        if (_streak >= 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFFCA28)]),
              borderRadius: BorderRadius.circular(8)),
            child: Text('🔥 x$_streak',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)))
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(6)),
            child: Text(_ai.tierLabel(_tier), style: const TextStyle(color: Colors.white70, fontSize: 10))),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (_currentIndex + 1) / _questions.length, minHeight: 5,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation(Colors.amber))),
    ])),
  ]);

  // ✅ FIX PRINCIPAL : image adaptée pour l'alphabet
  Widget _buildQuestionImage(_QuizQ q) {
    final isAlpha = q.correct.word.length == 1;
    final exemple = q.correct.traductionDarija; // "Girafe" pour G

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => FractionalTranslation(translation: _shakeAnim.value, child: child),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(fit: StackFit.expand, children: [

            // Image de fond
            if (isAlpha && exemple != null)
              _buildAlphaExampleImage(q.correct, exemple)
            else
              Image.asset(q.correct.imagePath, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _lc.withOpacity(0.3),
                  child: Center(child: Text(q.correct.word,
                    style: TextStyle(fontSize: q.correct.word.length == 1 ? 80 : 36,
                        fontWeight: FontWeight.w900, color: Colors.white))))),

            // Pour l'alphabet : dégradé + grande lettre en cercle par-dessus
            if (isAlpha) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.2)])),
              ),
              Positioned(
                top: 12, left: 14,
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: _lc.withOpacity(0.88),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12)],
                  ),
                  child: Center(child: Text(q.correct.word,
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
              ),
              // "comme…" en bas à droite
              if (exemple != null && !_isAnswered)
                Positioned(top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10)),
                    child: Text('comme $exemple',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  )),
            ],

            // Overlay bonne/mauvaise réponse
            if (_isAnswered)
              Container(
                color: (_selectedId == q.correct.id ? Colors.green : Colors.red).withOpacity(0.4),
                child: Center(child: Icon(
                  _selectedId == q.correct.id ? Icons.check_circle : Icons.cancel,
                  color: Colors.white, size: 56))),

            // Bouton TTS
            Positioned(bottom: isAlpha ? null : 8, top: isAlpha ? 8 : null, right: 8,
              child: GestureDetector(
                onTap: () => _speakWord(q.correct),
                child: Container(width: 34, height: 34,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
                  child: const Icon(Icons.volume_up, color: Colors.white, size: 18)))),

            // Label après réponse
            if (_isAnswered)
              Positioned(bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: Colors.black.withOpacity(0.6),
                  child: Text(
                    isAlpha && exemple != null ? '${q.correct.word} comme $exemple' : q.correct.word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)))),
          ]),
        ),
      ),
    );
  }

  /// Cherche l'image du mot-exemple dans le vocabulaire du niveau
  Widget _buildAlphaExampleImage(Word letter, String exemple) {
    final exampleWord = widget.levelData.vocabulary
        .where((w) => w.word.toLowerCase() == exemple.toLowerCase())
        .firstOrNull;
    final imagePath = exampleWord?.imagePath ?? letter.imagePath;
    return Image.asset(imagePath, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: _lc.withOpacity(0.25),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(letter.word, style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.white)),
          Text('comme $exemple', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7))),
        ]))));
  }

  // ✅ FIX : question adaptée au type de niveau
  Widget _buildQuestionLabel(bool isAlpha) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Flexible(child: Text(
        isAlpha ? 'Quelle est cette lettre ?' : 'Quel mot correspond à cette image ?',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
      if (_streak >= 3) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFFCA28)]),
            borderRadius: BorderRadius.circular(8)),
          child: Text('🔥 x$_streak',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900))),
      ],
    ]),
  );

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
    final isSelected   = _selectedId == opt.id;
    final isCorrect    = opt.id == q.correct.id;
    final isEliminated = _eliminatedIds.contains(opt.id);
    final isAlpha      = opt.word.length == 1;

    // ✅ FIX OPTION : "G — Girafe" pour l'alphabet, pas juste "G"
    final String optLabel = isAlpha && opt.traductionDarija != null
        ? '${opt.word}  —  ${opt.traductionDarija}'
        : opt.word;

    if (isEliminated && !_isAnswered) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10), height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white.withOpacity(0.08))),
        child: Row(children: [
          Container(width: 26, height: 26,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
            child: const Center(child: Icon(Icons.close, color: Colors.white24, size: 14))),
          const SizedBox(width: 10),
          Expanded(child: Text(optLabel,
              style: const TextStyle(color: Colors.white24, fontSize: 14, decoration: TextDecoration.lineThrough))),
        ]));
    }

    Color bg     = Colors.white.withOpacity(0.12);
    Color border = Colors.white.withOpacity(0.22);
    if (_isAnswered) {
      if (isCorrect)       { bg = Colors.green.withOpacity(0.75); border = Colors.green.shade300; }
      else if (isSelected) { bg = Colors.red.withOpacity(0.70);   border = Colors.red.shade300; }
    }

    final letter = String.fromCharCode(65 + q.options.indexOf(opt));

    Widget btn = GestureDetector(
      onTap: _isAnswered ? null : () => _onAnswer(opt.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54, margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13),
          border: Border.all(color: border, width: 1.5),
          boxShadow: isCorrect && _isAnswered
              ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 10)] : []),
        child: Row(children: [
          Container(width: 26, height: 26,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: _isAnswered
                  ? (isCorrect ? Colors.green.shade300 : isSelected ? Colors.red.shade300 : Colors.white.withOpacity(0.1))
                  : Colors.white.withOpacity(0.18)),
            child: Center(child: _isAnswered
                ? Icon(isCorrect ? Icons.check : (isSelected ? Icons.close : null), color: Colors.white, size: 14)
                : Text(letter, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 10),
          Expanded(child: Text(optLabel,
            style: TextStyle(color: Colors.white, fontSize: isAlpha ? 15 : 14, fontWeight: FontWeight.bold),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (_isAnswered && isCorrect && opt.traductionArabic != null)
            Padding(padding: const EdgeInsets.only(left: 6),
              child: Text(opt.traductionArabic!, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13))),
        ]),
      ),
    );

    if (_isAnswered && isCorrect) {
      return AnimatedBuilder(
        animation: _bounceAnim,
        builder: (_, child) => Transform.scale(scale: _bounceAnim.value, child: child),
        child: btn);
    }
    return btn;
  }
}

class _QuizQ {
  final Word correct;
  final List<Word> options;
  _QuizQ({required this.correct, required this.options});
}