import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../utils/citation_formatter.dart';

class CitationScreen extends StatefulWidget {
  const CitationScreen({Key? key}) : super(key: key);

  @override
  State<CitationScreen> createState() => _CitationScreenState();
}

class _CitationScreenState extends State<CitationScreen> {
  final _authorController = TextEditingController();
  final _titleController = TextEditingController();
  final _yearController = TextEditingController(text: '2024');
  final _publisherController = TextEditingController();
  final _urlController = TextEditingController();

  String _apaResult = '';
  String _mlaResult = '';

  void _generateCitation() {
    final author = _authorController.text.trim();
    final title = _titleController.text.trim();
    final year = _yearController.text.trim();
    final publisher = _publisherController.text.trim();
    final url = _urlController.text.trim();

    setState(() {
      _apaResult = CitationFormatter.formatAPA(
        author: author,
        title: title,
        year: year,
        publisher: publisher,
        url: url,
      );

      _mlaResult = CitationFormatter.formatMLA(
        author: author,
        title: title,
        year: year,
        publisher: publisher,
        url: url,
      );
    });
  }

  void _copyToClipboard(String text, String formatName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$formatName citation copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citation Generator', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author Name (e.g., Smith, J.)'),
                onChanged: (_) => _generateCitation(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Source / Book Title'),
                onChanged: (_) => _generateCitation(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year'),
                      onChanged: (_) => _generateCitation(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _publisherController,
                      decoration: const InputDecoration(labelText: 'Publisher / Journal'),
                      onChanged: (_) => _generateCitation(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL (Optional)'),
                onChanged: (_) => _generateCitation(),
              ),
              const SizedBox(height: 24),

              // Formatted Citations Cards
              Text('Formatted Citations', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              // APA Card
              _buildCitationCard('APA 7th Edition', _apaResult, () => _copyToClipboard(_apaResult, 'APA')),
              const SizedBox(height: 12),

              // MLA Card
              _buildCitationCard('MLA 9th Edition', _mlaResult, () => _copyToClipboard(_mlaResult, 'MLA')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCitationCard(String title, String citationText, VoidCallback onCopy) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan)),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: AppTheme.accentCyan, size: 20),
                onPressed: onCopy,
                tooltip: 'Copy Citation',
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            citationText.isEmpty ? 'Fill in source details above...' : citationText,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}
