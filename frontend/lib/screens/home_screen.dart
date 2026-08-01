import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/wellbeing_provider.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'doubt_solver_screen.dart';
import 'quiz_setup_screen.dart';
import 'notes_screen.dart';
import 'timetable_screen.dart';
import 'essay_grader_screen.dart';
import 'reference_library_screen.dart';
import 'citation_screen.dart';
import 'pomodoro_screen.dart';
import 'settings_screen.dart';
import 'study_receipt_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _inviteCode;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final student = ref.read(authProvider).student;
      if (student != null) {
        ref.read(wellbeingProvider.notifier).loadStudentProgress(student.id);
      }
    });
  }

  void _generateGuardianInvite() async {
    final student = ref.read(authProvider).student;
    if (student == null) return;

    setState(() => _isGeneratingCode = true);
    final apiService = ApiService();
    final res = await apiService.generateInviteCode(student.id);

    setState(() {
      _isGeneratingCode = false;
      if (res['success']) {
        _inviteCode = res['invite_code'];
      }
    });
  }

  void _showAntiAddictionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: Row(
          children: const [
            Icon(Icons.coffee_rounded, color: AppTheme.warningOrange, size: 28),
            SizedBox(width: 10),
            Text('Time for a Break?'),
          ],
        ),
        content: const Text(
          "You've been studying for a while today — consider taking a short break to refresh your mind!",
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(wellbeingProvider.notifier).dismissAntiAddictionNudge();
              Navigator.of(ctx).pop();
            },
            child: const Text('I will take a break soon', style: TextStyle(color: AppTheme.accentCyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final wellbeingState = ref.watch(wellbeingProvider);
    final student = authState.student;

    if (wellbeingState.showAntiAddictionNudge) {
      Future.microtask(() {
        _showAntiAddictionDialog();
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(AppConstants.appName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppTheme.accentCyan),
            tooltip: 'Settings & Anti-Addiction',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.warningOrange),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Profile & Gamification Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryViolet.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hello, ${student?.name ?? "Student"}!',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Grade ${student?.grade ?? 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gamification Bar: XP, Streak, Badges
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: AppTheme.accentCyan, size: 22),
                            const SizedBox(width: 6),
                            Text('${wellbeingState.xp} XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(height: 20, width: 1, color: Colors.white24),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded, color: AppTheme.warningOrange, size: 22),
                            const SizedBox(width: 6),
                            Text('${wellbeingState.currentStreak} Day Streak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(height: 20, width: 1, color: Colors.white24),
                        Row(
                          children: [
                            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
                            const SizedBox(width: 6),
                            Text('${wellbeingState.badges.length} Badges', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Wellbeing Quick Bar: Pomodoro & Study Receipts
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PomodoroScreen())),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.timer_rounded, color: AppTheme.primaryViolet, size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('Pomodoro Focus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudyReceiptScreen())),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.receipt_long_rounded, color: AppTheme.accentCyan, size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('Study Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Guardian Invite Row
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.family_restroom_rounded, color: AppTheme.accentCyan, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Guardian Invite Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Share invite code for parent linking', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_inviteCode != null)
                    SelectableText(
                      _inviteCode!,
                      style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 16),
                    )
                  else
                    TextButton(
                      onPressed: _isGeneratingCode ? null : _generateGuardianInvite,
                      child: const Text('Generate Code', style: TextStyle(color: AppTheme.accentCyan)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Core AI Tools Grid
            Text('Core AI Learning Tools', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.25,
              children: [
                _buildActionTile(
                  context,
                  title: 'AI Doubt Solver',
                  subtitle: 'OCR, Voice & Multilingual',
                  icon: Icons.help_center_rounded,
                  color: AppTheme.primaryViolet,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoubtSolverScreen())),
                ),
                _buildActionTile(
                  context,
                  title: 'Adaptive Quizzes',
                  subtitle: 'Mock Exams & Weak Topics',
                  icon: Icons.quiz_rounded,
                  color: AppTheme.accentCyan,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuizSetupScreen())),
                ),
                _buildActionTile(
                  context,
                  title: 'Notes Organizer',
                  subtitle: 'AI Auto-Tag & Handwriting OCR',
                  icon: Icons.note_alt_rounded,
                  color: AppTheme.successGreen,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotesScreen())),
                ),
                _buildActionTile(
                  context,
                  title: 'Timetable & Planner',
                  subtitle: 'OCR Homework & Reminders',
                  icon: Icons.calendar_month_rounded,
                  color: AppTheme.warningOrange,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TimetableScreen())),
                ),
                _buildActionTile(
                  context,
                  title: 'Essay Grader',
                  subtitle: 'Inline AI Suggestions',
                  icon: Icons.rule_folder_rounded,
                  color: const Color(0xFFe84393),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EssayGraderScreen())),
                ),
                _buildActionTile(
                  context,
                  title: 'Formula Library',
                  subtitle: 'Math & Physics Theorems',
                  icon: Icons.functions_rounded,
                  color: const Color(0xFF0984e3),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferenceLibraryScreen())),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Citation Generator Card
            InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CitationScreen())),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.format_quote_rounded, color: AppTheme.accentCyan, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('APA & MLA Citation Generator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Instant bibliography formatting for student papers', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
