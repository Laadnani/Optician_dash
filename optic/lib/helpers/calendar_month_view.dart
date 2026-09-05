import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/dashboard_appointment.dart';
import 'breakpoint.dart';
import 'calendar_date_utils.dart';

class CalendarMonthView extends StatelessWidget {
  final DateTime selectedDate;
  final List<DashboardAppointment> appointments;
  final Breakpoint breakpoint;
  final ValueChanged<DateTime>? onSelectDay;

  const CalendarMonthView({
    super.key,
    required this.selectedDate,
    required this.appointments,
    required this.breakpoint,
    this.onSelectDay,
  });

  // Fixed 6 rows (42 cells) so the grid height is consistent regardless of
  // which month is showing (some months need 6 rows to fit all their
  // leading/trailing days, so using a variable row count would make the
  // grid jump size between months).
  List<DateTime> _gridDays() {
    final firstOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final gridStart = startOfWeek(firstOfMonth);
    return List.generate(42, (i) => gridStart.add(Duration(days: i)));
  }

  Color _statusColor(ColorScheme colors, AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return colors.primary;
      case AppointmentStatus.completed:
        return Colors.green.shade700;
      case AppointmentStatus.cancelled:
        return colors.destructive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _gridDays();
    final today = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var w = 1; w <= 7; w++)
                  Expanded(
                    child: Center(
                      child: Text(
                        weekdayShort(w),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).muted().small(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, i) {
                final day = days[i];
                final inCurrentMonth = day.month == selectedDate.month;
                final isToday = isSameDay(day, today);
                final isSelected = isSameDay(day, selectedDate);
                final dayTasks =
                    appointments.where((a) => isSameDay(a.start, day)).toList();

                return _MonthCell(
                  day: day,
                  inCurrentMonth: inCurrentMonth,
                  isToday: isToday,
                  isSelected: isSelected,
                  breakpoint: breakpoint,
                  taskColors: [
                    for (final t in dayTasks)
                      _statusColor(theme.colorScheme, t.status),
                  ],
                  onTap: onSelectDay == null ? null : () => onSelectDay!(day),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final DateTime day;
  final bool inCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final Breakpoint breakpoint;
  final List<Color> taskColors;
  final VoidCallback? onTap;

  const _MonthCell({
    required this.day,
    required this.inCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.breakpoint,
    required this.taskColors,
    required this.onTap,
  });

  // Bands, not dots: each task gets its own small rounded bar instead of a
  // 6px circle — reads clearly at a glance instead of blurring into a
  // single blob, and each bar is already colored independently via
  // `taskColors`, so this is ready for per-task-*type* color coding later
  // (not just appointment status) with no further changes here.
  //
  // Sized per breakpoint rather than one fixed size: phone cells are tiny
  // (7 columns on a ~390px screen) and the FittedBox below already has to
  // scale hard just to fit the date circle, so bands stay compact there.
  // Tablet/desktop cells have real room to spare, so the bands scale up
  // to actually read as bands instead of looking lost in the extra space.
  static const int _maxBands = 3;

  double get _bandWidth => switch (breakpoint) {
    Breakpoint.mobile => 26,
    Breakpoint.tablet => 40,
    Breakpoint.desktop => 56,
  };

  double get _bandHeight => switch (breakpoint) {
    Breakpoint.mobile => 5,
    Breakpoint.tablet => 9,
    Breakpoint.desktop => 12,
  };

  double get _bandSpacing => switch (breakpoint) {
    Breakpoint.mobile => 2,
    Breakpoint.tablet => 3,
    Breakpoint.desktop => 4,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overflowCount = taskColors.length - _maxBands;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.10)
              : null,
          border: Border.all(
            color: theme.colorScheme.border,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(4),
        // Safety net: month cells get very small on a phone (7 columns),
        // and this is exactly the shape of layout that overflowed on the
        // KPI cards earlier — FittedBox guarantees this can't repeat here,
        // regardless of how tight the cell ends up being.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? theme.colorScheme.primary : null,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isToday
                        ? theme.colorScheme.primaryForeground
                        : (inCurrentMonth
                            ? null
                            : theme.colorScheme.mutedForeground),
                  ),
                ).small(),
              ),
              const SizedBox(height: 4),
              // Always renders `_maxBands` slots (transparent when unused)
              // so every cell reserves the same natural height — otherwise
              // a quiet day and a busy day would scale differently under
              // the FittedBox above, making date numbers visibly different
              // sizes across the same grid.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _maxBands; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: _bandSpacing),
                      child: Container(
                        width: _bandWidth,
                        height: _bandHeight,
                        decoration: BoxDecoration(
                          color: i < taskColors.length
                              ? taskColors[i]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            _bandHeight / 2,
                          ),
                        ),
                      ),
                    ),
                  if (overflowCount > 0)
                    Text('+$overflowCount').muted().small(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
