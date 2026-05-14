// lib/widgets/lumi_mascot.dart
// CORRIGÉ : suppression de LumiMood.sad

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── UNIQUEMENT ces 6 états valides ───────────────────────────
enum LumiMood { idle, happy, celebrate, encourage, thinking, guide }

class LumiMascot extends StatefulWidget {
  final LumiMood mood;
  final double size;
  final String? message;
  final VoidCallback? onTap;
  final bool showBubble;

  const LumiMascot({
    super.key,
    this.mood = LumiMood.idle,
    this.size = 60,
    this.message,
    this.onTap,
    this.showBubble = false,
  });

  @override
  State<LumiMascot> createState() => _LumiMascotState();
}

class _LumiMascotState extends State<LumiMascot>
    with TickerProviderStateMixin {

  late AnimationController _floatCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _celebCtrl;
  late AnimationController _wingsCtrl;

  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _celebAnim;
  late Animation<double> _wingsAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _celebCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _wingsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -4, end: 4).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _glowAnim = Tween<double>(begin: 0.15, end: 0.35).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _celebAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut));
    _wingsAnim = Tween<double>(begin: -0.15, end: 0.15).animate(
        CurvedAnimation(parent: _wingsCtrl, curve: Curves.easeInOut));

    _triggerMood();
  }

  @override
  void didUpdateWidget(LumiMascot old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _triggerMood();
  }

  void _triggerMood() {
    if (widget.mood == LumiMood.celebrate) {
      _celebCtrl.forward(from: 0).then((_) {
        Future.delayed(const Duration(milliseconds: 400),
            () { if (mounted) _celebCtrl.reverse(); });
      });
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _celebCtrl.dispose();
    _wingsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge(
                [_floatCtrl, _glowCtrl, _celebCtrl, _wingsCtrl]),
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: Transform.scale(
                scale: _celebAnim.value,
                child: SizedBox(
                  width: widget.size + 20,
                  height: widget.size + 20,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Halo lumineux
                      Container(
                        width: widget.size + 16,
                        height: widget.size + 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LKColors.lumiYellow
                              .withOpacity(_glowAnim.value),
                        ),
                      ),
                      // Aile gauche
                      Transform.translate(
                        offset: Offset(-widget.size * 0.52, 0),
                        child: Transform.rotate(
                          angle: -0.4 + _wingsAnim.value,
                          child: _wing(),
                        ),
                      ),
                      // Aile droite
                      Transform.translate(
                        offset: Offset(widget.size * 0.52, 0),
                        child: Transform.rotate(
                          angle: 0.4 - _wingsAnim.value,
                          child: Transform.scale(
                              scaleX: -1, child: _wing()),
                        ),
                      ),
                      // Corps
                      _body(),
                      // Étincelles si celebrate
                      if (widget.mood == LumiMood.celebrate)
                        ..._sparkles(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.showBubble && widget.message != null)
            _bubble(),
        ],
      ),
    );
  }

  Widget _wing() {
    final s = widget.size * 0.42;
    return Container(
      width: s,
      height: s * 0.6,
      decoration: BoxDecoration(
        color: LKColors.lumiWing.withOpacity(0.85),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(s * 0.8),
          topRight: Radius.circular(s * 0.2),
          bottomLeft: Radius.circular(s * 0.2),
          bottomRight: Radius.circular(s * 0.4),
        ),
        border: Border.all(color: Colors.lightBlue.shade200, width: 1.5),
      ),
    );
  }

  Widget _body() {
    final s = widget.size;
    return Container(
      width: s, height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LKColors.lumiYellow,
        border: Border.all(color: LKColors.lumiOrange, width: 3),
      ),
      child: Stack(children: [
        // Yeux
        Positioned(top: s * 0.28, left: s * 0.18, child: _eye()),
        Positioned(top: s * 0.28, right: s * 0.18, child: _eye()),
        // Joues roses (happy + celebrate)
        if (widget.mood == LumiMood.happy ||
            widget.mood == LumiMood.celebrate) ...[
          Positioned(top: s * 0.52, left: s * 0.1,  child: _cheek()),
          Positioned(top: s * 0.52, right: s * 0.1, child: _cheek()),
        ],
        // Bouche
        Positioned(
          bottom: s * 0.2,
          left: s * 0.28,
          right: s * 0.28,
          child: CustomPaint(
            size: Size(s * 0.44, s * 0.18),
            painter: _MouthPainter(mood: widget.mood),
          ),
        ),
        // Lueur du bas
        Positioned(
          bottom: s * 0.08, left: s * 0.38,
          child: Container(
            width: s * 0.22, height: s * 0.14,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFF80).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _eye() {
    final s = widget.size * 0.13;
    return Container(
      width: s, height: s * 1.2,
      decoration: const BoxDecoration(
          color: Color(0xFF3B2000), shape: BoxShape.circle),
      child: Center(
        child: Container(
          width: s * 0.3, height: s * 0.3,
          decoration: const BoxDecoration(
              color: Colors.white54, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _cheek() => Container(
    width: widget.size * 0.2, height: widget.size * 0.1,
    decoration: BoxDecoration(
      color: const Color(0xFFFFB347).withOpacity(0.7),
      borderRadius: BorderRadius.circular(20),
    ),
  );

  List<Widget> _sparkles() {
    const pos = [Offset(-18, -18), Offset(18, -18),
                  Offset(-22, 2),  Offset(22, 2)];
    return pos.map((p) => Transform.translate(
      offset: p,
      child: const Text('✨', style: TextStyle(fontSize: 12)),
    )).toList();
  }

  Widget _bubble() => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    constraints: const BoxConstraints(maxWidth: 240),
    decoration: BoxDecoration(
      color: LKColors.bgYellowLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: LKColors.sunDark, width: 2),
    ),
    child: Text(
      widget.message ?? '',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: LKColors.textOnYellow, height: 1.4,
      ),
    ),
  );
}

// ── Mouth painter ─────────────────────────────────────────────
class _MouthPainter extends CustomPainter {
  final LumiMood mood;
  const _MouthPainter({required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF3B2000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    switch (mood) {
      // encourage = bouche neutre légèrement triste (remplace LumiMood.sad)
      case LumiMood.encourage:
        path.moveTo(size.width * 0.1, size.height * 0.6);
        path.quadraticBezierTo(
            size.width * 0.5, size.height * 0.1,
            size.width * 0.9, size.height * 0.6);
        break;
      case LumiMood.thinking:
        path.moveTo(size.width * 0.2, size.height * 0.5);
        path.lineTo(size.width * 0.8, size.height * 0.5);
        break;
      // idle, happy, celebrate, guide → grand sourire
      default:
        path.moveTo(size.width * 0.05, size.height * 0.15);
        path.quadraticBezierTo(
            size.width * 0.5, size.height * 1.1,
            size.width * 0.95, size.height * 0.15);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_MouthPainter old) => old.mood != mood;
}