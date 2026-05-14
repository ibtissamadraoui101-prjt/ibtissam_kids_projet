// lib/screens/world_map_screen.dart
// ═══════════════════════════════════════════════════════════
// LinguaKids — World Map PREMIUM
// Îles flottantes dans un océan riche, style Disney Junior
// Tout dessiné en Flutter — aucune image externe requise
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../services/progress_service.dart';
import '../models/student_models.dart';
import '../widgets/lumi_mascot.dart';
import '../widgets/lk_widgets.dart';
import 'island_screen.dart';
import 'stats_screen.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});
  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {

  // Animations globales
  late AnimationController _waveCtrl;
  late AnimationController _cloudCtrl;
  late AnimationController _sunCtrl;
  late AnimationController _bubbleCtrl;
  late AnimationController _lumiCtrl;
  late AnimationController _shimmerCtrl;

  late Animation<double> _waveAnim;
  late Animation<double> _cloudAnim;
  late Animation<double> _sunAnim;
  late Animation<double> _bubbleAnim;
  late Animation<double> _lumiAnim;
  late Animation<double> _shimmerAnim;

  // Float animé par île (staggeré)
  late List<AnimationController> _floatCtrls;
  late List<Animation<double>>   _floatAnims;

  int      _tab      = 0;
  LumiMood _lumiMood = LumiMood.happy;

  @override
  void initState() {
    super.initState();

    _waveCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat(reverse: true);
    _cloudCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
    _sunCtrl     = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _bubbleCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _lumiCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);

    _waveAnim    = CurvedAnimation(parent: _waveCtrl,   curve: Curves.easeInOut);
    _cloudAnim   = CurvedAnimation(parent: _cloudCtrl,  curve: Curves.linear);
    _sunAnim     = CurvedAnimation(parent: _sunCtrl,    curve: Curves.linear);
    _bubbleAnim  = Tween<double>(begin: -4, end: 4).animate(CurvedAnimation(parent: _bubbleCtrl, curve: Curves.easeInOut));
    _lumiAnim    = Tween<double>(begin: -8, end: 8).animate(CurvedAnimation(parent: _lumiCtrl,   curve: Curves.easeInOut));
    _shimmerAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // Îles flottent à des rythmes légèrement différents
    _floatCtrls = List.generate(5, (i) {
      final ms = 1600 + i * 280;
      return AnimationController(vsync: this, duration: Duration(milliseconds: ms))
        ..repeat(reverse: true);
    });
    _floatAnims = List.generate(5, (i) =>
      Tween<double>(begin: -8.0, end: 8.0).animate(
        CurvedAnimation(parent: _floatCtrls[i], curve: Curves.easeInOut)));
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _cloudCtrl.dispose();
    _sunCtrl.dispose();
    _bubbleCtrl.dispose();
    _lumiCtrl.dispose();
    _shimmerCtrl.dispose();
    for (final c in _floatCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (_, __) {
        final ps      = ProgressService();
        final student = ps.student;
        final islands = ps.buildIslands();

        return Scaffold(
          body: Stack(children: [
            // 1) Fond ciel dégradé riche
            _Sky(),
            // 2) Étoiles (zone haute)
            const _StarField(),
            // 3) Aurora légère
            const _AuroraLayer(),
            // 4) Soleil animé
            _buildSun(),
            // 5) Nuages multi-couches
            AnimatedBuilder(animation: _cloudAnim, builder: (_, __) => _buildClouds()),
            // 6) Mer profonde animée
            AnimatedBuilder(animation: _waveAnim,  builder: (_, __) => _buildSea()),
            // 7) Chemin lumineux + îles
            _buildMapContent(islands),
            // 8) HUD (XP, streak, titre)
            SafeArea(child: _buildHUD(student)),
            // 9) Lumi
            _buildLumi(),
            // 10) Bulle histoire
            _buildStoryBubble(student),
            // 11) Nav bar
            Positioned(bottom: 0, left: 0, right: 0, child: _buildNavBar()),
          ]),
        );
      },
    );
  }

  // ── SKY ─────────────────────────────────────────────────
  Widget _buildSun() {
    return AnimatedBuilder(
      animation: _sunAnim,
      builder: (_, __) => Positioned(
        top: 55, right: 22,
        child: _SunWidget(rotation: _sunAnim.value * 2 * math.pi,
            shimmer: _shimmerAnim.value),
      ),
    );
  }

  Widget _buildClouds() {
    final w = MediaQuery.of(context).size.width;
    final t = _cloudAnim.value;
    return Stack(children: [
      _CloudWidget(left: w * t - 110,                top: 55, scale: 1.0),
      _CloudWidget(left: w * ((t + 0.38) % 1) - 80, top: 32, scale: 0.78),
      _CloudWidget(left: w * ((t + 0.62) % 1) - 90, top: 88, scale: 0.88),
      _CloudWidget(left: w * ((t + 0.84) % 1) - 60, top: 22, scale: 0.62),
    ]);
  }

  Widget _buildSea() {
    final size = MediaQuery.of(context).size;
    return Positioned(
      bottom: 64, left: 0, right: 0,
      height: size.height * 0.52,
      child: CustomPaint(
        painter: _PremiumSeaPainter(
          wave: _waveAnim.value,
          shimmer: _shimmerAnim.value,
        ),
      ),
    );
  }

  // ── MAP CONTENT (chemin + îles) ─────────────────────────
  Widget _buildMapContent(List<Island> islands) {
    final size = MediaQuery.of(context).size;
    final contentH = math.max(size.height - 180.0, islands.length * 155.0 + 60);

    return Positioned(
      top: 110, bottom: 68,
      left: 0, right: 0,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: size.width,
          height: contentH,
          child: Stack(children: [
            // Chemin pointillé lumineux
            CustomPaint(
              size: Size(size.width, contentH),
              painter: _PathPainter(
                count: islands.length,
                screenW: size.width,
              ),
            ),
            // Îles
            ...List.generate(islands.length, (i) =>
              _buildIsland(islands[i], IslandTheme.all[i], i, size.width)),
          ]),
        ),
      ),
    );
  }

  Widget _buildIsland(Island island, IslandTheme theme, int idx, double screenW) {
    final unlocked = island.isUnlocked;

    // Disposition zigzag
    final isLeft = idx % 2 == 0;
    final left   = isLeft ? screenW * 0.04 : screenW * 0.40;
    final top    = idx * 148.0 + 10;

    // Taille décroissante
    final w = 175.0 - idx * 9.0;
    final h = 128.0 - idx * 7.0;

    return AnimatedBuilder(
      animation: _floatAnims[idx],
      builder: (_, __) => Positioned(
        left: left,
        top:  top + _floatAnims[idx].value,
        child: GestureDetector(
          onTap: unlocked
            ? () {
                HapticFeedback.mediumImpact();
                Navigator.push(context, _pageRoute(
                  IslandScreen(islandId: island.id, theme: theme)));
              }
            : () {
                HapticFeedback.heavyImpact();
                _snack(island.starsToUnlock);
              },
          child: _IslandWidget(
            island: island,
            theme:  theme,
            width:  w,
            height: h,
            index:  idx,
            shimmer: _shimmerAnim.value,
          ),
        ),
      ),
    );
  }

  // ── HUD ─────────────────────────────────────────────────
  Widget _buildHUD(Student? student) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(children: [
        // XP
        _GlassPill(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⭐', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('${student?.totalStars ?? 0} XP',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                  color: Color(0xFF6B4400))),
          ]),
          color: const Color(0xFFFFD93D),
          border: const Color(0xFFFFA000),
        ),
        const Spacer(),
        // Titre
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
          ),
          child: const Text('🗺 LinguaKids',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 6)])),
        ),
        const Spacer(),
        // Streak
        _GlassPill(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔥', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('${student?.currentStreak ?? 0}j',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                  color: Colors.white)),
          ]),
          color: const Color(0xFFFF6B35),
          border: const Color(0xFFFF3D00),
        ),
      ]),
    );
  }

  // ── LUMI ────────────────────────────────────────────────
  Widget _buildLumi() {
    return AnimatedBuilder(
      animation: _lumiAnim,
      builder: (_, __) => Positioned(
        bottom: 145, right: 14,
        child: Transform.translate(
          offset: Offset(0, _lumiAnim.value),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _lumiMood = LumiMood.celebrate);
              Future.delayed(const Duration(milliseconds: 1000),
                () { if (mounted) setState(() => _lumiMood = LumiMood.happy); });
            },
            child: Stack(alignment: Alignment.center, children: [
              // Halo externe
              Container(
                width: 78, height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD93D).withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              LumiMascot(mood: _lumiMood, size: 52),
              // Étincelles autour
              Positioned(top: 0,  left: 4,  child: _sparkle('✦', 12)),
              Positioned(top: 2,  right: 2, child: _sparkle('✧', 10)),
              Positioned(bottom: 4, left: 2, child: _sparkle('✦', 9)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sparkle(String s, double size) => Text(s,
    style: TextStyle(fontSize: size, color: const Color(0xFFFFD93D),
        fontWeight: FontWeight.w900));

  // ── STORY BUBBLE ────────────────────────────────────────
  Widget _buildStoryBubble(Student? student) {
    final name = student?.name ?? 'Champion';
    return AnimatedBuilder(
      animation: _bubbleAnim,
      builder: (_, __) => Positioned(
        bottom: 72, left: 10, right: 78,
        child: Transform.translate(
          offset: Offset(0, _bubbleAnim.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFDE7), Color(0xFFFFF8DC)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFD93D), width: 2.5),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.35),
                    blurRadius: 14, offset: const Offset(0, 4)),
                BoxShadow(color: Colors.black.withOpacity(0.08),
                    blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFF176), Color(0xFFFFD93D)]),
                  border: Border.all(color: const Color(0xFFFFA000), width: 2),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFFFFD93D).withOpacity(0.5), blurRadius: 8)],
                ),
                child: const Center(child: Text('✨', style: TextStyle(fontSize: 17))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour $name ! 👋',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                        color: Color(0xFF7A5200))),
                  const SizedBox(height: 2),
                  const Text('Explore les îles magiques 🏝',
                    style: TextStyle(fontSize: 10, color: Color(0xFF9B6C00),
                        fontWeight: FontWeight.w600)),
                ],
              )),
            ]),
          ),
        ),
      ),
    );
  }

  // ── NAV BAR ─────────────────────────────────────────────
  Widget _buildNavBar() {
    final items = [
      (Icons.map_rounded,          'Carte'),
      (Icons.bar_chart_rounded,    'Stats'),
      (Icons.emoji_events_rounded, 'Trophées'),
      (Icons.people_rounded,       'Parents'),
    ];
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFFFD93D), width: 2.5)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((e) {
          final i      = e.key;
          final item   = e.value;
          final active = _tab == i;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _tab = i);
              if (i == 1) Navigator.push(context, _pageRoute(const StatsScreen()));
              if (i == 3) Navigator.push(context, _pageRoute(const ProfileScreen()));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFFF0EB) : Colors.transparent,
                borderRadius: BorderRadius.circular(14)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(item.$1, size: 24,
                  color: active ? const Color(0xFFFF8C6B) : Colors.grey.shade400),
                const SizedBox(height: 2),
                Text(item.$2, style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  color: active ? const Color(0xFFFF8C6B) : Colors.grey.shade400)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _snack(int n) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🔒 Il te faut $n ⭐ pour débloquer cette île !',
        style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: const Color(0xFF5DCAA5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 2),
    ));
  }
}

