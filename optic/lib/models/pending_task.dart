/// What kind of record generated this task — drives the icon/color in
/// [PendingTasksPanel] and (eventually) which detail screen tapping it
/// should open. Add a case here whenever a new source model needs to
/// surface "needs attention" items; the compiler will then flag every
/// switch (in the panel, in any factory below) that needs a new case too.
///
/// Trimmed down as part of the clinical → optical-retail pivot: `labResult`,
/// `imagingResult`, `referral`, and `lowStock` all came from deleted
/// clinical/generic-inventory models. Only `signature` survives; new
/// retail-derived kinds (e.g. order/production-stage tasks) get added here
/// once those modules exist.
enum PendingTaskKind { signature }

/// A single "needs your attention" item on the dashboard. Deliberately
/// generic — it does NOT hold a `DigitalSignature`/etc. directly, just a
/// display-ready `title`/`subtitle` plus enough identity (`sourceId`,
/// `clientId`) to navigate back to the real record. This is what lets any
/// model "produce" a pending task the same way any model can carry a
/// `clientId` to reference a `Client` — the model that generates it
/// doesn't need to know anything about how the dashboard displays it.
///
/// Factory constructors — one per source model — can be added here as new
/// retail modules (orders, production stages, etc.) grow their own
/// "needs attention" states; for now `derivePendingTasks` in
/// `dashboard_repository.dart` builds every [PendingTask] directly.
class PendingTask {
  final String id;
  final String title;
  final String subtitle;
  final PendingTaskKind kind;

  /// id of the record this task is about, so tapping the task can
  /// navigate straight to it once that wiring exists.
  final String sourceId;

  /// Client this task concerns, if any.
  final String? clientId;

  /// When the underlying source record was created — lets the Tasks screen
  /// scope this list to a browsed month the same way every other activity
  /// module screen does.
  final DateTime date;

  const PendingTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.sourceId,
    required this.date,
    this.clientId,
  });
}
