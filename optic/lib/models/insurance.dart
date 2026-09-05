class Insurance {
  final String id;
  final String clientId;
  final String provider;
  final String policyNumber;
  final DateTime validUntil;

  Insurance({
    required this.id,
    required this.clientId,
    required this.provider,
    required this.policyNumber,
    required this.validUntil,
  });
}
