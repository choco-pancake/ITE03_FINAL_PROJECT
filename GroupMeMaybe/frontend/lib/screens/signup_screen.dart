import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'professor_dashboard_screen.dart';
import 'student_dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  final String? initialRole;

  const SignupScreen({super.key, this.initialRole});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _deptOrSectionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  late String _selectedRole; // 'student' or 'professor'
  String _preferredProjectRole = 'Frontend Developer';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = true;
  bool _isLoading = false;
  String? _errorMessage;

  static const List<String> _studentRoles = [
    'Project Leader / Team Leader',
    'Frontend Developer',
    'Backend Developer',
    'Full-Stack Developer',
    'Mobile App Developer',
    'UI / UX Designer',
    'Database Administrator',
    'System Analyst',
    'QA / Software Tester',
    'Technical Writer / Documentation Specialist',
    'Researcher',
    'Cybersecurity Specialist',
    'AI / Machine Learning Developer',
    'Data Analyst',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole?.toLowerCase() == 'professor'
        ? 'professor'
        : 'student';
    if (_selectedRole == 'student') {
      _deptOrSectionController.text = 'BSIT 2A';
    } else {
      _deptOrSectionController.text = 'College of Computer Studies';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _deptOrSectionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'student' && _deptOrSectionController.text == 'College of Computer Studies') {
        _deptOrSectionController.text = 'BSIT 2A';
      } else if (role == 'professor' && _deptOrSectionController.text == 'BSIT 2A') {
        _deptOrSectionController.text = 'College of Computer Studies';
      }
    });
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service to proceed.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        departmentOrSection: _deptOrSectionController.text.trim(),
        preferredRole: _selectedRole == 'student' ? _preferredProjectRole : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account successfully created! Welcome, ${user.name}!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Route to respective portal
      if (user.isProfessor) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProfessorDashboardScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = _selectedRole == 'student';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo & Header
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.hub, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'GroupMeMaybe',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Join the platform to build balanced, high-performing teams.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Alert Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Role Selection Cards
                    const Text(
                      'I am registering as a:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleCard(
                            role: 'student',
                            title: 'Student',
                            icon: Icons.school,
                            isSelected: isStudent,
                            activeColor: const Color(0xFF1E40AF),
                            activeBg: const Color(0xFFEFF6FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRoleCard(
                            role: 'professor',
                            title: 'Instructor / Prof',
                            icon: Icons.co_present,
                            isSelected: !isStudent,
                            activeColor: const Color(0xFF4338CA),
                            activeBg: const Color(0xFFEEF2FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Full Name Input
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: isStudent ? 'e.g. Carlos Mendoza' : 'e.g. Prof. Aivhan Navarro',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.person_outline, size: 18, color: Color(0xFF64748B)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Email Address Input
                    const Text(
                      'Institutional Email Address',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: isStudent ? 'carlos@student.edu' : 'prof@university.edu',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF64748B)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your institutional email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Role-Specific Field (Section or Department)
                    Text(
                      isStudent ? 'Class Section / Block' : 'Department / College',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _deptOrSectionController,
                      decoration: InputDecoration(
                        hintText: isStudent ? 'e.g. BSIT 2A' : 'e.g. College of Computer Studies',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: Icon(
                          isStudent ? Icons.class_outlined : Icons.account_balance_outlined,
                          size: 18,
                          color: const Color(0xFF64748B),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Student Preferred Role Dropdown
                    if (isStudent) ...[
                      const Text(
                        'Primary Preferred Project Role',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _preferredProjectRole,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF64748B)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
                          ),
                        ),
                        items: _studentRoles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(
                              role,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _preferredProjectRole = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Password Input
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Create a password (min. 6 characters)',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF64748B)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password Input
                    const Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        hintText: 'Re-enter your password',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.lock_reset, size: 18, color: Color(0xFF64748B)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            activeColor: const Color(0xFF1E40AF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() => _agreedToTerms = val ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'I agree to the GroupMeMaybe Honor Code and Privacy Policy regarding student project collaboration.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bottom Sign In Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeBg,
  }) {
    return InkWell(
      onTap: () => _onRoleChanged(role),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
