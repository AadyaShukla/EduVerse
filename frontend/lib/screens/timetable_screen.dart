import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/productivity_provider.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  String _itemType = 'assignment';
  bool _reminderSet = true;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _scanHomeworkDiary() async {
    final student = ref.read(authProvider).student;
    if (student == null) return;

    await ref.read(productivityProvider.notifier).scanAndParseHomework(student.id, ImageSource.camera);
    final state = ref.read(productivityProvider);

    if (state.parsedHomework != null) {
      final items = (state.parsedHomework!['extracted_items'] as List?) ?? [];
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          title: const Text('Parsed Homework Tasks'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((i) => ListTile(
                title: Text(i['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${i['subject']} • Deadline: ${i['suggested_deadline'] ?? 'Tomorrow'}"),
                trailing: const Icon(Icons.check_circle_outline, color: AppTheme.successGreen),
              )).toList(),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Homework tasks added to your schedule!')),
                );
              },
              child: const Text('Confirm & Save to Schedule'),
            ),
          ],
        ),
      );
    }
  }

  void _addScheduleItem() async {
    final student = ref.read(authProvider).student;
    if (student == null) return;

    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();
    if (title.isEmpty || subject.isEmpty) return;

    await ref.read(productivityProvider.notifier).addScheduleItem(
      studentId: student.id,
      type: _itemType,
      title: title,
      subject: subject,
      itemDateTime: DateTime.now().add(const Duration(hours: 4)),
      reminderSet: _reminderSet,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scheduled "$title" with local reminder notification!')),
    );

    _titleController.clear();
    _subjectController.clear();
    Navigator.of(context).pop();
  }

  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Class or Assignment', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Assignment Deadline')),
                      selected: _itemType == 'assignment',
                      onSelected: (val) => setModalState(() => _itemType = 'assignment'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Class Session')),
                      selected: _itemType == 'class',
                      onSelected: (val) => setModalState(() => _itemType = 'class'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title / Task Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject Name'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Set Local Device Notification'),
                value: _reminderSet,
                activeColor: AppTheme.accentCyan,
                onChanged: (val) => setModalState(() => _reminderSet = val),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addScheduleItem,
                  child: const Text('Save Schedule Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable & Homework Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemModal,
        backgroundColor: AppTheme.accentCyan,
        icon: const Icon(Icons.add_alert_rounded, color: Colors.black),
        label: const Text('Add Task', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Homework Diary Scanner Button Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text('AI Homework Scanner', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Photograph your homework diary page. Gemini will extract tasks and auto-schedule deadlines!',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _scanHomeworkDiary,
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.black),
                      label: const Text('Scan Homework Diary', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Upcoming Schedule & Reminders', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              _buildScheduleCard(
                type: 'assignment',
                title: 'Math Exercise 4B Worksheet',
                subject: 'Mathematics',
                time: 'Today at 5:00 PM',
                hasReminder: true,
              ),
              _buildScheduleCard(
                type: 'class',
                title: 'Physics Mechanics Lecture',
                subject: 'Physics',
                time: 'Tomorrow at 10:00 AM',
                hasReminder: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard({
    required String type,
    required String title,
    required String subject,
    required String time,
    required bool hasReminder,
  }) {
    final isAssignment = type == 'assignment';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAssignment ? AppTheme.warningOrange.withOpacity(0.4) : AppTheme.accentCyan.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isAssignment ? AppTheme.warningOrange.withOpacity(0.2) : AppTheme.accentCyan.withOpacity(0.2),
            child: Icon(isAssignment ? Icons.assignment_late_rounded : Icons.class_rounded, color: isAssignment ? AppTheme.warningOrange : AppTheme.accentCyan),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text("$subject • $time", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (hasReminder)
            const Icon(Icons.notifications_active_rounded, color: AppTheme.successGreen, size: 20),
        ],
      ),
    );
  }
}
