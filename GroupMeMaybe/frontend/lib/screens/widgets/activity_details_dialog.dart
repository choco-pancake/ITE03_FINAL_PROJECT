import 'package:flutter/material.dart';

import '../../models/grouping_activity.dart';

class ActivityDetailsDialog extends StatelessWidget {
  final GroupingActivity activity;
  final VoidCallback onEdit;

  const ActivityDetailsDialog({
    super.key,
    required this.activity,
    required this.onEdit,
  });

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'grouping in progress':
        return Colors.orange;
      case 'completed':
        return Colors.blueGrey;
      case 'draft':
      default:
        return Colors.grey;
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'auto':
        return Colors.purple;
      case 'hybrid':
        return Colors.indigo;
      case 'manual':
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(activity.status);
    final methodColor = _getMethodColor(activity.groupingMethod);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.school, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              activity.className,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      activity.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Scrollable Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      if (activity.description != null && activity.description!.isNotEmpty) ...[
                        const Text(
                          'Activity Description',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            activity.description!,
                            style: TextStyle(color: Colors.grey[800], height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Grid specs
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          _buildDetailTile(
                            icon: Icons.hub,
                            label: 'Grouping Method',
                            value: activity.groupingMethod.toUpperCase(),
                            valueColor: methodColor,
                          ),
                          _buildDetailTile(
                            icon: Icons.groups,
                            label: 'Group Capacity',
                            value: '${activity.groupCapacity} students / team',
                          ),
                          _buildDetailTile(
                            icon: Icons.format_list_numbered,
                            label: 'Planned Groups',
                            value: '${activity.numberOfGroups} teams (${activity.studentsCount} students)',
                          ),
                          _buildDetailTile(
                            icon: Icons.star_rate,
                            label: 'Min Proficiency',
                            value: activity.minProficiencyLevel,
                            valueColor: Colors.deepOrange,
                          ),
                          _buildDetailTile(
                            icon: Icons.access_time,
                            label: 'Min Common Hours',
                            value: '${activity.minCommonHours} hours / week',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Deadlines Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.event, size: 16, color: Colors.blue),
                                      SizedBox(width: 6),
                                      Text(
                                        'Grouping Deadline',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(activity.groupingDeadline),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            if (activity.studentModificationDeadline != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.edit_calendar, size: 16, color: Colors.indigo),
                                        SizedBox(width: 6),
                                        Text(
                                          'Modification Deadline',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDateTime(activity.studentModificationDeadline!),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Required Skills
                      const Text(
                        'Required Skills (Must have in each group)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: activity.requiredSkills.map((skill) {
                          return Chip(
                            label: Text(skill, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            backgroundColor: Colors.blue[50],
                            side: BorderSide(color: Colors.blue[300]!),
                            avatar: const Icon(Icons.check_circle_outline, size: 16, color: Colors.blue),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Preferred Skills
                      if (activity.preferredSkills.isNotEmpty) ...[
                        const Text(
                          'Preferred Skills (Bonus compatibility points)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: activity.preferredSkills.map((skill) {
                            return Chip(
                              label: Text(skill, style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.teal[50],
                              side: BorderSide(color: Colors.teal[300]!),
                              avatar: const Icon(Icons.add_task, size: 16, color: Colors.teal),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Matching Formula Note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.pie_chart, size: 20, color: Colors.amber),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Compatibility algorithm weights: 40% Skills coverage, 30% Shared interests, 30% Availability overlap. Unassigned students will be flagged for scarcity distribution after student sign-up.',
                                style: TextStyle(fontSize: 12, color: Colors.brown[800], height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit();
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Activity'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.grey[900],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
