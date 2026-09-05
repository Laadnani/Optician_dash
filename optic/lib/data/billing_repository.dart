import 'package:optic/data/data_provider.dart';
import '../models/billing.dart';
import '../models/appointment.dart';

/// One calendar month's invoice totals, split by [Invoice.status] — both
/// the summed amount (MAD) and the raw count, since `BillingScreen` lets
/// the doctor flip between an "amount" view and a "count" view of the same
/// underlying months without re-fetching.
class MonthlyBillingSummary {
  /// The 1st of the month this summary covers — just used for labeling
  /// (month/year) and to guarantee chronological order; the day is always 1.
  final DateTime month;

  final double paidAmount;
  final double pendingAmount;
  final double cancelledAmount;

  final int paidCount;
  final int pendingCount;
  final int cancelledCount;

  const MonthlyBillingSummary({
    required this.month,
    required this.paidAmount,
    required this.pendingAmount,
    required this.cancelledAmount,
    required this.paidCount,
    required this.pendingCount,
    required this.cancelledCount,
  });

  double get totalAmount => paidAmount + pendingAmount + cancelledAmount;
  int get totalCount => paidCount + pendingCount + cancelledCount;
}

/// Where `BillingScreen` gets its data — same "simple for now, real backend
/// later" bridge as `DashboardRepository`/`ClientRepository`.
///
/// [fetchMonthlySummary] is the older, Invoice-based view — still here for
/// whatever still reads it (e.g. a client's own Invoices/Payments tab is
/// backed by `Invoice` directly, not through this repository, so this stays
/// untouched). [fetchWeeklyAppointmentRevenue]/[fetchMonthlyRevenueComparison]
/// are the newer, Appointment-based views the billing screen itself now
/// reads: appointments carry their own `price`/`paymentStatus`/`type`, so
/// "how much did the doctor actually make" no longer depends on a separate,
/// unlinked Invoice record existing for it.
abstract class BillingRepository {
  Future<List<MonthlyBillingSummary>> fetchMonthlySummary({int monthsBack});
  Future<List<WeeklyAppointmentRevenue>> fetchWeeklyAppointmentRevenue({
    int weeksBack,
  });
  /// The calendar weeks (Monday-start) that overlap [month] — what the
  /// billing screen's month filter reads instead of
  /// [fetchWeeklyAppointmentRevenue] once a specific month is being browsed.
  Future<List<WeeklyAppointmentRevenue>> fetchWeeksForMonth(DateTime month);
  Future<MonthlyRevenueComparison> fetchMonthlyRevenueComparison({
    DateTime? referenceMonth,
  });
}

class ProviderBillingRepository implements BillingRepository {
  final DataProvider dataProvider;

  const ProviderBillingRepository(this.dataProvider);

  @override
  Future<List<MonthlyBillingSummary>> fetchMonthlySummary({
    int monthsBack = 6,
  }) async => deriveMonthlyBillingSummary(dataProvider.invoices, monthsBack: monthsBack);

  @override
  Future<List<WeeklyAppointmentRevenue>> fetchWeeklyAppointmentRevenue({
    int weeksBack = 8,
  }) async => deriveWeeklyAppointmentRevenue(
    dataProvider.appointments,
    weeksBack: weeksBack,
  );

  @override
  Future<List<WeeklyAppointmentRevenue>> fetchWeeksForMonth(
    DateTime month,
  ) async => deriveWeeksForMonth(dataProvider.appointments, month);

  @override
  Future<MonthlyRevenueComparison> fetchMonthlyRevenueComparison({
    DateTime? referenceMonth,
  }) async => deriveMonthlyRevenueComparison(
    dataProvider.appointments,
    referenceMonth: referenceMonth,
  );
}

