import 'package:flutter/material.dart' as material;
import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/constants.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/data/billing_repository.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/dashboard_appointment.dart';
import 'package:optic/models/dashboard_date_range.dart';
import 'package:optic/models/pending_task.dart';
import 'dashboard_sections.dart';

/// The redesigned (Aug 2026 "minimalist operational center") dashboard's
/// widget catalog — a compact KPI tile, the always-on 4-tile summary row,
/// the expandable Attention section, and the six panels that make up the
/// three asymmetric pairs below it (Tasks/Appointments, Sales/Activity,
/// Inventory/QuickActions), plus the global date-range control.
///
/// Deliberately does NOT reuse `DashboardStatCard` (`stat_card.dart`) —
/// that widget is shared by 26+ other module screens' own KPI strips with
/// its own established look, so restyling it here would silently reskin
/// every one of those screens too. [DashboardKpiTile] below is a new,
/// dashboard-only widget instead.

// ---------------------------------------------------------------------------
// KPI tile + sparkline
// ---------------------------------------------------------------------------

/// A compact KPI tile per the redesign brief: label+icon header row, a
/// 28px/w600 value, an optional 12px comparison line, and — only where the
/// caller opts in (just the Clients tile) — a tiny trend sparkline. No
/// tinted background; [accent] is used sparingly, only on the icon and the
/// comparison line's color when it's semantically positive/negative.
class DashboardKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? comparison;

  /// null = neutral/informational comparison color; true/false tints the
  /// comparison line green/red per the brief's "green = success, red =
  /// urgent" semantic-color rule.
  final bool? comparisonPositive;
  final List<double>? sparkline;
  final VoidCallback? onTap;

  const DashboardKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.comparison,
    this.comparisonPositive,
    this.sparkline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final comparisonColor = comparisonPositive == null
        ? colorScheme.mutedForeground
        : (comparisonPositive! ? Colors.green.shade700 : colorScheme.destructive);

    return DashboardPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: accent),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          if (comparison != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (comparisonPositive != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(
                      comparisonPositive! ? Icons.trending_up : Icons.trending_down,
                      size: 13,
                      color: comparisonColor,
                    ),
                  ),
                Flexible(
                  child: Text(
                    comparison!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: comparisonColor),
                  ),
                ),
              ],
            ),
          ],
          if (sparkline != null && sparkline!.length >= 2) ...[
            const SizedBox(height: 10),
            SizedBox(height: 26, child: _MiniSparkline(values: sparkline!, color: accent)),
          ],
        ],
      ),
    );
  }
}

/// A tiny trend line, no axes/grid/dots-by-default — used only by the
/// Clients KPI tile per the brief's "don't put a sparkline on every card"
/// guidance.
class _MiniSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;

  const _MiniSparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final spots = [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])];
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.2 + 0.5;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Always-on 4-tile KPI summary row
// ---------------------------------------------------------------------------

/// The always-visible "Clients / Appointments / Sales / Orders" row —
/// replaces the old `DashboardHeroRow` + `DashboardKpiRow`. All four tiles
/// respond to the same [range] (the global date-range filter), per the
/// brief's point 13.
class DashboardKpiSummaryRow extends StatelessWidget {
  final Breakpoint breakpoint;
  final DataProvider dataProvider;
  final DashboardDateRange range;
  final VoidCallback? onClientsTap;
  final VoidCallback? onAppointmentsTap;
  final VoidCallback? onSalesTap;
  final VoidCallback? onOrdersTap;

  const DashboardKpiSummaryRow({
    super.key,
    required this.breakpoint,
    required this.dataProvider,
    required this.range,
    this.onClientsTap,
    this.onAppointmentsTap,
    this.onSalesTap,
    this.onOrdersTap,
  });

