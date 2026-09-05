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
import 'package:optic/models/delivery_record.dart';
import 'package:optic/widgets/delivery_record_card.dart';

String _deliveryMethodLabel(String s) {
  switch (s) {
    case 'homeDelivery':
      return AppStrings.deliveryMethodHome;
    case 'courier':
      return AppStrings.deliveryMethodCourier;
    case 'inStore':
    default:
      return AppStrings.deliveryMethodInStore;
  }
}

String _deliveryStatusLabel(String s) {
  switch (s) {
    case 'delivered':
      return AppStrings.deliveryStatusDelivered;
    case 'failed':
      return AppStrings.deliveryStatusFailed;
    case 'scheduled':
    default:
      return AppStrings.deliveryStatusScheduled;
  }
}

/// Module 17 — Delivery (Client Delivery). Every handoff on file, newest
/// first — the close of the production pipeline that started at [Order].
class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.delivery),
      bodyBuilder: (context, breakpoint) =>
          _DeliveryBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _DeliveryBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _DeliveryBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_DeliveryBody> createState() => _DeliveryBodyState();
}

class _DeliveryBodyState extends State<_DeliveryBody> with MonthFilterState<_DeliveryBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addDelivery(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'DEL${DateTime.now().millisecondsSinceEpoch}';

  void _showDetail(DeliveryRecord d) {
    showRecordDetailDialog(
      context: context,
      title: _deliveryMethodLabel(d.method),
      subtitle: d.orderId,
      rows: [
        DetailRow(AppStrings.recordFieldOrderId, d.orderId),
        DetailRow(AppStrings.cardFieldDate, _formatDate(d.date)),
        DetailRow(AppStrings.recordFieldMethod, _deliveryMethodLabel(d.method)),
        DetailRow(AppStrings.recordFieldStatus, _deliveryStatusLabel(d.status)),
      ],
      onDelete: () => context.read<DataProvider>().deleteDeliveryRecord(d.id),
    );
  }

  void _addDelivery(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogDeliveryTitle,
      journeyStep: NavRoute.delivery,
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
          key: 'method',
          label: AppStrings.recordFieldMethod,
          options:  [
            MapEntry('inStore', AppStrings.deliveryMethodInStore),
            MapEntry('homeDelivery', AppStrings.deliveryMethodHome),
            MapEntry('courier', AppStrings.deliveryMethodCourier),
          ],
        ),
        RecordField(
          key: 'status',
          label: AppStrings.recordFieldStatus,
          options:  [
            MapEntry('scheduled', AppStrings.deliveryStatusScheduled),
            MapEntry('delivered', AppStrings.deliveryStatusDelivered),
            MapEntry('failed', AppStrings.deliveryStatusFailed),
          ],
        ),
      ],
      onSubmit: (v) {
        final order = dataProvider.orders.firstWhere(
          (o) => o.id == v['orderId'],
        );
        // "Payment completed" per the diagram — the invoice this handoff
        // confirms was settled, when one is on file for this order.
        final orderInvoices = dataProvider.invoices
            .where((i) => i.orderId == v['orderId'])
            .toList();
        dataProvider.addDeliveryRecord(
          DeliveryRecord(
            id: _newId(),
            orderId: v['orderId']!,
            clientId: order.clientId,
            date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
            method: v['method']!,
            status: v['status']!,
            recipientSignature: v['status'] == 'delivered',
            invoiceId: orderInvoices.isEmpty ? null : orderInvoices.last.id,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allRecords = [...dataProvider.deliveryRecords]
      ..sort((a, b) => b.date.compareTo(a.date));
    final records = allRecords.where((d) => isInSelectedMonth(d.date)).toList();

    final now = DateTime.now();
    final thisMonth = allRecords
        .where((d) => d.date.year == now.year && d.date.month == now.month)
        .length;
    final scheduled = records.where((d) => d.status == 'scheduled').length;
    final delivered = records.where((d) => d.status == 'delivered').length;

    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navDelivery).large().bold()),
              PrimaryButton(
                onPressed: () => _addDelivery(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.deliveryAddButton),
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
                label: AppStrings.deliveryKpiThisMonth,
                value: '$thisMonth',
                icon: Icons.calendar_today_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.deliveryKpiScheduled,
                value: '$scheduled',
                icon: Icons.schedule_outlined,
                accent: Colors.orange.shade700,
              ),
              DashboardStatCard(
                label: AppStrings.deliveryKpiDelivered,
                value: '$delivered',
                icon: Icons.local_shipping_outlined,
                accent: Colors.green.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (records.isEmpty)
            EmptyState(
              icon: Icons.local_shipping_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final d in records)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 300,
                    child: material.InkWell(
                      onTap: () => _showDetail(d),
                      borderRadius: BorderRadius.circular(12),
                      child: DeliveryRecordCard(record: d),
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
