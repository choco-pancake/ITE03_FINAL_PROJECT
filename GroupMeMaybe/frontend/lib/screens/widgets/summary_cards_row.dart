import 'package:flutter/material.dart';

import '../../models/activity_summary.dart';

class SummaryCardsRow extends StatelessWidget {
  final ActivitySummary summary;
  final String? selectedFilter;
  final Function(String) onSelectFilter;

  const SummaryCardsRow({
    super.key,
    required this.summary,
    this.selectedFilter,
    required this.onSelectFilter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        final items = [
          _buildSummaryCard(
            title: 'Total Activities',
            count: summary.total,
            icon: Icons.assignment_outlined,
            color: Colors.blue.shade700,
            filterKey: 'all',
          ),
          _buildSummaryCard(
            title: 'Active Activities',
            count: summary.active,
            icon: Icons.trending_up,
            color: const Color(0xFF059669),
            filterKey: 'active',
          ),
          _buildSummaryCard(
            title: 'Upcoming Activities',
            count: summary.upcoming,
            icon: Icons.upcoming_outlined,
            color: Colors.indigo.shade600,
            filterKey: 'upcoming',
          ),
          _buildSummaryCard(
            title: 'Completed Activities',
            count: summary.completed,
            icon: Icons.task_alt,
            color: Colors.blueGrey.shade600,
            filterKey: 'completed',
          ),
        ];

        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: items,
          );
        }

        return Row(
          children: items
              .map((card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: card,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String filterKey,
  }) {
    final isSelected = selectedFilter == filterKey;

    return InkWell(
      onTap: () => onSelectFilter(filterKey),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


