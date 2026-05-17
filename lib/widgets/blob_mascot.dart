import 'package:flutter/material.dart';
import 'dart:math' as math;

class BlobMascot extends StatefulWidget {
  final double size;
  final bool animate;

  const BlobMascot({
    Key? key,
    this.size = 120,
    this.animate = true,
  }) : super(key: key);

  @override
  State<BlobMascot> createState() => _BlobMascotState();
}

class _BlobMascotState extends State<BlobMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnim;
  late Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _floatAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _blinkAnim = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.4, 0.45, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, widget.animate ? _floatAnim.value : 0),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main body - blue blob with CustomPaint
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _BlobPainter(
                    eyeBlinkOpacity: _blinkAnim.value,
                    armRotation: widget.animate
                        ? math.sin(_controller.value * math.pi * 2) * 0.15
                        : 0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double eyeBlinkOpacity;
  final double armRotation;

  _BlobPainter({required this.eyeBlinkOpacity, required this.armRotation});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Body - blue blob
    final bodyPaint = Paint()..color = const Color(0xFF2196F3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.85,
        height: size.height * 0.88,
      ),
      bodyPaint,
    );

    // Belly - lighter blue
    final bellyPaint = Paint()..color = const Color(0xFF64B5F6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 8),
        width: size.width * 0.48,
        height: size.height * 0.52,
      ),
      bellyPaint,
    );

    // Left arm - green
    _drawArm(canvas, cx - 20, cy + 10, -0.3 + armRotation, size, true);

    // Right arm - green
    _drawArm(canvas, cx + 20, cy + 10, 0.3 - armRotation, size, false);

    // Left foot
    _drawFoot(canvas, cx - 12, cy + 38, size);

    // Right foot
    _drawFoot(canvas, cx + 12, cy + 38, size);

    // Eye - big single eye centered
    final eyeWhitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(cx, cy - 6),
      size.width * 0.18,
      eyeWhitePaint,
    );

    // Pupil
    final pupilPaint = Paint()..color = const Color(0xFF1565C0);
    canvas.drawCircle(
      Offset(cx + 3, cy - 5),
      size.width * 0.10,
      pupilPaint,
    );

    // Eye shine
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(cx + 6, cy - 8),
      size.width * 0.04,
      shinePaint,
    );

    // Eyebrow - expressive
    final browPaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy - 18),
        width: size.width * 0.28,
        height: size.height * 0.12,
      ),
      math.pi * 0.2,
      math.pi * 0.6,
      false,
      browPaint,
    );

    // Antenna - yellow
    _drawAntenna(canvas, cx, cy - 32, size);

    // Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy + 8),
        width: size.width * 0.22,
        height: size.height * 0.12,
      ),
      0,
      math.pi,
      false,
      smilePaint,
    );

    // Cheeks - pink circles
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF69B4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(cx - 22, cy),
      size.width * 0.08,
      cheekPaint..color = cheekPaint.color.withOpacity(0.4),
    );
    canvas.drawCircle(
      Offset(cx + 22, cy),
      size.width * 0.08,
      cheekPaint..color = cheekPaint.color.withOpacity(0.4),
    );
  }

  void _drawArm(Canvas canvas, double x, double y, double angle, Size size, bool isLeft) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final armPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-4, -8, 8, 24),
        const Radius.circular(4),
      ),
      armPaint,
    );

    // Hand
    canvas.drawCircle(Offset(0, 16), 6, armPaint);

    canvas.restore();
  }

  void _drawFoot(Canvas canvas, double x, double y, Size size) {
    final footPaint = Paint()..color = const Color(0xFF1565C0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 12, height: 8),
        const Radius.circular(4),
      ),
      footPaint,
    );
  }

  void _drawAntenna(Canvas canvas, double cx, double cy, Size size) {
    final antennaPaint = Paint()
      ..color = const Color(0xFFFFD740)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Antenna line
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx, cy - 16),
      antennaPaint,
    );

    // Ball on top
    canvas.drawCircle(
      Offset(cx, cy - 18),
      4,
      Paint()..color = const Color(0xFFFFD740),
    );
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) {
    return eyeBlinkOpacity != oldDelegate.eyeBlinkOpacity ||
        armRotation != oldDelegate.armRotation;
  }
}
