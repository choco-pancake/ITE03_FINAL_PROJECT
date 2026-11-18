import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../models/activity_model.dart';

class ProfileStatusBadge extends StatelessWidget {
  final ProfileCompletionStatus status;

  const ProfileStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case ProfileCompletionStatus.complete:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Complete';
        icon = Icons.check_circle_outline;
        break;
      case ProfileCompletionStatus.incomplete:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Incomplete';
        icon = Icons.error_outline;
        break;
      case ProfileCompletionStatus.uninitialized:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        label = 'Uninitialized';
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class RequestStatusBadge extends StatelessWidget {
  final RequestStatus status;

  const RequestStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case RequestStatus.pending:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Pending';
        break;
      case RequestStatus.underReview:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'Under Review';
        break;
      case RequestStatus.approved:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Approved';
        break;
      case RequestStatus.rejected:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class ActivityStatusBadge extends StatelessWidget {
  final ActivityStatus status;

  const ActivityStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ActivityStatus.draft:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = 'Draft';
        break;
      case ActivityStatus.open:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'Open';
        break;
      case ActivityStatus.groupingInProgress:
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade800;
        label = 'Grouping In Progress';
        break;
      case ActivityStatus.completed:
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade800;
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
