import 'package:optic/data/data_provider.dart';
import '../models/dashboard_appointment.dart';
import '../models/pending_task.dart';
import '../localization/app_strings.dart';

/// Where the dashboard's data comes from. `DashboardScreen` only ever talks
/// to this interface — swap the implementation and nothing in the UI needs
/// to change.
abstract class DashboardRepository {
  Future<List<DashboardAppointment>> fetchAppointments();
  Future<List<PendingTask>> fetchPendingTasks();
}

/// Backed by your real `DataProvider` (Clients/Appointments/etc., wired
/// through Provider). This is the "simple for now, real backend later"
/// bridge you asked for: once `DataProvider` itself talks to your API
/// instead of holding `mockClients`/`mockAppointments` in memory, this
/// class doesn't need to change at all — it already just reads through
/// `DataProvider`.
class ProviderDashboardRepository implements DashboardRepository {
  final DataProvider dataProvider;

  const ProviderDashboardRepository(this.dataProvider);

  @override
  Future<List<DashboardAppointment>> fetchAppointments() async {
    final clientsById = {
      for (final client in dataProvider.clients) client.id: client,
    };

    return dataProvider.appointments.map((appointment) {
      final client = clientsById[appointment.clientId];
      final clientName = client != null
          ? '${client.firstName} ${client.lastName}'
          : AppStrings.taskUnknownClient;

      return DashboardAppointment(
        id: appointment.id,
        clientId: appointment.clientId,
        clientName: clientName,
        start: appointment.date,
        reason: appointment.reason,
        status: _mapStatus(appointment.status),
      );
    }).toList();
  }

  AppointmentStatus _mapStatus(String raw) {
    switch (raw) {
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'scheduled':
      default:
        // Falls back to "scheduled" for any unrecognized value rather than
        // throwing, since `Appointment.status` is a plain String (not an
        // enum) and could carry an unexpected value from a future backend.
        return AppointmentStatus.scheduled;
    }
  }

  @override
  Future<List<PendingTask>> fetchPendingTasks() async =>
      derivePendingTasks(dataProvider);
}

/// Derived straight from `DataProvider`'s record lists — no separate
/// "tasks" table exists (or needs to). Trimmed down as part of the
/// clinical → optical-retail pivot: the lab-result, imaging-result,
/// referral, and low-stock sources all read off deleted clinical/generic-
/// inventory models and are gone. What's left:
///   - signatures: a consent `DocumentRecord` with no matching
///     `DigitalSignature` for that client yet
///
/// Pulled out as a plain synchronous top-level function (rather than kept
/// private inside [ProviderDashboardRepository.fetchPendingTasks]) so the
/// global notification bell (in `AppShell`, showing on every screen) can
/// call it directly off `context.watch<DataProvider>()` without needing a
/// `FutureBuilder` for what's actually synchronous in-memory work — it's
/// the exact same derivation `fetchPendingTasks()` uses, just callable from
/// both places.
List<PendingTask> derivePendingTasks(DataProvider dataProvider) {
  final clientsById = {
    for (final client in dataProvider.clients) client.id: client,
  };
  String nameFor(String clientId) {
    final client = clientsById[clientId];
    return client != null
        ? '${client.firstName} ${client.lastName}'
        : AppStrings.taskUnknownClient;
  }

  final tasks = <PendingTask>[];

  final signedClientIds = dataProvider.signatures
      .map((s) => s.clientId)
      .toSet();
  for (final doc in dataProvider.documents) {
    if (!doc.type.toLowerCase().contains('consent')) continue;
    if (signedClientIds.contains(doc.clientId)) continue;
    tasks.add(
      PendingTask(
        id: 'signature-${doc.id}',
        title: AppStrings.taskConsentNeedsSignature,
        subtitle: nameFor(doc.clientId),
        kind: PendingTaskKind.signature,
        sourceId: doc.id,
        clientId: doc.clientId,
        date: doc.uploadedAt,
      ),
    );
  }

  return tasks;
}
