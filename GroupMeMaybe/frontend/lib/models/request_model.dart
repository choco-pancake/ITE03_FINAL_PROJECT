enum RequestStatus { pending, underReview, approved, rejected }

class ModificationRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String studentBlock;
  final String photoUrl;
  final String requestTitle;
  final String requestType; // "Switch Group", "Update Skills", "Availability Change"
  final String currentValue;
  final String requestedChange;
  final String? attachedFile;
  final DateTime dateSubmitted;
  RequestStatus status;
  String? remarks;
  DateTime? decisionDate;

  ModificationRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.studentBlock,
    this.photoUrl = '',
    required this.requestTitle,
    required this.requestType,
    required this.currentValue,
    required this.requestedChange,
    this.attachedFile,
    required this.dateSubmitted,
    this.status = RequestStatus.pending,
    this.remarks,
    this.decisionDate,
  });

  String get statusLabel {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.underReview:
        return 'Under Review';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isDecided => status == RequestStatus.approved || status == RequestStatus.rejected;
}

class CustomSkillRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String skillName;
  final String category;
  final String justification;
  final DateTime dateRequested;
  RequestStatus status;
  String? reviewerRemarks;

  CustomSkillRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.skillName,
    required this.category,
    required this.justification,
    required this.dateRequested,
    this.status = RequestStatus.pending,
    this.reviewerRemarks,
  });

  String get statusLabel {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.underReview:
        return 'Under Review';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }
}