  List<double> _weeklyNewClientCounts(Iterable<DateTime> firstVisits, {int weeks = 8}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final buckets = List<double>.filled(weeks, 0);

    for (final d in firstVisits) {
      final day = DateTime(d.year, d.month, d.day);
      final weekStart = day.subtract(Duration(days: day.weekday - 1));
      final diffWeeks = currentWeekStart.difference(weekStart).inDays ~/ 7;
      final idx = weeks - 1 - diffWeeks;
      if (idx >= 0 && idx < weeks) buckets[idx]++;
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final firstApptByClient = <String, DateTime>{};
    for (final a in dataProvider.appointments) {
      final existing = firstApptByClient[a.clientId];
      if (existing == null || a.date.isBefore(existing)) {
        firstApptByClient[a.clientId] = a.date;
      }
    }
    final newInRange = firstApptByClient.values.where(range.contains).length;
    final sparkline = _weeklyNewClientCounts(firstApptByClient.values, weeks: 8);

    final inRange = dataProvider.appointments.where((a) => range.contains(a.date)).length;
    final today = dataProvider.appointments
        .where((a) => DashboardAppointment.isSameDay(a.date, DateTime.now()))
        .length;

    final revenue = deriveRevenueForRange(
      dataProvider.appointments,
      start: range.start,
      end: range.end,
    );
    final salesUp = revenue.delta >= 0;
    final salesComparison = revenue.percentChange != null
        ? '${salesUp ? '↑' : '↓'} ${(revenue.percentChange!.abs() * 100).toStringAsFixed(0)}% ${AppStrings.dashSalesVsPrevious}'
        : AppStrings.dashRevenueNoComparison;

    final orders = dataProvider.orders;
    final pendingOrders = orders.where((o) => o.status == 'pending').length;

    final tiles = <Widget>[
      DashboardKpiTile(
        label: AppStrings.dashKpiClients,
        value: '${dataProvider.clients.length}',
        icon: Icons.people_outline,
        accent: colorScheme.primary,
        comparison: AppStrings.dashKpiClientsSub.replaceAll('{n}', '$newInRange'),
        sparkline: sparkline.length >= 2 ? sparkline : null,
        onTap: onClientsTap,
      ),
      DashboardKpiTile(
        label: AppStrings.dashKpiAppointments,
        value: '$inRange',
        icon: Icons.event_outlined,
        accent: colorScheme.chart2,
        comparison: AppStrings.dashKpiAppointmentsSub.replaceAll('{n}', '$today'),
        onTap: onAppointmentsTap,
      ),
      DashboardKpiTile(
        label: AppStrings.dashKpiSales,
        value: '${revenue.currentTotal.toStringAsFixed(0)} MAD',
        icon: Icons.payments_outlined,
        accent: Colors.green.shade700,
        comparison: salesComparison,
        comparisonPositive: revenue.percentChange != null ? salesUp : null,
        onTap: onSalesTap,
      ),
      DashboardKpiTile(
        label: AppStrings.dashKpiOrders,
        value: '${orders.length}',
        icon: Icons.shopping_cart_outlined,
        accent: Colors.orange.shade700,
        comparison: AppStrings.dashKpiOrdersSub.replaceAll('{n}', '$pendingOrders'),
        onTap: onOrdersTap,
      ),
    ];

    // Rows of tiles sized by their own content (via `IntrinsicHeight`)
    // rather than a fixed `GridView` aspect ratio — a KPI tile's natural
    // height varies (the Clients tile carries a sparkline the others
    // don't, and text/icon scaling settings can grow the content further),
    // so locking every cell to one aspect ratio is what caused the bottom
    // overflow on narrow/mobile layouts. Desktop shows all 4 in one row;
    // tablet and mobile both wrap to a 2-per-row grid per the brief's
    // point 19 (tablet: 2x2, mobile: stacked in pairs).
    final perRow = breakpoint == Breakpoint.desktop ? 4 : 2;
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += perRow) {
      final rowTiles = tiles.sublist(i, (i + perRow > tiles.length) ? tiles.length : i + perRow);
      if (rows.isNotEmpty) rows.add(const SizedBox(height: DashboardTokens.itemGap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < rowTiles.length; j++) ...[
                if (j > 0) const SizedBox(width: DashboardTokens.itemGap),
                Expanded(child: rowTiles[j]),
              ],
            ],
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

// ---------------------------------------------------------------------------
// Global date-range control ("Today ▾")
// ---------------------------------------------------------------------------

/// The top-right global filter from the brief's point 13 — one selection
/// drives the KPI row, Sales Overview, and (indirectly, via [range]'s
/// `.contains`) the Attention section's "unconfirmed today" count.
class DashboardDateRangeControl extends StatelessWidget {
  final DashboardDateRangeKind selected;
  final ValueChanged<DashboardDateRangeKind> onChanged;

  const DashboardDateRangeControl({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DashboardTokens.smallRadius),
        border: Border.all(color: colorScheme.border, width: DashboardTokens.borderWidth),
      ),
      child: material.DropdownButtonHideUnderline(
        child: material.DropdownButton<DashboardDateRangeKind>(
          value: selected,
          isDense: true,
          icon: Icon(Icons.expand_more, size: 16, color: colorScheme.mutedForeground),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: colorScheme.foreground,
          ),
          items: [
            for (final kind in DashboardDateRangeKind.values)
              material.DropdownMenuItem(value: kind, child: Text(kind.label)),
          ],
          onChanged: (kind) {
            if (kind != null) onChanged(kind);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attention section (expandable)
// ---------------------------------------------------------------------------

/// "⚠ N items need your attention" — collapsed by default, expands into
/// one row per non-zero category (brief point 16). [n] in the header is the
/// sum of every category's count (matching the brief's own example: 2+3+1+1
/// = 7), not the number of categories.
class AttentionSection extends StatefulWidget {
  final DataProvider dataProvider;
  final VoidCallback? onOrdersTap;
  final VoidCallback? onLowStockTap;
  final VoidCallback? onOverdueTap;
  final VoidCallback? onUnconfirmedTap;

  const AttentionSection({
    super.key,
    required this.dataProvider,
    this.onOrdersTap,
    this.onLowStockTap,
    this.onOverdueTap,
    this.onUnconfirmedTap,
  });

  @override
  State<AttentionSection> createState() => _AttentionSectionState();
}

class _AttentionSectionState extends State<AttentionSection> {
  bool _expanded = false;

  static const int _frameLowStock = 3;
  static const int _overdueInvoiceDays = 14;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dp = widget.dataProvider;
    final now = DateTime.now();

    final ordersReady = dp.orders.where((o) => o.status == 'ready').length;
    final lowStockFrames = dp.frames
        .where((f) => f.stockAvailable > 0 && f.stockAvailable <= _frameLowStock)
        .length;
    final overdueInvoices = dp.invoices
        .where((i) => i.status == 'pending' && now.difference(i.date).inDays > _overdueInvoiceDays)
        .length;
    final unconfirmed = dp.appointments
        .where((a) => DashboardAppointment.isSameDay(a.date, now) && a.status == 'scheduled')
        .length;

    final items = <(String, VoidCallback?)>[
      if (ordersReady > 0)
        (AppStrings.dashAttentionOrdersReady.replaceAll('{n}', '$ordersReady'), widget.onOrdersTap),
      if (lowStockFrames > 0)
        (AppStrings.dashAttentionLowStock.replaceAll('{n}', '$lowStockFrames'), widget.onLowStockTap),
      if (overdueInvoices > 0)
        (AppStrings.dashAttentionOverduePayments.replaceAll('{n}', '$overdueInvoices'), widget.onOverdueTap),
      if (unconfirmed > 0)
        (
          AppStrings.dashAttentionUnconfirmedAppointments.replaceAll('{n}', '$unconfirmed'),
          widget.onUnconfirmedTap,
        ),
    ];

    final total = ordersReady + lowStockFrames + overdueInvoices + unconfirmed;

    if (total == 0) {
      return DashboardPanel(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade700),
            const SizedBox(width: 10),
            Expanded(child: Text(AppStrings.dashAttentionEmpty).muted()),
          ],
        ),
      );
    }

    return DashboardPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          material.InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: Colors.orange.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.dashAttentionTitle.replaceAll('{n}', '$total'),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: colorScheme.mutedForeground,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            for (final (label, onTap) in items) _attentionRow(label, onTap, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _attentionRow(String label, VoidCallback? onTap, ColorScheme colorScheme) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: Colors.orange.shade700, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label).small()),
          if (onTap != null) Icon(Icons.chevron_right, size: 16, color: colorScheme.mutedForeground),
        ],
      ),
    );
    if (onTap == null) return row;
    return material.InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashboardTokens.smallRadius),
      child: row,
    );
  }
}

