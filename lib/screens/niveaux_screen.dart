// lib/screens/niveaux_screen.dart
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../data/cp_levels_data.dart';
import '../data/ce1_ce2_cm1_cm2_levels_data.dart';
import '../services/tts_service.dart';
import 'game_selection_screen.dart';

class NiveauxScreen extends StatelessWidget {
  const NiveauxScreen({super.key});

  static const _levels = [
    {'niveau': 'CP',  'color': Color(0xFF1565C0), 'emoji': '🌱', 'desc': 'Débute ton apprentissage !', 'sub': '6 semaines'},
    {'niveau': 'CE1', 'color': Color(0xFF2E7D32), 'emoji': '🌿', 'desc': 'Progressons ensemble !',      'sub': '3 trimestres'},
    {'niveau': 'CE2', 'color': Color(0xFFE65100), 'emoji': '🌳', 'desc': 'Phrases et formules !',        'sub': '3 trimestres'},
    {'niveau': 'CM1', 'color': Color(0xFF6A1B9A), 'emoji': '🦋', 'desc': 'Descriptions et histoires !', 'sub': '3 trimestres'},
    {'niveau': 'CM2', 'color': Color(0xFFC62828), 'emoji': '🚀', 'desc': 'Textes et préparation !',     'sub': '3 trimestres'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisis ton niveau', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F8E9), Color(0xFFE3F2FD)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _levels.length,
          itemBuilder: (ctx, i) {
            final l = _levels[i];
            return _LevelCard(
              niveau: l['niveau'] as String,
              color:  l['color'] as Color,
              emoji:  l['emoji'] as String,
              desc:   l['desc'] as String,
              sub:    l['sub'] as String,
              onTap: () {
                TtsService().speak(l['niveau'] as String);
                Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => SubLevelsScreen(niveau: l['niveau'] as String),
                ));
              },
            );
          },
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String niveau, emoji, desc, sub;
  final Color color;
  final VoidCallback onTap;
  const _LevelCard({required this.niveau, required this.color, required this.emoji,
      required this.desc, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 62, height: 62,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 30))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(niveau, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text(desc, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                          child: Text(sub, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class SubLevelsScreen extends StatelessWidget {
  final String niveau;
  const SubLevelsScreen({super.key, required this.niveau});

  List<GameLevelData> _levels() {
    switch (niveau) {
      case 'CP':  return CPLevelsProvider.getAllCPLevels();
      case 'CE1': return CE1LevelsProvider.getAllCE1Levels();
      case 'CE2': return CE2LevelsProvider.getAllCE2Levels();
      case 'CM1': return CM1LevelsProvider.getAllCM1Levels();
      case 'CM2': return CM2LevelsProvider.getAllCM2Levels();
      default:    return [];
    }
  }

  Color _color() {
    switch (niveau) {
      case 'CP':  return const Color(0xFF1565C0);
      case 'CE1': return const Color(0xFF2E7D32);
      case 'CE2': return const Color(0xFFE65100);
      case 'CM1': return const Color(0xFF6A1B9A);
      case 'CM2': return const Color(0xFFC62828);
      default:    return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = _levels();
    final color  = _color();
    return Scaffold(
      appBar: AppBar(
        title: Text('$niveau — Choisir un thème', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color, foregroundColor: Colors.white, elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.07), Colors.white],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: levels.length,
          itemBuilder: (ctx, i) {
            final lv = levels[i];
            return _SubCard(
              level: lv, color: color,
              onTap: () {
                TtsService().speak(lv.title);
                Navigator.push(ctx, MaterialPageRoute(builder: (_) => GameSelectionScreen(levelData: lv)));
              },
            );
          },
        ),
      ),
    );
  }
}

class _SubCard extends StatelessWidget {
  final GameLevelData level;
  final Color color;
  final VoidCallback onTap;
  const _SubCard({required this.level, required this.color, required this.onTap});

  String _diff() {
    switch (level.difficulty) {
      case Difficulty.easy:   return '⭐ Facile';
      case Difficulty.medium: return '⭐⭐ Moyen';
      case Difficulty.hard:   return '⭐⭐⭐ Difficile';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        shadowColor: color.withOpacity(0.18),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text('${level.progression}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(level.getProgression(),
                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(level.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text(level.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, children: [
                        _chip('📖 ${level.vocabulary.length} mots', color),
                        _chip('⏱ ${level.estimatedDuration} min', color),
                        _chip(_diff(), color),
                      ]),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );
}