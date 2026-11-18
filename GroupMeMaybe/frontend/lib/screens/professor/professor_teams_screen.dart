// import 'package:flutter/material.dart';
// import '../../models/team_model.dart';
// import '../../state/app_state.dart';
// import '../../widgets/compatibility_ring.dart';

// class ProfessorTeamsScreen extends StatefulWidget {
//   final AppState appState;

//   const ProfessorTeamsScreen({super.key, required this.appState});

//   @override
//   State<ProfessorTeamsScreen> createState() => _ProfessorTeamsScreenState();
// }

// class _ProfessorTeamsScreenState extends State<ProfessorTeamsScreen> {
//   String? _selectedActivityId;
//   String? _selectedClassId;
//   int _teamSize = 4;
//   int _minCommonHours = 6;
//   bool _fillIncompleteFirst = true;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.appState.activities.isNotEmpty) {
//       final act = widget.appState.activities.first;
//       _selectedActivityId = act.id;
//       _selectedClassId = act.classId;
//       _teamSize = act.groupCapacity;
//       _minCommonHours = act.minCommonHours;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final app = widget.appState;
//     final activities = app.activities;
//     final classes = app.classes;

//     final currentAct = activities.firstWhere(
//       (a) => a.id == _selectedActivityId,
//       orElse: () => activities.first,
//     );

//     final currentTeams = app.teams.where((t) => t.activityId == currentAct.id).toList();

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
//                     'Team Formation Studio (Auto & Hybrid)',
//                     style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Automated team balancing algorithm with live drag-and-drop member reordering and hybrid patching.',
//                     style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//                   ),
//                 ],
//               ),
//               // Adjustable Weights Dialog button
//               OutlinedButton.icon(
//                 onPressed: () => _showWeightsAdjustmentDialog(context),
//                 icon: const Icon(Icons.tune_rounded, size: 16),
//                 label: Text('Adjust Compatibility Weights (${(app.skillsWeight * 100).toInt()}% / ${(app.interestWeight * 100).toInt()}% / ${(app.availabilityWeight * 100).toInt()}%)'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),

//           // Team Settings Panel (Juliana, Page 4)
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
//                 const Row(
//                   children: [
//                     Icon(Icons.settings_suggest_rounded, color: Color(0xFF4F46E5)),
//                     SizedBox(width: 10),
//                     Text('Algorithm & Section Configuration Panel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//                 const SizedBox(height: 18),
//                 Row(
//                   children: [
//                     // Section / Class Selector (Page 4)
//                     Expanded(
//                       flex: 2,
//                       child: DropdownButtonFormField<String>(
//                         value: _selectedClassId,
//                         decoration: InputDecoration(
//                           labelText: 'Section / Class Selector',
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.code} - ${c.section} (${c.name})'))).toList(),
//                         onChanged: (val) {
//                           if (val != null) setState(() => _selectedClassId = val);
//                         },
//                       ),
//                     ),
//                     const SizedBox(width: 14),
//                     // Activity Selector
//                     Expanded(
//                       flex: 2,
//                       child: DropdownButtonFormField<String>(
//                         value: _selectedActivityId,
//                         decoration: InputDecoration(
//                           labelText: 'Target Grouping Activity',
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         items: activities.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.title} (${a.groupingMethodLabel})'))).toList(),
//                         onChanged: (val) {
//                           if (val != null) {
//                             setState(() {
//                               _selectedActivityId = val;
//                               final a = activities.firstWhere((e) => e.id == val);
//                               _teamSize = a.groupCapacity;
//                               _minCommonHours = a.minCommonHours;
//                             });
//                           }
//                         },
//                       ),
//                     ),
//                     const SizedBox(width: 14),
//                     // Team Size Setting
//                     Expanded(
//                       child: DropdownButtonFormField<int>(
//                         value: _teamSize,
//                         decoration: InputDecoration(
//                           labelText: 'Team Capacity',
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         items: [2, 3, 4, 5, 6].map((s) => DropdownMenuItem(value: s, child: Text('$s Students'))).toList(),
//                         onChanged: (val) {
//                           if (val != null) setState(() => _teamSize = val);
//                         },
//                       ),
//                     ),
//                     const SizedBox(width: 14),
//                     // Min Common Hours
//                     Expanded(
//                       child: DropdownButtonFormField<int>(
//                         value: _minCommonHours,
//                         decoration: InputDecoration(
//                           labelText: 'Min Common Hours',
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         items: [4, 6, 8, 10, 12].map((h) => DropdownMenuItem(value: h, child: Text('$h hrs/wk'))).toList(),
//                         onChanged: (val) {
//                           if (val != null) setState(() => _minCommonHours = val);
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 18),

