// lib/screens/parcours_game_screen.dart
import '../services/progress_service.dart';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/tts_service.dart';
import '../services/adaptive_engine.dart';

class ParcourGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const ParcourGameScreen({super.key, required this.levelData});
  @override State<ParcourGameScreen> createState() => _ParcourGameScreenState();
}

class _ParcourGameScreenState extends State<ParcourGameScreen> {
  late ParcourGame game;
  late List<ParcoursChallenges> challenges;
  int score = 0;
  String? selectedOpt;
  bool answered = false;
  late Stopwatch _sw;
  final _tts = TtsService();

  @override
  void initState() {
    super.initState();
    challenges = _build();
    game = ParcourGame(cases: challenges);
    _sw = Stopwatch()..start();
    Future.delayed(const Duration(milliseconds: 700), _announce);
  }

  List<ParcoursChallenges> _build() {
    final words = widget.levelData.vocabulary;
    final result = <ParcoursChallenges>[];
    for (int i = 0; i < words.length && i < 12; i++) {
      final w = words[i];
      result.add(ParcoursChallenges(
        caseNumber: i + 1,
        type: i % 2 == 0 ? 'emoji' : 'question',
        instruction: i % 2 == 0 ? 'Quel est ce mot ?' : 'Choisis la bonne réponse !',
        word: w,
        correctAnswer: 'opt_0',
        question: QuizQuestion(
          id: i,
          question: i % 2 == 0 ? 'Quel est ce mot ?' : 'Comment dit-on « ${w.traductionArabic ?? w.word} » ?',
          emoji: w.emoji,
          options: _opts(words, i),
          correctAnswerId: 'opt_0',
        ),
      ));
    }
    return result;
  }

  List<QuizOption> _opts(List<Word> words, int ci) {
    final correct = words[ci];
    final others  = words.where((w) => w.id != correct.id).toList()..shuffle();
    final raw     = [correct, ...others.take(3)];
    raw.shuffle();
    return raw.map((w) => QuizOption(
      id: w.id == correct.id ? 'opt_0' : 'opt_${w.id}',
      label: w.word,
    )).toList();
  }

  void _announce() {
    final ch = game.getCurrentChallenge();
    if (ch == null || ch.word == null) return;
    _tts.speak(ch.word!.word);
  }

  void _onAnswer(String optId) {
    if (answered) return;
    final ch = game.getCurrentChallenge();
    if (ch == null) return;
    final ok = optId == ch.correctAnswer;
    setState(() { selectedOpt = optId; answered = true; });
    if (ok) {
      score += 10;
      _tts.speak('Bravo ! ${ch.word?.word ?? ""}');
    } else {
      _tts.speak('La bonne réponse est ${ch.word?.word ?? ""}');
    }
    Future.delayed(const Duration(milliseconds: 1800), () {
      game.advance();
      setState(() { selectedOpt = null; answered = false; });
      if (game.isFinished()) {
        _finish();
      } else {
        Future.delayed(const Duration(milliseconds: 400), _announce);
      }
    });
  }

  void _finish() {
    _sw.stop();
    ProgressService().recordScore(
    levelId: widget.levelData.id,
    gameType: 'parcours',
    score: score,
    maxScore: challenges.length * 10,
    durationSeconds: _sw.elapsed.inSeconds,
);
  // 
    final pct = (score / (challenges.length * 10) * 100).round();
    _tts.speak('Parcours terminé ! Félicitations !');
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.orange[50],
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🏁', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 8),
        const Text('Parcours Terminé !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) =>
            Icon(Icons.star, color: i < _stars(pct) ? Colors.amber : Colors.grey[300], size: 36))),
        const SizedBox(height: 12),
        Text('$score / ${challenges.length * 10} pts',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('${_sw.elapsed.inSeconds}s', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ]),
      actions: [SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Retour', style: TextStyle(color: Colors.white, fontSize: 16)),
      ))],
    ));
  }

  int _stars(int p) { if (p >= 80) return 3; if (p >= 60) return 2; return 1; }

  @override
  void dispose() { _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (game.isFinished()) return Scaffold(
      appBar: AppBar(title: const Text('Parcours'), backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🏁', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        const Text('Terminé !', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('$score pts', style: const TextStyle(fontSize: 18)),
      ])),
    );

    final ch = game.getCurrentChallenge();
    if (ch == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return WillPopScope(
      onWillPop: () async => await showDialog<bool>(context: context,
        builder: (_) => AlertDialog(title: const Text('Quitter ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continuer')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitter')),
          ])) ?? false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Parcours — ${widget.levelData.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white, elevation: 0,
          actions: [Padding(padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('Case ${game.currentCase + 1}/${challenges.length}  •  $score pts',
                  style: const TextStyle(fontWeight: FontWeight.bold))))],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.orange[50]!, Colors.white],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: Column(children: [
            LinearProgressIndicator(
              value: game.currentCase / challenges.length, minHeight: 6,
              backgroundColor: Colors.orange[100],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
            ),
            // Mini plateau
            _miniBoard(),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Instruction
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFE65100).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(ch.type == 'emoji' ? '🖼️' : '❓', style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(ch.instruction,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87))),
                  if (ch.word != null)
                    IconButton(
                      onPressed: () => _tts.speak(ch.word!.word),
                      icon: const Icon(Icons.volume_up, color: Color(0xFFE65100)),
                    ),
                ]),
                const SizedBox(height: 16),
                // Emoji du mot
                if (ch.word != null)
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange[200]!, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
                    ),
                    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(ch.word!.emoji, style: const TextStyle(fontSize: 72)),
                      if (ch.type == 'question')
                        Text(ch.word!.traductionArabic ?? ch.word!.traductionDarija ?? '',
                            style: const TextStyle(fontSize: 18, color: Colors.grey)),
                    ])),
                  ),
                const SizedBox(height: 16),
                // Options QCM
                if (ch.question != null)
                  ...ch.question!.options.map((opt) {
                    final isSel = opt.id == selectedOpt;
                    final isOk  = opt.id == ch.correctAnswer;
                    Color bg = Colors.white; Color bd = Colors.orange[200]!;
                    if (answered) {
                      if (isSel && isOk) { bg = Colors.green[100]!; bd = Colors.green; }
                      else if (isSel)    { bg = Colors.red[100]!;   bd = Colors.red; }
                      else if (isOk)     { bg = Colors.green[50]!;  bd = Colors.green[300]!; }
                    }
                    return Padding(padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: answered ? null : () => _onAnswer(opt.id),
                        child: AnimatedContainer(duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: bd, width: 2)),
                          child: Row(children: [
                            Expanded(child: Text(opt.label,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                            if (answered && isSel)
                              Icon(isOk ? Icons.check_circle : Icons.cancel, color: isOk ? Colors.green : Colors.red),
                            if (answered && !isSel && isOk)
                              const Icon(Icons.check_circle_outline, color: Colors.green),
                          ]),
                        ),
                      ),
                    );
                  }),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _miniBoard() => SizedBox(
    height: 50,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: challenges.length,
      itemBuilder: (_, i) {
        final done = i < game.currentCase, cur = i == game.currentCase;
        return Container(
          width: 28, height: 28, margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            color: done ? Colors.green : cur ? const Color(0xFFE65100) : Colors.orange[100],
            shape: BoxShape.circle,
            border: Border.all(color: cur ? const Color(0xFFE65100) : Colors.transparent, width: 2),
          ),
          child: Center(child: done
              ? const Icon(Icons.check, color: Colors.white, size: 13)
              : Text('${i + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                  color: cur ? Colors.white : Colors.orange[700]))),
        );
      },
    ),
  );
}