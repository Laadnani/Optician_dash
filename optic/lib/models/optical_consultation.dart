/// Optical Consultation — the lifestyle/visual-needs intake that follows an
/// [Appointment] and precedes [Prescription]/[Measurement]/
/// [FrameSelectionSession] on the CRM flow diagram. Captures why the
/// client is here today (daily activities, screen usage, driving, reading,
/// work environment, previous problems) so those three downstream records
/// can point back to the same visit's context via `consultationId`.
class OpticalConsultation {
  final String id;
  final String clientId;

  /// References [Appointment.id], when the consultation follows one on file.
  final String? appointmentId;

  final DateTime date;

  final String visualNeeds;
  final String dailyActivities;

  /// 'low' | 'moderate' | 'high'.
  final String screenUsage;

  final bool driving;
  final bool reading;
  final String workEnvironment;
  final String previousProblems;
  final String notes;

  OpticalConsultation({
    required this.id,
    required this.clientId,
    this.appointmentId,
    required this.date,
    this.visualNeeds = '',
    this.dailyActivities = '',
    this.screenUsage = 'moderate',
    this.driving = false,
    this.reading = false,
    this.workEnvironment = '',
    this.previousProblems = '',
    this.notes = '',
  });
}
