import 'package:flutter/material.dart';
import 'package:frontend/screens/doubt_solver_screen.dart';
import 'package:frontend/screens/quiz_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduVerse Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Home Screen (Placeholder)'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DoubtSolverScreen()),
                );
              },
              child: const Text('Solve a Doubt'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const QuizSetupScreen()),
                );
              },
              child: const Text('Practice & Assessment'),
            ),
          ],
        ),
      ),
    );
  }
}