// ── Pill HUD avec verre ──────────────────────────────────────
class _GlassPill extends StatelessWidget {
  final Widget child;
  final Color  color;
  final Color  border;

  const _GlassPill({required this.child, required this.color, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 3)),
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

// ── Route de navigation ──────────────────────────────────────
Route _pageRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, a, __) => page,
  transitionsBuilder: (_, a, __, child) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
      .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: child,
  ),
  transitionDuration: const Duration(milliseconds: 320),
);


// ══════════════════════════════════════════════════════════════
// WIDGET ÎLE PREMIUM
// ══════════════════════════════════════════════════════════════
class _IslandWidget extends StatelessWidget {
  final Island      island;
  final IslandTheme theme;
  final double      width;
  final double      height;
  final int         index;
  final double      shimmer;

  const _IslandWidget({
    required this.island, required this.theme,
    required this.width,  required this.height,
    required this.index,  required this.shimmer,
  });

  bool get unlocked => island.isUnlocked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width + 40,
      height: height + 68,
      child: Stack(clipBehavior: Clip.none, children: [

        // ── Glow anneau actif ──────────────────────────
        if (unlocked)
          Positioned(
            top: 0, left: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: width + 40, height: height + 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(60), bottom: Radius.circular(50)),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withOpacity(0.55),
                    blurRadius: 22, spreadRadius: 4,
                    offset: const Offset(0, 4)),
                ],
              ),
            ),
          ),

        // ── Ombre eau sous l'île ────────────────────────
        Positioned(
          bottom: 28, left: 10,
          child: Container(
            width: width + 20, height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: RadialGradient(
                colors: [
                  Colors.black.withOpacity(0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Reflet eau ──────────────────────────────────
        Positioned(
          bottom: 18, left: 8,
          child: Container(
            width: width + 24, height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4DC8E8).withOpacity(0.55),
                  const Color(0xFF2AABCC).withOpacity(0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4DC8E8).withOpacity(0.4),
                  blurRadius: 6),
              ],
            ),
          ),
        ),

        // ── Corps île dessiné ────────────────────────────
        Positioned(
          top: 0, left: 0,
          child: CustomPaint(
            size: Size(width + 40, height + 4),
            painter: _IslandPainter(
              primary: unlocked ? theme.primary : const Color(0xFF9EAFAF),
              dark:    unlocked ? theme.dark    : const Color(0xFF7A9090),
              light:   unlocked ? theme.light   : const Color(0xFFCCDEDE),
              unlocked: unlocked,
            ),
          ),
        ),

        // ── Décoration sur île ─────────────────────────
        if (unlocked) _buildDecorations(),

        // ── Overlay verrou ─────────────────────────────
        if (!unlocked)
          Positioned(
            top: 0, left: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(width * 0.48),
                  bottom: Radius.circular(width * 0.42)),
              child: Container(
                width: width + 40, height: height,
                color: Colors.black.withOpacity(0.28)),
            ),
          ),

        // ── Icône centrale ─────────────────────────────
        Positioned(
          top: height * 0.20,
          left: (width + 40) / 2 - 24,
          child: _buildCenterIcon(),
        ),

        // ── Badge étoiles ───────────────────────────────
        if (unlocked && island.starsEarned > 0)
          Positioned(
            top: -14, right: 0,
            child: _StarsBadge(stars: island.starsEarned),
          ),

        // ── Badge EN COURS ─────────────────────────────
        if (unlocked && island.starsEarned == 0)
          Positioned(
            top: -16, left: 0, right: 40,
            child: Center(child: _ActiveBadge()),
          ),

        // ── Étoiles alignées (progression) ─────────────
        if (unlocked)
          Positioned(
            top: -22, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: i < island.starsEarned
                    ? const Color(0xFFFFD93D)
                    : Colors.white.withOpacity(0.25),
                  shadows: i < island.starsEarned ? const [
                    Shadow(color: Color(0xFFFFD93D), blurRadius: 8),
                  ] : null,
                ),
              )),
            ),
          ),

        // ── Label île ──────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Center(child: _IslandLabel(theme: theme, unlocked: unlocked,
              starsToUnlock: island.starsToUnlock)),
        ),
      ]),
    );
  }

  Widget _buildCenterIcon() {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: unlocked
            ? [Colors.white, const Color(0xFFF8FFF8)]
            : [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.3)],
        ),
        border: Border.all(
          color: unlocked
            ? Colors.white.withOpacity(0.85)
            : Colors.white.withOpacity(0.35),
          width: 2.5,
        ),
        boxShadow: unlocked ? [
          BoxShadow(color: Colors.black.withOpacity(0.25),
              blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.white.withOpacity(0.5),
              blurRadius: 4, offset: const Offset(-1, -1)),
        ] : [],
      ),
      child: Center(
        child: Text(
          unlocked ? theme.emoji : '🔒',
          style: TextStyle(fontSize: unlocked ? 26 : 22),
        ),
      ),
    );
  }

  Widget _buildDecorations() {
    // Chaque île a ses propres décos
    final configs = [
      // Île 1 — Sons : perroquet, palmiers, fleurs
      _DecoConfig(
        leftTree: true, rightTree: true,
        animals: ['🦜', '🎵'],
        flowers: ['🌺', '🌸', '🌼'],
        animalPositions: [const Offset(0.68, 0.06), const Offset(0.32, 0.08)],
        flowerPositions: [const Offset(0.12, 0.72), const Offset(0.82, 0.70), const Offset(0.5, 0.78)],
      ),
      // Île 2 — Lettres : lettres 3D, étoiles de mer
      _DecoConfig(
        leftTree: true, rightTree: false,
        animals: ['⭐', '🐚'],
        flowers: ['🌊', '🐠'],
        animalPositions: [const Offset(0.38, 0.07), const Offset(0.72, 0.10)],
        flowerPositions: [const Offset(0.14, 0.72), const Offset(0.80, 0.70)],
        letters: ['A', 'B', 'C'],
      ),
      // Île 3 — Syllabes : dalles
      _DecoConfig(
        leftTree: true, rightTree: true,
        animals: ['🦋', '🎶'],
        flowers: ['🌸', '🌿'],
        animalPositions: [const Offset(0.65, 0.07), const Offset(0.30, 0.08)],
        flowerPositions: [const Offset(0.12, 0.73), const Offset(0.80, 0.72)],
        syllables: ['ma', 'li'],
      ),
      // Île 4 — Mots : animaux savane
      _DecoConfig(
        leftTree: false, rightTree: false,
        animals: ['🦁', '🐘'],
        flowers: ['📖', '🌵'],
        animalPositions: [const Offset(0.15, 0.08), const Offset(0.72, 0.08)],
        flowerPositions: [const Offset(0.15, 0.73), const Offset(0.78, 0.72)],
      ),
      // Île 5 — Royaume : château
      _DecoConfig(
        leftTree: false, rightTree: false,
        animals: ['🌹', '✨'],
        flowers: ['👑', '🎠'],
        animalPositions: [const Offset(0.15, 0.08), const Offset(0.72, 0.08)],
        flowerPositions: [const Offset(0.15, 0.73), const Offset(0.78, 0.72)],
        castle: true,
      ),
    ];

    final cfg = configs[index.clamp(0, configs.length - 1)];
    final W   = width + 40;
    final H   = height.toDouble();

    return Stack(children: [
      // Arbres
      if (cfg.leftTree)
        Positioned(left: 8, bottom: H * 0.30,
          child: _PalmTree(color: theme.dark, small: false)),
      if (cfg.rightTree)
        Positioned(right: 10, bottom: H * 0.32,
          child: _PalmTree(color: theme.dark.withOpacity(0.85), small: true)),

      // Lettres 3D (île Lettres)
      if (cfg.letters != null)
        ...List.generate(cfg.letters!.length, (i) {
          final xs = [0.12, 0.44, 0.76];
          return Positioned(
            left: W * xs[i],
            top:  H * 0.06,
            child: Text(cfg.letters![i],
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900,
                color: i == 1 ? const Color(0xFFFFD93D) : Colors.white,
                shadows: [
                  Shadow(color: theme.dark, offset: const Offset(2, 2)),
                  const Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                ],
              )),
          );
        }),

      // Dalles syllabes (île Syllabes)
      if (cfg.syllables != null)
        ...List.generate(cfg.syllables!.length, (i) {
          final xs = [0.08, 0.62];
          return Positioned(
            left: W * xs[i], top: H * 0.07,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                boxShadow: [BoxShadow(color: theme.dark.withOpacity(0.3), blurRadius: 4, offset: const Offset(0,2))],
              ),
              child: Text(cfg.syllables![i],
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                    color: theme.dark)),
            ),
          );
        }),

      // Château (île Royaume)
      if (cfg.castle)
        Positioned(
          bottom: H * 0.28, left: W * 0.28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _CastleTower(h: 18, w: 9, color: Colors.white.withOpacity(0.7)),
              _CastleBridge(w: 3, h: 6),
              _CastleTower(h: 26, w: 12, color: Colors.white.withOpacity(0.75)),
              _CastleBridge(w: 3, h: 6),
              _CastleTower(h: 18, w: 9, color: Colors.white.withOpacity(0.7)),
            ],
          ),
        ),

      // Animaux / déco
      ...List.generate(cfg.animals.length, (i) {
        final pos = cfg.animalPositions[i];
        return Positioned(
          left: W * pos.dx, top: H * pos.dy,
          child: Text(cfg.animals[i],
            style: TextStyle(fontSize: index == 0 ? 15 : 13)),
        );
      }),

      // Fleurs
      ...List.generate(cfg.flowers.length, (i) {
        final pos = cfg.flowerPositions[i];
        return Positioned(
          left: W * pos.dx, top: H * pos.dy,
          child: Text(cfg.flowers[i], style: const TextStyle(fontSize: 11)),
        );
      }),

      // Sable doré en bas
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
          child: Container(
            height: H * 0.28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFF5D06A), Color(0xFFE8B030)],
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}


