// lib/screens/games/letter_writing_game_cp.dart
// ════════════════════════════════════════════════════════════
// JEU 4 CP — ÉCRITURE + RÉCOMPENSE FINALE
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

class LetterWritingGameCP extends StatefulWidget {
  final String islandId;
  final List<String> letters;
  final int dayNumber;
  final IslandTheme theme;
  const LetterWritingGameCP({
    super.key,
    required this.islandId,
    required this.letters,
    required this.dayNumber,
    required this.theme,
  });
  @override
  State<LetterWritingGameCP> createState() => _State();
}

class _State extends State<LetterWritingGameCP> with TickerProviderStateMixin {
  int _letterIdx = 0;
  bool _validated = false;
  bool _showReward = false;
  List<List<Offset>> _strokes = [[]];
  // ✅ CORRIGÉ : uniquement des valeurs qui existent dans l'enum
  LumiMood _mood = LumiMood.guide;

  late AnimationController _mascotRunCtrl;
  late AnimationController _chestCtrl;
  late AnimationController _letterPopCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _validateCtrl;

  late Animation<double> _mascotRun;
  late Animation<double> _chestOpen;
  late Animation<double> _letterPop;
  late Animation<double> _float;
  late Animation<double> _validateAnim;

  LetterData get _d => kLetterDB[widget.letters[_letterIdx]] ?? kLetterDB['A']!;

