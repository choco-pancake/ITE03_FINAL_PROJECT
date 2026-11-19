import 'package:flutter/foundation.dart';

import '../models/custom_skill_request.dart';

class SkillApprovalService extends ChangeNotifier {
  static final SkillApprovalService _instance =
      SkillApprovalService._internal();
  factory SkillApprovalService() => _instance;

  SkillApprovalService._internal();

  final List<CustomSkillRequest> _requests = [];
  final Set<String> _approvedSkills = {};

  List<CustomSkillRequest> get requests => List.unmodifiable(_requests);

  Set<String> get approvedSkills => Set.unmodifiable(_approvedSkills);

  List<CustomSkillRequest> getRequestsByStatus(SkillApprovalStatus? status) {
    if (status == null) return List.unmodifiable(_requests);
    return _requests.where((r) => r.status == status).toList();
  }

  void submitRequest({
    required String studentName,
    required String studentId,
    required String block,
    required String skillName,
    required String domain,
  }) {
    final newReq = CustomSkillRequest(
      id: 'csr-${DateTime.now().millisecondsSinceEpoch}',
      studentName: studentName,
      studentId: studentId,
      block: block,
      skillName: skillName,
      domain: domain,
      submittedAt: DateTime.now(),
      status: SkillApprovalStatus.pending,
    );
    _requests.insert(0, newReq);
    notifyListeners();
  }

  void updateStatus(
    String requestId,
    SkillApprovalStatus newStatus, {
    String? remarks,
  }) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final req = _requests[index];
      _requests[index] = req.copyWith(status: newStatus, remarks: remarks);

      if (newStatus == SkillApprovalStatus.approved) {
        _approvedSkills.add(req.skillName);
      } else {
        _approvedSkills.remove(req.skillName);
      }
      notifyListeners();
    }
  }

  void deleteRequest(String requestId) {
    _requests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  bool isSkillApproved(String skill) {
    return _approvedSkills.contains(skill);
  }
}
