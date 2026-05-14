// lib/theme/app_theme.dart
// ═══════════════════════════════════════════════════════════
// LinguaKids — Design System complet
// Couleurs pastels joyeuses pour enfants 6-7 ans
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette principale ──────────────────────────────────────
class LKColors {
  LKColors._();

  // Ciel et mer
  static const skyBlue       = Color(0xFF87CEEB);
  static const skyBlueDark   = Color(0xFF5BB8D4);
  static const seaBlue       = Color(0xFF4DC8E8);
  static const seaDeep       = Color(0xFF2AABCC);

  // Îles — chaque île a sa couleur
  static const island1Green  = Color(0xFF5DCAA5); // Sons
  static const island1Dark   = Color(0xFF3DAD8A);
  static const island2Blue   = Color(0xFF85B7EB); // Lettres
  static const island2Dark   = Color(0xFF378ADD);
  static const island3Purple = Color(0xFFB0A4EC); // Syllabes
  static const island3Dark   = Color(0xFF8B7FD4);
  static const island4Coral  = Color(0xFFFF9B7A); // Mots
  static const island4Dark   = Color(0xFFE07050);
  static const island5Pink   = Color(0xFFF4A8BC); // Royaume
  static const island5Dark   = Color(0xFFD4537E);

  // Soleil et récompenses
  static const sun           = Color(0xFFFFD93D);
  static const sunDark       = Color(0xFFFFA500);
  static const sunDeep       = Color(0xFFFF8C00);

  // Lumi la luciole
  static const lumiYellow    = Color(0xFFFFD93D);
  static const lumiOrange    = Color(0xFFFFA500);
  static const lumiWing      = Color(0xFFB4EEFF);

  // Feedback
  static const correct       = Color(0xFF5DCAA5);
  static const correctLight  = Color(0xFFE1F5EE);
  static const wrong         = Color(0xFFFF6B6B);
  static const wrongLight    = Color(0xFFFFEEEE);
  static const neutral       = Color(0xFFE8E5DC);
  static const neutralDark   = Color(0xFFD3D0C7);

  // Texte
  static const textDark      = Color(0xFF2C2C2A);
  static const textMedium    = Color(0xFF6B6B68);
  static const textLight     = Color(0xFF9B9B98);
  static const textOnYellow  = Color(0xFF7A5200);
  static const textOnGreen   = Color(0xFF085041);
  static const textOnBlue    = Color(0xFF0C447C);

  // Fond global
  static const bgCream       = Color(0xFFFFFDF5);
  static const bgYellowLight = Color(0xFFFFF9CC);
  static const bgBlueLight   = Color(0xFFE8F8FF);
  static const bgGreenLight  = Color(0xFFE1F5EE);

  // Arc-en-ciel pour les décorations
  static const rainbow = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF5DCAA5),
    Color(0xFF4DC8E8),
    Color(0xFFC3A6FF),
    Color(0xFFFF8C6B),
  ];

  // Étoile
  static const star          = Color(0xFFFFD93D);
  static const starEmpty     = Color(0xFFD3D1C7);
  static const starBorder    = Color(0xFFFFA500);
}

// ── Typographie ──────────────────────────────────────────────
class LKTextStyles {
  LKTextStyles._();

  static TextStyle hero(BuildContext ctx) => GoogleFonts.nunito(
    fontSize: 28, fontWeight: FontWeight.w900,
    color: LKColors.textDark, height: 1.2,
  );

  static TextStyle title(BuildContext ctx) => GoogleFonts.nunito(
    fontSize: 20, fontWeight: FontWeight.w800, color: LKColors.textDark,
  );

  static TextStyle cardTitle(BuildContext ctx) => GoogleFonts.nunito(
    fontSize: 14, fontWeight: FontWeight.w700, color: LKColors.textDark,
  );

  static TextStyle body(BuildContext ctx) => GoogleFonts.nunito(
    fontSize: 13, fontWeight: FontWeight.w500, color: LKColors.textMedium,
  );

  static TextStyle caption(BuildContext ctx) => GoogleFonts.nunito(
    fontSize: 11, fontWeight: FontWeight.w600, color: LKColors.textLight,
  );

  static TextStyle pill(BuildContext ctx) => GoogleFonts.nunito(
    fontSize: 12, fontWeight: FontWeight.w800,
  );

