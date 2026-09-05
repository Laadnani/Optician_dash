class DigitalSignature {
  final String id;
  final String clientId;
  final DateTime signedAt;
  final String signatureData; // base64 or file path

  DigitalSignature({
    required this.id,
    required this.clientId,
    required this.signedAt,
    required this.signatureData,
  });
}
