import 'package:flutter/material.dart';

import '../models/student_record.dart';
import '../services/student_record_service.dart';
import 'widgets/portal_top_actions.dart';
import 'widgets/professor_sidebar.dart';

// ───────────────────────── Models for Step 9 ─────────────────────────

enum _Status { pending, underReview, approved, rejected }

extension _StatusX on _Status {
  String get label => switch (this) {
    _Status.pending => 'Pending',
    _Status.underReview => 'Under review',
    _Status.approved => 'Approved',
    _Status.rejected => 'Rejected',
  };

  Color get color => switch (this) {
    _Status.pending => const Color(0xFFE0A800),
    _Status.underReview => const Color(0xFF2563EB),
    _Status.approved => const Color(0xFF16A34A),
    _Status.rejected => const Color(0xFFDC2626),
  };
}

class _HistoryEntry {
  final DateTime date;
  final String action;
  _HistoryEntry(this.date, this.action);
}

class _Request {
  final String studentName;
  final String studentId;
  final String program;
  final String title;
  final String field;
  final String currentValue;
  final String requestedValue;
  final DateTime submitted;
  _Status status;
  final List<_HistoryEntry> history;

  _Request({
    required this.studentName,
    required this.studentId,
    required this.program,
    required this.title,
    required this.field,
    required this.currentValue,
    required this.requestedValue,
    required this.submitted,
    this.status = _Status.pending,
  }) : history = [_HistoryEntry(submitted, 'Request submitted')];

  String get initials {
    final parts = studentName.trim().split(' ');
    return parts.length == 1
        ? parts.first[0]
        : '${parts.first[0]}${parts.last[0]}';
  }
}

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

  // Step 9 Modification Requests state
  final List<_Request> _requests = [
    _Request(
      studentName: 'Alex Santos',
      studentId: '2024-0012',
      program: 'BSIT 2A',
      title: 'Request to swap with Bea Cruz',
      field: 'Teammate Swap',
      currentValue: 'Group 3 (Olive Ramos)',
      requestedValue: 'Group 1 (Bea Cruz)',
      submitted: DateTime.now().subtract(const Duration(hours: 2)),
      status: _Status.pending,
    ),
    _Request(
      studentName: 'Mia Alberto',
      studentId: '2024-0045',
      program: 'BSIT 2A',
      title: 'Schedule conflict',
      field: 'Availability Overlap',
      currentValue: 'Evening Sessions (Tue/Thu)',
      requestedValue: 'Morning / Afternoon Sessions',
      submitted: DateTime.now().subtract(const Duration(hours: 5)),
      status: _Status.underReview,
    ),
    _Request(
      studentName: 'Noah Sy',
      studentId: '2024-0089',
      program: 'BSIT 2A',
      title: 'Request reconsideration',
      field: 'Role Assignment',
      currentValue: 'Documentation Specialist',
      requestedValue: 'Database Specialist',
      submitted: DateTime.now().subtract(const Duration(days: 1)),
      status: _Status.pending,
    ),
  ];
  final Set<_Status> _reqFilters = {};

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Student Records & Evaluations',
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
                          'Manage enrolled student records and review Step 9 team modification requests.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        const TabBar(
                          labelColor: Color(0xFF1E40AF),
                          unselectedLabelColor: Color(0xFF64748B),
                          indicatorColor: Color(0xFF1E40AF),
                          tabs: [
                            Tab(icon: Icon(Icons.people_outline), text: 'Student Records'),
                            Tab(icon: Icon(Icons.rate_review_outlined), text: 'Step 9: Modification Requests'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Tab 1: Student Records
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                              final idText = student.studentId.isNotEmpty
                                                  ? student.studentId
                                                  : 'ID Pending';
                                              final academicInfo = [
                                                if (student.yearLevel.isNotEmpty)
                                                  student.yearLevel,
                                                if (student.block.isNotEmpty)
                                                  student.block,
                                              ].join(' • ');
                                              final classInfo = student.classes.isNotEmpty
                                                  ? student.classes.join(', ')
                                                  : 'No classes enrolled';

                                              return Card(
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  side: const BorderSide(
                                                    color: Color(0xFFE2E8F0),
                                                  ),
                                                ),
                                                child: ListTile(
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  leading: CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor:
                                                        const Color(0xFF1E40AF),
                                                    child: Text(
                                                      student.name.isNotEmpty
                                                          ? student.name[0].toUpperCase()
                                                          : 'S',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          student.name,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFEFF6FF),
                                                          borderRadius:
                                                              BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          idText,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF1D4ED8),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  subtitle: Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Text(
                                                      academicInfo.isNotEmpty
                                                          ? '$academicInfo | $classInfo'
                                                          : classInfo,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ),
                                                  trailing: const Icon(
                                                    Icons.edit_outlined,
                                                    color: Color(0xFF1E40AF),
                                                  ),
                                                  onTap: () => _editStudent(student),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                              // Tab 2: Step 9 Modification Requests
                              _buildModificationRequestsTab(),
                            ],
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
      ),
    );
  }

  Widget _buildModificationRequestsTab() {
    final filtered = _requests.where((r) {
      if (_reqFilters.isNotEmpty && !_reqFilters.contains(r.status)) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status filter pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final st in _Status.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${st.label} (${_requests.where((r) => r.status == st).length})'),
                    selected: _reqFilters.contains(st),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _reqFilters.add(st);
                        } else {
                          _reqFilters.remove(st);
                        }
                      });
                    },
                    selectedColor: st.color.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No modification requests found.'))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = filtered[index];
                    final canDecide = req.status == _Status.pending || req.status == _Status.underReview;
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                                  child: Text(
                                    req.initials,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E40AF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        req.studentName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        '${req.studentId} • ${req.program}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: req.status.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    req.status.label,
                                    style: TextStyle(
                                      color: req.status.color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              req.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${req.field}: ${req.currentValue} → ${req.requestedValue}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                            if (canDecide) ...[
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(color: Color(0xFFDC2626)),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        req.status = _Status.rejected;
                                        req.history.add(_HistoryEntry(DateTime.now(), 'Rejected by professor'));
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Rejected ${req.studentName}\'s request.'),
                                          backgroundColor: const Color(0xFFDC2626),
                                        ),
                                      );
                                    },
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        req.status = _Status.approved;
                                        req.history.add(_HistoryEntry(DateTime.now(), 'Approved by professor'));
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Approved ${req.studentName}\'s request.'),
                                          backgroundColor: const Color(0xFF16A34A),
                                        ),
                                      );
                                    },
                                    child: const Text('Approve'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
