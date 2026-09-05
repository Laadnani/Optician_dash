/// Module 17 — Delivery (Client Delivery). The handoff of a finished
/// [Order] to its client — in-store pickup or sent out — closing the
/// production pipeline that started at [Order].
class DeliveryRecord {
  final String id;
  final String orderId;
  final String clientId;
  final DateTime date;

  /// 'inStore' | 'homeDelivery' | 'courier'.
  final String method;

  /// 'scheduled' | 'delivered' | 'failed'.
  final String status;

  final bool recipientSignature;

  /// References [Invoice.id] — the payment/invoice this handoff confirms
  /// was settled (per the diagram's "Payment completed" delivery check).
  final String? invoiceId;

  DeliveryRecord({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.date,
    this.method = 'inStore',
    this.status = 'scheduled',
    this.recipientSignature = false,
    this.invoiceId,
  });
}
