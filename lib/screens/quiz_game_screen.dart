// lib/screens/quiz_game_screen.dart
import '../services/progress_service.dart';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/tts_service.dart';
import '../services/adaptive_engine.dart';

class QuizGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const QuizGameScreen({super.key, required this.levelData});
  @override State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  late List<QuizQuestion> questions;
  int currentQ = 0, score = 0;
  bool answered = false;
  String? selected;
  late Stopwatch _sw;
  final _tts = TtsService();

  @override
  void initState() {
    super.initState();
    questions = _build();
    _sw = Stopwatch()..start();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (questions.isNotEmpty) _tts.speak(questions[0].options.firstWhere((o) => o.id == questions[0].correctAnswerId).label);
    });
  }

  List<QuizQuestion> _build() {
    final vocab = widget.levelData.vocabulary;
    final qs = <QuizQuestion>[];
    for (int i = 0; i < vocab.length && i < 10; i++) {
      final correct = vocab[i];
      final others = vocab.where((w) => w.id != correct.id).toList()..shuffle();
      final opts = <QuizOption>[QuizOption(id: 'opt_0', label: correct.word)];
      for (int j = 0; j < 3 && j < others.length; j++) {
        opts.add(QuizOption(id: 'opt_${j + 1}', label: others[j].word));
      }
      opts.shuffle();
      qs.add(QuizQuestion(
        id: i,
        question: 'Quel mot correspond à cet emoji ?',
        emoji: correct.emoji,
        options: opts,
        correctAnswerId: opts.firstWhere((o) => o.label == correct.word).id,
        explanation: '✅  ${correct.word}  —  ${correct.traductionArabic ?? correct.traductionDarija ?? ""}',
      ));
    }
    return qs;
  }

  void _answer(String optId) {
    if (answered) return;
    final q = questions[currentQ];
    setState(() { answered = true; selected = optId; });
    final isCorrect = optId == q.correctAnswerId;
    if (isCorrect) {
      score += 10;
      final label = q.options.firstWhere((o) => o.id == optId).label;
      _tts.speak('Bravo ! $label');
    } else {
      final cl = q.options.firstWhere((o) => o.id == q.correctAnswerId).label;
      _tts.speak('La bonne réponse est : $cl');
    }
  }

  void _next() {
    if (currentQ < questions.length - 1) {
      setState(() { currentQ++; answered = false; selected = null; });
      final q = questions[currentQ];
      Future.delayed(const Duration(milliseconds: 300), () {
        _tts.speak(q.options.firstWhere((o) => o.id == q.correctAnswerId).label);
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    _sw.stop();
    ProgressService().recordScore(
  levelId: widget.levelData.id,
  gameType: 'quiz',
  score: score,
  maxScore: questions.length * 10,
  durationSeconds: _sw.elapsed.inSeconds,
);
    final pct = (score / (questions.length * 10) * 100).round();
    _tts.speak(AdaptiveEngine().encouragementMessage(score * 100 ~/ (questions.length * 10)));
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.amber[50],
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🏆', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 8),
        const Text('Quiz Terminé !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) =>
            Icon(Icons.star, color: i < _stars(pct) ? Colors.amber : Colors.grey[300], size: 36))),
        const SizedBox(height: 12),
        Text('$score / ${questions.length * 10} pts',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('$pct%  •  ${_sw.elapsed.inSeconds}s',
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ]),
      actions: [SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Retour', style: TextStyle(color: Colors.white, fontSize: 16)),
      ))],
    ));
  }

  int _stars(int p) { if (p >= 80) return 3; if (p >= 60) return 2; return 1; }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final q = questions[currentQ];

    return WillPopScope(
      onWillPop: () async => await showDialog<bool>(context: context,
        builder: (_) => AlertDialog(title: const Text('Quitter ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continuer')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitter')),
          ])) ?? false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Quiz — ${widget.levelData.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, elevation: 0,
          actions: [Padding(padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${currentQ + 1}/${questions.length}  •  $score pts',
                  style: const TextStyle(fontWeight: FontWeight.bold))))],
        ),
        body: Column(children: [
          LinearProgressIndicator(
            value: (currentQ + 1) / questions.length, minHeight: 6,
            backgroundColor: Colors.green[100],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Emoji géant
              GestureDetector(
                onTap: () {
                  final label = q.options.firstWhere((o) => o.id == q.correctAnswerId).label;
                  _tts.speak(label);
                },
                child: Container(
                  width: double.infinity, height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green[200]!, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(q.emoji ?? '❓', style: const TextStyle(fontSize: 80)),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.volume_up, color: Colors.green[400], size: 16),
                      const SizedBox(width: 4),
                      Text('Appuie pour écouter', style: TextStyle(fontSize: 11, color: Colors.green[400])),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Text(q.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ...q.options.map((opt) {
                final isSel = opt.id == selected;
                final isOk  = opt.id == q.correctAnswerId;
                Color bg = Colors.white;
                Color bd = Colors.green[200]!;
                if (answered) {
                  if (isSel && isOk) { bg = Colors.green[100]!; bd = Colors.green; }
                  else if (isSel)    { bg = Colors.red[100]!;   bd = Colors.red; }
                  else if (isOk)     { bg = Colors.green[50]!;  bd = Colors.green[300]!; }
                }
                return Padding(padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: answered ? null : () => _answer(opt.id),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: bd, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
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
              if (answered && q.explanation != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                  child: Text(q.explanation!, style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(height: 16),
              if (answered) SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(
                  currentQ == questions.length - 1 ? 'Terminer !' : 'Suivant →',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )),
            ]),
          )),
        ]),
      ),
    );
  }
}