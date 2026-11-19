import 'package:flutter/foundation.dart';

import '../models/custom_skill_request.dart';

class SkillApprovalService extends ChangeNotifier {
  static final SkillApprovalService _instance =
      SkillApprovalService._internal();
  factory SkillApprovalService() => _instance;

  SkillApprovalService._internal() {
    _initDefaultRequests();
  }

  final List<CustomSkillRequest> _requests = [];
  final Set<String> _approvedSkills = {
    'Solidity',
    'Unreal Engine 5',
    'Kubernetes',
  };

  void _initDefaultRequests() {
    _requests.addAll([
      CustomSkillRequest(
        id: 'csr-01',
        studentName: 'Carlos Mendoza',
        studentId: '2023-10492',
        block: 'BSIT-3A',
        skillName: 'GraphQL',
        domain: 'API Development & Integration',
        submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
        status: SkillApprovalStatus.pending,
      ),
      CustomSkillRequest(
        id: 'csr-02',
        studentName: 'Bianca Cruz',
        studentId: '2023-10114',
        block: 'BSIT-3A',
        skillName: 'Three.js 3D Web Graphics',
        domain: 'Frontend Development',
        submittedAt: DateTime.now().subtract(const Duration(hours: 12)),
        status: SkillApprovalStatus.underReview,
        remarks:
            'Checking syllabus alignment with interactive graphics module.',
      ),
      CustomSkillRequest(
        id: 'csr-03',
        studentName: 'Dani Garcia',
        studentId: '2023-10229',
        block: 'BSIT-3B',
        skillName: 'Solidity Smart Contracts',
        domain: 'Cybersecurity & Blockchain',
        submittedAt: DateTime.now().subtract(const Duration(days: 1)),
        status: SkillApprovalStatus.approved,
        remarks: 'Approved for Decentralized App activity.',
      ),
      CustomSkillRequest(
        id: 'csr-04',
        studentName: 'Juan Dela Cruz',
        studentId: '2023-10881',
        block: 'BSIT-3B',
        skillName: 'Fortran 77 Legacy Maintenance',
        domain: 'Programming Languages',
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
        status: SkillApprovalStatus.rejected,
        remarks: 'Not applicable for Modern Web and Cloud capstones.',
      ),
    ]);
  }

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

  bool isSkillApproved(String skill) {
    return _approvedSkills.contains(skill);
  }
}
