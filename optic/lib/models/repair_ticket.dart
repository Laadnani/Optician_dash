/// Module 19 — Repairs (Client Delivery). Physical repair service on a
/// client's own item — separate from [AfterSalesTicket] (a fresh-order
/// complaint) and [WarrantyClaim] (a manufacturer-defect claim); this is
/// paid or goodwill repair work on something already in use.
class RepairTicket {
  final String id;
  final String clientId;

  /// References [Order.id], when the item being repaired traces back to an
  /// order on file. Optional — walk-in repairs on an item never sold here
  /// (or sold before this system existed) have no order to link to.
  final String? orderId;

  final DateTime date;

  /// 'frame' | 'lens' | 'contactLens' | 'other'.
  final String itemType;

  final String issueDescription;

  /// 'received' | 'inProgress' | 'completed' | 'cannotRepair'.
  final String status;

  final double cost;

  /// References [AfterSalesTicket.id], when this repair was opened from an
  /// after-sales complaint on file.
  final String? afterSalesTicketId;

  RepairTicket({
    required this.id,
    required this.clientId,
    this.orderId,
    required this.date,
    this.itemType = 'frame',
    required this.issueDescription,
    this.status = 'received',
    this.cost = 0,
    this.afterSalesTicketId,
  });
}
