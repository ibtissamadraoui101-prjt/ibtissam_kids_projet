// lib/screens/teacher/teacher_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/student_models.dart';
import '../../services/firebase_service.dart';
import '../../services/progress_service.dart';
import 'teacher_login_screen.dart';
import 'student_detail_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});
  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _firebase  = FirebaseService();
  final _progress  = ProgressService();

  List<Student> _students = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    final teacher = _firebase.currentTeacher;
    List<Student> students = [];

    if (teacher != null) {
      students = await _firebase.getStudentsByClass(teacher.classCode);
    }

    // Ajouter l'élève local si pas déjà dans la liste
    final local = _progress.student;
    if (local != null && !students.any((s) => s.id == local.id)) {
      students.insert(0, local);
    }

    if (mounted) setState(() { _students = students; _loading = false; });
  }

  List<Student> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students.where((s) =>
        s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  // ── Couleur par niveau ────────────────────────
  Color _levelColor(Student s) {
    final stars = s.totalStars;
    if (stars >= 36) return const Color(0xFFC62828);
    if (stars >= 27) return const Color(0xFF6A1B9A);
    if (stars >= 18) return const Color(0xFFE65100);
    if (stars >= 10) return const Color(0xFF2E7D32);
    return const Color(0xFF1565C0);
  }

  String _levelLabel(Student s) {
    final stars = s.totalStars;
    if (stars >= 36) return 'CM2';
    if (stars >= 27) return 'CM1';
    if (stars >= 18) return 'CE2';
    if (stars >= 10) return 'CE1';
    return 'CP';
  }

  @override
  Widget build(BuildContext context) {
    final teacher = _firebase.currentTeacher;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('👩‍🏫 Tableau de Bord',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (teacher != null)
              Text('${teacher.name} — ${teacher.schoolName}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          // Code classe
          if (teacher != null)
            GestureDetector(
              onTap: () => _showClassCode(teacher.classCode),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Code classe',
                        style: TextStyle(fontSize: 9, color: Colors.white70)),
                    Text(teacher.classCode,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold,
                            color: Colors.amber, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _loadStudents,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.people, size: 18), text: 'Élèves'),
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Stats'),
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
                  Text('Chargement...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _buildStudentsTab(),
                _buildStatsTab(),
                _buildDifficultiesTab(),
              ],
            ),
    );
  }

  // ────────────────────────────────────────────────
  // ONGLET 1 : Élèves
  // ────────────────────────────────────────────────
  Widget _buildStudentsTab() {
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Rechercher un élève…',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // Résumé global
        _buildGlobalSummary(),

        // Liste élèves
        Expanded(
          child: _filteredStudents.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _filteredStudents.length,
                  itemBuilder: (_, i) =>
                      _StudentCard(
                        student: _filteredStudents[i],
                        color: _levelColor(_filteredStudents[i]),
                        level: _levelLabel(_filteredStudents[i]),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentDetailScreen(
                              student: _filteredStudents[i],
                            ),
                          ),
                        ),
                      ),
                ),
        ),
      ],
    );
  }

  Widget _buildGlobalSummary() {
    if (_students.isEmpty) return const SizedBox.shrink();

    final totalStars = _students.fold(0, (s, st) => s + st.totalStars);
    final avgStars = (totalStars / _students.length).round();
    final bestStreak = _students
        .map((s) => s.currentStreak)
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 10, offset: const Offset(0, 4),
          )],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem('${_students.length}', 'Élèves', Icons.people),
            _vDivider(),
            _summaryItem('$avgStars ⭐', 'Moy. étoiles', Icons.star),
            _vDivider(),
            _summaryItem('$bestStreak 🔥', 'Meilleure série', Icons.local_fire_department),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String value, String label, IconData icon) => Column(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(
              color: Colors.white60, fontSize: 10)),
        ],
      );

  Widget _vDivider() => Container(
        height: 40, width: 1, color: Colors.white.withOpacity(0.2));

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👥', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text('Aucun élève inscrit.',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            'Partagez le code classe pour que les\nélèves puissent vous rejoindre.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          if (_firebase.currentTeacher != null)
            ElevatedButton.icon(
              onPressed: () =>
                  _showClassCode(_firebase.currentTeacher!.classCode),
              icon: const Icon(Icons.share),
              label: Text(
                  'Code : ${_firebase.currentTeacher!.classCode}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // ONGLET 2 : Statistiques
  // ────────────────────────────────────────────────
  Widget _buildStatsTab() {
    final scores = _progress.allScores;
    if (scores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📊', style: TextStyle(fontSize: 52)),
            SizedBox(height: 12),
            Text('Aucune donnée disponible.',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            SizedBox(height: 8),
            Text('Les statistiques apparaîtront\naprès les premières parties.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    final avgPerLevel = _progress.avgScorePerLevel();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Graphique scores par niveau
        _SectionTitle(title: '📈 Score moyen par niveau', icon: Icons.bar_chart),
        const SizedBox(height: 8),
        _buildBarChart(avgPerLevel),
        const SizedBox(height: 16),

        // Graphique évolution dans le temps
        _SectionTitle(title: '📅 Évolution des 10 dernières parties', icon: Icons.show_chart),
        const SizedBox(height: 8),
        _buildLineChart(scores.reversed.take(10).toList().reversed.toList()),
        const SizedBox(height: 16),

        // Répartition par jeu
        _SectionTitle(title: '🎮 Parties par type de jeu', icon: Icons.pie_chart),
        const SizedBox(height: 8),
        _buildGamePieChart(scores),
        const SizedBox(height: 16),

        // Dernières parties
        _SectionTitle(title: '🕐 Dernières parties', icon: Icons.history),
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
      decoration: _chartDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: entries.asMap().entries.map((e) {
                  final val = e.value.value.clamp(0, 100).toDouble();
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(
                      toY: val,
                      gradient: LinearGradient(
                        colors: val >= 80
                            ? [Colors.green, Colors.lightGreen]
                            : val >= 60
                                ? [Colors.orange, Colors.amber]
                                : [Colors.red, Colors.redAccent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 18,
                      borderRadius: BorderRadius.circular(6),
                    )],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                        final parts = entries[i].key.split('-');
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(parts.length > 1 ? parts[1] : parts[0],
                              style: const TextStyle(fontSize: 9)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}%',
                          style: const TextStyle(fontSize: 9)),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
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

  Widget _buildLineChart(List<GameScore> scores) {
    if (scores.length < 2) {
      return Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: _chartDecoration(),
        child: const Center(child: Text('Pas assez de données')),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: _chartDecoration(),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: scores.asMap().entries.map((e) =>
                  FlSpot(e.key.toDouble(), e.value.percentage)).toList(),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF42A5F5)],
              ),
              barWidth: 3,
              dotData: FlDotData(
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 5,
                  color: const Color(0xFF1A237E),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A237E).withOpacity(0.15),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minY: 0, maxY: 100,
          titlesData: FlTitlesData(
            bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
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
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildGamePieChart(List<GameScore> scores) {
    final counts = <String, int>{};
    for (final s in scores) {
      counts[s.gameType] = (counts[s.gameType] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox.shrink();

    const colors = {
      'memory':   Color(0xFF1565C0),
      'quiz':     Color(0xFF2E7D32),
      'bingo':    Color(0xFF6A1B9A),
      'parcours': Color(0xFFE65100),
    };
    const emojis = {
      'memory': '🃏', 'quiz': '❓', 'bingo': '🎯', 'parcours': '🏆',
    };
    final total = counts.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 160, height: 160,
            child: PieChart(
              PieChartData(
                sections: counts.entries.map((e) {
                  final pct = e.value / total * 100;
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    color: colors[e.key] ?? Colors.grey,
                    title: '${pct.round()}%',
                    titleStyle: const TextStyle(
                        color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.bold),
                    radius: 70,
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: counts.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: colors[e.key] ?? Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${emojis[e.key] ?? ''} ${e.key}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      Text('${e.value}',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // ONGLET 3 : Difficultés
  // ────────────────────────────────────────────────
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mots à retravailler en classe',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      'Ces mots ont le taux de réussite le plus bas. '
                      'Pensez à les réviser oralement avec les élèves.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange[800]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (weak.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Text('🎉', style: TextStyle(fontSize: 40)),
                SizedBox(height: 8),
                Text('Aucune difficulté détectée !',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 4),
                Text('Jouez plus de parties pour voir les stats.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          )
        else ...[
          // Graphique barres taux de réussite
          _SectionTitle(
              title: '📊 Taux de réussite', icon: Icons.analytics),
          const SizedBox(height: 8),
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: _chartDecoration(),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: weak.asMap().entries.map((e) {
                  final rate = (e.value.successRate * 100).clamp(0, 100);
                  final color = rate >= 70 ? Colors.green
                      : rate >= 40 ? Colors.orange : Colors.red;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(
                      toY: rate.toDouble(),
                      color: color,
                      width: 14,
                      borderRadius: BorderRadius.circular(4),
                    )],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i >= weak.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('#${weak[i].wordId}',
                              style: const TextStyle(fontSize: 9)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
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
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Liste détaillée
          _SectionTitle(
              title: '📋 Liste détaillée', icon: Icons.list_alt),
          const SizedBox(height: 8),
          ...weak.asMap().entries.map((e) {
            final stat = e.value;
            final pct  = (stat.successRate * 100).round();
            final color = pct >= 70 ? Colors.green
                : pct >= 40 ? Colors.orange : Colors.red;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6, offset: const Offset(0, 2),
                )],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${e.key + 1}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mot #${stat.wordId}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          '${stat.attempts} essais • ${stat.successes} réussites',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: stat.successRate,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(color),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$pct%',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16, color: color)),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  // ── Helpers ──────────────────────────────────
  BoxDecoration _chartDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, 3),
        )],
      );

  void _showClassCode(String code) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏫', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('Code de la classe',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF1A237E).withOpacity(0.3)),
                ),
                child: Text(code,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A237E),
                      letterSpacing: 6,
                    )),
              ),
              const SizedBox(height: 12),
              Text(
                'Partagez ce code avec vos élèves\npour les relier à votre classe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Déconnexion',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await _firebase.logoutTeacher();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TeacherLoginScreen()),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets réutilisables
// ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A237E)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A237E))),
        ],
      );
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final Color color;
  final String level;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student, required this.color,
    required this.level, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(student.avatarEmoji,
                style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(student.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(level,
                  style: TextStyle(
                      fontSize: 10, color: color,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.star, size: 12, color: Colors.amber),
            Text(' ${student.totalStars}',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Icon(Icons.local_fire_department,
                size: 12, color: Colors.orange),
            Text(' ${student.currentStreak}j',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mini barre de progression
            SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                value: (student.totalStars / 54).clamp(0, 1),
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: Colors.grey),
          ],
        ),
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
          Text(emojis[score.gameType] ?? '🎮',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(score.levelId,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                Text('${score.durationSeconds}s • ${score.errorsCount} erreurs',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${score.percentage.round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: score.percentage >= 80
                        ? Colors.green
                        : score.percentage >= 60
                            ? Colors.orange
                            : Colors.red,
                  )),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => Icon(
                  i < score.stars ? Icons.star : Icons.star_border,
                  size: 12,
                  color: i < score.stars
                      ? Colors.amber : Colors.grey[300],
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}