import 'package:flutter/material.dart';
import '../state/app_state.dart';

class CustomSkillRequestDialog extends StatefulWidget {
  final AppState appState;

  const CustomSkillRequestDialog({super.key, required this.appState});

  @override
  State<CustomSkillRequestDialog> createState() => _CustomSkillRequestDialogState();
}

class _CustomSkillRequestDialogState extends State<CustomSkillRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _justificationController = TextEditingController();
  String _selectedCategory = 'Frontend Development';

  final List<String> _categories = [
    'Frontend Development',
    'Backend Development',
    'Full-Stack Development',
    'Mobile App Development',
    'UI/UX Design',
    'Database Management',
    'API Development and Integration',
    'Software Testing and Quality Assurance',
    'Cybersecurity',
    'Networking',
    'Artificial Intelligence and Machine Learning',
    'Data Analysis',
    'Cloud and Deployment',
    'Project Management and Documentation',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _justificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.stars, color: Color(0xFF6366F1)),
          SizedBox(width: 10),
          Text('Request Custom Skill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Custom skills require approval by your professor before being added to the official catalog and reflected on your profile.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Skill / Tool Name *',
                    hintText: 'e.g. GraphQL, Three.js, Kubernetes',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter skill name' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Competency Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _justificationController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Relevance / Justification *',
                    hintText: 'Explain how this skill fits the project competencies and your demonstrated experience...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (val) => (val == null || val.trim().length < 10) ? 'Please provide a brief justification (at least 10 chars)' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.appState.submitCustomSkillRequest(
                skillName: _nameController.text.trim(),
                category: _selectedCategory,
                justification: _justificationController.text.trim(),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Custom skill request submitted to instructor for approval!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Submit Request'),
        ),
      ],
    );
  }
}
