/// Module 12 — Orders. What a [Quote] turns into once a client commits —
/// the record that [LabWorkOrder] (module 13) and [MountingJob] (module 14)
/// hang off of via `orderId`.
class Order {
  final String id;
  final String clientId;
  final DateTime date;

  /// References [Quote.id], when the order followed a quote.
  final String? quoteId;

  final String description;
  final double totalAmount;

  /// 'pending' | 'inProduction' | 'ready' | 'delivered' | 'cancelled'.
  final String status;


  /// References [Prescription.id] — carried over from the quote, when set.
  final String? prescriptionId;

  /// References [Measurement.id] — carried over from the quote, when set.
  final String? measurementId;

  /// References [Frame.id] — the frame reserved for this order.
  final String? frameId;

  /// References [Lens.id] — the lens product this order is for.
  final String? lensId;

  /// References [Accessory.id], when an accessory is bundled into the
  /// order.
  final String? accessoryId;

  Order({
    required this.id,
    required this.clientId,
    required this.date,
    this.quoteId,
    required this.description,
    this.totalAmount = 0,
    this.status = 'pending',
    this.prescriptionId,
    this.measurementId,
    this.frameId,
    this.lensId,
    this.accessoryId,
  });
}
