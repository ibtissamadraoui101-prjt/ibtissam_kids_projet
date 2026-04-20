// lib/screens/world_map_screen.dart
// La carte principale avec les 5 îles animées
// Utilisé par : main.dart (écran d'accueil)

import 'package:flutter/material.dart';
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'niveaux_screen.dart';
import 'teacher/teacher_login_screen.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveCtrl;
  late Animation<double> _waveAnim;
  late AnimationController _starCtrl;
  late Animation<double> _starAnim;
  // Pour l'animation "nouvelle étoile gagnée"
  int _lastTotalStars = 0;

  @override
  void initState() {
    super.initState();
    _lastTotalStars = ProgressService().student?.totalStars ?? 0;

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _waveAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut),
    );

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _starAnim = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _starCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  void _checkNewStars() {
    final current = ProgressService().student?.totalStars ?? 0;
    if (current > _lastTotalStars) {
      _lastTotalStars = current;
      _starCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkNewStars());
        final student = ProgressService().student;
        final islands = ProgressService().buildIslands();

        return Scaffold(
          body: Stack(
            children: [
              // Fond océan avec dégradé
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0A1929),
                      Color(0xFF0D47A1),
                      Color(0xFF1565C0),
                      Color(0xFF1976D2),
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Étoiles de fond (décoratives)
              const _StarField(),
              // Contenu principal
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(student),
                    Expanded(
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: islands.length,
                        itemBuilder: (ctx, i) {
                          return AnimatedBuilder(
                            animation: _waveAnim,
                            builder: (_, __) => _IslandCard(
                              island: islands[i],
                              waveValue: _waveAnim.value,
                              animationDelay: i * 0.15,
                              onTap: islands[i].isUnlocked
                                  ? () {
                                      TtsService().speak(
                                        'Île ${islands[i].label} !',
                                      );
                                      Navigator.push(
                                        ctx,
                                        _slideRoute(
                                          SubLevelsScreen(
                                            niveau: islands[i].label,
                                          ),
                                        ),
                                      );
                                    }
                                  : () => _showLockedMessage(
                                        ctx,
                                        islands[i],
                                      ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Student? student) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {}, // TODO: profil élève
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  student?.avatarEmoji ?? '🦁',
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nom + streak
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (student != null && student.currentStreak >= 1)
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 13,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${student.currentStreak} jour(s) 🔥',
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
          // Étoiles totales (avec animation au gain)
          AnimatedBuilder(
            animation: _starAnim,
            builder: (_, __) => Transform.scale(
              scale: _starAnim.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${student?.totalStars ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton espace enseignant
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherLoginScreen(),
              ),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedMessage(BuildContext ctx, Island island) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🔒 ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                'Il te faut ${island.starsToUnlock} ⭐ pour débloquer ${island.label} !',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[850],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, anim, __) => page,
      transitionsBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

// ─────────────────────────────────────────────
// Widget île avec animation
// ─────────────────────────────────────────────
class _IslandCard extends StatelessWidget {
  final Island island;
  final double waveValue;
  final double animationDelay;
  final VoidCallback? onTap;

  double _sin(double x) {
  x = x % (2 * 3.14159);
  if (x < 3.14159) {
    return 4 * x * (3.14159 - x) / (3.14159 * 3.14159);
  } else {
    return -4 * (x - 3.14159) * (x - 2 * 3.14159) / (3.14159 * 3.14159);
  }
}

  const _IslandCard({
    required this.island,
    required this.waveValue,
    required this.animationDelay,
    this.onTap,
  });

  static const Map<String, List<Color>> _gradients = {
    'CP':  [Color(0xFF1565C0), Color(0xFF2196F3), Color(0xFF42A5F5)],
    'CE1': [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF66BB6A)],
    'CE2': [Color(0xFFBF360C), Color(0xFFE64A19), Color(0xFFFF7043)],
    'CM1': [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFFAB47BC)],
    'CM2': [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFEF5350)],
  };

  @override
  Widget build(BuildContext context) {
    final locked = !island.isUnlocked;
    final colors = _gradients[island.label] ??
        [const Color(0xFF37474F), const Color(0xFF546E7A), Colors.grey];
    // Décalage de vague unique par île
    final wave = locked ? 0.0 : (waveValue + animationDelay) % 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
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
                  // Île avec animation flottante
                  Transform.translate(
                    offset:
                        Offset(0, locked ? 0 : _sin(wave * 2 * 3.14159) * 4),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          locked ? '🔒' : island.emoji,
                          style: const TextStyle(fontSize: 36),
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
                            Text(
                              island.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!locked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${island.totalLevels} niveaux',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          locked
                              ? '🌟 ${island.starsToUnlock} étoiles pour débloquer'
                              : island.tagline,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                        if (!locked) ...[
                          const SizedBox(height: 10),
                          // Barre de progression
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: island.completionRate,
                              minHeight: 8,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${(island.completionRate * 100).round()}% complété',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                              const Spacer(),
                              // Étoiles gagnées
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  island.totalLevels * 3,
                                  (i) => Icon(
                                    i < island.starsEarned
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 13,
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
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.7),
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension pour sin (nécessaire pour l'animation)
extension _DoubleExt on double {
  double get sin {
    // Approximation simple de sin pour animation
    final x = this % (2 * 3.14159);
    return x < 3.14159
        ? 4 * x * (3.14159 - x) / (3.14159 * 3.14159)
        : -4 * (x - 3.14159) * (x - 2 * 3.14159) / (3.14159 * 3.14159);
  }
}

// ─────────────────────────────────────────────
// Champ d'étoiles décoratif
// ─────────────────────────────────────────────
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _StarPainter(),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5);
    // 50 étoiles fixes décoratives
    final positions = [
      [0.05, 0.08], [0.15, 0.03], [0.25, 0.12], [0.35, 0.05],
      [0.45, 0.09], [0.55, 0.02], [0.65, 0.07], [0.75, 0.04],
      [0.85, 0.11], [0.92, 0.06], [0.08, 0.18], [0.18, 0.22],
      [0.28, 0.16], [0.38, 0.20], [0.48, 0.14], [0.58, 0.19],
      [0.68, 0.15], [0.78, 0.21], [0.88, 0.17], [0.95, 0.23],
      [0.03, 0.30], [0.12, 0.35], [0.22, 0.28], [0.32, 0.33],
      [0.42, 0.27], [0.52, 0.32], [0.62, 0.26], [0.72, 0.31],
      [0.82, 0.29], [0.90, 0.34], [0.07, 0.42], [0.17, 0.45],
      [0.27, 0.40], [0.37, 0.44], [0.47, 0.38], [0.57, 0.43],
      [0.67, 0.39], [0.77, 0.46], [0.87, 0.41], [0.94, 0.48],
      [0.02, 0.55], [0.11, 0.60], [0.21, 0.53], [0.31, 0.58],
      [0.41, 0.52], [0.51, 0.57], [0.61, 0.51], [0.71, 0.56],
      [0.81, 0.54], [0.91, 0.59],
    ];
    for (final pos in positions) {
      canvas.drawCircle(
        Offset(size.width * pos[0], size.height * pos[1]),
        1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}