// ══════════════════════════════════════════════════════════════
// PAINTERS
// ══════════════════════════════════════════════════════════════

class _IslandPainter extends CustomPainter {
  final Color   primary, dark, light;
  final bool    unlocked;
  const _IslandPainter({
    required this.primary, required this.dark,
    required this.light,   required this.unlocked});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ombre douce
    final shadowPath = _islandPath(w, h);
    canvas.drawPath(shadowPath,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    // Corps principal
    final bodyPath = _islandPath(w, h);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [light, primary, dark],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(bodyPath, bodyPaint);

    // Lumière dessus
    final topPath = _topLightPath(w, h);
    canvas.drawPath(topPath,
      Paint()..color = Colors.white.withOpacity(0.38));

    // Contour
    canvas.drawPath(_islandPath(w, h),
      Paint()
        ..color = Colors.white.withOpacity(unlocked ? 0.55 : 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
  }

  Path _islandPath(double w, double h) {
    final p = Path();
    p.moveTo(w * 0.10, h * 0.52);
    p.cubicTo(w * -0.02, h * 0.28, w * -0.02, h * 0.08, w * 0.20, h * 0.04);
    p.cubicTo(w * 0.34, h * -0.01, w * 0.56, h * -0.01, w * 0.74, h * 0.04);
    p.cubicTo(w * 0.98, h * 0.08, w * 1.02, h * 0.28, w * 1.00, h * 0.52);
    p.cubicTo(w * 0.98, h * 0.70, w * 0.88, h * 0.85, w * 0.72, h * 0.90);
    p.cubicTo(w * 0.56, h * 0.95, w * 0.36, h * 0.95, w * 0.20, h * 0.90);
    p.cubicTo(w * 0.05, h * 0.85, w * 0.08, h * 0.70, w * 0.10, h * 0.52);
    p.close();
    return p;
  }

  Path _topLightPath(double w, double h) {
    final p = Path();
    p.moveTo(w * 0.10, h * 0.52);
    p.cubicTo(w * -0.02, h * 0.28, w * -0.02, h * 0.08, w * 0.20, h * 0.04);
    p.cubicTo(w * 0.34, h * -0.01, w * 0.56, h * -0.01, w * 0.74, h * 0.04);
    p.cubicTo(w * 0.98, h * 0.08, w * 1.02, h * 0.28, w * 1.00, h * 0.52);
    p.cubicTo(w * 0.96, h * 0.38, w * 0.75, h * 0.30, w * 0.50, h * 0.32);
    p.cubicTo(w * 0.25, h * 0.34, w * 0.08, h * 0.42, w * 0.10, h * 0.52);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(_IslandPainter o) => o.primary != primary;
}

class _PremiumSeaPainter extends CustomPainter {
  final double wave, shimmer;
  const _PremiumSeaPainter({required this.wave, required this.shimmer});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fond marin profond
    final deepRect = Rect.fromLTWH(0, h * 0.12, w, h * 0.88);
    canvas.drawRect(deepRect,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF1A7FA8), Color(0xFF0D5F88), Color(0xFF052E4A)],
        stops: [0, 0.5, 1],
      ).createShader(deepRect));

