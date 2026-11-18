import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../state/app_state.dart';
import 'main_shell.dart';

class LoginSignUpDialog extends StatefulWidget {
  final AppState appState;
  final int initialTab; // 0: Login, 1: Sign Up
  final UserRole defaultRole;

  const LoginSignUpDialog({
    super.key,
    required this.appState,
    this.initialTab = 0,
    this.defaultRole = UserRole.student,
  });

  @override
  State<LoginSignUpDialog> createState() => _LoginSignUpDialogState();
}

class _LoginSignUpDialogState extends State<LoginSignUpDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserRole _selectedRole;

  // Active theme color (Blue)
  static const Color activeBlue = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color lightBlueBg = Color(0xFFEFF6FF);

  // Sign In Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController(text: 'password123');

  // Sign Up Controllers
  final _signupFirstController = TextEditingController();
  final _signupLastController = TextEditingController();
  final _signupIdController = TextEditingController(); // Student ID or Employee ID
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  String _signupBlock = 'BSCS 4-A';

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.defaultRole;
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);

    // Prefill demo login email according to default role
    _loginEmailController.text = _selectedRole == UserRole.professor
        ? 'ghian.prof@university.edu'
        : 'alex.santos@university.edu';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupFirstController.dispose();
    _signupLastController.dispose();
    _signupIdController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isStudent = _selectedRole == UserRole.student;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Brand & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: lightBlueBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: activeBlue.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.group_work_rounded, color: activeBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GroupMeMaybe',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Color(0xFF0F172A), letterSpacing: -0.5),
                          ),
                          Text(
                            'University Team Formation Platform',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Segmented TabBar: Sign In & Sign Up (Blue when active)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: activeBlue, // Vibrant Blue when active
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: activeBlue.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF475569),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  dividerColor: Colors.transparent,
                  onTap: (_) => setState(() {}),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Sign In'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Sign Up'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Role Selector Chips (Blue when active)
              Row(
                children: [
                  const Text('Account Type: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.school_outlined,
                      size: 16,
                      color: isStudent ? Colors.white : const Color(0xFF475569),
                    ),
                    label: const Text('Student'),
                    selected: isStudent,
                    selectedColor: activeBlue, // Blue when active
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isStudent ? Colors.white : const Color(0xFF334155),
                      fontWeight: isStudent ? FontWeight.bold : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isStudent ? activeBlue : Colors.grey.shade300,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedRole = UserRole.student;
                          _loginEmailController.text = 'juliana.s@university.edu';
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.psychology_alt_outlined,
                      size: 16,
                      color: !isStudent ? Colors.white : const Color(0xFF475569),
                    ),
                    label: const Text('Instructor'),
                    selected: !isStudent,
                    selectedColor: activeBlue, // Blue when active
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: !isStudent ? Colors.white : const Color(0xFF334155),
                      fontWeight: !isStudent ? FontWeight.bold : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: !isStudent ? activeBlue : Colors.grey.shade300,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedRole = UserRole.professor;
                          _loginEmailController.text = 'ghian.prof@university.edu';
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Animated Forms: Sign In & Sign Up
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  if (_tabController.index == 0) {
                    return _buildSignInTab(context, isStudent);
                  } else {
                    return _buildSignUpTab(context, isStudent);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sign In Tab View
  Widget _buildSignInTab(BuildContext context, bool isStudent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'School Email',
            hintText: isStudent ? 'e.g. student@university.edu' : 'e.g. instructor@university.edu',
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: activeBlue),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: activeBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: activeBlue),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: activeBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_selectedRole == UserRole.professor) {
                widget.appState.loginAsProfessor();
              } else {
                final email = _loginEmailController.text.trim().toLowerCase();
                final matched = widget.appState.students.firstWhere(
                  (s) => s.email.toLowerCase() == email,
                  orElse: () => widget.appState.students.first,
                );
                widget.appState.loginAsStudent(matched.id);
              }
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => MainShell(appState: widget.appState)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: activeBlue, // Blue when active
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isStudent ? 'Sign In as Student' : 'Sign In as Instructor',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Sign Up Tab View: First Name, Last Name, Student-ID / Employee-ID, School Email
  Widget _buildSignUpTab(BuildContext context, bool isStudent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. First Name & Last Name
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _signupFirstController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  hintText: 'e.g. Alex',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: activeBlue),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: activeBlue, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _signupLastController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'e.g. Reyes',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: activeBlue),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: activeBlue, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Student ID (for Students) / Employee ID (for Instructors)
        TextField(
          controller: _signupIdController,
          decoration: InputDecoration(
            labelText: isStudent ? 'Student ID' : 'Employee ID',
            hintText: isStudent ? 'e.g. 2023-10492' : 'e.g. EMP-2041',
            prefixIcon: const Icon(Icons.badge_outlined, color: activeBlue),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: activeBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 3. School Email
        TextField(
          controller: _signupEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'School Email',
            hintText: isStudent ? 'student@university.edu' : 'instructor@university.edu',
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: activeBlue),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: activeBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 4. Password & (if Student, Academic Block)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _signupPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password ',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: activeBlue),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: activeBlue, width: 2),
                  ),
                ),
              ),
            ),
            if (isStudent) ...[
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _signupBlock,
                  decoration: InputDecoration(
                    labelText: 'Block / Section',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: activeBlue, width: 2),
                    ),
                  ),
                  items: ['BSCS 4-A', 'BSCS 4-B', 'BSIT 4-A', 'BSIT 4-B', 'BSIS 3-A']
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _signupBlock = val);
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 22),

        // 5. Submit Sign Up Button (Blue)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final first = _signupFirstController.text.trim();
              final last = _signupLastController.text.trim();
              final id = _signupIdController.text.trim();
              final email = _signupEmailController.text.trim();

              if (first.isEmpty || last.isEmpty || id.isEmpty || email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill out First Name, Last Name, ID, and School Email.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              if (isStudent) {
                final newStudent = UserModel(
                  id: 'stud-${DateTime.now().millisecondsSinceEpoch}',
                  email: email,
                  role: UserRole.student,
                  firstName: first,
                  lastName: last,
                  studentId: id,
                  block: _signupBlock,
                  profileStatus: ProfileCompletionStatus.uninitialized,
                );
                widget.appState.updateStudentProfile(newStudent);
                widget.appState.loginAsStudent(newStudent.id);
              } else {
                final newProf = UserModel(
                  id: 'prof-${DateTime.now().millisecondsSinceEpoch}',
                  email: email,
                  role: UserRole.professor,
                  firstName: first,
                  lastName: last,
                  studentId: id, // Employee ID
                  block: 'Faculty of Computer Studies',
                  profileStatus: ProfileCompletionStatus.complete,
                );
                widget.appState.setCurrentUser(newProf);
              }

              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => MainShell(appState: widget.appState)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: activeBlue, // Blue when active
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isStudent ? 'Complete Student Registration' : 'Register Instructor Account',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
