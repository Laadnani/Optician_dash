/// Module 18 — After-Sales (Client Delivery). Post-delivery support —
/// comfort complaints, breakage, vision issues raised after a client
/// already has their glasses in hand.
class AfterSalesTicket {
  final String id;
  final String orderId;
  final String clientId;
  final DateTime date;

  /// 'comfort' | 'breakage' | 'visionIssue' | 'other'.
  final String issueType;

  /// 'open' | 'inProgress' | 'resolved' | 'closed'.
  final String status;

  final String resolution;

  /// References [DeliveryRecord.id] — the handoff this after-sales issue
  /// was raised against.
  final String? deliveryRecordId;

  /// Where this ticket lands per the diagram's three-way after-sales
  /// outcome: 'pending' | 'satisfied' | 'complaint' | 'repair'.
  final String outcome;

  AfterSalesTicket({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.date,
    this.issueType = 'comfort',
    this.status = 'open',
    this.resolution = '',
    this.deliveryRecordId,
    this.outcome = 'pending',
  });
}
