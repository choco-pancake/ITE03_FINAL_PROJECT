import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/skill_approval_service.dart';
import 'widgets/student_sidebar.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  // Step 1: Personal & Academic Info
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedBlock = 'BSIT 2A';

  final ProfileService _profileService = ProfileService();
  int? _existingProfileId;

  // Step 2: Technical Skills
  final List<String> _selectedSkills = [
    'Frontend development',
    'UI/UX design',
    'Mobile app development',
  ];

  // Preferred Project Roles (1 to 3 ordered by priority)
  String _rolePriority1 = 'Frontend developer';
  String? _rolePriority2 = 'UI / UX designer';
  String? _rolePriority3 = 'Project leader / team leader';

  // Tools & Technologies
  final List<String> _selectedTools = [
    'Flutter',
    'Dart',
    'Figma',
    'Git',
    'GitHub',
    'HTML',
    'CSS',
  ];

  // Interests
  final List<String> _selectedInterests = [
    'Web development',
    'Mobile apps',
    'UI/UX and creative design',
  ];

  // Availability & Collaboration Mode
  final Set<String> _selectedDays = {'Mon', 'Wed', 'Fri', 'Sat'};
  String _selectedMeetingTime = 'Afternoon (1PM - 5PM)';
  String _collaborationMode = 'Hybrid';
  final _experienceController = TextEditingController(
    text: 'Developed a mobile task tracker in Flutter; built landing pages for school organizations.',
  );

  // Validation state tracking
  final Map<String, bool> _invalidCards = {};
  bool _isSavedAsComplete = true;
  bool _isSaving = false;

  // Options catalogs
  static const List<String> _blocks = [
    'BSIT 2A',
    'BSIT 2B',
    'BSCS 3A',
    'BSCS 3B',
    'BSCS 4A',
  ];

  static const List<String> _allTechnicalSkills = [
    'Frontend development',
    'Backend development',
    'Full-stack development',
    'Mobile app development',
    'UI/UX design',
    'Database management',
    'API development and integration',
    'Software testing and quality assurance',
    'Cybersecurity',
    'Networking',
    'Artificial Intelligence and Machine Learning',
    'Data analysis',
    'System analysis and design',
    'Technical documentation',
    'Project management',
    'Research and problem solving',
    'Presentation and communication',
  ];

  static const List<String> _allProjectRoles = [
    'Project leader / team leader',
    'Frontend developer',
    'Backend developer',
    'Full-stack developer',
    'Mobile app developer',
    'UI / UX designer',
    'Database administrator',
    'System analyst',
    'QA / software tester',
    'Technical writer / documentation specialist',
    'Researcher',
    'Cybersecurity specialist',
    'AI / Machine Learning developer',
    'Data analyst',
  ];

  static const List<String> _allInterests = [
    'Web development',
    'Mobile apps',
    'Software development',
    'AI and machine learning',
    'Data and analytics',
    'Cybersecurity',
    'Networking and cloud',
    'Game development',
    'UI/UX and creative design',
    'Internet of Things and robotics',
    'Business and e-commerce',
    'Education and social impact',
    'Health and science technology',
    'Project management and documentation',
  ];

  static const Map<String, List<String>> _toolCategories = {
    'programming': [
      'Python',
      'Java',
      'JavaScript',
      'TypeScript',
      'PHP',
      'C',
      'C++',
      'C#',
      'Kotlin',
      'Dart',
    ],
    'version_control': ['Git', 'GitHub', 'GitLab', 'Trello', 'Jira', 'Notion'],
    'frontend': [
      'HTML',
      'CSS',
      'React',
      'Vue.js',
      'Angular',
      'Bootstrap',
      'Tailwind CSS',
    ],
    'backend': [
      'Node.js',
      'Express.js',
      'Laravel',
      'Django',
      'Flask',
      'Spring Boot',
      'ASP.NET Core',
    ],
    'mobile': ['Flutter', 'React Native', 'Android Studio', 'Jetpack Compose'],
    'database': [
      'MySQL',
      'PostgreSQL',
      'SQLite',
      'MongoDB',
      'Firebase',
      'Supabase',
    ],
    'ui_ux': ['Figma', 'Adobe XD', 'Canva', 'Adobe Photoshop'],
    'api': ['Postman', 'Swagger', 'Insomnia'],
    'cloud': [
      'Google Cloud',
      'AWS',
      'Microsoft Azure',
      'Vercel',
      'Netlify',
      'Docker',
    ],
    'ai_data': [
      'Jupyter Notebook',
      'Pandas',
      'NumPy',
      'TensorFlow',
      'PyTorch',
      'Power BI',
    ],
    'docs': [
      'Microsoft Word',
      'Excel',
      'PowerPoint',
      'Google Docs',
      'Google Sheets',
    ],
    'security': ['Cisco Packet Tracer', 'Wireshark', 'Nmap', 'Kali Linux'],
  };

  @override
  void initState() {
    super.initState();
    SkillApprovalService().addListener(_onSkillsUpdated);
    _initUserFields();
    _loadExistingProfile();
  }

  void _initUserFields() {
    final user = AuthService.currentUser;
    if (user != null) {
      final parts = user.name.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) _firstNameController.text = parts.first;
      if (parts.length > 2) {
        _middleNameController.text =
            parts.sublist(1, parts.length - 1).join(' ');
        _lastNameController.text = parts.last;
      } else if (parts.length == 2) {
        _lastNameController.text = parts.last;
      }
      _emailController.text = user.email;
      if (user.departmentOrSection != null &&
          user.departmentOrSection!.isNotEmpty) {
        _selectedBlock = user.departmentOrSection!;
      }
      _studentIdController.text =
          '2026-${(user.id ?? 1).toString().padLeft(4, '0')}';
    } else {
      _firstNameController.text = 'Student';
      _lastNameController.text = 'User';
      _studentIdController.text = '2026-0001';
      _emailController.text = 'student@university.edu';
    }
  }

  Future<void> _loadExistingProfile() async {
    try {
      final profiles = await _profileService.getProfiles();
      final currentEmail = _emailController.text.trim();
      final myProfile = profiles.cast<Profile?>().firstWhere(
            (p) =>
                p != null &&
                p.email.toLowerCase() == currentEmail.toLowerCase(),
            orElse: () => null,
          );

      if (myProfile != null && mounted) {
        setState(() {
          _existingProfileId = myProfile.id;
          if (myProfile.skills.isNotEmpty) {
            _selectedSkills.clear();
            _selectedSkills.addAll(myProfile.skills);
          }
          if (myProfile.preferredRole.isNotEmpty) {
            _rolePriority1 = myProfile.preferredRole;
          }
          if (myProfile.interests.isNotEmpty) {
            _selectedInterests.clear();
            _selectedInterests.addAll(myProfile.interests);
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    SkillApprovalService().removeListener(_onSkillsUpdated);
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _onSkillsUpdated() {
    if (mounted) setState(() {});
  }

  List<String> get _combinedTechnicalSkills {
    final approved = SkillApprovalService().approvedSkills;
    return [..._allTechnicalSkills, ...approved];
  }

  // Calculate dynamic proficiency level based on skill counts and tools
  String get _calculatedProficiencyLevel {
    final count = _selectedSkills.length + _selectedTools.length;
    if (count <= 4) return 'Beginner';
    if (count <= 10) return 'Intermediate';
    return 'Advanced';
  }

  double get _completionProgress {
    double progress = 0.0;
    if (_firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty) {
      progress += 0.20;
    }
    if (_studentIdController.text.isNotEmpty && _selectedBlock.isNotEmpty) {
      progress += 0.20;
    }
    if (_selectedSkills.isNotEmpty) progress += 0.20;
    if (_rolePriority1.isNotEmpty) progress += 0.15;
    if (_selectedTools.isNotEmpty) progress += 0.15;
    if (_selectedDays.isNotEmpty) progress += 0.10;
    return progress.clamp(0.0, 1.0);
  }

  // Dynamic tools matching selected technical skills
  List<String> get _relevantToolCategories {
    final categories = <String>{'programming', 'version_control'};

    final skillNames = _selectedSkills.map((s) => s.toLowerCase()).toList();

    for (final skill in skillNames) {
      if (skill.contains('frontend')) categories.add('frontend');
      if (skill.contains('backend')) categories.add('backend');
      if (skill.contains('full-stack')) {
        categories.add('frontend');
        categories.add('backend');
        categories.add('database');
      }
      if (skill.contains('mobile')) categories.add('mobile');
      if (skill.contains('database')) categories.add('database');
      if (skill.contains('ui/ux')) categories.add('ui_ux');
      if (skill.contains('api')) categories.add('api');
      if (skill.contains('networking') || skill.contains('cybersecurity')) {
        categories.add('security');
      }
      if (skill.contains('artificial') || skill.contains('data')) {
        categories.add('ai_data');
      }
      if (skill.contains('documentation')) categories.add('docs');
    }

    return categories.toList();
  }

  void _validateAndSave({required bool isDraft}) async {
    setState(() {
      _invalidCards.clear();
      _isSaving = true;
    });

    if (!isDraft) {
      // Validate Card 1: Info
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _studentIdController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty) {
        _invalidCards['info'] = true;
      }

      // Validate Card 2: Skills
      if (_selectedSkills.isEmpty) {
        _invalidCards['skills'] = true;
      }

      // Validate Card 3: Role
      if (_rolePriority1.isEmpty) {
        _invalidCards['roles'] = true;
      }

      // Validate Card 5: Availability
      if (_selectedDays.isEmpty) {
        _invalidCards['availability'] = true;
      }

      if (_invalidCards.isNotEmpty) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete the highlighted sections to save your full profile.',
            ),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final fullName = [
      _firstNameController.text.trim(),
      _middleNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');

    final profile = Profile(
      id: _existingProfileId,
      name: fullName.isNotEmpty
          ? fullName
          : (_emailController.text.split('@').first),
      email: _emailController.text.trim(),
      skills: _selectedSkills,
      interests: _selectedInterests,
      preferredRole:
          _rolePriority1.isNotEmpty ? _rolePriority1 : 'Frontend developer',
      availability: _selectedBlock,
    );

    try {
      if (_existingProfileId != null) {
        await _profileService.updateProfile(_existingProfileId!, profile);
      } else {
        final created = await _profileService.createProfile(profile);
        _existingProfileId = created.id;
      }
    } catch (_) {
      // Graceful offline fallback
    }

    if (!mounted) return;
    setState(() {
      _isSavedAsComplete = !isDraft;
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isDraft
              ? 'Draft saved successfully!'
              : 'Profile complete! You are now visible in team matching recommendations.',
        ),
        backgroundColor:
            isDraft ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddCustomSkillDialog() {
    final customSkillController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: const [
            Icon(Icons.lightbulb_outline, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text(
              'Request Custom Skill',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom skills must be verified and approved by your professor before they appear on your official team matching card.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: customSkillController,
              decoration: InputDecoration(
                labelText: 'Skill Name',
                hintText: 'e.g. Solidity, Unreal Engine, Kubernetes',
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
            onPressed: () {
              final newSkill = customSkillController.text.trim();
              if (newSkill.isNotEmpty) {
                SkillApprovalService().submitRequest(
                  studentName:
                      '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                          .trim(),
                  studentId: _studentIdController.text.trim(),
                  block: _selectedBlock,
                  skillName: newSkill,
                  domain: 'Custom Student Request',
                );

                setState(() {
                  if (!_selectedSkills.contains(newSkill)) {
                    _selectedSkills.add(newSkill);
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Custom skill "$newSkill" submitted for professor approval.',
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Submit Request'),
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
            currentDestination: StudentNavDestination.settings,
          ),

          // Main Scrollable Form Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'My Profile',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tell us about your skills and availability so we can build the best team for you.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // System Rating Badge
                          _buildProficiencyBadge(_calculatedProficiencyLevel),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Progress Bar Container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                Text(
                                  'Profile Setup Completion (${(_completionProgress * 100).toInt()}%)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                Text(
                                  _isSavedAsComplete
                                      ? '✅ Complete & Active in Matching'
                                      : 'Draft / Incomplete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isSavedAsComplete
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _completionProgress,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _completionProgress >= 0.8
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Step 1: Personal & Academic Info Card
                      _buildSectionCard(
                        id: 'info',
                        title: '1. Personal & Academic Information',
                        subtitle:
                            'Basic student credentials and section assignment',
                        icon: Icons.person_outline,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: 'First Name',
                                    controller: _firstNameController,
                                    hint: 'e.g. Carlos',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Middle Name (Optional)',
                                    controller: _middleNameController,
                                    hint: 'e.g. Alvarez',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Last Name',
                                    controller: _lastNameController,
                                    hint: 'e.g. Mendoza',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    label: 'Student ID Number',
                                    controller: _studentIdController,
                                    hint: 'e.g. 2023-10492',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    label: 'Institutional Email',
                                    controller: _emailController,
                                    hint: 'carlos.mendoza@student.edu',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Class Block / Section',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _selectedBlock,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        items: _blocks
                                            .map(
                                              (b) => DropdownMenuItem(
                                                value: b,
                                                child: Text(
                                                  b,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _selectedBlock = val,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Step 2: Technical Skills Card
                      _buildSectionCard(
                        id: 'skills',
                        title: '2. Technical Skills',
                        subtitle: 'Select all skills you are proficient in (removable with X). Request custom skills if needed.',
                        icon: Icons.code,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    hint: const Text(
                                      'Select a technical skill to add...',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    items: _combinedTechnicalSkills
                                        .where(
                                          (s) => !_selectedSkills.contains(s),
                                        )
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(
                                              s,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(
                                          () => _selectedSkills.add(val),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _showAddCustomSkillDialog,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Request Custom Skill'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E40AF),
                                    side: const BorderSide(
                                      color: Color(0xFFBFDBFE),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Removable Chips with X Icon
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedSkills.map((skill) {
                                return _buildRemovableChip(
                                  label: skill,
                                  color: const Color(0xFFDBEAFE),
                                  textColor: const Color(0xFF1E40AF),
                                  onRemove: () {
                                    setState(
                                      () => _selectedSkills.remove(skill),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Step 3: Preferred Project Roles (Priority 1, 2, 3)
                      _buildSectionCard(
                        id: 'roles',
                        title: '3. Preferred Project Roles',
                        subtitle: 'Select up to three preferred roles ordered by your personal priority.',
                        icon: Icons.badge_outlined,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 650) {
                              return Column(
                                children: [
                                  _buildPriorityRoleDropdown(
                                    priorityLabel:
                                        '1st Priority (Primary Role)',
                                    badgeColor: const Color(0xFF16A34A),
                                    value: _rolePriority1,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _rolePriority1 = val);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _buildPriorityRoleDropdown(
                                    priorityLabel: '2nd Priority (Secondary)',
                                    badgeColor: const Color(0xFF2563EB),
                                    value: _rolePriority2,
                                    onChanged: (val) =>
                                        setState(() => _rolePriority2 = val),
                                    isOptional: true,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildPriorityRoleDropdown(
                                    priorityLabel: '3rd Priority (Tertiary)',
                                    badgeColor: const Color(0xFF6B7280),
                                    value: _rolePriority3,
                                    onChanged: (val) =>
                                        setState(() => _rolePriority3 = val),
                                    isOptional: true,
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildPriorityRoleDropdown(
                                    priorityLabel:
                                        '1st Priority (Primary Role)',
                                    badgeColor: const Color(0xFF16A34A),
                                    value: _rolePriority1,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _rolePriority1 = val);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildPriorityRoleDropdown(
                                    priorityLabel: '2nd Priority (Secondary)',
                                    badgeColor: const Color(0xFF2563EB),
                                    value: _rolePriority2,
                                    onChanged: (val) =>
                                        setState(() => _rolePriority2 = val),
                                    isOptional: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildPriorityRoleDropdown(
                                    priorityLabel: '3rd Priority (Tertiary)',
                                    badgeColor: const Color(0xFF6B7280),
                                    value: _rolePriority3,
                                    onChanged: (val) =>
                                        setState(() => _rolePriority3 = val),
                                    isOptional: true,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Step 4: Tools & Technologies (Dynamic Filtering)
                      _buildSectionCard(
                        id: 'tools',
                        title: '4. Tools & Technologies',
                        subtitle: 'Programming languages & Git appear everywhere. Specialized tools appear automatically based on your technical skills.',
                        icon: Icons.build_circle_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final category in _relevantToolCategories) ...[
                              Text(
                                _categoryTitle(category),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _toolCategories[category]!.map((
                                  tool,
                                ) {
                                  final isSelected = _selectedTools.contains(
                                    tool,
                                  );
                                  return FilterChip(
                                    label: Text(tool),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFFEFF6FF),
                                    checkmarkColor: const Color(0xFF1D4ED8),
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFFCBD5E1),
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedTools.add(tool);
                                        } else {
                                          _selectedTools.remove(tool);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Step 5: Project Interests & Experience
                      _buildSectionCard(
                        id: 'interests',
                        title: '5. Project Interests & Experience',
                        subtitle: 'Select thematic topics you enjoy and outline past capstone/course project experience.',
                        icon: Icons.lightbulb_outline,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _allInterests.map((interest) {
                                final isSelected = _selectedInterests.contains(
                                  interest,
                                );
                                return FilterChip(
                                  label: Text(
                                    interest,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFFECFDF5),
                                  checkmarkColor: const Color(0xFF059669),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedInterests.add(interest);
                                      } else {
                                        _selectedInterests.remove(interest);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Previous Project Experience',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _experienceController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Share a brief summary of projects or coursework you have worked on...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Step 6: Availability & Collaboration Mode
                      _buildSectionCard(
                        id: 'availability',
                        title: '6. Availability & Collaboration Mode',
                        subtitle: 'Help the system find teammates whose schedules align with yours.',
                        icon: Icons.schedule,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Days',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children:
                                  [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ].map((day) {
                                    final isSelected = _selectedDays.contains(
                                      day,
                                    );
                                    return ChoiceChip(
                                      label: Text(day),
                                      selected: isSelected,
                                      selectedColor: const Color(0xFF1E40AF),
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF334155),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedDays.add(day);
                                          } else {
                                            _selectedDays.remove(day);
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Preferred Meeting Time',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _selectedMeetingTime,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        items:
                                            [
                                                  'Morning (8AM - 12PM)',
                                                  'Afternoon (1PM - 5PM)',
                                                  'Evening (after 5PM)',
                                                  'Weekends',
                                                ]
                                                .map(
                                                  (t) => DropdownMenuItem(
                                                    value: t,
                                                    child: Text(
                                                      t,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _selectedMeetingTime = val,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Preferred Collaboration Mode',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _collaborationMode,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        items: ['On-campus', 'Online', 'Hybrid']
                                            .map(
                                              (m) => DropdownMenuItem(
                                                value: m,
                                                child: Text(
                                                  m,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _collaborationMode = val,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Bottom Save Actions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final buttons = Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => _validateAndSave(isDraft: true),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: const Text('Save as Draft'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () => _validateAndSave(isDraft: false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E40AF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check, size: 18),
                                  label: const Text(
                                    'Save Profile',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );

                            if (constraints.maxWidth < 700) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.info_outline,
                                        color: Color(0xFF2563EB),
                                        size: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Saving your complete profile publishes your preferences so you appear in recommendations and can join or form groups.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  buttons,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Saving your complete profile publishes your preferences so you appear in recommendations and can join or form groups.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                buttons,
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
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

  // Section Card container with error state highlighting in red
  Widget _buildSectionCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final hasError = _invalidCards[id] == true;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
          width: hasError ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasError
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: hasError
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasError
                            ? const Color(0xFF991B1B)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasError
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasError)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildRemovableChip({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Icon(Icons.close, size: 16, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityRoleDropdown({
    required String priorityLabel,
    required Color badgeColor,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                priorityLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: value,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          hint: Text(
            isOptional ? 'None' : 'Select role...',
            style: const TextStyle(fontSize: 13),
          ),
          items: [
            if (isOptional)
              const DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'None',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ..._allProjectRoles.map(
              (r) => DropdownMenuItem(
                value: r,
                child: Text(
                  r,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildProficiencyBadge(String level) {
    Color bg;
    Color text;
    IconData icon;

    switch (level) {
      case 'Advanced':
        bg = const Color(0xFFF3E8FF);
        text = const Color(0xFF7E22CE);
        icon = Icons.stars;
        break;
      case 'Intermediate':
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        icon = Icons.verified;
        break;
      default:
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
        icon = Icons.emoji_objects_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: text.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: text),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Skill Level',
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
              Text(
                level,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryTitle(String cat) {
    switch (cat) {
      case 'programming':
        return '💻 PROGRAMMING LANGUAGES';
      case 'version_control':
        return '🔄 VERSION CONTROL & COLLABORATION';
      case 'frontend':
        return '🌐 FRONTEND TECHNOLOGIES';
      case 'backend':
        return '⚙️ BACKEND FRAMEWORKS';
      case 'mobile':
        return '📱 MOBILE APP FRAMEWORKS';
      case 'database':
        return '🗄️ DATABASE MANAGEMENT';
      case 'ui_ux':
        return '🎨 UI / UX DESIGN TOOLS';
      case 'api':
        return '🔌 API TESTING & TOOLS';
      case 'cloud':
        return '☁️ CLOUD & DEPLOYMENT';
      case 'ai_data':
        return '📊 DATA ANALYSIS & AI';
      case 'docs':
        return '📄 DOCUMENTATION & PRODUCTIVITY';
      case 'security':
        return '🛡️ NETWORKING & CYBERSECURITY';
      default:
        return cat.toUpperCase();
    }
  }
}
