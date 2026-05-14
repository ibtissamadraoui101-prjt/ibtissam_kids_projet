// lib/screens/games/word_builder_screen.dart
// CORRIGÉ : SoundService().play(SoundEffect.correct/wrong)

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

class WordBuilderScreen extends StatefulWidget {
  final String islandId;
  final IslandTheme theme;

  const WordBuilderScreen({
    super.key,
    required this.islandId,
    required this.theme,
  });

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen>
    with TickerProviderStateMixin {

  static const _words = [
    _WordData(word: 'chat',   emoji: '🐱', syllables: ['cha', 't'],   arabic: 'قطة'),
    _WordData(word: 'pomme',  emoji: '🍎', syllables: ['pom', 'me'],  arabic: 'تفاحة'),
    _WordData(word: 'lapin',  emoji: '🐰', syllables: ['la', 'pin'],  arabic: 'أرنب'),
    _WordData(word: 'maison', emoji: '🏠', syllables: ['mai', 'son'], arabic: 'دار'),
    _WordData(word: 'soleil', emoji: '☀️', syllables: ['so', 'leil'], arabic: 'شمس'),
    _WordData(word: 'arbre',  emoji: '🌳', syllables: ['ar', 'bre'],  arabic: 'شجرة'),
  ];

  int _currentIndex = 0;
  int _score        = 0;
  LumiMood _lumiMood = LumiMood.guide;
  String   _lumiMsg  = 'Glisse les syllabes pour construire le mot !';

  late List<String?> _dropZones;
  late List<String>  _availableTiles;
  bool _showSuccess = false;

  late AnimationController _successCtrl;
  late Animation<double>   _successAnim;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _successAnim = CurvedAnimation(
        parent: _successCtrl, curve: Curves.elasticOut);
    _setupWord();
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  void _setupWord() {
    final word = _words[_currentIndex];
    _dropZones      = List.filled(word.syllables.length, null);
    final allSyls   = _words.expand((w) => w.syllables).toSet();
    final distractors = allSyls
        .where((s) => !word.syllables.contains(s))
        .toList()..shuffle(Random());
    _availableTiles = [...word.syllables, ...distractors.take(2)]
      ..shuffle(Random());
    _showSuccess = false;
    _lumiMood    = LumiMood.guide;
    _lumiMsg     = 'Glisse les syllabes pour construire le mot !';

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) TtsService().speak(word.word);
    });
  }

  _WordData get _current => _words[_currentIndex];

  bool get _isComplete => !_dropZones.any((z) => z == null);

  bool get _isCorrect {
    for (int i = 0; i < _current.syllables.length; i++) {
      if (_dropZones[i] != _current.syllables[i]) return false;
    }
    return true;
  }

  void _onTileDropped(String syllable, int slotIndex) {
    final existing = _dropZones[slotIndex];
    setState(() {
      if (existing != null) _availableTiles.add(existing);
      _availableTiles.remove(syllable);
      _dropZones[slotIndex] = syllable;
    });
    HapticFeedback.lightImpact();
    if (_isComplete) _checkAnswer();
  }

  void _returnToPool(int slotIndex) {
    final syllable = _dropZones[slotIndex];
    if (syllable == null) return;
    setState(() {
      _availableTiles.add(syllable);
      _dropZones[slotIndex] = null;
    });
    HapticFeedback.lightImpact();
  }

  void _checkAnswer() {
    if (_isCorrect) {
      _score += 2;
      // ✅ CORRIGÉ : SoundEffect enum
      SoundService().play(SoundEffect.correct);
      _successCtrl.forward(from: 0);
      setState(() {
        _showSuccess = true;
        _lumiMood    = LumiMood.celebrate;
        _lumiMsg     = '🎉 Parfait ! "${_current.word}" c\'est correct !';
      });
      TtsService().speak(_current.word);

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        if (_currentIndex + 1 < _words.length) {
          setState(() { _currentIndex++; _setupWord(); });
        } else {
          _finishGame();
        }
      });
    } else {
      // ✅ CORRIGÉ : SoundEffect enum
      SoundService().play(SoundEffect.wrong);
      setState(() {
        _lumiMood = LumiMood.encourage;
        _lumiMsg  = 'Pas tout à fait... réessaie ! 💪';
      });
    }
  }

  Future<void> _finishGame() async {
    await ProgressService().recordScore(
      levelId: widget.islandId,
      gameType: 'word_builder',
      score: _score,
      maxScore: _words.length * 2,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => RewardScreen(
          score: _score, maxScore: _words.length * 2,
          gameTitle: 'Construis le Mot',
          islandId: widget.islandId, theme: widget.theme,
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E6),
      body: Column(children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _buildWordCard(),
              const SizedBox(height: 16),
              _buildDropZone(),
              const SizedBox(height: 16),
              _buildTilePool(),
              const SizedBox(height: 12),
              _buildLumiHint(),
              const SizedBox(height: 12),
              _buildDecorRow(),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(color: LKColors.island4Coral),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: LKColors.sun, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LKColors.sunDark, width: 2)),
              child: Text('⭐ $_score pts',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                    color: LKColors.textOnYellow)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16)),
              child: Text('Mot ${_currentIndex + 1} / ${_words.length}',
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: LKColors.textDark)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: LKProgressBar(
            progress: (_currentIndex + 1) / _words.length,
            fillColor: LKColors.sun,
            bgColor: Colors.white.withOpacity(0.3), height: 8),
        ),
      ])),
    );
  }

  Widget _buildWordCard() {
    return ScaleTransition(
      scale: _showSuccess ? _successAnim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _showSuccess ? LKColors.correct : LKColors.sun, width: 3)),
        child: Column(children: [
          const Text('Quel est ce mot ?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                color: LKColors.textOnYellow)),
          const SizedBox(height: 10),
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              color: LKColors.bgYellowLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: LKColors.sun, width: 3)),
            child: Stack(alignment: Alignment.center, children: [
              Text(_current.emoji, style: const TextStyle(fontSize: 60)),
              if (_showSuccess)
                const Positioned(top: -6, right: -6,
                  child: Text('✨', style: TextStyle(fontSize: 18))),
            ]),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => TtsService().speak(_current.word),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: LKColors.bgBlueLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LKColors.island2Blue, width: 2)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.volume_up_rounded,
                    color: LKColors.island2Dark, size: 18),
                const SizedBox(width: 6),
                Text('${_current.word} — ${_current.arabic}',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: LKColors.textOnBlue)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildDropZone() {
    return Column(children: [
      const Text('Construis le mot ici !',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
            color: LKColors.textMedium)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0CC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _showSuccess ? LKColors.correct : LKColors.sun, width: 3)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_dropZones.length, (i) {
            final syl = _dropZones[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: DragTarget<String>(
                onAcceptWithDetails: (d) => _onTileDropped(d.data, i),
                builder: (_, candidates, __) {
                  final highlight = candidates.isNotEmpty;
                  return GestureDetector(
                    onTap: () => _returnToPool(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: syl != null ? null : 56,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: syl != null
                          ? (_showSuccess ? LKColors.correct : LKColors.sun)
                          : (highlight
                            ? LKColors.sun.withOpacity(0.4)
                            : Colors.white.withOpacity(0.6)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: syl != null
                            ? (_showSuccess
                              ? LKColors.island1Dark : LKColors.sunDark)
                            : LKColors.sun,
                          width: 2.5)),
                      child: Text(
                        syl ?? '  ',
                        style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: syl != null
                            ? (_showSuccess ? Colors.white : LKColors.textOnYellow)
                            : LKColors.sun)),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
      if (_showSuccess)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('✅ "${_current.word}" !',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: LKColors.correct)),
        ),
    ]);
  }

  Widget _buildTilePool() {
    // Palette de couleurs pour les tuiles
    const tileColors = [
      (LKColors.island4Coral, LKColors.island4Dark),
      (LKColors.island1Green, LKColors.island1Dark),
      (LKColors.island2Blue,  LKColors.island2Dark),
      (LKColors.island3Purple, LKColors.island3Dark),
    ];

    return Column(children: [
      const Text('SYLLABES À GLISSER',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
            color: LKColors.textLight, letterSpacing: 1.2)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10, runSpacing: 10,
        alignment: WrapAlignment.center,
        children: _availableTiles.map((syl) {
          final ci = syl.hashCode.abs() % tileColors.length;
          final (bg, border) = tileColors[ci];
          return Draggable<String>(
            data: syl,
            feedback: Material(
              color: Colors.transparent,
              child: _tile(syl, bg, border, scale: 1.15)),
            childWhenDragging: Opacity(
              opacity: 0.35, child: _tile(syl, bg, border)),
            child: _tile(syl, bg, border),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _tile(String syl, Color bg, Color border, {double scale = 1.0}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 2.5)),
        child: Text(syl,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
              color: Colors.white)),
      ),
    );
  }

  Widget _buildLumiHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LKColors.correctLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LKColors.correct, width: 2)),
      child: Row(children: [
        LumiMascot(mood: _lumiMood, size: 34),
        const SizedBox(width: 10),
        Expanded(child: Text(_lumiMsg,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: LKColors.textOnGreen))),
      ]),
    );
  }

  Widget _buildDecorRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: widget.theme.decorEmojis.map((e) =>
        Text(e, style: const TextStyle(fontSize: 22))).toList(),
    );
  }
}

class _WordData {
  final String word, emoji, arabic;
  final List<String> syllables;
  const _WordData({
    required this.word, required this.emoji,
    required this.syllables, required this.arabic,
  });
}