import 'package:flutter/material.dart';

class ProfessorClassesScreen extends StatelessWidget {
  const ProfessorClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professor Classes'),
      ),
      body: const Center(
        child: Text(
          'Professor Classes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

