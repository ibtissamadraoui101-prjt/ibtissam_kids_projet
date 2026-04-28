// lib/screens/world_map_screen.dart
import 'package:flutter/material.dart';
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'island_levels_screen.dart';
import 'profile_screen.dart';
import 'teacher/teacher_login_screen.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});
  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveCtrl;
  late AnimationController _starCtrl;
  late Animation<double> _waveAnim;
  late Animation<double> _starAnim;
  int _lastStars = 0;

  @override
  void initState() {
    super.initState();
    _lastStars = ProgressService().student?.totalStars ?? 0;

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _waveAnim = CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut);

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _starAnim = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _starCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (context, _) {
        // Animation étoiles si gain
        final cur = ProgressService().student?.totalStars ?? 0;
        if (cur > _lastStars) {
          _lastStars = cur;
          _starCtrl.forward(from: 0);
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A1628),
                  Color(0xFF0D47A1),
                  Color(0xFF1565C0),
                  Color(0xFF1E88E5),
                ],
                stops: [0.0, 0.25, 0.65, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                const _OceanWaves(),
                const _StarField(),
                SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(),
                      Expanded(child: _buildIslandList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // BARRE DU HAUT
  // ─────────────────────────────────────────────
  Widget _buildTopBar() {
    final student = ProgressService().student;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [

          // ── Avatar → ouvre le profil ───────────
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, anim, __) => const ProfileScreen(),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.6),
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      student?.avatarEmoji ?? '🦁',
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                // Petit badge profil
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.person,
                        color: Colors.black87, size: 10),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Nom + streak ────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student != null
                      ? 'Bonjour, ${student.name} !'
                      : 'LinguaKids Maroc',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if ((student?.currentStreak ?? 0) >= 1)
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 13),
                      const SizedBox(width: 2),
                      Text(
                        '${student!.currentStreak} jour(s) 🔥',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Compteur étoiles (animé) ─────────────
          AnimatedBuilder(
            animation: _starAnim,
            builder: (_, __) => Transform.scale(
              scale: _starAnim.value,
              child: GestureDetector(
                onTap: () {
                  // Tap étoiles → ouvre aussi le profil
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.amber.withOpacity(0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 17),
                      const SizedBox(width: 4),
                      Text(
                        '${student?.totalStars ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Bouton espace enseignant ─────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TeacherLoginScreen()),
            ),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25)),
              ),
              child: const Icon(Icons.school_outlined,
                  color: Colors.white, size: 19),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LISTE DES ÎLES
  // ─────────────────────────────────────────────
  Widget _buildIslandList() {
    final islands = ProgressService().buildIslands();

    return AnimatedBuilder(
      animation: _waveAnim,
      builder: (_, __) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: islands.length,
        itemBuilder: (ctx, i) => _IslandCard(
          island: islands[i],
          waveValue: _waveAnim.value,
          delay: i * 0.18,
          onTap: () {
            if (!islands[i].isUnlocked) {
              _showLocked(ctx, islands[i]);
              return;
            }
            TtsService().speak('Île ${islands[i].label} !');
            Navigator.push(
              ctx,
              PageRouteBuilder(
                pageBuilder: (_, anim, __) =>
                    IslandLevelsScreen(niveauLabel: islands[i].label),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLocked(BuildContext ctx, Island island) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          '🔒 Il te faut ${island.starsToUnlock} ⭐ pour débloquer ${island.label} !',
        ),
        backgroundColor: Colors.grey[850],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Carte d'une île
// ─────────────────────────────────────────────────────────────
class _IslandCard extends StatelessWidget {
  final Island island;
  final double waveValue;
  final double delay;
  final VoidCallback onTap;

  const _IslandCard({
    required this.island,
    required this.waveValue,
    required this.delay,
    required this.onTap,
  });

  static const Map<String, List<Color>> _gradients = {
    'CP':  [Color(0xFF1565C0), Color(0xFF2196F3), Color(0xFF42A5F5)],
    'CE1': [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF66BB6A)],
    'CE2': [Color(0xFFBF360C), Color(0xFFE64A19), Color(0xFFFF7043)],
    'CM1': [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFFAB47BC)],
    'CM2': [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFEF5350)],
  };

  double _sin(double x) {
    final v = x % 6.28318;
    return v < 3.14159
        ? 4 * v * (3.14159 - v) / 9.8696
        : -4 * (v - 3.14159) * (v - 6.28318) / 9.8696;
  }

  @override
  Widget build(BuildContext context) {
    final locked = !island.isUnlocked;
    final colors = _gradients[island.label] ??
        [const Color(0xFF37474F), const Color(0xFF546E7A), Colors.grey];
    final t = (waveValue + delay) % 1.0;
    final bob = locked ? 0.0 : _sin(t * 6.28) * 4.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: locked ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: locked
                    ? [const Color(0xFF263238), const Color(0xFF37474F)]
                    : colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: locked
                  ? []
                  : [
                      BoxShadow(
                        color: colors[0].withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Île flottante
                Transform.translate(
                  offset: Offset(0, bob),
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        locked ? '🔒' : island.emoji,
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(island.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              )),
                          const SizedBox(width: 8),
                          if (!locked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${island.totalLevels} niveaux',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locked
                            ? '🌟 ${island.starsToUnlock} étoiles nécessaires'
                            : island.tagline,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12),
                      ),
                      if (!locked) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: island.completionRate,
                            minHeight: 8,
                            backgroundColor:
                                Colors.white.withOpacity(0.2),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              '${(island.completionRate * 100).round()}% complété',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                island.totalLevels * 3,
                                (i) => Icon(
                                  i < island.starsEarned
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 12,
                                  color: i < island.starsEarned
                                      ? Colors.amber
                                      : Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!locked)
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.7), size: 17),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Étoiles décoratives
// ─────────────────────────────────────────────────────────────
class _StarField extends StatelessWidget {
  const _StarField();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _StarPainter());
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.45);
    const pts = [
      [.05,.06],[.15,.02],[.28,.09],[.42,.04],[.57,.07],[.71,.03],
      [.85,.08],[.92,.05],[.08,.16],[.22,.20],[.36,.13],[.50,.18],
      [.64,.14],[.78,.19],[.94,.11],[.03,.28],[.17,.32],[.31,.26],
      [.45,.30],[.59,.24],[.73,.29],[.88,.27],[.11,.40],[.25,.44],
      [.39,.38],[.53,.43],[.67,.37],[.81,.42],[.95,.39],
    ];
    for (final pt in pts) {
      canvas.drawCircle(
          Offset(size.width * pt[0], size.height * pt[1]), 1.3, p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
// Vagues décoratives
// ─────────────────────────────────────────────────────────────
class _OceanWaves extends StatelessWidget {
  const _OceanWaves();
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Opacity(
        opacity: 0.06,
        child: CustomPaint(
          size: const Size(double.infinity, 100),
          painter: _WavePainter(),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.lightBlue
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, 50);
    for (double x = 0; x <= size.width; x += 8) {
      final y = 50 + 18 * _sin(x / 55);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, p);
  }

  double _sin(double x) {
    final v = x % 6.28318;
    return v < 3.14159
        ? 4 * v * (3.14159 - v) / 9.8696
        : -4 * (v - 3.14159) * (v - 6.28318) / 9.8696;
  }

  @override
  bool shouldRepaint(_) => false;
}