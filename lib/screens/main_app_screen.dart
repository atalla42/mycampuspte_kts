import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainAppScreen extends StatelessWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Main Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎓 Welcome to MyCampusPTE!'),
            const SizedBox(height: 12),
            Text('Logged in as: ${user?.email ?? "Unknown"}'),
          ],
        ),
      ),
    );
  }
}
