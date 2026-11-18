// import 'package:flutter/material.dart';
// import '../../models/request_model.dart';
// import '../../state/app_state.dart';
// import '../../widgets/status_badge.dart';

// class ProfessorEvaluationScreen extends StatefulWidget {
//   final AppState appState;

//   const ProfessorEvaluationScreen({super.key, required this.appState});

//   @override
//   State<ProfessorEvaluationScreen> createState() => _ProfessorEvaluationScreenState();
// }

// class _ProfessorEvaluationScreenState extends State<ProfessorEvaluationScreen> {
//   RequestStatus? _statusFilter;
//   final _searchController = TextEditingController();
//   String _sortBy = 'date'; // 'date' or 'name'
//   bool _showHistoryOnly = false;
//   ModificationRequestModel? _selectedRequest; // When viewing details

//   final _remarksController = TextEditingController();

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _remarksController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final app = widget.appState;
//     final allRequests = app.requests;

//     // Filter counts (Jansen, Page 2)
//     final pendingCount = allRequests.where((r) => r.status == RequestStatus.pending).length;
//     final reviewCount = allRequests.where((r) => r.status == RequestStatus.underReview).length;
//     final approvedCount = allRequests.where((r) => r.status == RequestStatus.approved).length;
//     final rejectedCount = allRequests.where((r) => r.status == RequestStatus.rejected).length;

//     // Apply filters, search & sort
//     List<ModificationRequestModel> displayed = allRequests.where((r) {
//       if (_showHistoryOnly && !r.isDecided) return false;
//       if (!_showHistoryOnly && _statusFilter != null && r.status != _statusFilter) return false;

//       final query = _searchController.text.trim().toLowerCase();
//       if (query.isNotEmpty) {
//         final matchName = r.studentName.toLowerCase().contains(query);
//         final matchTitle = r.requestTitle.toLowerCase().contains(query);
//         final matchType = r.requestType.toLowerCase().contains(query);
//         if (!matchName && !matchTitle && !matchType) return false;
//       }
//       return true;
//     }).toList();

//     // Sort
//     if (_sortBy == 'date') {
//       displayed.sort((a, b) => b.dateSubmitted.compareTo(a.dateSubmitted));
//     } else {
//       displayed.sort((a, b) => a.studentName.compareTo(b.studentName));
//     }

//     // If viewing details of a specific request
//     if (_selectedRequest != null) {
//       return _buildDetailView(context, _selectedRequest!);
//     }

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
//                     'Modification Requests',
//                     style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Evaluate student transfer petitions, profile changes, and availability adjustments.',
//                     style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//                   ),
//                 ],
//               ),
//               Row(
//                 children: [
//                   FilterChip(
//                     label: const Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.history_rounded, size: 16),
//                         SizedBox(width: 6),
//                         Text('History Log'),
//                       ],
//                     ),
//                     selected: _showHistoryOnly,
//                     onSelected: (val) {
//                       setState(() {
//                         _showHistoryOnly = val;
//                         _statusFilter = null;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),

//           // Filters Row: Pending (Yellow), Under Review (Blue), Approved (Green), Rejected (Red) (Page 2)
//           Wrap(
//             spacing: 12,
//             runSpacing: 8,
//             children: [
//               _buildFilterBadge('All', allRequests.length, null, const Color(0xFF4F46E5)),
//               _buildFilterBadge('Pending', pendingCount, RequestStatus.pending, const Color(0xFFD97706)),
//               _buildFilterBadge('Under Review', reviewCount, RequestStatus.underReview, const Color(0xFF2563EB)),
//               _buildFilterBadge('Approved', approvedCount, RequestStatus.approved, const Color(0xFF10B981)),
//               _buildFilterBadge('Rejected', rejectedCount, RequestStatus.rejected, const Color(0xFFDC2626)),
//             ],
//           ),
//           const SizedBox(height: 20),