    // Couche intermédiaire
    _drawWaveLayer(canvas, size, h * 0.14, const Color(0xFF2AABCC), wave, 48, 16);
    // Surface claire
    _drawWaveLayer(canvas, size, h * 0.04, const Color(0xFF4DC8E8), wave, 60, 20);

    // Reflets du soleil
    final shimmerOpacity = 0.15 + shimmer * 0.18;
    final refPaint = Paint()..color = const Color(0xFFFFEE88).withOpacity(shimmerOpacity);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.72, h * 0.08), width: 70, height: 14), refPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.80, h * 0.13), width: 30, height: 7), refPaint);

    // Écume
    _drawFoam(canvas, size, wave);
    // Bulles profondes
    _drawBubbles(canvas, size);
    // Poissons
    _drawFish(canvas, size);
  }

  void _drawWaveLayer(Canvas canvas, Size size, double topY,
      Color color, double wave, double period, double amp) {
    final path = Path();
    path.moveTo(-20, topY);
    for (double x = -20; x <= size.width + period; x += period) {
      path.quadraticBezierTo(
        x + period / 4, topY - amp + wave * amp,
        x + period / 2, topY);
      path.quadraticBezierTo(
        x + 3 * period / 4, topY + amp - wave * amp,
        x + period, topY);
    }
    path.lineTo(size.width + 20, size.height);
    path.lineTo(-20, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawFoam(Canvas canvas, Size size, double wave) {
    final p = Paint()..color = Colors.white.withOpacity(0.28 + wave * 0.12);
    for (double x = 10; x < size.width - 20; x += 65) {
      canvas.drawOval(Rect.fromCenter(
        center: Offset(x + wave * 12, size.height * 0.09),
        width: 52, height: 13), p);
    }
    final p2 = Paint()..color = Colors.white.withOpacity(0.16);
    for (double x = 35; x < size.width; x += 80) {
      canvas.drawOval(Rect.fromCenter(
        center: Offset(x - wave * 8, size.height * 0.16),
        width: 38, height: 9), p2);
    }
  }

  void _drawBubbles(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.18);
    final positions = [
      Offset(size.width * 0.10, size.height * 0.38),
      Offset(size.width * 0.32, size.height * 0.45),
      Offset(size.width * 0.60, size.height * 0.32),
      Offset(size.width * 0.80, size.height * 0.50),
    ];
    final sizes = [7.0, 5.0, 6.0, 4.0];
    for (int i = 0; i < positions.length; i++) {
      canvas.drawCircle(positions[i], sizes[i], p);
    }
  }

  void _drawFish(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final fishEmojis = ['🐠', '🐟', '🐡'];
    final positions  = [
      Offset(size.width * 0.08, size.height * 0.42),
      Offset(size.width * 0.58, size.height * 0.35),
      Offset(size.width * 0.80, size.height * 0.50),
    ];
    final opacities = [0.5, 0.4, 0.45];
    for (int i = 0; i < fishEmojis.length; i++) {
      textPainter.text = TextSpan(
        text: fishEmojis[i],
        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(opacities[i])),
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(positions[i].dx, positions[i].dy);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PremiumSeaPainter o) => o.wave != wave || o.shimmer != shimmer;
}

class _PathPainter extends CustomPainter {
  final int    count;
  final double screenW;
  const _PathPainter({required this.count, required this.screenW});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFFFFE066).withOpacity(0.45)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Centres des îles en zigzag
    final centers = List.generate(count, (i) {
      final isLeft = i % 2 == 0;
      final x = isLeft ? screenW * 0.22 : screenW * 0.63;
      final y = i * 148.0 + 72;
      return Offset(x, y);
    });

    for (int i = 0; i < centers.length - 1; i++) {
      final start = centers[i];
      final end   = centers[i + 1];
      // Glow
      _dashedLine(canvas, start, end, glowPaint);
      // Pointillé blanc
      _dashedLine(canvas, start, end, dotPaint);

      // Étoile au milieu
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      _drawStar(canvas, mid);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint p) {
    const dash = 9.0;
    const gap  = 7.0;
    final dir  = b - a;
    final len  = dir.distance;
    final unit = dir / len;
    double d   = 0;
    while (d < len) {
      canvas.drawLine(a + unit * d, a + unit * (d + dash).clamp(0, len), p);
      d += dash + gap;
    }
  }

  void _drawStar(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 5.5,
      Paint()
        ..color = const Color(0xFFFFE066).withOpacity(0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(center, 3.5,
      Paint()..color = Colors.white.withOpacity(0.95));
  }

  @override
  bool shouldRepaint(_PathPainter o) => false;
}


// ══════════════════════════════════════════════════════════════
// WIDGETS DÉCORATIFS
// ══════════════════════════════════════════════════════════════

class _Sky extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0B3D6E), Color(0xFF1565A8), Color(0xFF2196C8),
          Color(0xFF42B8E0), Color(0xFF78CCEC), Color(0xFFADE6F8),
        ],
        stops: [0.0, 0.15, 0.30, 0.50, 0.70, 1.0],
      ),
    ),
  );
}

