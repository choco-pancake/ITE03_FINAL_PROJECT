import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/bottom_right_notification.dart';
import 'widgets/portal_top_actions.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  AdminNavDestination _currentNav = AdminNavDestination.overview;

  AdminOverview? _overview;
  List<AdminFacultyMember> _faculty = [];
  List<AdminStudent> _students = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    try {
      final overview = await _adminService.getOverview();
      final faculty = await _adminService.getFaculty();
      final students = await _adminService.getStudents();
      if (mounted) {
        setState(() {
          _overview = overview;
          _faculty = faculty;
          _students = students;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _copyFacultyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    AppNotification.showSuccess(
      context,
      'Code Copied',
      'Faculty Authorization Code "$code" copied to clipboard!',
    );
  }

  Future<void> _openUpdateFacultyCodeDialog() async {
    final controller =
        TextEditingController(text: _overview?.activeFacultyCode ?? '');
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.vpn_key, color: Color(0xFF581C87), size: 22),
              SizedBox(width: 10),
              Text(
                'Update Faculty Access Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set the new authorization code required for new instructors to register. Instructors will use this code during sign-up.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Faculty Authorization Code',
                    hintText: 'e.g. BSIT-FACULTY-2027',
                    errorText: dialogError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF581C87),
              ),
              onPressed: () async {
                final code = controller.text.trim().toUpperCase();
                if (code.length < 4) {
                  setDlgState(() => dialogError = 'Code must be at least 4 characters.');
                  return;
                }
                Navigator.pop(dialogCtx);
                try {
                  await _adminService.updateFacultyCode(code);
                  await _loadAllData();
                  if (mounted) {
                    AppNotification.showSuccess(
                      context,
                      'Code Updated',
                      'Faculty Authorization Code updated to "$code".',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    AppNotification.showError(
                      context,
                      'Update Failed',
                      e.toString().replaceAll('Exception: ', ''),
                    );
                  }
                }
              },
              child: const Text('Save Code'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUpdateSemesterDialog() async {
    String selectedMode = _overview?.semesterMode ?? 'auto';
    String selectedSem = _overview?.manualSemester ?? '1st Semester';
    String selectedAY = _overview?.manualAcademicYear ?? '2026-2027';

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.calendar_month, color: Color(0xFF581C87), size: 22),
              SizedBox(width: 10),
              Text(
                'Configure Academic Semester',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose whether the system automatically calculates the term based on calendar dates, or manually override the semester.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setDlgState(() => selectedMode = 'auto'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedMode == 'auto'
                          ? const Color(0xFFF3E8FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedMode == 'auto'
                            ? const Color(0xFF581C87)
                            : const Color(0xFFE2E8F0),
                        width: selectedMode == 'auto' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedMode == 'auto'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selectedMode == 'auto'
                              ? const Color(0xFF581C87)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-determine by Date (Recommended)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Aug-Dec: 1st Sem • Jan-May: 2nd Sem • Jun-Jul: Summer',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setDlgState(() => selectedMode = 'manual'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedMode == 'manual'
                          ? const Color(0xFFF3E8FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedMode == 'manual'
                            ? const Color(0xFF581C87)
                            : const Color(0xFFE2E8F0),
                        width: selectedMode == 'manual' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedMode == 'manual'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selectedMode == 'manual'
                              ? const Color(0xFF581C87)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manual Override',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Specify an explicit term for the institution.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedMode == 'manual') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSem,
                    decoration: InputDecoration(
                      labelText: 'Semester',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '1st Semester',
                        child: Text('1st Semester'),
                      ),
                      DropdownMenuItem(
                        value: '2nd Semester',
                        child: Text('2nd Semester'),
                      ),
                      DropdownMenuItem(
                        value: 'Midyear / Summer Term',
                        child: Text('Midyear / Summer Term'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedSem = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAY,
                    decoration: InputDecoration(
                      labelText: 'Academic Year',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '2025-2026',
                        child: Text('A.Y. 2025-2026'),
                      ),
                      DropdownMenuItem(
                        value: '2026-2027',
                        child: Text('A.Y. 2026-2027'),
                      ),
                      DropdownMenuItem(
                        value: '2027-2028',
                        child: Text('A.Y. 2027-2028'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedAY = val);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF581C87),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  await _adminService.updateSemester(
                    mode: selectedMode,
                    semester: selectedSem,
                    academicYear: selectedAY,
                  );
                  await _loadAllData();
                  if (mounted) {
                    AppNotification.showSuccess(
                      context,
                      'Calendar Updated',
                      'Academic semester configuration updated successfully.',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    AppNotification.showError(
                      context,
                      'Update Failed',
                      e.toString().replaceAll('Exception: ', ''),
                    );
                  }
                }
              },
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Admin Sidebar
          AdminSidebar(
            currentDestination: _currentNav,
            onDestinationSelected: (dest) {
              setState(() => _currentNav = dest);
            },
          ),

          // Main View Content
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dean ${user?.effectiveFirstName ?? 'Eleanor'} Vance',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Department Chair • College of Computer Studies',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const PortalTopActions(),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Body Content
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _loadAllData,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: _buildMainContent(),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_currentNav) {
      case AdminNavDestination.faculty:
        return _buildFacultySection();
      case AdminNavDestination.academicTerms:
        return _buildAcademicTermsSection();
      case AdminNavDestination.students:
        return _buildStudentsSection();
      case AdminNavDestination.overview:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Metric Cards
            _buildMetricsRow(),
            const SizedBox(height: 28),

            // Faculty Code Management Banner
            _buildFacultyCodeBanner(),
            const SizedBox(height: 28),

            // Academic Semester Control Banner
            _buildSemesterControlBanner(),
            const SizedBox(height: 28),

            // Faculty Roster Preview
            _buildFacultySection(),
            const SizedBox(height: 28),

            // Students Directory Preview
            _buildStudentsSection(),
          ],
        );
    }
  }

  Widget _buildMetricsRow() {
    final ov = _overview;
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            label: 'Registered Faculty',
            value: '${ov?.totalFaculty ?? 0}',
            icon: Icons.badge,
            color: const Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _metricCard(
            label: 'Enrolled Students',
            value: '${ov?.totalStudents ?? 0}',
            icon: Icons.people_alt,
            color: const Color(0xFF047857),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _metricCard(
            label: 'Course Sections',
            value: '${ov?.totalClasses ?? 0}',
            icon: Icons.school,
            color: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _metricCard(
            label: 'Current Academic Term',
            value: ov?.semester ?? '1st Sem',
            subtitle: 'A.Y. ${ov?.academicYear ?? '2026-2027'}',
            icon: Icons.calendar_month,
            color: const Color(0xFF581C87),
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyCodeBanner() {
    final code = _overview?.activeFacultyCode ?? 'BSIT-FACULTY-2026';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.vpn_key,
                  color: Color(0xFF581C87),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faculty Authorization Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'This code is issued to instructors so they can register their official faculty account.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Change Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF581C87),
                ),
                onPressed: _openUpdateFacultyCodeDialog,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT ACTIVE CODE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                        color: Color(0xFF581C87),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Faculty Code'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF581C87),
                  ),
                  onPressed: () => _copyFacultyCode(code),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterControlBanner() {
    final ov = _overview;
    final isAuto = ov?.semesterMode == 'auto';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Color(0xFF1E40AF),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Academic Calendar & Active Semester',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isAuto
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAuto ? 'AUTO-CALCULATED' : 'MANUAL OVERRIDE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAuto
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Current Active Term: ${ov?.semester ?? '1st Semester'} • Academic Year ${ov?.academicYear ?? '2026-2027'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAuto
                      ? 'The system determines the semester automatically based on university dates (August-December: 1st Sem, January-May: 2nd Sem, June-July: Summer).'
                      : 'The Department Chair has set a manual semester override for this department.',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Configure'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E40AF),
            ),
            onPressed: _openUpdateSemesterDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildFacultySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Department Faculty Directory',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                '${_faculty.length} Faculty Members',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_faculty.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No registered faculty members found.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(2.5),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'FACULTY NAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'EMAIL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'DEPARTMENT / OFFICE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                ..._faculty.map(
                  (f) => TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF1E40AF),
                              child: Text(
                                f.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          f.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          f.department,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStudentsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Enrolled Student Directory & Profile Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                '${_students.length} Registered Students',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_students.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No registered students found.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'STUDENT NAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'EMAIL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'SECTION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'PROFILE STATUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                ..._students.map(
                  (s) => TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          s.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          s.section,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: _statusBadge(s.status),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'complete':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        text = 'COMPLETE';
        break;
      case 'incomplete':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        text = 'INCOMPLETE';
        break;
      case 'uninitialized':
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        text = 'UNINITIALIZED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildAcademicTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSemesterControlBanner(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'University Academic Calendar Guide',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The default academic calendar follows the Philippine Commission on Higher Education (CHED) and university standard schedule:\n\n'
                '• 1st Semester: August 1 to December 31\n'
                '• 2nd Semester: January 1 to May 31\n'
                '• Midyear / Summer Term: June 1 to July 31\n\n'
                'When "Auto-determine" is selected, the system computes the active semester in real-time from the current server date. If the university operates on an alternative trimester or academic adjustment, select "Manual Override" above.',
                style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
