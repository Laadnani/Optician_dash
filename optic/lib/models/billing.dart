class Invoice {
  final String id;
  final String clientId;
  final DateTime date;
  final double amount;
  final String status; // paid, pending, cancelled

  /// References [Order.id], when this invoice bills a specific order rather
  /// than a plain appointment visit.
  final String? orderId;

  Invoice({
    required this.id,
    required this.clientId,
    required this.date,
    required this.amount,
    required this.status,
    this.orderId,
  });
}