class _StarField extends StatelessWidget {
  const _StarField();
  static const _stars = [
    (0.08, 0.04, 2.5), (0.22, 0.09, 1.8), (0.38, 0.03, 2.2),
    (0.52, 0.07, 1.5), (0.66, 0.02, 2.8), (0.80, 0.08, 2.0),
    (0.92, 0.04, 1.6), (0.15, 0.14, 1.4), (0.45, 0.12, 2.0),
    (0.73, 0.15, 1.8), (0.88, 0.11, 1.4), (0.30, 0.18, 1.6),
  ];
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      top: 0, left: 0, right: 0,
      height: size.height * 0.26,
      child: Stack(children: _stars.map((s) => Positioned(
        left: size.width * s.$1,
        top:  size.height * 0.26 * s.$2,
        child: Container(
          width: s.$3, height: s.$3,
          decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Colors.white),
        ),
      )).toList()),
    );
  }
}

class _AuroraLayer extends StatelessWidget {
  const _AuroraLayer();
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      height: MediaQuery.of(context).size.height * 0.28,
      child: Stack(children: [
        Positioned(top: 20, left: -40, right: -40,
          child: Transform.rotate(angle: -0.03,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  const Color(0xFF80FFD4).withOpacity(0.13),
                  const Color(0xFF60C8FF).withOpacity(0.10),
                  Colors.transparent,
                ]),
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),
        ),
        Positioned(top: 55, left: -30, right: -30,
          child: Transform.rotate(angle: 0.02,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  const Color(0xFF60C8FF).withOpacity(0.08),
                  Colors.transparent,
                ]),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SunWidget extends StatelessWidget {
  final double rotation, shimmer;
  const _SunWidget({required this.rotation, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 80, height: 80,
      child: Stack(alignment: Alignment.center, children: [
        // Halo externe
        Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFFFFD93D).withOpacity(0.28 + shimmer * 0.12),
              Colors.transparent,
            ]),
          ),
        ),
        // Rayons
        Transform.rotate(angle: rotation,
          child: CustomPaint(
            size: const Size(80, 80),
            painter: _SunRaysPainter(),
          ),
        ),
        // Corps
        Container(width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.3),
              colors: [Color(0xFFFFF9C4), Color(0xFFFFD93D), Color(0xFFFFA000)],
              stops: [0.0, 0.55, 1.0],
            ),
            border: Border.all(color: const Color(0xFFFFA000), width: 2.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.6),
                  blurRadius: 18, spreadRadius: 4),
            ],
          ),
          child: const Center(child: Text('🌞', style: TextStyle(fontSize: 24))),
        ),
      ]),
    );
  }
}