  static TextStyle gameTitle(BuildContext ctx) => GoogleFonts.nunito(
    fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white,
    shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))],
  );

  static TextStyle syllable(BuildContext ctx) => GoogleFonts.nunito(
    fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white,
    letterSpacing: 1.2,
  );

  static TextStyle wordDisplay(BuildContext ctx) => GoogleFonts.nunito(
    fontSize: 32, fontWeight: FontWeight.w900, color: LKColors.textOnYellow,
    letterSpacing: 1.5,
  );
}

// ── Décorations réutilisables ─────────────────────────────────
class LKDecorations {
  LKDecorations._();

  static BoxDecoration card({
    Color? color,
    Color? borderColor,
    double radius = 20,
    double borderWidth = 2.5,
  }) => BoxDecoration(
    color: color ?? LKColors.bgCream,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: borderColor ?? LKColors.neutralDark,
      width: borderWidth,
    ),
  );

  static BoxDecoration pill({Color? color, Color? borderColor}) =>
    BoxDecoration(
      color: color ?? LKColors.sun,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: borderColor ?? LKColors.sunDark, width: 2,
      ),
    );

  static BoxDecoration gameButton({required Color color, required Color borderColor}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor, width: 3),
    );

  static BoxDecoration rainbowTop({double radius = 0}) => BoxDecoration(
    gradient: const LinearGradient(colors: LKColors.rainbow),
    borderRadius: radius > 0
      ? BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        )
      : BorderRadius.zero,
  );

  static BoxDecoration islandCard(Color color, Color border) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: border, width: 3),
  );

  static BoxDecoration skyGradient() => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF87CEEB), Color(0xFF4DC8E8)],
    ),
  );
}

// ── Thème Material global ─────────────────────────────────────
class AppTheme {
  static ThemeData get light {
    final base = GoogleFonts.nunitoTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: LKColors.skyBlue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: LKColors.bgCream,
      textTheme: base.copyWith(
        bodyLarge:   GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium:  GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w500),
        titleLarge:  GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900),
        titleMedium: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
        labelLarge:  GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}

// ── Island config data ────────────────────────────────────────
class IslandTheme {
  final String id;
  final String emoji;
  final String name;
  final String subtitle;
  final Color primary;
  final Color dark;
  final Color light;
  final Color textColor;
  final List<String> decorEmojis;

  const IslandTheme({
    required this.id,
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.primary,
    required this.dark,
    required this.light,
    required this.textColor,
    required this.decorEmojis,
  });

  static const List<IslandTheme> all = [
    IslandTheme(
      id: 'cp', emoji: '🔊', name: 'Île des Sons',
      subtitle: 'Écoute et reconnais les sons',
      primary: LKColors.island1Green, dark: LKColors.island1Dark,
      light: Color(0xFFE1F5EE), textColor: LKColors.textOnGreen,
      decorEmojis: ['🌺', '🌸', '🦋', '🌻', '🐢'],
    ),
    IslandTheme(
      id: 'ce1', emoji: '🔤', name: 'Île des Lettres',
      subtitle: 'Reconnais les lettres',
      primary: LKColors.island2Blue, dark: LKColors.island2Dark,
      light: Color(0xFFE6F1FB), textColor: LKColors.textOnBlue,
      decorEmojis: ['🐠', '🐬', '🌊', '⭐', '🐙'],
    ),
    IslandTheme(
      id: 'ce2', emoji: '🎵', name: 'Île des Syllabes',
      subtitle: 'Combine les sons',
      primary: LKColors.island3Purple, dark: LKColors.island3Dark,
      light: Color(0xFFEEEDFE), textColor: Color(0xFF3C3489),
      decorEmojis: ['🦜', '🌺', '🎶', '🦚', '🌴'],
    ),
    IslandTheme(
      id: 'cm1', emoji: '📖', name: 'Île des Mots',
      subtitle: 'Lis des mots simples',
      primary: LKColors.island4Coral, dark: LKColors.island4Dark,
      light: Color(0xFFFAECE7), textColor: Color(0xFF7A3010),
      decorEmojis: ['🦁', '🌵', '🦒', '☀️', '🏜️'],
    ),
    IslandTheme(
      id: 'cm2', emoji: '👑', name: 'Royaume des Phrases',
      subtitle: 'Comprends des phrases',
      primary: LKColors.island5Pink, dark: LKColors.island5Dark,
      light: Color(0xFFFBEAF0), textColor: Color(0xFF72243E),
      decorEmojis: ['🌹', '🦄', '🏰', '✨', '🎠'],
    ),
  ];
}