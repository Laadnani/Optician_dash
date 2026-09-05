/// Module 22 — Purchasing (Procurement). A purchase order sent to a
/// [Supplier] to restock frames/lenses/contact lenses/accessories — the
/// closing module of the spec's own architecture tree.
class PurchaseOrder {
  final String id;
  final String supplierId;
  final DateTime date;
  final String description;
  final double totalAmount;

  /// 'draft' | 'sent' | 'confirmed' | 'received' | 'cancelled'.
  final String status;

  final DateTime? expectedDate;

  /// References [Order.id], when this restock was triggered by a specific
  /// customer order needing stock that wasn't on hand.
  final String? orderId;

  /// References [Frame.id], when this purchase order restocks a frame.
  final String? frameId;

  /// References [Lens.id], when this purchase order restocks a lens.
  final String? lensId;

  PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.date,
    required this.description,
    this.totalAmount = 0,
    this.status = 'draft',
    this.expectedDate,
    this.orderId,
    this.frameId,
    this.lensId,
  });
}
