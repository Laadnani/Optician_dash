import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/dashboard_appointment.dart';
import '../localization/app_strings.dart';
import 'status_chip.dart';

class AppointmentTile extends StatelessWidget {
  final DashboardAppointment appointment;
  final VoidCallback? onStart;
  final VoidCallback? onOpenChart;

  const AppointmentTile({
    super.key,
    required this.appointment,
    this.onStart,
    this.onOpenChart,
  });

  // Below this width there isn't room for time + divider + avatar + name
  // + status chip + action button all in one Row — the trailing
  // status/action group drops to its own line instead of forcing an
  // overflow.
  static const double _compactBreakpoint = 420;

  // `AppointmentStatus` is the enum; `statusChipStyle` (shared with every
  // other status-bearing card — lab/imaging orders, invoices) works off the
  // raw string values those models actually store, so this is the one spot
  // that bridges enum -> string before handing off to it.
  String get _rawStatus {
    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        return 'scheduled';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusLabel, statusColor) = statusChipStyle(
      _rawStatus,
      theme.colorScheme,
    );
    final timeFmt = TimeOfDay.fromDateTime(appointment.start);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < _compactBreakpoint;

            final timeBlock = SizedBox(
              width: 56,
              child: Text(
                '${timeFmt.hour}:${timeFmt.minute.toString().padLeft(2, '0')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ).semiBold(),
            );

            final clientBlock = Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).semiBold(),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notes_outlined,
                        size: 14,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          appointment.reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).muted(),
                      ),
                    ],
                  ),
                ],
              ),
            );

            final actionButton = appointment.status == AppointmentStatus.scheduled
                ? Button.outline(
                    onPressed: onStart,
                    leading: const Icon(Icons.play_arrow_outlined, size: 12),
                    child: Text(
                      AppStrings.actionStart,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Button.outline(
                    onPressed: onOpenChart,
                    child: Text(
                      AppStrings.actionChart,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );

            final statusAndAction = isCompact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusChip(label: statusLabel, color: statusColor),
                      const SizedBox(height: 6),
                      actionButton,
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip(label: statusLabel, color: statusColor),
                      const SizedBox(width: 8),
                      actionButton,
                    ],
                  );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                timeBlock,
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Avatar(
                  initials: appointment.clientName.isNotEmpty
                      ? appointment.clientName.substring(0, 1).toUpperCase()
                      : '?',
                ),
                const SizedBox(width: 12),
                clientBlock,
                const SizedBox(width: 8),
                statusAndAction,
              ],
            );
          },
        ),
      ),
    );
  }
}