// ---------------------------------------------------------------------------
// Today's Tasks panel (list + status dots)
// ---------------------------------------------------------------------------

/// Restyled per brief points 8-9: a list-style panel with tiny dots instead
/// of `PendingTasksPanel`'s old per-kind icon. Every task this app currently
/// derives (`derivePendingTasks`) is a "needs attention" item, so the dot is
/// a flat orange — not a per-row judgment call this data doesn't support yet.
class DashboardTasksPanel extends StatelessWidget {
  final List<PendingTask> items;
  final VoidCallback? onSeeAll;
  final void Function(PendingTask item)? onTapItem;

  const DashboardTasksPanel({
    super.key,
    required this.items,
    this.onSeeAll,
    this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardPanelHeader(
            title: AppStrings.dashPanelTasksTitle,
            actionLabel: onSeeAll != null ? AppStrings.dashViewAll : null,
            onAction: onSeeAll,
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(AppStrings.pendingTasksEmpty).muted(),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colorScheme.border),
              _row(items[i], colorScheme),
            ],
        ],
      ),
    );
  }

  Widget _row(PendingTask item, ColorScheme colorScheme) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: Colors.orange.shade700, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis).small(),
                Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis).muted(),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTapItem == null) return row;
    return material.InkWell(onTap: () => onTapItem!(item), child: row);
  }
}