//                 // Control Buttons: Generate Teams, Regenerate, Confirm Teams (Page 4) + Hybrid Auto-Form Button (Page 5)
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             app.generateTeamsAuto(
//                               activityId: currentAct.id,
//                               classId: _selectedClassId ?? classes.first.id,
//                               teamSize: _teamSize,
//                             );
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('Auto-generated balanced teams fulfilling skill coverage!'),
//                                 backgroundColor: Color(0xFF10B981),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF4F46E5),
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                           icon: const Icon(Icons.bolt, size: 18),
//                           label: const Text('Generate Teams (Auto)', style: TextStyle(fontWeight: FontWeight.bold)),
//                         ),
//                         const SizedBox(width: 12),
//                         OutlinedButton.icon(
//                           onPressed: () {
//                             app.generateTeamsAuto(
//                               activityId: currentAct.id,
//                               classId: _selectedClassId ?? classes.first.id,
//                               teamSize: _teamSize,
//                             );
//                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regenerated team groupings.')));
//                           },
//                           icon: const Icon(Icons.refresh, size: 16),
//                           label: const Text('Regenerate'),
//                         ),
//                         const SizedBox(width: 12),
//                         // Hybrid Auto-Form Button (Page 5)
//                         PopupMenuButton<bool>(
//                           tooltip: 'Hybrid Strategy Options (Current: ${_fillIncompleteFirst ? "Fill Incomplete First" : "Form New Teams Only"})',
//                           onSelected: (fillIncomplete) {
//                             setState(() => _fillIncompleteFirst = fillIncomplete);
//                             app.autoFormUnassignedStudents(
//                               activityId: currentAct.id,
//                               classId: _selectedClassId ?? classes.first.id,
//                               fillIncompleteFirst: fillIncomplete,
//                             );
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(fillIncomplete
//                                     ? 'Hybrid auto-form: Patched incomplete teams with unassigned students!'
//                                     : 'Hybrid auto-form: Formed new teams only for unassigned students!'),
//                                 backgroundColor: const Color(0xFF8B5CF6),
//                               ),
//                             );
//                           },
//                           itemBuilder: (ctx) => [
//                             const PopupMenuItem(
//                               value: true,
//                               child: Text('Fill incomplete teams first before forming new teams'),
//                             ),
//                             const PopupMenuItem(
//                               value: false,
//                               child: Text('Form new teams only (keep existing teams intact)'),
//                             ),
//                           ],
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFF5F3FF),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: const Color(0xFFDDD6FE)),
//                             ),
//                             child: const Row(
//                               children: [
//                                 Icon(Icons.merge_type_rounded, size: 18, color: Color(0xFF7C3AED)),
//                                 SizedBox(width: 8),
//                                 Text(
//                                   'Auto-Form Unassigned (Hybrid)',
//                                   style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
//                                 ),
//                                 SizedBox(width: 6),
//                                 Icon(Icons.arrow_drop_down, color: Color(0xFF6D28D9)),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     // Confirm Teams Button (Page 4)
//                     ElevatedButton.icon(
//                       onPressed: currentTeams.isEmpty
//                           ? null
//                           : () {
//                               app.confirmTeams(currentAct.id);
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text('Teams officially confirmed! Notifications sent to all students.'),
//                                   backgroundColor: Color(0xFF10B981),
//                                 ),
//                               );
//                             },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF10B981),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                       icon: const Icon(Icons.check_circle_outline, size: 18),
//                       label: const Text('Confirm Teams & Notify Students', style: TextStyle(fontWeight: FontWeight.bold)),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Drag and Drop Notice (Page 4)
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
//             child: const Row(
//               children: [
//                 Icon(Icons.touch_app_outlined, size: 18, color: Color(0xFF4F46E5)),
//                 SizedBox(width: 10),
//                 Text(
//                   '💡 Interactive Drag-and-Drop Enabled: Drag any member card to a different team to rebalance roles. Compatibility rings update live!',
//                   style: TextStyle(fontSize: 13, color: Color(0xFF3730A3), fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Teams Canvas with DragTarget
//           currentTeams.isEmpty
//               ? Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(50),
//                   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
//                   child: const Center(child: Text('No teams generated yet. Click "Generate Teams (Auto)" above.')),
//                 )
//               : GridView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
//                     maxCrossAxisExtent: 580,
//                     mainAxisExtent: 380,
//                     crossAxisSpacing: 18,
//                     mainAxisSpacing: 18,
//                   ),
//                   itemCount: currentTeams.length,
//                   itemBuilder: (context, idx) {
//                     final team = currentTeams[idx];
//                     return DragTarget<Map<String, dynamic>>(
//                       onWillAcceptWithDetails: (details) {
//                         return details.data['teamId'] != team.id && !team.isFull;
//                       },
//                       onAcceptWithDetails: (details) {
//                         final sourceTeamId = details.data['teamId'] as String;
//                         final userId = details.data['userId'] as String;
//                         app.transferTeamMember(
//                           sourceTeamId: sourceTeamId,
//                           targetTeamId: team.id,
//                           userId: userId,
//                         );
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text('Moved ${details.data["name"]} to ${team.name}')),
//                         );
//                       },
//                       builder: (context, candidateData, rejectedData) {
//                         final isHovered = candidateData.isNotEmpty;
//                         return Container(
//                           padding: const EdgeInsets.all(20),
//                           decoration: BoxDecoration(
//                             color: isHovered ? const Color(0xFFEEF2FF) : Colors.white,
//                             borderRadius: BorderRadius.circular(18),
//                             border: Border.all(
//                               color: isHovered ? const Color(0xFF4F46E5) : (team.isConfirmed ? const Color(0xFF10B981) : Colors.grey.shade200),
//                               width: isHovered ? 2 : 1,
//                             ),
//                             boxShadow: [
//                               BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
//                             ],
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                                       const SizedBox(height: 2),
//                                       Text(
//                                         '${team.members.length} / ${team.capacity} Members • ${team.isConfirmed ? "Confirmed" : "Draft"}',
//                                         style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                                       ),
//                                     ],
//                                   ),
//                                   // Compatibility Ring with metrics
//                                   CompatibilityRing(
//                                     score: team.overallCompatibility,
//                                     size: 58,
//                                     strokeWidth: 5,
//                                     skillCoverage: team.skillCoverage,
//                                     interestMatch: team.interestMatch,
//                                     availabilityOverlap: team.availabilityOverlap,
//                                   ),
//                                 ],
//                               ),
//                               const Divider(height: 20),

