// lib/models/island_model.dart
// ═══════════════════════════════════════════════════════════
// 🏝️ MODÈLE DES ÎLES — LinguaKids Maroc
// CORRIGÉ :
//   • IslandVisuals séparé de IslandTheme (qui est dans app_theme.dart)
//   • IDs alignés avec progress_service.dart ('cp','ce1','ce2','cm1','cm2')
//   • StoryScene conservé intégralement
//   • Pas de conflit avec app_theme.dart
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

// ── ENUM THÈME ÎLE ──────────────────────────────────────────
// NOTE : N'importe pas IslandTheme depuis app_theme.dart —
// IslandVisualTheme est le nom ici pour éviter les conflits.
enum IslandVisualTheme {
  sons,      // ID 'cp'
  lettres,   // ID 'ce1'
  syllabes,  // ID 'ce2'
  mots,      // ID 'cm1'
  royaume,   // ID 'cm2'
}

// ── DONNÉES VISUELLES D'UNE ÎLE ─────────────────────────────
class IslandVisual {
  final IslandVisualTheme theme;
  final String islandId;       // Correspond à Island.id dans progress_service
  final String name;
  final String emoji;
  final String mascotMood;
  final Color  primaryColor;
  final Color  secondaryColor;
  final Color  shadowColor;
  final String pedagogicGoal;
  final String skillTrained;
  final double mapX;           // Position sur la carte (ratio 0.0–1.0)
  final double mapY;
  final double mapSize;
  final String islandRestoredEmoji;

  const IslandVisual({
    required this.theme,
    required this.islandId,
    required this.name,
    required this.emoji,
    required this.mascotMood,
    required this.primaryColor,
    required this.secondaryColor,
    required this.shadowColor,
    required this.pedagogicGoal,
    required this.skillTrained,
    required this.mapX,
    required this.mapY,
    this.mapSize = 90,
    required this.islandRestoredEmoji,
  });

  LinearGradient get gradient => LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ── CATALOGUE DES 5 ÎLES ────────────────────────────────────
class IslandVisuals {
  static const List<IslandVisual> all = [

    // ÎLE 1 — Sons
    IslandVisual(
      theme: IslandVisualTheme.sons,
      islandId: 'cp',
      name: 'Île des Sons',
      emoji: '🔊',
      mascotMood: '😄',
      primaryColor:   Color(0xFF5DCAA5),
      secondaryColor: Color(0xFF3DAD8A),
      shadowColor:    Color(0xFF2D8E6C),
      pedagogicGoal: 'Reconnaître les sons du français (phonèmes)',
      skillTrained:  'Écoute active',
      mapX: 0.42, mapY: 0.12,
      mapSize: 100,
      islandRestoredEmoji: '🌿',
    ),

    // ÎLE 2 — Lettres
    IslandVisual(
      theme: IslandVisualTheme.lettres,
      islandId: 'ce1',
      name: 'Île des Lettres',
      emoji: '🔤',
      mascotMood: '🤩',
      primaryColor:   Color(0xFF378ADD),
      secondaryColor: Color(0xFF1565C0),
      shadowColor:    Color(0xFF0D47A1),
      pedagogicGoal: 'Reconnaître et nommer les lettres A-Z',
      skillTrained:  'Mémoire visuelle',
      mapX: 0.08, mapY: 0.34,
      mapSize: 94,
      islandRestoredEmoji: '📘',
    ),

    // ÎLE 3 — Syllabes
    IslandVisual(
      theme: IslandVisualTheme.syllabes,
      islandId: 'ce2',
      name: 'Île des Syllabes',
      emoji: '🎵',
      mascotMood: '😤',
      primaryColor:   Color(0xFFAFA9EC),
      secondaryColor: Color(0xFF8B7FD4),
      shadowColor:    Color(0xFF5240A8),
      pedagogicGoal: 'Assembler des syllabes simples (MA, RI, NA…)',
      skillTrained:  'Conscience phonologique',
      mapX: 0.54, mapY: 0.50,
      mapSize: 90,
      islandRestoredEmoji: '🔶',
    ),

    // ÎLE 4 — Mots
    IslandVisual(
      theme: IslandVisualTheme.mots,
      islandId: 'cm1',
      name: 'Île des Mots',
      emoji: '📖',
      mascotMood: '😎',
      primaryColor:   Color(0xFFFF9B7A),
      secondaryColor: Color(0xFFE07050),
      shadowColor:    Color(0xFFC05030),
      pedagogicGoal: 'Lire des mots de 2-3 syllabes',
      skillTrained:  'Lecture déchiffrée',
      mapX: 0.08, mapY: 0.65,
      mapSize: 88,
      islandRestoredEmoji: '📙',
    ),

    // ÎLE 5 — Royaume
    IslandVisual(
      theme: IslandVisualTheme.royaume,
      islandId: 'cm2',
      name: 'Royaume des Phrases',
      emoji: '👑',
      mascotMood: '🥳',
      primaryColor:   Color(0xFFF4A8BC),
      secondaryColor: Color(0xFFD4537E),
      shadowColor:    Color(0xFFB03060),
      pedagogicGoal: 'Comprendre des phrases simples en français',
      skillTrained:  'Compréhension orale et lecture',
      mapX: 0.42, mapY: 0.80,
      mapSize: 84,
      islandRestoredEmoji: '👑',
    ),
  ];

