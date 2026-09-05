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
import 'package:optic/models/warranty_claim.dart';
import 'package:optic/widgets/warranty_claim_card.dart';

String _warrantyItemLabel(String s) {
  switch (s) {
    case 'lens':
      return AppStrings.repairItemLens;
    case 'contactLens':
      return AppStrings.repairItemContactLens;
    case 'frame':
    default:
      return AppStrings.repairItemFrame;
  }
}

String _warrantyStatusLabel(String s) {
  switch (s) {
    case 'approved':
      return AppStrings.warrantyStatusApproved;
    case 'rejected':
      return AppStrings.warrantyStatusRejected;
    case 'replaced':
      return AppStrings.warrantyStatusReplaced;
    case 'submitted':
    default:
      return AppStrings.warrantyStatusSubmitted;
  }
}

/// Module 20 — Warranty (Client Delivery). Every manufacturer-defect
/// claim on file, newest first.
class WarrantyScreen extends StatelessWidget {
  const WarrantyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.warranty),
      bodyBuilder: (context, breakpoint) =>
          _WarrantyBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _WarrantyBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _WarrantyBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_WarrantyBody> createState() => _WarrantyBodyState();
}

class _WarrantyBodyState extends State<_WarrantyBody> with MonthFilterState<_WarrantyBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addClaim(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'WAR${DateTime.now().millisecondsSinceEpoch}';

  void _showDetail(WarrantyClaim c, String clientName) {
    showRecordDetailDialog(
      context: context,
      title: _warrantyItemLabel(c.itemType),
      subtitle: clientName,
      rows: [
        DetailRow(AppStrings.recordFieldClient, clientName),
        if (c.orderId != null)
          DetailRow(AppStrings.recordFieldLinkedOrder, c.orderId!),
        DetailRow(AppStrings.cardFieldDate, _formatDate(c.date)),
        DetailRow(AppStrings.recordFieldItemType, _warrantyItemLabel(c.itemType)),
        DetailRow(AppStrings.recordFieldIssueDescription, c.issueDescription),
        DetailRow(AppStrings.recordFieldStatus, _warrantyStatusLabel(c.status)),
      ],
      onDelete: () => context.read<DataProvider>().deleteWarrantyClaim(c.id),
    );
  }

  void _addClaim(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogWarrantyTitle,
      journeyStep: NavRoute.warranty,
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
          key: 'itemType',
          label: AppStrings.recordFieldItemType,
          options:  [
            MapEntry('frame', AppStrings.repairItemFrame),
            MapEntry('lens', AppStrings.repairItemLens),
            MapEntry('contactLens', AppStrings.repairItemContactLens),
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
            MapEntry('submitted', AppStrings.warrantyStatusSubmitted),
            MapEntry('approved', AppStrings.warrantyStatusApproved),
            MapEntry('rejected', AppStrings.warrantyStatusRejected),
            MapEntry('replaced', AppStrings.warrantyStatusReplaced),
          ],
        ),
      ],
      onSubmit: (v) => dataProvider.addWarrantyClaim(
        WarrantyClaim(
          id: _newId(),
          clientId: v['clientId']!,
          orderId: v['orderId']!.isEmpty ? null : v['orderId'],
          date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
          itemType: v['itemType']!,
          issueDescription: v['issueDescription']!,
          status: v['status']!,
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
    final allClaims = [...dataProvider.warrantyClaims]
      ..sort((a, b) => b.date.compareTo(a.date));
    final claims = allClaims.where((c) => isInSelectedMonth(c.date)).toList();

    final submitted = claims.where((c) => c.status == 'submitted').length;
    final approvedOrReplaced = claims
        .where((c) => c.status == 'approved' || c.status == 'replaced')
        .length;

    final clientsById = {for (final p in dataProvider.clients) p.id: p};
    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navWarranty).large().bold()),
              PrimaryButton(
                onPressed: () => _addClaim(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.warrantyAddButton),
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
                label: AppStrings.warrantyKpiTotal,
                value: '${claims.length}',
                icon: Icons.verified_user_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.warrantyKpiPending,
                value: '$submitted',
                icon: Icons.pending_outlined,
                accent: Colors.orange.shade700,
              ),
              DashboardStatCard(
                label: AppStrings.warrantyKpiApproved,
                value: '$approvedOrReplaced',
                icon: Icons.check_circle_outline,
                accent: Colors.green.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (claims.isEmpty)
            EmptyState(
              icon: Icons.verified_user_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in claims)
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
                            clientsById[c.clientId] != null
                                ? '${clientsById[c.clientId]!.firstName} ${clientsById[c.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ).muted().small(),
                        ),
                        material.InkWell(
                          onTap: () => _showDetail(
                            c,
                            clientsById[c.clientId] != null
                                ? '${clientsById[c.clientId]!.firstName} ${clientsById[c.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: WarrantyClaimCard(claim: c),
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
