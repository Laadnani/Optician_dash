/// Module 14 — Mounting. The frame + lens assembly step that follows
/// [LabWorkOrder] (module 13) — fitting the finished lenses into the
/// client's chosen frame ahead of final fitting/delivery.
class MountingJob {
  final String id;
  final String orderId;
  final String clientId;
  final DateTime date;

  /// References [Frame.id].
  final String frameId;

  /// References [Lens.id].
  final String lensId;

  /// 'pending' | 'inProgress' | 'completed' | 'rework'.
  final String status;

  final DateTime? completedDate;

  /// References [LabWorkOrder.id] — the lab job this mounting followed.
  final String? labWorkOrderId;

  /// References [QualityCheck.id], set when this job exists specifically to
  /// remake/rework a failed quality check (the diagram's Remake/Rework
  /// loop back into Assembly/Mounting).
  final String? reworkOfQualityCheckId;

  MountingJob({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.date,
    required this.frameId,
    required this.lensId,
    this.status = 'pending',
    this.completedDate,
    this.labWorkOrderId,
    this.reworkOfQualityCheckId,
  });
}
