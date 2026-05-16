import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/mascot_model.dart';

class MascotWidget extends StatefulWidget {
  final ZakiMood mood;
  final double size;
  final bool showBubble;
  final String? bubbleText;

  const MascotWidget({
    super.key,
    required this.mood,
    this.size = 100,
    this.showBubble = false,
    this.bubbleText,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with TickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expr = ZakiExpressions.get(widget.mood);

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) {
        double yOffset = 0;
        double scale = 1.0;
        double rotation = 0;

        switch (expr.animation) {
          case MascotAnimation.bounce:
            yOffset = -8 * _animCtrl.value;
            break;
          case MascotAnimation.float:
            yOffset = -4 * math.sin(_animCtrl.value * math.pi * 2);
            break;
          case MascotAnimation.shake:
            rotation = 0.05 * math.sin(_animCtrl.value * math.pi * 4);
            break;
          case MascotAnimation.pulse:
            scale = 0.95 + 0.1 * _animCtrl.value;
            break;
          case MascotAnimation.sway:
            rotation = 0.08 * math.sin(_animCtrl.value * math.pi * 2);
            break;
          case MascotAnimation.wave:
            rotation = 0.3 * math.sin(_animCtrl.value * math.pi * 2);
            break;
          case MascotAnimation.fistPump:
            yOffset = -12 * (0.5 - (_animCtrl.value - 0.5).abs());
            break;
          case MascotAnimation.still:
            break;
        }

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildZakiBody(expr),
                        if (expr.hasCape) _buildCape(expr),
                        if (expr.hasCrown) _buildCrown(expr),
                        if (expr.hasStar) _buildStar(expr),
                      ],
                    ),
                  ),
                  if (widget.showBubble && expr.bubbleEmoji != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(expr.bubbleEmoji ?? '',
                          style: TextStyle(fontSize: widget.size * 0.3)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildZakiBody(ZakiExpression expr) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _ZakiPainter(expr, widget.size),
    );
  }

  Widget _buildCape(ZakiExpression expr) {
    return Positioned(
      top: widget.size * 0.15,
      child: Container(
        width: widget.size * 0.6,
        height: widget.size * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5).withOpacity(0.8),
          borderRadius: BorderRadius.circular(widget.size * 0.1),
        ),
      ),
    );
  }

  Widget _buildCrown(ZakiExpression expr) {
    return Positioned(
      top: 0,
      child: Container(
        width: widget.size * 0.5,
        height: widget.size * 0.15,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700),
          borderRadius: BorderRadius.circular(widget.size * 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
              3,
              (i) => Container(
                    width: widget.size * 0.08,
                    height: widget.size * 0.12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                  )),
        ),
      ),
    );
  }

  Widget _buildStar(ZakiExpression expr) {
    return Positioned(
      top: -widget.size * 0.08,
      right: -widget.size * 0.08,
      child: const Text('⭐', style: TextStyle(fontSize: 24)),
    );
  }
}

class _ZakiPainter extends CustomPainter {
  final ZakiExpression expr;
  final double size;

  _ZakiPainter(this.expr, this.size);

  @override
  void paint(Canvas canvas, Size sz) {
    final cx = sz.width / 2;
    final cy = sz.height / 2;

    // Mane (crinière)
    _drawMane(canvas, cx, cy);

    // Head
    _drawHead(canvas, cx, cy);

    // Eyes
    _drawEyes(canvas, cx, cy);

    // Mouth
    _drawMouth(canvas, cx, cy);

    // Cheeks
    if (expr.cheekColor.alpha > 0) {
      _drawCheeks(canvas, cx, cy);
    }

    // Tears
    if (expr.hasTears) {
      _drawTears(canvas, cx, cy);
    }

    // Sweat
    if (expr.hasSweat) {
      _drawSweat(canvas, cx, cy);
    }
  }

