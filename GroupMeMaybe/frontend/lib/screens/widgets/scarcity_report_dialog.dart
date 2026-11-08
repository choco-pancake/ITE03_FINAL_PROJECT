import 'package:flutter/material.dart';

import '../../models/grouping_activity.dart';
import '../../models/scarcity_report.dart';
import '../../services/activity_service.dart';

class ScarcityReportDialog extends StatefulWidget {
  final GroupingActivity activity;
  final VoidCallback onUpdated;

  const ScarcityReportDialog({
    super.key,
    required this.activity,
    required this.onUpdated,
  });

  @override
  State<ScarcityReportDialog> createState() => _ScarcityReportDialogState();
}

class _ScarcityReportDialogState extends State<ScarcityReportDialog> {
  final _activityService = ActivityService();
  final _customSkillController = TextEditingController();

  ScarcityReport? _report;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAutoForming = false;
  bool _isAddingSkill = false;
  String _autoFormStrategy = 'fill_incomplete'; // fill_incomplete or new_teams

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _customSkillController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report =
          await _activityService.getScarcityReport(widget.activity.id!);
      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _triggerAutoForm() async {
    setState(() => _isAutoForming = true);

    try {
      final result = await _activityService.autoFormUnassigned(
        widget.activity.id!,
        strategy: _autoFormStrategy,
      );

      if (mounted) {
        setState(() => _isAutoForming = false);
        Navigator.of(context).pop();
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ??
                'Successfully auto-formed unassigned students!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAutoForming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-form failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addSkill(bool isRequired) async {
    final skill = _customSkillController.text.trim();
    if (skill.isEmpty) return;

    setState(() => _isAddingSkill = true);

    try {
      await _activityService.addSkillToActivity(
        widget.activity.id!,
        skill,
        isRequired ? 'required' : 'preferred',
      );
      _customSkillController.clear();
      widget.onUpdated();
      await _loadReport();
      if (mounted) {
        setState(() => _isAddingSkill = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$skill" to activity.'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingSkill = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add skill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics_outlined,
                        color: Color(0xFF1E40AF), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Class Skill Distribution & Scarcity Report',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.activity.title} • ${widget.activity.className}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey.shade600,
                          ),
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
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),

              // Content Body
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Error: $_errorMessage',
                                    style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadReport,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _buildReportContent(_report!),
              ),

              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grouping mode: ${widget.activity.groupingMethod.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isAutoForming ? null : _triggerAutoForm,
                        icon: _isAutoForming
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Auto-Form Unassigned Students'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(ScarcityReport report) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat chips row
          Row(
            children: [
              _buildMiniMetric(
                label: 'Enrolled Students',
                value: '${report.totalStudents}',
                icon: Icons.people_outline,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 12),
              _buildMiniMetric(
                label: 'Target Teams',
                value: '${report.numberOfGroups}',
                icon: Icons.grid_view,
                color: Colors.indigo.shade700,
              ),
              const SizedBox(width: 12),
              _buildMiniMetric(
                label: 'Unassigned',
                value: '${report.unassignedStudentsCount}',
                icon: Icons.person_search,
                color: Colors.amber.shade900,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scarce skills notification banner
          if (report.hasScarcity) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.amber.shade900, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Scarce Skills Identified',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'There are fewer students specializing in these required skills than the planned ${report.numberOfGroups} groups:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.brown.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: report.scarceSkills.map((s) {
                      return Chip(
                        avatar: const Icon(Icons.error_outline,
                            size: 16, color: Colors.red),
                        label: Text(
                          '${s.skill}: ${s.count} students (Needs ${s.needed}, deficit -${s.deficit})',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.red.shade300),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recommendation: Use the Auto-Form tool below to distribute unassigned students and balance specialists evenly across teams.',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.brown.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Skill Distribution List Header
          const Text(
            'Skill Distribution Breakdown',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),

          // Skill Distribution bars
          ...report.skillsDistribution.map((item) {
            Color barColor = const Color(0xFF059669); // Green
            if (item.isScarce) {
              barColor = const Color(0xFFDC2626); // Red
            } else if (item.percentage < 30) {
              barColor = const Color(0xFFD97706); // Amber
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.skill,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.isRequired
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: item.isRequired
                                    ? const Color(0xFFBFDBFE)
                                    : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Text(
                              item.isRequired ? 'REQUIRED' : 'PREFERRED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: item.isRequired
                                    ? const Color(0xFF1E40AF)
                                    : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                          if (item.isScarce) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: const Color(0xFFFECACA)),
                              ),
                              child: const Text(
                                'SCARCE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${item.count}/${item.totalStudents} (${item.percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: item.percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // Add to activity section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '+ Add to Activity',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customSkillController,
                        decoration: InputDecoration(
                          hintText: 'Enter new skill to add (e.g. Docker, DevOps, Cloud)',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _isAddingSkill ? null : () => _addSkill(true),
                      child: const Text('+ Required'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _isAddingSkill ? null : () => _addSkill(false),
                      child: const Text('+ Preferred'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Strategy Selector for Auto-Form
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune, size: 20, color: Color(0xFF1E40AF)),
                const SizedBox(width: 10),
                const Text(
                  'Auto-Form Strategy:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(width: 14),
                DropdownButton<String>(
                  value: _autoFormStrategy,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'fill_incomplete',
                      child: Text('Fill Incomplete Teams First'),
                    ),
                    DropdownMenuItem(
                      value: 'new_teams',
                      child: Text('Form New Teams Only'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _autoFormStrategy = val);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
