import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/usage_tracker_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Anti-Addiction', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      'Configures on-device daily usage time threshold. Reaching the limit triggers a gentle break recommendation without locking your account.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    const Text('Daily Study Nudge Threshold:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    RadioListTile<int>(
                      title: const Text('60 Minutes (Light Study)'),
                      value: 60,
                      groupValue: _selectedThreshold,
                      activeColor: AppTheme.accentCyan,
                      onChanged: (val) => _updateThreshold(val!),
                    ),
                    RadioListTile<int>(
                      title: const Text('90 Minutes (Recommended Standard)'),
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
