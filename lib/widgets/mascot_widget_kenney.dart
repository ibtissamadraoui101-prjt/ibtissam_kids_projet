// lib/widgets/mascot_widget_kenney.dart
// ═══════════════════════════════════════════════════════════
// 🎨 MASCOTTE KENNEY — Assemblage réel avec images PNG
// Remplace les emojis par les vraies illustrations Kenney
// Monster Builder Pack → body + arms + eyes = mascotte pro
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../models/mascot_model.dart';

// ── Chemin de base des assets mascotte ─────────────────────
const _kBase = 'assets/images/mascots/kenney_monster-builder-pack/PNG/Default/';
const _kDouble = 'assets/images/mascots/kenney_monster-builder-pack/PNG/Double/';

// ── Config d'une mascotte assemblée ────────────────────────
class KenneyMascotConfig {
  final String bodyAsset;
  final String armAsset;
  final String eyeAsset;
  final String? detailAsset;
  final Color  bgColor;
  final String name;

  const KenneyMascotConfig({
    required this.bodyAsset,
    required this.armAsset,
    required this.eyeAsset,
    this.detailAsset,
    required this.bgColor,
    required this.name,
  });
}

// ── Les 5 mascottes disponibles (toutes avec images Kenney) ─
class KenneyMascots {
  static const List<KenneyMascotConfig> all = [
    // 1 — Monstre vert
    KenneyMascotConfig(
      name: 'Zaki',
      bodyAsset:   '${_kBase}body_greenC.png',
      armAsset:    '${_kBase}arm_greenC.png',
      eyeAsset:    '${_kBase}eye_human_green.png',
      detailAsset: '${_kBase}detail_green_horn_large.png',
      bgColor: Color(0xFFE8F5E9),
    ),
    // 2 — Monstre bleu
    KenneyMascotConfig(
      name: 'Lumi',
      bodyAsset:   '${_kBase}body_blueC.png',
      armAsset:    '${_kBase}arm_blueC.png',
      eyeAsset:    '${_kBase}eye_human_blue.png',
      detailAsset: '${_kBase}detail_blue_antenna_large.png',
      bgColor: Color(0xFFE3F2FD),
    ),
    // 3 — Monstre rouge
    KenneyMascotConfig(
      name: 'Rami',
      bodyAsset:   '${_kBase}body_redC.png',
      armAsset:    '${_kBase}arm_redC.png',
      eyeAsset:    '${_kBase}eye_human_red.png',
      bgColor: Color(0xFFFCE4EC),
    ),
    // 4 — Monstre jaune
    KenneyMascotConfig(
      name: 'Safi',
      bodyAsset:   '${_kBase}body_yellowC.png',
      armAsset:    '${_kBase}arm_yellowC.png',
      eyeAsset:    '${_kBase}eye_human_yellow.png',
      detailAsset: '${_kBase}detail_yellow_antenna_large.png',
      bgColor: Color(0xFFFFF8E1),
    ),
    // 5 — Monstre blanc
    KenneyMascotConfig(
      name: 'Nour',
      bodyAsset:   '${_kBase}body_whiteC.png',
      armAsset:    '${_kBase}arm_whiteC.png',
      eyeAsset:    '${_kBase}eye_human_blue.png',
      detailAsset: '${_kBase}detail_white_horn_large.png',
      bgColor: Color(0xFFF3E5F5),
    ),
  ];
}

// ── Widget mascotte assemblé depuis images PNG ──────────────
class KenneyMascotWidget extends StatefulWidget {
  final KenneyMascotConfig config;
  final double size;
  final ZakiMood mood;
  final bool animate;

  const KenneyMascotWidget({
    super.key,
    required this.config,
    this.size = 120,
    this.mood = ZakiMood.happy,
    this.animate = true,
  });

  @override
  State<KenneyMascotWidget> createState() => _KenneyMascotWidgetState();
}

