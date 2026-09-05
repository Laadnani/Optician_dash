/// Module 7 — Client Communication. One record per call/SMS/WhatsApp/email
/// touchpoint with a client (appointment reminders, order-ready notices,
/// follow-up check-ins). Same "practical core fields" depth as modules 2-6
/// — this is a log, not a full messaging/CRM thread system.
class CommunicationLog {
  final String id;
  final String clientId;
  final DateTime date;

  /// 'phone' | 'sms' | 'whatsapp' | 'email' | 'inPerson'.
  final String channel;

  /// 'inbound' | 'outbound'.
  final String direction;

  final String subject;
  final String note;
  final bool followUpRequired;

  CommunicationLog({
    required this.id,
    required this.clientId,
    required this.date,
    this.channel = 'phone',
    this.direction = 'outbound',
    required this.subject,
    this.note = '',
    this.followUpRequired = false,
  });
}
