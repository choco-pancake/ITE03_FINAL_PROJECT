import 'dart:math';

import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'widgets/portal_top_actions.dart';

import 'package:flutter/services.dart';

import '../models/academic_class.dart';
import '../models/class_sections.dart';
import '../services/activity_service.dart';
import 'profile_list_screen.dart';
import 'widgets/professor_sidebar.dart';

class ProfessorClassesScreen extends StatefulWidget {
  const ProfessorClassesScreen({super.key});

  @override
  State<ProfessorClassesScreen> createState() => _ProfessorClassesScreenState();
}

class _ProfessorClassesScreenState extends State<ProfessorClassesScreen> {
  final ActivityService _activityService = ActivityService();
  final TextEditingController _searchController = TextEditingController();

  List<AcademicClass> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await _activityService.getClasses();
      if (mounted) {
        setState(() {
          _classes = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _classes = [];
          _isLoading = false;
        });
        final errorStr = e.toString();
        final isAuth = errorStr.contains('401') ||
            errorStr.toLowerCase().contains('unauthenticated') ||
            errorStr.toLowerCase().contains('session');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAuth
                  ? 'Your session expired or is unauthenticated. Please log in again.'
                  : 'Could not load classes: $e',
            ),
            backgroundColor: isAuth ? Colors.red.shade700 : null,
            behavior: SnackBarBehavior.floating,
            action: isAuth
                ? SnackBarAction(
                    label: 'Log In',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  Future<void> _deleteClass(AcademicClass c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Course Section'),
        content: Text(
          'Are you sure you want to delete "${c.name}"? This removes the enrollment code and its data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (c.id != null) {
        await _activityService.deleteClass(c.id!);
      }
      _loadClasses();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete class: $error')),
        );
      }
    }
  }

  // Generate a cryptographically distinct 6-character alphanumeric code
  String _generateUniqueCode(String coursePrefix) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final randomPart = String.fromCharCodes(
      Iterable.generate(
        4,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    final prefix = coursePrefix.replaceAll(RegExp(r'[^A-Z]'), '');
    final cleanPrefix = prefix.length >= 2 ? prefix.substring(0, 2) : 'CL';
    return '$cleanPrefix$randomPart'.toUpperCase();
  }

  void _showCreateClassDialog() {
    final messenger = ScaffoldMessenger.of(context);
    final courseCodeController = TextEditingController();
    final courseNameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedYearLevel = '2nd Year';
    String selectedBlock = ClassSections.byYear['2nd Year']!.first;
    String generatedCode = _generateUniqueCode('CS');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final availableBlocks =
              ClassSections.byYear[selectedYearLevel] ?? [];

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.add_circle_outline, color: Color(0xFF1E40AF)),
                SizedBox(width: 8),
                Text(
                  'Create Class & Generate Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set course details and generate a unique 6-character enrollment code for student registration.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),

                    // Course Code & Course Name (Separated)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: courseCodeController,
                            decoration: InputDecoration(
                              labelText: 'Course Code',
                              hintText: 'e.g. ITE 04',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (val) {
                              setDialogState(() {
                                generatedCode = _generateUniqueCode(
                                  val.trim().isNotEmpty ? val : 'CS',
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: courseNameController,
                            decoration: InputDecoration(
                              labelText: 'Course Name / Title',
                              hintText: 'e.g. Software Engineering 1',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (val) {
                              if (courseCodeController.text.trim().isEmpty) {
                                setDialogState(() {
                                  generatedCode = _generateUniqueCode(val);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Year Level & Block Dropdowns (Synced with Student Sign-up)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('class_dialog_year_$selectedYearLevel'),
                            initialValue: selectedYearLevel,
                            decoration: InputDecoration(
                              labelText: 'Year Level',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: ClassSections.byYear.keys
                                .map((year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedYearLevel = val;
                                  final blocks =
                                      ClassSections.byYear[val] ?? [];
                                  if (!blocks.contains(selectedBlock)) {
                                    selectedBlock = blocks.isNotEmpty
                                        ? blocks.first
                                        : 'BSIT 2A';
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('class_dialog_block_${selectedYearLevel}_$selectedBlock'),
                            initialValue: availableBlocks.contains(selectedBlock)
                                ? selectedBlock
                                : (availableBlocks.isNotEmpty
                                    ? availableBlocks.first
                                    : null),
                            decoration: InputDecoration(
                              labelText: 'Section / Block',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: availableBlocks
                                .map((block) => DropdownMenuItem(
                                      value: block,
                                      child: Text(block),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedBlock = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Course Description (Optional)',
                        hintText:
                            'Syllabus, team match activity specifications...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Generated Code Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Generated Enrollment Code',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                generatedCode,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Color(0xFF1E40AF),
                            ),
                            tooltip: 'Regenerate Code',
                            onPressed: () {
                              setDialogState(() {
                                final prefix =
                                    courseCodeController.text.trim().isNotEmpty
                                        ? courseCodeController.text.trim()
                                        : courseNameController.text.trim();
                                generatedCode = _generateUniqueCode(
                                  prefix.isNotEmpty ? prefix : 'CS',
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                  final code = courseCodeController.text.trim();
                  final courseName = courseNameController.text.trim();
                  if (code.isEmpty && courseName.isEmpty) return;

                  final fullName = (code.isNotEmpty && courseName.isNotEmpty)
                      ? '$code - $courseName'
                      : (code.isNotEmpty ? code : courseName);

                  final newClass = AcademicClass(
                    name: fullName,
                    classCode: generatedCode,
                    section: selectedBlock,
                    description: descriptionController.text.trim().isNotEmpty
                        ? descriptionController.text.trim()
                        : 'Course syllabus and project team requirements.',
                    studentCount: 0,
                    activitiesCount: 0,
                  );

                  Navigator.pop(ctx);

                  try {
                    await _activityService.createClass(newClass);
                    _loadClasses();
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Class "$fullName" created for $selectedBlock with code: $generatedCode',
                          ),
                          backgroundColor: const Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (error) {
                    if (mounted) {
                      final errorStr = error.toString();
                      final isAuth = errorStr.contains('401') ||
                          errorStr.toLowerCase().contains('unauthenticated') ||
                          errorStr.toLowerCase().contains('session');
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isAuth
                                ? 'Your session expired or is unauthenticated. Please log in again.'
                                : 'Could not create class: $error',
                          ),
                          backgroundColor: isAuth ? Colors.red.shade700 : null,
                          behavior: SnackBarBehavior.floating,
                          action: isAuth
                              ? SnackBarAction(
                                  label: 'Log In',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                )
                              : null,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Create Class'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _rotateClassCode(AcademicClass c) async {
    final newCode = _generateUniqueCode(c.name);
    if (c.id != null) {
      try {
        await _activityService.updateClass(c.id!, AcademicClass(
          id: c.id,
          name: c.name,
          classCode: newCode,
          description: c.description,
          section: c.section,
          studentCount: c.studentCount,
          activitiesCount: c.activitiesCount,
        ));
        await _loadClasses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Rotated enrollment code for "${c.name}" to "$newCode"!'),
            backgroundColor: const Color(0xFF16A34A),
          ));
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not rotate class code: $error')),
          );
        }
      }
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Class code "$code" copied to clipboard!'),
        backgroundColor: const Color(0xFF1E40AF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _classes.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.classCode.toLowerCase().contains(query) ||
          (c.section != null && c.section!.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Unified Professor Sidebar
          const ProfessorSidebar(
            currentDestination: ProfessorNavDestination.classes,
          ),

          // Main Classes Content
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

                              // Top Bar
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 650;
                                  final titleColumn = Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Course Sections & Class Codes',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Generate unique enrollment codes and manage student sections.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  );

                                  final createBtn = ElevatedButton.icon(
                                    onPressed: _showCreateClassDialog,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text(
                                      'Create Class & Generate Code',
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
                                        createBtn,
                                      ],
                                    );
                                  }

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: titleColumn),
                                      const SizedBox(width: 16),
                                      createBtn,
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Search Bar
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by course name, section, or 6-character class code...',
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
                              if (filtered.isEmpty)
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
                                          'Try adjusting your search query or generate a new class code.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        OutlinedButton.icon(
                                          onPressed: _showCreateClassDialog,
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text('Create New Class'),
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
                                            mainAxisExtent: 240,
                                          ),
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final academicClass = filtered[index];
                                        return _buildClassCard(academicClass);
                                      },
                                    );
                                  },
                                ),
                              const SizedBox(height: 32),
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
    return Container(
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

              // Unique Enrollment Code Chip with Copy and Rotate actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.key,
                          size: 12,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          c.classCode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      size: 14,
                      color: Color(0xFF1E40AF),
                    ),
                    tooltip: 'Copy Code',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _copyToClipboard(c.classCode),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.rotate_right,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    tooltip: 'Regenerate Code',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _rotateClassCode(c),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: Colors.red.shade400,
                    ),
                    tooltip: 'Delete Class',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _deleteClass(c),
                  ),
                ],
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
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileListScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View Groups',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
