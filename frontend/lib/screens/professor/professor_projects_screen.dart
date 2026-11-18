// import 'package:flutter/material.dart';
// import '../../models/activity_model.dart';
// import '../../state/app_state.dart';
// import '../../widgets/status_badge.dart';

// class ProfessorProjectsScreen extends StatefulWidget {
//   final AppState appState;

//   const ProfessorProjectsScreen({super.key, required this.appState});

//   @override
//   State<ProfessorProjectsScreen> createState() => _ProfessorProjectsScreenState();
// }

// class _ProfessorProjectsScreenState extends State<ProfessorProjectsScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final app = widget.appState;
//     final activities = app.activities;

//     // Summary cards calculation (Aivhan, Page 2)
//     final total = activities.length;
//     final active = activities.where((a) => a.status == ActivityStatus.open || a.status == ActivityStatus.groupingInProgress).length;
//     final upcoming = activities.where((a) => a.groupingDeadline.isAfter(DateTime.now()) && a.status == ActivityStatus.open).length;
//     final completed = activities.where((a) => a.status == ActivityStatus.completed).length;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(28.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Title & Description (Aivhan, Page 1)
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Grouping Activities',
//                     style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
//                   ),
//                   const SizedBox(height: 4),
//                   const Text(
//                     'Create and manage group activities for your classes',
//                     style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
//                   ),
//                 ],
//               ),
//               ElevatedButton.icon(
//                 onPressed: () => _showCreateActivityDialog(context),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF4F46E5),
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   elevation: 0,
//                 ),
//                 icon: const Icon(Icons.add_rounded, size: 20),
//                 label: const Text('+ Create Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),

//           // Summary Cards (Total, Active, Upcoming, Completed)
//           Row(
//             children: [
//               Expanded(child: _buildSummaryCard('Total Activities', '$total', Icons.folder_copy_outlined, const Color(0xFF4F46E5))),
//               const SizedBox(width: 16),
//               Expanded(child: _buildSummaryCard('Active Activities', '$active', Icons.play_circle_outline, const Color(0xFF10B981))),
//               const SizedBox(width: 16),
//               Expanded(child: _buildSummaryCard('Upcoming Activities', '$upcoming', Icons.access_time_rounded, const Color(0xFFF59E0B))),
//               const SizedBox(width: 16),
//               Expanded(child: _buildSummaryCard('Completed Activities', '$completed', Icons.task_alt_rounded, const Color(0xFF64748B))),
//             ],
//           ),
//           const SizedBox(height: 28),

//           // Group Activity List
//           const Text('All Activity Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
//           const SizedBox(height: 14),

//           activities.isEmpty
//               ? Container(
//                   padding: const EdgeInsets.all(48),
//                   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
//                   child: const Center(child: Text('No activities created yet. Click "+ Create Activity" to begin.')),
//                 )
//               : ListView.separated(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: activities.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 16),
//                   itemBuilder: (ctx, idx) {
//                     final act = activities[idx];
//                     return _buildActivityCard(context, act);
//                   },
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: color.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, color: color, size: 24),
//           ),
//           const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
//               const SizedBox(height: 2),
//               Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActivityCard(BuildContext context, ActivityModel act) {
//     final app = widget.appState;
//     final targetClass = app.classes.firstWhere((c) => c.id == act.classId, orElse: () => app.classes.first);
//     final int enrolledCount = targetClass.enrolledStudentIds.length;

