import 'widgets/student_profile_dialog.dart';
import 'package:flutter/material.dart';

import 'widgets/bottom_right_notification.dart';
import '../models/student_record.dart';
import '../services/student_record_service.dart';
import '../services/activity_service.dart';
import 'widgets/portal_top_actions.dart';
import 'widgets/professor_sidebar.dart';

// ───────────────────────── Models for Step 9 ─────────────────────────

class ProfessorEvaluationScreen extends StatefulWidget {
  const ProfessorEvaluationScreen({super.key, this.service, this.activityService});

  final StudentRecordService? service;
  final ActivityService? activityService;

  @override
  State<ProfessorEvaluationScreen> createState() =>
      _ProfessorEvaluationScreenState();
}

class _ProfessorEvaluationScreenState extends State<ProfessorEvaluationScreen> {
  String? _selectedBlock;
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
        if (_selectedBlock != null && !students.any((student) => student.block == _selectedBlock)) {
          _selectedBlock = null;
        }
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

  Future<void> _unenrollStudent(StudentRecord student) async {
    if (student.classEnrollments.isEmpty) return;
    Map<String, dynamic>? selectedClass;
    if (student.classEnrollments.length == 1) {
      selectedClass = student.classEnrollments.first;
    } else {
      selectedClass = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text('Select a class for ${student.name}'),
          children: student.classEnrollments.map((item) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, item),
            child: Text('${item['name']} • ${item['section'] ?? 'General'}'),
          )).toList(),
        ),
      );
    }
    if (selectedClass == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unenroll student?'),
        content: Text('${student.name} will leave ${selectedClass!['name']} and its project teams.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unenroll')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.unenrollStudent(selectedClass['id'] as int, student.id);
      await _loadStudents();
      if (mounted) AppNotification.showSuccess(context, '${student.name} was unenrolled.');
    } catch (error) {
      if (mounted) AppNotification.showError(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    // Group students by block
    final Map<String, List<StudentRecord>> blockMap = {};
    for (final s in _students) {
      final blk = s.block.trim().isNotEmpty ? s.block.trim() : 'General';
      blockMap.putIfAbsent(blk, () => []).add(s);
    }

    final sortedBlocks = blockMap.keys.toList()..sort();

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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedBlock != null
                                  ? 'Student Records • $_selectedBlock'
                                  : 'Student Records',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const PortalTopActions(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedBlock != null
                            ? 'Viewing enrolled students in block $_selectedBlock. Tap a student to view their profile.'
                            : 'Browse enrolled student records categorized by academic block / section.',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),

                      if (_selectedBlock != null) ...[
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => setState(() {
                                _selectedBlock = null;
                                _searchController.clear();
                              }),
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Back to Blocks'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E40AF),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Text(
                                'Block: $_selectedBlock',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: _selectedBlock != null
                              ? 'Search students in $_selectedBlock'
                              : 'Search blocks or student names',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                            : _selectedBlock == null
                            ? _buildBlockCardsView(sortedBlocks, blockMap, query)
                            : _buildStudentsInBlockView(blockMap[_selectedBlock] ?? [], query),
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

  Widget _buildBlockCardsView(
    List<String> sortedBlocks,
    Map<String, List<StudentRecord>> blockMap,
    String query,
  ) {
    final filteredBlocks = sortedBlocks.where((blk) {
      if (query.isEmpty) return true;
      if (blk.toLowerCase().contains(query)) return true;
      final students = blockMap[blk] ?? [];
      return students.any((s) =>
          s.name.toLowerCase().contains(query) ||
          s.studentId.toLowerCase().contains(query));
    }).toList();

    if (filteredBlocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.grid_view_outlined, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No blocks found matching your query.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 2 : 1;

        return GridView.builder(
          itemCount: filteredBlocks.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 112,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, idx) {
            final blk = filteredBlocks[idx];
            final students = blockMap[blk] ?? [];

            String yearLevel = 'Year Pending';
            for (final s in students) {
              if (s.yearLevel.isNotEmpty) {
                yearLevel = s.yearLevel;
                break;
              }
            }
            if (yearLevel == 'Year Pending') {
              if (blk.startsWith('11-')) { yearLevel = '1st Year'; }
              else if (blk.startsWith('21-')) { yearLevel = '2nd Year'; }
              else if (blk.startsWith('31-')) { yearLevel = '3rd Year'; }
              else if (blk.startsWith('41-')) { yearLevel = '4th Year'; }
            }

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedBlock = blk),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(blk,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              yearLevel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_alt_outlined, color: Color(0xFF1E40AF), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${students.length} Students Enrolled',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentsInBlockView(List<StudentRecord> students, String query) {
    final visible = students.where((student) {
      return query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.studentId.toLowerCase().contains(query) ||
          student.classes.any((name) => name.toLowerCase().contains(query));
    }).toList();

    if (visible.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.search_off, size: 40, color: Color(0xFF94A3B8)),
              SizedBox(height: 8),
              Text(
                'No students found in this block matching your search.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final student = visible[index];
        final idText = student.studentId.isNotEmpty ? student.studentId : 'ID Pending';
        final academicInfo = [
          if (student.yearLevel.isNotEmpty) student.yearLevel,
          if (student.block.isNotEmpty) student.block,
        ].join(' • ');
        final classInfo = student.classes.isNotEmpty
            ? student.classes.join(', ')
            : 'No classes enrolled';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            onTap: () => StudentProfileDialog.show(context, studentRecord: student),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF1E40AF),
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
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
                academicInfo.isNotEmpty ? '$academicInfo | $classInfo' : classInfo,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                  tooltip: 'Unenroll from class',
                  onPressed: student.classEnrollments.isEmpty
                      ? null
                      : () => _unenrollStudent(student),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