  void _drawMane(Canvas canvas, double cx, double cy) {
    final manePaint = Paint()
      ..color = expr.maneColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(cx, cy - size * 0.05),
      size * 0.45,
      manePaint,
    );
  }

  void _drawHead(Canvas canvas, double cx, double cy) {
    final facePaint = Paint()
      ..color = expr.faceColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(cx, cy),
      size * 0.35,
      facePaint,
    );
  }

  void _drawEyes(Canvas canvas, double cx, double cy) {
    final eyePaint = Paint()..color = expr.eyeColor;
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final eyeY = cy - size * 0.08;
    final eyeSize = size * 0.08 * expr.eyeOpenness;

    // Left eye
    canvas.drawCircle(
      Offset(cx - size * 0.12, eyeY),
      eyeSize,
      eyePaint,
    );
    if (expr.hasEyeShine) {
      canvas.drawCircle(
        Offset(cx - size * 0.12, eyeY - eyeSize * 0.3),
        eyeSize * 0.4,
        shinePaint,
      );
    }

    // Right eye
    canvas.drawCircle(
      Offset(cx + size * 0.12, eyeY),
      eyeSize,
      eyePaint,
    );
    if (expr.hasEyeShine) {
      canvas.drawCircle(
        Offset(cx + size * 0.12, eyeY - eyeSize * 0.3),
        eyeSize * 0.4,
        shinePaint,
      );
    }

    // Fire eyes
    if (expr.hasFireEyes) {
      _drawFireEyes(canvas, cx, cy);
    }
  }

  void _drawFireEyes(Canvas canvas, double cx, double cy) {
    final eyeY = cy - size * 0.08;
    const fireColors = [Color(0xFFFF5722), Color(0xFFFFB74D)];

    for (int i = 0; i < 2; i++) {
      final eyeX = i == 0 ? cx - size * 0.12 : cx + size * 0.12;
      final paint = Paint()
        ..shader = RadialGradient(colors: fireColors).createShader(
          Rect.fromCircle(center: Offset(eyeX, eyeY), radius: size * 0.06),
        );
      canvas.drawCircle(Offset(eyeX, eyeY), size * 0.06, paint);
    }
  }

  void _drawMouth(Canvas canvas, double cx, double cy) {
    final mouthPaint = Paint()
      ..color = expr.eyeColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final mouthY = cy + size * 0.1;

    switch (expr.mouth) {
      case MouthShape.bigSmile:
        final path = Path()
          ..moveTo(cx - size * 0.15, mouthY)
          ..quadraticBezierTo(
              cx, mouthY + size * 0.12, cx + size * 0.15, mouthY);
        canvas.drawPath(path, mouthPaint);
        break;
      case MouthShape.smile:
        final path = Path()
          ..moveTo(cx - size * 0.12, mouthY)
          ..quadraticBezierTo(
              cx, mouthY + size * 0.08, cx + size * 0.12, mouthY);
        canvas.drawPath(path, mouthPaint);
        break;
      case MouthShape.smileSmall:
        final path = Path()
          ..moveTo(cx - size * 0.1, mouthY)
          ..quadraticBezierTo(
              cx, mouthY + size * 0.04, cx + size * 0.1, mouthY);
        canvas.drawPath(path, mouthPaint);
        break;
      case MouthShape.neutral:
        canvas.drawLine(
          Offset(cx - size * 0.12, mouthY),
          Offset(cx + size * 0.12, mouthY),
          mouthPaint,
        );
        break;
      case MouthShape.surprised:
        canvas.drawCircle(
          Offset(cx, mouthY + size * 0.04),
          size * 0.06,
          Paint()..color = expr.eyeColor,
        );
        break;
      case MouthShape.openHappy:
        final path = Path()
          ..moveTo(cx - size * 0.15, mouthY)
          ..quadraticBezierTo(
              cx, mouthY + size * 0.15, cx + size * 0.15, mouthY)
          ..lineTo(cx + size * 0.12, mouthY - size * 0.04)
          ..quadraticBezierTo(
              cx, mouthY - size * 0.08, cx - size * 0.12, mouthY - size * 0.04)
          ..close();
        canvas.drawPath(path, Paint()..color = expr.eyeColor);
        break;
    }

    if (expr.hasTeeth) {
      _drawTeeth(canvas, cx, mouthY);
    }
  }

  void _drawTeeth(Canvas canvas, double cx, double cy) {
    final toothPaint = Paint()..color = Colors.white;
    final toothWidth = size * 0.04;
    for (int i = -1; i <= 1; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          cx + (i * toothWidth * 1.2) - toothWidth / 2,
          cy + size * 0.02,
          toothWidth * 0.8,
          size * 0.05,
        ),
        toothPaint,
      );
    }
  }

  void _drawCheeks(Canvas canvas, double cx, double cy) {
    final cheekPaint = Paint()..color = expr.cheekColor;
    final cheekY = cy;

    canvas.drawCircle(
      Offset(cx - size * 0.2, cheekY),
      size * 0.08,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(cx + size * 0.2, cheekY),
      size * 0.08,
      cheekPaint,
    );
  }

  void _drawTears(Canvas canvas, double cx, double cy) {
    final tearPaint = Paint()..color = const Color(0xFF64B5F6);
    final eyeY = cy - size * 0.08;

    for (int i = 0; i < 2; i++) {
      final eyeX = i == 0 ? cx - size * 0.12 : cx + size * 0.12;
      canvas.drawCircle(
        Offset(eyeX, eyeY + size * 0.15),
        size * 0.04,
        tearPaint,
      );
    }
  }

  void _drawSweat(Canvas canvas, double cx, double cy) {
    final sweatPaint = Paint()..color = const Color(0xFF64B5F6);
    canvas.drawCircle(
      Offset(cx + size * 0.25, cy - size * 0.15),
      size * 0.04,
      sweatPaint,
    );
  }

  @override
  bool shouldRepaint(_ZakiPainter oldDelegate) {
    return oldDelegate.expr.mood != expr.mood || oldDelegate.size != size;
  }
}
