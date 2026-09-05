/// Module 8 — Frame Selection / Virtual Sale. One record per fitting
/// session: which frames a client tried (in-store or via a virtual
/// try-on), and which one — if any — they picked. `selectedFrameId`, when
/// set, references [Frame.id] from the frame inventory catalog.
class FrameSelectionSession {
  final String id;
  final String clientId;

  /// References [OpticalConsultation.id], when this session follows a
  /// recorded consultation visit.
  final String? consultationId;
  final DateTime date;

  /// 'inStore' | 'virtual'.
  final String method;

  /// Frame SKUs/ids tried during the session.
  final List<String> framesTried;

  /// The frame the client settled on, if any — references [Frame.id].
  final String? selectedFrameId;

  final String notes;

  FrameSelectionSession({
    required this.id,
    required this.clientId,
    this.consultationId,
    required this.date,
    this.method = 'inStore',
    this.framesTried = const [],
    this.selectedFrameId,
    this.notes = '',
  });
}