/// Pure synchronous derivation, pulled out the same way
/// `derivePendingTasks` was — lets anything holding a `DataProvider`
/// compute this without going through the repository/Future indirection
/// if it needs to (e.g. a future dashboard KPI card).
///
/// Always returns exactly [monthsBack] entries, oldest first, one per
/// calendar month — including months with zero invoices — so the chart's
/// x-axis is a stable, evenly-spaced timeline instead of only showing
/// whichever months happen to have data.
List<MonthlyBillingSummary> deriveMonthlyBillingSummary(
  List<Invoice> invoices, {
  int monthsBack = 6,
}) {
  final now = DateTime.now();

  // One bucket per month, keyed by "YYYY-M" so we don't have to worry
  // about DateTime equality/hashing across differently-constructed dates
  // for what's conceptually the same month.
  final months = <String, DateTime>{};
  final paidAmount = <String, double>{};
  final pendingAmount = <String, double>{};
  final cancelledAmount = <String, double>{};
  final paidCount = <String, int>{};
  final pendingCount = <String, int>{};
  final cancelledCount = <String, int>{};

  String keyFor(int year, int month) => '$year-$month';

  for (var i = monthsBack - 1; i >= 0; i--) {
    final totalMonths = now.year * 12 + (now.month - 1) - i;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final key = keyFor(year, month);
    months[key] = DateTime(year, month, 1);
    paidAmount[key] = 0;
    pendingAmount[key] = 0;
    cancelledAmount[key] = 0;
    paidCount[key] = 0;
    pendingCount[key] = 0;
    cancelledCount[key] = 0;
  }

  for (final invoice in invoices) {
    final key = keyFor(invoice.date.year, invoice.date.month);
    if (!months.containsKey(key)) continue; // outside the requested window

    switch (invoice.status.toLowerCase()) {
      case 'paid':
        paidAmount[key] = paidAmount[key]! + invoice.amount;
        paidCount[key] = paidCount[key]! + 1;
        break;
      case 'pending':
        pendingAmount[key] = pendingAmount[key]! + invoice.amount;
        pendingCount[key] = pendingCount[key]! + 1;
        break;
      case 'cancelled':
        cancelledAmount[key] = cancelledAmount[key]! + invoice.amount;
        cancelledCount[key] = cancelledCount[key]! + 1;
        break;
      default:
        // Unrecognized status value — same defensive stance as
        // `statusChipStyle`'s default case: don't drop it, but don't
        // guess which bucket it belongs in either.
        break;
    }
  }

  final orderedKeys = months.keys.toList()
    ..sort((a, b) => months[a]!.compareTo(months[b]!));

  return [
    for (final key in orderedKeys)
      MonthlyBillingSummary(
        month: months[key]!,
        paidAmount: paidAmount[key]!,
        pendingAmount: pendingAmount[key]!,
        cancelledAmount: cancelledAmount[key]!,
        paidCount: paidCount[key]!,
        pendingCount: pendingCount[key]!,
        cancelledCount: cancelledCount[key]!,
      ),
  ];
}

// ---------------------------------------------------------------------------
// Appointment-based revenue — what the billing screen actually reads now.
// Entirely separate from the Invoice-based types/functions above.
// ---------------------------------------------------------------------------

/// One calendar week's paid appointment revenue, split by [Appointment.type]
/// ('appointment' — a first visit — vs 'reschedule' — a follow-up booked
/// once an earlier visit for the same client wrapped up).
class WeeklyAppointmentRevenue {
  /// The Monday that starts this week — used for labeling and to
  /// guarantee chronological order; only the date part is meaningful.
  final DateTime weekStart;
  final double appointmentAmount;
  final double rescheduleAmount;

  const WeeklyAppointmentRevenue({
    required this.weekStart,
    required this.appointmentAmount,
    required this.rescheduleAmount,
  });

  double get totalAmount => appointmentAmount + rescheduleAmount;
}

