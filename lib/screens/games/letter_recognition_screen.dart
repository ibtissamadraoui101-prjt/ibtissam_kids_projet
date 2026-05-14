// lib/screens/games/letter_recognition_screen.dart
// CORRIGÉ :
//   • SoundService().play(SoundEffect.correct) au lieu de String
//   • SoundMatchingScreen défini ici (plus de fichier séparé)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/lumi_mascot.dart';
import '../../widgets/lk_widgets.dart';
import '../reward_screen.dart';

// ═══════════════════════════════════════════════════════════
// LETTER RECOGNITION GAME
// ═══════════════════════════════════════════════════════════
class LetterRecognitionScreen extends StatefulWidget {
  final String islandId;
  final IslandTheme theme;

  const LetterRecognitionScreen({
    super.key,
    required this.islandId,
    required this.theme,
  });

  @override
  State<LetterRecognitionScreen> createState() => _LetterRecognitionState();
}

class _LetterRecognitionState extends State<LetterRecognitionScreen>
    with TickerProviderStateMixin {

  static const _letters = [
    _LetterData('A', 'a', '🍎', 'Comme ABRICOT'),
    _LetterData('B', 'b', '🐝', 'Comme BALLON'),
    _LetterData('C', 'c', '🐱', 'Comme CHAT'),
    _LetterData('D', 'd', '🦆', 'Comme DINDON'),
    _LetterData('E', 'e', '🐘', 'Comme ÉLÉPHANT'),
    _LetterData('F', 'f', '🌸', 'Comme FLEUR'),
    _LetterData('G', 'g', '🐸', 'Comme GRENOUILLE'),
    _LetterData('H', 'h', '🌿', 'Comme HERBE'),
  ];

  int _currentQ = 0;
  static const _totalQ = 8;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  LumiMood _lumiMood = LumiMood.guide;
  late List<_LetterData> _choices;
  late _LetterData _correct;
  final _rng = Random();

  late AnimationController _bounceCtrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _bounce = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut));
    _setup();
  }

  @override
  void dispose() { _bounceCtrl.dispose(); super.dispose(); }

  void _setup() {
    final shuffled = List<_LetterData>.from(_letters)..shuffle(_rng);
    _correct = shuffled[_currentQ % shuffled.length];
    final dist = shuffled.where((l) => l.letter != _correct.letter).take(3).toList();
    _choices = [_correct, ...dist]..shuffle(_rng);
    _selected = null;
    _answered = false;
    _lumiMood = LumiMood.guide;
    _bounceCtrl.forward(from: 0);
  }

  void _onChoice(int index) {
    if (_answered) return;
    HapticFeedback.lightImpact();
    final isRight = _choices[index].letter == _correct.letter;

    setState(() {
      _selected = index;
      _answered = true;
      _lumiMood = isRight ? LumiMood.celebrate : LumiMood.encourage;
    });

    TtsService().speak(_correct.sound);
    // ✅ CORRIGÉ : utilisation de SoundEffect enum
    SoundService().play(isRight ? SoundEffect.correct : SoundEffect.wrong);
    if (isRight) _score++;

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentQ + 1 >= _totalQ) {
        _finish();
      } else {
        setState(() { _currentQ++; _setup(); });
      }
    });
  }

  Future<void> _finish() async {
    await ProgressService().recordScore(
      levelId: widget.islandId,
      gameType: 'letter_recognition',
      score: _score,
      maxScore: _totalQ,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => RewardScreen(
          score: _score, maxScore: _totalQ,
          gameTitle: 'Reconnais la Lettre',
          islandId: widget.islandId, theme: widget.theme,
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F1FB),
      body: Column(children: [
        _buildTopBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              AnimatedBuilder(
                animation: _bounce,
                builder: (_, child) =>
                    Transform.scale(scale: _bounce.value, child: child),
                child: _buildLetterCard(),
              ),
              const SizedBox(height: 16),
              const Text('Quel son fait cette lettre ?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                    color: LKColors.textMedium)),
              const SizedBox(height: 12),
              ...List.generate(4, _buildChoiceRow),
              const Spacer(),
              _buildLumiRow(),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(color: widget.theme.primary),
      child: SafeArea(bottom: false, child: Column(children: [
        const RainbowStrip(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.close_rounded,
                    color: LKColors.textDark, size: 20)),
            ),
            const Spacer(),
            LKPill.xp(_score * 3),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16)),
              child: Text('Lettre ${_currentQ + 1}/$_totalQ',
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: LKColors.textDark)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: LKProgressBar(
            progress: (_currentQ + 1) / _totalQ,
            fillColor: LKColors.sun, height: 8,
            bgColor: Colors.white.withOpacity(0.3)),
        ),
      ])),
    );
  }

  Widget _buildLetterCard() {
    return Container(
      width: double.infinity, height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.theme.primary, widget.theme.dark],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: widget.theme.dark, width: 3)),
      child: Stack(alignment: Alignment.center, children: [
        Positioned(top: 12, right: 16,
          child: Text(_correct.emoji,
              style: const TextStyle(fontSize: 36))),
        Center(child: Text(_correct.letter,
          style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26,
                  blurRadius: 8, offset: Offset(0, 4))]))),
        Positioned(bottom: 8, right: 12,
          child: Text(_correct.hint,
            style: TextStyle(fontSize: 10,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _buildChoiceRow(int index) {
    if (index >= _choices.length) return const SizedBox.shrink();
    final l = _choices[index];
    final isSelected = _selected == index;
    final isRight = l.letter == _correct.letter;

    Color bg = Colors.white;
    Color border = LKColors.neutralDark;
    if (_answered && isSelected) {
      bg = isRight ? LKColors.correctLight : LKColors.wrongLight;
      border = isRight ? LKColors.correct : LKColors.wrong;
    } else if (_answered && isRight) {
      bg = LKColors.correctLight; border = LKColors.correct;
    }

    return GestureDetector(
      onTap: () { _onChoice(index); TtsService().speak(l.sound); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2.5)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: widget.theme.light, shape: BoxShape.circle,
              border: Border.all(color: widget.theme.primary, width: 2)),
            child: const Center(child: Icon(Icons.volume_up_rounded,
                color: LKColors.textMedium, size: 20))),
          const SizedBox(width: 12),
          Text('"${l.sound}"',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                color: _answered && isRight
                    ? LKColors.textOnGreen : LKColors.textDark)),
          const Spacer(),
          if (_answered && isSelected)
            Icon(isRight ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isRight ? LKColors.correct : LKColors.wrong, size: 24),
        ]),
      ),
    );
  }

  Widget _buildLumiRow() {
    return Row(children: [
      LumiMascot(mood: _lumiMood, size: 42),
      const SizedBox(width: 10),
      Expanded(child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: LKColors.bgYellowLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LKColors.sun, width: 2)),
        child: Text(
          _answered
            ? (_lumiMood == LumiMood.celebrate
              ? '⭐ Bravo ! "${_correct.letter}" fait le son "${_correct.sound}" !'
              : '💪 "${_correct.letter}" fait le son "${_correct.sound}" !')
            : 'Appuie sur un bouton pour écouter le son !',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: LKColors.textOnYellow)),
      )),
    ]);
  }
}

