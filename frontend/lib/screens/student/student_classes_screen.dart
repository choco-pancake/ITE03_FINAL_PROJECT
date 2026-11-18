import 'package:flutter/material.dart';
import '../../state/app_state.dart';

class StudentClassesScreen extends StatefulWidget {
  final AppState appState;

  const StudentClassesScreen({super.key, required this.appState});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.appState;
    final user = app.currentUser;
    final enrolledClasses = app.classes.where((c) => c.enrolledStudentIds.contains(user.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Enrolled Classes',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View course subjects or enter a unique class code provided by your professor to enroll.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showJoinClassDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Join Class with Code', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          enrolledClasses.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: Text('You are not currently enrolled in any class. Click "Join Class with Code" to enter a class code.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: enrolledClasses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, idx) {
                    final c = enrolledClasses[idx];
                    return Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.school_outlined, color: Color(0xFF4F46E5), size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${c.code}: ${c.name}',
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                      child: Text(c.section, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Instructor: ${c.professorName} • Enrollment Code: ${c.enrollmentCode}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Icon(Icons.check, size: 14, color: Colors.green.shade800),
                                const SizedBox(width: 6),
                                Text('Enrolled', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showJoinClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Join Class with Enrollment Code', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Enrollment Code *',
                  hintText: 'e.g. GMM-4011',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Ask your instructor for the unique class enrollment code.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final code = _codeController.text.trim();
              if (code.isNotEmpty) {
                final success = widget.appState.enrollInClass(code);
                Navigator.pop(ctx);
                _codeController.clear();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Successfully joined class!'), backgroundColor: Color(0xFF10B981)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid enrollment code. Please check with your instructor.'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Join Class'),
          ),
        ],
      ),
    );
  }
}
