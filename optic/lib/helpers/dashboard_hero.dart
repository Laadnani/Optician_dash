import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';

import 'package:optic/controllers/tenant_session.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/responsive.dart';
import 'calendar_date_utils.dart';
import 'stat_card.dart';

/// "Good morning, [Name] / [Day, Date]" — the operational-center greeting
/// from the redesign brief, replacing the old static `Header` (title +
/// search field — search now lives in the global `AppTopBar` instead, so
/// this widget is just the greeting).
///
/// Falls back to a name-less greeting when there's no signed-in user email
/// yet (shouldn't happen post-auth-gate, but cheap to guard) rather than
/// fabricating a name.
class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({super.key});

  String _greetingForHour(int hour) {
    if (hour < 12) return AppStrings.topBarGreetingMorning;
    if (hour < 18) return AppStrings.topBarGreetingAfternoon;
    return AppStrings.topBarGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingForHour(now.hour);
    final doctorName = context.watch<TenantSession>().user?.email ?? '';
    final title = doctorName.isNotEmpty ? '$greeting, $doctorName' : greeting;
    final dateLine = '${formatFullDate(now)}, ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ).large().bold(),
        const SizedBox(height: 4),
        Text(dateLine).muted(),
      ],
    );
  }
}

/// The fixed 4-tile "Clients / Orders / Revenue / Pending" hero row —
/// always visible at the top of the dashboard (unlike the rest of the
/// widgets below it, which are switched on/off via Settings → Dashboard),
/// matching the designer brief's "operational center" headline numbers.
class DashboardHeroRow extends StatelessWidget {
  final int clients;
  final int orders;
  final double revenueThisMonth;
  final int pending;

  const DashboardHeroRow({
    super.key,
    required this.clients,
    required this.orders,
    required this.revenueThisMonth,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final crossAxisCount = Responsive.isMobile(context) ? 2 : 4;
    final aspectRatio = Responsive.isMobile(context) ? 1.7 : 2.6;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: aspectRatio,
      children: [
        DashboardStatCard(
          label: AppStrings.dashHeroClients,
          value: '$clients',
          icon: Icons.people_outline,
          accent: colorScheme.primary,
        ),
        DashboardStatCard(
          label: AppStrings.dashHeroOrders,
          value: '$orders',
          icon: Icons.shopping_cart_outlined,
          accent: colorScheme.chart2,
        ),
        DashboardStatCard(
          label: AppStrings.dashHeroRevenue,
          value: '${revenueThisMonth.toStringAsFixed(0)} MAD',
          icon: Icons.payments_outlined,
          accent: Colors.green.shade700,
        ),
        DashboardStatCard(
          label: AppStrings.dashHeroPending,
          value: '$pending',
          icon: Icons.pending_actions_outlined,
          accent: Colors.orange.shade700,
        ),
      ],
    );
  }
}
