import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'stat_card.dart';
import '../localization/app_strings.dart';
import '../helpers/breakpoint.dart';

/// The 4-tile KPI row ("Today's appointments" / "Completed" / "Scheduled" /
/// "Cancelled" — matching the 3 real Appointment.status values, plus the
/// day's total). Isolated so it — and the [DashboardStatCard] tiles inside
/// it — can be tweaked without touching the rest of the dashboard.
class DashboardKpiRow extends StatelessWidget {
  final Breakpoint breakpoint;
  final int todaysCount;
  final int completed;
  final int scheduled;
  final int cancelled;

  const DashboardKpiRow({
    super.key,
    required this.breakpoint,
    required this.todaysCount,
    required this.completed,
    required this.scheduled,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    // 4 columns only fits comfortably on desktop. A square (1:1) aspect
    // ratio on top of that is what squeezed cells down to a few pixels
    // wide on a phone (crossAxisCount: 4 unconditionally, previously) —
    // fewer columns and a wider (non-square) aspect ratio give each card
    // real room on mobile/tablet instead of relying on DashboardStatCard's
    // FittedBox to paper over an impossibly tiny cell.
    final int crossAxisCount;
    final double childAspectRatio;
    switch (breakpoint) {
      case Breakpoint.desktop:
        crossAxisCount = 4;
        childAspectRatio = 3;
        break;
      case Breakpoint.tablet:
        crossAxisCount = 2;
        childAspectRatio = 2.2;
        break;
      case Breakpoint.mobile:
        crossAxisCount = 2;
        childAspectRatio = 1.6;
        break;
    }

    // Reads the *active* color scheme (family + dark/light) instead of a
    // hardcoded `lightDefaultColor`, so these accent colors follow the
    // "one strong primary accent" theme setting like everything else does.
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: childAspectRatio,
      children: [
        DashboardStatCard(
          label: AppStrings.kpiTodaysAppointments,
          value: '$todaysCount',
          icon: Icons.calendar_today_outlined,
          accent: colorScheme.chart2,
        ),
        DashboardStatCard(
          label: AppStrings.kpiCompleted,
          value: '$completed',
          icon: Icons.check_circle_outline,
          accent: Colors.green.shade700,
        ),
        DashboardStatCard(
          label: AppStrings.kpiScheduled,
          value: '$scheduled',
          icon: Icons.schedule_outlined,
          accent: Colors.orange.shade700,
        ),
        DashboardStatCard(
          label: AppStrings.kpiCancelled,
          value: '$cancelled',
          icon: Icons.cancel_outlined,
          accent: colorScheme.chart3,
        ),
      ],
    );
  }
}
