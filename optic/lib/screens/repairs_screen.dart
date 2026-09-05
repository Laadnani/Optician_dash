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
import 'package:optic/models/repair_ticket.dart';
import 'package:optic/widgets/repair_ticket_card.dart';

String _repairItemLabel(String s) {
  switch (s) {
    case 'lens':
      return AppStrings.repairItemLens;
    case 'contactLens':
      return AppStrings.repairItemContactLens;
    case 'other':
      return AppStrings.repairItemOther;
    case 'frame':
    default:
      return AppStrings.repairItemFrame;
  }
}

String _repairStatusLabel(String s) {
  switch (s) {
    case 'inProgress':
      return AppStrings.repairStatusInProgress;
    case 'completed':
      return AppStrings.repairStatusCompleted;
    case 'cannotRepair':
      return AppStrings.repairStatusCannotRepair;
    case 'received':
    default:
      return AppStrings.repairStatusReceived;
  }
}

/// Module 19 — Repairs (Client Delivery). Physical repair work on a
/// client's own item — every ticket on file, newest first.
class RepairsScreen extends StatelessWidget {
  const RepairsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.repairs),
      bodyBuilder: (context, breakpoint) =>
          _RepairsBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _RepairsBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _RepairsBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_RepairsBody> createState() => _RepairsBodyState();
}

class _RepairsBodyState extends State<_RepairsBody> with MonthFilterState<_RepairsBody> {
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

  String _newId() => 'REP${DateTime.now().millisecondsSinceEpoch}';

  void _showDetail(RepairTicket t, String clientName) {
    showRecordDetailDialog(
      context: context,
      title: _repairItemLabel(t.itemType),
      subtitle: clientName,
      rows: [
        DetailRow(AppStrings.recordFieldClient, clientName),
        if (t.orderId != null)
          DetailRow(AppStrings.recordFieldLinkedOrder, t.orderId!),
        DetailRow(AppStrings.cardFieldDate, _formatDate(t.date)),
        DetailRow(AppStrings.recordFieldItemType, _repairItemLabel(t.itemType)),
        DetailRow(AppStrings.recordFieldIssueDescription, t.issueDescription),
        DetailRow(AppStrings.recordFieldStatus, _repairStatusLabel(t.status)),
        DetailRow(AppStrings.recordFieldCost, '${t.cost.toStringAsFixed(0)} MAD'),
      ],
      onDelete: () => context.read<DataProvider>().deleteRepairTicket(t.id),
    );
  }

  void _addTicket(DataProvider dataProvider, {String? initialClientId}) {
    if (dataProvider.clients.isEmpty) {
      // Previously silently did nothing here — this record always needs an
      // existing client to attach to, so with none yet, tell the user that
      // instead of the button just appearing dead.
      showRecordDetailDialog(
        context: context,
        title: AppStrings.missingDependencyTitle,
        subtitle: AppStrings.missingClientDependencyMessage,
        rows: const [],
        actions: [
          DetailAction(
            label: AppStrings.navClients,
            icon: Icons.arrow_forward,
            primary: true,
            onPressed: () => context.go(NavRoute.clients.path),
          ),
        ],
      );
      return;
    }
    showAddRecordDialog(
      context: context,
      title: AppStrings.addDialogRepairTitle,
      journeyStep: NavRoute.repairs,
      fields: [
        RecordField(
          key: 'clientId',
          label: AppStrings.recordFieldClient,
          initialValue: initialClientId,
          options: [
            for (final p in dataProvider.clients)
              MapEntry(p.id, '${p.firstName} ${p.lastName}'),
          ],
        ),
        RecordField(
          key: 'date',
          label: AppStrings.cardFieldDate,
          hint: 'YYYY-MM-DD',
          initialValue: _formatDate(DateTime.now()),
        ),
        RecordField(
          key: 'itemType',
          label: AppStrings.recordFieldItemType,
          options:  [
            MapEntry('frame', AppStrings.repairItemFrame),
            MapEntry('lens', AppStrings.repairItemLens),
            MapEntry('contactLens', AppStrings.repairItemContactLens),
            MapEntry('other', AppStrings.repairItemOther),
          ],
        ),
        RecordField(
          key: 'orderId',
          label: AppStrings.recordFieldLinkedOrder,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final o in dataProvider.orders)
              MapEntry(o.id, '${o.id} — ${o.description}'),
          ],
        ),
        RecordField(
          key: 'afterSalesTicketId',
          label: AppStrings.recordFieldLinkedAfterSalesTicket,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final t in dataProvider.afterSalesTickets)
              MapEntry(t.id, '${t.id} — ${_formatDate(t.date)}'),
          ],
        ),
        RecordField(
          key: 'issueDescription',
          label: AppStrings.recordFieldIssueDescription,
          maxLines: 2,
        ),
        RecordField(
          key: 'status',
          label: AppStrings.recordFieldStatus,
          options:  [
            MapEntry('received', AppStrings.repairStatusReceived),
            MapEntry('inProgress', AppStrings.repairStatusInProgress),
            MapEntry('completed', AppStrings.repairStatusCompleted),
            MapEntry('cannotRepair', AppStrings.repairStatusCannotRepair),
          ],
        ),
        RecordField(
          key: 'cost',
          label: AppStrings.recordFieldCost,
          required: false,
          initialValue: '0',
          keyboardType: material.TextInputType.number,
        ),
      ],
      onSubmit: (v) => dataProvider.addRepairTicket(
        RepairTicket(
          id: _newId(),
          clientId: v['clientId']!,
          orderId: v['orderId']!.isEmpty ? null : v['orderId'],
          date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
          itemType: v['itemType']!,
          issueDescription: v['issueDescription']!,
          status: v['status']!,
          cost: double.tryParse(v['cost']!) ?? 0,
          afterSalesTicketId: v['afterSalesTicketId']!.isEmpty
              ? null
              : v['afterSalesTicketId'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allTickets = [...dataProvider.repairTickets]
      ..sort((a, b) => b.date.compareTo(a.date));
    final tickets = allTickets.where((t) => isInSelectedMonth(t.date)).toList();

    final inProgress = tickets.where((t) => t.status == 'inProgress').length;
    final revenue = tickets
        .where((t) => t.status == 'completed')
        .fold<double>(0, (sum, t) => sum + t.cost);

    final clientsById = {for (final p in dataProvider.clients) p.id: p};
    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navRepairs).large().bold()),
              PrimaryButton(
                onPressed: () => _addTicket(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.repairsAddButton),
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
                label: AppStrings.repairsKpiTotal,
                value: '${tickets.length}',
                icon: Icons.build_circle_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.repairsKpiInProgress,
                value: '$inProgress',
                icon: Icons.precision_manufacturing_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.repairsKpiRevenue,
                value: '${revenue.toStringAsFixed(0)} MAD',
                icon: Icons.payments_outlined,
                accent: Colors.green.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (tickets.isEmpty)
            EmptyState(
              icon: Icons.build_circle_outlined,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            clientsById[t.clientId] != null
                                ? '${clientsById[t.clientId]!.firstName} ${clientsById[t.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ).muted().small(),
                        ),
                        material.InkWell(
                          onTap: () => _showDetail(
                            t,
                            clientsById[t.clientId] != null
                                ? '${clientsById[t.clientId]!.firstName} ${clientsById[t.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: RepairTicketCard(ticket: t),
                        ),
                      ],
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
