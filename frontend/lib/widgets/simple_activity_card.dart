// Simple activity card used in the Professor Dashboard.
import 'package:flutter/material.dart';

/// A minimal card displaying an activity or project entry.
/// Shows a title, optional description, and an optional tap handler.
class SimpleActivityCard extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback? onTap;

  const SimpleActivityCard({
    Key? key,
    required this.title,
    this.description,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: description != null
            ? Text(
                description!,
                style: const TextStyle(fontSize: 13, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
