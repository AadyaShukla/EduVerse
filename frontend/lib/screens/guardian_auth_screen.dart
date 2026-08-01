import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/guardian_provider.dart';
import 'guardian_dashboard_screen.dart';
import 'auth_screen.dart';

class GuardianAuthScreen extends ConsumerStatefulWidget {
  const GuardianAuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GuardianAuthScreen> createState() => _GuardianAuthScreenState();
}

class _GuardianAuthScreenState extends ConsumerState<GuardianAuthScreen> {
  final _inviteCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _submitLink() async {
    final inviteCode = _inviteCodeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pin = _pinController.text.trim();

    if (inviteCode.length != 6 || name.isEmpty || email.isEmpty || pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-character invite code, valid name, email, and 4+ digit PIN.')),
      );
      return;
    }

    final success = await ref.read(guardianProvider.notifier).linkWithInviteCode(
      inviteCode: inviteCode,
      guardianName: name,
      guardianEmail: email,
      pin: pin,
    );

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GuardianDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardianState = ref.watch(guardianProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
            child: const Text('Student Login', style: TextStyle(color: AppTheme.accentCyan)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.family_restroom_rounded, color: Colors.black, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'One-on-One Guardian Linking',
                            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enter student invite code to link and monitor your child\'s learning progress.',
                            style: TextStyle(color: Colors.black87, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _inviteCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: '6-Character Student Invite Code',
                  prefixIcon: Icon(Icons.vpn_key_rounded, color: AppTheme.accentCyan),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Guardian Full Name',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryViolet),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Guardian Email Address',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.accentCyan),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Set 4+ Digit Local Security PIN',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryViolet),
                ),
              ),
              const SizedBox(height: 24),

              if (guardianState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    guardianState.errorMessage!,
                    style: const TextStyle(color: AppTheme.warningOrange, fontSize: 13),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: guardianState.isLoading ? null : _submitLink,
                  child: guardianState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Link & View Student Progress'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
