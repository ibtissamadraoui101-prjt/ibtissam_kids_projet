// lib/screens/teacher/student_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/student_models.dart';
import '../../services/firebase_service.dart';
import '../../services/progress_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  const StudentDetailScreen({super.key, required this.student});
  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  List<GameScore> _scores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    setState(() => _loading = true);
    List<GameScore> scores = [];

    // Essayer Firestore d'abord
    scores = await FirebaseService().getScoresForStudent(widget.student.id);

    // Fallback : données locales si c'est l'élève courant
    if (scores.isEmpty) {
      scores = ProgressService()
          .allScores
          .where((s) => s.studentId == widget.student.id)
          .toList();
    }

    if (mounted) setState(() { _scores = scores; _loading = false; });
  }

  Color get _levelColor {
    final s = widget.student.totalStars;
    if (s >= 36) return const Color(0xFFC62828);
    if (s >= 27) return const Color(0xFF6A1B9A);
    if (s >= 18) return const Color(0xFFE65100);
    if (s >= 10) return const Color(0xFF2E7D32);
    return const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(
        slivers: [
          // ── En-tête élève ──────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _levelColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_levelColor, _levelColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: Center(
                          child: Text(widget.student.avatarEmoji,
                              style: const TextStyle(fontSize: 40)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.student.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 16),
                          Text(' ${widget.student.totalStars} étoiles',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                          const SizedBox(width: 16),
                          const Icon(Icons.local_fire_department,
                              color: Colors.orange, size: 16),
                          Text(' ${widget.student.currentStreak} jours',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Contenu ───────────────────────────────
          SliverToBoxAdapter(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats rapides
                        _buildQuickStats(),
                        const SizedBox(height: 16),

                        // Progression par île
                        _buildIslandProgress(),
                        const SizedBox(height: 16),

                        // Graphique performances
                        if (_scores.isNotEmpty) ...[
                          _buildPerformanceChart(),
                          const SizedBox(height: 16),
                        ],

                        // Historique parties
                        _buildHistory(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final avgScore = _scores.isEmpty
        ? 0.0
        : _scores.map((s) => s.percentage).reduce((a, b) => a + b) /
            _scores.length;
    final totalErrors = _scores.fold(0, (s, g) => s + g.errorsCount);
    final totalTime = _scores.fold(0, (s, g) => s + g.durationSeconds);

    return Row(
      children: [
        _QuickStatCard(
          icon: '🎮',
          value: '${_scores.length}',
          label: 'Parties jouées',
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 10),
        _QuickStatCard(
          icon: '📊',
          value: '${avgScore.round()}%',
          label: 'Score moyen',
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(width: 10),
        _QuickStatCard(
          icon: '⏱',
          value: '${(totalTime / 60).round()}min',
          label: 'Temps total',
          color: const Color(0xFF6A1B9A),
        ),
      ],
    );
  }

  Widget _buildIslandProgress() {
    const islandConfig = [
      ('CP',  '🌱', Color(0xFF1565C0),  0,  6,
        ['cp-w1-alpha','cp-w2-numbers','cp-w3-colors',
         'cp-w4-greet','cp-w5-animals1','cp-w6-animals2']),
      ('CE1', '🌿', Color(0xFF2E7D32), 10,  3,
        ['ce1-t1','ce1-t2','ce1-t3']),
      ('CE2', '🌳', Color(0xFFE65100), 18,  3,
        ['ce2-t1','ce2-t2','ce2-t3']),
      ('CM1', '🦋', Color(0xFF6A1B9A), 27,  3,
        ['cm1-t1','cm1-t2','cm1-t3']),
      ('CM2', '🚀', Color(0xFFC62828), 36,  3,
        ['cm2-t1','cm2-t2','cm2-t3']),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map, color: Color(0xFF1A237E), size: 18),
              SizedBox(width: 8),
              Text('Progression par île',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15, color: Color(0xFF1A237E))),
            ],
          ),
          const SizedBox(height: 14),
          ...islandConfig.map((c) {
            final earned = (c.$6 as List<String>).fold(0, (sum, id) =>
                sum + (widget.student.levelStars[id] ?? 0));
            final maxStars = (c.$5 as int) * 3;
            final rate = maxStars == 0 ? 0.0 : earned / maxStars;
            final isUnlocked = widget.student.totalStars >= (c.$4 as int)
                || c.$1 == 'CP';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(c.$2 as String,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(c.$1 as String,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isUnlocked
                              ? (c.$3 as Color) : Colors.grey)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: isUnlocked ? rate : 0,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                            isUnlocked ? (c.$3 as Color) : Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUnlocked ? '$earned / $maxStars ⭐' : '🔒',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? Colors.amber[700] : Colors.grey),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final recent = _scores.reversed.take(10).toList().reversed.toList();
    if (recent.length < 2) return const SizedBox.shrink();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.show_chart, color: _levelColor, size: 18),
            const SizedBox(width: 8),
            Text('Évolution des scores',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 14, color: _levelColor)),
          ]),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: recent.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(), e.value.percentage)).toList(),
                    isCurved: true,
                    color: _levelColor,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                        radius: 4, color: _levelColor,
                        strokeWidth: 2, strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _levelColor.withOpacity(0.08),
                    ),
                  ),
                ],
                minY: 0, maxY: 100,
                titlesData: FlTitlesData(
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 30,
                      getTitlesWidget: (v, _) =>
                          Text('${v.toInt()}%',
                              style: const TextStyle(fontSize: 9)),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.history, color: _levelColor, size: 18),
            const SizedBox(width: 8),
            Text('Historique des parties',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 14, color: _levelColor)),
          ]),
          const SizedBox(height: 12),
          if (_scores.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const Text('🎮', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text('Aucune partie jouée',
                      style: TextStyle(color: Colors.grey[500])),
                ]),
              ),
            )
          else
            ..._scores.reversed.take(20).map((s) {
              const emojis = {
                'memory': '🃏', 'quiz': '❓',
                'bingo': '🎯', 'parcours': '🏆',
              };
              final color = s.percentage >= 80 ? Colors.green
                  : s.percentage >= 60 ? Colors.orange : Colors.red;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(emojis[s.gameType] ?? '🎮',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.levelId,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                          Text(
                            '${_formatDate(s.playedAt)}  •  ${s.durationSeconds}s',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${s.percentage.round()}%',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, color: color)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) => Icon(
                            i < s.stars ? Icons.star : Icons.star_border,
                            size: 11,
                            color: i < s.stars
                                ? Colors.amber : Colors.grey[300],
                          )),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2,'0')}/'
      '${dt.month.toString().padLeft(2,'0')} '
      '${dt.hour.toString().padLeft(2,'0')}:'
      '${dt.minute.toString().padLeft(2,'0')}';
}

// ─────────────────────────────────────────────────────────────
class _QuickStatCard extends StatelessWidget {
  final String icon, value, label;
  final Color color;
  const _QuickStatCard({
    required this.icon, required this.value,
    required this.label, required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2),
            )],
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, color: color)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      );
}