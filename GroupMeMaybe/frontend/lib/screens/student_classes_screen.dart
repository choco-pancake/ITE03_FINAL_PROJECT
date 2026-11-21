import 'package:flutter/material.dart';

import 'widgets/bottom_right_notification.dart';
import 'widgets/portal_top_actions.dart';

import '../models/academic_class.dart';
import '../services/activity_service.dart';
import '../services/instruction_file_picker.dart';
import 'student_groups_screen.dart';
import 'widgets/student_sidebar.dart';
import '../models/grouping_activity.dart';
import 'widgets/student_profile_dialog.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key, this.service});

  final ActivityService? service;

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  late final ActivityService _activityService;
  final _searchController = TextEditingController();

  List<AcademicClass> _allClasses = [];
  List<AcademicClass> _filteredClasses = [];
  bool _isLoading = true;

  AcademicClass? _selectedClass;
  List<Map<String, dynamic>> _classStudents = [];
  List<GroupingActivity> _classActivities = [];
  Map<int, Map<String, dynamic>> _projectStatuses = {};
  String _projectFilter = 'all';
  bool _isLoadingClassDetails = false;
  String? _classDetailsError;

  Future<void> _selectClass(AcademicClass c) async {
    setState(() {
      _selectedClass = c;
      _isLoadingClassDetails = true;
      _classStudents = [];
      _classActivities = [];
      _projectStatuses = {};
      _projectFilter = 'all';
      _classDetailsError = null;
    });
    try {
      final studentsFuture = c.id != null
          ? _activityService.getClassStudents(c.id!)
          : Future.value(<Map<String, dynamic>>[]);
      final activitiesFuture = _activityService.getActivities(classId: c.id);
      final statusesFuture = _activityService.getProjectStatuses(c.id!);
      final results = await Future.wait([studentsFuture, activitiesFuture, statusesFuture]);
      if (mounted && _selectedClass?.id == c.id) {
        setState(() {
          _classStudents = results[0] as List<Map<String, dynamic>>;
          _classActivities = results[1] as List<GroupingActivity>;
          _projectStatuses = results[2] as Map<int, Map<String, dynamic>>;
          _isLoadingClassDetails = false;
        });
      }
    } catch (error) {
      if (mounted && _selectedClass?.id == c.id) {
        setState(() {
          _isLoadingClassDetails = false;
          _classDetailsError = error.toString();
        });
      }
    }
  }

  Future<void> _submitProject(GroupingActivity activity, AcademicClass c) async {
    final status = _projectStatuses[activity.id] ?? {};
    final teamName = status['team_name']?.toString();
    if (teamName == null || activity.id == null) return;
    final file = await pickProjectFile();
    if (file == null || !mounted) return;
    if (file.bytes.length > 10 * 1024 * 1024) {
      AppNotification.showError(context, 'Project file must be 10 MB or smaller.');
      return;
    }
    try {
      await _activityService.submitProject(activity.id!, teamName, file);
      await _selectClass(c);
      if (mounted) AppNotification.showSuccess(context, 'Project submitted for $teamName.');
    } catch (error) {
      if (mounted) AppNotification.showError(context, error.toString());
    }
  }

  Future<void> _downloadSubmission(GroupingActivity activity) async {
    if (activity.id == null) return;
    try {
      final submissions = await _activityService.getProjectSubmissions(activity.id!);
      if (submissions.isNotEmpty) {
        await _activityService.downloadProjectSubmission(submissions.first);
      }
    } catch (error) {
      if (mounted) AppNotification.showError(context, error.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _activityService = widget.service ?? ActivityService();
    _loadClasses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClasses = List.from(_allClasses);
      } else {
        _filteredClasses = _allClasses.where((c) {
          final nameMatch = c.name.toLowerCase().contains(query);
          final codeMatch = c.classCode.toLowerCase().contains(query);
          final sectionMatch = (c.section ?? '').toLowerCase().contains(query);
          return nameMatch || codeMatch || sectionMatch;
        }).toList();
      }
    });
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final classes = await _activityService.getClasses();
      if (mounted) {
        setState(() {
          _allClasses = classes;
          _filteredClasses = classes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEnrollWithCodeDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.add_circle_outline, color: Color(0xFF1E40AF)),
            SizedBox(width: 8),
            Text(
              'Enroll with Class Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the class code provided by your instructor to join their academic section and grouping activities.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Class Code',
                hintText: 'e.g. WD2A-7K92',
                prefixIcon: const Icon(Icons.key, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.isEmpty) return;

              final matchedClass = _allClasses.cast<AcademicClass?>().firstWhere(
                (c) => c != null && c.classCode.toUpperCase() == code,
                orElse: () => null,
              );

              if (matchedClass != null) {
                if (ctx.mounted) Navigator.pop(ctx);
                AppNotification.showSuccess(
                  context,
                  'Already Enrolled',
                  'You are already enrolled in ${matchedClass.displayName}.',
                );
                await _loadClasses();
              } else {
                try {
                  final enrolled = await _activityService.enrollInClass(code);
                  if (!mounted) return;
                  if (ctx.mounted) Navigator.pop(ctx);
                  AppNotification.showSuccess(
                    context,
                    'Enrolled Successfully',
                    'You have joined ${enrolled.displayName}.',
                  );
                  await _loadClasses();
                } catch (error) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!mounted) return;
                  final rawErr = error.toString().replaceAll('Exception: ', '');
                  final message = (rawErr.isEmpty ||
                          rawErr.toLowerCase().contains('found') ||
                          rawErr.toLowerCase().contains('client') ||
                          rawErr.toLowerCase().contains('failed') ||
                          rawErr.toLowerCase().contains('socket'))
                      ? 'Class code "$code" not found. Please verify with your instructor.'
                      : rawErr;
                  AppNotification.showError(
                    context,
                    'Enrollment Failed',
                    message,
                  );
                }
              }
            },
            child: const Text('Enroll Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Unified Sidebar
          const StudentSidebar(
            currentDestination: StudentNavDestination.classes,
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadClasses,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 28,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Actions Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: const [PortalTopActions()],
                              ),
                              const SizedBox(height: 12),

                              if (_selectedClass != null) ...[
                                _buildClassDetailView(_selectedClass!),
                              ] else ...[

                              // Top Bar
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 650;
                                  final titleColumn = Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'My Enrolled Classes',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'View your course sections, class codes, and group activities.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  );

                                  final enrollBtn = ElevatedButton.icon(
                                    onPressed: _showEnrollWithCodeDialog,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text(
                                      'Enroll with Class Code',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E40AF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );

                                  if (isNarrow) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        titleColumn,
                                        const SizedBox(height: 14),
                                        enrollBtn,
                                      ],
                                    );
                                  }

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: titleColumn),
                                      const SizedBox(width: 16),
                                      enrollBtn,
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Search Bar
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search classes by course name, section, or class code...',
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 20,
                                    color: Color(0xFF64748B),
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                          ),
                                          onPressed: () =>
                                              _searchController.clear(),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Classes Grid
                              if (_filteredClasses.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.school_outlined,
                                          size: 48,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No classes found.',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Try adjusting your search query or enter a new class code.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        OutlinedButton.icon(
                                          onPressed: _showEnrollWithCodeDialog,
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text(
                                            'Enroll with Class Code',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final crossAxisCount =
                                        constraints.maxWidth >= 720 ? 2 : 1;
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing: 20,
                                            mainAxisSpacing: 20,
                                            mainAxisExtent: 220,
                                          ),
                                      itemCount: _filteredClasses.length,
                                      itemBuilder: (context, index) {
                                        final academicClass =
                                            _filteredClasses[index];
                                        return _buildClassCard(academicClass);
                                      },
                                    );
                                  },
                                ),
                              const SizedBox(height: 32),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(AcademicClass c) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _selectClass(c),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c.section ?? 'General',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.key, size: 12, color: Color(0xFF475569)),
                        const SizedBox(width: 4),
                        Text(
                          c.classCode,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  c.description ?? 'Course syllabus, project milestones, and team match activity specifications.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${c.studentCount} Students',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.hub_outlined,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${c.activitiesCount} Activities',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'View Projects →',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassDetailView(AcademicClass c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _selectedClass = null),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Classes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E40AF),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (c.section != null && c.section!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        'Block: ${c.section}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.key, size: 13, color: Color(0xFF475569)),
                        const SizedBox(width: 4),
                        Text(
                          c.classCode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_classDetailsError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('Could not load class details: $_classDetailsError',
              style: const TextStyle(color: Colors.red)),
          ),

        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 820;

            final leftColumn = Container(
              padding: const EdgeInsets.all(20),
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
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.people_alt_outlined, color: Color(0xFF1E40AF), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Enrolled Classmates',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_classStudents.length} Students',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Classmates enrolled in ${c.section ?? "this block"}. Tap to view profile.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const Divider(height: 24),
                  if (_isLoadingClassDetails)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (_classStudents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No students found in this block roster.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _classStudents.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final student = _classStudents[idx];
                        final sName = student['name']?.toString() ?? 'Student';
                        final sRole = student['preferred_role']?.toString() ?? 'Developer';
                        final sId = student['student_id']?.toString() ?? '';
                        final initials = sName.isNotEmpty ? sName.substring(0, 1).toUpperCase() : 'S';

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              StudentProfileDialog.show(context, memberData: student);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF1E40AF),
                                    child: Text(
                                      initials,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sName,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 2),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            if (sId.isNotEmpty) ...[
                                              Text(sId, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                              const SizedBox(width: 6),
                                              const Text('•', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                              const SizedBox(width: 6),
                                            ],
                                            Text(sRole, style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );

            final visibleActivities = _classActivities.where((activity) {
              final status = _projectStatuses[activity.id] ?? {};
              final submitted = status['submitted'] == true;
              final graded = status['graded'] == true;
              return switch (_projectFilter) {
                'graded' => graded,
                'complete' => submitted,
                'incomplete' => !submitted,
                _ => true,
              };
            }).toList();

            final rightColumn = Container(
              padding: const EdgeInsets.all(20),
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
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.assignment_outlined, color: Color(0xFF1E40AF), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Class Projects & Activities',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_classActivities.length} Projects',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Grouping activities, squad assignments, and team matching for this course.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: const [
                      ('all', 'All'), ('graded', 'Graded'),
                      ('complete', 'Complete'), ('incomplete', 'Incomplete'),
                    ].map((item) => ChoiceChip(
                      label: Text(item.$2),
                      selected: _projectFilter == item.$1,
                      onSelected: (_) => setState(() => _projectFilter = item.$1),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingClassDetails)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (visibleActivities.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.folder_open_outlined, size: 36, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 8),
                          Text(
                            _projectFilter == 'all'
                                ? 'No projects created for this class yet.'
                                : 'No projects match this filter.',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _projectFilter == 'all'
                                ? 'Your instructor has not posted any grouping activities for this section.'
                                : 'Try another project filter.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleActivities.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final act = visibleActivities[idx];
                        final isAuto = act.groupingMethod.toLowerCase() == 'auto';
                        final projectStatus = _projectStatuses[act.id] ?? {};

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          act.title,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isAuto ? const Color(0xFFF3E8FF) : const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isAuto ? const Color(0xFFD8B4FE) : const Color(0xFFA7F3D0)),
                                    ),
                                    child: Text(
                                      isAuto ? 'Auto-Formed' : 'Student-Made',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isAuto ? const Color(0xFF7E22CE) : const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Dedicated Project Instructions Box
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 10, bottom: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF1E40AF)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Project Instructions',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (act.description != null && act.description!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        act.description!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF334155),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    if (act.instructionFileName != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFF1E40AF)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                act.instructionFileName!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            FilledButton.icon(
                                              onPressed: () async {
                                                try {
                                                  await _activityService.downloadInstructions(act);
                                                } catch (error) {
                                                  if (context.mounted) AppNotification.showError(context, error.toString());
                                                }
                                              },
                                              icon: const Icon(Icons.download, size: 14),
                                              label: const Text('Download Instructions', style: TextStyle(fontSize: 11)),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: const Color(0xFF1E40AF),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                minimumSize: Size.zero,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people_outline, size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text('${act.groupCapacity} members / squad', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Project deadline: ${(act.projectSubmissionDeadline ?? act.groupingDeadline).month.toString().padLeft(2, '0')}-${(act.projectSubmissionDeadline ?? act.groupingDeadline).day.toString().padLeft(2, '0')}-${(act.projectSubmissionDeadline ?? act.groupingDeadline).year}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                  if (!isAuto)
                                    Text(
                                      'Group deadline: ${act.groupingDeadline.month.toString().padLeft(2, '0')}-${act.groupingDeadline.day.toString().padLeft(2, '0')}-${act.groupingDeadline.year}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                projectStatus['graded'] == true
                                    ? 'Graded: ${projectStatus['grade']} / 100'
                                    : projectStatus['submitted'] == true
                                        ? 'Complete • Submitted by ${projectStatus['team_name']}'
                                        : 'Incomplete • No project file submitted',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: projectStatus['graded'] == true
                                      ? const Color(0xFF047857)
                                      : const Color(0xFF475569),
                                ),
                              ),
                              if (projectStatus['feedback'] != null &&
                                  projectStatus['feedback'].toString().isNotEmpty)
                                Text('Feedback: ${projectStatus['feedback']}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              if (projectStatus['submitted'] == true)
                                TextButton.icon(
                                  onPressed: () => _downloadSubmission(act),
                                  icon: const Icon(Icons.download_outlined, size: 16),
                                  label: Text('Download ${projectStatus['file_name'] ?? 'submission'}'),
                                ),
                              if (projectStatus['can_submit'] == true)
                                OutlinedButton.icon(
                                  onPressed: () => _submitProject(act, c),
                                  icon: const Icon(Icons.upload_file_outlined, size: 16),
                                  label: Text(projectStatus['submitted'] == true
                                      ? 'Replace Project File' : 'Submit Project File'),
                                ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentGroupsScreen(
                                          initialActivityId: act.id,
                                          initialClassId: c.id,
                                          initialClassName: c.displayName,
                                        ),
                                      ),
                                    );
                                    if (mounted) _selectClass(c);
                                  },
                                  icon: const Icon(Icons.group_work_outlined, size: 16),
                                  label: const Text('View Squads & Join Team'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E40AF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );

            if (isNarrow) {
              return Column(
                children: [
                  leftColumn,
                  const SizedBox(height: 20),
                  rightColumn,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: leftColumn),
                const SizedBox(width: 24),
                Expanded(flex: 5, child: rightColumn),
              ],
            );
          },
        ),
      ],
    );
  }

}
