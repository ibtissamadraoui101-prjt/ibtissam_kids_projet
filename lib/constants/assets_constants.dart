// lib/constants/assets_constants.dart
// ═══════════════════════════════════════════════════════════
// 🎨 CONSTANTES DES ASSETS — Images, Boutons, Backgrounds
// ═══════════════════════════════════════════════════════════

class AssetsPaths {
  // ── MASCOTES (Monster Builder Pack) ─────────────────────
  static const String _mascotBase =
      'assets/images/mascots/kenney_monster-builder-pack/PNG/Default';

  static const String mascotBody1 = '$_mascotBase/body_redA.png';
  static const String mascotBody2 = '$_mascotBase/body_darkB.png';
  static const String mascotArm1 = '$_mascotBase/arm_greenB.png';
  static const String mascotArm2 = '$_mascotBase/arm_blueE.png';
  static const String mascotEye1 = '$_mascotBase/eye_angry_blue.png';

  // ── BOUTONS (UI Pack) ───────────────────────────────────
  static const String _buttonBase =
      'assets/images/buttons/kenney_ui-pack/PNG/Green/Default';

  static const String buttonRoundGloss = '$_buttonBase/button_round_gloss.png';
  static const String buttonRectangleGradient =
      '$_buttonBase/button_rectangle_gradient.png';
  static const String buttonSquareGradient =
      '$_buttonBase/button_square_gradient.png';
  static const String buttonRoundFlat = '$_buttonBase/button_round_flat.png';

  // ── BACKGROUNDS (Platformer Tileset) ────────────────────
  static const String _backgroundBase =
      'assets/images/backgrounds/kenney_platformer-art-extended-tileset/PNG Grass';

  static const String bgGrass1 = '$_backgroundBase/grassHalfRight.png';
  static const String bgGrass2 = '$_backgroundBase/grassHalfLeft.png';

  // ── PREVIEW ─────────────────────────────────────────────
  static const String mascotPreview =
      'assets/images/mascots/kenney_monster-builder-pack/Preview.png';
  static const String buttonPreview =
      'assets/images/buttons/kenney_ui-pack/Preview.png';
  static const String bgPreview =
      'assets/images/backgrounds/kenney_platformer-art-extended-tileset/preview.png';
}
