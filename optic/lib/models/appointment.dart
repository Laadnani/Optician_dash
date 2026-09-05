class Appointment {
  final String id;
  final String clientId;
  final DateTime date;
  final String reason;
  final String status; // scheduled, completed, cancelled

  /// The fee for this visit, in MAD — editable from the appointment card,
  /// independent of [paymentStatus] (a price can be set before it's paid).
  final double price;

  /// paid, unpaid, or not_billable — tracked per appointment rather than
  /// derived, since whether a given visit was actually paid is a fact only
  /// the front desk knows, not something computable from [status].
  final String paymentStatus;

  /// appointment, or reschedule — 'reschedule' means this is a follow-up
  /// visit booked for a client who already has an earlier appointment on
  /// file (booked once the prior one wrapped up), not a first-time booking.
  final String type;

  Appointment({
    required this.id,
    required this.clientId,
    required this.date,
    required this.reason,
    required this.status,
    this.price = 0,
    this.paymentStatus = 'unpaid',
    this.type = 'appointment',
  });

  Appointment copyWith({
    String? id,
    String? clientId,
    DateTime? date,
    String? reason,
    String? status,
    double? price,
    String? paymentStatus,
    String? type,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      price: price ?? this.price,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      type: type ?? this.type,
    );
  }
}
