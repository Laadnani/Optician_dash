import 'package:optic/localization/app_strings.dart';

/// The dashboard's single global date-range filter (Aug 2026 redesign,
/// replacing the old per-widget mini calendar) — one selection drives the
/// KPI row, the Attention section, and the Sales chart, instead of each
/// picking its own timeframe. See `DashboardDateRangeBounds.resolve`.
enum DashboardDateRangeKind { today, thisWeek, thisMonth, custom }

extension DashboardDateRangeKindLabel on DashboardDateRangeKind {
  String get label {
    switch (this) {
      case DashboardDateRangeKind.today:
        return AppStrings.dashRangeToday;
      case DashboardDateRangeKind.thisWeek:
        return AppStrings.dashRangeThisWeek;
      case DashboardDateRangeKind.thisMonth:
        return AppStrings.dashRangeThisMonth;
      case DashboardDateRangeKind.custom:
        return AppStrings.dashRangeCustom;
    }
  }
}

/// The resolved [start, end] (inclusive start, exclusive end) window for a
/// [DashboardDateRangeKind] — plus the same-length window immediately
/// before it, used for every "vs. previous period" comparison on the
/// dashboard (KPI row, Sales Overview) so they all agree on what "previous"
/// means for whichever range is selected.
class DashboardDateRange {
  final DashboardDateRangeKind kind;
  final DateTime start;

  /// Exclusive — e.g. "today" is [start, start + 1 day).
  final DateTime end;

  const DashboardDateRange({
    required this.kind,
    required this.start,
    required this.end,
  });

  Duration get span => end.difference(start);

  DashboardDateRange get previousPeriod => DashboardDateRange(
    kind: kind,
    start: start.subtract(span),
    end: start,
  );

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Builds the current window for [kind]. [customStart]/[customEnd] are
  /// only consulted for [DashboardDateRangeKind.custom] — falls back to
  /// "this month" if a custom range hasn't been picked yet.
  factory DashboardDateRange.resolve(
    DashboardDateRangeKind kind, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();
    switch (kind) {
      case DashboardDateRangeKind.today:
        final start = _dayStart(now);
        return DashboardDateRange(
          kind: kind,
          start: start,
          end: start.add(const Duration(days: 1)),
        );
      case DashboardDateRangeKind.thisWeek:
        final start = _dayStart(now).subtract(Duration(days: now.weekday - 1));
        return DashboardDateRange(
          kind: kind,
          start: start,
          end: start.add(const Duration(days: 7)),
        );
      case DashboardDateRangeKind.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return DashboardDateRange(kind: kind, start: start, end: end);
      case DashboardDateRangeKind.custom:
        if (customStart == null || customEnd == null) {
          return DashboardDateRange.resolve(DashboardDateRangeKind.thisMonth);
        }
        return DashboardDateRange(
          kind: kind,
          start: _dayStart(customStart),
          end: _dayStart(customEnd).add(const Duration(days: 1)),
        );
    }
  }
}
