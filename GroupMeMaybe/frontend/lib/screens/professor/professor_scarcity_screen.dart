// import 'package:flutter/material.dart';
// import '../../models/activity_model.dart';
// import '../../state/app_state.dart';

// class ProfessorScarcityScreen extends StatefulWidget {
//   final AppState appState;
//   final Function(int) onNavigate;

//   const ProfessorScarcityScreen({super.key, required this.appState, required this.onNavigate});

//   @override
//   State<ProfessorScarcityScreen> createState() => _ProfessorScarcityScreenState();
// }

// class _ProfessorScarcityScreenState extends State<ProfessorScarcityScreen> {
//   String? _selectedActivityId;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.appState.activities.isNotEmpty) {
//       _selectedActivityId = widget.appState.activities.first.id;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final app = widget.appState;
//     final activities = app.activities.where((a) => a.groupingMethod == GroupingMethod.auto || a.groupingMethod == GroupingMethod.hybrid).toList();

//     if (activities.isEmpty) {
//       return const Center(child: Text('No Auto or Hybrid activities available for scarcity analysis.'));
//     }

//     _selectedActivityId ??= activities.first.id;
//     final report = app.calculateScarcityReport(_selectedActivityId!);
//     final ActivityModel act = report['activity'] as ActivityModel;
//     final List<Map<String, dynamic>> breakdown = report['breakdown'] as List<Map<String, dynamic>>;
//     final List<String> scarceSkills = report['scarceSkills'] as List<String>;
//     final bool hasScarcity = report['hasScarcity'] as bool;
//     final int totalStudents = report['totalStudents'] as int;
//     final int estimatedTeams = report['estimatedTeams'] as int;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(28.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Skill Scarcity & Distribution Report',
//                     style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Calculates skill supply across student profiles vs required team capacity to alert on deficits.',
//                     style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//                   ),
//                 ],
//               ),
//               // Activity Selector Dropdown
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
//                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
//                 child: DropdownButton<String>(
//                   value: _selectedActivityId,
//                   underline: const SizedBox(),
//                   items: activities.map((a) {
//                     return DropdownMenuItem(value: a.id, child: Text('${a.title} (${a.groupingMethodLabel})'));
//                   }).toList(),
//                   onChanged: (val) {
//                     if (val != null) setState(() => _selectedActivityId = val);
//                   },
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),

//           // Scarcity Alert Banner (Yvonne, Page 2)
//           if (hasScarcity)
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.amber.shade50,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.amber.shade300),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
//                   const SizedBox(width: 14),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Skill Scarcity Detected!',
//                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF92400E)),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Estimated teams needed: $estimatedTeams. The following required skills have a deficit in the current student pool: ${scarceSkills.join(", ")}. When students finish their profiles, use the Hybrid Auto-Form feature to balance remaining members.',
//                           style: const TextStyle(fontSize: 13, color: Color(0xFF78350F), height: 1.4),
//                         ),
//                         const SizedBox(height: 12),
//                         ElevatedButton.icon(
//                           onPressed: () => widget.onNavigate(5), // Navigate to Teams Generator
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFFD97706),
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                           ),
//                           icon: const Icon(Icons.auto_awesome_rounded, size: 16),
//                           label: const Text('Open Auto-Form & Hybrid Matcher'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           else
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.green.shade300),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 28),
//                   SizedBox(width: 14),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Optimal Skill Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF065F46))),
//                         SizedBox(height: 4),
//                         Text('All required skills have adequate student supply to satisfy every proposed team capacity.', style: TextStyle(fontSize: 13, color: Color(0xFF047857))),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//           const SizedBox(height: 24),

//           // Overview Metrics Card
//           Row(
//             children: [
//               Expanded(child: _buildMetricTile('Enrolled Pool', '$totalStudents Students', Icons.people_outline, Colors.blue)),
//               const SizedBox(width: 16),
//               Expanded(child: _buildMetricTile('Team Capacity', '${act.groupCapacity} Per Team', Icons.group_work_outlined, Colors.purple)),
//               const SizedBox(width: 16),
//               Expanded(child: _buildMetricTile('Projected Teams', '$estimatedTeams Teams', Icons.grid_view_rounded, Colors.indigo)),
//               const SizedBox(width: 16),
//               Expanded(child: _buildMetricTile('Deficit Skills', '${scarceSkills.length} Skills', Icons.analytics_outlined, hasScarcity ? Colors.red : Colors.green)),
//             ],
//           ),
//           const SizedBox(height: 28),

//           // Skill Distribution Report Table (Yvonne, Page 2)
//           Container(
//             padding: const EdgeInsets.all(22),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(18),
//               border: Border.all(color: Colors.grey.shade200),
//               boxShadow: [
//                 BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text('Skill Supply vs Demand Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
//                     Text('Minimum Proficiency: ${act.minProficiencyLevel}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Table(
//                   columnWidths: const {
//                     0: FlexColumnWidth(3),
//                     1: FlexColumnWidth(1.5),
//                     2: FlexColumnWidth(1.5),
//                     3: FlexColumnWidth(2),
//                     4: FlexColumnWidth(2),
//                   },
//                   children: [
//                     TableRow(
//                       decoration: BoxDecoration(color: Colors.grey.shade50),
//                       children: const [
//                         Padding(padding: EdgeInsets.all(12), child: Text('Required Skill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
//                         Padding(padding: EdgeInsets.all(12), child: Text('Student Supply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
//                         Padding(padding: EdgeInsets.all(12), child: Text('Team Demand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
//                         Padding(padding: EdgeInsets.all(12), child: Text('Deficit / Surplus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
//                         Padding(padding: EdgeInsets.all(12), child: Text('Scarcity Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
//                       ],
//                     ),
//                     ...breakdown.map((row) {
//                       final String skill = row['skill'];
//                       final int supply = row['supply'];
//                       final int demand = row['demand'];
//                       final int shortage = row['shortage'];
//                       final String status = row['status'];

//                       Color statusColor = Colors.green;
//                       if (status == 'Critical') statusColor = Colors.red;
//                       if (status == 'Moderate') statusColor = Colors.amber.shade800;

//                       return TableRow(
//                         decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF4F46E5)),
//                                 const SizedBox(width: 8),
//                                 Expanded(child: Text(skill, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
//                               ],
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Text('$supply students', style: const TextStyle(fontSize: 13)),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Text('$demand teams', style: const TextStyle(fontSize: 13)),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Text(
//                               shortage > 0 ? '-$shortage deficit' : '+${-shortage} surplus',
//                               style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: shortage > 0 ? Colors.red : Colors.green),
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                               decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
//                               child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
//                             ),
//                           ),
//                         ],
//                       );
//                     }),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundColor: color.withValues(alpha: 0.1),
//             child: Icon(icon, color: color, size: 20),
//           ),
//           const SizedBox(width: 14),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
//               Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
