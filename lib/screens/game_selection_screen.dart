// lib/screens/game_selection_screen.dart
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/tts_service.dart';
import 'memory_game_screen.dart';
import 'quiz_game_screen.dart';
import 'bingo_game_screen.dart';
import 'parcours_game_screen.dart';

class GameSelectionScreen extends StatelessWidget {
  final GameLevelData levelData;
  const GameSelectionScreen({super.key, required this.levelData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(levelData.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white, elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Colors.white],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info niveau
              Container(
                width: double.infinity, padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(levelData.getProgression(),
                        style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 10),
                  Text(levelData.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(levelData.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, children: [
                    _statChip(Icons.book, '${levelData.vocabulary.length} mots'),
                    _statChip(Icons.timer, '${levelData.estimatedDuration} min'),
                    _statChip(Icons.bar_chart, _diffLabel()),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              const Text('Choisis un jeu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.0,
                children: [
                  _GameCard(title: 'Memory',   desc: 'Retourne les cartes,\ntrouve les paires !', emoji: '🃏', color: const Color(0xFF1565C0), onTap: () => _launch(context, GameType.memory)),
                  _GameCard(title: 'Quiz',     desc: 'Réponds aux\nquestions !',                   emoji: '❓', color: const Color(0xFF2E7D32), onTap: () => _launch(context, GameType.quiz)),
                  _GameCard(title: 'Bingo',    desc: 'Écoute et clique\nla bonne image !',          emoji: '🎯', color: const Color(0xFF6A1B9A), onTap: () => _launch(context, GameType.bingo)),
                  _GameCard(title: 'Parcours', desc: 'Avance case\npar case !',                     emoji: '🏆', color: const Color(0xFFE65100), onTap: () => _launch(context, GameType.parcours)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.amber[50], borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!)),
                child: Row(children: [
                  const Text('💡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Essaie tous les jeux pour mieux apprendre !',
                      style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.w600, fontSize: 13))),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _diffLabel() {
    switch (levelData.difficulty) {
      case Difficulty.easy:   return 'Facile';
      case Difficulty.medium: return 'Moyen';
      case Difficulty.hard:   return 'Difficile';
    }
  }

  Widget _statChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
    ]),
  );

  void _launch(BuildContext ctx, GameType type) {
    TtsService().speak('C\'est parti !');
    Widget screen;
    switch (type) {
      case GameType.memory:   screen = MemoryGameScreen(levelData: levelData);  break;
      case GameType.quiz:     screen = QuizGameScreen(levelData: levelData);    break;
      case GameType.bingo:    screen = BingoGameScreen(levelData: levelData);   break;
      case GameType.parcours: screen = ParcourGameScreen(levelData: levelData); break;
    }
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
  }
}

class _GameCard extends StatelessWidget {
  final String title, desc, emoji;
  final Color color;
  final VoidCallback onTap;
  const _GameCard({required this.title, required this.desc, required this.emoji,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(18), onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.75)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(emoji, style: const TextStyle(fontSize: 38)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(desc, textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
          ]),
        ),
      ),
    ),
  );
}