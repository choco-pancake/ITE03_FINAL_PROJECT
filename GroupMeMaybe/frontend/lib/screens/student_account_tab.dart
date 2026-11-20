import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/skill_approval_service.dart';
import 'landing_screen.dart';
import 'widgets/google_auth_button.dart';

class StudentAccountTab extends StatefulWidget {
  const StudentAccountTab({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentAccountTab> createState() => _StudentAccountTabState();
}

class _StudentAccountTabState extends State<StudentAccountTab> {
  String? _error;

  Future<Map<String, String>?> _askProof({
    bool changingPassword = false,
  }) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    String? googleToken;
    String? dialogError;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(changingPassword ? 'Change Password' : 'Delete Account'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!changingPassword)
                    const Text(
                      'This permanently removes your account and saved profile.',
                    ),
                  TextField(
                    controller: current,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                    ),
                  ),
                  if (!changingPassword) ...[
                    const SizedBox(height: 12),
                    const Text('Or verify with your linked Google account:'),
                    GoogleAuthButton(
                      onIdToken: (token) async {
                        refresh(() {
                          googleToken = token;
                          dialogError = null;
                        });
                      },
                      onError: (message) => refresh(() => dialogError = message),
                    ),
                    if (googleToken != null)
                      const Text(
                        'Google account verified',
                        style: TextStyle(color: Colors.green),
                      ),
                  ],
                  if (changingPassword) ...[
                    TextField(
                      controller: next,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                      ),
                    ),
                    TextField(
                      controller: confirm,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                      ),
                    ),
                  ],
                  if (dialogError != null)
                    Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (current.text.isEmpty && googleToken == null) {
                  refresh(
                    () => dialogError =
                        'Enter your current password or verify with Google.',
                  );
                  return;
                }
                if (changingPassword &&
                    (next.text.length < 8 || next.text != confirm.text)) {
                  refresh(
                    () => dialogError =
                        'Use at least 8 characters and matching passwords.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, {
                  'current_password': current.text,
                  'id_token': googleToken ?? '',
                  if (changingPassword) 'password': next.text,
                });
              },
              child: Text(
                changingPassword ? 'Change Password' : 'Delete Account',
              ),
            ),
          ],
        ),
      ),
    );
    current.dispose();
    next.dispose();
    confirm.dispose();
    return result;
  }

  Future<void> _changePassword() async {
    final proof = await _askProof(changingPassword: true);
    if (proof == null) return;
    try {
      await AuthService().changePassword(
        password: proof['password']!,
        currentPassword: proof['current_password'],
        idToken: proof['id_token'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Password updated.')));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _deleteAccount() async {
    final proof = await _askProof();
    if (proof == null) return;
    try {
      await AuthService().deleteAccount(
        currentPassword: proof['current_password'],
        idToken: proof['id_token'],
      );
      SkillApprovalService().removeRequestsForStudent(widget.studentId);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (_) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of GroupMeMaybe?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security,
                  size: 20,
                  color: Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account & Security',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Manage your credentials, active session, and account access.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 18),
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
                      _error!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 1. Change Password
          _buildActionRow(
            title: 'Change Password',
            description: 'Update your institutional account password regularly to keep your account secure.',
            button: OutlinedButton(
              onPressed: _changePassword,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E40AF),
                side: const BorderSide(color: Color(0xFF93C5FD)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Change Password'),
            ),
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),

          // 2. Log Out
          _buildActionRow(
            title: 'Log Out',
            description: 'Sign out of your active session on this device. You will need to log back in.',
            button: OutlinedButton.icon(
              onPressed: _logOut,
              icon: const Icon(Icons.logout, size: 16, color: Color(0xFFDC2626)),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),

          // 3. Delete Account
          _buildActionRow(
            title: 'Delete Account',
            description: 'Permanently remove your account, saved profile, and all team matching records.',
            button: ElevatedButton(
              onPressed: _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete Account'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required String title,
    required String description,
    required Widget button,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              button,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            button,
          ],
        );
      },
    );
  }
}
