import 'package:optic/helpers/appointment_tile.dart';
import 'package:optic/models/dashboard_appointment.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/localization/app_strings.dart';

class AppointmentsColumn extends StatelessWidget {
  final DateTime selectedDate;
  final bool isToday;
  final List<DashboardAppointment> appointments;

  const AppointmentsColumn({
    super.key, 
    required this.selectedDate,
    required this.isToday,
    required this.appointments,
  });

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 28,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(height: 8),
          Text(AppStrings.dashboardNoAppointmentsToday).muted(),
        ],
      ),
    );
  }

  List<Widget> _tiles() => appointments
      .map(
        (a) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppointmentTile(
            appointment: a,
            onStart: () {},
            onOpenChart: () {},
          ),
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = _formatDate(selectedDate);

    final header = Row(
      children: [
        Flexible(
          child: Text(
            isToday
                ? AppStrings.dashboardScheduleTodayTitle
                : AppStrings.dashboardScheduleTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ).semiBold(),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '· $dateLabel',
            maxLines: 1,
            overflow: TextOverflow.fade,
          ).muted(),
        ),
      ],
    );

    // One Card matching the calendar/pending-tasks cards' framing (this
    // used to be the only card-less column of the three, which is part of
    // why the row read as uneven heights) — and, via LayoutBuilder, one
    // widget that adapts to however its parent constrains it:
    //  - Desktop: `DashboardMainSection` stretches all three cards to a
    //    shared fixed height, so `constraints.maxHeight` here is finite —
    //    the tile list scrolls internally (ListView) inside the remaining
    //    space instead of overflowing or forcing the row taller.
    //  - Mobile/tablet: cards stack in an unbounded-height Column, so
    //    `maxHeight` is infinite — falls back to the old plain-Column
    //    behavior (grows with content; the page's own scroll view handles
    //    overflow, same as before).
    return Card(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.maxHeight.isFinite;
          final body = appointments.isEmpty
              ? _emptyState(theme)
              : (bounded
                    ? ListView(padding: EdgeInsets.zero, children: _tiles())
                    : Column(children: _tiles()));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              header,
              const SizedBox(height: 12),
              bounded ? Expanded(child: body) : body,
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}