  /// Récupérer par islandId (ex: 'cp', 'ce1'…)
  static IslandVisual? byIslandId(String islandId) {
    try {
      return all.firstWhere((v) => v.islandId == islandId);
    } catch (_) {
      return null;
    }
  }

  /// Récupérer par thème visuel
  static IslandVisual byTheme(IslandVisualTheme theme) =>
      all.firstWhere((v) => v.theme == theme);
}

// ── EXTENSION GAME TYPE ──────────────────────────────────────
extension GameTypeDisplay on String {
  String get gameEmoji {
    switch (this) {
      case 'memory':             return '🃏';
      case 'quiz':               return '❓';
      case 'bingo':              return '🎯';
      case 'parcours':           return '🏆';
      case 'listening':          return '👂';
      case 'letter_recognition': return '🔤';
      case 'sound_matching':     return '🎵';
      case 'word_builder':       return '🏗️';
      default:                   return '🎮';
    }
  }

  String get gameLabel {
    switch (this) {
      case 'memory':             return 'Memory';
      case 'quiz':               return 'Quiz';
      case 'bingo':              return 'Bingo';
      case 'parcours':           return 'Parcours';
      case 'listening':          return 'Écoute';
      case 'letter_recognition': return 'Reconnaissance';
      case 'sound_matching':     return 'Sons Pareils';
      case 'word_builder':       return 'Construction';
      default:                   return this;
    }
  }

  String get gameSkill {
    switch (this) {
      case 'memory':             return 'Mémoire de travail';
      case 'quiz':               return 'Reconnaissance visuelle';
      case 'bingo':              return 'Écoute active';
      case 'parcours':           return 'Compréhension globale';
      case 'listening':          return 'Écoute active';
      case 'letter_recognition': return 'Mémoire visuelle';
      case 'sound_matching':     return 'Discrimination audio';
      case 'word_builder':       return 'Lecture déchiffrée';
      default:                   return '';
    }
  }
}

// ── SCÈNES DU STORYTELLING ───────────────────────────────────
enum StoryScene {
  titleScreen,      // 0 : Logo + Zaki sur planète étoilée
  worldBeautiful,   // 1 : Le monde heureux, îles colorées
  bouzidArrives,    // 2 : Bouzid arrive (éclairs, yeux jaunes)
  lettersStolen,    // 3 : Les lettres s'envolent (vortex)
  zakiSad,          // 4 : Zaki choqué, larmes douces
  zakiDetermined,   // 5 : Zaki décidé (yeux de feu, poing levé)
  islandRestored,   // 6 : Une île redevient colorée
  letsGo,           // 7 : Appel à l'action → bouton Jouer
}

extension StorySceneX on StoryScene {
  // Durée auto-advance en ms (0 = attend tap utilisateur)
  int get autoAdvanceMs {
    switch (this) {
      case StoryScene.titleScreen:    return 3000;
      case StoryScene.worldBeautiful: return 4000;
      case StoryScene.bouzidArrives:  return 4000;
      case StoryScene.lettersStolen:  return 3500;
      case StoryScene.zakiSad:        return 3000;
      case StoryScene.zakiDetermined: return 3500;
      case StoryScene.islandRestored: return 4000;
      case StoryScene.letsGo:         return 0;
    }
  }

  // Couleurs de fond de la scène
  List<Color> get gradientColors {
    switch (this) {
      case StoryScene.titleScreen:
        return [const Color(0xFF1B0066), const Color(0xFF0A0020)];
      case StoryScene.worldBeautiful:
        return [const Color(0xFF56CCF2), const Color(0xFF4CAF50)];
      case StoryScene.bouzidArrives:
        return [const Color(0xFF3A0000), const Color(0xFF0A0010)];
      case StoryScene.lettersStolen:
        return [const Color(0xFF1A0A2E), const Color(0xFF2D1B4E)];
      case StoryScene.zakiSad:
        return [const Color(0xFF1B3A1B), const Color(0xFF2E5E2E)];
      case StoryScene.zakiDetermined:
        return [const Color(0xFF0D47A1), const Color(0xFF1976D2)];
      case StoryScene.islandRestored:
        return [const Color(0xFF004D40), const Color(0xFF00897B)];
      case StoryScene.letsGo:
        return [const Color(0xFFFF6F00), const Color(0xFFFFA000)];
    }
  }
}