//     return Container(
//       padding: const EdgeInsets.all(22),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Top Row: Title, Class, Method, Status
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Row(
//                   children: [
//                     Text(
//                       act.title,
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
//                     ),
//                     const SizedBox(width: 10),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                       decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
//                       child: Text(act.className, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
//                     ),
//                     const SizedBox(width: 8),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                       decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
//                       child: Text('Method: ${act.groupingMethodLabel}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
//                     ),
//                   ],
//                 ),
//               ),
//               ActivityStatusBadge(status: act.status),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(act.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
//           const SizedBox(height: 14),

//           // Details row: Students, Required Skills, Preferred Skills, Deadline
//           Wrap(
//             spacing: 20,
//             runSpacing: 8,
//             children: [
//               _buildDetailItem(Icons.groups_rounded, '$enrolledCount Enrolled Students • Target Size: ${act.groupCapacity}'),
//               _buildDetailItem(Icons.schedule, 'Min Common: ${act.minCommonHours}h/wk • Min Level: ${act.minProficiencyLevel}'),
//               _buildDetailItem(Icons.event_available, 'Grouping Deadline: ${act.groupingDeadline.month}/${act.groupingDeadline.day}/${act.groupingDeadline.year}'),
//               _buildDetailItem(Icons.lock_clock, 'Modification Lock: ${act.studentModificationDeadline.month}/${act.studentModificationDeadline.day}/${act.studentModificationDeadline.year}'),
//             ],
//           ),
//           const SizedBox(height: 14),

//           // Skill chips
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('Required Skills: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
//               Expanded(
//                 child: Wrap(
//                   spacing: 6,
//                   runSpacing: 4,
//                   children: act.requiredSkills.map((s) {
//                     return Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                       decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
//                       child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ],
//           ),
//           if (act.preferredSkills.isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('Preferred Skills: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
//                 Expanded(
//                   child: Wrap(
//                     spacing: 6,
//                     runSpacing: 4,
//                     children: act.preferredSkills.map((s) {
//                       return Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
//                         child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple.shade800)),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//           const Divider(height: 24),

//           // Buttons: View Details, Edit, Delete (Aivhan, Page 2)
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               OutlinedButton.icon(
//                 onPressed: () {
//                   _showActivityDetailsModal(context, act);
//                 },
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: const Color(0xFF334155),
//                   side: BorderSide(color: Colors.grey.shade300),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 icon: const Icon(Icons.visibility_outlined, size: 16),
//                 label: const Text('View Details'),
//               ),
//               const SizedBox(width: 10),
//               OutlinedButton.icon(
//                 onPressed: () {
//                   _showEditActivityDialog(context, act);
//                 },
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: const Color(0xFF4F46E5),
//                   side: const BorderSide(color: Color(0xFF4F46E5)),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 icon: const Icon(Icons.edit_outlined, size: 16),
//                 label: const Text('Edit'),
//               ),
//               const SizedBox(width: 10),
//               IconButton(
//                 icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
//                 tooltip: 'Delete Activity',
//                 onPressed: () {
//                   _confirmDeleteActivity(context, act);
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailItem(IconData icon, String text) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 14, color: Colors.grey.shade600),
//         const SizedBox(width: 6),
//         Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
//       ],
//     );
//   }

//   // Create Activity Form Dialog (Page 1 & 2)
//   void _showCreateActivityDialog(BuildContext context) {
//     final app = widget.appState;
//     String selectedClassId = app.classes.first.id;
//     final titleController = TextEditingController();
//     final descController = TextEditingController();
//     GroupingMethod groupingMethod = GroupingMethod.auto;
//     int groupCapacity = 4;
//     String minProficiency = 'Intermediate';
//     int minCommonHours = 6;
//     DateTime groupingDeadline = DateTime.now().add(const Duration(days: 4));
//     DateTime modificationDeadline = DateTime.now().add(const Duration(days: 6));
//     List<String> selectedRequiredSkills = ['Frontend Development', 'Backend Development', 'UI/UX Design'];
//     List<String> selectedPreferredSkills = ['API Development and Integration'];

//     showDialog(
//       context: context,
//       builder: (ctx) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//               title: const Text('Activity Configuration Form', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//               content: SizedBox(
//                 width: 680,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Class Selection Dropdown
//                       DropdownButtonFormField<String>(
//                         value: selectedClassId,
//                         decoration: InputDecoration(
//                           labelText: 'Class Selection *',
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         items: app.classes.map((c) {
//                           return DropdownMenuItem(value: c.id, child: Text('${c.code} - ${c.name} (${c.section})'));
//                         }).toList(),
//                         onChanged: (val) {
//                           if (val != null) setDialogState(() => selectedClassId = val);
//                         },
//                       ),
//                       const SizedBox(height: 14),

//                       // Title & Description
//                       TextField(
//                         controller: titleController,
//                         decoration: InputDecoration(
//                           labelText: 'Activity Title *',
//                           hintText: 'e.g. Capstone Phase 1: Team Project',
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                       ),
//                       const SizedBox(height: 14),
//                       TextField(
//                         controller: descController,
//                         maxLines: 2,
//                         decoration: InputDecoration(
//                           labelText: 'Activity Description *',
//                           hintText: 'Objectives, expectations, and deliverables...',
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                       ),
//                       const SizedBox(height: 16),

//                       // Grouping Method, Capacity, Common Hours
//                       Row(
//                         children: [
//                           Expanded(
//                             child: DropdownButtonFormField<GroupingMethod>(
//                               value: groupingMethod,
//                               decoration: InputDecoration(
//                                 labelText: 'Grouping Method *',
//                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                               ),
//                               items: const [
//                                 DropdownMenuItem(value: GroupingMethod.auto, child: Text('Auto (Algorithm)')),
//                                 DropdownMenuItem(value: GroupingMethod.hybrid, child: Text('Hybrid (Manual + Auto Patch)')),
//                                 DropdownMenuItem(value: GroupingMethod.manual, child: Text('Manual (Student Invitations)')),
//                               ],
//                               onChanged: (val) {
//                                 if (val != null) setDialogState(() => groupingMethod = val);
//                               },
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: DropdownButtonFormField<int>(
//                               value: groupCapacity,
//                               decoration: InputDecoration(
//                                 labelText: 'Group Capacity (Team Size)',
//                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                               ),
//                               items: [2, 3, 4, 5, 6].map((s) => DropdownMenuItem(value: s, child: Text('$s Students'))).toList(),
//                               onChanged: (val) {
//                                 if (val != null) setDialogState(() => groupCapacity = val);
//                               },
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: DropdownButtonFormField<int>(
//                               value: minCommonHours,
//                               decoration: InputDecoration(
//                                 labelText: 'Min Common Hours',
//                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                               ),
//                               items: [4, 6, 8, 10, 12].map((h) => DropdownMenuItem(value: h, child: Text('$h hrs/week'))).toList(),
//                               onChanged: (val) {
//                                 if (val != null) setDialogState(() => minCommonHours = val);
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),

//                       // Proficiency Level
//                       DropdownButtonFormField<String>(
//                         value: minProficiency,
//                         decoration: InputDecoration(
//                           labelText: 'Minimum Proficiency Level',
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         items: ['Beginner', 'Intermediate', 'Advanced'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
//                         onChanged: (val) {
//                           if (val != null) setDialogState(() => minProficiency = val);
//                         },
//                       ),
//                       const SizedBox(height: 16),

//                       // Required Skills Chips Selection
//                       const Text('Required Skills (Each team must cover these):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 6,
//                         children: app.officialSkills.map((skill) {
//                           final isSelected = selectedRequiredSkills.contains(skill);
//                           return FilterChip(
//                             label: Text(skill, style: const TextStyle(fontSize: 12)),
//                             selected: isSelected,
//                             onSelected: (val) {
//                               setDialogState(() {
//                                 if (val) {
//                                   selectedRequiredSkills.add(skill);
//                                 } else {
//                                   selectedRequiredSkills.remove(skill);
//                                 }
//                               });
//                             },
//                           );
//                         }).toList(),
//                       ),
//                       const SizedBox(height: 16),

//                       // Deadlines: Grouping Deadline & Student Modification Deadline
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text('Grouping Deadline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
//                                   const SizedBox(height: 4),
//                                   Text('${groupingDeadline.month}/${groupingDeadline.day}/${groupingDeadline.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text('Modification Deadline (Lockout)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
//                                   const SizedBox(height: 4),
//                                   Text('${modificationDeadline.month}/${modificationDeadline.day}/${modificationDeadline.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               // Cancel and Create Activity buttons (Page 2)
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(ctx),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     if (titleController.text.trim().isNotEmpty) {
//                       final targetCls = app.classes.firstWhere((c) => c.id == selectedClassId);
//                       final newAct = ActivityModel(
//                         id: 'act-${DateTime.now().millisecondsSinceEpoch}',
//                         classId: targetCls.id,
//                         className: '${targetCls.code} - ${targetCls.name}',
//                         title: titleController.text.trim(),
//                         description: descController.text.trim().isNotEmpty ? descController.text.trim() : 'Project grouping activity.',
//                         groupingMethod: groupingMethod,
//                         groupCapacity: groupCapacity,
//                         requiredSkills: selectedRequiredSkills,
//                         preferredSkills: selectedPreferredSkills,
//                         minProficiencyLevel: minProficiency,
//                         minCommonHours: minCommonHours,
//                         groupingDeadline: groupingDeadline,
//                         studentModificationDeadline: modificationDeadline,
//                         status: ActivityStatus.open,
//                       );

//                       app.createActivity(newAct);
//                       Navigator.pop(ctx);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Grouping activity created successfully!'),
//                           backgroundColor: Color(0xFF10B981),
//                         ),
//                       );
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF4F46E5),
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                   ),
//                   child: const Text('Create Activity'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   void _showActivityDetailsModal(BuildContext context, ActivityModel act) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Text(act.title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         content: SizedBox(
//           width: 500,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Class: ${act.className}'),
//               const SizedBox(height: 8),
//               Text('Method: ${act.groupingMethodLabel} • Status: ${act.statusLabel}'),
//               const SizedBox(height: 8),
//               Text('Description: ${act.description}'),
//               const SizedBox(height: 12),
//               Text('Target Capacity: ${act.groupCapacity} students per team'),
//               Text('Min Common Hours: ${act.minCommonHours} hours/week'),
//               Text('Min Proficiency: ${act.minProficiencyLevel}'),
//               const SizedBox(height: 12),
//               const Text('Required Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
//               Text(act.requiredSkills.join(', ')),
//               const SizedBox(height: 12),
//               Text('Grouping Deadline: ${act.groupingDeadline}'),
//               Text('Student Modification Lockout: ${act.studentModificationDeadline}'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
//         ],
//       ),
//     );
//   }

//   void _showEditActivityDialog(BuildContext context, ActivityModel act) {
//     final titleCtrl = TextEditingController(text: act.title);
//     final descCtrl = TextEditingController(text: act.description);
//     int capacity = act.groupCapacity;

//     showDialog(
//       context: context,
//       builder: (ctx) {
//         return StatefulBuilder(
//           builder: (c, setS) => AlertDialog(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             title: const Text('Edit Activity Configuration'),
//             content: SizedBox(
//               width: 480,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Activity Title')),
//                   const SizedBox(height: 12),
//                   TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
//                   const SizedBox(height: 12),
//                   DropdownButtonFormField<int>(
//                     value: capacity,
//                     decoration: const InputDecoration(labelText: 'Group Capacity'),
//                     items: [2, 3, 4, 5, 6].map((s) => DropdownMenuItem(value: s, child: Text('$s Students'))).toList(),
//                     onChanged: (v) {
//                       if (v != null) setS(() => capacity = v);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
//               ElevatedButton(
//                 onPressed: () {
//                   final updated = act.copyWith(title: titleCtrl.text.trim(), description: descCtrl.text.trim(), groupCapacity: capacity);
//                   widget.appState.updateActivity(updated);
//                   Navigator.pop(ctx);
//                 },
//                 child: const Text('Save Changes'),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _confirmDeleteActivity(BuildContext context, ActivityModel act) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Delete Activity?'),
//         content: Text('Are you sure you want to delete "${act.title}"? Associated teams will also be removed.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () {
//               widget.appState.deleteActivity(act.id);
//               Navigator.pop(ctx);
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
// }