//                               // Members List (Each is Draggable!)
//                               Expanded(
//                                 child: ListView.separated(
//                                   itemCount: team.members.length,
//                                   separatorBuilder: (_, __) => const SizedBox(height: 8),
//                                   itemBuilder: (ctx, mIdx) {
//                                     final member = team.members[mIdx];
//                                     final bool isLeader = member.userId == team.leaderId;

//                                     return Draggable<Map<String, dynamic>>(
//                                       data: {
//                                         'teamId': team.id,
//                                         'userId': member.userId,
//                                         'name': member.name,
//                                       },
//                                       feedback: Material(
//                                         elevation: 8,
//                                         borderRadius: BorderRadius.circular(12),
//                                         child: Container(
//                                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                                           decoration: BoxDecoration(
//                                             color: const Color(0xFF0F172A),
//                                             borderRadius: BorderRadius.circular(12),
//                                           ),
//                                           child: Text(
//                                             'Dragging: ${member.name} (${member.assignedRole})',
//                                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
//                                           ),
//                                         ),
//                                       ),
//                                       childWhenDragging: Opacity(
//                                         opacity: 0.3,
//                                         child: _buildMemberTile(member, isLeader),
//                                       ),
//                                       child: _buildMemberTile(member, isLeader),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMemberTile(TeamMember member, bool isLeader) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
//           const SizedBox(width: 8),
//           CircleAvatar(
//             radius: 14,
//             backgroundColor: isLeader ? const Color(0xFF4F46E5) : Colors.grey.shade400,
//             child: Text(
//               member.name.isNotEmpty ? member.name[0] : 'M',
//               style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(member.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
//                 Text(
//                   '${isLeader ? "★ Leader • " : ""}${member.assignedRole}',
//                   style: TextStyle(fontSize: 11, color: isLeader ? const Color(0xFF4338CA) : Colors.grey.shade700, fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//           ),
//           Text('${member.weeklyCommonHours}h/wk', style: const TextStyle(fontSize: 11, color: Colors.grey)),
//         ],
//       ),
//     );
//   }

