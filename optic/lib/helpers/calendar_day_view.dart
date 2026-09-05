import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/dashboard_appointment.dart';
import 'calendar_date_utils.dart';
import 'appointment_tile.dart';
import '../localization/app_strings.dart';

class CalendarDayView extends StatelessWidget {
  final DateTime selectedDate;
  final List<DashboardAppointment> appointments;

  const CalendarDayView({
    super.key,
    required this.selectedDate,
    required this.appointments,
  });

  @override
  Widget build(BuildContext context) {
    final todays =
        appointments.where((a) => isSameDay(a.start, selectedDate)).toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    if (todays.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(AppStrings.calendarNothingScheduled).muted(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final appointment in todays)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppointmentTile(appointment: appointment),
          ),
      ],
    );
  }
}
