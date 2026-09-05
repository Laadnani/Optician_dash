/// What kind of record produced this timeline entry — drives the icon in
/// `ClientTimelineTab` (client_file_screen.dart) the same way
/// `PendingTaskKind` drives `PendingTasksPanel`'s icons. Add a case here
/// whenever a new source model should appear on a client's timeline; the
/// compiler then flags every switch that needs a new case too.
///
/// Ordered to roughly follow the CRM flow diagram: intake → clinical →
/// funnel → production → delivery → after-sales.
enum ClientTimelineEventKind {
  appointment,
  consultation,
  eyeExam,
  prescription,
  measurement,
  frameSelection,
  lensRecommendation,
  communication,
  quote,
  order,
  payment,
  labWorkOrder,
  mountingJob,
  qualityCheck,
  finalFitting,
  invoice,
  delivery,
  afterSales,
  repair,
  warranty,
}

/// A single chronological entry on a client's timeline — the CRM flow
/// diagram's "Client Timeline" node, aggregating every client-linked
/// record `DataProvider` carries into one ordered feed. Deliberately
/// generic (display-ready `title`/`subtitle` + enough identity to navigate
/// back to the source record later) — same shape as `PendingTask`, just
/// covering the full client history instead of only open items.
class ClientTimelineEvent {
  final String id;
  final String title;
  final String subtitle;
  final ClientTimelineEventKind kind;

  /// id of the record this entry summarizes.
  final String sourceId;

  final DateTime date;

  const ClientTimelineEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.sourceId,
    required this.date,
  });
}
