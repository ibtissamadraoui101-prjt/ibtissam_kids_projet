// lib/screens/games/memory_game_screen.dart
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

class MemoryGameScreen extends StatefulWidget {
  final String islandId;
  final IslandTheme theme;

  const MemoryGameScreen({
    super.key,
    required this.islandId,
    required this.theme,
  });

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with TickerProviderStateMixin {

  static const _pairs = [
    _MemoPair('pomme',   '🍎', 'تفاحة'),
    _MemoPair('chat',    '🐱', 'قطة'),
    _MemoPair('maison',  '🏠', 'دار'),
    _MemoPair('soleil',  '☀️', 'شمس'),
    _MemoPair('arbre',   '🌳', 'شجرة'),
    _MemoPair('voiture', '🚗', 'طومبيل'),
  ];

  late List<_MemoCard> _cards;
  final List<int> _flipped = [];
  final Set<int>  _matched = {};
  bool _checking = false;
  int  _moves    = 0;
  int  _score    = 0;
  LumiMood _lumiMood = LumiMood.guide;
  String   _lumiMsg  = 'Retourne les cartes pour trouver les paires !';
  late DateTime _startTime;

  late List<AnimationController> _flipCtrls;
  late List<Animation<double>>   _flipAnims;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _buildCards();
    _flipCtrls = List.generate(_cards.length, (i) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400)));
    _flipAnims = _flipCtrls.map((c) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
  }

  void _buildCards() {
    final pool     = List<_MemoPair>.from(_pairs)..shuffle(Random());
    final selected = pool.take(6).toList();
    final cards    = <_MemoCard>[];
    for (int i = 0; i < selected.length; i++) {
      cards.add(_MemoCard(id: i * 2,     pair: selected[i], isImage: true));
      cards.add(_MemoCard(id: i * 2 + 1, pair: selected[i], isImage: false));
    }
    cards.shuffle(Random());
    _cards = cards;
  }

  @override
  void dispose() {
    for (final c in _flipCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _onCardTap(int index) async {
    if (_checking) return;
    if (_matched.contains(index)) return;
    if (_flipped.contains(index)) return;
    if (_flipped.length >= 2) return;

    HapticFeedback.lightImpact();
    _flipCtrls[index].forward();
    TtsService().speak(_cards[index].pair.word);

    setState(() {
      _flipped.add(index);
      _lumiMsg = _flipped.length == 1
        ? 'Bien ! Maintenant cherche la paire !'
        : 'Voyons si c\'est une paire...';
    });

    if (_flipped.length == 2) {
      _checking = true;
      _moves++;
      final a = _flipped[0];
      final b = _flipped[1];
      await Future.delayed(const Duration(milliseconds: 800));

      final match = _cards[a].pair.word == _cards[b].pair.word
                 && _cards[a].isImage != _cards[b].isImage;

      if (match) {
        // ✅ CORRIGÉ
        SoundService().play(SoundEffect.match);
        _score += 2;
        setState(() {
          _matched.addAll([a, b]);
          _flipped.clear();
          _lumiMood = LumiMood.celebrate;
          _lumiMsg  = '🎉 Bravo ! Une paire trouvée !';
        });
        Future.delayed(const Duration(milliseconds: 600),
          () { if (mounted) setState(() => _lumiMood = LumiMood.happy); });

        if (_matched.length == _cards.length) {
          await Future.delayed(const Duration(milliseconds: 800));
          _finishGame();
        }
      } else {
        // ✅ CORRIGÉ
        SoundService().play(SoundEffect.wrong);
        setState(() {
          _lumiMood = LumiMood.encourage;
          _lumiMsg  = 'Pas de chance ! Essaie encore 💪';
        });
        await Future.delayed(const Duration(milliseconds: 600));
        _flipCtrls[a].reverse();
        _flipCtrls[b].reverse();
        setState(() {
          _flipped.clear();
          _lumiMood = LumiMood.guide;
          _lumiMsg  = 'Continue à chercher les paires !';
        });
      }
      _checking = false;
    }
  }

  Future<void> _finishGame() async {
    final duration = DateTime.now().difference(_startTime);
    await ProgressService().recordScore(
      levelId: widget.islandId,
      gameType: 'memory',
      score: _score,
      maxScore: _pairs.length * 2,
      durationSeconds: duration.inSeconds,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => RewardScreen(
          score: _score, maxScore: _pairs.length * 2,
          gameTitle: 'Jeu de Mémoire',
          islandId: widget.islandId, theme: widget.theme,
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final found = _matched.length ~/ 2;
    final total = _cards.length ~/ 2;
    return Scaffold(
      backgroundColor: const Color(0xFFEEEDFE),
      body: Column(children: [
        _buildTopBar(found, total),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              _buildLumiStrip(),
              const SizedBox(height: 14),
              _buildGrid(),
              const SizedBox(height: 12),
              _buildStats(found, total),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildTopBar(int found, int total) {
    return Container(
      decoration: const BoxDecoration(color: LKColors.island3Purple),
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
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: LKColors.sun,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LKColors.sunDark, width: 2)),
              child: Text('🃏 $found / $total paires',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                    color: LKColors.textOnYellow)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16)),
              child: Text('⭐ $_score pts',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                    color: LKColors.textOnYellow)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: LKProgressBar(
            progress: _matched.length / _cards.length,
            fillColor: LKColors.island3Purple,
            bgColor: Colors.white.withOpacity(0.3), height: 8),
        ),
      ])),
    );
  }

  Widget _buildLumiStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9CC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LKColors.sun, width: 2.5)),
      child: Row(children: [
        LumiMascot(mood: _lumiMood, size: 40),
        const SizedBox(width: 10),
        Expanded(child: Text(_lumiMsg,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: LKColors.textOnYellow))),
      ]),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 10,
        crossAxisSpacing: 10, childAspectRatio: 0.85),
      itemCount: _cards.length,
      itemBuilder: (_, i) => _buildCard(i),
    );
  }

  Widget _buildCard(int index) {
    final isFlipped = _flipped.contains(index) || _matched.contains(index);
    final isMatched = _matched.contains(index);

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedBuilder(
        animation: _flipAnims[index],
        builder: (_, __) {
          final t      = _flipAnims[index].value;
          final isFront = t >= 0.5;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY((1 - t) * pi),
            alignment: Alignment.center,
            child: isFront || isFlipped
              ? _cardFront(_cards[index], isMatched)
              : _cardBack(),
          );
        },
      ),
    );
  }

  Widget _cardFront(_MemoCard card, bool isMatched) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isMatched ? LKColors.correctLight : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMatched ? LKColors.correct : LKColors.island3Purple,
          width: isMatched ? 3 : 2.5)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (card.isImage)
          Text(card.pair.emoji, style: const TextStyle(fontSize: 32))
        else ...[
          Text(card.pair.word,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                color: LKColors.island3Dark)),
          const SizedBox(height: 3),
          Text(card.pair.arabic,
            style: const TextStyle(fontSize: 10, color: LKColors.textLight)),
        ],
        if (isMatched)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('✅', style: TextStyle(fontSize: 14))),
      ]),
    );
  }

  Widget _cardBack() {
    return Container(
      decoration: BoxDecoration(
        color: LKColors.island3Purple,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LKColors.island3Dark, width: 2.5)),
      child: Center(child: Text('?',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.8)))),
    );
  }

  Widget _buildStats(int found, int total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LKColors.island3Purple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: LKColors.island3Purple.withOpacity(0.3), width: 1.5)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat('🃏', '$found/$total', 'Paires'),
        _stat('🔄', '$_moves',       'Essais'),
        _stat('⭐', '$_score',       'Points'),
      ]),
    );
  }

  Widget _stat(String emoji, String value, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      Text(value, style: const TextStyle(fontSize: 16,
          fontWeight: FontWeight.w900, color: LKColors.island3Dark)),
      Text(label, style: const TextStyle(
          fontSize: 10, color: LKColors.textMedium)),
    ]);
  }
}

class _MemoPair {
  final String word, emoji, arabic;
  const _MemoPair(this.word, this.emoji, this.arabic);
}

class _MemoCard {
  final int id;
  final _MemoPair pair;
  final bool isImage;
  const _MemoCard({required this.id, required this.pair, required this.isImage});
}