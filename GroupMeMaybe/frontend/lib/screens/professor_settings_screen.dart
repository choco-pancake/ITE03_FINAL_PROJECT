import 'package:flutter/material.dart';

class ProfessorSettingsScreen extends StatelessWidget {
  const ProfessorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professor Settings'),
      ),
      body: const Center(
        child: Text(
          'Professor Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

