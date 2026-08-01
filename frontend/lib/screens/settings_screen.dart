import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/accessibility_provider.dart';
import '../services/usage_tracker_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final UsageTrackerService _tracker = UsageTrackerService();
  int _selectedThreshold = 90;

  @override
  void initState() {
    super.initState();
    _selectedThreshold = _tracker.thresholdMinutes;
  }

  void _updateThreshold(int val) async {
    setState(() => _selectedThreshold = val);
    await _tracker.updateThreshold(val);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Daily study nudge threshold set to $val minutes.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(accessibilityProvider);
    final accessNotifier = ref.read(accessibilityProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Accessibility', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accessibility Settings Section
              Text('Accessibility & Visual Theme', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Dyslexia-Friendly Font'),
                      subtitle: const Text('Uses Open-Source Lexend typography app-wide'),
                      value: accessState.isDyslexicFont,
                      activeColor: AppTheme.accentCyan,
                      onChanged: accessNotifier.toggleDyslexicFont,
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    SwitchListTile(
                      title: const Text('High-Contrast Color Theme'),
                      subtitle: const Text('Maximizes color contrast for visual clarity'),
                      value: accessState.isHighContrast,
                      activeColor: AppTheme.accentCyan,
                      onChanged: accessNotifier.toggleHighContrast,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Network & Data Settings Section
              Text('Network & Data Optimization', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Low-Data Mode'),
                      subtitle: const Text('Compresses API responses & aggressive SQLite caching'),
                      value: accessState.isLowDataMode,
                      activeColor: AppTheme.accentCyan,
                      onChanged: accessNotifier.toggleLowDataMode,
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    SwitchListTile(
                      title: const Text('Simulate Offline Mode'),
                      subtitle: const Text('Forces local SQLite caching and sync queue'),
                      value: accessState.isOffline,
                      activeColor: AppTheme.warningOrange,
                      onChanged: accessNotifier.toggleOfflineMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Anti-Addiction Nudge Settings Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.health_and_safety_rounded, color: AppTheme.accentCyan, size: 28),
                        SizedBox(width: 12),
                        Text('Anti-Addiction Study Nudge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Configures on-device daily usage time threshold.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<int>(
                      title: const Text('60 Minutes (Light Study)'),
                      value: 60,
                      groupValue: _selectedThreshold,
                      activeColor: AppTheme.accentCyan,
                      onChanged: (val) => _updateThreshold(val!),
                    ),
                    RadioListTile<int>(
                      title: const Text('90 Minutes (Recommended)'),
                      value: 90,
                      groupValue: _selectedThreshold,
                      activeColor: AppTheme.accentCyan,
                      onChanged: (val) => _updateThreshold(val!),
                    ),
                    RadioListTile<int>(
                      title: const Text('120 Minutes (Deep Focus)'),
                      value: 120,
                      groupValue: _selectedThreshold,
                      activeColor: AppTheme.accentCyan,
                      onChanged: (val) => _updateThreshold(val!),
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
}