// ---------------------------------------------------------------------------
// Upcoming Appointments panel (ultra-compact single-line rows)
// ---------------------------------------------------------------------------

/// Brief point 10 — `10:30  Ahmed El Amrani · Eye examination      ✓`
/// instead of a full appointment card. Bypasses `AppointmentTile`/
/// `AppointmentsColumn` entirely (those still exist, just unused by the
/// dashboard now) since this row shape is dashboard-specific.
class DashboardAppointmentsPanel extends StatelessWidget {
  final List<DashboardAppointment> appointments;
  final VoidCallback? onSeeAll;
  final void Function(DashboardAppointment appt)? onTapItem;

  const DashboardAppointmentsPanel({
    super.key,
    required this.appointments,
    this.onSeeAll,
    this.onTapItem,
  });

  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sorted = [...appointments]..sort((a, b) => a.start.compareTo(b.start));

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardPanelHeader(
            title: AppStrings.dashPanelAppointmentsTitle,
            actionLabel: onSeeAll != null ? AppStrings.dashViewAll : null,
            onAction: onSeeAll,
          ),
          const SizedBox(height: 8),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(AppStrings.dashAppointmentsEmptyUpcoming).muted(),
            )
          else
            for (var i = 0; i < sorted.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colorScheme.border),
              _row(sorted[i], colorScheme),
            ],
        ],
      ),
    );
  }

  Widget _row(DashboardAppointment appt, ColorScheme colorScheme) {
    Color dotColor;
    IconData? trailingIcon;
    switch (appt.status) {
      case AppointmentStatus.completed:
        dotColor = Colors.green.shade700;
        trailingIcon = Icons.check;
        break;
      case AppointmentStatus.cancelled:
        dotColor = colorScheme.destructive;
        trailingIcon = Icons.close;
        break;
      case AppointmentStatus.scheduled:
        dotColor = colorScheme.chart2;
        trailingIcon = null;
        break;
    }

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              _time(appt.start),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12.5, color: colorScheme.foreground),
                children: [
                  TextSpan(
                    text: appt.clientName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: '  ·  ${appt.reason}',
                    style: TextStyle(color: colorScheme.mutedForeground),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (trailingIcon != null)
            Icon(trailingIcon, size: 14, color: dotColor)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
        ],
      ),
    );
    if (onTapItem == null) return row;
    return material.InkWell(onTap: () => onTapItem!(appt), child: row);
  }
}

// ---------------------------------------------------------------------------
// Sales Overview panel (thin line chart)
// ---------------------------------------------------------------------------

/// Brief points 11-12 — headline number + trend is the important part, the
/// chart itself stays thin/subtle (60% width slot via `DashboardPanelPair`).
/// The headline responds to the global [range]; the trend line always shows
/// the trailing 8 weeks regardless of [range], for stable trend context.
class DashboardSalesOverviewPanel extends StatelessWidget {
  final DataProvider dataProvider;
  final DashboardDateRange range;
  final VoidCallback? onSeeAll;

