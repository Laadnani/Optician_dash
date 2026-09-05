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
import 'package:optic/models/lab_work_order.dart';
import 'package:optic/widgets/lab_work_order_card.dart';

String _labTaskLabel(String s) {
  switch (s) {
    case 'edging':
      return AppStrings.labTaskEdging;
    case 'coating':
      return AppStrings.labTaskCoating;
    case 'tinting':
      return AppStrings.labTaskTinting;
    case 'engraving':
      return AppStrings.labTaskEngraving;
    case 'other':
      return AppStrings.labTaskOther;
    case 'lensCutting':
    default:
      return AppStrings.labTaskLensCutting;
  }
}

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

/// Module 13 — Laboratory. Every production task an [Order] requires
/// (cutting, edging, coating, tinting, engraving), newest first, with an
/// overdue count for anything past its due date and not yet completed.
class LaboratoryScreen extends StatelessWidget {
  const LaboratoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.laboratory),
      bodyBuilder: (context, breakpoint) =>
          _LaboratoryBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _LaboratoryBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _LaboratoryBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_LaboratoryBody> createState() => _LaboratoryBodyState();
}

class _LaboratoryBodyState extends State<_LaboratoryBody> with MonthFilterState<_LaboratoryBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addWorkOrder(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'LAB${DateTime.now().millisecondsSinceEpoch}';

  void _showDetail(LabWorkOrder w, DataProvider dataProvider) {
    final order = dataProvider.orders.where((o) => o.id == w.orderId);
    showRecordDetailDialog(
      context: context,
      title: _labTaskLabel(w.taskType),
      subtitle: order.isNotEmpty ? order.first.description : w.orderId,
      rows: [
        DetailRow(AppStrings.recordFieldOrderId, w.orderId),
        DetailRow(AppStrings.cardFieldDate, _formatDate(w.date)),
        DetailRow(AppStrings.recordFieldTaskType, _labTaskLabel(w.taskType)),
        DetailRow(AppStrings.recordFieldStatus, _labStatusLabel(w.status)),
        if (w.dueDate != null)
          DetailRow(AppStrings.recordFieldDueDate, _formatDate(w.dueDate!)),
      ],
      onDelete: () => dataProvider.deleteLabWorkOrder(w.id),
    );
  }

  void _addWorkOrder(DataProvider dataProvider, {String? initialClientId}) {
    final eligibleOrders = initialClientId == null
        ? dataProvider.orders
        : dataProvider.orders
            .where((o) => o.clientId == initialClientId)
            .toList();
    final orderOptions = eligibleOrders.isEmpty ? dataProvider.orders : eligibleOrders;
    if (dataProvider.orders.isEmpty) {
      // Previously silently did nothing here — a work order always needs
      // an existing order to attach to, so with none yet, tell the user
      // that instead of the button just appearing dead.
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
      title: AppStrings.addDialogLabWorkOrderTitle,
      journeyStep: NavRoute.laboratory,
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
          key: 'taskType',
          label: AppStrings.recordFieldTaskType,
          options:  [
            MapEntry('lensCutting', AppStrings.labTaskLensCutting),
            MapEntry('edging', AppStrings.labTaskEdging),
            MapEntry('coating', AppStrings.labTaskCoating),
            MapEntry('tinting', AppStrings.labTaskTinting),
            MapEntry('engraving', AppStrings.labTaskEngraving),
            MapEntry('other', AppStrings.labTaskOther),
          ],
        ),
        RecordField(
          key: 'status',
          label: AppStrings.recordFieldStatus,
          options:  [
            MapEntry('queued', AppStrings.labStatusQueued),
            MapEntry('inProgress', AppStrings.labStatusInProgress),
            MapEntry('qualityHold', AppStrings.labStatusQualityHold),
            MapEntry('completed', AppStrings.labStatusCompleted),
          ],
        ),
        RecordField(
          key: 'dueDate',
          label: AppStrings.recordFieldDueDate,
          hint: 'YYYY-MM-DD',
          required: false,
        ),
      ],
      onSubmit: (v) {
        final order = dataProvider.orders.firstWhere(
          (o) => o.id == v['orderId'],
        );
        dataProvider.addLabWorkOrder(
          LabWorkOrder(
            id: _newId(),
            orderId: v['orderId']!,
            clientId: order.clientId,
            date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
            taskType: v['taskType']!,
            status: v['status']!,
            dueDate: v['dueDate']!.isEmpty
                ? null
                : DateTime.tryParse(v['dueDate']!),
            // Carried over from the order itself rather than re-asked —
            // the diagram's Laboratory Order node is just the order's own
            // clinical/product payload plus production instructions.
            prescriptionId: order.prescriptionId,
            measurementId: order.measurementId,
            frameId: order.frameId,
            lensId: order.lensId,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allWorkOrders = [...dataProvider.labWorkOrders]
      ..sort((a, b) => b.date.compareTo(a.date));
    final workOrders = allWorkOrders.where((w) => isInSelectedMonth(w.date)).toList();

    final now = DateTime.now();
    final inProgress = workOrders.where((w) => w.status == 'inProgress').length;
    final overdue = workOrders
        .where(
          (w) =>
              w.status != 'completed' &&
              w.dueDate != null &&
              w.dueDate!.isBefore(now),
        )
        .length;
    final completedThisMonth = allWorkOrders
        .where(
          (w) =>
              w.status == 'completed' &&
              w.date.year == now.year &&
              w.date.month == now.month,
        )
        .length;

    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navLaboratory).large().bold()),
              PrimaryButton(
                onPressed: () => _addWorkOrder(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.laboratoryAddButton),
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
                label: AppStrings.laboratoryKpiTotal,
                value: '${workOrders.length}',
                icon: Icons.science_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.laboratoryKpiInProgress,
                value: '$inProgress',
                icon: Icons.precision_manufacturing_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.laboratoryKpiOverdue,
                value: '$overdue',
                icon: Icons.warning_amber_outlined,
                accent: colorScheme.destructive,
              ),
              DashboardStatCard(
                label: AppStrings.laboratoryKpiCompletedThisMonth,
                value: '$completedThisMonth',
                icon: Icons.check_circle_outline,
                accent: Colors.green.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (workOrders.isEmpty)
            EmptyState(
              icon: Icons.science_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final w in workOrders)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 300,
                    child: material.InkWell(
                      onTap: () => _showDetail(w, dataProvider),
                      borderRadius: BorderRadius.circular(12),
                      child: LabWorkOrderCard(workOrder: w),
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
