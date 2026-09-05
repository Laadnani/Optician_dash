import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'calendar_date_utils.dart';
import '../localization/app_strings.dart';

enum CalendarViewMode { day, week, month }

class CalendarHeaderBar extends StatelessWidget {
  final DateTime selectedDate;
  final CalendarViewMode viewMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<CalendarViewMode> onViewModeChanged;

  const CalendarHeaderBar({
    super.key,
    required this.selectedDate,
    required this.viewMode,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onViewModeChanged,
  });

  String get _headingText {
    switch (viewMode) {
      case CalendarViewMode.day:
        return formatFullDate(selectedDate);
      case CalendarViewMode.week:
        return formatWeekRange(startOfWeek(selectedDate));
      case CalendarViewMode.month:
        return formatMonthYear(selectedDate);
    }
  }

  Widget _viewModeButton(String label, CalendarViewMode mode) {
    return Button(
      style: mode == viewMode
          ? const ButtonStyle.primary()
          : const ButtonStyle.ghost(),
      onPressed: () => onViewModeChanged(mode),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Below this width there isn't room for the heading text and the
        // full nav+switcher cluster on one line — the switcher drops to
        // its own row instead of forcing an overflow.
        final isCompact = constraints.maxWidth < 560;

        final navCluster = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button(
              style: const ButtonStyle.ghost(),
              onPressed: onPrevious,
              child: const Icon(Icons.chevron_left, size: 18),
            ),
            Button(
              style: const ButtonStyle.ghost(),
              onPressed: onNext,
              child: const Icon(Icons.chevron_right, size: 18),
            ),
            const SizedBox(width: 4),
            Button.outline(
              onPressed: onToday,
              child: Text(AppStrings.calendarTodayButton),
            ),
          ],
        );

        final viewSwitcher = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _viewModeButton('Day', CalendarViewMode.day),
            const SizedBox(width: 4),
            _viewModeButton('Week', CalendarViewMode.week),
            const SizedBox(width: 4),
            _viewModeButton('Month', CalendarViewMode.month),
          ],
        );

        final heading = Text(
          _headingText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ).semiBold();

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: heading),
                  navCluster,
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: viewSwitcher,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 12),
            navCluster,
            const SizedBox(width: 16),
            viewSwitcher,
          ],
        );
      },
    );
  }
}
