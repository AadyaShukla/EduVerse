import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/guardian_provider.dart';
import 'guardian_auth_screen.dart';

class GuardianDashboardScreen extends ConsumerWidget {
  const GuardianDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardianState = ref.watch(guardianProvider);
    final dash = guardianState.dashboardData;
    final insights = guardianState.aiInsights;

    final studentName = dash?['student_name'] ?? 'Student';
    final grade = dash?['student_grade'] ?? 8;
    final avgScore = (dash?['avg_quiz_score'] as num?)?.toDouble() ?? 82.0;
    final totalMins = dash?['total_study_minutes'] ?? 120;
    final streak = dash?['current_streak'] ?? 4;
    final xp = dash?['xp'] ?? 320;
    final inactivityAlert = dash?['inactivity_alert'] == true;
    final inactivityDays = dash?['inactivity_days'] ?? 0;
    final weakTopics = (dash?['weak_topics'] as List?) ?? [];
    final doubts = (dash?['recent_doubts'] as List?) ?? [];

    final aiSummary = insights?['weekly_insight_summary'] ?? 
        "$studentName has been consistent with daily study sessions this week, achieving an average quiz score of ${avgScore.toStringAsFixed(1)}%. Extra practice on Quadratic Equations will help reinforce confidence!";

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard: $studentName (Grade $grade)', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.warningOrange),
            tooltip: 'Logout Guardian Portal',
            onPressed: () async {
              await ref.read(guardianProvider.notifier).logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GuardianAuthScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inactivity Banner Alert
              if (inactivityAlert)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.warningOrange, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Inactivity Alert: $studentName hasn\'t completed study sessions in $inactivityDays+ days.',
                          style: const TextStyle(color: AppTheme.warningOrange, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // AI Weekly Summary Insight Card (Gemini Daily Cached)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentCyan.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: Colors.black, size: 24),
                        SizedBox(width: 8),
                        Text('AI Weekly Plain-Language Summary', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      aiSummary,
                      style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Metrics Overview Grid
              Row(
                children: [
                  _buildMetricTile('Avg Quiz Score', '${avgScore.toStringAsFixed(1)}%', Icons.analytics, AppTheme.primaryViolet),
                  const SizedBox(width: 12),
                  _buildMetricTile('Study Time', '$totalMins mins', Icons.timer, AppTheme.accentCyan),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricTile('Active Streak', '$streak Days', Icons.local_fire_department, AppTheme.warningOrange),
                  const SizedBox(width: 12),
                  _buildMetricTile('Total Progress', '$xp XP', Icons.bolt, AppTheme.successGreen),
                ],
              ),
              const SizedBox(height: 24),

              // Current Weak Topics Section
              Text('Current Weak Topics', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...weakTopics.map((wt) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.warningOrange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(wt['topic'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${wt['times_wrong']}x Needs Practice', style: const TextStyle(color: AppTheme.warningOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 24),

              // Recent Doubts Summary Section
              Text('Recent Questions Asked', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...doubts.map((d) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline_rounded, color: AppTheme.accentCyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['question_text'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Topic: ${d['topic'] ?? "General"}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
