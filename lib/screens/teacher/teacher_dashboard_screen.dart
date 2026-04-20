// lib/screens/teacher/teacher_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/student_models.dart';
import '../../services/firebase_service.dart';
import '../../services/progress_service.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _firebase = FirebaseService();
  final _progress = ProgressService();

  List<Student> _students = [];
  Student? _selectedStudent;
  List<GameScore> _selectedStudentScores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final teacher = _firebase.currentTeacher;
    if (teacher != null) {
      final students = await _firebase.getStudentsByClass(teacher.classCode);
      setState(() {
        _students = students;
        // Ajouter l'élève local si disponible
        final local = _progress.student;
        if (local != null && !students.any((s) => s.id == local.id)) {
          _students.insert(0, local);
        }
        _loading = false;
      });
    } else {
      // Mode hors ligne : afficher uniquement l'élève local
      final local = _progress.student;
      setState(() {
        if (local != null) _students = [local];
        _loading = false;
      });
    }
  }

  Future<void> _loadStudentScores(Student student) async {
    final scores = await _firebase.getScoresForStudent(student.id);
    setState(() {
      _selectedStudent = student;
      _selectedStudentScores = scores.isNotEmpty
          ? scores
          : _progress.allScores
              .where((s) => s.studentId == student.id)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final teacher = _firebase.currentTeacher;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👩‍🏫 Tableau de Bord',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (teacher != null)
              Text(
                '${teacher.name} — ${teacher.schoolName}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (teacher != null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Code classe',
                    style: TextStyle(fontSize: 9, color: Colors.white70),
                  ),
                  Text(
                    teacher.classCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _firebase.logoutTeacher();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.people, size: 18), text: 'Élèves'),
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Progrès'),
            Tab(icon: Icon(Icons.warning_amber, size: 18), text: 'Difficultés'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1A237E)),
                  SizedBox(height: 16),
                  Text('Chargement des données...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _buildStudentsTab(),
                _buildProgressTab(),
                _buildDifficultiesTab(),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────
  // ONGLET 1 : Liste des élèves
  // ─────────────────────────────────────────────
  Widget _buildStudentsTab() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            const Text(
              'Aucun élève inscrit.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Partagez le code classe pour que les élèves\npuissent vous rejoindre.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Résumé global
        _buildGlobalSummaryCard(),
        const SizedBox(height: 16),
        Text(
          '${_students.length} élève(s)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        ..._students.map(
          (s) => _StudentListTile(
            student: s,
            isSelected: _selectedStudent?.id == s.id,
            onTap: () async {
              await _loadStudentScores(s);
              _tabs.animateTo(1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalSummaryCard() {
    final totalStars = _students.fold(0, (s, st) => s + st.totalStars);
    final avgStars = _students.isEmpty
        ? 0
        : (totalStars / _students.length).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBox('${_students.length}', 'Élèves', Icons.people),
          _divider(),
          _statBox('$avgStars ⭐', 'Moy. étoiles', Icons.star),
          _divider(),
          _statBox(
            _students.isNotEmpty
                ? _students
                    .map((s) => s.currentStreak)
                    .reduce((a, b) => a > b ? a : b)
                    .toString()
                : '0',
            'Meilleure série',
            Icons.local_fire_department,
          ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, IconData icon) => Column(
        children: [
          Icon(icon, color: Colors.amber, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      );

  Widget _divider() => Container(
        height: 50,
        width: 1,
        color: Colors.white.withOpacity(0.2),
      );

  // ─────────────────────────────────────────────
  // ONGLET 2 : Graphiques de progression
  // ─────────────────────────────────────────────
  Widget _buildProgressTab() {
    final scores = _selectedStudent != null
        ? _selectedStudentScores
        : _progress.allScores;

    final studentName =
        _selectedStudent?.name ?? _progress.student?.name ?? 'Élève';

    if (scores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📊', style: TextStyle(fontSize: 52)),
            SizedBox(height: 16),
            Text('Aucune partie jouée encore.'),
          ],
        ),
      );
    }

    // Grouper scores par niveau
    final byLevel = <String, List<GameScore>>{};
    for (final s in scores) {
      byLevel.putIfAbsent(s.levelId, () => []).add(s);
    }

    // Score moyen par niveau
    final avgByLevel = byLevel.map((k, v) {
      final avg = v.map((s) => s.percentage).reduce((a, b) => a + b) / v.length;
      return MapEntry(k, avg);
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sélecteur élève
        if (_students.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Student>(
                value: _selectedStudent,
                hint: const Text('Sélectionner un élève'),
                isExpanded: true,
                items: _students
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Text(s.avatarEmoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(s.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (s) {
                  if (s != null) _loadStudentScores(s);
                },
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Titre
        Text(
          'Progression de $studentName',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 12),
        // Graphique barres — score moyen par niveau
        _buildBarChart(avgByLevel),
        const SizedBox(height: 16),
        // Graphique ligne — évolution dans le temps (10 dernières parties)
        _buildLineChart(scores.reversed.take(10).toList().reversed.toList()),
        const SizedBox(height: 16),
        // Liste dernières parties
        const Text(
          'Dernières parties',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        ...scores.reversed.take(15).map((s) => _ScoreRow(score: s)),
      ],
    );
  }

  Widget _buildBarChart(Map<String, double> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    final entries = data.entries.toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score moyen par niveau',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: entries.asMap().entries.map((e) {
                  final val = e.value.value;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: val >= 80
                            ? Colors.green
                            : val >= 60
                                ? Colors.orange
                                : Colors.red,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        // Afficher seulement le niveau (ex: "cp-w1" → "w1")
                        final parts = entries[i].key.split('-');
                        final short = parts.length > 1 ? parts[1] : parts[0];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            short,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}%',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<GameScore> recent) {
    if (recent.length < 2) return const SizedBox.shrink();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évolution des scores (10 dernières parties)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: recent.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value.percentage,
                      );
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF1A237E),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF1A237E),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1A237E).withOpacity(0.08),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
                titlesData: FlTitlesData(
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}%',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ONGLET 3 : Mots difficiles
  // ─────────────────────────────────────────────
  Widget _buildDifficultiesTab() {
    final weak = _progress.weakestWords(top: 10);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Alerte pédagogique
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mots à retravailler en classe',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Ces mots ont le taux de réussite le plus bas. '
                      'Pensez à les réviser oralement.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (weak.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Pas assez de données.\nJouez plus de parties !',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

        // Graphique radar (taux de réussite par mot)
        if (weak.isNotEmpty) ...[
          _buildWeakWordsChart(weak),
          const SizedBox(height: 16),
          // Liste détaillée
          ...weak.asMap().entries.map((e) {
            final i = e.key;
            final stat = e.value;
            final pct = (stat.successRate * 100).round();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _colorForRate(stat.successRate).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  // Rang
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _colorForRate(stat.successRate).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _colorForRate(stat.successRate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mot #${stat.wordId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${stat.attempts} essais • ${stat.successes} réussites',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Barre de succès
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _colorForRate(stat.successRate),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 80,
                        child: LinearProgressIndicator(
                          value: stat.successRate,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _colorForRate(stat.successRate),
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildWeakWordsChart(List<WordStat> stats) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Taux de réussite — mots difficiles',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: stats.asMap().entries.map((e) {
                  final rate = e.value.successRate * 100;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: rate,
                        color: _colorForRate(e.value.successRate),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= stats.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '#${stats[i].wordId}',
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForRate(double rate) {
    if (rate >= 0.7) return Colors.green;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }
}

// ─────────────────────────────────────────────
// Widgets réutilisables
// ─────────────────────────────────────────────
class _StudentListTile extends StatelessWidget {
  final Student student;
  final bool isSelected;
  final VoidCallback onTap;

  const _StudentListTile({
    required this.student,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1A237E).withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF1A237E).withOpacity(0.4)
              : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              student.avatarEmoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.star, size: 12, color: Colors.amber),
            const SizedBox(width: 2),
            Text(
              '${student.totalStars} étoiles',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.local_fire_department,
              size: 12,
              color: Colors.orange,
            ),
            const SizedBox(width: 2),
            Text(
              '${student.currentStreak} j.',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              student.currentLevel.name.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1A237E),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  GameLevel get currentLevel => student.currentLevel;
}

// Propriété manquante sur Student — niveau actuel calculé
extension on Student {
  GameLevel get currentLevel {
    if (totalStars >= 36) return GameLevel.cm2;
    if (totalStars >= 27) return GameLevel.cm1;
    if (totalStars >= 18) return GameLevel.ce2;
    if (totalStars >= 10) return GameLevel.ce1;
    return GameLevel.cp;
  }
}

enum GameLevel { cp, ce1, ce2, cm1, cm2 }

class _ScoreRow extends StatelessWidget {
  final GameScore score;
  const _ScoreRow({required this.score});

  @override
  Widget build(BuildContext context) {
    final emoji = switch (score.gameType) {
      'memory'   => '🃏',
      'quiz'     => '❓',
      'bingo'    => '🎯',
      'parcours' => '🏆',
      _          => '🎮',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score.levelId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${score.durationSeconds}s • ${score.errorsCount} erreurs',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.percentage.round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: score.percentage >= 80
                      ? Colors.green
                      : score.percentage >= 60
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < score.stars ? Icons.star : Icons.star_border,
                    size: 12,
                    color:
                        i < score.stars ? Colors.amber : Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}