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
import 'package:optic/models/final_fitting.dart';
import 'package:optic/models/mounting_job.dart';
import 'package:optic/models/quality_check.dart';
import 'package:optic/widgets/quality_check_card.dart';

String _qcTypeLabel(String s) {
  switch (s) {
    case 'lensQuality':
      return AppStrings.qcTypeLensQuality;
    case 'prescriptionAccuracy':
      return AppStrings.qcTypePrescriptionAccuracy;
    case 'cosmetic':
      return AppStrings.qcTypeCosmetic;
    case 'other':
      return AppStrings.qcTypeOther;
    case 'frameFit':
    default:
      return AppStrings.qcTypeFrameFit;
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

/// Module 15 — Quality Control. Every inspection on file, newest first,
/// with a pass-rate KPI covering the checks an optician actually watches
/// before an order reaches Final Fitting.
class QualityControlScreen extends StatelessWidget {
  const QualityControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) =>
          buildAppNavItems(context, NavRoute.qualityControl),
      bodyBuilder: (context, breakpoint) =>
          _QualityControlBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _QualityControlBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _QualityControlBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_QualityControlBody> createState() => _QualityControlBodyState();
}

class _QualityControlBodyState extends State<_QualityControlBody> with MonthFilterState<_QualityControlBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addCheck(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'QC${DateTime.now().millisecondsSinceEpoch}';

  // Per the diagram: a passing QC feeds Final Fitting; a failed QC loops
  // back into a new Assembly/Mounting job (Remake/Rework) instead. Both
  // quick actions carry the check's own orderId/clientId and — where
  // known — the frame/lens the original mounting job used, so the new
  // record isn't just a bare id but the same real payload.
  void _createFinalFitting(DataProvider dataProvider, QualityCheck c) {
    dataProvider.addFinalFitting(
      FinalFitting(
        id: 'FF${DateTime.now().millisecondsSinceEpoch}',
        orderId: c.orderId,
        clientId: c.clientId,
        date: DateTime.now(),
        qualityCheckId: c.id,
      ),
    );
    material.ScaffoldMessenger.of(context).showSnackBar(
      material.SnackBar(content: Text(AppStrings.qcFinalFittingCreatedSnackbar)),
    );
    context.go(NavRoute.finalFitting.path);
  }

  void _createRework(DataProvider dataProvider, QualityCheck c) {
    final matchingJobs = c.mountingJobId == null
        ? const <MountingJob>[]
        : dataProvider.mountingJobs
              .where((m) => m.id == c.mountingJobId)
              .toList();
    final originalJob = matchingJobs.isEmpty ? null : matchingJobs.first;
    dataProvider.addMountingJob(
      MountingJob(
        id: 'MNT${DateTime.now().millisecondsSinceEpoch}',
        orderId: c.orderId,
        clientId: c.clientId,
        date: DateTime.now(),
        frameId: originalJob?.frameId ?? '',
        lensId: originalJob?.lensId ?? '',
        status: 'rework',
        reworkOfQualityCheckId: c.id,
      ),
    );
    material.ScaffoldMessenger.of(context).showSnackBar(
      material.SnackBar(content: Text(AppStrings.qcReworkCreatedSnackbar)),
    );
    context.go(NavRoute.mounting.path);
  }

  void _showDetail(QualityCheck c, DataProvider dataProvider) {
    showRecordDetailDialog(
      context: context,
      title: _qcTypeLabel(c.checkType),
      subtitle: c.orderId,
      rows: [
        DetailRow(AppStrings.recordFieldOrderId, c.orderId),
        DetailRow(AppStrings.cardFieldDate, _formatDate(c.date)),
        DetailRow(AppStrings.recordFieldCheckType, _qcTypeLabel(c.checkType)),
        DetailRow(AppStrings.recordFieldResult, _qcResultLabel(c.result)),
        if (c.notes.isNotEmpty)
          DetailRow(AppStrings.recordFieldNotes, c.notes),
      ],
      actions: [
        if (c.result == 'pass' || c.result == 'conditionalPass')
          DetailAction(
            label: AppStrings.qcCreateFinalFittingAction,
            icon: Icons.tune_outlined,
            primary: true,
            onPressed: () => _createFinalFitting(dataProvider, c),
          ),
        if (c.result == 'fail')
          DetailAction(
            label: AppStrings.qcCreateReworkAction,
            icon: Icons.build_outlined,
            primary: true,
            onPressed: () => _createRework(dataProvider, c),
          ),
      ],
      onDelete: () => dataProvider.deleteQualityCheck(c.id),
    );
  }

  void _addCheck(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogQualityCheckTitle,
      journeyStep: NavRoute.qualityControl,
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
          key: 'checkType',
          label: AppStrings.recordFieldCheckType,
          options:  [
            MapEntry('frameFit', AppStrings.qcTypeFrameFit),
            MapEntry('lensQuality', AppStrings.qcTypeLensQuality),
            MapEntry(
              'prescriptionAccuracy',
              AppStrings.qcTypePrescriptionAccuracy,
            ),
            MapEntry('cosmetic', AppStrings.qcTypeCosmetic),
            MapEntry('other', AppStrings.qcTypeOther),
          ],
        ),
        RecordField(
          key: 'result',
          label: AppStrings.recordFieldResult,
          options:  [
            MapEntry('pass', AppStrings.qcResultPass),
            MapEntry('conditionalPass', AppStrings.qcResultConditionalPass),
            MapEntry('fail', AppStrings.qcResultFail),
          ],
        ),
        RecordField(
          key: 'notes',
          label: AppStrings.recordFieldNotes,
          required: false,
          maxLines: 2,
        ),
      ],
      onSubmit: (v) {
        final order = dataProvider.orders.firstWhere(
          (o) => o.id == v['orderId'],
        );
        final mountingJobs = dataProvider.mountingJobs
            .where((m) => m.orderId == v['orderId'])
            .toList();
        dataProvider.addQualityCheck(
          QualityCheck(
            id: _newId(),
            orderId: v['orderId']!,
            clientId: order.clientId,
            date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
            checkType: v['checkType']!,
            result: v['result']!,
            notes: v['notes']!,
            mountingJobId:
                mountingJobs.isEmpty ? null : mountingJobs.last.id,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allChecks = [...dataProvider.qualityChecks]
      ..sort((a, b) => b.date.compareTo(a.date));
    final checks = allChecks.where((c) => isInSelectedMonth(c.date)).toList();

    final passed = checks.where((c) => c.result == 'pass').length;
    final failed = checks.where((c) => c.result == 'fail').length;
    final passRate = checks.isEmpty ? 0 : (passed / checks.length * 100).round();

    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.navQualityControl).large().bold(),
              ),
              PrimaryButton(
                onPressed: () => _addCheck(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.qualityControlAddButton),
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
                label: AppStrings.qualityControlKpiTotal,
                value: '${checks.length}',
                icon: Icons.verified_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.qualityControlKpiPassRate,
                value: '$passRate%',
                icon: Icons.check_circle_outline,
                accent: Colors.green.shade700,
              ),
              DashboardStatCard(
                label: AppStrings.qualityControlKpiFailed,
                value: '$failed',
                icon: Icons.error_outline,
                accent: colorScheme.destructive,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (checks.isEmpty)
            EmptyState(
              icon: Icons.verified_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in checks)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 300,
                    child: material.InkWell(
                      onTap: () => _showDetail(c, dataProvider),
                      borderRadius: BorderRadius.circular(12),
                      child: QualityCheckCard(check: c),
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
