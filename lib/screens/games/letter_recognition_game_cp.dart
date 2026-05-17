// lib/screens/games/letter_recognition_game_cp.dart
// ════════════════════════════════════════════════════════════
// JEU 2 CP — RECONNAISSANCE
// Lumi dit "Trouve la lettre A" → l'enfant tape la bonne image
// Affiche les 3 lettres du jour + 1 distraction
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../widgets/lumi_mascot.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../services/sound_service.dart';
import '../../data/letter_games_data.dart';
import 'memory_matching_game_cp.dart';

class LetterRecognitionGameCP extends StatefulWidget {
  final String islandId;
  final List<String> letters;
  final int dayNumber;
  final IslandTheme theme;
  const LetterRecognitionGameCP({
    super.key,
    required this.islandId,
    required this.letters,
    required this.dayNumber,
    required this.theme,
  });
  @override
  State<LetterRecognitionGameCP> createState() => _State();
}

class _State extends State<LetterRecognitionGameCP>
    with TickerProviderStateMixin {
  // Chaque lettre du jour doit être correctement identifiée
  int _questionIdx = 0; // 0..2 (3 questions)
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _correct = false;
  LumiMood _mood = LumiMood.guide;

  late List<String> _choices; // 4 lettres à afficher
  late String _target; // la lettre à trouver

  late AnimationController _bounceCtrl, _floatCtrl;
  late Animation<double> _bounce, _float;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _bounce = Tween(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut));
    _float = Tween(begin: -5.0, end: 5.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _setupQuestion();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _setupQuestion() {
    _target = widget.letters[_questionIdx % widget.letters.length];
    // 1 bonne + 3 distracteurs parmi toutes les lettres
    final pool = kAllLetters.where((l) => l != _target).toList()..shuffle(_rng);
    _choices = [_target, ...pool.take(3)]..shuffle(_rng);
    _selected = null;
    _answered = false;
    _correct = false;
    _mood = LumiMood.guide;
    // Lumi dit "Touche la lettre X !"
    Future.delayed(const Duration(milliseconds: 400), () {
      TtsService().speak('Touche la lettre $_target !');
    });
  }

  Future<void> _onChoice(int idx) async {
    if (_answered) return;
    HapticFeedback.lightImpact();
    final isOk = _choices[idx] == _target;
    setState(() {
      _selected = idx;
      _answered = true;
      _correct = isOk;
      _mood = isOk ? LumiMood.celebrate : LumiMood.encourage;
    });
    _bounceCtrl.forward(from: 0);
    SoundService().play(isOk ? SoundEffect.correct : SoundEffect.wrong);
    if (isOk) {
      _score++;
      await TtsService().speak('Bravo ! ${_target} !');
    } else {
      await TtsService().speak('C\'est la lettre $_target !');
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (_questionIdx + 1 < widget.letters.length * 2) {
      // 2 tours par lettre
      setState(() => _questionIdx++);
      _setupQuestion();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ProgressService().recordScore(
      levelId: widget.islandId,
      gameType: 'recognition_${widget.dayNumber}',
      score: _score,
      maxScore: widget.letters.length * 2,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => MemoryMatchingGameCP(
            islandId: widget.islandId,
            letters: widget.letters,
            dayNumber: widget.dayNumber,
            theme: widget.theme,
          ),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ));
  }

  @override
  Widget build(BuildContext ctx) {
    final t = widget.theme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              t.primary.withOpacity(0.9),
              t.dark.withOpacity(0.5),
              Colors.white
            ],
            stops: const [0, 0.3, 1],
          ),
        ),
        child: SafeArea(
            child: Column(children: [
          _topBar(t),
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _lumiPrompt(t),
              const SizedBox(height: 24),
              const Text('👇 Touche la bonne lettre !',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _choiceGrid(t),
            ],
          )),
          _lumiBar(t),
        ])),
      ),
    );
  }

  Widget _topBar(IslandTheme t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2)),
                  child: Icon(Icons.close_rounded, color: t.dark, size: 20))),
          const Spacer(),
          // Progression
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16)),
            child: Text(
                'Q ${(_questionIdx + 1)} / ${widget.letters.length * 2}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: t.dark)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFFFD93D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFA000), width: 2)),
            child: Text('⭐ $_score',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7A3800))),
          ),
        ]),
      );

  Widget _lumiPrompt(IslandTheme t) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD93D), width: 3),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFFD93D).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(children: [
          AnimatedBuilder(
              animation: _bounce,
              builder: (_, child) =>
                  Transform.scale(scale: _bounce.value, child: child),
              child: LumiMascot(mood: _mood, size: 52)),
          const SizedBox(height: 10),
          // Affichage grande lettre cible
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: const Color(0xFFFFD93D).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD93D), width: 2.5)),
            child: Center(
                child: Text(_target,
                    style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF7A3800)))),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => TtsService().speak('Touche la lettre $_target !'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFD93D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFA000), width: 2)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.volume_up_rounded,
                    size: 18, color: Color(0xFF7A3800)),
                const SizedBox(width: 6),
                const Text('Écouter',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7A3800))),
              ]),
            ),
          ),
        ]),
      );

  Widget _choiceGrid(IslandTheme t) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1),
      itemCount: _choices.length,
      itemBuilder: (_, i) => _choiceCard(i, t),
    );
  }

  Widget _choiceCard(int i, IslandTheme t) {
    final letter = _choices[i];
    final data = kLetterDB[letter];
    final isSel = _selected == i;
    final isRight = letter == _target;

    Color bg = Colors.white;
    Color border = Colors.grey.shade200;
    if (_answered && isSel) {
      bg = _correct ? const Color(0xFFE1F5EE) : const Color(0xFFFFEEEE);
      border = _correct ? const Color(0xFF5DCAA5) : const Color(0xFFFF6B6B);
    } else if (_answered && isRight) {
      bg = const Color(0xFFE1F5EE);
      border = const Color(0xFF5DCAA5);
    }

    return GestureDetector(
      onTap: () => _onChoice(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSel ? border : Colors.white.withOpacity(0.7), width: 3),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Image de la lettre
          if (data != null)
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(data.imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                      child: Text(letter,
                          style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: data.dark)))),
            ))
          else
            Expanded(
                child: Center(
                    child: Text(letter,
                        style: const TextStyle(
                            fontSize: 52, fontWeight: FontWeight.w900)))),
          // Label lettre
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
                color:
                    (data?.color ?? const Color(0xFFFFD93D)).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
            child: Text(letter,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: data?.dark ?? const Color(0xFF7A3800))),
          ),
          // Tick ou croix
          if (_answered && isSel)
            Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                    _correct
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: _correct
                        ? const Color(0xFF5DCAA5)
                        : const Color(0xFFFF6B6B),
                    size: 22)),
        ]),
      ),
    );
  }

  Widget _lumiBar(IslandTheme t) => AnimatedBuilder(
        animation: _float,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _float.value),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.93),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: t.primary, width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]),
            child: Row(children: [
              LumiMascot(mood: _mood, size: 40),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      _answered
                          ? (_correct
                              ? '⭐ Bravo ! C\'est bien la lettre $_target !'
                              : '💪 C\'est la lettre $_target ! Réessaie !')
                          : '👁 Touche la lettre $_target !',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: t.dark))),
            ]),
          ),
        ),
      );
}
