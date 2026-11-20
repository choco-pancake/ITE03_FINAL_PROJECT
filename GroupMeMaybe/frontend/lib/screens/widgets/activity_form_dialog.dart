import 'package:flutter/material.dart';

import 'bottom_right_notification.dart';
import '../../models/academic_class.dart';
import '../../models/grouping_activity.dart';
import '../../services/activity_service.dart';

/// Simplified Project Making Dialog based on Workflow Step 4:
/// "Grouping Activity Configuration"
class ActivityFormDialog extends StatefulWidget {
  final GroupingActivity? activity;
  final VoidCallback onSaved;

  const ActivityFormDialog({super.key, this.activity, required this.onSaved});

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
  final _customSkillController = TextEditingController();

  String? _selectedClassDisplay;
  int? _selectedClassId;
  List<AcademicClass> _availableClasses = [];
  bool _loadingClasses = true;

  late DateTime _groupingDeadline;

  final List<String> _requiredSkills = [];
  final List<String> _preferredSkills = [];
  bool _isSaving = false;

  // Streamlined skill pools from Step 4 infographic
  static const List<String> _commonRequiredSkills = [
    'Frontend Development',
    'Backend Development',
    'Database Management',
    'Mobile App Development',
    'UI/UX Design',
    'API Development and Integration',
    'Software Testing and Quality Assurance',
    'Cybersecurity',
    'Full-Stack Development',
  ];

  static const List<String> _commonPreferredSkills = [
    'UI/UX Design',
    'Technical Documentation',
    'Project Management',
    'Research and Problem Solving',
    'Presentation and Communication',
    'Data Analysis',
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.activity;

    _titleController = TextEditingController(text: a?.title ?? 'Final Project');
    _descriptionController = TextEditingController(text: a?.description ?? '');
    _groupCapacityController = TextEditingController(
      text: (a?.groupCapacity ?? 5).toString(),
    );
    _numberOfGroupsController = TextEditingController(
      text: (a?.numberOfGroups ?? 6).toString(),
    );

    _selectedClassDisplay = a?.className;
    _selectedClassId = a?.academicClassId;

    _groupingDeadline =
        a?.groupingDeadline ?? DateTime.now().add(const Duration(days: 21));

    if (a != null) {
      _requiredSkills.addAll(a.requiredSkills);
      _preferredSkills.addAll(a.preferredSkills);
    } else {
      // Default common skills as shown in Step 4 infographic
      _requiredSkills.addAll([
        'Frontend Development',
        'Backend Development',
        'Database Management',
      ]);
      _preferredSkills.addAll(['UI/UX Design', 'Technical Documentation']);
    }

    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _groupCapacityController.dispose();
    _numberOfGroupsController.dispose();
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
          if (_selectedClassDisplay == null && classes.isNotEmpty) {
            _selectedClassDisplay = classes.first.displayName;
            _selectedClassId = classes.first.id;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _groupingDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _groupingDeadline = picked);
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    if (_requiredSkills.isEmpty) {
      AppNotification.showError(
        context,
        'Please select at least one required skill.',
      );
      return;
    }

    setState(() => _isSaving = true);

    final capacity = int.tryParse(_groupCapacityController.text) ?? 5;
    final groups = int.tryParse(_numberOfGroupsController.text) ?? 6;

    final activity = GroupingActivity(
      id: widget.activity?.id,
      academicClassId: _selectedClassId,
      className: _selectedClassDisplay ?? 'Web Development - BSIT 2A',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Final project activity specifications, guidelines, and team requirements.',
      groupingMethod: 'auto',
      groupCapacity: capacity,
      numberOfGroups: groups,
      requiredSkills: _requiredSkills,
      preferredSkills: _preferredSkills,
      minProficiencyLevel: 'Intermediate',
      minCommonHours: 5,
      groupingDeadline: _groupingDeadline,
      status: 'open',
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
                            isEditing ? 'Edit Grouping Activity' : 'Create Grouping Activity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Step 4: Set project requirements to automatically balance teams',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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

                        // Group Size & Number of Groups (Side-by-side)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Group Size',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _groupCapacityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.people_alt_outlined, size: 18),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    validator: (v) => (int.tryParse(v ?? '') ?? 0) < 2 ? 'Min 2' : null,
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
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _numberOfGroupsController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.grid_view_outlined, size: 18),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Min 1' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                          children: _commonRequiredSkills.map((skill) {
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
                          children: _commonPreferredSkills.map((skill) {
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

                        // Grouping Deadline
                        const Text(
                          'Deadline',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDeadline,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF059669)),
                                const SizedBox(width: 10),
                                Text(
                                  '${_groupingDeadline.year}-${_groupingDeadline.month.toString().padLeft(2, '0')}-${_groupingDeadline.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const Spacer(),
                                const Text('Change', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
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
