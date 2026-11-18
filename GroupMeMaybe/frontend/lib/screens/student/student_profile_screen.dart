import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../data/constants.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_skill_dialog.dart';

class StudentProfileScreen extends StatefulWidget {
  final AppState appState;

  const StudentProfileScreen({super.key, required this.appState});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  int _currentStep = 1; // 1 or 2

  // Step 1 Controllers
  late TextEditingController _firstController;
  late TextEditingController _middleController;
  late TextEditingController _lastController;
  late TextEditingController _idController;
  late TextEditingController _emailController;
  late String _block;

  // Step 2 State
  late List<String> _selectedTechnicalSkills;
  late List<String> _selectedPreferredRoles; // 1-3 ordered
  late List<String> _selectedInterests;
  late List<String> _selectedAvailableDays;
  late String _preferredMeetingTime;
  late int _weeklyCommonHours;
  late String _collaborationMode;
  late TextEditingController _experienceController;
  late List<String> _selectedTools;

  // Validation flags for turning cards red (Page 4)
  bool _step1Invalid = false;
  bool _skillsCardInvalid = false;
  bool _rolesCardInvalid = false;
  bool _interestsCardInvalid = false;
  bool _availabilityCardInvalid = false;

  @override
  void initState() {
    super.initState();
    final user = widget.appState.currentUser;
    _firstController = TextEditingController(text: user.firstName);
    _middleController = TextEditingController(text: user.middleName);
    _lastController = TextEditingController(text: user.lastName);
    _idController = TextEditingController(text: user.studentId);
    _emailController = TextEditingController(text: user.email);
    _block = user.block.isNotEmpty ? user.block : 'BSCS 4-A';

    _selectedTechnicalSkills = List.from(user.technicalSkills);
    _selectedPreferredRoles = List.from(user.preferredRoles);
    _selectedInterests = List.from(user.interests);
    _selectedAvailableDays = List.from(user.availableDays);
    _preferredMeetingTime = user.preferredMeetingTime;
    _weeklyCommonHours = user.weeklyCommonHours;
    _collaborationMode = user.collaborationMode;
    _experienceController = TextEditingController(text: user.previousExperience);
    _selectedTools = List.from(user.toolsAndTechnologies);
  }

