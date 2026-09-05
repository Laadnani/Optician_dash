/// Module 20 — Warranty (Client Delivery). A manufacturer-defect claim
/// against an item's [Frame.warrantyMonths]/[Lens.warrantyMonths] coverage
/// — distinct from [RepairTicket], which covers non-warranty repair work.
class WarrantyClaim {
  final String id;
  final String clientId;

  /// References [Order.id], when the item traces back to an order on file.
  final String? orderId;

  final DateTime date;

  /// 'frame' | 'lens' | 'contactLens'.
  final String itemType;

  final String issueDescription;

  /// 'submitted' | 'approved' | 'rejected' | 'replaced'.
  final String status;


  /// References [AfterSalesTicket.id], when this claim was opened from an
  /// after-sales complaint on file.
  final String? afterSalesTicketId;

  WarrantyClaim({
    required this.id,
    required this.clientId,
    this.orderId,
    required this.date,
    this.itemType = 'frame',
    required this.issueDescription,
    this.status = 'submitted',
    this.afterSalesTicketId,
  });
}
