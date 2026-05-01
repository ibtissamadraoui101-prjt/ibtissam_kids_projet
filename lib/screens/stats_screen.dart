// lib/screens/stats_screen.dart
// Statistiques avancées de l'élève :
// - Graphiques d'évolution des scores
// - Répartition par jeu et par niveau
// - Heatmap d'activité hebdomadaire
// - Points forts / points faibles
// - Mots à réviser (SM-2)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../models/student_models.dart';
import '../services/progress_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF0D2137),
              Color(0xFF1565C0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _ProgressTab(),
                    _GamesTab(),
                    _WeakWordsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊  Mes Statistiques',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              Text('Analyse détaillée de ta progression',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: '📈 Progression'),
            Tab(text: '🎮 Jeux'),
            Tab(text: '📚 Révision'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ONGLET 1 : Progression
// ─────────────────────────────────────────────────────────────
class _ProgressTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scores  = ProgressService().allScores;
    final student = ProgressService().student;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Résumé global
        _buildGlobalResume(student, scores),
        const SizedBox(height: 16),

        // Graphique évolution dans le temps
        _buildLineChart(scores),
        const SizedBox(height: 16),

        // Score moyen par niveau (barres)
        _buildBarChartByLevel(scores),
        const SizedBox(height: 16),

        // Activité hebdomadaire (heatmap)
        _buildWeeklyHeatmap(scores),
        const SizedBox(height: 16),

        // Progression par île
        _buildIslandCards(student),
      ],
    );
  }

  Widget _buildGlobalResume(Student? student, List<GameScore> scores) {
    final totalGames  = scores.length;
    final totalTime   = scores.fold(0, (s, g) => s + g.durationSeconds);
    final avgScore    = scores.isEmpty ? 0
        : (scores.map((s) => s.percentage).reduce((a, b) => a + b) /
               scores.length).round();
    final bestScore   = scores.isEmpty ? 0
        : scores.map((s) => s.percentage).reduce((a, b) => a > b ? a : b).round();
    final totalStars  = student?.totalStars ?? 0;
    final streak      = student?.currentStreak ?? 0;

    return Column(
      children: [
        Row(
          children: [
            _BigStatCard(emoji: '🎮', value: '$totalGames',
                label: 'Parties jouées',
                color: const Color(0xFF1565C0)),
            const SizedBox(width: 10),
            _BigStatCard(emoji: '⭐', value: '$totalStars',
                label: 'Étoiles totales',
                color: const Color(0xFFFF8F00)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _BigStatCard(emoji: '📊', value: '$avgScore%',
                label: 'Score moyen',
                color: const Color(0xFF2E7D32)),
            const SizedBox(width: 10),
            _BigStatCard(emoji: '🏆', value: '$bestScore%',
                label: 'Meilleur score',
                color: const Color(0xFF6A1B9A)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _BigStatCard(
                emoji: '⏱',
                value: '${(totalTime / 60).round()}min',
                label: 'Temps de jeu',
                color: const Color(0xFFE65100)),
            const SizedBox(width: 10),
            _BigStatCard(emoji: '🔥', value: '$streak j.',
                label: 'Série actuelle',
                color: const Color(0xFFC62828)),
          ],
        ),
      ],
    );
  }

  Widget _buildLineChart(List<GameScore> scores) {
    if (scores.length < 2) {
      return _EmptyChart(
          title: '📈 Évolution des scores',
          message: 'Joue plus de parties pour voir ton évolution !');
    }

    final recent = scores.reversed.take(15).toList().reversed.toList();

    return _ChartCard(
      title: '📈 Évolution des scores',
      subtitle: '${recent.length} dernières parties',
      height: 220,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: recent.asMap().entries.map((e) =>
                  FlSpot(e.key.toDouble(),
                      e.value.percentage.clamp(0, 100))).toList(),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)],
              ),
              barWidth: 3,
              dotData: FlDotData(
                getDotPainter: (spot, _, __, ___) {
                  final c = spot.y >= 80 ? Colors.green
                      : spot.y >= 60 ? Colors.amber : Colors.red;
                  return FlDotCirclePainter(
                      radius: 5, color: c,
                      strokeWidth: 2, strokeColor: Colors.white);
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF8F00).withOpacity(0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          // Ligne de référence à 80%
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 80,
                color: Colors.green.withOpacity(0.4),
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (_) => '80%',
                  style: const TextStyle(
                      color: Colors.green, fontSize: 9),
                  alignment: Alignment.topRight,
                ),
              ),
            ],
          ),
          minY: 0, maxY: 100,
          titlesData: FlTitlesData(
            bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}%',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 9),
                ),
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
                FlLine(color: Colors.white.withOpacity(0.08),
                    strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildBarChartByLevel(List<GameScore> scores) {
    final avgPerLevel = <String, double>{};
    final countPerLevel = <String, int>{};
    for (final s in scores) {
      avgPerLevel[s.levelId] =
          (avgPerLevel[s.levelId] ?? 0) + s.percentage;
      countPerLevel[s.levelId] = (countPerLevel[s.levelId] ?? 0) + 1;
    }
    final data = avgPerLevel.map((k, v) =>
        MapEntry(k, v / countPerLevel[k]!));

    if (data.isEmpty) {
      return _EmptyChart(
          title: '📊 Score par niveau',
          message: 'Aucune donnée disponible encore.');
    }

    final entries = data.entries.toList();

    return _ChartCard(
      title: '📊 Score moyen par niveau',
      subtitle: '${entries.length} niveaux joués',
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barGroups: entries.asMap().entries.map((e) {
            final val = e.value.value.clamp(0, 100).toDouble();
            final barColor = val >= 80
                ? const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter)
                : val >= 60
                    ? const LinearGradient(
                        colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter)
                    : const LinearGradient(
                        colors: [Color(0xFFB71C1C), Color(0xFFEF5350)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter);
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: val,
                  gradient: barColor,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                )
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
                  final parts = entries[i].key.split('-');
                  final label = parts.length > 1
                      ? parts[1].toUpperCase() : parts[0];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(label,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 8)),
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
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 9),
                ),
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
                FlLine(color: Colors.white.withOpacity(0.08),
                    strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildWeeklyHeatmap(List<GameScore> scores) {
    // Compter les parties par jour (7 derniers jours)
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final count = scores.where((s) =>
          s.playedAt.year == d.year &&
          s.playedAt.month == d.month &&
          s.playedAt.day == d.day).length;
      final avg = scores.where((s) =>
          s.playedAt.year == d.year &&
          s.playedAt.month == d.month &&
          s.playedAt.day == d.day).isEmpty
          ? 0.0
          : scores.where((s) =>
              s.playedAt.year == d.year &&
              s.playedAt.month == d.month &&
              s.playedAt.day == d.day)
              .map((s) => s.percentage)
              .reduce((a, b) => a + b) /
          scores.where((s) =>
              s.playedAt.year == d.year &&
              s.playedAt.month == d.month &&
              s.playedAt.day == d.day).length;
      return (date: d, count: count, avg: avg);
    });

    const dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return _ChartCard(
      title: '📅 Activité des 7 derniers jours',
      subtitle: 'Intensité basée sur les parties jouées',
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.asMap().entries.map((e) {
          final d = e.value;
          final isToday = d.date.day == now.day &&
              d.date.month == now.month;
          final intensity = d.count == 0 ? 0.0
              : d.count == 1 ? 0.35
              : d.count == 2 ? 0.6
              : d.count >= 3 ? 0.9 : 0.0;

          Color barColor;
          if (d.count == 0) {
            barColor = Colors.white.withOpacity(0.06);
          } else if (d.avg >= 80) {
            barColor = Colors.green.withOpacity(intensity);
          } else if (d.avg >= 60) {
            barColor = Colors.amber.withOpacity(intensity);
          } else {
            barColor = Colors.red.withOpacity(intensity);
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (d.count > 0)
                Text('${d.count}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 32,
                height: d.count == 0 ? 8 : (8 + d.count * 12.0).clamp(8, 60),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                  border: isToday
                      ? Border.all(color: Colors.amber, width: 2)
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dayLabels[d.date.weekday - 1],
                style: TextStyle(
                  color: isToday
                      ? Colors.amber
                      : Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIslandCards(Student? student) {
    if (student == null) return const SizedBox.shrink();
    final islands = ProgressService().buildIslands();

    return _ChartCard(
      title: '🗺️ Progression par île',
      subtitle: 'Étoiles gagnées sur chaque île',
      height: null,
      child: Column(
        children: islands.map((island) {
          const colors = {
            'CP':  Color(0xFF1565C0),
            'CE1': Color(0xFF2E7D32),
            'CE2': Color(0xFFE65100),
            'CM1': Color(0xFF6A1B9A),
            'CM2': Color(0xFFC62828),
          };
          final color = colors[island.label] ?? Colors.grey;
          final locked = !island.isUnlocked;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(locked ? '🔒' : island.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  child: Text(island.label,
                      style: TextStyle(
                          color: locked
                              ? Colors.white38
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: locked ? 0 : island.completionRate,
                      minHeight: 12,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(
                          locked ? Colors.white12 : color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    locked
                        ? '🔒 ${island.starsToUnlock}⭐'
                        : '${island.starsEarned}/${island.totalLevels * 3}⭐',
                    style: TextStyle(
                        color: locked ? Colors.white24 : Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ONGLET 2 : Jeux
// ─────────────────────────────────────────────────────────────
class _GamesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scores = ProgressService().allScores;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildGamesPieChart(scores),
        const SizedBox(height: 16),
        _buildGameDetails(scores),
        const SizedBox(height: 16),
        _buildBestScores(scores),
      ],
    );
  }

  Widget _buildGamesPieChart(List<GameScore> scores) {
    if (scores.isEmpty) {
      return _EmptyChart(
          title: '🎮 Répartition des jeux',
          message: 'Joue des parties pour voir les statistiques !');
    }

    final counts = <String, int>{};
    for (final s in scores) {
      counts[s.gameType] = (counts[s.gameType] ?? 0) + 1;
    }

    const gameColors = {
      'memory':   [Color(0xFF1565C0), Color(0xFF42A5F5)],
      'quiz':     [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      'bingo':    [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
      'parcours': [Color(0xFFE65100), Color(0xFFFF7043)],
    };
    const gameEmojis = {
      'memory': '🃏', 'quiz': '❓',
      'bingo': '🎯', 'parcours': '🏆',
    };
    final total = counts.values.fold(0, (a, b) => a + b);

    return _ChartCard(
      title: '🎮 Répartition des jeux',
      subtitle: '$total parties au total',
      height: 260,
      child: Row(
        children: [
          // Camembert
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: counts.entries.map((e) {
                  final colors = gameColors[e.key] ??
                      [Colors.grey, Colors.grey];
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    gradient: LinearGradient(colors: colors),
                    title: '${(e.value / total * 100).round()}%',
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                    radius: 80,
                    titlePositionPercentageOffset: 0.6,
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 28,
                centerSpaceColor: Colors.transparent,
              ),
            ),
          ),
          // Légende
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: counts.entries.map((e) {
                final colors = gameColors[e.key] ??
                    [Colors.grey, Colors.grey];
                final avgPct = scores
                    .where((s) => s.gameType == e.key)
                    .map((s) => s.percentage)
                    .reduce((a, b) => a + b) / e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colors),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${gameEmojis[e.key]} ${e.key}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text('${e.value} parties • ${avgPct.round()}% moy.',
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 9)),
                          ],
                        ),
                      ),
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

  Widget _buildGameDetails(List<GameScore> scores) {
    const gameNames = {
      'memory': 'Memory', 'quiz': 'Quiz',
      'bingo': 'Bingo', 'parcours': 'Parcours',
    };
    const gameEmojis = {
      'memory': '🃏', 'quiz': '❓',
      'bingo': '🎯', 'parcours': '🏆',
    };
    const gameColors = {
      'memory':   Color(0xFF1565C0),
      'quiz':     Color(0xFF2E7D32),
      'bingo':    Color(0xFF6A1B9A),
      'parcours': Color(0xFFE65100),
    };

    return _ChartCard(
      title: '📋 Détails par jeu',
      subtitle: 'Performances individuelles',
      height: null,
      child: Column(
        children: ['memory', 'quiz', 'bingo', 'parcours'].map((type) {
          final gameScores = scores.where((s) => s.gameType == type).toList();
          if (gameScores.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(gameEmojis[type]!,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(gameNames[type]!,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13)),
                  const Spacer(),
                  Text('Pas encore joué',
                      style: const TextStyle(
                          color: Colors.white24, fontSize: 11)),
                ],
              ),
            );
          }

          final avg = gameScores.map((s) => s.percentage)
              .reduce((a, b) => a + b) / gameScores.length;
          final best = gameScores.map((s) => s.percentage)
              .reduce((a, b) => a > b ? a : b);
          final color = gameColors[type] ?? Colors.grey;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(gameEmojis[type]!,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text(gameNames[type]!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${gameScores.length} parties',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: avg / 100,
                          minHeight: 10,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${avg.round()}%',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    Text(' / meilleur: ${best.round()}%',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBestScores(List<GameScore> scores) {
    if (scores.isEmpty) return const SizedBox.shrink();

    final sorted = [...scores]
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final top5 = sorted.take(5).toList();

    const gameEmojis = {
      'memory': '🃏', 'quiz': '❓',
      'bingo': '🎯', 'parcours': '🏆',
    };

    return _ChartCard(
      title: '🥇 Meilleurs scores',
      subtitle: 'Top 5 de tes meilleures parties',
      height: null,
      child: Column(
        children: top5.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          const medals = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'];
          final color = s.percentage >= 90 ? Colors.amber
              : s.percentage >= 80 ? Colors.green
              : Colors.blue;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(medals[i],
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(gameEmojis[s.gameType] ?? '🎮',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.levelId,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text('${s.durationSeconds}s  •  ${s.errorsCount} erreurs',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
                Text('${s.percentage.round()}%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ONGLET 3 : Mots à réviser (SM-2)
// ─────────────────────────────────────────────────────────────
class _WeakWordsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weak = ProgressService().weakestWords(top: 15);
    final due  = ProgressService().dueWordIds();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Bannière révision
        _buildRevisionBanner(due.length),
        const SizedBox(height: 16),

        // Graphique radial des points forts/faibles
        _buildRadarSummary(weak),
        const SizedBox(height: 16),

        // Liste mots difficiles
        if (weak.isEmpty)
          _EmptyChart(
              title: '📚 Mots à réviser',
              message: 'Joue plus de parties pour identifier\ntes points faibles !')
        else ...[
          _ChartCard(
            title: '⚠️ Mots les plus difficiles',
            subtitle: '${weak.length} mots identifiés',
            height: null,
            child: Column(
              children: weak.asMap().entries.map((e) {
                final stat  = e.value;
                final pct   = (stat.successRate * 100).round();
                final color = pct >= 70 ? Colors.green
                    : pct >= 40 ? Colors.orange : Colors.red;
                final isDue = due.contains(stat.wordId);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Rang
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Mot #${stat.wordId}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                if (isDue) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.amber.withOpacity(0.5)),
                                    ),
                                    child: const Text('À réviser',
                                        style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${stat.attempts} essais  •  '
                              '${stat.successes} réussites',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: stat.successRate,
                                minHeight: 6,
                                backgroundColor:
                                    Colors.white.withOpacity(0.08),
                                valueColor:
                                    AlwaysStoppedAnimation(color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$pct%',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRevisionBanner(int dueCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: dueCount > 0
            ? const LinearGradient(
                colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: dueCount == 0 ? Colors.white.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dueCount > 0
              ? Colors.amber.withOpacity(0.5)
              : Colors.white.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Text(dueCount > 0 ? '⏰' : '✅',
              style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dueCount > 0
                      ? '$dueCount mots à réviser aujourd\'hui !'
                      : 'Tout est à jour !',
                  style: TextStyle(
                    color: dueCount > 0 ? Colors.black87 : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dueCount > 0
                      ? 'Joue une partie pour les revoir.'
                      : 'Aucune révision en attente. Bravo !',
                  style: TextStyle(
                    color: dueCount > 0
                        ? Colors.black54
                        : Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarSummary(List<WordStat> weak) {
    if (weak.isEmpty) return const SizedBox.shrink();

    final excellent = weak.where((s) => s.successRate >= 0.8).length;
    final good      = weak.where((s) => s.successRate >= 0.6 && s.successRate < 0.8).length;
    final medium    = weak.where((s) => s.successRate >= 0.4 && s.successRate < 0.6).length;
    final poor      = weak.where((s) => s.successRate < 0.4).length;

    return _ChartCard(
      title: '📊 Répartition des performances',
      subtitle: 'Sur tes ${weak.length} mots les plus pratiqués',
      height: 80,
      child: Row(
        children: [
          _LevelBadge(count: excellent, label: 'Excellent',
              color: Colors.green),
          const SizedBox(width: 8),
          _LevelBadge(count: good, label: 'Bien',
              color: Colors.lightGreen),
          const SizedBox(width: 8),
          _LevelBadge(count: medium, label: 'Moyen',
              color: Colors.orange),
          const SizedBox(width: 8),
          _LevelBadge(count: poor, label: 'Difficile',
              color: Colors.red),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets communs
// ─────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final double? height;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          Text(subtitle,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 14),
          height != null
              ? SizedBox(height: height, child: child)
              : child,
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String title, message;
  const _EmptyChart({required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('📊', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
}

class _BigStatCard extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _BigStatCard({
    required this.emoji, required this.value,
    required this.label, required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: TextStyle(
                            color: color == const Color(0xFFFF8F00)
                                ? Colors.amber
                                : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _LevelBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _LevelBadge({
    required this.count, required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text('$count',
                  style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 9),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}