/// Monday of the week [date] falls in, at midnight — `DateTime.weekday` is
/// 1 (Monday) through 7 (Sunday), so subtracting `weekday - 1` days always
/// lands on that week's Monday regardless of which day [date] itself is.
DateTime _mondayOf(DateTime date) {
  final atMidnight = DateTime(date.year, date.month, date.day);
  return atMidnight.subtract(Duration(days: atMidnight.weekday - 1));
}

/// Always returns exactly [weeksBack] entries, oldest first, one per
/// calendar week (Monday-start) ending with the current week — including
/// weeks with zero paid revenue — so the chart's x-axis is a stable,
/// evenly-spaced timeline. Only [Appointment.paymentStatus] == 'paid'
/// counts as revenue; 'unpaid'/'not_billable' visits don't contribute,
/// since this is "how much money the doctor made", not "how much was
/// scheduled".
List<WeeklyAppointmentRevenue> deriveWeeklyAppointmentRevenue(
  List<Appointment> appointments, {
  int weeksBack = 8,
}) {
  final currentWeekStart = _mondayOf(DateTime.now());

  // Keyed by "YYYY-M-D" (the week's Monday) for the same reason
  // `deriveMonthlyBillingSummary` uses string keys instead of `DateTime`
  // itself — sidesteps ever having to reason about `DateTime`
  // equality/hashing across two differently-constructed dates that are
  // meant to represent the same day.
  String keyFor(DateTime d) => '${d.year}-${d.month}-${d.day}';

  final weekStarts = <String, DateTime>{};
  final appointmentAmount = <String, double>{};
  final rescheduleAmount = <String, double>{};

  for (var i = weeksBack - 1; i >= 0; i--) {
    final weekStart = currentWeekStart.subtract(Duration(days: 7 * i));
    final key = keyFor(weekStart);
    weekStarts[key] = weekStart;
    appointmentAmount[key] = 0;
    rescheduleAmount[key] = 0;
  }

  for (final appt in appointments) {
    if (appt.paymentStatus != 'paid') continue;
    final key = keyFor(_mondayOf(appt.date));
    if (!weekStarts.containsKey(key)) continue; // outside the requested window

    if (appt.type == 'reschedule') {
      rescheduleAmount[key] = rescheduleAmount[key]! + appt.price;
    } else {
      appointmentAmount[key] = appointmentAmount[key]! + appt.price;
    }
  }

  final orderedKeys = weekStarts.keys.toList()
    ..sort((a, b) => weekStarts[a]!.compareTo(weekStarts[b]!));

  return [
    for (final key in orderedKeys)
      WeeklyAppointmentRevenue(
        weekStart: weekStarts[key]!,
        appointmentAmount: appointmentAmount[key]!,
        rescheduleAmount: rescheduleAmount[key]!,
      ),
  ];
}

/// The calendar weeks (Monday-start) that overlap [month] — every week
/// with at least one day falling in that month, including zero-revenue
/// weeks, so a chart built off this always has a stable, evenly-spaced
/// x-axis for whichever month is being browsed. Same 'paid'-only revenue
/// rule as [deriveWeeklyAppointmentRevenue].
List<WeeklyAppointmentRevenue> deriveWeeksForMonth(
  List<Appointment> appointments,
  DateTime month,
) {
  final monthStart = DateTime(month.year, month.month, 1);
  final monthEnd = DateTime(month.year, month.month + 1, 0);
  final firstWeekStart = _mondayOf(monthStart);
  final lastWeekStart = _mondayOf(monthEnd);

  String keyFor(DateTime d) => '${d.year}-${d.month}-${d.day}';

  final weekStarts = <String, DateTime>{};
  final appointmentAmount = <String, double>{};
  final rescheduleAmount = <String, double>{};

  var cursor = firstWeekStart;
  while (!cursor.isAfter(lastWeekStart)) {
    final key = keyFor(cursor);
    weekStarts[key] = cursor;
    appointmentAmount[key] = 0;
    rescheduleAmount[key] = 0;
    cursor = cursor.add(const Duration(days: 7));
  }

  for (final appt in appointments) {
    if (appt.paymentStatus != 'paid') continue;
    final key = keyFor(_mondayOf(appt.date));
    if (!weekStarts.containsKey(key)) continue; // outside the requested window

    if (appt.type == 'reschedule') {
      rescheduleAmount[key] = rescheduleAmount[key]! + appt.price;
    } else {
      appointmentAmount[key] = appointmentAmount[key]! + appt.price;
    }
  }

  final orderedKeys = weekStarts.keys.toList()
    ..sort((a, b) => weekStarts[a]!.compareTo(weekStarts[b]!));

  return [
    for (final key in orderedKeys)
      WeeklyAppointmentRevenue(
        weekStart: weekStarts[key]!,
        appointmentAmount: appointmentAmount[key]!,
        rescheduleAmount: rescheduleAmount[key]!,
      ),
  ];
}

