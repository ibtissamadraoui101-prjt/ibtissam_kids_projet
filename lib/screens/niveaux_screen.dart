// lib/screens/niveaux_screen.dart
// Ce fichier redirige vers IslandLevelsScreen.
// NiveauxScreen et SubLevelsScreen sont conservés pour
// la compatibilité avec les imports existants.

import 'package:flutter/material.dart';
import 'island_levels_screen.dart';

// Écran principal des niveaux — redirige vers la carte d'île
class NiveauxScreen extends StatelessWidget {
  const NiveauxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Par défaut affiche CP — mais normalement on passe
    // par WorldMapScreen qui lance IslandLevelsScreen directement
    return const IslandLevelsScreen(niveauLabel: 'CP');
  }
}

// SubLevelsScreen est appelé depuis world_map_screen.dart
// Il redirige vers la nouvelle carte d'îles du niveau concerné
class SubLevelsScreen extends StatelessWidget {
  final String niveau; // 'CP', 'CE1', 'CE2', 'CM1', 'CM2'
  const SubLevelsScreen({super.key, required this.niveau});

  @override
  Widget build(BuildContext context) {
    return IslandLevelsScreen(niveauLabel: niveau);
  }
}