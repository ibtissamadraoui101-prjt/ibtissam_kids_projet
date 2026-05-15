// lib/models/mascot_model.dart
// ═══════════════════════════════════════════════════════════
// 🦁 SYSTÈME MASCOTTE ZAKI — LinguaKids Maroc
// CORRIGÉ : Colors.transparent compatible (non-const), import Flutter
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

// ── EXPRESSIONS DE ZAKI ─────────────────────────────────────
enum ZakiMood {
  // Navigation
  happy, excited, focused, thinking, sleepy,
  // Succès
  celebrating, proud, loving, surprised,
  // Encouragement (jamais sévère)
  encouraging, tryAgain, cheering,
  // Storytelling
  storyHappy, storyShocked, storySad, storyDetermined, storyHero, storyVictory,
  // Onboarding
  waving, inviting,
}

// ── FORME DE BOUCHE ─────────────────────────────────────────
enum MouthShape { bigSmile, smile, smileSmall, neutral, openHappy, surprised }

// ── ANIMATION DE BASE ────────────────────────────────────────
enum MascotAnimation { bounce, float, shake, still, sway, pulse, fistPump, wave }

// ── EXPRESSION COMPLÈTE ──────────────────────────────────────
class ZakiExpression {
  final ZakiMood mood;
  final Color faceColor;
  final Color maneColor;
  final Color cheekColor;
  final Color eyeColor;
  final double eyeOpenness;
  final bool hasEyeShine;
  final bool hasFireEyes;
  final double eyebrowAngle;
  final MouthShape mouth;
  final bool hasTeeth;
  final bool hasTears;
  final bool hasCrown;
  final bool hasCape;
  final bool hasStar;
  final bool hasSweat;
  final MascotAnimation animation;
  final String? bubbleEmoji;

  const ZakiExpression({
    required this.mood,
    this.faceColor    = const Color(0xFFFFE082),
    this.maneColor    = const Color(0xFFE65100),
    this.cheekColor   = const Color(0x4DFF6464),
    this.eyeColor     = const Color(0xFF1A1A1A),
    this.eyeOpenness  = 1.0,
    this.hasEyeShine  = true,
    this.hasFireEyes  = false,
    this.eyebrowAngle = 0.0,
    this.mouth        = MouthShape.smile,
    this.hasTeeth     = false,
    this.hasTears     = false,
    this.hasCrown     = false,
    this.hasCape      = false,
    this.hasStar      = false,
    this.hasSweat     = false,
    this.animation    = MascotAnimation.bounce,
    this.bubbleEmoji,
  });
}

// ── CATALOGUE COMPLET ────────────────────────────────────────
class ZakiExpressions {
  // CORRIGÉ : Color(0x00FFFFFF) au lieu de Colors.transparent (non-const)
  static const _transparent = Color(0x00FFFFFF);

