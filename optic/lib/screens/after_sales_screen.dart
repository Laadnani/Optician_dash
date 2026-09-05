import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/empty_state.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/helpers/add_record_dialog.dart';
import 'package:optic/helpers/month_filter_bar.dart';
import 'package:optic/helpers/record_detail_dialog.dart';
import 'package:optic/helpers/stat_card.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/after_sales_ticket.dart';
import 'package:optic/widgets/after_sales_ticket_card.dart';

String _issueTypeLabel(String s) {
  switch (s) {
    case 'breakage':
      return AppStrings.afterSalesIssueBreakage;
    case 'visionIssue':
      return AppStrings.afterSalesIssueVision;
    case 'other':
      return AppStrings.afterSalesIssueOther;
    case 'comfort':
    default:
      return AppStrings.afterSalesIssueComfort;
  }
}

String _afterSalesStatusLabel(String s) {
  switch (s) {
    case 'inProgress':
      return AppStrings.afterSalesStatusInProgress;
    case 'resolved':
      return AppStrings.afterSalesStatusResolved;
    case 'closed':
      return AppStrings.afterSalesStatusClosed;
    case 'open':
    default:
      return AppStrings.afterSalesStatusOpen;
  }
}

/// Module 18 — After-Sales (Client Delivery). Every post-delivery support
/// ticket on file, newest first, with an open-ticket count.
class AfterSalesScreen extends StatelessWidget {
  const AfterSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.afterSales),
      bodyBuilder: (context, breakpoint) =>
          _AfterSalesBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _AfterSalesBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _AfterSalesBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_AfterSalesBody> createState() => _AfterSalesBodyState();
}

class _AfterSalesBodyState extends State<_AfterSalesBody> with MonthFilterState<_AfterSalesBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addTicket(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'AS${DateTime.now().millisecondsSinceEpoch}';

  void _showDetail(AfterSalesTicket t) {
    showRecordDetailDialog(
      context: context,
      title: _issueTypeLabel(t.issueType),
      subtitle: t.orderId,
      rows: [
        DetailRow(AppStrings.recordFieldOrderId, t.orderId),
        DetailRow(AppStrings.cardFieldDate, _formatDate(t.date)),
        DetailRow(AppStrings.recordFieldIssueType, _issueTypeLabel(t.issueType)),
        DetailRow(AppStrings.recordFieldStatus, _afterSalesStatusLabel(t.status)),
        if (t.resolution.isNotEmpty)
          DetailRow(AppStrings.recordFieldResolution, t.resolution),
      ],
      onDelete: () => context.read<DataProvider>().deleteAfterSalesTicket(t.id),
    );
  }

  void _addTicket(DataProvider dataProvider, {String? initialClientId}) {
    final eligibleOrders = initialClientId == null
        ? dataProvider.orders
        : dataProvider.orders
            .where((o) => o.clientId == initialClientId)
            .toList();
    final orderOptions = eligibleOrders.isEmpty ? dataProvider.orders : eligibleOrders;
    if (dataProvider.orders.isEmpty) {
      // Previously silently did nothing here — this record always needs an
      // existing order to attach to, so with none yet, tell the user that
      // instead of the button just appearing dead.
      showRecordDetailDialog(
        context: context,
        title: AppStrings.missingDependencyTitle,
        subtitle: AppStrings.missingOrderDependencyMessage,
        rows: const [],
        actions: [
          DetailAction(
            label: AppStrings.navOrders,
            icon: Icons.arrow_forward,
            primary: true,
            onPressed: () => context.go(NavRoute.orders.path),
          ),
        ],
      );
      return;
    }
    showAddRecordDialog(
      context: context,
      title: AppStrings.addDialogAfterSalesTitle,
      journeyStep: NavRoute.afterSales,
      fields: [
        RecordField(
          key: 'orderId',
          label: AppStrings.recordFieldOrderId,
          initialValue: orderOptions.isEmpty ? null : orderOptions.first.id,
          options: [
            for (final o in orderOptions)
              MapEntry(o.id, '${o.id} — ${o.description}'),
          ],
        ),
        RecordField(
          key: 'date',
          label: AppStrings.cardFieldDate,
          hint: 'YYYY-MM-DD',
          initialValue: _formatDate(DateTime.now()),
        ),
        RecordField(
          key: 'issueType',
          label: AppStrings.recordFieldIssueType,
          options:  [
            MapEntry('comfort', AppStrings.afterSalesIssueComfort),
            MapEntry('breakage', AppStrings.afterSalesIssueBreakage),
            MapEntry('visionIssue', AppStrings.afterSalesIssueVision),
            MapEntry('other', AppStrings.afterSalesIssueOther),
          ],
        ),
        RecordField(
          key: 'status',
          label: AppStrings.recordFieldStatus,
          options:  [
            MapEntry('open', AppStrings.afterSalesStatusOpen),
            MapEntry('inProgress', AppStrings.afterSalesStatusInProgress),
            MapEntry('resolved', AppStrings.afterSalesStatusResolved),
            MapEntry('closed', AppStrings.afterSalesStatusClosed),
          ],
        ),
        RecordField(
          key: 'outcome',
          label: AppStrings.afterSalesFieldOutcome,
          options: [
            MapEntry('pending', AppStrings.afterSalesOutcomePending),
            MapEntry('satisfied', AppStrings.afterSalesOutcomeSatisfied),
            MapEntry('complaint', AppStrings.afterSalesOutcomeComplaint),
            MapEntry('repair', AppStrings.afterSalesOutcomeRepair),
          ],
        ),
        RecordField(
          key: 'resolution',
          label: AppStrings.recordFieldResolution,
          required: false,
          maxLines: 2,
        ),
      ],
      onSubmit: (v) {
        final order = dataProvider.orders.firstWhere(
          (o) => o.id == v['orderId'],
        );
        final orderDeliveries = dataProvider.deliveryRecords
            .where((d) => d.orderId == v['orderId'])
            .toList();
        dataProvider.addAfterSalesTicket(
          AfterSalesTicket(
            id: _newId(),
            orderId: v['orderId']!,
            clientId: order.clientId,
            date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
            issueType: v['issueType']!,
            status: v['status']!,
            resolution: v['resolution']!,
            outcome: v['outcome']!,
            deliveryRecordId:
                orderDeliveries.isEmpty ? null : orderDeliveries.last.id,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allTickets = [...dataProvider.afterSalesTickets]
      ..sort((a, b) => b.date.compareTo(a.date));
    final tickets = allTickets.where((t) => isInSelectedMonth(t.date)).toList();

    final open = tickets.where((t) => t.status == 'open').length;
    final resolved = tickets
        .where((t) => t.status == 'resolved' || t.status == 'closed')
        .length;

    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navAfterSales).large().bold()),
              PrimaryButton(
                onPressed: () => _addTicket(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.afterSalesAddButton),
              ),
            ],
          ),
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
                label: AppStrings.afterSalesKpiTotal,
                value: '${tickets.length}',
                icon: Icons.support_agent_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.afterSalesKpiOpen,
                value: '$open',
                icon: Icons.flag_outlined,
                accent: Colors.orange.shade700,
              ),
              DashboardStatCard(
                label: AppStrings.afterSalesKpiResolved,
                value: '$resolved',
                icon: Icons.check_circle_outline,
                accent: Colors.green.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (tickets.isEmpty)
            EmptyState(
              icon: Icons.support_agent_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final t in tickets)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 320,
                    child: material.InkWell(
                      onTap: () => _showDetail(t),
                      borderRadius: BorderRadius.circular(12),
                      child: AfterSalesTicketCard(ticket: t),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