class _LetterData {
  final String letter, sound, emoji, hint;
  const _LetterData(this.letter, this.sound, this.emoji, this.hint);
}


// ═══════════════════════════════════════════════════════════
// SOUND MATCHING GAME
// (dans ce même fichier pour éviter le doublon d'export)
// ═══════════════════════════════════════════════════════════
class SoundMatchingScreen extends StatefulWidget {
  final String islandId;
  final IslandTheme theme;

  const SoundMatchingScreen({
    super.key,
    required this.islandId,
    required this.theme,
  });

  @override
  State<SoundMatchingScreen> createState() => _SoundMatchingState();
}

class _SoundMatchingState extends State<SoundMatchingScreen>
    with TickerProviderStateMixin {

  static const _rounds = [
    _SoundRound('ma',  'ma',  true),
    _SoundRound('ba',  'pa',  false),
    _SoundRound('li',  'li',  true),
    _SoundRound('sa',  'cha', false),
    _SoundRound('ou',  'ou',  true),
    _SoundRound('ta',  'da',  false),
    _SoundRound('mi',  'mi',  true),
    _SoundRound('ro',  'lo',  false),
  ];

  int _current = 0;
  int _score = 0;
  bool? _answered;
  final List<bool> _history = [];
  LumiMood _lumiMood = LumiMood.guide;

  @override
  void initState() { super.initState(); }

  void _playSound1() => TtsService().speak(_rounds[_current].sound1);
  void _playSound2() => TtsService().speak(_rounds[_current].sound2);

  void _onAnswer(bool userSaysMatch) {
    if (_answered != null) return;
    final round  = _rounds[_current];
    final isOk   = (userSaysMatch == round.areSame);

    HapticFeedback.mediumImpact();
    setState(() {
      _answered = isOk;
      _lumiMood = isOk ? LumiMood.celebrate : LumiMood.encourage;
      _history.add(isOk);
    });

    // ✅ CORRIGÉ : utilisation de SoundEffect enum
    SoundService().play(isOk ? SoundEffect.correct : SoundEffect.wrong);
    if (isOk) _score++;

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_current + 1 >= _rounds.length) {
        _finish();
      } else {
        setState(() { _current++; _answered = null; _lumiMood = LumiMood.guide; });
      }
    });
  }

  Future<void> _finish() async {
    await ProgressService().recordScore(
      levelId: widget.islandId,
      gameType: 'sound_matching',
      score: _score,
      maxScore: _rounds.length,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => RewardScreen(
          score: _score, maxScore: _rounds.length,
          gameTitle: 'Sons Pareils',
          islandId: widget.islandId, theme: widget.theme,
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_current];
    return Scaffold(
      backgroundColor: const Color(0xFFFBEAF0),
      body: Column(children: [
        _buildTopBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('Ces deux sons sont pareils ?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                    color: Color(0xFF72243E))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _soundBtn(round.sound1, 1, _playSound1)),
                const SizedBox(width: 12),
                Expanded(child: _soundBtn(round.sound2, 2, _playSound2)),
              ]),
              const SizedBox(height: 20),
              const Text('TAPE TA RÉPONSE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                    color: LKColors.textLight, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _answerZone(true,  '✓', 'Pareils !',
                    LKColors.correctLight, LKColors.correct,
                    const Color(0xFF27500A))),
                const SizedBox(width: 12),
                Expanded(child: _answerZone(false, '✗', 'Différents !',
                    LKColors.wrongLight, LKColors.wrong,
                    const Color(0xFF791F1F))),
              ]),
              const SizedBox(height: 16),
              _buildHistory(),
              const Spacer(),
              Row(children: [
                LumiMascot(mood: _lumiMood, size: 42),
                const SizedBox(width: 10),
                Expanded(child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4C0D1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: LKColors.island5Dark, width: 2)),
                  child: Text(
                    _answered == null
                      ? 'Écoute bien les 2 sons puis réponds !'
                      : (_answered! ? '⭐ C\'est correct !' : '💪 Réessaie !'),
                    style: const TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF72243E))),
                )),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(color: LKColors.island5Pink),
      child: SafeArea(bottom: false, child: Column(children: [
        const RainbowStrip(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.close_rounded,
                    color: LKColors.textDark, size: 20)),
            ),
            const Spacer(),
            LKPill.xp(_score * 5),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16)),
              child: Text('Tour ${_current + 1}/${_rounds.length}',
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: LKColors.textDark)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: LKProgressBar(
            progress: (_current + 1) / _rounds.length,
            fillColor: LKColors.sun, height: 8,
            bgColor: Colors.white.withOpacity(0.3)),
        ),
      ])),
    );
  }

  Widget _soundBtn(String sound, int num, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LKColors.island5Dark, width: 2.5)),
        child: Column(children: [
          Container(
            width: 52, height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF4C0D1), shape: BoxShape.circle),
            child: const Icon(Icons.volume_up_rounded,
                color: Color(0xFF993556), size: 28)),
          const SizedBox(height: 8),
          Text('Son $num', style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: Color(0xFF993556))),
          const SizedBox(height: 2),
          Text('"$sound"', style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900,
              color: Color(0xFF72243E))),
        ]),
      ),
    );
  }

  Widget _answerZone(bool value, String icon, String label,
      Color bg, Color border, Color textColor) {
    final isSelected = _answered != null &&
        (value ? _answered! : !_answered!);
    return GestureDetector(
      onTap: () => _onAnswer(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: isSelected ? border.withOpacity(0.15) : bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? border : border.withOpacity(0.4),
            width: isSelected ? 3.5 : 2)),
        child: Column(children: [
          Text(icon, style: TextStyle(
              fontSize: 32, color: textColor,
              fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
        ]),
      ),
    );
  }

  Widget _buildHistory() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_rounds.length, (i) {
        if (i >= _history.length) {
          return Container(
            width: 24, height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: LKColors.neutral,
              borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('?',
                style: TextStyle(fontSize: 10, color: LKColors.textLight))),
          );
        }
        return Container(
          width: 24, height: 24,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: _history[i] ? LKColors.correct : LKColors.wrong,
            borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(
            _history[i] ? '✓' : '✗',
            style: const TextStyle(fontSize: 11, color: Colors.white,
                fontWeight: FontWeight.w700))),
        );
      }),
    );
  }
}

class _SoundRound {
  final String sound1, sound2;
  final bool areSame;
  const _SoundRound(this.sound1, this.sound2, this.areSame);
}