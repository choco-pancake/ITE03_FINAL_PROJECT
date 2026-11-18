import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../state/app_state.dart';
import 'login_signup_screen.dart';

class LandingPage extends StatelessWidget {
  final AppState appState;

  const LandingPage({super.key, required this.appState});

  static const Color activeBlue = Color(0xFF2563EB); // Vibrant Royal Blue

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: activeBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.group_work_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'GroupMeMaybe',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // Topbar Buttons: Log In and Sign Up (with active Blue styling)
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _showAuthDialog(context, initialTab: 0);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeBlue,
                      side: const BorderSide(color: activeBlue, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      _showAuthDialog(context, initialTab: 1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeBlue, // Blue when active
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 56),
            // Title & Subtitle Section
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 840),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: activeBlue),
                          SizedBox(width: 6),
                          Text(
                            'Next-Generation Automated & Collaborative Grouping',
                            style: TextStyle(
                              color: activeBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'GroupMeMaybe Algorithm',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -1.0,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Intelligent team matchmaking driven by verified skills, scheduled availability, complementary roles, and scarcity mitigation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 52),

            // Two Option Boxes: Student Option & Instructor Option
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1040),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWide = constraints.maxWidth > 700;
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildStudentOptionCard(context)),
                              const SizedBox(width: 24),
                              Expanded(child: _buildInstructorOptionCard(context)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildStudentOptionCard(context),
                              const SizedBox(height: 24),
                              _buildInstructorOptionCard(context),
                            ],
                          );
                  },
                ),
              ),
            ),

            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  // Box with Student Option (Page 1)
  Widget _buildStudentOptionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: activeBlue.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Icon(Icons.school_rounded, color: activeBlue, size: 28),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text('Learners & Group Teammates', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Tell us about your skills and availability so we can build the best team for you.',
            style: TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.45),
          ),
          const SizedBox(height: 20),
          const Text(
            'MAIN ROLES & CAPABILITIES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          _buildRoleBullet(Icons.person_outline, 'Build comprehensive profile with technical chips & rated proficiency'),
          _buildRoleBullet(Icons.schedule, 'Set availability days, weekly common hours & preferred meeting windows'),
          _buildRoleBullet(Icons.group_add_outlined, 'Manual & hybrid teammate search with compatibility percentage ring'),
          _buildRoleBullet(Icons.swap_horiz_rounded, 'Submit group switch and profile modification requests'),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showAuthDialog(context, initialTab: 1, defaultRole: UserRole.student);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: activeBlue, // Blue when active
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Join as Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Right Side: Instructor Option (Page 1)
  Widget _buildInstructorOptionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.psychology_alt_rounded, color: Color(0xFF0F172A), size: 28),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructor',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text('Professors & Project Leads', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Configure grouping activities, detect skill scarcity, auto-generate balanced teams, and evaluate requests.',
            style: TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.45),
          ),
          const SizedBox(height: 20),
          const Text(
            'MAIN ROLES & CAPABILITIES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          _buildRoleBullet(Icons.vpn_key_outlined, 'Generate unique class enrollment codes for seamless student onboarding'),
          _buildRoleBullet(Icons.donut_large_rounded, 'Real-time skill distribution & scarcity alert calculations'),
          _buildRoleBullet(Icons.auto_awesome_motion_rounded, 'Auto & Hybrid team generation with drag-and-drop member rebalancing'),
          _buildRoleBullet(Icons.fact_check_outlined, 'Evaluate modification requests and approve custom student-submitted skills'),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showAuthDialog(context, initialTab: 0, defaultRole: UserRole.professor);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Launch Team Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(width: 8),
                  Icon(Icons.rocket_launch_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: activeBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  void _showAuthDialog(BuildContext context, {required int initialTab, UserRole defaultRole = UserRole.student}) {
    showDialog(
      context: context,
      builder: (_) => LoginSignUpDialog(
        appState: appState,
        initialTab: initialTab,
        defaultRole: defaultRole,
      ),
    );
  }
}
