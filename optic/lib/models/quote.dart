/// Module 11 — Quotes / Estimates. A priced proposal sent to a client
/// before an [Order] is placed. Kept as one free-text `description` +
/// `totalAmount` rather than a full line-item structure — practical-core
/// depth, same simplification `Appointment` made for billing before a real
/// line-item/order system existed.
class Quote {
  final String id;
  final String clientId;
  final DateTime date;
  final String description;
  final double totalAmount;

  /// 'draft' | 'sent' | 'accepted' | 'declined' | 'expired'.
  final String status;

  final DateTime? validUntil;

  /// References [LensRecommendation.id], when this quote was built from a
  /// recommendation on file.
  final String? lensRecommendationId;

  /// References [Prescription.id] — what the quoted lenses are being cut
  /// against.
  final String? prescriptionId;

  /// References [Measurement.id] — the fitting numbers the quoted frame/
  /// lens combination is sized to.
  final String? measurementId;

  /// References [Frame.id] — the frame this quote is priced around.
  final String? frameId;

  /// References [Lens.id] — the lens product this quote is priced around.
  final String? lensId;

  /// References [Accessory.id], when an accessory is bundled into the
  /// quote.
  final String? accessoryId;

  Quote({
    required this.id,
    required this.clientId,
    required this.date,
    required this.description,
    this.totalAmount = 0,
    this.status = 'draft',
    this.validUntil,
    this.lensRecommendationId,
    this.prescriptionId,
    this.measurementId,
    this.frameId,
    this.lensId,
    this.accessoryId,
  });
}
