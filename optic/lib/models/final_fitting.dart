/// Module 16 — Final Fitting (Client Delivery). The in-person adjustment
/// pass on a client's finished glasses before [DeliveryRecord] (module
/// 17) hands them over — nose pads, temple length, frame alignment.
class FinalFitting {
  final String id;
  final String orderId;
  final String clientId;
  final DateTime date;

  /// 'nosePads' | 'templeLength' | 'frameAlignment' | 'lensPosition' |
  /// 'other'.
  final String adjustmentType;

  /// 1-5, client-reported comfort after adjustment.
  final int comfortRating;

  final String notes;

  /// References [QualityCheck.id] — the passing inspection this fitting
  /// follows (per the diagram, Final Fitting only happens after QC pass).
  final String? qualityCheckId;

  FinalFitting({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.date,
    this.adjustmentType = 'frameAlignment',
    this.comfortRating = 5,
    this.notes = '',
    this.qualityCheckId,
  });
}
