import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'calendar_date_utils.dart';
import '../localization/app_strings.dart';

/// The "‹ August 2026 ›" month-navigation control every activity-driven
/// module screen (Quotes, Orders, Laboratory, ... — anything with its own
/// per-record [DateTime]) uses to scope its list/KPIs to one calendar
/// month at a time — the same interaction pattern `CalendarHeaderBar`
/// already established on the Calendar screen, just without the Day/Week
/// view switcher these list screens don't need.
///
/// Stateless — the caller (each screen's own State) owns `selectedMonth`
/// and reacts to [onPrevious]/[onNext]/[onCurrentMonth] by filtering its
/// own data, same division of responsibility as `CalendarHeaderBar`.
class MonthFilterBar extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrentMonth;

  const MonthFilterBar({
    super.key,
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrentMonth,
  });

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 18,
            color: colorScheme.mutedForeground,
          ),
          const SizedBox(width: 10),
          Button(
            style: const ButtonStyle.ghost(),
            onPressed: onPrevious,
            child: const Icon(Icons.chevron_left, size: 18),
          ),
          SizedBox(
            width: 140,
            child: Text(
              formatMonthYear(selectedMonth),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ).semiBold(),
          ),
          Button(
            style: const ButtonStyle.ghost(),
            onPressed: onNext,
            child: const Icon(Icons.chevron_right, size: 18),
          ),
          const SizedBox(width: 8),
          if (!_isCurrentMonth)
            Button.outline(
              onPressed: onCurrentMonth,
              child: Text(AppStrings.monthFilterThisMonth),
            ),
        ],
      ),
    );
  }
}

/// Shared month-navigation state — every `_XxxBody` `State` mixes this in
/// instead of re-declaring the same three methods 16 times. Callers
/// implement nothing beyond calling `setState` implicitly via [initState]
/// not being required — `selectedMonth` starts on the current month and
/// [goPreviousMonth]/[goNextMonth]/[goCurrentMonth] are ready to wire
/// straight into a [MonthFilterBar].
mixin MonthFilterState<T extends StatefulWidget> on State<T> {
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  void goPreviousMonth() => setState(() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
  });

  void goNextMonth() => setState(() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
  });

  void goCurrentMonth() => setState(() {
    selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  });

  bool isInSelectedMonth(DateTime date) =>
      date.year == selectedMonth.year && date.month == selectedMonth.month;

  MonthFilterBar buildMonthFilterBar() => MonthFilterBar(
    selectedMonth: selectedMonth,
    onPrevious: goPreviousMonth,
    onNext: goNextMonth,
    onCurrentMonth: goCurrentMonth,
  );
}
