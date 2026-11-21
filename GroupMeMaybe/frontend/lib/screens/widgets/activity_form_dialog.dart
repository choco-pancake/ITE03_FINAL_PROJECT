import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bottom_right_notification.dart';
import '../../models/academic_class.dart';
import '../../models/grouping_activity.dart';
import '../../models/instruction_file.dart';
import '../../services/activity_service.dart';
import '../../services/instruction_file_picker.dart';

/// Simplified Project Making Dialog based on Workflow Step 4:
/// "Grouping Activity Configuration"
class ActivityFormDialog extends StatefulWidget {
  final GroupingActivity? activity;
  final AcademicClass? initialClass;
  final VoidCallback onSaved;

  const ActivityFormDialog({
    super.key,
    this.activity,
    this.initialClass,
    required this.onSaved,
  });

  @override
  State<ActivityFormDialog> createState() => _ActivityFormDialogState();
}

class _ActivityFormDialogState extends State<ActivityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _activityService = ActivityService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _groupCapacityController;
  late TextEditingController _deadlineController;
  late TextEditingController _projectDeadlineController;
  String _groupingMethod = 'auto'; // 'auto' or 'student_formed'
  final _customSkillController = TextEditingController();

  String? _selectedClassDisplay;
  int? _selectedClassId;
  List<AcademicClass> _availableClasses = [];
  bool _loadingClasses = true;

  DateTime? _groupingDeadline;
  InstructionFile? _instructionFile;
  bool _removeInstructionFile = false;

  final List<String> _requiredSkills = [];
  final List<String> _preferredSkills = [];
  bool _isSaving = false;

  // Streamlined skill pools from Step 4 infographic
  static const List<String> _skillOptions = [
    'Frontend Development',
    'Backend Development',
    'Database Management',
    'Mobile App Development',
    'UI/UX Design',
    'API Development and Integration',
    'Software Testing and Quality Assurance',
    'Cybersecurity',
    'Technical Documentation',
    'Project Management',
    'Research and Problem Solving',
    'Presentation and Communication',
    'Data Analysis',
  ];

  List<String> get _allSkillOptions => {
    ..._skillOptions,
    ..._requiredSkills,
    ..._preferredSkills,
  }.toList();

  Future<void> _chooseInstructionFile() async {
    try {
      final file = await pickInstructionFile();
      if (file == null || !mounted) return;
      if (file.bytes.length > 10 * 1024 * 1024) {
        AppNotification.showError(context, 'File must be 10 MB or smaller.');
        return;
      }
      setState(() {
        _instructionFile = file;
        _removeInstructionFile = false;
      });
    } catch (error) {
      if (mounted) AppNotification.showError(context, 'Could not open the selected file.', error.toString());
    }
  }

  String _formatDeadline(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year}';

  DateTime? _parseDeadline(String value) {
    if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(value)) return null;
    final month = int.parse(value.substring(0, 2));
    final day = int.parse(value.substring(3, 5));
    final year = int.parse(value.substring(6, 10));
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) return null;
    return date;
  }

  @override
  void initState() {
    super.initState();
    final a = widget.activity;

    _titleController = TextEditingController(text: a?.title ?? 'Final Project');
    _descriptionController = TextEditingController(text: a?.description ?? '');
    _groupCapacityController = TextEditingController(
      text: (a?.groupCapacity ?? 5).toString(),
    );
    _groupingMethod = a?.groupingMethod ?? 'auto';

    _selectedClassDisplay = widget.initialClass?.displayName ?? a?.className;
    _selectedClassId = widget.initialClass?.id ?? a?.academicClassId;

    _groupingDeadline = a?.groupingDeadline;
    _deadlineController = TextEditingController(
      text: a == null || a.groupingMethod == 'auto' ? '' : _formatDeadline(a.groupingDeadline),
    );
    _projectDeadlineController = TextEditingController(
      text: a == null ? '' : _formatDeadline(a.projectSubmissionDeadline ?? a.groupingDeadline),
    );

    if (a != null) {
      _requiredSkills.addAll(a.requiredSkills);
      _preferredSkills.addAll(a.preferredSkills.where((skill) => !_requiredSkills.contains(skill)));
    }

    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _groupCapacityController.dispose();
    _deadlineController.dispose();
    _projectDeadlineController.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _activityService.getClasses();
      if (mounted) {
        setState(() {
          _availableClasses = classes;
          _loadingClasses = false;
          if (_selectedClassId != null) {
            final match = classes.where((c) => c.id == _selectedClassId).firstOrNull;
            if (match != null) {
              _selectedClassDisplay = match.displayName;
            }
          } else if (_selectedClassDisplay == null && classes.isNotEmpty) {
            _selectedClassDisplay = classes.first.displayName;
            _selectedClassId = classes.first.id;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  Future<void> _pickDeadline(TextEditingController controller) async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final lastDate = firstDate.add(const Duration(days: 365));
    final typedDate = _parseDeadline(controller.text.trim());
    final initialDate = typedDate ?? _groupingDeadline ?? firstDate.add(const Duration(days: 21));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate)
          ? firstDate
          : (initialDate.isAfter(lastDate) ? lastDate : initialDate),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _groupingDeadline = picked;
        controller.text = _formatDeadline(picked);
      });
    }
  }

  Widget _deadlineField(TextEditingController controller) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.datetime,
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
      LengthLimitingTextInputFormatter(10),
    ],
    decoration: InputDecoration(
      hintText: 'MM-DD-YYYY',
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      suffixIcon: IconButton(
        tooltip: 'Choose deadline from calendar',
        icon: const Icon(Icons.calendar_month_outlined),
        onPressed: () => _pickDeadline(controller),
      ),
    ),
    validator: (value) {
      final date = _parseDeadline(value?.trim() ?? '');
      if (date == null) return 'Enter a date as MM-DD-YYYY';
      final today = DateTime.now();
      if (date.isBefore(DateTime(today.year, today.month, today.day))) {
        return 'Deadline cannot be in the past';
      }
      return null;
    },
  );

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;
    final projectDate = _parseDeadline(_projectDeadlineController.text.trim())!;
    final groupDate = _groupingMethod == 'student_formed'
        ? _parseDeadline(_deadlineController.text.trim())!
        : projectDate;
    final projectDeadline = DateTime(projectDate.year, projectDate.month, projectDate.day, 23, 59, 59);
    final deadline = DateTime(groupDate.year, groupDate.month, groupDate.day, 23, 59, 59);
    if (deadline.isAfter(projectDeadline)) {
      AppNotification.showError(context, 'Group deadline must be on or before the project deadline.');
      return;
    }
    _groupingDeadline = deadline;

    if (_requiredSkills.isEmpty) {
      AppNotification.showError(
        context,
        'Please select at least one required skill.',
      );
      return;
    }

    setState(() => _isSaving = true);

    final capacity = int.tryParse(_groupCapacityController.text) ?? 5;
    final currentClass = widget.initialClass ??
        _availableClasses
            .where((c) =>
                c.id == _selectedClassId ||
                c.displayName == _selectedClassDisplay)
            .firstOrNull;
    final targetClassId = _selectedClassId ?? currentClass?.id;
    final studentCount = currentClass?.studentCount ?? 30;
    final groups = studentCount > 0 ? (studentCount / capacity).ceil() : 6;

    final activity = GroupingActivity(
      id: widget.activity?.id,
      academicClassId: targetClassId,
      className: _selectedClassDisplay ?? currentClass?.displayName ?? 'Web Development - BSIT 2A',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Final project activity specifications, guidelines, and team requirements.',
      groupingMethod: _groupingMethod,
      groupCapacity: capacity,
      numberOfGroups: groups,
      requiredSkills: _requiredSkills,
      preferredSkills: _preferredSkills,
      minProficiencyLevel: 'Intermediate',
      minCommonHours: 5,
      groupingDeadline: deadline,
      projectSubmissionDeadline: projectDeadline,
      status: 'open',
      studentsCount: studentCount > 0 ? studentCount : capacity * groups,
    );

    try {
      if (widget.activity == null) {
        await _activityService.createActivity(activity, instructionFile: _instructionFile);
      } else {
        await _activityService.updateActivity(
          widget.activity!.id!,
          activity,
          instructionFile: _instructionFile,
          removeInstructionFile: _removeInstructionFile,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppNotification.showError(
          context,
          'Failed to save activity: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.activity != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step 4 Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Icon(
                        Icons.check_box_outlined,
                        color: Color(0xFF059669),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? 'Edit Grouping Activity'
                                : (widget.initialClass != null
                                    ? 'Create Project for ${widget.initialClass!.name}'
                                    : 'Create Grouping Activity'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.initialClass != null
                                ? 'Configure team sizing, deadline, and skills for this class'
                                : 'Step 4: Set project requirements to automatically balance teams',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Form Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Class selector
                        const Text(
                          'Course Section',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        if (widget.initialClass != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.school, size: 20, color: Color(0xFF1E40AF)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.initialClass!.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Section: ${widget.initialClass!.section ?? "General"} • Code: ${widget.initialClass!.classCode}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF93C5FD)),
                                  ),
                                  child: const Text(
                                    'LOCKED TO CLASS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E40AF),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          _loadingClasses
                              ? const LinearProgressIndicator()
                              : DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _availableClasses.any((c) => c.displayName == _selectedClassDisplay)
                                      ? _selectedClassDisplay
                                      : (_availableClasses.isNotEmpty ? _availableClasses.first.displayName : null),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.school, size: 18, color: Color(0xFF1E40AF)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: _availableClasses
                                      .map((c) => DropdownMenuItem(value: c.displayName, child: Text(c.displayName, style: const TextStyle(fontSize: 13))))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedClassDisplay = val;
                                      final match = _availableClasses.cast<AcademicClass?>().firstWhere((c) => c?.displayName == val, orElse: () => null);
                                      _selectedClassId = match?.id;
                                    });
                                  },
                                ),
                        ],
                        const SizedBox(height: 16),

                        // Activity Title
                        const Text(
                          'Activity Title',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Final Project',
                            prefixIcon: const Icon(Icons.assignment_outlined, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 16),

                        // Grouping Method Selector
                        const Text(
                          'Grouping Method',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _groupingMethod = 'auto'),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _groupingMethod == 'auto'
                                        ? const Color(0xFFEFF6FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _groupingMethod == 'auto'
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFFCBD5E1),
                                      width: _groupingMethod == 'auto' ? 1.8 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            size: 16,
                                            color: _groupingMethod == 'auto'
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Auto-Formed',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _groupingMethod == 'auto'
                                                  ? const Color(0xFF1E3A8A)
                                                  : const Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'System balances skills, schedules, and availability automatically.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _groupingMethod == 'auto'
                                              ? const Color(0xFF1D4ED8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _groupingMethod = 'student_formed'),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _groupingMethod == 'student_formed'
                                        ? const Color(0xFFEFF6FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _groupingMethod == 'student_formed'
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFFCBD5E1),
                                      width: _groupingMethod == 'student_formed' ? 1.8 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.group_add_outlined,
                                            size: 16,
                                            color: _groupingMethod == 'student_formed'
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Student-Made',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _groupingMethod == 'student_formed'
                                                  ? const Color(0xFF1E3A8A)
                                                  : const Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Students form their own teams and join open squads directly.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _groupingMethod == 'student_formed'
                                              ? const Color(0xFF1D4ED8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Group Size (Capacity) with dynamic class-count calculation
                        Builder(
                          builder: (context) {
                            final currentClass = widget.initialClass ??
                                _availableClasses
                                    .where((c) =>
                                        c.id == _selectedClassId ||
                                        c.displayName == _selectedClassDisplay)
                                    .firstOrNull;
                            final studentCount = currentClass?.studentCount ?? 30;
                            final capacity = int.tryParse(_groupCapacityController.text) ?? 5;
                            final estimatedGroups = capacity > 0 ? (studentCount / capacity).ceil() : 6;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Group Size (Students per Group)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _groupCapacityController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.people_alt_outlined, size: 18),
                                    suffixText: 'members / group',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  validator: (v) => (int.tryParse(v ?? '') ?? 0) < 2 ? 'Min 2 members' : null,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, size: 14, color: Color(0xFF475569)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Number of groups is auto-determined by class roster: ~$estimatedGroups groups for $studentCount students.',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),

                        // Required Skills Chips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Required Skills (Tap to toggle)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            Text(
                              '${_requiredSkills.length} selected',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allSkillOptions.map((skill) {
                            final isSelected = _requiredSkills.contains(skill);
                            return FilterChip(
                              label: Text(skill, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : const Color(0xFF334155))),
                              selected: isSelected,
                              selectedColor: const Color(0xFF2563EB),
                              backgroundColor: const Color(0xFFF1F5F9),
                              checkmarkColor: Colors.white,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _requiredSkills.add(skill);
                                    _preferredSkills.remove(skill);
                                  } else {
                                    _requiredSkills.remove(skill);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Preferred Skills Chips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Preferred Skills (Tap to toggle)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            Text(
                              '${_preferredSkills.length} selected',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF7E22CE), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allSkillOptions.where((skill) => !_requiredSkills.contains(skill)).map((skill) {
                            final isSelected = _preferredSkills.contains(skill);
                            return FilterChip(
                              label: Text(skill, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : const Color(0xFF334155))),
                              selected: isSelected,
                              selectedColor: const Color(0xFF7E22CE),
                              backgroundColor: const Color(0xFFF1F5F9),
                              checkmarkColor: Colors.white,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _preferredSkills.add(skill);
                                  } else {
                                    _preferredSkills.remove(skill);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        if (_groupingMethod == 'student_formed') ...[
                          const Text('Group Submission Deadline',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          _deadlineField(_deadlineController),
                          const SizedBox(height: 16),
                        ],
                        const Text('Project Submission Deadline',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 6),
                        _deadlineField(_projectDeadlineController),
                        const SizedBox(height: 18),
                        const Text('Project Instructions (optional)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 6),
                        if (_instructionFile != null || (widget.activity?.instructionFileName != null && !_removeInstructionFile))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.description, size: 20, color: Color(0xFF1E40AF)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _instructionFile?.name ?? widget.activity!.instructionFileName!,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _chooseInstructionFile,
                                  icon: const Icon(Icons.sync, size: 14),
                                  label: const Text('Change', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove instructions',
                                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                                  onPressed: () => setState(() {
                                    _instructionFile = null;
                                    _removeInstructionFile = true;
                                  }),
                                ),
                              ],
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: _chooseInstructionFile,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Choose PDF, DOCX, or TXT file'),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Bottom Action Button: matching Step 4 green button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669), // Emerald green from Step 4
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _saveActivity,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 18),
                      label: Text(
                        _isSaving ? 'Creating...' : (isEditing ? 'Save Changes' : 'Create Activity'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
