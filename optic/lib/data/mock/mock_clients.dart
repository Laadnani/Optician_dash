import '../../models/client.dart';
import '../../models/appointment.dart';
import '../../models/eye_exam.dart';
import '../../models/billing.dart';
import '../../models/payments.dart';
import '../../models/insurance.dart';
import '../../models/document.dart';
import '../../models/digital_signature.dart';

/// Mock "today" — a busy demo day for the dashboard, anchored to whenever
/// the app actually launches rather than a hardcoded date, so the schedule
/// always shows up under "Today's schedule" instead of only looking busy on
/// one specific calendar day. Swap this whole file for a real backend (e.g.
/// Firestore) later and this goes away entirely.
final DateTime _today = DateTime.now();

/// A specific hour:minute on [_today] — used for every mock appointment
/// below so the day's timeline reads naturally instead of everything
/// happening at midnight.
DateTime _at(int hour, int minute) =>
    DateTime(_today.year, _today.month, _today.day, hour, minute);

/// [days] before [_today] at midnight — used for prior visits/orders so
/// they consistently land in the past relative to whenever this loads.
DateTime _daysAgo(int days) => _today.subtract(Duration(days: days));

/// [hour]:[minute] on the day [offsetDays] away from [_today] — negative
/// for the past, positive for the future. Used to scatter appointments
/// across the weeks surrounding "today" so the calendar's month view
/// stays alive no matter which real day the app happens to launch on,
/// instead of only ever showing activity on one hardcoded date.
DateTime _onDay(int offsetDays, int hour, int minute) =>
    _at(hour, minute).add(Duration(days: offsetDays));

/// [day] of the month that is [monthsBack] calendar months before
/// [_today]'s month (0 = this month, 1 = last month, ...) — used to spread
/// invoices across the billing screen's 6-month window regardless of which
/// real month the app happens to launch in. Deliberately takes [day]
/// rather than reusing `_today.day` for every call: `DateTime`'s
/// month-arithmetic normalizes an out-of-range day into the *next* month
/// (e.g. Feb 30 -> Mar 2), which would silently push an invoice out of the
/// month it's meant to represent — every call site below passes a safe
/// 1-28 value instead.
DateTime _monthsAgo(int monthsBack, int day) {
  // Zero-based absolute month count (e.g. Jan year 0 = 0), so subtracting
  // `monthsBack` and splitting back into year/month is plain arithmetic —
  // no separate under/overflow-into-previous-year case to get wrong.
  final totalMonths = _today.year * 12 + (_today.month - 1) - monthsBack;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  return DateTime(year, month, day);
}

/// Clients
///
/// P001/P002 are the original two. P003-P010 are "ongoing" clients — each
/// has at least one prior EyeExam below, so they read as established
/// clients rather than first-time visits. P011-P013 are brand new
/// clients — no prior records at all, only today's first appointment.
final List<Client> mockClients = [];

/// Appointments — today's schedule for one busy doctor: 10 ongoing clients
/// (P001-P010) plus 3 new-client first visits (P011-P013), 8:30-17:00 with
/// a lunch gap, mixed statuses so the dashboard's Completed/Scheduled/
/// Cancelled KPI tiles all show something.
final List<Appointment> mockAppointments = [];

/// Prior eye exams for established clients.
final List<EyeExam> mockEyeExams = [];

/// Billing & Invoices
///
/// Spread across the last 6 calendar months (this month back through 5
/// months ago) so `BillingScreen`'s monthly chart has something real to
/// show instead of one lonely bar — mix of paid/pending/cancelled per
/// month, weighted toward "paid" the way a real clinic's books would
/// mostly be, with a handful of pending and the occasional cancellation.
final List<Invoice> mockInvoices = [];

/// Payments
final List<Payment> mockPayments = [];

/// Insurance
final List<Insurance> mockInsurances = [];

/// Documents
final List<DocumentRecord> mockDocuments = [];

/// Digital Signatures
final List<DigitalSignature> mockSignatures = [];