/// This calendar month's total paid appointment revenue vs. last month's —
/// what the billing screen's two KPI cards ("Total this month" /
/// "Vs. last month") read off.
class MonthlyRevenueComparison {
  final double thisMonthTotal;
  final double lastMonthTotal;

  const MonthlyRevenueComparison({
    required this.thisMonthTotal,
    required this.lastMonthTotal,
  });

  double get delta => thisMonthTotal - lastMonthTotal;

  /// Percent change vs. last month (e.g. 0.12 for +12%). Null when last
  /// month had zero revenue — a percentage off a zero base isn't
  /// meaningful, so the UI falls back to showing the raw MAD delta instead.
  double? get percentChange =>
      lastMonthTotal == 0 ? null : delta / lastMonthTotal;
}

/// Paid-appointment revenue total for an arbitrary `[start, end)` window,
/// plus the same total for the immediately preceding window of equal
/// length — what the redesigned dashboard's Sales KPI tile and Sales
/// Overview panel headline read off once a [DashboardDateRange] (Today /
/// This week / This month / Custom) is selected, instead of being locked
/// to calendar months like [deriveMonthlyRevenueComparison] above (which
/// stays as-is for `BillingScreen`, unrelated to this).
class RangeRevenueComparison {
  final double currentTotal;
  final double previousTotal;

  const RangeRevenueComparison({
    required this.currentTotal,
    required this.previousTotal,
  });

  double get delta => currentTotal - previousTotal;

  double? get percentChange =>
      previousTotal == 0 ? null : delta / previousTotal;
}

RangeRevenueComparison deriveRevenueForRange(
  List<Appointment> appointments, {
  required DateTime start,
  required DateTime end,
}) {
  final span = end.difference(start);
  final previousStart = start.subtract(span);

  double totalIn(DateTime from, DateTime to) => appointments
      .where(
        (a) =>
            a.paymentStatus == 'paid' &&
            !a.date.isBefore(from) &&
            a.date.isBefore(to),
      )
      .fold<double>(0, (sum, a) => sum + a.price);

  return RangeRevenueComparison(
    currentTotal: totalIn(start, end),
    previousTotal: totalIn(previousStart, start),
  );
}

MonthlyRevenueComparison deriveMonthlyRevenueComparison(
  List<Appointment> appointments, {
  DateTime? referenceMonth,
}) {
  final ref = referenceMonth ?? DateTime.now();

  double totalPaidFor(int year, int month) => appointments
      .where(
        (a) =>
            a.paymentStatus == 'paid' &&
            a.date.year == year &&
            a.date.month == month,
      )
      .fold<double>(0, (sum, a) => sum + a.price);

  final lastMonth = DateTime(ref.year, ref.month - 1, 1);

  return MonthlyRevenueComparison(
    thisMonthTotal: totalPaidFor(ref.year, ref.month),
    lastMonthTotal: totalPaidFor(lastMonth.year, lastMonth.month),
  );
}
