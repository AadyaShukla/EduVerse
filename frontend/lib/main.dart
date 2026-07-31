import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Dummy provider setup, normally would hold state models
        Provider(create: (_) => 'EduVerseAppProvider'),
      ],
      child: const EduVerseApp(),
    ),
  );
}

class EduVerseApp extends StatelessWidget {
  const EduVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduVerse',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}
