import 'package:flutter/material.dart';

import '../../models/academic_class.dart';
import '../../models/grouping_activity.dart';
import '../../services/activity_service.dart';

class ActivityFormDialog extends StatefulWidget {
  final GroupingActivity? activity;
  final VoidCallback onSaved;

  const ActivityFormDialog({
    super.key,
    this.activity,
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
  late TextEditingController _numberOfGroupsController;
  late TextEditingController _minCommonHoursController;
  late TextEditingController _customSkillController;

  String? _selectedClassDisplay;
  int? _selectedClassId;
  List<AcademicClass> _availableClasses = [];
  bool _loadingClasses = true;

  String _groupingMethod = 'auto'; // auto, manual, hybrid
  String _minProficiencyLevel = 'Intermediate'; // Beginner, Intermediate, Advanced
  String _status = 'open'; // draft, open, grouping in progress, completed

  late DateTime _groupingDeadline;
  DateTime? _modificationDeadline;

  final List<String> _requiredSkills = [];
  final List<String> _preferredSkills = [];

  bool _isSaving = false;

  // Standard skills pool from specifications
  static const List<String> _standardSkills = [
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
    'System Analysis and Design',
    'Technical Documentation',
    'Project Management',
    'Research and Problem Solving',
    'Presentation and Communication',
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.activity;

    _titleController = TextEditingController(text: a?.title ?? '');
    _descriptionController = TextEditingController(text: a?.description ?? '');
    _groupCapacityController =
        TextEditingController(text: (a?.groupCapacity ?? 5).toString());
    _numberOfGroupsController =
        TextEditingController(text: (a?.numberOfGroups ?? 6).toString());
    _minCommonHoursController =
        TextEditingController(text: (a?.minCommonHours ?? 5).toString());
    _customSkillController = TextEditingController();

    _groupingMethod = a?.groupingMethod ?? 'auto';
    _minProficiencyLevel = a?.minProficiencyLevel ?? 'Intermediate';
    _status = a?.status ?? 'open';

    _selectedClassDisplay = a?.className;
    _selectedClassId = a?.academicClassId;

    _groupingDeadline =
        a?.groupingDeadline ?? DateTime.now().add(const Duration(days: 14));
    _modificationDeadline = a?.studentModificationDeadline ??
        DateTime.now().add(const Duration(days: 17));

    if (a != null) {
      _requiredSkills.addAll(a.requiredSkills);
      _preferredSkills.addAll(a.preferredSkills);
    } else {
      _requiredSkills.addAll(['Frontend Development', 'Backend Development']);
      _preferredSkills.add('UI/UX Design');
    }

    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _groupCapacityController.dispose();
    _numberOfGroupsController.dispose();
    _minCommonHoursController.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _activityService.getClasses();
      setState(() {
        _availableClasses = classes;
        _loadingClasses = false;
        if (_selectedClassDisplay == null && classes.isNotEmpty) {
          _selectedClassDisplay = classes.first.displayName;
          _selectedClassId = classes.first.id;
        }
      });
    } catch (_) {
      setState(() {
        _loadingClasses = false;
        _selectedClassDisplay ??= 'Web Development - BSIT 2A';
      });
    }
  }

  Future<void> _pickDateTime({
    required BuildContext context,
    required DateTime initialDate,
    required Function(DateTime) onPicked,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: this.context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null || !mounted) return;

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    onPicked(finalDateTime);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _addCustomSkill(bool isRequired) {
    final skill = _customSkillController.text.trim();
    if (skill.isEmpty) return;

    setState(() {
      if (isRequired) {
        if (!_requiredSkills.contains(skill)) {
          _requiredSkills.add(skill);
          _preferredSkills.remove(skill);
        }
      } else {
        if (!_preferredSkills.contains(skill)) {
          _preferredSkills.add(skill);
          _requiredSkills.remove(skill);
        }
      }
      _customSkillController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_requiredSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one required skill.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final capacity = int.tryParse(_groupCapacityController.text) ?? 5;
    final groups = int.tryParse(_numberOfGroupsController.text) ?? 6;
    final commonHours = int.tryParse(_minCommonHoursController.text) ?? 5;

    final activity = GroupingActivity(
      id: widget.activity?.id,
      academicClassId: _selectedClassId,
      className: _selectedClassDisplay ?? 'Web Development - BSIT 2A',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      groupingMethod: _groupingMethod,
      groupCapacity: capacity,
      numberOfGroups: groups,
      requiredSkills: _requiredSkills,
      preferredSkills: _preferredSkills,
      minProficiencyLevel: _minProficiencyLevel,
      minCommonHours: commonHours,
      groupingDeadline: _groupingDeadline,
      studentModificationDeadline: _modificationDeadline,
      status: _status,
      studentsCount: capacity * groups,
    );

    try {
      if (widget.activity == null) {
        await _activityService.createActivity(activity);
      } else {
        await _activityService.updateActivity(widget.activity!.id!, activity);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save activity: $e'),
            backgroundColor: Colors.red,
          ),
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
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note : Icons.add_task,
                        color: Colors.blue[700],
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Edit Grouping Activity'
                              : 'Create Grouping Activity',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure matching parameters, required skills, and deadlines',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),

                // Form body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Class Selection & Status
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Class Selection
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Class Selection *',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  _loadingClasses
                                      ? const LinearProgressIndicator()
                                      : DropdownButtonFormField<String>(
                                          initialValue: _availableClasses.any((c) =>
                                                  c.displayName ==
                                                  _selectedClassDisplay)
                                              ? _selectedClassDisplay
                                              : (_availableClasses.isNotEmpty
                                                  ? _availableClasses
                                                      .first.displayName
                                                  : null),
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(Icons.school,
                                                size: 20),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12),
                                          ),
                                          items: _availableClasses.map((c) {
                                            return DropdownMenuItem<String>(
                                              value: c.displayName,
                                              child: Text(c.displayName),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val == null) return;
                                            final matching = _availableClasses
                                                .firstWhere((c) =>
                                                    c.displayName == val);
                                            setState(() {
                                              _selectedClassDisplay = val;
                                              _selectedClassId = matching.id;
                                            });
                                          },
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Status dropdown
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _status,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'open', child: Text('Open')),
                                      DropdownMenuItem(
                                          value: 'grouping in progress',
                                          child: Text('Grouping in Progress')),
                                      DropdownMenuItem(
                                          value: 'completed',
                                          child: Text('Completed')),
                                      DropdownMenuItem(
                                          value: 'draft', child: Text('Draft')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _status = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Activity Title
                        const Text(
                          'Activity Title *',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Final Capstone Project',
                            prefixIcon: const Icon(Icons.assignment, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Activity title is required'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Description
                        const Text(
                          'Activity Description',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                'Explain the activity goals, expected deliverables, and grouping guidelines...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Grouping Method & Team Sizes
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Grouping Method (Auto, Manual, Hybrid)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Grouping Method *',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildMethodChip(
                                          'auto', 'Auto (Algorithm)', Icons.smart_toy),
                                      const SizedBox(width: 8),
                                      _buildMethodChip(
                                          'manual', 'Manual', Icons.person_search),
                                      const SizedBox(width: 8),
                                      _buildMethodChip(
                                          'hybrid', 'Hybrid', Icons.shuffle),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Capacity, Number of Groups, Min Common Hours, Min Proficiency
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Group Capacity *',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _groupCapacityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.group, size: 20),
                                      suffixText: 'members',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                    validator: (val) {
                                      final n = int.tryParse(val ?? '');
                                      if (n == null || n < 2) {
                                        return 'Min 2';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Number of Groups',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _numberOfGroupsController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.grid_view,
                                          size: 20),
                                      suffixText: 'teams',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Min Common Hours *',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _minCommonHoursController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.access_time,
                                          size: 20),
                                      suffixText: 'hrs/wk',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Min Proficiency *',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _minProficiencyLevel,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'Beginner',
                                          child: Text('Beginner')),
                                      DropdownMenuItem(
                                          value: 'Intermediate',
                                          child: Text('Intermediate')),
                                      DropdownMenuItem(
                                          value: 'Advanced',
                                          child: Text('Advanced')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(
                                            () => _minProficiencyLevel = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Deadlines
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Grouping Deadline *',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () => _pickDateTime(
                                      context: context,
                                      initialDate: _groupingDeadline,
                                      onPicked: (dt) =>
                                          setState(() => _groupingDeadline = dt),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.event,
                                              size: 20, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Text(_formatDateTime(_groupingDeadline)),
                                          const Spacer(),
                                          const Icon(Icons.arrow_drop_down,
                                              color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Student Modification Deadline (Switch cutoff)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () => _pickDateTime(
                                      context: context,
                                      initialDate: _modificationDeadline ??
                                          DateTime.now()
                                              .add(const Duration(days: 17)),
                                      onPicked: (dt) => setState(
                                          () => _modificationDeadline = dt),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit_calendar,
                                              size: 20, color: Colors.indigo),
                                          const SizedBox(width: 8),
                                          Text(_modificationDeadline != null
                                              ? _formatDateTime(
                                                  _modificationDeadline!)
                                              : 'Set deadline'),
                                          const Spacer(),
                                          const Icon(Icons.arrow_drop_down,
                                              color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Required Skills Section
                        Row(
                          children: [
                            const Text(
                              'Required Skills *',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_requiredSkills.length} selected - Every group will require these)',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _standardSkills.map((skill) {
                            final isSelected = _requiredSkills.contains(skill);
                            return FilterChip(
                              label: Text(skill),
                              selected: isSelected,
                              selectedColor: Colors.blue[100],
                              checkmarkColor: Colors.blue[800],
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
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

                        // Preferred Skills Section
                        Row(
                          children: [
                            const Text(
                              'Preferred Skills (Optional)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_preferredSkills.length} selected - Weighted in matching score)',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _standardSkills
                              .where((s) => !_requiredSkills.contains(s))
                              .map((skill) {
                            final isSelected = _preferredSkills.contains(skill);
                            return FilterChip(
                              label: Text(skill),
                              selected: isSelected,
                              selectedColor: Colors.teal[100],
                              checkmarkColor: Colors.teal[800],
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _preferredSkills.add(skill);
                                  } else {
                                    _preferredSkills.remove(skill);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Custom Skill addition
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customSkillController,
                                decoration: InputDecoration(
                                  hintText: 'Add custom skill (e.g. GraphQL, Tailwind CSS)',
                                  prefixIcon: const Icon(Icons.add, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                onSubmitted: (_) => _addCustomSkill(true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _addCustomSkill(true),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('+ Required'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _addCustomSkill(false),
                              icon: const Icon(Icons.favorite_border, size: 16),
                              label: const Text('+ Preferred'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),

                // Bottom Buttons: Cancel & Create Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(isEditing ? Icons.save : Icons.add_task),
                      label: Text(
                        isEditing ? 'Save Changes' : 'Create Activity',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildMethodChip(String method, String label, IconData icon) {
    final isSelected = _groupingMethod == method;
    return ChoiceChip(
      avatar: Icon(icon,
          size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blue[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) setState(() => _groupingMethod = method);
      },
    );
  }
}
