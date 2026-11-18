import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'landing_page.dart';

// Professor screens
import 'professor/professor_dashboard_screen.dart';
import 'professor/professor_classes_screen.dart';

// Student screens
import 'student/student_dashboard_screen.dart';
import 'student/student_classes_screen.dart';
import 'student/student_teams_screen.dart';

class MainShell extends StatefulWidget {
  final AppState appState;
  final int initialIndex;

  const MainShell({super.key, required this.appState, this.initialIndex = 2});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isSidebarCollapsed = false;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    widget.appState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _setIndex(int idx) {
    setState(() => _selectedIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.appState;
    final user = app.currentUser;
    final bool isProf = app.isProfessor;

    // 4 Primary Navigation Items matching the reference photo
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.grid_view_outlined, 'activeIcon': Icons.grid_view_rounded, 'label': 'Dashboard'},
      {'icon': Icons.school_outlined, 'activeIcon': Icons.school_rounded, 'label': 'Classes'},
      {'icon': Icons.people_outline_rounded, 'activeIcon': Icons.people_rounded, 'label': 'Groups (Teams)'},
      {'icon': Icons.settings_outlined, 'activeIcon': Icons.settings_rounded, 'label': 'Settings'},
    ];

    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 2; // Default to Groups (Teams) gallery
    }

    String topbarTitle = 'Course Projects (Gallery)';
    if (_selectedIndex == 0) {
      topbarTitle = 'Dashboard';
    } else if (_selectedIndex == 1) {
      topbarTitle = 'Classes & Enrollments';
    } else if (_selectedIndex == 2) {
      topbarTitle = 'Course Projects (Gallery)';
    } else if (_selectedIndex == 3) {
      topbarTitle = 'Settings';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Dark Navy Sidebar (Photo Match)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSidebarCollapsed ? 76 : 240,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A), // Dark Navy Background
            ),
            child: Column(
              children: [
                // Top Brand
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB), // Active Blue Theme Logo
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hub_rounded, color: Colors.white, size: 22),
                      ),
                      if (!_isSidebarCollapsed) ...[
                        const SizedBox(width: 12),
                        const Text(
                          'GroupMeMaybe',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Navigation Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: navItems.length,
                    itemBuilder: (context, idx) {
                      final item = navItems[idx];
                      final bool isSelected = _selectedIndex == idx;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => setState(() => _selectedIndex = idx),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _isSidebarCollapsed ? 12 : 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E293B) : Colors.transparent, // Active pill highlight
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? item['activeIcon'] : item['icon'],
                                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                if (!_isSidebarCollapsed) ...[
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item['label'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Log Out Button (Pinned Red Door Icon & Text)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    onTap: () {
                      app.logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LandingPage(appState: app)),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                          if (!_isSidebarCollapsed) ...[
                            const SizedBox(width: 12),
                            const Text(
                              'Log Out',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main View Content
          Expanded(
            child: Column(
              children: [
                // Clean Topbar (Photo Match)
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Hamburger Menu + Page Title
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 22),
                            onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                            tooltip: _isSidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                          ),
                          const SizedBox(width: 12),
                          Text(
                            topbarTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),

                      // Right: Green Circle Avatar + User Name (Alex Santos)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: const Color(0xFF10B981), // Emerald Green
                            child: Text(
                              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            user.fullName.isNotEmpty ? user.fullName : 'Alex Santos',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Page Body Routed by Selected Index
                Expanded(
                  child: _buildCurrentScreen(isProf),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen(bool isProf) {
    final app = widget.appState;
    if (isProf) {
      switch (_selectedIndex) {
        case 0:
          return ProfessorDashboardScreen(appState: app, onNavigate: _setIndex);
        case 1:
          return ProfessorClassesScreen(appState: app);
        case 2:
          return StudentTeamsScreen(appState: app);
        case 3:
          return _buildSettingsScreen();
        default:
          return ProfessorDashboardScreen(appState: app, onNavigate: _setIndex);
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return StudentDashboardScreen(appState: app, onNavigate: _setIndex);
        case 1:
          return StudentClassesScreen(appState: app);
        case 2:
          return StudentTeamsScreen(appState: app); // Course Projects Gallery
        case 3:
          return _buildSettingsScreen();
        default:
          return StudentTeamsScreen(appState: app);
      }
    }
  }

  Widget _buildSettingsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account & System Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            const Text('Manage platform preferences, notifications, and algorithm configurations.', style: TextStyle(color: Color(0xFF64748B))),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined, color: Color(0xFF2563EB)),
              title: const Text('24-Hour Grouping Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Notify students when 24 hours remain before project lockout.'),
              trailing: Switch(value: true, activeTrackColor: const Color(0xFF2563EB), onChanged: (_) {}),
            ),
            ListTile(
              leading: const Icon(Icons.lock_clock_outlined, color: Color(0xFF2563EB)),
              title: const Text('Strict Deadline Lockout', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Disable manual team joining after grouping deadline has passed.'),
              trailing: Switch(value: true, activeTrackColor: const Color(0xFF2563EB), onChanged: (_) {}),
            ),
            ListTile(
              leading: const Icon(Icons.verified_outlined, color: Color(0xFF2563EB)),
              title: const Text('Automatic Custom Skill Sync', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Update student profiles immediately upon professor skill approval.'),
              trailing: Switch(value: true, activeTrackColor: const Color(0xFF2563EB), onChanged: (_) {}),
            ),
          ],
        ),
      ),
    );
  }
}