//   // Compatibility Weights Adjustment Dialog (Page 5)
//   void _showWeightsAdjustmentDialog(BuildContext context) {
//     double tempSkills = widget.appState.skillsWeight;
//     double tempInterests = widget.appState.interestWeight;
//     double tempAvailability = widget.appState.availabilityWeight;

//     showDialog(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (c, setD) => AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           title: const Text('Adjust Compatibility Ring Weights', style: TextStyle(fontWeight: FontWeight.bold)),
//           content: SizedBox(
//             width: 480,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Default: Skills Coverage (40%), Interests Match (30%), Availability Overlap (30%). Weights must sum to 100%.',
//                   style: TextStyle(fontSize: 13, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 20),
//                 Text('Skills Coverage: ${(tempSkills * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
//                 Slider(
//                   value: tempSkills,
//                   min: 0.1,
//                   max: 0.8,
//                   divisions: 14,
//                   onChanged: (v) => setD(() => tempSkills = double.parse(v.toStringAsFixed(2))),
//                 ),
//                 Text('Interests Match: ${(tempInterests * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
//                 Slider(
//                   value: tempInterests,
//                   min: 0.1,
//                   max: 0.8,
//                   divisions: 14,
//                   onChanged: (v) => setD(() => tempInterests = double.parse(v.toStringAsFixed(2))),
//                 ),
//                 Text('Availability Overlap: ${(tempAvailability * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
//                 Slider(
//                   value: tempAvailability,
//                   min: 0.1,
//                   max: 0.8,
//                   divisions: 14,
//                   onChanged: (v) => setD(() => tempAvailability = double.parse(v.toStringAsFixed(2))),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 // Reset to default
//                 widget.appState.setWeights(skills: 0.40, interests: 0.30, availability: 0.30);
//                 Navigator.pop(ctx);
//               },
//               child: const Text('Reset Defaults'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 // Normalize to sum to 1.0
//                 final total = tempSkills + tempInterests + tempAvailability;
//                 widget.appState.setWeights(
//                   skills: tempSkills / total,
//                   interests: tempInterests / total,
//                   availability: tempAvailability / total,
//                 );
//                 Navigator.pop(ctx);
//                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compatibility weights updated across all algorithms!')));
//               },
//               child: const Text('Save Weights'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
