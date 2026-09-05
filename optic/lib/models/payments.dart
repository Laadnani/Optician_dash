class Payment {
  final String id;
  final String invoiceId;
  final DateTime date;
  final double amount;
  final String method; // cash, card, transfer

  Payment({
    required this.id,
    required this.invoiceId,
    required this.date,
    required this.amount,
    required this.method,
  });
}
