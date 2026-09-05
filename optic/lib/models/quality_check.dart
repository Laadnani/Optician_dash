/// Module 15 — Quality Control. The inspection step between [LabWorkOrder]
/// (module 13) / [MountingJob] (module 14) and [FinalFitting] (module 16)
/// — verifying an order's finished glasses meet spec before the client
/// ever sees them.
class QualityCheck {
  final String id;
  final String orderId;
  final String clientId;
  final DateTime date;

  /// 'frameFit' | 'lensQuality' | 'prescriptionAccuracy' | 'cosmetic' |
  /// 'other'.
  final String checkType;

  /// 'pass' | 'fail' | 'conditionalPass'.
  final String result;

  final String notes;

  /// References [MountingJob.id] — the assembly step this check inspects.
  final String? mountingJobId;

  QualityCheck({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.date,
    this.checkType = 'frameFit',
    this.result = 'pass',
    this.notes = '',
    this.mountingJobId,
  });
}
