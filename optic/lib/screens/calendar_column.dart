import 'package:optic/models/dashboard_appointment.dart';
import 'package:optic/helpers/mini_month_calendar.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class CalendarColumn extends StatelessWidget {
  final DateTime selectedDate;
  final List<DashboardAppointment> appointments;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarColumn({
    required this.selectedDate,
    required this.appointments,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final datesWithAppointments = appointments
        .map((a) => DateTime(a.start.year, a.start.month, a.start.day))
        .toSet();

    // Fixed card padding (matching AppointmentsColumn/PendingTasksPanel)
    // rather than the previous no-padding layout, now that all three
    // dashboard cards share one consistent card frame. `MiniMonthCalendar`
    // is handed straight to `Card` (no intermediate Column) so it receives
    // the Card's real, possibly-bounded height constraint directly — a
    // Flex like Column always hands its single non-flex child an *unbounded*
    // main-axis constraint, which is exactly what let a 6-week month
    // silently grow taller than the fixed desktop card height and overflow.
    // `MiniMonthCalendar` itself now adapts to whatever height it's given,
    // the same way `AppointmentsColumn`/`PendingTasksPanel` do.
    return Card(
      padding: const EdgeInsets.all(16),
      child: MiniMonthCalendar(
        selectedDate: selectedDate,
        onDateSelected: onDateSelected,
        datesWithAppointments: datesWithAppointments,
      ),
    );
  }
}
