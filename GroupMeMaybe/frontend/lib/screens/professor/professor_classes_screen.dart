import 'package:flutter/material.dart';
import '../../state/app_state.dart';

class ProfessorClassesScreen extends StatefulWidget {
  final AppState appState;

  const ProfessorClassesScreen({super.key, required this.appState});

  @override
  State<ProfessorClassesScreen> createState() => _ProfessorClassesScreenState();
}

class _ProfessorClassesScreenState extends State<ProfessorClassesScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedSection = 'BSCS 4-A';

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.appState;
    final classes = app.classes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Class Management',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generate unique class enrollment codes and manage enrolled student sections.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateClassDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create New Class', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Classes list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: classes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, idx) {
              final c = classes[idx];
              final enrolled = app.students.where((s) => c.enrolledStudentIds.contains(s.id)).toList();

              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.class_outlined, color: Color(0xFF4F46E5), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${c.code}: ${c.name}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                      child: Text(c.section, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Instructor: ${c.professorName} • ${enrolled.length} Enrolled Students',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Unique Enrollment Code Box (Jedrik, Page 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ENROLLMENT CODE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                  SizedBox(height: 2),
                                ],
                              ),
                              const SizedBox(width: 8),
                              SelectableText(
                                c.enrollmentCode,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4F46E5),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                                tooltip: 'Copy Enrollment Code',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Copied unique code "${c.enrollmentCode}" to clipboard!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    const Text('ENROLLED STUDENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: enrolled.map((s) {
                        return Chip(
                          avatar: CircleAvatar(
                            radius: 10,
                            backgroundColor: const Color(0xFF6366F1),
                            child: Text(s.fullName.isNotEmpty ? s.fullName[0] : 'S', style: const TextStyle(fontSize: 9, color: Colors.white)),
                          ),
                          label: Text('${s.fullName.isNotEmpty ? s.fullName : s.displayName} (${s.studentId})', style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey.shade50,
                          side: BorderSide(color: Colors.grey.shade200),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Create New Class & Generate Code', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Course Code *',
                        hintText: 'e.g. CS401, IT302',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Course Title *',
                        hintText: 'e.g. Software Engineering & Capstone',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedSection,
                      decoration: InputDecoration(
                        labelText: 'Section / Block',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['BSCS 4-A', 'BSCS 4-B', 'BSIT 4-A', 'BSIT 4-B', 'BSIS 3-A']
                          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => _selectedSection = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (_codeController.text.trim().isNotEmpty && _nameController.text.trim().isNotEmpty) {
                      widget.appState.createClass(
                        code: _codeController.text.trim().toUpperCase(),
                        name: _nameController.text.trim(),
                        section: _selectedSection,
                      );
                      _codeController.clear();
                      _nameController.clear();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Class created with unique enrollment code!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Generate Code & Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
