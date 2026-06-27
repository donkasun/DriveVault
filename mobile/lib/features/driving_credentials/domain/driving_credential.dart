enum CredentialStatus { ok, soon, overdue }

CredentialStatus? _parseStatus(String? raw) {
  switch (raw) {
    case 'soon':
      return CredentialStatus.soon;
    case 'overdue':
      return CredentialStatus.overdue;
    case 'ok':
      return CredentialStatus.ok;
    default:
      return null;
  }
}

class DrivingCredential {
  final String id;
  final String docType; // 'license' | 'permit' | 'international_license'
  final String? docNumber;
  final String? issueDate; // "YYYY-MM-DD"
  final String? expiryDate; // "YYYY-MM-DD"
  final String? notes;
  final CredentialStatus? status;
  final int? daysUntilExpiry;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DrivingCredential({
    required this.id,
    required this.docType,
    this.docNumber,
    this.issueDate,
    this.expiryDate,
    this.notes,
    this.status,
    this.daysUntilExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DrivingCredential.fromJson(Map<String, dynamic> json) =>
      DrivingCredential(
        id: json['id'] as String,
        docType: json['docType'] as String,
        docNumber: json['docNumber'] as String?,
        issueDate: json['issueDate'] as String?,
        expiryDate: json['expiryDate'] as String?,
        notes: json['notes'] as String?,
        status: _parseStatus(json['status'] as String?),
        daysUntilExpiry: json['daysUntilExpiry'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static String labelFor(String docType) {
    switch (docType) {
      case 'license':
        return "Driver's License";
      case 'permit':
        return 'Driving Permit';
      case 'international_license':
        return 'International Driving License';
      default:
        return docType;
    }
  }
}
