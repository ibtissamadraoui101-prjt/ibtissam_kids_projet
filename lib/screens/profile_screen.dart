// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'stats_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _cardCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _cardAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _cardCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    )..forward();
    _cardAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (context, _) {
        final student = ProgressService().student;
        if (student == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          body: Stack(
            children: [
              // Fond animé
              AnimatedBuilder(
                animation: _bgAnim,
                builder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(const Color(0xFF0A1628),
                            const Color(0xFF1A237E), _bgAnim.value)!,
                        Color.lerp(const Color(0xFF1565C0),
                            const Color(0xFF0D47A1), _bgAnim.value)!,
                        const Color(0xFF1976D2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              const _BgStars(),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                        child: AnimatedBuilder(
                          animation: _cardAnim,
                          builder: (_, child) => FadeTransition(
                            opacity: _cardAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(_cardAnim),
                              child: child,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildAvatarCard(student, context),
                              const SizedBox(height: 16),
                              _buildStatsRow(student),
                              const SizedBox(height: 16),
                              _buildStreakCard(student),
                              const SizedBox(height: 16),
                              _buildIslandProgress(student),
                              const SizedBox(height: 16),
                              _buildRecentScores(),
                              const SizedBox(height: 16),
                              _buildActions(context),
                            ],
                          ),
                        ),
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          const Text('👤  Mon Profil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              )),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(Student student, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.amber.withOpacity(0.6), width: 3),
                  boxShadow: [BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 20, spreadRadius: 2,
                  )],
                ),
                child: Center(
                  child: Text(student.avatarEmoji,
                      style: const TextStyle(fontSize: 52)),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: () => _editProfile(context, student),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: Colors.amber, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit,
                        color: Colors.black87, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(student.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${student.totalStars} étoiles  •  ${_getLevelLabel(student)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Student student) {
    final scores = ProgressService().allScores;
    final totalGames = scores.length;
    final avgScore = scores.isEmpty
        ? 0
        : (scores.map((s) => s.percentage).reduce((a, b) => a + b) /
                scores.length)
            .round();
    final completedLevels =
        student.levelStars.values.where((s) => s > 0).length;

    return Row(
      children: [
        _StatCard(emoji: '🎮', value: '$totalGames',
            label: 'Parties', color: const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        _StatCard(emoji: '📊', value: '$avgScore%',
            label: 'Moy. score', color: const Color(0xFF2E7D32)),
        const SizedBox(width: 10),
        _StatCard(emoji: '🏆', value: '$completedLevels',
            label: 'Niveaux', color: const Color(0xFF6A1B9A)),
      ],
    );
  }

  Widget _buildStreakCard(Student student) {
    final isHot = student.currentStreak >= 3;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isHot
            ? const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF7043)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: isHot ? null : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHot
              ? Colors.orange.withOpacity(0.5)
              : Colors.white.withOpacity(0.15),
        ),
        boxShadow: isHot
            ? [BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${student.currentStreak} jour${student.currentStreak > 1 ? 's' : ''} de suite !',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
                Text(
                  student.currentStreak == 0
                      ? 'Joue aujourd\'hui pour démarrer ta série !'
                      : student.currentStreak < 3
                          ? 'Continue ! Tu peux faire mieux !'
                          : student.currentStreak < 7
                              ? 'Excellent ! Maintiens ta série !'
                              : '🌟 Incroyable ! Tu es champion !',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('${student.currentStreak}',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 32,
                      fontWeight: FontWeight.w900)),
              Text('jours',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIslandProgress(Student student) {
    final islands = ProgressService().buildIslands();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🗺️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Progression par île',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          ...islands.map((island) => _IslandRow(island: island)),
        ],
      ),
    );
  }

  Widget _buildRecentScores() {
    final scores = ProgressService().recentScores(limit: 5);
    if (scores.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🕐', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Dernières parties',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...scores.map((s) => _ScoreRow(score: s)),
        ],
      ),
    );
  }
  Widget _buildActions(BuildContext context) {
  return Column(
    children: [
      // ── Bouton Statistiques ────────────────────
      _ActionButton(
        icon: Icons.bar_chart,
        label: '📊 Voir mes statistiques',
        color: const Color(0xFF6A1B9A),
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => const StatsScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
      ),
      const SizedBox(height: 10),
      _ActionButton(
        icon: Icons.edit,
        label: 'Modifier mon profil',
        color: const Color(0xFF1565C0),
        onTap: () => _editProfile(context, ProgressService().student!),
      ),
      const SizedBox(height: 10),
      _ActionButton(
        icon: Icons.refresh,
        label: 'Réinitialiser la progression',
        color: Colors.red[700]!,
        onTap: () => _confirmReset(context),
      ),
    ],
  );
}

  void _editProfile(BuildContext context, Student student) {
    final nameCtrl =
        TextEditingController(text: student.name);
    String selectedAvatar = student.avatarEmoji;

    const avatars = [
      '🦁', '🐸', '🦊', '🐧', '🦋',
      '🐬', '🦄', '🦅', '🐼', '🐯',
      '🦉', '🐨', '🦒', '🐙', '🦕',
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✏️ Modifier le profil',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(selectedAvatar,
                    style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: avatars.map((a) {
                    final isSel = a == selectedAvatar;
                    return GestureDetector(
                      onTap: () => setS(() => selectedAvatar = a),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: isSel
                              ? Colors.amber.withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel
                                ? Colors.amber
                                : Colors.white.withOpacity(0.2),
                            width: isSel ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(a,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Ton prénom',
                      labelStyle:
                          TextStyle(color: Colors.white60),
                      prefixIcon: Icon(Icons.person_outline,
                          color: Colors.white60, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Annuler',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          await ProgressService()
                              .updateProfile(name, selectedAvatar);
                          if (ctx.mounted) Navigator.pop(ctx);
                          TtsService().speak('Profil mis à jour !');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Sauvegarder',
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B0000), Color(0xFFC62828)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                'Réinitialiser la progression ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Toutes tes étoiles et tous tes progrès seront perdus. '
                'Cette action est irréversible.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await ProgressService().resetProgress();
                        if (mounted) {
                          Navigator.of(context)
                              .popUntil((r) => r.isFirst);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red[700],
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                      child: const Text('Réinitialiser',
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLevelLabel(Student student) {
    final s = student.totalStars;
    if (s >= 36) return 'CM2 🚀';
    if (s >= 27) return 'CM1 🦋';
    if (s >= 18) return 'CE2 🌳';
    if (s >= 10) return 'CE1 🌿';
    return 'CP 🌱';
  }
}

// ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _StatCard({
    required this.emoji, required this.value,
    required this.label, required this.color,
  });
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10)),
            ],
          ),
        ),
      );
}

class _IslandRow extends StatelessWidget {
  final Island island;
  const _IslandRow({required this.island});

  static const _colors = {
    'CP':  Color(0xFF1565C0),
    'CE1': Color(0xFF2E7D32),
    'CE2': Color(0xFFE65100),
    'CM1': Color(0xFF6A1B9A),
    'CM2': Color(0xFFC62828),
  };

  @override
  Widget build(BuildContext context) {
    final color  = _colors[island.label] ?? Colors.grey;
    final locked = !island.isUnlocked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(locked ? '🔒' : island.emoji,
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(island.label,
              style: TextStyle(
                  color: locked
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: locked ? 0 : island.completionRate,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(
                    locked ? Colors.grey.withOpacity(0.3) : color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            locked
                ? '🔒 ${island.starsToUnlock}⭐'
                : '${island.starsEarned}/${island.totalLevels * 3}⭐',
            style: TextStyle(
                color: locked
                    ? Colors.white.withOpacity(0.3)
                    : Colors.amber,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final GameScore score;
  const _ScoreRow({required this.score});
  @override
  Widget build(BuildContext context) {
    const emojis = {
      'memory': '🃏', 'quiz': '❓',
      'bingo': '🎯', 'parcours': '🏆',
    };
    final color = score.percentage >= 80
        ? Colors.greenAccent
        : score.percentage >= 60
            ? Colors.amber
            : Colors.redAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emojis[score.gameType] ?? '🎮',
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(score.levelId,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text(
                  '${score.durationSeconds}s  •  ${score.errorsCount} erreur(s)',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${score.percentage.round()}%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => Icon(
                  i < score.stars ? Icons.star : Icons.star_border,
                  size: 11,
                  color: i < score.stars
                      ? Colors.amber
                      : Colors.white.withOpacity(0.2),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.5), size: 14),
            ],
          ),
        ),
      );
}

class _BgStars extends StatelessWidget {
  const _BgStars();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _StarPainter());
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.25);
    final rng = math.Random(42);
    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width,
            rng.nextDouble() * size.height * 0.5),
        1.2, p,
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}