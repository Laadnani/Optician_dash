/// Module 9 — Lens Recommendation (Optical Consultation). The staff's
/// lens-type/coating advice for a client, usually following their
/// prescription and frame selection — and whether the client accepted it.
class LensRecommendation {
  final String id;
  final String clientId;
  final DateTime date;

  /// References [Prescription.id], when the recommendation follows one on
  /// file.
  final String? prescriptionId;

  /// References [Measurement.id], when the recommendation was informed by a
  /// fitting measurement session on file.
  final String? measurementId;

  /// References [FrameSelectionSession.id], when the recommendation follows
  /// a frame selection session on file.
  final String? frameSelectionId;

  /// Matches [Lens.lensType] values (singleVision, progressive, ...).
  final String recommendedLensType;
  final List<String> recommendedCoatings;
  final String reason;
  final bool accepted;

  LensRecommendation({
    required this.id,
    required this.clientId,
    required this.date,
    this.prescriptionId,
    this.measurementId,
    this.frameSelectionId,
    required this.recommendedLensType,
    this.recommendedCoatings = const [],
    this.reason = '',
    this.accepted = false,
  });
}