  @override
  void initState() {
    super.initState();
    _mascotRunCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _chestCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _letterPopCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _validateCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _mascotRun = Tween(begin: 1.2, end: 0.05).animate(
        CurvedAnimation(parent: _mascotRunCtrl, curve: Curves.easeInOut));
    _chestOpen = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _chestCtrl, curve: Curves.elasticOut));
    _letterPop = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _letterPopCtrl, curve: Curves.elasticOut));
    _float = Tween(begin: -5.0, end: 5.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _validateAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _validateCtrl, curve: Curves.elasticOut));

    _intro();
  }

  Future<void> _intro() async {
    await Future.delayed(const Duration(milliseconds: 400));
    await TtsService().speak('Écris la lettre ${_d.letter} avec ton doigt !');
  }

  @override
  void dispose() {
    _mascotRunCtrl.dispose();
    _chestCtrl.dispose();
    _letterPopCtrl.dispose();
    _floatCtrl.dispose();
    _validateCtrl.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    if (_validated) return;
    setState(() => _strokes.add([d.localPosition]));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_validated) return;
    setState(() => _strokes.last.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    if (_validated) return;
    final total = _strokes.fold(0, (s, t) => s + t.length);
    if (total > 30) _validate();
  }

  Future<void> _validate() async {
    HapticFeedback.heavyImpact();
    SoundService().play(SoundEffect.correct);
    setState(() {
      _validated = true;
      _mood = LumiMood.celebrate; // ✅ CORRIGÉ
    });
    _validateCtrl.forward(from: 0);
    await TtsService().speak('Bravo ! La lettre ${_d.letter} !');
    await Future.delayed(const Duration(milliseconds: 1200));

    if (_letterIdx + 1 < widget.letters.length) {
      setState(() {
        _letterIdx++;
        _strokes = [[]];
        _validated = false;
        _mood = LumiMood.guide;
      });
      _validateCtrl.reset();
      await TtsService().speak('Maintenant écris la lettre ${_d.letter} !');
    } else {
      await _showFinalReward();
    }
  }

  void _clearStrokes() => setState(() {
        _strokes = [[]];
        _validated = false;
      });

  Future<void> _showFinalReward() async {
    await ProgressService().recordScore(
      levelId: widget.islandId,
      gameType: 'writing_${widget.dayNumber}',
      score: widget.letters.length,
      maxScore: widget.letters.length,
    );
    setState(() {
      _showReward = true;
      _mood = LumiMood.celebrate; // ✅ CORRIGÉ
    });
    await Future.delayed(const Duration(milliseconds: 500));
    _mascotRunCtrl.forward();
    await TtsService().speak('Tu as tout réussi ! Allons sauver les lettres !');
    await Future.delayed(const Duration(milliseconds: 2000));
    _chestCtrl.forward();
    SoundService().play(SoundEffect.levelDone); // ✅ existe
    await Future.delayed(const Duration(milliseconds: 800));
    _letterPopCtrl.forward();
    setState(() => _mood = LumiMood.celebrate); // ✅ CORRIGÉ
    await TtsService().speak(
        'Bravo ! Les lettres ${widget.letters.join(", ")} sont sauvées !');
  }

  @override
  Widget build(BuildContext ctx) {
    if (_showReward) return _buildRewardScreen();
    return _buildWritingScreen();
  }

  // ════════════════════════════════════════════════════════
  // ÉCRAN ÉCRITURE
  // ════════════════════════════════════════════════════════
  Widget _buildWritingScreen() {
    final d = _d;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8EC), Color(0xFFFFF0D0), Colors.white],
          ),
        ),
        child: SafeArea(
            child: Column(children: [
          _writingTopBar(d),
          _letterGuideCard(d),
          const SizedBox(height: 12),
          Expanded(child: _drawingZone(d)),
          const SizedBox(height: 8),
          _writingActions(d),
          _lumiBar(d),
        ])),
      ),
    );
  }

  Widget _writingTopBar(LetterData d) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2)),
                child: Icon(Icons.close_rounded, color: d.dark, size: 20)),
          ),
          const Spacer(),
          Row(
              children: List.generate(widget.letters.length, (i) {
            final done = i < _letterIdx;
            final cur = i == _letterIdx;
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
                          ? d.color
                          : Colors.white.withOpacity(0.5),
                  border: Border.all(
                      color: done
                          ? const Color(0xFF3DAD8A)
                          : cur
                              ? d.dark
                              : Colors.grey.shade300,
                      width: 2.5)),
              child: Center(
                  child: done
                      ? const Icon(Icons.star_rounded,
                          color: Colors.white, size: 18)
                      : Text(widget.letters[i],
                          style: TextStyle(
                              fontSize: cur ? 18 : 14,
                              fontWeight: FontWeight.w900,
                              color: cur ? d.dark : Colors.grey))),
            );
          })),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: d.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: d.dark, width: 1.5)),
            child: Text('✏️ Écriture',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: d.dark)),
          ),
        ]),
      );

  Widget _letterGuideCard(LetterData d) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: d.color, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: d.color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Row(children: [
          Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: d.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: d.color, width: 1.5)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(d.imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                          child: Text(d.letter,
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: d.dark)))))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Écris la lettre',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            Text(d.letter,
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w900, color: d.dark)),
          ]),
          const Spacer(),
          Column(children: [
            Text('ou',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            Text(d.lowercase,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: d.color)),
          ]),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: () => TtsService()
                  .speak('Écris la lettre ${d.letter} avec ton doigt !'),
              child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: d.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: d.dark, width: 2)),
                  child: const Icon(Icons.volume_up_rounded,
                      color: Colors.white, size: 18))),
        ]),
      );

  Widget _drawingZone(LetterData d) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: _validated ? const Color(0xFF5DCAA5) : d.color,
                width: 3),
            boxShadow: [
              BoxShadow(
                  color: d.color.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 5))
            ]),
        child: Stack(children: [
          // Guide lettre en filigrane
          Center(
              child: Text(d.letter,
                  style: TextStyle(
                      fontSize: 160,
                      fontWeight: FontWeight.w900,
                      color: d.color.withOpacity(0.07)))),
          // Canvas dessin
          GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                  painter: _DrawingPainter(strokes: _strokes, color: d.dark),
                  child: Container(color: Colors.transparent))),
          // Overlay succès
          if (_validated)
            AnimatedBuilder(
                animation: _validateAnim,
                builder: (_, __) => Transform.scale(
                    scale: _validateAnim.value,
                    child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFF5DCAA5).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(22)),
                        child: const Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              Text('⭐', style: TextStyle(fontSize: 72)),
                              Text('Bravo !',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ]))))),
        ]),
      );

  Widget _writingActions(LetterData d) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          GestureDetector(
              onTap: _clearStrokes,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFFFF6B6B), width: 2)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh_rounded,
                        color: Color(0xFFFF6B6B), size: 20),
                    SizedBox(width: 6),
                    Text('Effacer',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF6B6B))),
                  ]))),
          const SizedBox(width: 10),
          Expanded(
              child: GestureDetector(
                  onTap: _validated ? null : _validate,
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [d.color, d.dark]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: d.dark.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 5))
                          ]),
                      child: const Center(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('✅', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 6),
                        Text('Valider !',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ]))))),
        ]),
      );

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
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]),
            child: Row(children: [
              LumiMascot(mood: _mood, size: 40),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      _validated
                          ? '🎉 Super ! Lettre ${d.letter} écrite !'
                          : '✏️ Trace la lettre ${d.letter} avec ton doigt !',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: d.dark))),
            ]),
          ),
        ),
      );

  // ════════════════════════════════════════════════════════
  // ÉCRAN RÉCOMPENSE FINALE
  // ════════════════════════════════════════════════════════
  Widget _buildRewardScreen() {
    final t = widget.theme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3DE), Color(0xFFC8F0D8), Colors.white],
          ),
        ),
        child: SafeArea(
            child: Column(children: [
          // Rainbow strip
          Container(
              height: 6,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                Color(0xFFFF6B6B),
                Color(0xFFFFD93D),
                Color(0xFF5DCAA5),
                Color(0xFF4DC8E8),
                Color(0xFFC3A6FF),
                Color(0xFFFF8C6B)
              ]))),
          Expanded(
              child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              const SizedBox(height: 16),
              // Titre
              const Text('🎉 Mission accomplie !',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF27500A))),
              const SizedBox(height: 4),
              const Text('Tu as sauvé les lettres !',
                  style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3B6D11),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),

              // ── Animation mascotte court vers l'île ──
              SizedBox(
                  height: 100,
                  child: AnimatedBuilder(
                      animation: _mascotRun,
                      builder: (_, __) {
                        final size = MediaQuery.of(context).size;
                        return Stack(alignment: Alignment.center, children: [
                          // Île destination
                          Positioned(
                              right: 20,
                              child: Container(
                                  width: 90,
                                  height: 70,
                                  decoration: BoxDecoration(
                                      color: t.primary,
                                      borderRadius: BorderRadius.circular(45),
                                      border:
                                          Border.all(color: t.dark, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                            color: t.primary.withOpacity(0.5),
                                            blurRadius: 16)
                                      ]),
                                  child: Center(
                                      child: Text(t.emoji,
                                          style:
                                              const TextStyle(fontSize: 32))))),
                          // Mascotte qui court
                          Positioned(
                              right: size.width * _mascotRun.value,
                              child: Transform.flip(
                                  flipX: true,
                                  child: LumiMascot(
                                      mood: LumiMood.celebrate,
                                      size: 60))), // ✅
                        ]);
                      })),
              const SizedBox(height: 16),

              // ── Coffre ──────────────────────────────
              AnimatedBuilder(
                animation: _chestOpen,
                builder: (_, __) => Center(
                    child: Column(children: [
                  Transform.rotate(
                      angle: -_chestOpen.value * 0.8,
                      alignment: Alignment.bottomCenter,
                      child: const Text('📦', style: TextStyle(fontSize: 64))),
                  if (_chestOpen.value > 0.5)
                    Transform.translate(
                        offset: Offset(0, -_chestOpen.value * 20),
                        child: const Text('✨', style: TextStyle(fontSize: 32))),
                ])),
              ),
              const SizedBox(height: 16),

              // ── Lettres sauvées ──────────────────────
              ScaleTransition(
                scale: _letterPop,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: const Color(0xFF5DCAA5), width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF5DCAA5).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6))
                      ]),
                  child: Column(children: [
                    const Text('Lettres sauvées !',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF27500A))),
                    const SizedBox(height: 16),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: widget.letters.map((l) {
                          final d = kLetterDB[l];
                          return Column(children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: d?.color ?? const Color(0xFFFFD93D),
                                  border: Border.all(
                                      color: d?.dark ?? const Color(0xFFFFA000),
                                      width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                        color: (d?.color ??
                                                const Color(0xFFFFD93D))
                                            .withOpacity(0.5),
                                        blurRadius: 12,
                                        spreadRadius: 2)
                                  ]),
                              child: d != null
                                  ? ClipOval(
                                      child: Image.asset(d.imageAsset,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Center(
                                              child: Text(l,
                                                  style: TextStyle(
                                                      fontSize: 32,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Colors.white)))))
                                  : Center(
                                      child: Text(l,
                                          style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white))),
                            ),
                            const SizedBox(height: 4),
                            Text(d?.word ?? l,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: d?.dark ?? Colors.grey)),
                          ]);
                        }).toList()),
                    const SizedBox(height: 12),
                    // 3 étoiles
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            3,
                            (i) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.star_rounded,
                                    size: i == 1 ? 52 : 42,
                                    color: const Color(0xFFFFD93D),
                                    shadows: const [
                                      Shadow(
                                          color: Color(0xFFFFD93D),
                                          blurRadius: 8)
                                    ])))),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // ── Lumi célèbre ────────────────────────
              LumiMascot(mood: LumiMood.celebrate, size: 70), // ✅
              const SizedBox(height: 8),
              const Text('🎊 Lumi est super fier de toi !',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF27500A))),
              const SizedBox(height: 20),

              // ── Stats ───────────────────────────────
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: [
                    Expanded(
                        child: _statCard(
                            '📝',
                            '${widget.letters.length}/3',
                            'Lettres',
                            const Color(0xFFE1F5EE),
                            const Color(0xFF5DCAA5))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _statCard(
                            '⭐',
                            '${widget.letters.length * 3}',
                            'Points',
                            const Color(0xFFFFF8CC),
                            const Color(0xFFFFD93D))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _statCard('🔑', '1', 'Clé obtenue',
                            const Color(0xFFF4C0D1), const Color(0xFFD4537E))),
                  ])),
              const SizedBox(height: 24),

              // ── Bouton retour ───────────────────────
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF5DCAA5),
                                Color(0xFF3DAD8A)
                              ]),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color: const Color(0xFF2D8E6C), width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF5DCAA5)
                                        .withOpacity(0.5),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6))
                              ]),
                          child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🗺️', style: TextStyle(fontSize: 22)),
                                SizedBox(width: 8),
                                Text('Retour à la carte !',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white)),
                              ])))),
              const SizedBox(height: 20),
            ]),
          )),
        ])),
      ),
    );
  }

  Widget _statCard(
          String emoji, String val, String label, Color bg, Color border) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2.5)),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(val,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: border)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: border.withOpacity(0.7),
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

// ── Painter dessin ────────────────────────────────────────────
class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;
  const _DrawingPainter({required this.strokes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter o) =>
      o.strokes != strokes || o.color != color;
}
