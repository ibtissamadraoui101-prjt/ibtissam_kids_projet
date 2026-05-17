// lib/data/letter_games_data.dart
// ════════════════════════════════════════════════════════════
// Données centralisées des lettres CP pour les 4 jeux
// Voir + Écouter, Reconnaissance, Mémoire, Écriture
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

// ── Données d'une lettre ─────────────────────────────────────
class LetterData {
  final String letter;
  final String lowercase;
  final String word;
  final String wordArabic;
  final String imageAsset;
  final String wordAsset;
  final Color color;
  final Color dark;
  const LetterData({
    required this.letter,
    required this.lowercase,
    required this.word,
    required this.wordArabic,
    required this.imageAsset,
    required this.wordAsset,
    required this.color,
    required this.dark,
  });
}

// ── Base de données 26 lettres ────────────────────────────────
const Map<String, LetterData> kLetterDB = {
  'A': LetterData(
      letter: 'A',
      lowercase: 'a',
      word: 'Avion',
      wordArabic: 'طيارة',
      imageAsset: 'assets/images/cp/alphabet_a.png',
      wordAsset: 'assets/images/cp/animal_chicken.png',
      color: Color(0xFFFFD93D),
      dark: Color(0xFFFFA000)),
  'B': LetterData(
      letter: 'B',
      lowercase: 'b',
      word: 'Ballon',
      wordArabic: 'بالون',
      imageAsset: 'assets/images/cp/alphabet_b.png',
      wordAsset: 'assets/images/cp/animal_horse.png',
      color: Color(0xFFFF8C9E),
      dark: Color(0xFFD4537E)),
  'C': LetterData(
      letter: 'C',
      lowercase: 'c',
      word: 'Chat',
      wordArabic: 'قطة',
      imageAsset: 'assets/images/cp/alphabet_c.png',
      wordAsset: 'assets/images/cp/animal_cat.png',
      color: Color(0xFF85DAFF),
      dark: Color(0xFF378ADD)),
  'D': LetterData(
      letter: 'D',
      lowercase: 'd',
      word: 'Dindon',
      wordArabic: 'ديك',
      imageAsset: 'assets/images/cp/alphabet_d.png',
      wordAsset: 'assets/images/cp/animal_duck.png',
      color: Color(0xFFA8E6CF),
      dark: Color(0xFF3DAD8A)),
  'E': LetterData(
      letter: 'E',
      lowercase: 'e',
      word: 'Éléphant',
      wordArabic: 'فيل',
      imageAsset: 'assets/images/cp/alphabet_e.png',
      wordAsset: 'assets/images/cp/animal_donkey.png',
      color: Color(0xFFCECBF6),
      dark: Color(0xFF8B7FD4)),
  'F': LetterData(
      letter: 'F',
      lowercase: 'f',
      word: 'Ferme',
      wordArabic: 'ضيعة',
      imageAsset: 'assets/images/cp/alphabet_f.png',
      wordAsset: 'assets/images/cp/farm.png',
      color: Color(0xFFFF9B7A),
      dark: Color(0xFFE07050)),
  'G': LetterData(
      letter: 'G',
      lowercase: 'g',
      word: 'Grenouille',
      wordArabic: 'ضفدع',
      imageAsset: 'assets/images/cp/alphabet_g.png',
      wordAsset: 'assets/images/cp/animal_pig.png',
      color: Color(0xFF5DCAA5),
      dark: Color(0xFF3DAD8A)),
  'H': LetterData(
      letter: 'H',
      lowercase: 'h',
      word: 'Hibou',
      wordArabic: 'بومة',
      imageAsset: 'assets/images/cp/alphabet_h.png',
      wordAsset: 'assets/images/cp/animal_chicken.png',
      color: Color(0xFFFFD93D),
      dark: Color(0xFFFFA000)),
  'I': LetterData(
      letter: 'I',
      lowercase: 'i',
      word: 'Igloo',
      wordArabic: 'إيغلو',
      imageAsset: 'assets/images/cp/alphabet_i.png',
      wordAsset: 'assets/images/cp/animal_sheep.png',
      color: Color(0xFF85DAFF),
      dark: Color(0xFF378ADD)),
  'J': LetterData(
      letter: 'J',
      lowercase: 'j',
      word: 'Jardin',
      wordArabic: 'حديقة',
      imageAsset: 'assets/images/cp/alphabet_j.png',
      wordAsset: 'assets/images/cp/animal_rabbit.png',
      color: Color(0xFFFF8C9E),
      dark: Color(0xFFD4537E)),
  'K': LetterData(
      letter: 'K',
      lowercase: 'k',
      word: 'Koala',
      wordArabic: 'كوالا',
      imageAsset: 'assets/images/cp/alphabet_k.png',
      wordAsset: 'assets/images/cp/animal_rabbit.png',
      color: Color(0xFFA8E6CF),
      dark: Color(0xFF3DAD8A)),
  'L': LetterData(
      letter: 'L',
      lowercase: 'l',
      word: 'Lion',
      wordArabic: 'أسد',
      imageAsset: 'assets/images/cp/alphabet_l.png',
      wordAsset: 'assets/images/cp/animal_dog.png',
      color: Color(0xFFFFD93D),
      dark: Color(0xFFFFA000)),
};

// ── Groupes 3 lettres / jour ──────────────────────────────────
const List<List<String>> kDailyGroups = [
  ['A', 'B', 'C'],
  ['D', 'E', 'F'],
  ['G', 'H', 'I'],
  ['J', 'K', 'L'],
];

List<String> getTodayLetters(int day) =>
    kDailyGroups[day % kDailyGroups.length];

// ── Toutes les lettres pour distracteurs ───────────────────────
const List<String> kAllLetters = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L'
];
