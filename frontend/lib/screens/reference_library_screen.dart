import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../core/theme/app_theme.dart';

class ReferenceLibraryScreen extends StatefulWidget {
  const ReferenceLibraryScreen({Key? key}) : super(key: key);

  @override
  State<ReferenceLibraryScreen> createState() => _ReferenceLibraryScreenState();
}

class _ReferenceLibraryScreenState extends State<ReferenceLibraryScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _subjects = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFormulasData();
  }

  void _loadFormulasData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/formulas_data.json');
      final data = jsonDecode(jsonString);
      setState(() {
        _subjects = data['subjects'] ?? [];
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formula & Theorem Library', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search formulas, laws, or theorems...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.accentCyan),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                  itemCount: _subjects.length,
                  itemBuilder: (ctx, index) {
                    final subj = _subjects[index];
                    final subjName = subj['name'] ?? '';
                    final categories = (subj['categories'] as List?) ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subjName, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primaryViolet)),
                        const SizedBox(height: 10),

                        ...categories.map((cat) {
                          final catName = cat['category'] ?? '';
                          final items = (cat['items'] as List?) ?? [];
                          final filteredItems = items.where((i) {
                            final title = (i['title'] ?? '').toString().toLowerCase();
                            final formula = (i['formula'] ?? '').toString().toLowerCase();
                            return _searchQuery.isEmpty || title.contains(_searchQuery) || formula.contains(_searchQuery);
                          }).toList();

                          if (filteredItems.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(catName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan)),
                              const SizedBox(height: 8),

                              ...filteredItems.map((item) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2739),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppTheme.accentCyan),
                                      ),
                                      child: SelectableText(
                                        item['formula'] ?? '',
                                        style: const TextStyle(
                                          color: AppTheme.accentCyan,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(item['description'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              )).toList(),
                            ],
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
