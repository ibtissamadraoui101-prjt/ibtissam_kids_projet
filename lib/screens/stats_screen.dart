// lib/screens/stats_screen.dart
// CORRIGÉ : contient StatsScreen + ProfileScreen dans le même fichier
// → world_map_screen.dart importe uniquement ce fichier pour les deux classes

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/progress_service.dart';
import '../models/student_models.dart';
import '../widgets/lumi_mascot.dart';
import '../widgets/lk_widgets.dart';

// ═══════════════════════════════════════════════════════════
// STATS SCREEN
// ═══════════════════════════════════════════════════════════
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (_, __) {
        final ps      = ProgressService();
        final student = ps.student;
        return Scaffold(
          backgroundColor: LKColors.bgCream,
          body: Column(children: [
            _buildHeader(context, student),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(children: [
                  _buildXPCard(student),
                  const SizedBox(height: 14),
                  _buildIslandProgress(ps),
                  const SizedBox(height: 14),
                  _buildWeakWords(ps),
                  const SizedBox(height: 14),
                  _buildRecentActivity(ps),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext ctx, Student? student) {
    return Container(
      decoration: const BoxDecoration(color: LKColors.island1Green),
      child: SafeArea(bottom: false, child: Column(children: [
        const RainbowStrip(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Row(children: [
            GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); Navigator.pop(ctx); },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: LKColors.textDark, size: 18)),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(student?.name ?? 'Mon profil',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                    color: Colors.white)),
              const Text('CP — LinguaKids',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
            ]),
            const Spacer(),
            LumiMascot(mood: LumiMood.happy, size: 42),
          ]),
        ),
      ])),
    );
  }

  Widget _buildXPCard(Student? student) {
    final xp     = student?.totalStars ?? 0;
    final streak = student?.currentStreak ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: LKDecorations.card(
          color: LKColors.bgYellowLight, borderColor: LKColors.sun),
      child: Row(children: [
        Expanded(child: _miniStat('⭐', '$xp',     'XP Total',
            LKColors.sun, LKColors.textOnYellow)),
        const _Divider(),
        Expanded(child: _miniStat('🔥', '$streak', 'Streak',
            const Color(0xFFFF8C6B), const Color(0xFF5A1800))),
        const _Divider(),
        Expanded(child: _miniStat('🌟', '$xp',     'Étoiles',
            LKColors.island1Green, LKColors.textOnGreen)),
      ]),
    );
  }

  Widget _miniStat(String emoji, String value, String label,
      Color bgColor, Color textColor) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      Text(value, style: TextStyle(fontSize: 22,
          fontWeight: FontWeight.w900, color: textColor)),
      Text(label, style: TextStyle(fontSize: 10,
          color: textColor.withOpacity(0.7), fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildIslandProgress(ProgressService ps) {
    final islands = ps.buildIslands();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: LKDecorations.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Progression par île',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
              color: LKColors.textDark)),
        const SizedBox(height: 12),
        ...List.generate(islands.length, (i) {
          final island   = islands[i];
          final theme    = IslandTheme.all[i];
          final progress = island.totalLevels > 0
            ? island.starsEarned / (island.totalLevels * 3) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(children: [
              Row(children: [
                Text(theme.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(theme.name, style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: LKColors.textDark)),
                const Spacer(),
                Text(
                  island.isUnlocked
                    ? '${(progress * 100).round()}%' : '🔒',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                    color: island.isUnlocked ? theme.textColor : LKColors.textLight)),
              ]),
              const SizedBox(height: 6),
              LKProgressBar(
                progress: island.isUnlocked ? progress : 0,
                fillColor: island.isUnlocked ? theme.primary : LKColors.neutral,
                bgColor: LKColors.neutralDark, height: 8),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildWeakWords(ProgressService ps) {
    final weak = ps.weakestWords(top: 5);
    if (weak.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: LKDecorations.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mots à retravailler',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
              color: LKColors.textDark)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
          children: weak.map((w) {
            final pct  = w.successRate;
            final color     = pct < 0.4 ? LKColors.wrong : LKColors.sun;
            final textColor = pct < 0.4
              ? const Color(0xFF791F1F) : LKColors.textOnYellow;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color, width: 1.5)),
              child: Text('Mot #${w.wordId}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: textColor)),
            );
          }).toList()),
      ]),
    );
  }

  Widget _buildRecentActivity(ProgressService ps) {
    final recent = ps.recentScores(limit: 5);
    if (recent.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: LKDecorations.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Activité récente',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
              color: LKColors.textDark)),
        const SizedBox(height: 10),
        ...recent.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: s.stars >= 2 ? LKColors.correctLight : LKColors.wrongLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: s.stars >= 2 ? LKColors.correct : LKColors.wrong)),
              child: Center(child: Text(
                s.stars >= 3 ? '⭐' : s.stars >= 2 ? '🌟' : '💪',
                style: const TextStyle(fontSize: 18)))),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.gameType, style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
                Text('${s.score}/${s.maxScore} — ${s.stars} ⭐',
                  style: const TextStyle(fontSize: 10, color: LKColors.textMedium)),
              ],
            )),
            LKStars(earned: s.stars, size: 14),
          ]),
        )),
      ]),
    );
  }
}

