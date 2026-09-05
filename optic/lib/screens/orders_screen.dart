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
import 'package:optic/models/order.dart';
import 'package:optic/widgets/order_card.dart';

String _labStatusLabel(String s) {
  switch (s) {
    case 'inProgress':
      return AppStrings.labStatusInProgress;
    case 'qualityHold':
      return AppStrings.labStatusQualityHold;
    case 'completed':
      return AppStrings.labStatusCompleted;
    case 'queued':
    default:
      return AppStrings.labStatusQueued;
  }
}

String _mountingStatusLabel(String s) {
  switch (s) {
    case 'inProgress':
      return AppStrings.mountingStatusInProgress;
    case 'completed':
      return AppStrings.mountingStatusCompleted;
    case 'rework':
      return AppStrings.mountingStatusRework;
    case 'pending':
    default:
      return AppStrings.mountingStatusPending;
  }
}

String _qcResultLabel(String s) {
  switch (s) {
    case 'conditionalPass':
      return AppStrings.qcResultConditionalPass;
    case 'fail':
      return AppStrings.qcResultFail;
    case 'pass':
    default:
      return AppStrings.qcResultPass;
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

String _orderStatusLabel(String s) {
  switch (s) {
    case 'inProduction':
      return AppStrings.orderStatusInProduction;
    case 'ready':
      return AppStrings.orderStatusReady;
    case 'delivered':
      return AppStrings.orderStatusDelivered;
    case 'cancelled':
      return AppStrings.orderStatusCancelled;
    case 'pending':
    default:
      return AppStrings.orderStatusPending;
  }
}

/// Module 12 — Orders. What a [Quote] becomes once a client commits — the
/// record `LabWorkOrder` (module 13) and `MountingJob` (module 14) hang
/// off of via `orderId`. Every order on file, newest first.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Arrived from a client file's "New order" quick action — see
    // `client_file_screen.dart` — pre-scopes the Add-order dialog to them.
    final extra = GoRouterState.of(context).extra;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    final openAdd = extra is Map && extra['openAdd'] == true;
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.orders),
      bodyBuilder: (context, breakpoint) => _OrdersBody(
        breakpoint: breakpoint,
        initialClientId: initialClientId,
        openAdd: openAdd,
      ),
    );
  }
}

class _OrdersBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final String? initialClientId;
  final bool openAdd;
  const _OrdersBody({
    required this.breakpoint,
    this.initialClientId,
    this.openAdd = false,
  });

  @override
  State<_OrdersBody> createState() => _OrdersBodyState();
}

class _OrdersBodyState extends State<_OrdersBody> with MonthFilterState<_OrdersBody> {
  String _newId() => 'ORD${DateTime.now().millisecondsSinceEpoch}';

