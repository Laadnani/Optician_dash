import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/dashboard_appointment.dart';
import 'calendar_date_utils.dart';

class CalendarWeekView extends StatelessWidget {
  final DateTime selectedDate;
  final List<DashboardAppointment> appointments;
  final ValueChanged<DateTime>? onSelectDay;

  const CalendarWeekView({
    super.key,
    required this.selectedDate,
    required this.appointments,
    this.onSelectDay,
  });

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
    final weekStart = startOfWeek(selectedDate);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final day in days)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DayBand(
              day: day,
              isToday: isSameDay(day, DateTime.now()),
              isSelected: isSameDay(day, selectedDate),
              tasks: appointments.where((a) => isSameDay(a.start, day)).toList()
                ..sort((a, b) => a.start.compareTo(b.start)),
              statusColorFor: (status) => _statusColor(theme.colorScheme, status),
              onTap: onSelectDay == null ? null : () => onSelectDay!(day),
            ),
          ),
      ],
    );
  }
}

class _DayBand extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final List<DashboardAppointment> tasks;
  final Color Function(AppointmentStatus) statusColorFor;
  final VoidCallback? onTap;

  const _DayBand({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.tasks,
    required this.statusColorFor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isToday
                          ? theme.colorScheme.primary
                          : (isSelected
                              ? theme.colorScheme.primary.withOpacity(0.15)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isToday ? theme.colorScheme.primaryForeground : null,
                      ),
                    ).semiBold(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      weekdayFull(day.weekday),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).semiBold(),
                  ),
                  if (tasks.isNotEmpty)
                    Text('${tasks.length}').muted().small(),
                ],
              ),
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final task in tasks)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColorFor(task.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColorFor(task.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              formatTime(task.start),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ).small(),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              task.clientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ).small().muted(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
