// lib/widgets/sound_button.dart
// 🔊 BOUTON AVEC SON INTÉGRÉ
// Remplace tous les GestureDetector/ElevatedButton de l'app
// Joue automatiquement le son de clic + vibration légère

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';

// ─────────────────────────────────────────────────────────────
// SoundButton — bouton 3D qui descend au clic + son
// ─────────────────────────────────────────────────────────────
class SoundButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color faceColor;
  final Color shadowColor;
  final double borderRadius;
  final EdgeInsets padding;
  final SoundEffect sound;
  final bool haptic;

  const SoundButton({
    super.key,
    required this.child,
    this.onTap,
    this.faceColor       = const Color(0xFF1565C0),
    this.shadowColor     = const Color(0xFF0D47A1),
    this.borderRadius    = 16,
    this.padding         = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.sound           = SoundEffect.click,
    this.haptic          = true,
  });

  @override
  State<SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<SoundButton>
    with SingleTickerProviderStateMixin {

  bool _pressed = false;

  void _onDown(_) {
    if (widget.onTap == null) return;
    setState(() => _pressed = true);
    if (widget.haptic) HapticFeedback.lightImpact();
    SoundService().play(widget.sound);
  }

  void _onUp(_) {
    if (_pressed) {
      setState(() => _pressed = false);
      widget.onTap?.call();
    }
  }

  void _onCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onDown,
      onTapUp:   _onUp,
      onTapCancel: _onCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve:    Curves.easeOut,
        margin:   EdgeInsets.only(top: _pressed ? 4 : 0, bottom: _pressed ? 0 : 4),
        decoration: BoxDecoration(
          color:         widget.faceColor,
          borderRadius:  BorderRadius.circular(widget.borderRadius),
          boxShadow: _pressed ? [] : [
            BoxShadow(
              color:  widget.shadowColor,
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
            BoxShadow(
              color:  Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 6),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GoldButton — bouton doré principal (JOUER, COMMENCER…)
// ─────────────────────────────────────────────────────────────
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? emoji;
  final double fontSize;

  const GoldButton({
    super.key,
    required this.label,
    this.onTap,
    this.emoji,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return SoundButton(
      onTap:       onTap,
      faceColor:   const Color(0xFFFFCA28),
      shadowColor: const Color(0xFFE65100),
      sound:       SoundEffect.click,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: TextStyle(fontSize: fontSize + 2)),
            const SizedBox(width: 8),
          ],
          Text(label,
            style: TextStyle(
              color:       Colors.white,
              fontSize:    fontSize,
              fontWeight:  FontWeight.w900,
              letterSpacing: 1.2,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 2)],
            )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// IconSoundButton — bouton icône avec son
// ─────────────────────────────────────────────────────────────
class IconSoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final SoundEffect sound;

  const IconSoundButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color = Colors.white,
    this.size  = 24,
    this.sound = SoundEffect.click,
  });

  @override
  Widget build(BuildContext context) {
    return SoundButton(
      onTap:       onTap,
      faceColor:   Colors.transparent,
      shadowColor: Colors.transparent,
      padding:     const EdgeInsets.all(10),
      sound:       sound,
      child: Icon(icon, color: color, size: size),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AnswerButton — bouton réponse Quiz avec feedback visuel+son
// ─────────────────────────────────────────────────────────────
class AnswerButton extends StatelessWidget {
  final String label;
  final String letter;  // A / B / C / D
  final bool? isCorrect;  // null = pas encore répondu
  final bool isSelected;
  final VoidCallback? onTap;

  const AnswerButton({
    super.key,
    required this.label,
    required this.letter,
    this.isCorrect,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Couleurs selon l'état
    Color bg, border;
    SoundEffect sound = SoundEffect.click;

    if (isCorrect == null) {
      bg     = Colors.white.withValues(alpha: 0.12);
      border = Colors.white.withValues(alpha: 0.25);
    } else if (isCorrect == true) {
      bg     = Colors.green.withValues(alpha: 0.75);
      border = Colors.green.shade300;
      sound  = SoundEffect.correct;
    } else {
      bg     = Colors.red.withValues(alpha: 0.7);
      border = Colors.red.shade300;
      sound  = SoundEffect.wrong;
    }

    return SoundButton(
      onTap:       isCorrect != null ? null : onTap,
      faceColor:   bg,
      shadowColor: border,
      borderRadius: 14,
      padding:      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      sound:        sound,
      child: Row(children: [
        // Badge lettre
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCorrect == null
                ? Colors.white.withValues(alpha: 0.18)
                : (isCorrect! ? Colors.green.shade300 : Colors.red.shade300),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: isCorrect != null
                ? Icon(isCorrect! ? Icons.check : Icons.close,
                    color: Colors.white, size: 14)
                : Text(letter,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
          style: const TextStyle(color: Colors.white,
              fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 2, overflow: TextOverflow.ellipsis,
        )),
      ]),
    );
  }
}