  void _showDetail(Order o, String clientName, DataProvider dataProvider) {
    String pipelineStage<T>(List<T> records, String Function(T) statusOf) {
      if (records.isEmpty) return AppStrings.orderPipelineNotStarted;
      return statusOf(records.last);
    }

    final labs = dataProvider.labWorkOrders.where((w) => w.orderId == o.id).toList();
    final mounts = dataProvider.mountingJobs.where((m) => m.orderId == o.id).toList();
    final checks = dataProvider.qualityChecks.where((c) => c.orderId == o.id).toList();
    final fittings = dataProvider.finalFittings.where((f) => f.orderId == o.id).toList();
    final deliveries = dataProvider.deliveryRecords.where((d) => d.orderId == o.id).toList();

    showRecordDetailDialog(
      context: context,
      title: '${o.totalAmount.toStringAsFixed(0)} MAD',
      subtitle: clientName,
      rows: [
        DetailRow(AppStrings.recordFieldClient, clientName),
        DetailRow(AppStrings.cardFieldDate, _formatDate(o.date)),
        DetailRow(AppStrings.recordFieldDescription, o.description),
        DetailRow(AppStrings.recordFieldStatus, _orderStatusLabel(o.status)),
        DetailRow(
          AppStrings.orderPipelineLab,
          pipelineStage(labs, (w) => _labStatusLabel(w.status)),
        ),
        DetailRow(
          AppStrings.orderPipelineMounting,
          pipelineStage(mounts, (m) => _mountingStatusLabel(m.status)),
        ),
        DetailRow(
          AppStrings.orderPipelineQuality,
          pipelineStage(checks, (c) => _qcResultLabel(c.result)),
        ),
        DetailRow(
          AppStrings.orderPipelineFitting,
          fittings.isEmpty
              ? AppStrings.orderPipelineNotStarted
              : '${fittings.last.comfortRating}/5',
        ),
        DetailRow(
          AppStrings.orderPipelineDelivery,
          pipelineStage(deliveries, (d) => _deliveryStatusLabel(d.status)),
        ),
      ],
      onDelete: () => dataProvider.deleteOrder(o.id),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialClientId != null || widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addOrder(context.read<DataProvider>(), initialClientId: widget.initialClientId);
      });
    }
  }

  void _addOrder(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogOrderTitle,
      journeyStep: NavRoute.orders,
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
          key: 'description',
          label: AppStrings.recordFieldDescription,
          maxLines: 2,
        ),
        RecordField(
          key: 'totalAmount',
          label: AppStrings.recordFieldAmount,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'prescriptionId',
          label: AppStrings.recordFieldLinkedPrescription,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final p in dataProvider.prescriptions)
              MapEntry(p.id, '${p.id} — ${_formatDate(p.date)}'),
          ],
        ),
        RecordField(
          key: 'measurementId',
          label: AppStrings.recordFieldLinkedMeasurement,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final m in dataProvider.measurements)
              MapEntry(m.id, '${m.id} — ${_formatDate(m.date)}'),
          ],
        ),
        RecordField(
          key: 'frameId',
          label: AppStrings.recordFieldFrame,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final f in dataProvider.frames)
              MapEntry(f.id, '${f.brand} ${f.model}'),
          ],
        ),
        RecordField(
          key: 'lensId',
          label: AppStrings.recordFieldLens,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final l in dataProvider.lenses)
              MapEntry(l.id, l.productName),
          ],
        ),
        RecordField(
          key: 'accessoryId',
          label: AppStrings.recordFieldLinkedAccessory,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final a in dataProvider.accessories)
              MapEntry(a.id, a.name),
          ],
        ),
        RecordField(
          key: 'status',
          label: AppStrings.recordFieldStatus,
          options:  [
            MapEntry('pending', AppStrings.orderStatusPending),
            MapEntry('inProduction', AppStrings.orderStatusInProduction),
            MapEntry('ready', AppStrings.orderStatusReady),
            MapEntry('delivered', AppStrings.orderStatusDelivered),
            MapEntry('cancelled', AppStrings.orderStatusCancelled),
          ],
        ),
      ],
      onSubmit: (v) {
        final frameId = v['frameId']!.isEmpty ? null : v['frameId'];
        dataProvider.addOrder(
          Order(
            id: _newId(),
            clientId: v['clientId']!,
            date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
            description: v['description']!,
            totalAmount: double.tryParse(v['totalAmount']!) ?? 0,
            status: v['status']!,
            prescriptionId:
                v['prescriptionId']!.isEmpty ? null : v['prescriptionId'],
            measurementId:
                v['measurementId']!.isEmpty ? null : v['measurementId'],
            frameId: frameId,
            lensId: v['lensId']!.isEmpty ? null : v['lensId'],
            accessoryId:
                v['accessoryId']!.isEmpty ? null : v['accessoryId'],
          ),
        );
        // Same "reserve on commit" rule as the quote-conversion path.
        if (frameId != null) {
          final frameIndex = dataProvider.frames.indexWhere(
            (f) => f.id == frameId,
          );
          if (frameIndex != -1) {
            final frame = dataProvider.frames[frameIndex];
            if (frame.stockAvailable > 0) {
              dataProvider.updateFrame(
                frame.copyWith(
                  stockAvailable: frame.stockAvailable - 1,
                  stockReserved: frame.stockReserved + 1,
                ),
              );
            }
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allOrders = [...dataProvider.orders]
      ..sort((a, b) => b.date.compareTo(a.date));
    final orders = allOrders.where((o) => isInSelectedMonth(o.date)).toList();

    final now = DateTime.now();
    final thisMonth = allOrders
        .where((o) => o.date.year == now.year && o.date.month == now.month)
        .length;
    final inProduction = orders
        .where((o) => o.status == 'inProduction')
        .length;
    final revenue = orders
        .where((o) => o.status != 'cancelled')
        .fold<double>(0, (sum, o) => sum + o.totalAmount);

    final clientsById = {for (final p in dataProvider.clients) p.id: p};
    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 4;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navOrders).large().bold()),
              PrimaryButton(
                onPressed: () => _addOrder(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.ordersAddButton),
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
            childAspectRatio: 2.6,
            children: [
              DashboardStatCard(
                label: AppStrings.ordersKpiTotal,
                value: '${orders.length}',
                icon: Icons.shopping_cart_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.ordersKpiThisMonth,
                value: '$thisMonth',
                icon: Icons.calendar_today_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.ordersKpiInProduction,
                value: '$inProduction',
                icon: Icons.precision_manufacturing_outlined,
                accent: Colors.teal.shade600,
              ),
              DashboardStatCard(
                label: AppStrings.ordersKpiRevenue,
                value: '${revenue.toStringAsFixed(0)} MAD',
                icon: Icons.payments_outlined,
                accent: Colors.green.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (orders.isEmpty)
            EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final o in orders)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 340,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            clientsById[o.clientId] != null
                                ? '${clientsById[o.clientId]!.firstName} ${clientsById[o.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ).muted().small(),
                        ),
                        material.InkWell(
                          onTap: () => _showDetail(
                            o,
                            clientsById[o.clientId] != null
                                ? '${clientsById[o.clientId]!.firstName} ${clientsById[o.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                            dataProvider,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: OrderCard(order: o),
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
