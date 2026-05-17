// lib/screens/games/memory_matching_game_cp.dart
// ════════════════════════════════════════════════════════════
// JEU 3 CP — MÉMORISATION (Matching)
// Associer l'image (avion) avec la lettre (A)
// Grille 2×3 de cartes retournées — 3 paires des lettres du jour
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
import 'letter_writing_game_cp.dart';

// ── Un carte mémoire ──────────────────────────────────────────
class _MemCard {
  final String pairId; // la lettre (A, B, C)
  final bool isImage; // true = image du mot, false = lettre texte
  bool flipped = false;
  bool matched = false;
  _MemCard({required this.pairId, required this.isImage});
}

class MemoryMatchingGameCP extends StatefulWidget {
  final String islandId;
  final List<String> letters;
  final int dayNumber;
  final IslandTheme theme;
  const MemoryMatchingGameCP({
    super.key,
    required this.islandId,
    required this.letters,
    required this.dayNumber,
    required this.theme,
  });
  @override
  State<MemoryMatchingGameCP> createState() => _State();
}

class _State extends State<MemoryMatchingGameCP> with TickerProviderStateMixin {
  late List<_MemCard> _cards;
  int? _first, _second;
  bool _checking = false;
  int _matched = 0;
  int _moves = 0;
  int _score = 0;
  LumiMood _mood = LumiMood.guide;
  String _lumiMsg = 'Retourne les cartes pour trouver les paires !';

