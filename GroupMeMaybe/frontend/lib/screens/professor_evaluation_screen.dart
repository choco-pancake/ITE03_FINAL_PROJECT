import 'package:flutter/material.dart';

import '../models/student_record.dart';
import '../services/student_record_service.dart';
import 'widgets/portal_top_actions.dart';
import 'widgets/professor_sidebar.dart';

class ProfessorEvaluationScreen extends StatefulWidget {
  const ProfessorEvaluationScreen({super.key, this.service});

  final StudentRecordService? service;

  @override
  State<ProfessorEvaluationScreen> createState() =>
      _ProfessorEvaluationScreenState();
}

class _ProfessorEvaluationScreenState extends State<ProfessorEvaluationScreen> {
  late final StudentRecordService _service;
  final TextEditingController _searchController = TextEditingController();
  List<StudentRecord> _students = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? StudentRecordService();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await _service.getStudents();
      if (!mounted) return;
      setState(() {
        _students = students;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _editStudent(StudentRecord student) async {
    final formKey = GlobalKey<FormState>();
    final values = <String, String>{
      'first_name': student.firstName,
      'middle_name': student.middleName,
      'last_name': student.lastName,
      'student_id': student.studentId,
      'year_level': student.yearLevel,
      'block': student.block,
    };
    bool saving = false;
    String? errorMessage;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text('Edit ${student.name}'),
          content: SizedBox(
            width: 470,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Changes are saved immediately and recorded with your account.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    for (final field in const [
                      ('first_name', 'First name'),
                      ('middle_name', 'Middle name'),
                      ('last_name', 'Last name'),
                      ('student_id', 'Student ID'),
                      ('year_level', 'Year level'),
                      ('block', 'Section / block'),
                    ]) ...[
                      TextFormField(
                        initialValue: values[field.$1],
                        onChanged: (value) => values[field.$1] = value,
                        decoration: InputDecoration(labelText: field.$2),
                        validator: (value) {
                          if (field.$1 != 'middle_name' &&
                              (value == null || value.trim().isEmpty)) {
                            return '${field.$2} is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Color(0xFFDC2626)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (formKey.currentState?.validate() != true) return;
                      refresh(() {
                        saving = true;
                        errorMessage = null;
                      });
                      try {
                        await _service.updateStudent(student.id, {
                          for (final entry in values.entries)
                            entry.key: entry.value.trim(),
                        });
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (error) {
                        if (dialogContext.mounted) {
                          refresh(() {
                            saving = false;
                            errorMessage = error.toString().replaceFirst(
                              'Exception: ',
                              '',
                            );
                          });
                        }
                      }
                    },
              child: const Text('Save record'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student record updated.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visible = _students.where((student) {
      return query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.studentId.toLowerCase().contains(query) ||
          student.classes.any((name) => name.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfessorSidebar(
            currentDestination: ProfessorNavDestination.evaluation,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Student Records',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const PortalTopActions(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Edit records for students enrolled in your classes.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Search students or classes',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _error != null
                            ? Center(
                                child: TextButton(
                                  onPressed: _loadStudents,
                                  child: Text('$_error Tap to retry.'),
                                ),
                              )
                            : visible.isEmpty
                            ? const Center(
                                child: Text('No enrolled students found.'),
                              )
                            : ListView.separated(
                                itemCount: visible.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final student = visible[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(student.name),
                                      subtitle: Text(
                                        '${student.studentId} | ${student.classes.join(', ')}',
                                      ),
                                      trailing: const Icon(Icons.edit_outlined),
                                      onTap: () => _editStudent(student),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