  static const Map<ZakiMood, ZakiExpression> _catalog = {

    ZakiMood.happy: ZakiExpression(
      mood: ZakiMood.happy,
      mouth: MouthShape.smile,
      animation: MascotAnimation.bounce,
      bubbleEmoji: '🎉',
    ),

    ZakiMood.excited: ZakiExpression(
      mood: ZakiMood.excited,
      mouth: MouthShape.bigSmile,
      hasTeeth: true,
      eyeOpenness: 1.2,
      animation: MascotAnimation.shake,
      bubbleEmoji: '🌟',
    ),

    ZakiMood.focused: ZakiExpression(
      mood: ZakiMood.focused,
      mouth: MouthShape.neutral,
      eyeOpenness: 0.7,
      eyebrowAngle: 15.0,
      // CORRIGÉ : Color(0x00FFFFFF) au lieu de Colors.transparent (non-const)
      cheekColor: _transparent,
      hasEyeShine: false,
      animation: MascotAnimation.still,
    ),

    ZakiMood.thinking: ZakiExpression(
      mood: ZakiMood.thinking,
      mouth: MouthShape.smileSmall,
      eyeOpenness: 0.8,
      animation: MascotAnimation.sway,
      bubbleEmoji: '🤔',
    ),

    ZakiMood.sleepy: ZakiExpression(
      mood: ZakiMood.sleepy,
      mouth: MouthShape.neutral,
      eyeOpenness: 0.2,
      animation: MascotAnimation.float,
      bubbleEmoji: '💤',
    ),

    ZakiMood.celebrating: ZakiExpression(
      mood: ZakiMood.celebrating,
      mouth: MouthShape.bigSmile,
      hasTeeth: true,
      hasCrown: true,
      hasStar: true,
      eyeOpenness: 1.3,
      animation: MascotAnimation.fistPump,
      bubbleEmoji: '🎊',
    ),

    ZakiMood.proud: ZakiExpression(
      mood: ZakiMood.proud,
      mouth: MouthShape.bigSmile,
      hasStar: true,
      animation: MascotAnimation.pulse,
      bubbleEmoji: '⭐',
    ),

    ZakiMood.loving: ZakiExpression(
      mood: ZakiMood.loving,
      mouth: MouthShape.bigSmile,
      cheekColor: Color(0x80FF6B6B),
      animation: MascotAnimation.bounce,
      bubbleEmoji: '❤️',
    ),

    ZakiMood.surprised: ZakiExpression(
      mood: ZakiMood.surprised,
      mouth: MouthShape.surprised,
      eyeOpenness: 1.5,
      hasSweat: true,
      animation: MascotAnimation.still,
      bubbleEmoji: '✨',
    ),

    ZakiMood.encouraging: ZakiExpression(
      mood: ZakiMood.encouraging,
      mouth: MouthShape.smile,
      eyeOpenness: 0.9,
      animation: MascotAnimation.sway,
      bubbleEmoji: '💪',
    ),

    ZakiMood.tryAgain: ZakiExpression(
      mood: ZakiMood.tryAgain,
      mouth: MouthShape.smileSmall,
      eyeOpenness: 0.85,
      animation: MascotAnimation.sway,
      bubbleEmoji: '🙏',
    ),

    ZakiMood.cheering: ZakiExpression(
      mood: ZakiMood.cheering,
      mouth: MouthShape.openHappy,
      hasTeeth: true,
      animation: MascotAnimation.wave,
      bubbleEmoji: '👏',
    ),

    // ── Story ──────────────────────────────────────────────
    ZakiMood.storyHappy: ZakiExpression(
      mood: ZakiMood.storyHappy,
      mouth: MouthShape.bigSmile,
      hasTeeth: true,
      cheekColor: Color(0x60FF6B6B),
      animation: MascotAnimation.bounce,
    ),

    ZakiMood.storyShocked: ZakiExpression(
      mood: ZakiMood.storyShocked,
      mouth: MouthShape.surprised,
      eyeOpenness: 1.6,
      hasSweat: true,
      animation: MascotAnimation.still,
    ),

    ZakiMood.storySad: ZakiExpression(
      mood: ZakiMood.storySad,
      mouth: MouthShape.neutral,
      eyeOpenness: 0.9,
      hasTears: true,
      eyebrowAngle: -10.0,
      animation: MascotAnimation.sway,
    ),

    ZakiMood.storyDetermined: ZakiExpression(
      mood: ZakiMood.storyDetermined,
      mouth: MouthShape.smile,
      eyeOpenness: 0.7,
      hasFireEyes: true,
      eyebrowAngle: 20.0,
      hasStar: true,
      animation: MascotAnimation.pulse,
      bubbleEmoji: '🔥',
    ),

    ZakiMood.storyHero: ZakiExpression(
      mood: ZakiMood.storyHero,
      mouth: MouthShape.bigSmile,
      hasTeeth: true,
      hasCape: true,
      hasStar: true,
      animation: MascotAnimation.fistPump,
      bubbleEmoji: '💪',
    ),

    ZakiMood.storyVictory: ZakiExpression(
      mood: ZakiMood.storyVictory,
      mouth: MouthShape.bigSmile,
      hasTeeth: true,
      hasCrown: true,
      hasCape: true,
      hasStar: true,
      eyeOpenness: 1.4,
      animation: MascotAnimation.fistPump,
      bubbleEmoji: '👑',
    ),

    ZakiMood.waving: ZakiExpression(
      mood: ZakiMood.waving,
      mouth: MouthShape.bigSmile,
      hasTeeth: true,
      cheekColor: Color(0x70FF6B6B),
      animation: MascotAnimation.wave,
      bubbleEmoji: '👋',
    ),

    ZakiMood.inviting: ZakiExpression(
      mood: ZakiMood.inviting,
      mouth: MouthShape.smile,
      animation: MascotAnimation.bounce,
      bubbleEmoji: '👉',
    ),
  };

  static ZakiExpression get(ZakiMood mood) =>
      _catalog[mood] ?? _catalog[ZakiMood.happy]!;

  static ZakiMood moodForStars(int stars) {
    if (stars == 3) return ZakiMood.celebrating;
    if (stars == 2) return ZakiMood.proud;
    return ZakiMood.encouraging;
  }

  static ZakiMood moodForAnswer({required bool correct, int errorCount = 0}) {
    if (correct) return ZakiMood.proud;
    if (errorCount >= 2) return ZakiMood.tryAgain;
    return ZakiMood.encouraging;
  }

  static ZakiMood moodForScore(double pct) {
    if (pct >= 80) return ZakiMood.celebrating;
    if (pct >= 60) return ZakiMood.proud;
    if (pct >= 40) return ZakiMood.encouraging;
    return ZakiMood.tryAgain;
  }
}