class _SunRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD93D).withOpacity(0.75)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int i = 0; i < 12; i++) {
      final a  = i * math.pi / 6;
      canvas.drawLine(
        Offset(cx + 28 * math.cos(a), cy + 28 * math.sin(a)),
        Offset(cx + 38 * math.cos(a), cy + 38 * math.sin(a)),
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(_SunRaysPainter o) => false;
}

class _CloudWidget extends StatelessWidget {
  final double left, top, scale;
  const _CloudWidget({required this.left, required this.top, required this.scale});

  @override
  Widget build(BuildContext context) {
    final w = 100.0 * scale;
    final h = 38.0  * scale;
    return Positioned(
      left: left, top: top,
      child: CustomPaint(
        size: Size(w, h),
        painter: _CloudPainter(scale: scale),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  final double scale;
  const _CloudPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ombre douce
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, h * 0.7, w - 4, h * 0.35),
          Radius.circular(h * 0.3)),
      Paint()..color = const Color(0xFFB8D8EE).withOpacity(0.35)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Corps principal
    final p = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFEEF8FF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.35, w, h * 0.65), Radius.circular(h * 0.35)),
      p);
    canvas.drawCircle(Offset(w * 0.25, h * 0.38), h * 0.40, p);
    canvas.drawCircle(Offset(w * 0.52, h * 0.26), h * 0.48, p);
    canvas.drawCircle(Offset(w * 0.76, h * 0.38), h * 0.34, p);

    // Reflet sur le dessus
    canvas.drawCircle(Offset(w * 0.42, h * 0.18),
      h * 0.22,
      Paint()..color = Colors.white.withOpacity(0.7));
  }

  @override
  bool shouldRepaint(_CloudPainter o) => false;
}

