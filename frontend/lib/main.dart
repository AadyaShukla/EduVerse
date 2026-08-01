import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/accessibility_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: EduVerseApp(),
    ),
  );
}

class EduVerseApp extends ConsumerWidget {
  const EduVerseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(accessibilityProvider);

    return MaterialApp(
      title: 'EduVerse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(
        isHighContrast: accessState.isHighContrast,
        isDyslexicFont: accessState.isDyslexicFont,
      ),
      home: const SplashScreen(),
    );
  }
}
