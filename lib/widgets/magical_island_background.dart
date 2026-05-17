import 'package:flutter/material.dart';
import 'dart:math' as math;

class MagicalIslandBackground extends StatefulWidget {
  final Widget? child;

  const MagicalIslandBackground({
    super.key,
    this.child,
  });

  @override
  State<MagicalIslandBackground> createState() =>
      _MagicalIslandBackgroundState();
}

class _MagicalIslandBackgroundState extends State<MagicalIslandBackground>
    with TickerProviderStateMixin {
  late AnimationController _cloudCtrl;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _cloudCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Background sky
        Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF87CEEB),
                Color(0xFF56CCF2),
                Color(0xFF29B6F6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Distant clouds
        AnimatedBuilder(
          animation: _cloudCtrl,
          builder: (_, __) => Stack(
            children: [
              _CloudWidget(
                x: -0.2 + _cloudCtrl.value,
                y: 0.08,
                size: 140,
                opacity: 0.7,
              ),
              _CloudWidget(
                x: 0.6 + (_cloudCtrl.value * 0.5),
                y: 0.06,
                size: 110,
                opacity: 0.6,
              ),
              _CloudWidget(
                x: -0.1 + (_cloudCtrl.value * 0.8),
                y: 0.14,
                size: 90,
                opacity: 0.5,
              ),
            ],
          ),
        ),

        // Sun
        Positioned(
          right: size.width * 0.08,
          top: size.height * 0.08,
          child: const _SunWidget(),
        ),

        // Water
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: size.height * 0.42,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0DA6D6),
                  Color(0xFF0288D1),
                  Color(0xFF01579B),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Waves
        Positioned(
          bottom: size.height * 0.30,
          left: 0,
          right: 0,
          height: 60,
          child: AnimatedBuilder(
            animation: _waveCtrl,
            builder: (_, __) => CustomPaint(
              painter: _WavePainter(_waveCtrl.value),
              size: Size(size.width, 60),
            ),
          ),
        ),

        // Islands
        Positioned(
          bottom: size.height * 0.35,
          left: size.width * 0.05,
          child: _IslandWidget(size: size.width * 0.25),
        ),
        Positioned(
          bottom: size.height * 0.33,
          right: size.width * 0.08,
          child: _IslandWidget(size: size.width * 0.20),
        ),

        // Content
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _CloudWidget extends StatelessWidget {
  final double x, y, size, opacity;

  const _CloudWidget({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double position = ((x % 1.5) * screenWidth).clamp(0.0, screenWidth);

    return Positioned(
      left: position,
      top: y * screenHeight,
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          painter: _CloudPainter(),
          size: Size(size, size * 0.4),
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromLTWH(0, size.height * 0.3, size.width * 0.6, size.height * 0.7),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      size.width * 0.2,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.15),
      size.width * 0.18,
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SunWidget extends StatelessWidget {
  const _SunWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SunPainter(),
      size: const Size(80, 80),
    );
  }
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.35,
      Paint()..color = const Color(0xFFFFF176),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.3,
      Paint()..color = const Color(0xFFFFEB3B),
    );

    final rayPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final startDist = size.width * 0.4;
      final endDist = size.width * 0.55;
      canvas.drawLine(
        Offset(
            cx + startDist * math.cos(angle), cy + startDist * math.sin(angle)),
        Offset(cx + endDist * math.cos(angle), cy + endDist * math.sin(angle)),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _IslandWidget extends StatelessWidget {
  final double size;

  const _IslandWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _IslandPainter(),
      size: Size(size, size * 0.5),
    );
  }
}

class _IslandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sand shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h + 5),
        width: w,
        height: h * 0.3,
      ),
      Paint()..color = const Color(0xFF0288D1).withOpacity(0.3),
    );

    // Main island
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.5),
        width: w * 0.9,
        height: h * 0.6,
      ),
      Paint()..color = const Color(0xFF4CAF50),
    );

    // Island highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.3),
        width: w * 0.7,
        height: h * 0.4,
      ),
      Paint()..color = const Color(0xFF66BB6A),
    );

    // Tree trunk
    canvas.drawLine(
      Offset(w * 0.5, h * 0.2),
      Offset(w * 0.5, h * 0.5),
      Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 4,
    );

    // Tree foliage
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.1),
      w * 0.15,
      Paint()..color = const Color(0xFF2E7D32),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _WavePainter extends CustomPainter {
  final double phase;

  _WavePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height * 0.5);

    for (int i = 0; i <= size.width.toInt(); i++) {
      final x = i.toDouble();
      final y =
          size.height * 0.5 + 6 * math.sin(x * 0.02 + phase * math.pi * 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withOpacity(0.15),
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.phase != phase;
}
