import 'package:flutter/material.dart';

class ProfessorEvaluationScreen extends StatelessWidget {
  const ProfessorEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professor Evaluation'),
      ),
      body: const Center(
        child: Text(
          'Professor Evaluation',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