class _PalmTree extends StatelessWidget {
  final Color color;
  final bool  small;
  const _PalmTree({required this.color, required this.small});

  @override
  Widget build(BuildContext context) {
    final s = small ? 0.72 : 1.0;
    return Transform.scale(scale: s, alignment: Alignment.bottomCenter,
      child: SizedBox(width: 28, height: 44,
        child: CustomPaint(painter: _PalmPainter(color: color)),
      ),
    );
  }
}

class _PalmPainter extends CustomPainter {
  final Color color;
  const _PalmPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final trunkPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFC49A2A), const Color(0xFF8B6914)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(size.width / 2 - 4, 0, 8, size.height));

    // Tronc légèrement courbé
    final trunk = Path();
    trunk.moveTo(size.width / 2 - 3.5, size.height);
    trunk.cubicTo(
      size.width / 2 - 1, size.height * 0.7,
      size.width / 2 + 2, size.height * 0.4,
      size.width / 2, 0,
    );
    trunk.lineTo(size.width / 2 + 3.5, 0);
    trunk.cubicTo(
      size.width / 2 + 5, size.height * 0.4,
      size.width / 2 + 4, size.height * 0.7,
      size.width / 2 + 3.5, size.height,
    );
    trunk.close();
    canvas.drawPath(trunk, trunkPaint);

    // Feuilles
    final leafPaint = Paint()..color = color;
    final leaves = [
      [-40.0, -20.0, 22.0, 10.0],
      [-15.0, -30.0, 18.0,  9.0],
      [10.0,  -28.0, 20.0,  9.0],
      [28.0,  -18.0, 18.0,  8.0],
      [-25.0, -12.0, 16.0,  8.0],
    ];
    final cx = size.width / 2;
    final cy = 2.0;
    for (final l in leaves) {
      final lp = Path();
      lp.moveTo(cx, cy);
      lp.cubicTo(
        cx + l[0] * 0.4, cy + l[1] * 0.4,
        cx + l[0] * 0.8, cy + l[1] * 0.8 + l[3],
        cx + l[0], cy + l[1],
      );
      lp.cubicTo(
        cx + l[0] + l[2] * 0.3, cy + l[1] + l[3] * 0.5,
        cx + l[2] * 0.2, cy + l[3] * 0.5,
        cx, cy,
      );
      canvas.drawPath(lp, leafPaint);
    }
  }

  @override
  bool shouldRepaint(_PalmPainter o) => o.color != color;
}

