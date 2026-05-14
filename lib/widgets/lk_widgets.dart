// lib/widgets/lk_widgets.dart
// ═══════════════════════════════════════════════════════════
// Composants UI réutilisables LinguaKids
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ── Étoiles ──────────────────────────────────────────────────
class LKStars extends StatelessWidget {
  final int earned;
  final int max;
  final double size;

  const LKStars({
    super.key,
    required this.earned,
    this.max = 3,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Icon(
          Icons.star_rounded,
          size: size,
          color: i < earned ? LKColors.star : LKColors.starEmpty,
        ),
      )),
    );
  }
}

// ── Pill HUD ─────────────────────────────────────────────────
class LKPill extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const LKPill({
    super.key,
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });

  factory LKPill.xp(int xp) => LKPill(
    icon: const Icon(Icons.star_rounded, color: Color(0xFF7A5200), size: 16),
    label: '$xp XP',
    bgColor: LKColors.sun,
    textColor: LKColors.textOnYellow,
    borderColor: LKColors.sunDark,
  );

  factory LKPill.streak(int days) => LKPill(
    icon: const Icon(Icons.local_fire_department_rounded,
        color: Color(0xFF5A1800), size: 16),
    label: '$days jour${days > 1 ? 's' : ''}',
    bgColor: const Color(0xFFFF8C6B),
    textColor: const Color(0xFF5A1800),
    borderColor: const Color(0xFFFF6040),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 5),
          Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barre de progression ──────────────────────────────────────
class LKProgressBar extends StatelessWidget {
  final double progress; // 0.0 → 1.0
  final Color fillColor;
  final Color bgColor;
  final double height;
  final double radius;

  const LKProgressBar({
    super.key,
    required this.progress,
    this.fillColor = LKColors.correct,
    this.bgColor = LKColors.neutralDark,
    this.height = 8,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        color: bgColor,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(color: fillColor),
        ),
      ),
    );
  }
}

// ── Bouton principal joyeux ───────────────────────────────────
class LKButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;
  final double fontSize;

  const LKButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = LKColors.sun,
    this.borderColor = LKColors.sunDark,
    this.textColor = LKColors.textOnYellow,
    this.icon,
    this.fontSize = 15,
  });

  factory LKButton.primary(String label, {VoidCallback? onPressed, IconData? icon}) =>
    LKButton(label: label, onPressed: onPressed, icon: icon);

  factory LKButton.green(String label, {VoidCallback? onPressed, IconData? icon}) =>
    LKButton(
      label: label, onPressed: onPressed, icon: icon,
      color: LKColors.correct,
      borderColor: LKColors.island1Dark,
      textColor: LKColors.textOnGreen,
    );

  factory LKButton.outline(String label, {VoidCallback? onPressed}) =>
    LKButton(
      label: label, onPressed: onPressed,
      color: Colors.white,
      borderColor: LKColors.sun,
      textColor: LKColors.textOnYellow,
    );

  @override
  State<LKButton> createState() => _LKButtonState();
}

class _LKButtonState extends State<LKButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.mediumImpact();
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed != null ? _onTap : null,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: widget.onPressed != null
              ? widget.color
              : widget.color.withOpacity(0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.borderColor, width: 3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w900,
                  color: widget.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Carte de jeu dans la liste de l'île ──────────────────────
class LKGameCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String badge;
  final Color cardColor;
  final Color borderColor;
  final Color badgeColor;
  final Color badgeTextColor;
  final bool locked;
  final VoidCallback? onTap;
  final int stars;

  const LKGameCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.cardColor = LKColors.bgCream,
    this.borderColor = LKColors.neutralDark,
    this.badgeColor = LKColors.neutralDark,
    this.badgeTextColor = LKColors.textMedium,
    this.locked = false,
    this.onTap,
    this.stars = 0,
  });

  factory LKGameCard.done({
    required String emoji, required String title,
    required String subtitle, int stars = 3, VoidCallback? onTap,
  }) => LKGameCard(
    emoji: emoji, title: title, subtitle: subtitle,
    badge: 'Terminé !', cardColor: LKColors.correctLight,
    borderColor: LKColors.correct,
    badgeColor: LKColors.correct, badgeTextColor: LKColors.textOnGreen,
    stars: stars, onTap: onTap,
  );

  factory LKGameCard.current({
    required String emoji, required String title,
    required String subtitle, VoidCallback? onTap,
  }) => LKGameCard(
    emoji: emoji, title: title, subtitle: subtitle,
    badge: '▶ Jouer !', cardColor: LKColors.bgYellowLight,
    borderColor: LKColors.sun,
    badgeColor: LKColors.sun, badgeTextColor: LKColors.textOnYellow,
    onTap: onTap,
  );

  factory LKGameCard.locked({
    required String emoji, required String title, required String subtitle,
  }) => LKGameCard(
    emoji: emoji, title: title, subtitle: subtitle,
    badge: '🔒',
    cardColor: LKColors.neutral.withOpacity(0.7),
    borderColor: LKColors.neutralDark.withOpacity(0.5),
    badgeColor: LKColors.neutralDark,
    badgeTextColor: LKColors.textLight,
    locked: true,
  );

  @override
  State<LKGameCard> createState() => _LKGameCardState();
}

class _LKGameCardState extends State<LKGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onTap() {
    if (widget.locked || widget.onTap == null) return;
    HapticFeedback.lightImpact();
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Opacity(
          opacity: widget.locked ? 0.55 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.borderColor, width: 2.5),
            ),
            child: Row(
              children: [
                // Emoji icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.borderColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.borderColor.withOpacity(0.5), width: 1.5),
                  ),
                  child: Center(
                    child: Text(widget.emoji,
                      style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: LKColors.textDark,
                        )),
                      const SizedBox(height: 2),
                      Text(widget.subtitle,
                        style: const TextStyle(
                          fontSize: 11, color: LKColors.textMedium)),
                      const SizedBox(height: 6),
                      if (widget.stars > 0)
                        LKStars(earned: widget.stars, size: 16)
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.badgeColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(widget.badge,
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800,
                              color: widget.badgeTextColor,
                            )),
                        ),
                    ],
                  ),
                ),
                if (widget.locked)
                  const Icon(Icons.lock_rounded,
                      color: LKColors.textLight, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Décoration arc-en-ciel ─────────────────────────────────────
class RainbowStrip extends StatelessWidget {
  final double height;
  const RainbowStrip({super.key, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: LKColors.rainbow),
      ),
    );
  }
}

// ── Confetti décoratif ────────────────────────────────────────
class ConfettiDots extends StatelessWidget {
  const ConfettiDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ConfettiPainter(),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  static const _dots = [
    (0.08, 0.05, Color(0xFFFF6B6B), 7.0),
    (0.25, 0.08, Color(0xFF5DCAA5), 5.0),
    (0.65, 0.04, Color(0xFF4DC8E8), 7.0),
    (0.80, 0.09, Color(0xFFFFD93D), 5.0),
    (0.42, 0.06, Color(0xFFC3A6FF), 6.0),
    (0.90, 0.12, Color(0xFFFF8C6B), 5.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _dots) {
      canvas.drawCircle(
        Offset(size.width * d.$1, size.height * d.$2),
        d.$4,
        Paint()..color = d.$3,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}