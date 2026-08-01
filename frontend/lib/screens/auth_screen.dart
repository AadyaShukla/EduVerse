import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _totpController = TextEditingController();
  final _newPinController = TextEditingController();

  int _selectedGrade = 6; // Default to test age-gate warning

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _totpController.dispose();
    _newPinController.dispose();
    super.dispose();
  }

  void _submit() async {
    final notifier = ref.read(authProvider.notifier);

    if (_isSignUp) {
      final name = _nameController.text.trim();
      final pin = _pinController.text.trim();
      if (name.isEmpty || pin.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid name and 4+ digit PIN.')),
        );
        return;
      }

      final success = await notifier.registerStudent(
        name: name,
        grade: _selectedGrade,
        pin: pin,
      );

      if (success) {
        final authState = ref.read(authProvider);
        if (authState.totpQrUri != null) {
          _showTotpSecretModal(authState.totpSecret!, authState.totpQrUri!);
        } else if (authState.status == AuthStatus.authenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } else {
      final pin = _pinController.text.trim();
      if (pin.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your PIN.')),
        );
        return;
      }

      final success = await notifier.loginWithPin(pin);
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  void _loginBiometrics() async {
    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.loginWithBiometrics();
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _showTotpSecretModal(String secret, String qrUri) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: Text('Setup Account Recovery (TOTP)', style: Theme.of(context).textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan this QR Code in Authenticator (Google Authenticator, Microsoft, etc.) to enable TOTP recovery in case you forget your PIN.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: qrUri,
                  version: QrVersions.auto,
                  size: 160.0,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                'Secret Key: $secret',
                style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final authState = ref.read(authProvider);
              if (authState.status == AuthStatus.authenticated) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            },
            child: const Text('I Have Saved My Recovery Key'),
          ),
        ],
      ),
    );
  }

  void _showTotpRecoveryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            Text('TOTP Account Recovery', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Enter the 6-digit verification code from your Authenticator app along with a new PIN.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _totpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '6-Digit TOTP Token',
                prefixIcon: Icon(Icons.shield_outlined, color: AppTheme.accentCyan),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Set New 4-Digit PIN',
                prefixIcon: Icon(Icons.lock_reset, color: AppTheme.primaryViolet),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final token = _totpController.text.trim();
                  final newPin = _newPinController.text.trim();
                  if (token.length != 6 || newPin.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a 6-digit TOTP and a valid new PIN.')),
                    );
                    return;
                  }

                  final success = await ref.read(authProvider.notifier).verifyTotpRecovery(token, newPin);
                  if (success) {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }
                },
                child: const Text('Verify & Reset PIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Brand Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Title & Switch Tab
              Text(
                _isSignUp ? 'Create Student Account' : 'Welcome Back Student',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUp
                    ? 'Join EduVerse with your name and school grade.'
                    : 'Log in securely with your local PIN or Biometrics.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Age-gate Banner Notice
              if (_isSignUp)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _selectedGrade < 7
                        ? AppTheme.warningOrange.withOpacity(0.15)
                        : AppTheme.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedGrade < 7 ? AppTheme.warningOrange : AppTheme.successGreen,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedGrade < 7 ? Icons.family_restroom : Icons.check_circle_outline,
                        color: _selectedGrade < 7 ? AppTheme.warningOrange : AppTheme.successGreen,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedGrade < 7
                              ? 'Age-Gate Rule: Grade $_selectedGrade requires parent/guardian link to activate account.'
                              : 'Grade $_selectedGrade: Account activates immediately. Guardian linking is optional.',
                          style: TextStyle(
                            color: _selectedGrade < 7 ? AppTheme.warningOrange : AppTheme.successGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Form fields
              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Student Name',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryViolet),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedGrade,
                  decoration: const InputDecoration(
                    labelText: 'School Grade',
                    prefixIcon: Icon(Icons.grade_outlined, color: AppTheme.accentCyan),
                  ),
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('Grade ${index + 1}'),
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedGrade = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _isSignUp ? 'Create 4+ Digit Local PIN' : 'Enter Local PIN',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryViolet),
                ),
              ),
              const SizedBox(height: 24),

              // Error Banner
              if (authState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: AppTheme.warningOrange, fontSize: 13),
                  ),
                ),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isSignUp ? 'Sign Up' : 'Log In with PIN'),
                ),
              ),
              const SizedBox(height: 12),

              // Biometric & Recovery options
              if (!_isSignUp) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loginBiometrics,
                        icon: const Icon(Icons.fingerprint, color: AppTheme.accentCyan),
                        label: const Text('Biometrics', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.accentCyan),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _showTotpRecoveryModal,
                        icon: const Icon(Icons.key, color: AppTheme.textSecondary),
                        label: const Text('TOTP Recovery', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Mode Toggle
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Log In'
                        : "Don't have an account? Sign Up",
                    style: const TextStyle(color: AppTheme.primaryViolet, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Age-Gate Blocked Status View
              if (authState.status == AuthStatus.ageGateBlocked)
                Container(
                  margin: const EdgeInsets.top(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.warningOrange, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_clock, color: AppTheme.warningOrange, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Account Activation Pending',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.warningOrange),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Under Phase 0 rules (Grade < 7), account activation requires parent/guardian verification.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