class _CastleTower extends StatelessWidget {
  final double h, w;
  final Color  color;
  const _CastleTower({required this.h, required this.w, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: w / 3, height: 4, color: color),
        Container(width: w / 3, height: 4, color: Colors.transparent),
        Container(width: w / 3, height: 4, color: color),
      ]),
      Container(width: w, height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
        ),
      ),
    ]);
  }
}

class _CastleBridge extends StatelessWidget {
  final double w, h;
  const _CastleBridge({required this.w, required this.h});
  @override
  Widget build(BuildContext context) => Container(width: w, height: h, color: Colors.transparent);
}

class _StarsBadge extends StatelessWidget {
  final int stars;
  const _StarsBadge({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFF176), Color(0xFFFFD93D)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFA000), width: 2),
        boxShadow: [BoxShadow(
          color: const Color(0xFFFFD93D).withOpacity(0.55),
          blurRadius: 10, spreadRadius: 1)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, size: 12, color: Color(0xFF7A5200)),
        const SizedBox(width: 2),
        Text('$stars', style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF7A5200))),
      ]),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFF8C6B), Color(0xFFFF5722)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF3D00), width: 2),
        boxShadow: [BoxShadow(
          color: const Color(0xFFFF5722).withOpacity(0.55),
          blurRadius: 10, spreadRadius: 1)],
      ),
      child: const Text('⚡ EN COURS !',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
            color: Colors.white, letterSpacing: 0.5)),
    );
  }
}

class _IslandLabel extends StatelessWidget {
  final IslandTheme theme;
  final bool        unlocked;
  final int         starsToUnlock;
  const _IslandLabel({required this.theme, required this.unlocked,
      required this.starsToUnlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: unlocked
          ? LinearGradient(colors: [theme.primary, theme.dark])
          : const LinearGradient(colors: [Color(0xFF9EAFAF), Color(0xFF7A9090)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2),
              blurRadius: 8, offset: const Offset(0, 3)),
          if (unlocked) BoxShadow(
            color: theme.primary.withOpacity(0.4),
            blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Text(
        unlocked ? theme.name : '🔒 ${theme.name} · $starsToUnlock ⭐',
        style: TextStyle(
          fontSize: unlocked ? 11 : 10,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,1))],
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Config décoration par île ────────────────────────────────
class _DecoConfig {
  final bool         leftTree, rightTree, castle;
  final List<String> animals, flowers;
  final List<Offset> animalPositions, flowerPositions;
  final List<String>? letters, syllables;

  const _DecoConfig({
    required this.leftTree,
    required this.rightTree,
    required this.animals,
    required this.flowers,
    required this.animalPositions,
    required this.flowerPositions,
    this.castle    = false,
    this.letters   = null,
    this.syllables = null,
  });
}