// ── Séparateur interne ─────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
    Container(width: 1, height: 50, color: LKColors.neutralDark);
}


// ═══════════════════════════════════════════════════════════
// PROFILE SCREEN  (dans ce même fichier — pas de profile_screen.dart)
// ═══════════════════════════════════════════════════════════
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (_, __) {
        final student = ProgressService().student;
        return Scaffold(
          backgroundColor: LKColors.bgCream,
          body: Column(children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // Avatar + nom
                  Center(child: Column(children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: LKColors.island2Blue, shape: BoxShape.circle,
                        border: Border.all(color: LKColors.island2Dark, width: 3)),
                      child: Center(child: Text(
                        student?.avatarEmoji ?? '👧',
                        style: const TextStyle(fontSize: 40)))),
                    const SizedBox(height: 8),
                    Text(student?.name ?? 'Mon enfant',
                      style: const TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: LKColors.textDark)),
                    const Text('CP — LinguaKids',
                      style: TextStyle(fontSize: 12, color: LKColors.textMedium)),
                  ])),
                  const SizedBox(height: 20),

                  // Stats résumé
                  _settingsCard('📊 Statistiques', [
                    _row('XP total',       '${student?.totalStars ?? 0}'),
                    _row('Streak actuel',  '${student?.currentStreak ?? 0} jours'),
                    _row('Étoiles',        '${student?.totalStars ?? 0} ⭐'),
                  ]),
                  const SizedBox(height: 14),

                  // Paramètres
                  _settingsCard('⚙️ Paramètres', [
                    _row('Langue TTS', 'Français'),
                    _row('Sons',       'Activés 🔊'),
                    _row('Niveau',     'CP (6-7 ans)'),
                  ]),
                  const SizedBox(height: 14),

                  // Reset
                  GestureDetector(
                    onTap: () => _confirmReset(context),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: LKColors.wrongLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LKColors.wrong, width: 2)),
                      child: const Row(children: [
                        Icon(Icons.refresh_rounded,
                            color: LKColors.wrong, size: 24),
                        SizedBox(width: 12),
                        Text('Recommencer depuis le début',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: LKColors.wrong)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext ctx) {
    return Container(
      decoration: const BoxDecoration(color: LKColors.island4Coral),
      child: SafeArea(bottom: false, child: Column(children: [
        const RainbowStrip(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Row(children: [
            GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); Navigator.pop(ctx); },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: LKColors.textDark, size: 18)),
            ),
            const SizedBox(width: 12),
            const Text('Profil & Parents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: Colors.white)),
          ]),
        ),
      ])),
    );
  }

  Widget _settingsCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: LKDecorations.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14,
            fontWeight: FontWeight.w800, color: LKColors.textDark)),
        const SizedBox(height: 10),
        ...rows,
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 12, color: LKColors.textMedium)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700, color: LKColors.textDark)),
      ]),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Recommencer ?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Toute la progression sera effacée. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, recommencer',
              style: TextStyle(color: LKColors.wrong,
                  fontWeight: FontWeight.w800))),
        ],
      ),
    );
    if (ok == true) {
      await ProgressService().resetProgress();
      if (context.mounted) Navigator.pop(context);
    }
  }
}