//           // Search Bar, Clear Filter Button, Sorting Dropdown (Page 2)
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: Colors.grey.shade200),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _searchController,
//                     onChanged: (_) => setState(() {}),
//                     decoration: InputDecoration(
//                       hintText: 'Search by student name, request title, or category...',
//                       prefixIcon: const Icon(Icons.search, size: 20),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 // Sorting by Date Submitted or Student Name
//                 DropdownButton<String>(
//                   value: _sortBy,
//                   underline: const SizedBox(),
//                   items: const [
//                     DropdownMenuItem(value: 'date', child: Text('Sort by Date Submitted')),
//                     DropdownMenuItem(value: 'name', child: Text('Sort by Student Name')),
//                   ],
//                   onChanged: (val) {
//                     if (val != null) setState(() => _sortBy = val);
//                   },
//                 ),
//                 const SizedBox(width: 10),
//                 // Clear Filter Button (Page 2)
//                 TextButton.icon(
//                   onPressed: () {
//                     setState(() {
//                       _statusFilter = null;
//                       _searchController.clear();
//                       _showHistoryOnly = false;
//                       _sortBy = 'date';
//                     });
//                   },
//                   icon: const Icon(Icons.clear_all, size: 18),
//                   label: const Text('Clear Filters'),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Empty state: "No requests found" (Page 2)
//           if (displayed.isEmpty)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 60),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: const Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
//                     SizedBox(height: 12),
//                     Text(
//                       'No requests found',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
//                     ),
//                     SizedBox(height: 4),
//                     Text('Try adjusting your search query or status filter.', style: TextStyle(color: Colors.grey, fontSize: 13)),
//                   ],
//                 ),
//               ),
//             )
//           else
//             ListView.separated(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: displayed.length,
//               separatorBuilder: (_, __) => const SizedBox(height: 14),
//               itemBuilder: (context, idx) {
//                 final req = displayed[idx];
//                 return _buildRequestCard(context, req);
//               },
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterBadge(String label, int count, RequestStatus? status, Color color) {
//     final bool isSelected = !_showHistoryOnly && _statusFilter == status;
//     return InkWell(
//       onTap: () {
//         setState(() {
//           _showHistoryOnly = false;
//           _statusFilter = status;
//         });
//       },
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 1.5 : 1.0),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? color : const Color(0xFF334155))),
//             const SizedBox(width: 8),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//               decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
//               child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRequestCard(BuildContext context, ModificationRequestModel req) {
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
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Student Profile Picture (Page 2)
//           CircleAvatar(
//             radius: 24,
//             backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
//             child: Text(
//               req.studentName.isNotEmpty ? req.studentName[0] : 'S',
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4F46E5)),
//             ),
//           ),
//           const SizedBox(width: 16),
//           // Student info, request title, date
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         Text(req.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
//                         const SizedBox(width: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                           decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
//                           child: Text(req.studentBlock, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
//                         ),
//                         const SizedBox(width: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                           decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
//                           child: Text(req.requestType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
//                         ),
//                       ],
//                     ),
//                     Text(
//                       'Submitted: ${req.dateSubmitted.month}/${req.dateSubmitted.day}/${req.dateSubmitted.year}',
//                       style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Text(req.requestTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B))),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Change: ${req.requestedChange}',
//                   style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 if (req.remarks != null) ...[
//                   const SizedBox(height: 6),
//                   Text('Remarks: ${req.remarks}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
//                 ],
//               ],
//             ),
//           ),
//           const SizedBox(width: 16),
//           // Status badge & View Details Button (Page 2)
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               RequestStatusBadge(status: req.status),
//               const SizedBox(height: 14),
//               ElevatedButton.icon(
//                 onPressed: () {
//                   setState(() {
//                     _selectedRequest = req;
//                     _remarksController.text = req.remarks ?? '';
//                   });
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFF1F5F9),
//                   foregroundColor: const Color(0xFF0F172A),
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                 ),
//                 icon: const Icon(Icons.visibility_outlined, size: 16),
//                 label: const Text('View Details'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // Detailed Request View (Jansen, Page 2)
//   Widget _buildDetailView(BuildContext context, ModificationRequestModel req) {
//     final app = widget.appState;
//     final bool isDecided = req.isDecided;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(28.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Back button
//           Row(
//             children: [
//               OutlinedButton.icon(
//                 onPressed: () => setState(() => _selectedRequest = null),
//                 icon: const Icon(Icons.arrow_back, size: 16),
//                 label: const Text('Back to Requests List'),
//               ),
//               const SizedBox(width: 16),
//               RequestStatusBadge(status: req.status),
//             ],
//           ),
//           const SizedBox(height: 20),

//           // Main Card
//           Container(
//             padding: const EdgeInsets.all(28),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: Colors.grey.shade200),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CircleAvatar(
//                       radius: 32,
//                       backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
//                       child: Text(
//                         req.studentName.isNotEmpty ? req.studentName[0] : 'S',
//                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF4F46E5)),
//                       ),
//                     ),
//                     const SizedBox(width: 18),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(req.studentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
//                           const SizedBox(height: 4),
//                           Text('${req.studentEmail} • ${req.studentBlock}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
//                           const SizedBox(height: 8),
//                           Text('Submitted on: ${req.dateSubmitted}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
//                         ],
//                       ),
//                     ),
//                     if (req.status == RequestStatus.pending)
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           app.markRequestUnderReview(req.id);
//                           setState(() {});
//                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as Under Review')));
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue.shade50,
//                           foregroundColor: Colors.blue.shade800,
//                           elevation: 0,
//                         ),
//                         icon: const Icon(Icons.rate_review_outlined, size: 16),
//                         label: const Text('Mark as Review'),
//                       ),
//                   ],
//                 ),
//                 const Divider(height: 36),

