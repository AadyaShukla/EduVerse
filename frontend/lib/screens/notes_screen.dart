import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/productivity_provider.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedSubject = 'General';
  String _filterSubject = 'All';

  void _scanHandwriting(ImageSource source) async {
    final extractedText = await ref.read(productivityProvider.notifier).scanHandwritingOCR(source);
    if (extractedText != null && extractedText.isNotEmpty) {
      setState(() {
        _contentController.text = (_contentController.text + "\n" + extractedText).trim();
      });
      _autoTagContent();
    }
  }

  void _autoTagContent() async {
    final text = _contentController.text.trim();
    if (text.length > 10) {
      final res = await ref.read(productivityProvider.notifier).autoTagNote(text);
      if (res['suggested_subject'] != null) {
        setState(() {
          _selectedSubject = res['suggested_subject'];
        });
      }
    }
  }

  void _saveNote() async {
    final student = ref.read(authProvider).student;
    if (student == null) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    // Save local note or sync to backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Note "$title" saved under $_selectedSubject!')),
    );

    _titleController.clear();
    _contentController.clear();
    Navigator.of(context).pop();
  }

  void _showNewNoteModal() {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New Study Note', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.document_scanner, color: AppTheme.accentCyan),
                      tooltip: 'OCR Handwriting Scan',
                      onPressed: () {
                        _scanHandwriting(ImageSource.camera);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Note Title'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: ['General', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'History']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => _selectedSubject = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Note Content',
                    hintText: 'Type or use OCR Handwriting scanner...',
                  ),
                  onChanged: (_) => _autoTagContent(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveNote,
                    child: const Text('Save Note'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Organizer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewNoteModal,
        backgroundColor: AppTheme.primaryViolet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search notes by keyword...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.accentCyan),
                ),
              ),
              const SizedBox(height: 16),

              // Subject Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Mathematics', 'Physics', 'Chemistry', 'General']
                      .map((subj) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(subj),
                              selected: _filterSubject == subj,
                              selectedColor: AppTheme.accentCyan.withOpacity(0.3),
                              onSelected: (val) {
                                setState(() => _filterSubject = subj);
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Sample Notes Grid
              Expanded(
                child: ListView(
                  children: [
                    _buildNoteCard(
                      title: 'Quadratic Equations & Roots',
                      subject: 'Mathematics',
                      tags: ['algebra', 'formulas'],
                      snippet: 'Quadratic Formula x = (-b ± sqrt(b^2 - 4ac)) / 2a. Discriminant b^2 - 4ac determines nature of roots.',
                      date: 'Just now',
                    ),
                    _buildNoteCard(
                      title: "Newton's Kinematic Laws",
                      subject: 'Physics',
                      tags: ['motion', 'velocity'],
                      snippet: 'v = u + at, s = ut + 0.5at^2, v^2 = u^2 + 2as. Applies under uniform acceleration.',
                      date: 'Today',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard({
    required String title,
    required String subject,
    required List<String> tags,
    required String snippet,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(subject, style: const TextStyle(color: AppTheme.primaryViolet, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(snippet, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.3)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: tags.map((t) => Chip(
              label: Text('#$t', style: const TextStyle(fontSize: 10, color: AppTheme.accentCyan)),
              backgroundColor: const Color(0xFF2A2739),
              padding: EdgeInsets.zero,
            )).toList(),
          ),
        ],
      ),
    );
  }
}