  @override
  void dispose() {
    _firstController.dispose();
    _middleController.dispose();
    _lastController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // Calculate live dynamic tools based on selected technical skills (Page 3)
  List<String> get availableTools {
    final Set<String> tools = {};
    // Programming languages and version control appear everywhere
    tools.addAll(AppConstants.programmingLanguages);
    tools.addAll(AppConstants.versionControlTools);

    // Conditional tools based on picked technical skills
    for (var skill in _selectedTechnicalSkills) {
      final matched = AppConstants.conditionalTools[skill];
      if (matched != null) {
        tools.addAll(matched);
      }
    }
    return tools.toList();
  }

  // System rating calculation (Page 4)
  ProficiencyLevel calculateRating() {
    int score = _selectedTechnicalSkills.length * 2 + _selectedTools.length;
    if (_experienceController.text.trim().length > 50) score += 4;
    if (score <= 5) return ProficiencyLevel.beginner;
    if (score <= 12) return ProficiencyLevel.intermediate;
    return ProficiencyLevel.advanced;
  }

  void _validateAndSave({required bool asDraft}) {
    // Reset flags
    setState(() {
      _step1Invalid = _firstController.text.trim().isEmpty || _lastController.text.trim().isEmpty || _idController.text.trim().isEmpty;
      if (!asDraft) {
        _skillsCardInvalid = _selectedTechnicalSkills.isEmpty;
        _rolesCardInvalid = _selectedPreferredRoles.isEmpty;
        _interestsCardInvalid = _selectedInterests.isEmpty;
        _availabilityCardInvalid = _selectedAvailableDays.isEmpty;
      } else {
        _skillsCardInvalid = false;
        _rolesCardInvalid = false;
        _interestsCardInvalid = false;
        _availabilityCardInvalid = false;
      }
    });

    if (!asDraft && (_step1Invalid || _skillsCardInvalid || _rolesCardInvalid || _interestsCardInvalid || _availabilityCardInvalid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Some cards are invalid! Incomplete cards are highlighted in red.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final updated = widget.appState.currentUser.copyWith(
      firstName: _firstController.text.trim(),
      middleName: _middleController.text.trim(),
      lastName: _lastController.text.trim(),
      studentId: _idController.text.trim(),
      email: _emailController.text.trim(),
      block: _block,
      technicalSkills: _selectedTechnicalSkills,
      preferredRoles: _selectedPreferredRoles,
      interests: _selectedInterests,
      availableDays: _selectedAvailableDays,
      preferredMeetingTime: _preferredMeetingTime,
      weeklyCommonHours: _weeklyCommonHours,
      collaborationMode: _collaborationMode,
      previousExperience: _experienceController.text.trim(),
      toolsAndTechnologies: _selectedTools,
    );

    widget.appState.updateStudentProfile(updated, asDraft: asDraft);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(asDraft
            ? 'Profile saved as draft successfully!'
            : 'Profile saved! System assessed your proficiency as: ${updated.proficiencyRating.name.toUpperCase()}'),
        backgroundColor: asDraft ? Colors.amber.shade800 : const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rating = calculateRating();
    final double progress = _currentStep == 1 ? 0.5 : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Jedrik & Ghian, Page 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tell us about your skills and availability so we can build the best team for you.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              // Live System Rating Badge (Page 4)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, color: Color(0xFF4F46E5), size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SYSTEM RATED LEVEL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4338CA), letterSpacing: 0.5)),
                        Text(rating.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar (Page 2)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentStep == 1 ? 'Step 1 of 2: Basic Academic Information' : 'Step 2 of 2: Technical Skills & Availability Cards',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                  ),
                  Text('${(progress * 100).toInt()}% Completed', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Step Switcher Buttons
          Row(
            children: [
              ChoiceChip(
                label: const Text('1. Basic Information'),
                selected: _currentStep == 1,
                onSelected: (val) {
                  if (val) setState(() => _currentStep = 1);
                },
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('2. Skills, Roles & Availability Cards'),
                selected: _currentStep == 2,
                onSelected: (val) {
                  if (val) setState(() => _currentStep = 2);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Form Steps
          if (_currentStep == 1) _buildStep1(context) else _buildStep2(context),

          const SizedBox(height: 32),

          // Bottom Action Bar: Save as Draft or Save Profile (Page 4)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep == 2)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _currentStep = 1),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to Step 1'),
                  )
                else
                  const SizedBox(),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _validateAndSave(asDraft: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save as Draft', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 14),
                    if (_currentStep == 1)
                      ElevatedButton(
                        onPressed: () {
                          if (_firstController.text.trim().isEmpty || _lastController.text.trim().isEmpty || _idController.text.trim().isEmpty) {
                            setState(() => _step1Invalid = true);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out required basic information')));
                          } else {
                            setState(() {
                              _step1Invalid = false;
                              _currentStep = 2;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Row(
                          children: [
                            Text('Proceed to Step 2', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _validateAndSave(asDraft: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check, size: 18),
                            SizedBox(width: 8),
                            Text('Save & Finalize Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Step 1: Basic Information Card (Page 2)
  Widget _buildStep1(BuildContext context) {
    return _wrapCard(
      isInvalid: _step1Invalid,
      title: 'Step 1: Academic & Personal Identification',
      subtitle: 'Official university registration details for class roster verification.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firstController,
                  decoration: InputDecoration(
                    labelText: 'First Name *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _middleController,
                  decoration: InputDecoration(
                    labelText: 'Middle Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _lastController,
                  decoration: InputDecoration(
                    labelText: 'Last Name *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: 'Student ID *',
                    hintText: '2023-XXXXX',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Institutional Email *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _block,
                  decoration: InputDecoration(
                    labelText: 'Block / Section *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: AppConstants.defaultBlocks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _block = val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 2: Cards with removable chips (X icon) (Page 2 & 3)
  Widget _buildStep2(BuildContext context) {
    final app = widget.appState;
    final toolsList = availableTools;

    return Column(
      children: [
        // Card 1: Technical Skills Dropdown & Removable Chips with X icon (Page 2 & 3)
        _wrapCard(
          isInvalid: _skillsCardInvalid,
          title: 'Technical Skills (Removable Chips with X)',
          subtitle: 'Select your key development and design proficiencies. Click X to remove chips.',
          action: TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CustomSkillRequestDialog(appState: app),
              );
            },
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('Request Custom Skill (Professor Approval)'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Technical Skill to Add',
                  hintText: 'Choose from official competencies list',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: app.officialSkills.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null && !_selectedTechnicalSkills.contains(val)) {
                    setState(() {
                      _selectedTechnicalSkills.add(val);
                      _skillsCardInvalid = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              // Removable Chips with X icon (Page 3)
              _selectedTechnicalSkills.isEmpty
                  ? const Text('No technical skills selected yet. Choose one from the dropdown.', style: TextStyle(color: Colors.grey, fontSize: 13))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedTechnicalSkills.map((skill) {
                        return Chip(
                          label: Text(skill, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _selectedTechnicalSkills.remove(skill);
                            });
                          },
                          backgroundColor: const Color(0xFFEEF2FF),
                          side: const BorderSide(color: Color(0xFFC7D2FE)),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Card 2: Preferred Project Roles (1 to 3 ordered by priority) (Page 3)
        _wrapCard(
          isInvalid: _rolesCardInvalid,
          title: 'Preferred Project Role (1 to 3, Ordered by Priority)',
          subtitle: 'Select up to 3 roles in order of preference (1st = primary, 2nd = secondary, 3rd = tertiary).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.projectRoles.map((role) {
                  final int priorityIdx = _selectedPreferredRoles.indexOf(role);
                  final bool isSelected = priorityIdx != -1;
                  return ChoiceChip(
                    label: Text(
                      isSelected ? '#${priorityIdx + 1} $role' : role,
                      style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF4F46E5),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          if (_selectedPreferredRoles.length < 3) {
                            _selectedPreferredRoles.add(role);
                            _rolesCardInvalid = false;
                          }
                        } else {
                          _selectedPreferredRoles.remove(role);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                'Selected Roles Priority: ${_selectedPreferredRoles.isEmpty ? "None" : _selectedPreferredRoles.asMap().entries.map((e) => "${e.key + 1}. ${e.value}").join("  |  ")}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Card 3: Interests (Page 3)
        _wrapCard(
          isInvalid: _interestsCardInvalid,
          title: 'Project Interests',
          subtitle: 'Fields and technological domains you are enthusiastic about tackling.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.interestsList.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return FilterChip(
                label: Text(interest, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedInterests.add(interest);
                      _interestsCardInvalid = false;
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Card 4: Availability & Collaboration Mode (Page 3)
        _wrapCard(
          isInvalid: _availabilityCardInvalid,
          title: 'Availability & Collaboration Preferences',
          subtitle: 'Preferred meeting windows and collaboration days used to calculate schedule overlap.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available Days of the Week:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: AppConstants.daysOfWeek.map((day) {
                  final isSelected = _selectedAvailableDays.contains(day);
                  return FilterChip(
                    label: Text(day, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedAvailableDays.add(day);
                          _availabilityCardInvalid = false;
                        } else {
                          _selectedAvailableDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _preferredMeetingTime,
                      decoration: InputDecoration(
                        labelText: 'Preferred Meeting Time',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: AppConstants.meetingTimes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _preferredMeetingTime = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _weeklyCommonHours,
                      decoration: InputDecoration(
                        labelText: 'Weekly Common Hours',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [4, 6, 8, 10, 12, 16, 20].map((h) => DropdownMenuItem(value: h, child: Text('$h hours/week'))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _weeklyCommonHours = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _collaborationMode,
                      decoration: InputDecoration(
                        labelText: 'Preferred Collaboration Mode',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: AppConstants.collaborationModes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _collaborationMode = val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Card 5: Previous Project Experience (Page 3)
        _wrapCard(
          isInvalid: false,
          title: 'Previous Project Experience',
          subtitle: 'Highlight past software development, UI design, hackathon, or capstone accomplishments.',
          child: TextField(
            controller: _experienceController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Developed a full-stack student portal with Flutter & Supabase, managed Git branch flows...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Card 6: Tools & Technologies (Dynamic conditional on skills picked) (Page 3)
        _wrapCard(
          isInvalid: false,
          title: 'Tools & Technologies (Dynamically Filtered by Skills)',
          subtitle: 'Languages and version control tools appear everywhere. Specialized tools dynamically appear according to your selected skills.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: toolsList.map((tool) {
                  final isSelected = _selectedTools.contains(tool);
                  return FilterChip(
                    label: Text(tool, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedTools.add(tool);
                        } else {
                          _selectedTools.remove(tool);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                '${_selectedTools.length} tools & frameworks selected',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Wrapper for cards that turn red if invalid (Page 4)
  Widget _wrapCard({
    required bool isInvalid,
    required String title,
    required String subtitle,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isInvalid ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isInvalid ? const Color(0xFFEF4444) : Colors.grey.shade200,
          width: isInvalid ? 2.0 : 1.0,
        ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isInvalid) ...[
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isInvalid ? const Color(0xFFB91C1C) : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isInvalid ? Colors.red.shade700 : Colors.grey.shade600)),
                ],
              ),
              if (action != null) action,
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}