//                 // Request Information
//                 const Text('REQUEST SPECIFICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
//                 const SizedBox(height: 12),
//                 Text(req.requestTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
//                 const SizedBox(height: 16),

//                 // Current Value vs Requested Change
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text('Current Value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
//                             const SizedBox(height: 6),
//                             Text(req.currentValue, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7D2FE))),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text('Requested Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
//                             const SizedBox(height: 6),
//                             Text(req.requestedChange, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 // Attached files (optional) (Page 2)
//                 if (req.attachedFile != null) ...[
//                   const SizedBox(height: 20),
//                   const Text('Attached Verification Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
//                   const SizedBox(height: 8),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                     decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.attach_file, size: 18, color: Color(0xFF4F46E5)),
//                         const SizedBox(width: 8),
//                         Text(req.attachedFile!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
//                       ],
//                     ),
//                   ),
//                 ],

//                 const Divider(height: 36),

//                 // Comments or Remarks Section (Page 2)
//                 const Text('Professor Comments & Remarks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: _remarksController,
//                   enabled: !isDecided,
//                   maxLines: 3,
//                   decoration: InputDecoration(
//                     hintText: 'Enter instructor feedback or rationale to accompany decision...',
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                     filled: isDecided,
//                     fillColor: isDecided ? Colors.grey.shade100 : Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 if (!isDecided)
//                   ElevatedButton(
//                     onPressed: () {
//                       app.addRequestRemarks(req.id, _remarksController.text.trim());
//                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remarks saved.')));
//                     },
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black87),
//                     child: const Text('Submit Remarks'),
//                   ),

//                 const SizedBox(height: 28),

//                 // Approve & Decline Buttons with Confirmations (Page 2)
//                 if (isDecided)
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: req.status == RequestStatus.approved ? Colors.green.shade50 : Colors.red.shade50,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           req.status == RequestStatus.approved ? Icons.check_circle : Icons.cancel,
//                           color: req.status == RequestStatus.approved ? Colors.green : Colors.red,
//                         ),
//                         const SizedBox(width: 12),
//                         Text(
//                           'Decision Finalized: ${req.statusLabel.toUpperCase()} on ${req.decisionDate ?? "recently"}',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: req.status == RequestStatus.approved ? Colors.green.shade900 : Colors.red.shade900,
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 else
//                   Row(
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: () => _confirmDecision(context, req, isApprove: true),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF10B981),
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         icon: const Icon(Icons.check, size: 18),
//                         label: const Text('Approve Request', style: TextStyle(fontWeight: FontWeight.bold)),
//                       ),
//                       const SizedBox(width: 14),
//                       ElevatedButton.icon(
//                         onPressed: () => _confirmDecision(context, req, isApprove: false),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFEF4444),
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         icon: const Icon(Icons.close, size: 18),
//                         label: const Text('Decline Request', style: TextStyle(fontWeight: FontWeight.bold)),
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Confirmation dialog with confirm and cancel buttons (Page 2)
//   void _confirmDecision(BuildContext context, ModificationRequestModel req, {required bool isApprove}) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(isApprove ? 'Confirm Approval?' : 'Confirm Decline?'),
//         content: Text(
//           isApprove
//               ? 'Are you sure you want to approve this request? A notification will be sent to ${req.studentName} with your decision and remarks.'
//               : 'Are you sure you want to decline this request? The student will be notified accordingly.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               final remarks = _remarksController.text.trim();
//               if (isApprove) {
//                 widget.appState.approveRequest(req.id, remarks: remarks);
//               } else {
//                 widget.appState.declineRequest(req.id, remarks: remarks);
//               }
//               setState(() {});
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(isApprove ? 'Request approved and notification dispatched!' : 'Request declined and notification dispatched!'),
//                   backgroundColor: isApprove ? const Color(0xFF10B981) : Colors.redAccent,
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: isApprove ? const Color(0xFF10B981) : const Color(0xFFEF4444),
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Confirm'),
//           ),
//         ],
//       ),
//     );
//   }
// }