  late List<AnimationController> _flipCtrls;
  late List<Animation<double>> _flipAnims;
  late AnimationController _floatCtrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _float = Tween(begin: -5.0, end: 5.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _buildCards();
    _flipCtrls = List.generate(
        _cards.length,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 400)));
    _flipAnims = _flipCtrls
        .map((c) => Tween(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
    // Instruction audio
    Future.delayed(const Duration(milliseconds: 500), () {
      TtsService().speak('Trouve les paires ! Touche les cartes !');
    });
  }

  void _buildCards() {
    // Pour chaque lettre du jour : 1 carte image + 1 carte lettre
    final cards = <_MemCard>[];
    for (final l in widget.letters) {
      cards.add(_MemCard(pairId: l, isImage: true));
      cards.add(_MemCard(pairId: l, isImage: false));
    }
    cards.shuffle(Random());
    _cards = cards;
  }

  @override
  void dispose() {
    for (final c in _flipCtrls) c.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCardTap(int i) async {
    if (_checking) return;
    if (_cards[i].matched) return;
    if (_cards[i].flipped) return;
    if (_first != null && _second != null) return;

    HapticFeedback.lightImpact();
    _flipCtrls[i].forward();
    setState(() {
      _cards[i].flipped = true;
      _lumiMsg = _first == null ? 'Bien ! Cherche la paire !' : 'Voyons...';
      _mood = LumiMood.thinking;
    });

    // Prononce la lettre à chaque retournement
    final data = kLetterDB[_cards[i].pairId];
    if (data != null) {
      await TtsService().speak(_cards[i].isImage ? data.word : data.letter);
    }

    if (_first == null) {
      _first = i;
    } else {
      _second = i;
      _checking = true;
      _moves++;

      final a = _first!;
      final b = _second!;
      await Future.delayed(const Duration(milliseconds: 700));

      // Match = même pairId, types différents (image ≠ lettre)
      final isMatch = _cards[a].pairId == _cards[b].pairId &&
          _cards[a].isImage != _cards[b].isImage;

      if (isMatch) {
        SoundService().play(SoundEffect.match);
        _score += 2;
        setState(() {
          _cards[a].matched = true;
          _cards[b].matched = true;
          _matched++;
          _mood = LumiMood.celebrate;
          _lumiMsg = '🎉 Bravo ! Paire trouvée !';
        });
        if (data != null) {
          await TtsService()
              .speak('Bravo ! ${data.letter} comme ${data.word} !');
        }
        if (_matched == widget.letters.length) {
          await Future.delayed(const Duration(milliseconds: 800));
          _finish();
        }
      } else {
        SoundService().play(SoundEffect.wrong);
        setState(() {
          _mood = LumiMood.encourage;
          _lumiMsg = 'Essaie encore ! 💪';
        });
        await Future.delayed(const Duration(milliseconds: 600));
        _flipCtrls[a].reverse();
        _flipCtrls[b].reverse();
        setState(() {
          _cards[a].flipped = false;
          _cards[b].flipped = false;
          _mood = LumiMood.guide;
          _lumiMsg = 'Continue à chercher les paires !';
        });
      }
      _first = null;
      _second = null;
      _checking = false;
    }
  }

  Future<void> _finish() async {
    await ProgressService().recordScore(
      levelId: widget.islandId,
      gameType: 'memory_${widget.dayNumber}',
      score: _score,
      maxScore: widget.letters.length * 2,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => LetterWritingGameCP(
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
    final total = widget.letters.length;
    return Scaffold(
      backgroundColor: const Color(0xFFEEEDFE),
      body: SafeArea(
          child: Column(children: [
        _topBar(t, total),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _lumiStrip(),
            const SizedBox(height: 14),
            Expanded(child: _grid()),
            const SizedBox(height: 12),
            _statsRow(total),
          ]),
        )),
      ])),
    );
  }

  Widget _topBar(IslandTheme t, int total) => Container(
        color: const Color(0xFF8B7FD4),
        child: Column(children: [
          // Rainbow strip
          Container(
              height: 5,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                Color(0xFFFF6B6B),
                Color(0xFFFFD93D),
                Color(0xFF5DCAA5),
                Color(0xFF4DC8E8),
                Color(0xFFC3A6FF),
                Color(0xFFFF8C6B)
              ]))),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.black54, size: 20))),
              const Spacer(),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFD93D),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: const Color(0xFFFFA000), width: 2)),
                  child: Text('🃏 $_matched/$total paires',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7A3800)))),
              const Spacer(),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(14)),
                  child: Text('⭐ $_score',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7A3800)))),
            ]),
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                      value: _matched / widget.letters.length,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFFFFD93D))))),
        ]),
      );

  Widget _lumiStrip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF9CC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD93D), width: 2.5)),
        child: Row(children: [
          AnimatedBuilder(
              animation: _float,
              builder: (_, child) => Transform.translate(
                  offset: Offset(0, _float.value), child: child),
              child: LumiMascot(mood: _mood, size: 42)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_lumiMsg,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7A5200)))),
        ]),
      );

  Widget _grid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85),
      itemCount: _cards.length,
      itemBuilder: (_, i) => _card(i),
    );
  }

  Widget _card(int i) {
    final c = _cards[i];
    return GestureDetector(
      onTap: () => _onCardTap(i),
      child: AnimatedBuilder(
        animation: _flipAnims[i],
        builder: (_, __) {
          final t = _flipAnims[i].value;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY((1 - t) * 3.14159),
            alignment: Alignment.center,
            child: t >= 0.5 ? _cardFront(c) : _cardBack(),
          );
        },
      ),
    );
  }

  Widget _cardFront(_MemCard c) {
    final data = kLetterDB[c.pairId];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
          color: c.matched ? const Color(0xFFE1F5EE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color:
                  c.matched ? const Color(0xFF5DCAA5) : const Color(0xFF8B7FD4),
              width: c.matched ? 3 : 2.5)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (c.isImage && data != null)
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(data.wordAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                          child: Text(data.word[0],
                              style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: data.dark))))))
        else if (data != null)
          Expanded(
              child: Center(
                  child: Text(c.pairId,
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: data.dark))))
        else
          Expanded(
              child: Center(
                  child: Text(c.pairId,
                      style: const TextStyle(
                          fontSize: 34, fontWeight: FontWeight.w900)))),
        if (c.matched)
          const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('✅', style: TextStyle(fontSize: 14))),
      ]),
    );
  }

  Widget _cardBack() => Container(
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF8B7FD4), Color(0xFF6B5FC4)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5240A8), width: 2.5)),
        child: Center(
            child: Text('?',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.8)))),
      );

  Widget _statsRow(int total) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF8B7FD4).withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF8B7FD4).withOpacity(0.3), width: 1.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat('🃏', '$_matched/$total', 'Paires'),
          _stat('🔄', '$_moves', 'Essais'),
          _stat('⭐', '$_score', 'Points'),
        ]),
      );

  Widget _stat(String emoji, String value, String label) => Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF5240A8))),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF8B7FD4))),
      ]);
}