  const DashboardSalesOverviewPanel({
    super.key,
    required this.dataProvider,
    required this.range,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekly = deriveWeeklyAppointmentRevenue(dataProvider.appointments, weeksBack: 8);
    final comparison = deriveRevenueForRange(
      dataProvider.appointments,
      start: range.start,
      end: range.end,
    );
    final isUp = comparison.delta >= 0;

    final spots = [for (var i = 0; i < weekly.length; i++) FlSpot(i.toDouble(), weekly[i].totalAmount)];
    final values = weekly.map((w) => w.totalAmount).toList();
    final maxTotal = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = maxTotal <= 0 ? 1.0 : maxTotal * 1.25;

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardPanelHeader(
            title: AppStrings.dashPanelSalesTitle,
            actionLabel: onSeeAll != null ? AppStrings.dashViewAll : null,
            onAction: onSeeAll,
          ),
          const SizedBox(height: 14),
          Text(
            '${comparison.currentTotal.toStringAsFixed(0)} MAD',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (comparison.percentChange != null)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(
                    isUp ? Icons.trending_up : Icons.trending_down,
                    size: 13,
                    color: isUp ? Colors.green.shade700 : colorScheme.destructive,
                  ),
                ),
              Text(
                comparison.percentChange != null
                    ? '${(comparison.percentChange!.abs() * 100).toStringAsFixed(0)}% ${AppStrings.dashSalesVsPrevious}'
                    : AppStrings.dashRevenueNoComparison,
                style: TextStyle(
                  fontSize: 12,
                  color: comparison.percentChange == null
                      ? colorScheme.mutedForeground
                      : (isUp ? Colors.green.shade700 : colorScheme.destructive),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 2,
                  getDrawingHorizontalLine: (_) => FlLine(color: colorScheme.border, strokeWidth: 1),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 1.75,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(radius: 2, color: colorScheme.primary, strokeWidth: 0),
                    ),
                    belowBarData: BarAreaData(show: true, color: colorScheme.primary.withOpacity(0.06)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Activity panel
// ---------------------------------------------------------------------------

class _ActivityEvent {
  final String text;
  final DateTime date;
  final Color color;

  const _ActivityEvent(this.text, this.date, this.color);
}

/// A merged, most-recent-first feed built from Orders, paid Invoices,
/// Prescriptions, and a "new client" proxy (a client's earliest
/// appointment on file — `Client` itself has no `createdAt` field to read
/// instead). Paired with [DashboardSalesOverviewPanel] at 40% width.
class DashboardRecentActivityPanel extends StatelessWidget {
  final DataProvider dataProvider;
  final VoidCallback? onSeeAll;

  const DashboardRecentActivityPanel({
    super.key,
    required this.dataProvider,
    this.onSeeAll,
  });

  static const int _maxRows = 6;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final clientsById = {for (final p in dataProvider.clients) p.id: p};
    String nameFor(String id) {
      final p = clientsById[id];
      return p != null ? '${p.firstName} ${p.lastName}' : '';
    }

    final events = <_ActivityEvent>[];

    for (final o in dataProvider.orders) {
      events.add(
        _ActivityEvent(
          AppStrings.dashActivityOrderPlaced.replaceAll('{id}', o.id),
          o.date,
          colorScheme.chart2,
        ),
      );
    }
    for (final inv in dataProvider.invoices.where((i) => i.status == 'paid')) {
      events.add(
        _ActivityEvent(
          AppStrings.dashActivityPaymentReceived
              .replaceAll('{amount}', '${inv.amount.toStringAsFixed(0)} MAD'),
          inv.date,
          Colors.green.shade700,
        ),
      );
    }
    for (final p in dataProvider.prescriptions) {
      events.add(
        _ActivityEvent(
          AppStrings.dashActivityPrescriptionUpdated.replaceAll('{name}', nameFor(p.clientId)),
          p.date,
          colorScheme.primary,
        ),
      );
    }
    final firstApptByClient = <String, DateTime>{};
    for (final a in dataProvider.appointments) {
      final existing = firstApptByClient[a.clientId];
      if (existing == null || a.date.isBefore(existing)) {
        firstApptByClient[a.clientId] = a.date;
      }
    }
    firstApptByClient.forEach((clientId, date) {
      events.add(
        _ActivityEvent(
          AppStrings.dashActivityNewClient.replaceAll('{name}', nameFor(clientId)),
          date,
          Colors.orange.shade700,
        ),
      );
    });

    events.sort((a, b) => b.date.compareTo(a.date));
    final recent = events.take(_maxRows).toList();

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardPanelHeader(
            title: AppStrings.dashPanelActivityTitle,
            actionLabel: onSeeAll != null ? AppStrings.dashViewAll : null,
            onAction: onSeeAll,
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(AppStrings.dashActivityEmpty).muted(),
            )
          else
            for (final e in recent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: e.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.text, maxLines: 2, overflow: TextOverflow.ellipsis).small(),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inventory Attention panel
// ---------------------------------------------------------------------------

/// Reuses the same critical/low-stock thresholds the old `InventoryAlertsCard`
/// used, restyled as red/orange dot rows instead of two separate `DashboardStatCard`
/// tiles. Paired with [DashboardQuickActionsPanel] at 60% width.
class DashboardInventoryAttentionPanel extends StatelessWidget {
  final DataProvider dataProvider;
  final VoidCallback? onSeeAll;

  const DashboardInventoryAttentionPanel({
    super.key,
    required this.dataProvider,
    this.onSeeAll,
  });

  static const int _frameLowStock = 3;
  static const int _otherLowStock = 5;

  @override
  Widget build(BuildContext context) {
    final critical = dataProvider.frames.where((f) => f.stockAvailable == 0).length +
        dataProvider.contactLensProducts.where((p) => p.stock == 0).length +
        dataProvider.accessories.where((a) => a.stock == 0).length;

    final low = dataProvider.frames
            .where((f) => f.stockAvailable > 0 && f.stockAvailable <= _frameLowStock)
            .length +
        dataProvider.contactLensProducts
            .where((p) => p.stock > 0 && p.stock <= _otherLowStock)
            .length +
        dataProvider.accessories
            .where((a) => a.stock > 0 && a.stock <= _otherLowStock)
            .length;

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardPanelHeader(
            title: AppStrings.dashPanelInventoryTitle,
            actionLabel: onSeeAll != null ? AppStrings.dashViewAll : null,
            onAction: onSeeAll,
          ),
          const SizedBox(height: 12),
          if (critical == 0 && low == 0)
            Text(AppStrings.dashAttentionEmpty).muted()
          else ...[
            if (critical > 0) _row(Theme.of(context).colorScheme.destructive, AppStrings.dashInventoryOutOfStock, critical),
            if (critical > 0 && low > 0) const SizedBox(height: 10),
            if (low > 0) _row(Colors.orange.shade700, AppStrings.dashInventoryLowStock, low),
          ],
        ],
      ),
    );
  }

  Widget _row(Color color, String label, int count) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text('$count $label').small(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions panel (tiny inline buttons)
// ---------------------------------------------------------------------------

/// Brief point 15 — `[ + Client ] [ + Sale ] [ + Exam ]` as small bordered
/// text chips, not big decorative cards. Replaces `QuickActionsBar`'s use on
/// the dashboard (that widget/file is untouched, just no longer wired here).
class DashboardQuickActionsPanel extends StatelessWidget {
  final VoidCallback onNewClient;
  final VoidCallback onNewSale;
  final VoidCallback onNewExam;

  const DashboardQuickActionsPanel({
    super.key,
    required this.onNewClient,
    required this.onNewSale,
    required this.onNewExam,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.dashPanelQuickActionsTitle,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(AppStrings.quickActionNewClient, Icons.person_add_alt_outlined, onNewClient, colorScheme),
              _chip(AppStrings.dashQuickActionSale, Icons.point_of_sale_outlined, onNewSale, colorScheme),
              _chip(AppStrings.dashQuickActionExam, Icons.visibility_outlined, onNewExam, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, VoidCallback onTap, ColorScheme colorScheme) {
    return material.InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashboardTokens.smallRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DashboardTokens.smallRadius),
          border: Border.all(color: colorScheme.border, width: DashboardTokens.borderWidth),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
