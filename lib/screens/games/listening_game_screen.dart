// lib/screens/games/listening_game_screen.dart
// CORRIGÉ : SoundService().play(SoundEffect.correct) au lieu de String

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

class ListeningGameScreen extends StatefulWidget {
  final String islandId;
  final IslandTheme theme;

  const ListeningGameScreen({
    super.key,
    required this.islandId,
    required this.theme,
  });

  @override
  State<ListeningGameScreen> createState() => _ListeningGameScreenState();
}

class _ListeningGameScreenState extends State<ListeningGameScreen>
    with TickerProviderStateMixin {

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  static const _totalQuestions = 8;
  int _currentQ  = 0;
  int _score     = 0;
  int _combo     = 0;
  int? _selectedIndex;
  bool _answered  = false;
  bool _isCorrect = false;
  LumiMood _lumiMood = LumiMood.guide;

  static const _vocab = [
    _VocabItem('pomme',   '🍎', 'تفاحة'),
    _VocabItem('chat',    '🐱', 'قطة'),
    _VocabItem('maison',  '🏠', 'دار'),
    _VocabItem('soleil',  '☀️', 'شمس'),
    _VocabItem('arbre',   '🌳', 'شجرة'),
    _VocabItem('voiture', '🚗', 'طومبيل'),
    _VocabItem('poisson', '🐟', 'حوت'),
    _VocabItem('fleur',   '🌸', 'وردة'),
    _VocabItem('chien',   '🐶', 'كلب'),
    _VocabItem('livre',   '📚', 'كتاب'),
    _VocabItem('oiseau',  '🐦', 'عصفور'),
    _VocabItem('lune',    '🌙', 'قمر'),
  ];

  late List<_VocabItem> _shuffled;
  late _VocabItem _correct;
  late List<_VocabItem> _choices;
  final _rng = Random();
  final Map<int, int> _wordQualities = {};

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut));
    _shuffled = List.from(_vocab)..shuffle(_rng);
    _setupQuestion();
  }

  @override
  void dispose() { _bounceCtrl.dispose(); super.dispose(); }

  void _setupQuestion() {
    _correct = _shuffled[_currentQ % _shuffled.length];
    final pool = _vocab.where((v) => v.word != _correct.word).toList()
      ..shuffle(_rng);
    _choices = [_correct, ...pool.take(3)]..shuffle(_rng);
    _selectedIndex = null;
    _answered      = false;
    _lumiMood      = LumiMood.guide;

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) TtsService().speak(_correct.word);
    });
  }

  void _onChoiceTap(int index) {
    if (_answered) return;
    HapticFeedback.lightImpact();

    final correct = _choices[index].word == _correct.word;
    setState(() {
      _selectedIndex = index;
      _answered      = true;
      _isCorrect     = correct;
      _lumiMood      = correct ? LumiMood.celebrate : LumiMood.encourage;
    });

    if (correct) {
      _combo++;
      _score += 1 + (_combo > 2 ? 1 : 0);
      // ✅ CORRIGÉ : SoundEffect enum
      SoundService().play(SoundEffect.correct);
      _wordQualities[_currentQ] = 5;
    } else {
      _combo = 0;
      // ✅ CORRIGÉ : SoundEffect enum
      SoundService().play(SoundEffect.wrong);
      TtsService().speak(_correct.word);
      _wordQualities[_currentQ] = 2;
    }

    _bounceCtrl.forward(from: 0).then((_) => _bounceCtrl.reverse());

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentQ + 1 >= _totalQuestions) {
        _finishGame();
      } else {
        setState(() { _currentQ++; _setupQuestion(); });
      }
    });
  }

  Future<void> _finishGame() async {
    await ProgressService().recordScore(
      levelId: widget.islandId,
      gameType: 'listening',
      score: _score,
      maxScore: _totalQuestions,
      wordQualities: _wordQualities,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => RewardScreen(
          score: _score, maxScore: _totalQuestions,
          gameTitle: 'Jeu d\'écoute',
          islandId: widget.islandId, theme: widget.theme,
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LKColors.bgBlueLight,
      body: Column(children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _buildLumiPromptCard(),
                const SizedBox(height: 12),
                _buildChoiceGrid(),
                const SizedBox(height: 14),
                _buildDecorBar(),
              ]),
            ),
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
            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: LKColors.sun, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LKColors.sunDark, width: 2)),
              child: Row(children: [
                const Icon(Icons.star_rounded,
                    color: LKColors.textOnYellow, size: 16),
                const SizedBox(width: 4),
                Text('$_score pts',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: LKColors.textOnYellow)),
              ]),
            ),
            const SizedBox(width: 8),
            // Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20)),
              child: Text('Q ${_currentQ + 1} / $_totalQuestions',
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: LKColors.textDark)),
            ),
            // Combo
            if (_combo >= 2) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C6B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF6040), width: 2)),
                child: Text('🔥 x$_combo',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: LKProgressBar(
            progress: (_currentQ + 1) / _totalQuestions,
            fillColor: LKColors.sun,
            bgColor: Colors.white.withOpacity(0.3), height: 10),
        ),
      ])),
    );
  }

  Widget _buildLumiPromptCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LKColors.sun, width: 3)),
      child: Column(children: [
        AnimatedBuilder(
          animation: _bounceAnim,
          builder: (_, child) => Transform.scale(
            scale: _answered ? _bounceAnim.value : 1.0, child: child),
          child: LumiMascot(mood: _lumiMood, size: 56),
        ),
        const SizedBox(height: 10),
        Text(
          _answered
            ? (_isCorrect
              ? '⭐ Super ! C\'est bien "${_correct.word}" !'
              : '💪 Le mot était "${_correct.word}"')
            : 'Lumi dit... écoute bien !',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
            color: _answered
              ? (_isCorrect ? LKColors.textOnGreen
                           : const Color(0xFF993556))
              : LKColors.textOnYellow),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            TtsService().speak(_correct.word);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: LKColors.bgBlueLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LKColors.island1Green, width: 2.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: LKColors.island1Green, shape: BoxShape.circle,
                  border: Border.all(color: LKColors.island1Dark, width: 2)),
                child: const Icon(Icons.volume_up_rounded,
                    color: Colors.white, size: 22)),
              const SizedBox(width: 10),
              const Text('Appuie pour écouter !',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                    color: LKColors.textOnGreen)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildChoiceGrid() {
    return Column(children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('👇 Tape la bonne image',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: LKColors.textMedium)),
        ),
      ),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 10,
          crossAxisSpacing: 10, childAspectRatio: 1.0),
        itemCount: _choices.length,
        itemBuilder: (_, i) => _buildChoiceCard(i),
      ),
    ]);
  }

  Widget _buildChoiceCard(int index) {
    final item = _choices[index];
    final isSelected    = _selectedIndex == index;
    final isCorrectItem = item.word == _correct.word;

    Color borderColor = LKColors.neutralDark;
    Color bgColor     = Colors.white;

    if (_answered && isSelected) {
      borderColor = _isCorrect ? LKColors.correct : LKColors.wrong;
      bgColor     = _isCorrect ? LKColors.correctLight : LKColors.wrongLight;
    } else if (_answered && isCorrectItem) {
      borderColor = LKColors.correct;
      bgColor     = LKColors.correctLight;
    }

    return GestureDetector(
      onTap: () => _onChoiceTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? borderColor : LKColors.neutralDark,
            width: isSelected ? 3.5 : 2.5)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(item.emoji, style: const TextStyle(fontSize: 50)),
          const SizedBox(height: 8),
          Text(item.word,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
              color: _answered && isCorrectItem
                ? LKColors.textOnGreen : LKColors.textDark)),
          if (_answered && isSelected)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(item.arabic,
                style: const TextStyle(
                    fontSize: 10, color: LKColors.textMedium))),
        ]),
      ),
    );
  }

  Widget _buildDecorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: widget.theme.primary,
        borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: widget.theme.decorEmojis.map((e) =>
          Text(e, style: const TextStyle(fontSize: 20))).toList(),
      ),
    );
  }
}

class _VocabItem {
  final String word, emoji, arabic;
  const _VocabItem(this.word, this.emoji, this.arabic);
}