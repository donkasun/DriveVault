class Document {
  final String id;
  final String vehicleId;
  final String docType;
  final String title;
  final String storageUrl;
  final String? storagePublicId;
  final String? mimeType;
  final int? fileSizeBytes;
  final String? issueDate;
  final String? expiryDate;
  final DateTime createdAt;

  const Document({
    required this.id,
    required this.vehicleId,
    required this.docType,
    required this.title,
    required this.storageUrl,
    this.storagePublicId,
    this.mimeType,
    this.fileSizeBytes,
    this.issueDate,
    this.expiryDate,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        docType: json['docType'] as String,
        title: json['title'] as String,
        storageUrl: json['storageUrl'] as String,
        storagePublicId: json['storagePublicId'] as String?,
        mimeType: json['mimeType'] as String?,
        fileSizeBytes: json['fileSizeBytes'] as int?,
        issueDate: json['issueDate'] as String?,
        expiryDate: json['expiryDate'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'docType': docType,
        'title': title,
        'storageUrl': storageUrl,
        if (storagePublicId != null) 'storagePublicId': storagePublicId,
        if (mimeType != null) 'mimeType': mimeType,
        if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
        if (issueDate != null) 'issueDate': issueDate,
        if (expiryDate != null) 'expiryDate': expiryDate,
        'createdAt': createdAt.toIso8601String(),
      };

  bool get isImage =>
      mimeType != null && mimeType!.startsWith('image/');

  /// Returns days until expiry. Negative = expired.
  int? daysUntilExpiry() {
    if (expiryDate == null) return null;
    final expiry = DateTime.tryParse(expiryDate!);
    if (expiry == null) return null;
    return expiry
        .difference(DateTime.now().copyWith(
            hour: 0, minute: 0, second: 0, millisecond: 0,
            microsecond: 0))
        .inDays;
  }
}

/// Groups a list of documents by docType.
Map<String, List<Document>> groupDocumentsByType(
    List<Document> documents) {
  final Map<String, List<Document>> grouped = {};
  for (final doc in documents) {
    grouped.putIfAbsent(doc.docType, () => []).add(doc);
  }
  return grouped;
}