class _KenneyMascotWidgetState extends State<KenneyMascotWidget>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double> _bounce;
  late Animation<double> _armSwing;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: _durationForMood(widget.mood),
    )..repeat(reverse: true);

    _bounce   = Tween<double>(begin: 0, end: -12).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _armSwing = Tween<double>(begin: -0.12, end: 0.12).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  Duration _durationForMood(ZakiMood m) {
    switch (m) {
      case ZakiMood.excited:
      case ZakiMood.celebrating: return const Duration(milliseconds: 400);
      case ZakiMood.sleepy:      return const Duration(milliseconds: 2400);
      default:                   return const Duration(milliseconds: 900);
    }
  }

  @override
  void didUpdateWidget(KenneyMascotWidget old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _ctrl.duration = _durationForMood(widget.mood);
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return _buildStatic();

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: _buildStatic(),
      ),
    );
  }

  Widget _buildStatic() {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Corps principal ──────────────────────
          Image.asset(
            widget.config.bodyAsset,
            width: s * 0.75,
            height: s * 0.75,
            errorBuilder: _fallback,
          ),

          // ── Bras gauche ──────────────────────────
          Positioned(
            left: 0,
            bottom: s * 0.10,
            child: AnimatedBuilder(
              animation: widget.animate ? _ctrl : kAlwaysCompleteAnimation,
              builder: (_, child) => Transform.rotate(
                angle: widget.animate ? _armSwing.value : 0,
                alignment: Alignment.topRight,
                child: child,
              ),
              child: Image.asset(
                widget.config.armAsset,
                width: s * 0.30,
                errorBuilder: _fallback,
              ),
            ),
          ),

          // ── Bras droit (miroir) ──────────────────
          Positioned(
            right: 0,
            bottom: s * 0.10,
            child: AnimatedBuilder(
              animation: widget.animate ? _ctrl : kAlwaysCompleteAnimation,
              builder: (_, child) => Transform.rotate(
                angle: widget.animate ? -_armSwing.value : 0,
                alignment: Alignment.topLeft,
                child: child,
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(-1.0, 1.0),
                child: Image.asset(
                  widget.config.armAsset,
                  width: s * 0.30,
                  errorBuilder: _fallback,
                ),
              ),
            ),
          ),

          // ── Yeux ────────────────────────────────
          Positioned(
            top: s * 0.08,
            child: Image.asset(
              _eyeForMood(widget.mood),
              width: s * 0.48,
              errorBuilder: _fallback,
            ),
          ),

          // ── Détail (corne / antenne) ─────────────
          if (widget.config.detailAsset != null)
            Positioned(
              top: -s * 0.05,
              child: Image.asset(
                widget.config.detailAsset!,
                width: s * 0.35,
                errorBuilder: _fallback,
              ),
            ),

          // ── Couronne si celebrating ───────────────
          if (widget.mood == ZakiMood.celebrating)
            Positioned(
              top: -s * 0.12,
              child: const Text('👑', style: TextStyle(fontSize: 28)),
            ),

          // ── Bulle emoji ──────────────────────────
          if (_bubbleFor(widget.mood) != null)
            Positioned(
              top: -s * 0.08,
              right: -s * 0.08,
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Center(child: Text(
                  _bubbleFor(widget.mood)!,
                  style: const TextStyle(fontSize: 16))),
              ),
            ),
        ],
      ),
    );
  }

  /// Choisit l'image des yeux selon le mood
  String _eyeForMood(ZakiMood mood) {
    switch (mood) {
      case ZakiMood.celebrating:
      case ZakiMood.excited:
        return '${_kBase}eye_angry_green.png'; // yeux grands ouverts
      case ZakiMood.sleepy:
        return '${_kBase}eye_sleep_green.png';
      case ZakiMood.storyShocked:
        return '${_kBase}eye_angry_green.png';
      default:
        return widget.config.eyeAsset;
    }
  }

  String? _bubbleFor(ZakiMood mood) {
    return ZakiExpressions.get(mood).bubbleEmoji;
  }

  Widget _fallback(BuildContext ctx, Object error, StackTrace? _) {
    return Container(
      width: widget.size * 0.5, height: widget.size * 0.5,
      decoration: BoxDecoration(
        color: widget.config.bgColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Sélecteur de mascotte (remplace les emojis) ─────────────
class KenneyMascotPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const KenneyMascotPicker({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Titre visuel — pas de texte complexe
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('🌟', style: TextStyle(fontSize: 18)),
        SizedBox(width: 8),
        Text('Choisis ton héros !',
          style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
        SizedBox(width: 8),
        Text('🌟', style: TextStyle(fontSize: 18)),
      ]),
      const SizedBox(height: 16),
      // Grille 5 mascottes avec vraies images
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(KenneyMascots.all.length, (i) {
          final m       = KenneyMascots.all[i];
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.elasticOut,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width:  selected ? 72 : 60,
              height: selected ? 72 : 60,
              decoration: BoxDecoration(
                color: m.bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.white.withOpacity(0.4),
                  width: selected ? 4 : 2),
                boxShadow: [BoxShadow(
                  color: selected
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.15),
                  blurRadius: selected ? 18 : 6,
                  spreadRadius: selected ? 2 : 0,
                )],
              ),
              child: Center(
                child: KenneyMascotWidget(
                  config: m,
                  size:   selected ? 58 : 48,
                  mood:   selected ? ZakiMood.happy : ZakiMood.thinking,
                  animate: selected,
                ),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 8),
      // Nom de la mascotte sélectionnée
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          KenneyMascots.all[selectedIndex].name,
          key: ValueKey(selectedIndex),
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)]),
        ),
      ),
    ]);
  }
}