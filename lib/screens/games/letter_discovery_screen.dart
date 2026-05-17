// lib/screens/games/letter_discovery_screen.dart
// ════════════════════════════════════════════════════════════
// JEU 1 CP — VOIR + ÉCOUTER
// Données centralisées dans lib/data/letter_games_data.dart
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lumi_mascot.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../services/sound_service.dart';
import '../../data/letter_games_data.dart';
import 'letter_recognition_game_cp.dart';

// ════════════════════════════════════════════════════════════
class LetterDiscoveryScreen extends StatefulWidget {
  final String islandId;
  final List<String> letters;
  final int dayNumber;
  const LetterDiscoveryScreen({
    super.key,
    required this.islandId,
    required this.letters,
    required this.dayNumber,
  });
  @override
  State<LetterDiscoveryScreen> createState() => _State();
}

class _State extends State<LetterDiscoveryScreen>
    with TickerProviderStateMixin {
  int _idx = 0;
  int _taps = 0;
  bool _showWord = false;
  bool _showMin = false;
  bool _done = false;
  LumiMood _mood = LumiMood.guide;

  late AnimationController _bounceCtrl, _wordCtrl, _rippleCtrl, _floatCtrl;
  late Animation<double> _bounce, _word, _ripple, _float;

  LetterData get _d => kLetterDB[widget.letters[_idx]] ?? kLetterDB['A']!;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _wordCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _bounce = Tween(begin: 1.0, end: 1.22).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut));
    _word = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _wordCtrl, curve: Curves.elasticOut));
    _ripple = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));
    _float = Tween(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _start();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _wordCtrl.dispose();
    _rippleCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _taps = 0;
      _showWord = false;
      _showMin = false;
      _done = false;
      _mood = LumiMood.guide;
    });
    _wordCtrl.reset();
    _bounceCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 300));
    await TtsService().speak(_d.letter);
    await Future.delayed(const Duration(milliseconds: 500));
    await TtsService().speak('${_d.letter} comme ${_d.word}');
    setState(() => _showWord = true);
    _wordCtrl.forward(from: 0);
  }

  Future<void> _onTap() async {
    if (_done) return;
    HapticFeedback.lightImpact();
    _taps++;
    _bounceCtrl.forward(from: 0);
    _rippleCtrl.forward(from: 0);
    SoundService().play(SoundEffect.correct);
    setState(() {
      _showMin = !_showMin;
      _mood = _taps >= 3 ? LumiMood.celebrate : LumiMood.happy;
    });
    await TtsService().speak(_d.letter);
    if (_taps >= 3) {
      setState(() => _done = true);
      await Future.delayed(const Duration(milliseconds: 900));
      if (_idx + 1 < widget.letters.length) {
        setState(() => _idx++);
        _start();
      } else {
        _finish();
      }
    }
  }

  Future<void> _finish() async {
    await ProgressService().recordScore(
      levelId: widget.islandId,
      gameType: 'discovery_${widget.dayNumber}',
      score: widget.letters.length,
      maxScore: widget.letters.length,
    );
    if (!mounted) return;
    // ✅ Récupère le thème de l'île
    final theme = IslandTheme.all.firstWhere((t) => t.id == widget.islandId,
        orElse: () => IslandTheme.all[0]);
    // ✅ Navigue vers LetterRecognitionGameCP (jeu 2)
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => LetterRecognitionGameCP(
            islandId: widget.islandId,
            letters: widget.letters,
            dayNumber: widget.dayNumber,
            theme: theme,
          ),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ));
  }

  @override
  Widget build(BuildContext ctx) {
    final d = _d;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              d.color.withOpacity(0.95),
              d.dark.withOpacity(0.55),
              Colors.white
            ],
            stops: const [0, 0.35, 1],
          ),
        ),
        child: SafeArea(
            child: Column(children: [
          _topBar(d),
          Expanded(
              child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              const SizedBox(height: 16),
              _letterCircle(d),
              const SizedBox(height: 20),
              if (_showWord) _wordCard(d),
              const SizedBox(height: 20),
              _tapBtn(d),
              const SizedBox(height: 12),
              _dots(),
              const SizedBox(height: 20),
            ]),
          )),
          _lumiBar(d),
        ])),
      ),
    );
  }

  Widget _topBar(LetterData d) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          _iconBtn(Icons.close_rounded, d.dark, () => Navigator.pop(context)),
          const Spacer(),
          Row(
              children: List.generate(widget.letters.length, (i) {
            final done = i < _idx;
            final cur = i == _idx;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: cur ? 40 : 30,
              height: cur ? 40 : 30,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? const Color(0xFF5DCAA5)
                      : cur
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                  border: Border.all(
                      color: done
                          ? const Color(0xFF3DAD8A)
                          : cur
                              ? d.dark
                              : Colors.white.withOpacity(0.5),
                      width: 2.5),
                  boxShadow: cur
                      ? [
                          BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 10)
                        ]
                      : []),
              child: Center(
                  child: done
                      ? const Icon(Icons.star_rounded,
                          color: Colors.white, size: 18)
                      : Text(widget.letters[i],
                          style: TextStyle(
                              fontSize: cur ? 20 : 15,
                              fontWeight: FontWeight.w900,
                              color: cur ? d.dark : Colors.white))),
            );
          })),
          const Spacer(),
          _iconBtn(Icons.volume_up_rounded, d.dark, () async {
            await TtsService().speak(d.letter);
            await Future.delayed(const Duration(milliseconds: 400));
            await TtsService().speak(d.word);
          }),
        ]),
      );

  Widget _iconBtn(IconData ic, Color col, VoidCallback onTap) =>
      GestureDetector(
          onTap: onTap,
          child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2)),
              child: Icon(ic, color: col, size: 20)));

  Widget _letterCircle(LetterData d) => AnimatedBuilder(
        animation: Listenable.merge([_bounce, _ripple]),
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          Transform.scale(
              scale: 1 + _ripple.value * 0.6,
              child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                          .withOpacity(0.18 * (1 - _ripple.value))))),
          GestureDetector(
              onTap: _onTap,
              child: Transform.scale(
                  scale: _bounce.value,
                  child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: d.dark, width: 4),
                          boxShadow: [
                            BoxShadow(
                                color: d.color.withOpacity(0.5),
                                blurRadius: 28,
                                spreadRadius: 4)
                          ]),
                      child: Stack(alignment: Alignment.center, children: [
                        ClipOval(
                            child: Image.asset(d.imageAsset,
                                width: 110,
                                height: 110,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Text(
                                    _showMin ? d.lowercase : d.letter,
                                    style: TextStyle(
                                        fontSize: 72,
                                        fontWeight: FontWeight.w900,
                                        color: d.dark)))),
                        Positioned(
                            bottom: 8,
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                    color: d.color,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: d.dark, width: 1.5)),
                                child: Text(_showMin ? d.lowercase : d.letter,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white)))),
                        if (_done)
                          Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF5DCAA5)
                                      .withOpacity(0.88)),
                              child: const Center(
                                  child: Text('⭐',
                                      style: TextStyle(fontSize: 64)))),
                      ])))),
        ]),
      );

  Widget _wordCard(LetterData d) => ScaleTransition(
        scale: _word,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: d.color, width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: d.color.withOpacity(0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 6))
              ]),
          child: Row(children: [
            Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: d.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: d.color.withOpacity(0.5), width: 1.5)),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(d.wordAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                            child: Text(d.letter,
                                style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: d.dark)))))),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  RichText(
                      text: TextSpan(children: [
                    TextSpan(
                        text: d.letter,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: d.dark)),
                    TextSpan(
                        text: d.word.length > 1
                            ? d.word.substring(1).toLowerCase()
                            : '',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600)),
                  ])),
                  const SizedBox(height: 4),
                  Text(d.wordArabic,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9B9B98),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                      onTap: () =>
                          TtsService().speak('${d.letter} comme ${d.word}'),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: d.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: d.color, width: 1.5)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.volume_up_rounded,
                                color: d.dark, size: 16),
                            const SizedBox(width: 4),
                            Text('Écouter',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: d.dark)),
                          ]))),
                ])),
          ]),
        ),
      );

  Widget _tapBtn(LetterData d) => GestureDetector(
        onTap: _onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [d.color, d.dark]),
              borderRadius: BorderRadius.circular(28),
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                    color: d.dark.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('👆', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tape et répète !',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              Text('${3 - _taps.clamp(0, 3)} fois encore',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withOpacity(0.85))),
            ]),
            const SizedBox(width: 10),
            const Text('🔊', style: TextStyle(fontSize: 22)),
          ]),
        ),
      );

  Widget _dots() => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final done = i < _taps;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: done ? 20 : 13,
          height: done ? 20 : 13,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? const Color(0xFF5DCAA5)
                  : Colors.white.withOpacity(0.45),
              border: Border.all(
                  color: done
                      ? const Color(0xFF3DAD8A)
                      : Colors.white.withOpacity(0.7),
                  width: 2),
              boxShadow: done
                  ? [
                      BoxShadow(
                          color: const Color(0xFF5DCAA5).withOpacity(0.5),
                          blurRadius: 8)
                    ]
                  : []),
          child: done
              ? const Center(
                  child:
                      Icon(Icons.check_rounded, color: Colors.white, size: 12))
              : null,
        );
      }));

  Widget _lumiBar(LetterData d) => AnimatedBuilder(
        animation: _float,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _float.value),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.93),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: d.color, width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]),
            child: Row(children: [
              LumiMascot(mood: _mood, size: 40),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      _taps == 0
                          ? '👁 Regarde ! Tape la lettre pour la répéter !'
                          : _taps == 1
                              ? '👏 Super ! Encore 2 fois !'
                              : _taps == 2
                                  ? '🔥 Presque ! Encore une fois !'
                                  : '🎉 Excellent ! Tu connais la lettre ${d.letter} !',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: d.dark))),
            ]),
          ),
        ),
      );
}
