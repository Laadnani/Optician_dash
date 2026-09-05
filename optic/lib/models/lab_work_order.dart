/// Module 13 — Laboratory. One production job per lens task an [Order]
/// requires (cutting, edging, coating, tinting, engraving) before it's
/// ready for [MountingJob] (module 14).
class LabWorkOrder {
  final String id;
  final String orderId;
  final String clientId;
  final DateTime date;

  /// 'lensCutting' | 'edging' | 'coating' | 'tinting' | 'engraving' |
  /// 'other'.
  final String taskType;

  /// 'queued' | 'inProgress' | 'qualityHold' | 'completed'.
  final String status;

  final DateTime? dueDate;

  /// The following four fields carry the order's clinical/product payload
  /// (per the CRM flow diagram's Laboratory Order node) — derived from
  /// [Order.prescriptionId]/[Order.measurementId]/[Order.frameId]/
  /// [Order.lensId] at creation time.
  final String? prescriptionId;
  final String? measurementId;
  final String? frameId;
  final String? lensId;

  LabWorkOrder({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.date,
    this.taskType = 'lensCutting',
    this.status = 'queued',
    this.dueDate,
    this.prescriptionId,
    this.measurementId,
    this.frameId,
    this.lensId,
  });
}
