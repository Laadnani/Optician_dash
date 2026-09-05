class DocumentRecord {
  final String id;
  final String clientId;
  final String type; // report, scan, consent
  final String filePath;
  final DateTime uploadedAt;

  DocumentRecord({
    required this.id,
    required this.clientId,
    required this.type,
    required this.filePath,
    required this.uploadedAt,
  });
}
