// lib/screens/bingo_game_screen.dart
import '../services/progress_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/game_models.dart';
import '../services/tts_service.dart';
import '../services/adaptive_engine.dart';

class BingoGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const BingoGameScreen({super.key, required this.levelData});
  @override State<BingoGameScreen> createState() => _BingoGameScreenState();
}

class _BingoGameScreenState extends State<BingoGameScreen> with SingleTickerProviderStateMixin {
  late List<Word> grid;
  late List<bool> marked;
  late List<int> targets;
  int idx = 0, score = 0, mistakes = 0;
  bool announcing = false;
  late Stopwatch _sw;
  final _tts = TtsService();
  late AnimationController _pulse;
  late Animation<double> _pulseA;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseA = Tween<double>(begin: 0.92, end: 1.05).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _init();
  }

  void _init() {
    final words = [...widget.levelData.vocabulary]..shuffle();
    grid = words.take(9).toList();
    marked = List.filled(9, false);
    final pos = List.generate(9, (i) => i)..shuffle();
    targets = pos.take(5).toList();
    _sw = Stopwatch()..start();
    Future.delayed(const Duration(milliseconds: 800), _announce);
  }

  Future<void> _announce() async {
    if (!mounted || idx >= targets.length) return;
    setState(() => announcing = true);
    final word = grid[targets[idx]];
    await _tts.speak('Trouve : ${word.word}');
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => announcing = false);
  }

  void _onTap(int pos) {
    if (announcing || marked[pos]) return;
    if (pos == targets[idx]) {
      setState(() { marked[pos] = true; score += 10; idx++; });
      _tts.speak('Bravo ! ${grid[pos].word}');
      if (idx >= targets.length) {
        Future.delayed(const Duration(milliseconds: 600), _finish);
      } else {
        Future.delayed(const Duration(milliseconds: 1200), _announce);
      }
    } else {
      mistakes++;
      _tts.speak('Non, réessaie !');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌  Cherche encore : ${grid[targets[idx]].word}'),
        backgroundColor: Colors.orange, duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _finish() {
    _sw.stop();
    ProgressService().recordScore(
    levelId: widget.levelData.id,
    gameType: 'bingo',
    score: score,
    maxScore: targets.length * 10,
    durationSeconds: _sw.elapsed.inSeconds,
    errorsCount: mistakes,
  );
    final pct = (score / (targets.length * 10) * 100).round();
    _tts.speak('Bingo ! Félicitations !');
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.purple[50],
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎯', style: TextStyle(fontSize: 52)),
        const Text('BINGO !', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.purple)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) =>
            Icon(Icons.star, color: i < _stars(pct) ? Colors.amber : Colors.grey[300], size: 36))),
        const SizedBox(height: 12),
        Text('$score / ${targets.length * 10} pts',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('Erreurs : $mistakes  •  ${_sw.elapsed.inSeconds}s',
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ]),
      actions: [SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[600],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Retour', style: TextStyle(color: Colors.white, fontSize: 16)),
      ))],
    ));
  }

  int _stars(int p) { if (p >= 80) return 3; if (p >= 60) return 2; return 1; }

  @override
  void dispose() { _pulse.dispose(); _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final current = idx < targets.length ? grid[targets[idx]] : null;
    return WillPopScope(
      onWillPop: () async => await showDialog<bool>(context: context,
        builder: (_) => AlertDialog(title: const Text('Quitter ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continuer')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitter')),
          ])) ?? false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bingo — ${widget.levelData.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF6A1B9A), foregroundColor: Colors.white, elevation: 0,
          actions: [Padding(padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('$idx/${targets.length}  •  $score pts',
                  style: const TextStyle(fontWeight: FontWeight.bold))))],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.purple[50]!, Colors.white],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              LinearProgressIndicator(
                value: idx / targets.length, minHeight: 6,
                backgroundColor: Colors.purple[100],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
              ),
              const SizedBox(height: 14),

              // Mot à trouver
              if (current != null)
                AnimatedBuilder(
                  animation: _pulseA,
                  builder: (_, child) => Transform.scale(scale: announcing ? _pulseA.value : 1.0, child: child),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => _tts.speak('Trouve : ${current.word}'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.volume_up, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(current.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Trouve :', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text(current.word, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ])),
                      announcing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                              child: Text('${idx + 1}/${targets.length}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ]),
                  ),
                ),
              const SizedBox(height: 14),

              // Grille 3x3
              Expanded(child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
                itemCount: 9,
                itemBuilder: (_, i) {
                  final word = grid[i];
                  final isMarked = marked[i];
                  return GestureDetector(
                    onTap: isMarked ? null : () => _onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isMarked ? Colors.green[100] : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isMarked ? Colors.green : Colors.purple[300]!,
                          width: 2,
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Stack(children: [
                        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(word.emoji, style: const TextStyle(fontSize: 34)),
                          const SizedBox(height: 4),
                          Text(word.word, textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                        ])),
                        if (isMarked)
                          Container(
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                            child: const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 40)),
                          ),
                      ]),
                    ),
                  );
                },
              )),

              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple[200]!)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.touch_app, color: Colors.purple[700], size: 18), const SizedBox(width: 6),
                  Text('Clique sur le mot annoncé !',
                      style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}