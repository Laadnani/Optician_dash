/// Matches your real `Appointment.status` values exactly — no invented
/// states. If you later add more statuses to the real model (e.g.
/// "in progress", "no-show"), add them here too and the switch statements
/// in `appointment_tile.dart` / `dashboard_screen.dart` will flag every
/// place that needs a new case (Dart's exhaustiveness check on enums).
enum AppointmentStatus { scheduled, completed, cancelled }

/// The dashboard/appointment-tile's view of an appointment: your real
/// `Appointment` (id, clientId, date, reason, status) plus `clientName`,
/// resolved from `Client` at the repository layer since `Appointment`
/// itself only stores `clientId`.
///
/// No `duration` or `type` — your real model doesn't have them, and I'd
/// rather the UI just not show that info than fake it.
class DashboardAppointment {
  final String id;
  final String clientId;
  final String clientName;
  final DateTime start;
  final String reason;
  final AppointmentStatus status;

  const DashboardAppointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.start,
    required this.reason,
    required this.status,
  });

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
