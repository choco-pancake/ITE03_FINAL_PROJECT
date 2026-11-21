import 'package:flutter/material.dart';

import '../models/academic_class.dart';
import '../models/grouping_activity.dart';
import '../models/project_submission.dart';
import '../services/activity_service.dart';
import 'widgets/activity_form_dialog.dart';
import 'widgets/bottom_right_notification.dart';
import 'widgets/professor_sidebar.dart';
import 'widgets/student_profile_dialog.dart';

class ProfessorClassDetailScreen extends StatefulWidget {
  const ProfessorClassDetailScreen({super.key, required this.academicClass, this.service});

  final AcademicClass academicClass;
  final ActivityService? service;

  @override
  State<ProfessorClassDetailScreen> createState() => _ProfessorClassDetailScreenState();
}

class _ProfessorClassDetailScreenState extends State<ProfessorClassDetailScreen> {
  late final ActivityService _service;
  List<Map<String, dynamic>> _students = [];
  List<GroupingActivity> _projects = [];
  Map<int, Map<String, dynamic>> _statuses = {};
  String _filter = 'all';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ActivityService();
    _load();
  }

  Future<void> _load() async {
    final classId = widget.academicClass.id;
    if (classId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getClassStudents(classId),
        _service.getActivities(classId: classId),
        _service.getProjectStatuses(classId),
      ]);
      if (!mounted) return;
      setState(() {
        _students = results[0] as List<Map<String, dynamic>>;
        _projects = results[1] as List<GroupingActivity>;
        _statuses = results[2] as Map<int, Map<String, dynamic>>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _unenroll(Map<String, dynamic> student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unenroll student?'),
        content: Text('${student['name']} will leave this class and its project teams.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unenroll')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.unenrollStudent(widget.academicClass.id!, student['id'] as int);
      await _load();
      if (mounted) AppNotification.showSuccess(context, 'Student unenrolled.');
    } catch (error) {
      if (mounted) AppNotification.showError(context, error.toString());
    }
  }

  void _createProject() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ActivityFormDialog(
        initialClass: widget.academicClass,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _projects.where((project) {
      final graded = _statuses[project.id]?['graded'] == true;
      return _filter == 'all' || (_filter == 'graded' ? graded : !graded);
    }).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const ProfessorSidebar(currentDestination: ProfessorNavDestination.classes),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Classes'),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 10,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.academicClass.name,
                            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                          Text('Block ${widget.academicClass.section ?? 'General'} • ${widget.academicClass.classCode}',
                            style: const TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: _createProject,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Project'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    Column(
                      children: [
                        Text('Could not load class details: $_error',
                          style: const TextStyle(color: Colors.red)),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final roster = _panel(
                          title: 'Enrolled Students (${_students.length})',
                          child: _students.isEmpty
                              ? const Text('No students are enrolled in this class.')
                              : Column(children: _students.map((student) => Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                  dense: true,
                                  title: Text(student['name']?.toString() ?? 'Student'),
                                  subtitle: Text(student['student_id']?.toString() ?? ''),
                                  onTap: () => StudentProfileDialog.show(context, memberData: student),
                                  trailing: IconButton(
                                    tooltip: 'Unenroll student',
                                    icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                                    onPressed: () => _unenroll(student),
                                  ),
                                  ),
                                )).toList()),
                        );
                        final projects = _panel(
                          title: 'Projects (${_projects.length})',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                children: const [
                                  ('all', 'All'), ('graded', 'Graded'), ('not_graded', 'Not graded'),
                                ].map((item) => ChoiceChip(
                                  label: Text(item.$2),
                                  selected: _filter == item.$1,
                                  onSelected: (_) => setState(() => _filter = item.$1),
                                )).toList(),
                              ),
                              const SizedBox(height: 12),
                              if (visible.isEmpty)
                                const Text('No projects match this filter.')
                              else
                                ...visible.map((project) {
                                  final status = _statuses[project.id] ?? {};
                                  final submitted = status['submitted_group_count'] ?? 0;
                                  final graded = status['graded_group_count'] ?? 0;
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(project.title,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Project deadline: ${(project.projectSubmissionDeadline ?? project.groupingDeadline).month.toString().padLeft(2, '0')}-${(project.projectSubmissionDeadline ?? project.groupingDeadline).day.toString().padLeft(2, '0')}-${(project.projectSubmissionDeadline ?? project.groupingDeadline).year}',
                                            style: const TextStyle(color: Color(0xFF64748B)),
                                          ),
                                          if (project.groupingMethod == 'student_formed')
                                            Text(
                                              'Group deadline: ${project.groupingDeadline.month.toString().padLeft(2, '0')}-${project.groupingDeadline.day.toString().padLeft(2, '0')}-${project.groupingDeadline.year}',
                                              style: const TextStyle(color: Color(0xFF64748B)),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(submitted == 0
                                              ? 'Not graded • No group submissions'
                                              : '$graded of $submitted submitted groups graded'),
                                          const SizedBox(height: 8),
                                          Wrap(spacing: 8, children: [
                                            TextButton(
                                              onPressed: () => showDialog(
                                                context: context,
                                                builder: (_) => ProjectSubmissionsDialog(
                                                  activity: project,
                                                  onChanged: _load,
                                                ),
                                              ),
                                              child: const Text('View submissions & grades'),
                                            ),
                                            TextButton.icon(
                                                onPressed: () => showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => ActivityFormDialog(
                                                    initialClass: widget.academicClass,
                                                    activity: project,
                                                    onSaved: _load,
                                                  ),
                                                ),
                                                icon: const Icon(Icons.edit_outlined, size: 16),
                                                label: const Text('Edit Project'),
                                              ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        );
                        if (constraints.maxWidth < 800) {
                          return Column(children: [roster, const SizedBox(height: 16), projects]);
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: roster),
                            const SizedBox(width: 16),
                            Expanded(flex: 5, child: projects),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(height: 20),
        child,
      ],
    ),
  );
}

class ProjectSubmissionsDialog extends StatefulWidget {
  const ProjectSubmissionsDialog({super.key, required this.activity, required this.onChanged});

  final GroupingActivity activity;
  final VoidCallback onChanged;

  @override
  State<ProjectSubmissionsDialog> createState() => _ProjectSubmissionsDialogState();
}

class _ProjectSubmissionsDialogState extends State<ProjectSubmissionsDialog> {
  final ActivityService _service = ActivityService();
  late Future<List<ProjectSubmission>> _submissions;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _submissions = _service.getProjectSubmissions(widget.activity.id!);
  }

  Future<void> _grade(ProjectSubmission submission) async {
    final gradeController = TextEditingController(text: submission.grade?.toString() ?? '');
    final feedbackController = TextEditingController(text: submission.feedback ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Grade ${submission.teamName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Score (0–100)'),
            ),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Feedback (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final grade = double.tryParse(gradeController.text.trim());
              if (grade == null || grade < 0 || grade > 100) {
                AppNotification.showError(dialogContext, 'Enter a score from 0 to 100.');
                return;
              }
              try {
                await _service.gradeProject(
                  submission.id, grade, feedbackController.text.trim(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (error) {
                if (dialogContext.mounted) AppNotification.showError(dialogContext, error.toString());
              }
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
    gradeController.dispose();
    feedbackController.dispose();
    if (saved == true && mounted) {
      setState(_reload);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.activity.projectSubmissionDeadline ?? widget.activity.groupingDeadline;
    final canGrade = DateTime.now().isAfter(deadline);
    return AlertDialog(
      title: Text('${widget.activity.title} • Submissions'),
      content: SizedBox(
        width: 540,
        child: FutureBuilder<List<ProjectSubmission>>(
          future: _submissions,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return snapshot.hasError
                  ? Text('Could not load submissions: ${snapshot.error}')
                  : const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.isEmpty) return const Text('No groups have submitted this project.');
            return ListView(
              shrinkWrap: true,
              children: snapshot.data!.map((submission) => ListTile(
                title: Text(submission.teamName),
                subtitle: Text(submission.grade == null
                    ? 'Submitted • Not graded'
                    : 'Grade: ${submission.grade} / 100${submission.feedback == null ? '' : '\n${submission.feedback}'}'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Download file',
                      icon: const Icon(Icons.download_outlined),
                      onPressed: () async {
                        try {
                          await _service.downloadProjectSubmission(submission);
                        } catch (error) {
                          if (context.mounted) AppNotification.showError(context, error.toString());
                        }
                      },
                    ),
                    IconButton(
                      tooltip: canGrade ? 'Grade submission' : 'Grading opens after the deadline',
                      icon: const Icon(Icons.grade_outlined),
                      onPressed: canGrade ? () => _grade(submission) : null,
                    ),
                  ],
                ),
              )).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
