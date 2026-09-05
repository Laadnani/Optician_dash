import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/month_filter_bar.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/helpers/stat_card.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/data/billing_repository.dart';
import 'package:optic/localization/app_strings.dart';

/// Billing screen — occupies the sidebar slot that used to be the
/// unimplemented "Appointments" placeholder (actual appointments already
/// live under "Calendar", so nothing was lost repurposing it).
///
/// Reads straight off `Appointment.price`/`paymentStatus`/`type` now,
/// rather than the separate (and unlinked) `Invoice` list: two KPI cards —
/// this month's total paid revenue, and how it compares to last month —
/// plus a weekly stacked-bar chart splitting revenue into first-time
/// 'appointment' visits vs. 'reschedule' follow-ups.
class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final repository = ProviderBillingRepository(dataProvider);

    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.billing),
      bodyBuilder: (context, breakpoint) =>
          _BillingBody(breakpoint: breakpoint, repository: repository),
    );
  }
}

class _BillingBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final BillingRepository repository;

  const _BillingBody({required this.breakpoint, required this.repository});

  @override
  State<_BillingBody> createState() => _BillingBodyState();
}

class _BillingBodyState extends State<_BillingBody> with MonthFilterState<_BillingBody> {
  List<WeeklyAppointmentRevenue> _weeks = const [];
  MonthlyRevenueComparison _comparison = const MonthlyRevenueComparison(
    thisMonthTotal: 0,
    lastMonthTotal: 0,
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant _BillingBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _loadData();
    }
  }

  @override
  void goPreviousMonth() {
    super.goPreviousMonth();
    _loadData();
  }

  @override
  void goNextMonth() {
    super.goNextMonth();
    _loadData();
  }

  @override
  void goCurrentMonth() {
    super.goCurrentMonth();
    _loadData();
  }

  Future<void> _loadData() async {
    final weeks = await widget.repository.fetchWeeksForMonth(selectedMonth);
    final comparison = await widget.repository.fetchMonthlyRevenueComparison(
      referenceMonth: selectedMonth,
    );
    if (!mounted) return;
    setState(() {
      _weeks = weeks;
      _comparison = comparison;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: material.CircularProgressIndicator());
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = _comparison.delta >= 0;
    final compareColor = _comparison.delta == 0
        ? colorScheme.mutedForeground
        : (isPositive ? Colors.green.shade700 : colorScheme.destructive);

    final int crossAxisCount;
    switch (widget.breakpoint) {
      case Breakpoint.desktop:
        crossAxisCount = 2;
        break;
      case Breakpoint.tablet:
        crossAxisCount = 2;
        break;
      case Breakpoint.mobile:
        crossAxisCount = 1;
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.billingScreenTitle).large().bold(),
          const SizedBox(height: 12),
          buildMonthFilterBar(),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3,
            children: [
              DashboardStatCard(
                label: AppStrings.billingKpiTotalThisMonth,
                value: '${_comparison.thisMonthTotal.toStringAsFixed(0)} MAD',
                icon: Icons.payments_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.billingKpiVsLastMonth,
                value: _vsLastMonthLabel(),
                icon: isPositive
                    ? Icons.trending_up
                    : (_comparison.delta == 0
                          ? Icons.trending_flat
                          : Icons.trending_down),
                accent: compareColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.billingWeeklyChartTitle).semiBold(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 280,
                  child: _weeks.isEmpty
                      ? const SizedBox.shrink()
                      : _WeeklyRevenueBarChart(
                          weeks: _weeks,
                          colorScheme: colorScheme,
                        ),
                ),
                const SizedBox(height: 16),
                _legend(colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "+180 MAD" style — falls back to the raw MAD delta (rather than a
  /// percentage) when last month had zero revenue, since a percent change
  /// off a zero base isn't meaningful.
  String _vsLastMonthLabel() {
    final percent = _comparison.percentChange;
    final sign = _comparison.delta > 0
        ? '+'
        : (_comparison.delta < 0 ? '' : '');
    if (percent != null) {
      return '$sign${(percent * 100).toStringAsFixed(0)}%';
    }
    return '$sign${_comparison.delta.toStringAsFixed(0)} MAD';
  }

  Widget _legend(ColorScheme colorScheme) {
    Widget dot(String label, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label).muted().small(),
      ],
    );

    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        dot(AppStrings.appointmentTypeNew, colorScheme.primary),
        dot(AppStrings.appointmentTypeReschedule, colorScheme.chart2),
      ],
    );
  }
}

/// The actual `fl_chart` stacked bar — one bar per week, split into
/// 'appointment' vs 'reschedule' revenue. Pulled into its own widget just
/// to keep `_BillingBodyState.build` from getting any longer.
class _WeeklyRevenueBarChart extends StatelessWidget {
  final List<WeeklyAppointmentRevenue> weeks;
  final ColorScheme colorScheme;

  const _WeeklyRevenueBarChart({required this.weeks, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final appointmentColor = colorScheme.primary;
    final rescheduleColor = colorScheme.chart2;

    final maxTotal = weeks
        .map((w) => w.totalAmount)
        .fold<double>(0, (a, b) => a > b ? a : b);
    // A little headroom above the tallest bar so it doesn't touch the top
    // of the chart area; falls back to 1 when every week is empty so
    // `maxY` is never 0 (fl_chart treats that as "no chart" territory).
    final maxY = maxTotal <= 0 ? 1.0 : maxTotal * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.mutedForeground,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= weeks.length) return const SizedBox.shrink();
                final weekStart = weeks[i].weekStart;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${weekStart.day} ${AppStrings.monthAbbreviation(weekStart.month)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.mutedForeground,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < weeks.length; i++)
            _groupFor(i, weeks[i], appointmentColor, rescheduleColor),
        ],
      ),
    );
  }

  BarChartGroupData _groupFor(
    int index,
    WeeklyAppointmentRevenue week,
    Color appointmentColor,
    Color rescheduleColor,
  ) {
    final appointment = week.appointmentAmount;
    final reschedule = week.rescheduleAmount;
    final total = appointment + reschedule;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: total,
          width: 20,
          borderRadius: BorderRadius.circular(4),
          rodStackItems: [
            BarChartRodStackItem(0, appointment, appointmentColor),
            BarChartRodStackItem(appointment, total, rescheduleColor),
          ],
        ),
      ],
    );
  }
}
