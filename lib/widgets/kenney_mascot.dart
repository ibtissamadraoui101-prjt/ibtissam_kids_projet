import 'package:flutter/material.dart';

class KenneyMascot extends StatefulWidget {
  final int mascotIndex;
  final double size;
  final bool animate;
  final VoidCallback? onTap;

  const KenneyMascot({
    super.key,
    required this.mascotIndex,
    this.size = 120,
    this.animate = true,
    this.onTap,
  });

  @override
  State<KenneyMascot> createState() => _KenneyMascotState();
}

class _KenneyMascotState extends State<KenneyMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _animCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (widget.animate) _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parts = _getMascotParts(widget.mascotIndex);

    Widget mascot = Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(parts['body']!, width: widget.size),
        Image.asset(parts['eyes']!, width: widget.size),
        Image.asset(parts['mouth']!, width: widget.size * 0.6),
      ],
    );

    if (widget.animate) {
      mascot = AnimatedBuilder(
        animation: _animCtrl,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, -8 * _animCtrl.value),
          child: mascot,
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: mascot,
    );
  }

  Map<String, String> _getMascotParts(int index) {
    const parts = [
      {
        'body':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/body_redA.png',
        'eyes':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/eye_angry_red.png',
        'mouth':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/mouth_closed_happy.png',
      },
      {
        'body':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/body_darkA.png',
        'eyes':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/eye_angry_blue.png',
        'mouth':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/mouth_closed_happy.png',
      },
      {
        'body':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/body_darkB.png',
        'eyes':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/eye_yellow.png',
        'mouth':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/mouth_closed_happy.png',
      },
      {
        'body':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/body_redB.png',
        'eyes':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/eye_angry_red.png',
        'mouth':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/mouth_closed_happy.png',
      },
      {
        'body':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/body_darkC.png',
        'eyes':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/eye_yellow.png',
        'mouth':
            'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/mouth_closed_happy.png',
      },
    ];
    return parts[index % parts.length].cast<String, String>();
  }
}
