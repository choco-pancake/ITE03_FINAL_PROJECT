import 'package:flutter/material.dart';

import '../models/activity_summary.dart';
import '../models/grouping_activity.dart';
import '../services/activity_service.dart';
import 'widgets/activity_card.dart';
import 'widgets/activity_details_dialog.dart';
import 'widgets/activity_form_dialog.dart';
import 'widgets/summary_cards_row.dart';

class ProfessorActivitiesScreen extends StatefulWidget {
  const ProfessorActivitiesScreen({super.key});

  @override
  State<ProfessorActivitiesScreen> createState() =>
      _ProfessorActivitiesScreenState();
}

class _ProfessorActivitiesScreenState extends State<ProfessorActivitiesScreen> {
  final _activityService = ActivityService();
  final _searchController = TextEditingController();

  List<GroupingActivity> _activities = [];
  ActivitySummary _summary = const ActivitySummary();

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summaryFuture = _activityService.getActivitySummary();
      final activitiesFuture = _activityService.getActivities(
        status: _selectedStatus,
        search: _searchController.text.trim(),
      );

      final results = await Future.wait([summaryFuture, activitiesFuture]);

      setState(() {
        _summary = results[0] as ActivitySummary;
        _activities = results[1] as List<GroupingActivity>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ActivityFormDialog(
        onSaved: () {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _openEditDialog(GroupingActivity activity) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ActivityFormDialog(
        activity: activity,
        onSaved: () {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _openDetailsDialog(GroupingActivity activity) {
    showDialog(
      context: context,
      builder: (ctx) => ActivityDetailsDialog(
        activity: activity,
        onEdit: () => _openEditDialog(activity),
      ),
    );
  }

  Future<void> _confirmDelete(GroupingActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity?'),
        content: Text(
          'Are you sure you want to delete "${activity.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _activityService.deleteActivity(activity.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activity deleted.')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting activity: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header: Grouping Activities + + Create Activity button
            _buildPageHeader(),
            const SizedBox(height: 20),

            // Summary Cards
            SummaryCardsRow(
              summary: _summary,
              selectedFilter: _selectedStatus,
              onSelectFilter: (filterKey) {
                setState(() => _selectedStatus = filterKey);
                _loadData();
              },
            ),
            const SizedBox(height: 20),

            // Search & Filter Toolbar
            _buildToolbar(),
            const SizedBox(height: 18),

            // Main Content Area
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_activities.isEmpty)
              _buildEmptyState()
            else
              _buildActivityGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grouping Activities',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create and manage group activities for your classes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey.shade600,
              ),
            ),
          ],
        );

        final createButton = ElevatedButton.icon(
          onPressed: _openCreateDialog,
          icon: const Icon(Icons.add, size: 20),
          label: const Text(
            '+ Create Activity',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E40AF), // Deep royal blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              createButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            titleBlock,
            createButton,
          ],
        );
      },
    );
  }

  Widget _buildToolbar() {
    final statusPills = [
      {'key': 'all', 'label': 'All'},
      {'key': 'active', 'label': 'Active'},
      {'key': 'grouping in progress', 'label': 'In Progress'},
      {'key': 'upcoming', 'label': 'Upcoming'},
      {'key': 'completed', 'label': 'Completed'},
      {'key': 'draft', 'label': 'Draft'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by activity title or class name...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadData();
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _loadData(),
                ),
              ),
              const SizedBox(width: 10),
              // Search button
              OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text('Search'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Refresh button
              IconButton(
                onPressed: _loadData,
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statusPills.map((pill) {
                final isSelected = _selectedStatus == pill['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(pill['label']!),
                    selected: isSelected,
                    selectedColor: const Color(0xFFDBEAFE),
                    checkmarkColor: const Color(0xFF1E40AF),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF1E40AF)
                          : const Color(0xFF475569),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      setState(() => _selectedStatus = pill['key']!);
                      _loadData();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 950;

        if (isWide) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 310,
            ),
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              final activity = _activities[index];
              return ActivityCard(
                activity: activity,
                onViewDetails: () => _openDetailsDialog(activity),
                onEdit: () => _openEditDialog(activity),
                onDelete: () => _confirmDelete(activity),
              );
            },
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _activities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final activity = _activities[index];
            return ActivityCard(
              activity: activity,
              onViewDetails: () => _openDetailsDialog(activity),
              onEdit: () => _openEditDialog(activity),
              onDelete: () => _confirmDelete(activity),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 56, color: Colors.blueGrey.shade300),
            const SizedBox(height: 14),
            const Text(
              'No Activities Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'There are no grouping activities matching your criteria.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create New Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 10),
            const Text(
              'Unable to load activities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.red.shade800),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
