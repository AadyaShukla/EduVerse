import 'package:flutter/material.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  bool _isAuthenticating = false;

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });

      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        authenticated = await auth.authenticate(
          localizedReason: 'Scan your fingerprint or enter PIN to access EduVerse',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          )
        );
      }
    } catch (e) {
      // Ignored
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }

    if (authenticated) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Signup')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isAuthenticating ? null : _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Login with Biometrics / PIN'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // TOTP Recovery placeholder UI
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Account Recovery'),
                      content: const TextField(
                        decoration: InputDecoration(hintText: 'Enter TOTP Code'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Validate TOTP code with backend
                            Navigator.of(context).pop();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                            );
                          },
                          child: const Text('Verify'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Forgot PIN? Use TOTP Recovery'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
