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
import 'package:optic/models/mounting_job.dart';
import 'package:optic/widgets/mounting_job_card.dart';

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

/// Module 14 — Mounting. The frame + lens assembly step that follows
/// `LaboratoryScreen` (module 13) — every mounting job on file, newest
/// first.
class MountingScreen extends StatelessWidget {
  const MountingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.mounting),
      bodyBuilder: (context, breakpoint) =>
          _MountingBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _MountingBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _MountingBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_MountingBody> createState() => _MountingBodyState();
}

class _MountingBodyState extends State<_MountingBody> with MonthFilterState<_MountingBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addJob(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'MNT${DateTime.now().millisecondsSinceEpoch}';

  void _showDetail(MountingJob j, String frameLabel, String lensLabel) {
    showRecordDetailDialog(
      context: context,
      title: '${AppStrings.navMounting} — ${j.orderId}',
      subtitle: frameLabel,
      rows: [
        DetailRow(AppStrings.recordFieldOrderId, j.orderId),
        DetailRow(AppStrings.cardFieldDate, _formatDate(j.date)),
        DetailRow(AppStrings.recordFieldFrame, frameLabel),
        DetailRow(AppStrings.recordFieldLens, lensLabel),
        DetailRow(AppStrings.recordFieldStatus, _mountingStatusLabel(j.status)),
      ],
      onDelete: () => context.read<DataProvider>().deleteMountingJob(j.id),
    );
  }

  void _addJob(DataProvider dataProvider, {String? initialClientId}) {
    final eligibleOrders = initialClientId == null
        ? dataProvider.orders
        : dataProvider.orders
            .where((o) => o.clientId == initialClientId)
            .toList();
    final orderOptions = eligibleOrders.isEmpty ? dataProvider.orders : eligibleOrders;
    // Previously silently did nothing here — a mounting job always needs an
    // existing order, a frame, and a lens to attach to, so with any of those
    // missing, tell the user instead of the button just appearing dead (same
    // fix as laboratory_screen.dart / quality_control_screen.dart, extended
    // to this screen's extra frame/lens dependencies).
    if (dataProvider.orders.isEmpty) {
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
    if (dataProvider.frames.isEmpty) {
      showRecordDetailDialog(
        context: context,
        title: AppStrings.missingDependencyTitle,
        subtitle: AppStrings.missingFrameDependencyMessage,
        rows: const [],
        actions: [
          DetailAction(
            label: AppStrings.navFrameInventory,
            icon: Icons.arrow_forward,
            primary: true,
            onPressed: () => context.go(NavRoute.frameInventory.path),
          ),
        ],
      );
      return;
    }
    if (dataProvider.lenses.isEmpty) {
      showRecordDetailDialog(
        context: context,
        title: AppStrings.missingDependencyTitle,
        subtitle: AppStrings.missingLensDependencyMessage,
        rows: const [],
        actions: [
          DetailAction(
            label: AppStrings.navLensCatalog,
            icon: Icons.arrow_forward,
            primary: true,
            onPressed: () => context.go(NavRoute.lensCatalog.path),
          ),
        ],
      );
      return;
    }
    showAddRecordDialog(
      context: context,
      title: AppStrings.addDialogMountingTitle,
      journeyStep: NavRoute.mounting,
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
          key: 'frameId',
          label: AppStrings.recordFieldFrame,
          options: [
            for (final f in dataProvider.frames)
              MapEntry(f.id, '${f.brand} ${f.model}'),
          ],
        ),
        RecordField(
          key: 'lensId',
          label: AppStrings.recordFieldLens,
          options: [
            for (final l in dataProvider.lenses)
              MapEntry(l.id, l.productName),
          ],
        ),
        RecordField(
          key: 'status',
          label: AppStrings.recordFieldStatus,
          options:  [
            MapEntry('pending', AppStrings.mountingStatusPending),
            MapEntry('inProgress', AppStrings.mountingStatusInProgress),
            MapEntry('completed', AppStrings.mountingStatusCompleted),
            MapEntry('rework', AppStrings.mountingStatusRework),
          ],
        ),
      ],
      onSubmit: (v) {
        final order = dataProvider.orders.firstWhere(
          (o) => o.id == v['orderId'],
        );
        // The lab job this mounting follows — most recent lab work order
        // on file for the same order, if any (the diagram's Production →
        // Assembly/Mounting arrow).
        final labWorkOrders = dataProvider.labWorkOrders
            .where((w) => w.orderId == v['orderId'])
            .toList();
        dataProvider.addMountingJob(
          MountingJob(
            id: _newId(),
            orderId: v['orderId']!,
            clientId: order.clientId,
            date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
            frameId: v['frameId']!,
            lensId: v['lensId']!,
            status: v['status']!,
            completedDate: v['status'] == 'completed' ? DateTime.now() : null,
            labWorkOrderId:
                labWorkOrders.isEmpty ? null : labWorkOrders.last.id,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allJobs = [...dataProvider.mountingJobs]
      ..sort((a, b) => b.date.compareTo(a.date));
    final jobs = allJobs.where((j) => isInSelectedMonth(j.date)).toList();

    final now = DateTime.now();
    final inProgress = jobs.where((j) => j.status == 'inProgress').length;
    final completedThisMonth = allJobs
        .where(
          (j) =>
              j.status == 'completed' &&
              j.date.year == now.year &&
              j.date.month == now.month,
        )
        .length;
    final rework = jobs.where((j) => j.status == 'rework').length;

    final framesById = {for (final f in dataProvider.frames) f.id: f};
    final lensesById = {for (final l in dataProvider.lenses) l.id: l};
    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navMounting).large().bold()),
              PrimaryButton(
                onPressed: () => _addJob(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.mountingAddButton),
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
                label: AppStrings.mountingKpiTotal,
                value: '${jobs.length}',
                icon: Icons.build_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.mountingKpiInProgress,
                value: '$inProgress',
                icon: Icons.precision_manufacturing_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.mountingKpiCompletedThisMonth,
                value: '$completedThisMonth',
                icon: Icons.check_circle_outline,
                accent: Colors.green.shade700,
              ),
              DashboardStatCard(
                label: AppStrings.mountingKpiRework,
                value: '$rework',
                icon: Icons.warning_amber_outlined,
                accent: colorScheme.destructive,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (jobs.isEmpty)
            EmptyState(
              icon: Icons.build_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final j in jobs)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 300,
                    child: material.InkWell(
                      onTap: () => _showDetail(
                        j,
                        framesById[j.frameId] != null
                            ? '${framesById[j.frameId]!.brand} ${framesById[j.frameId]!.model}'
                            : j.frameId,
                        lensesById[j.lensId]?.productName ?? j.lensId,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: MountingJobCard(
                        job: j,
                        frameLabel: framesById[j.frameId] != null
                            ? '${framesById[j.frameId]!.brand} ${framesById[j.frameId]!.model}'
                            : j.frameId,
                        lensLabel: lensesById[j.lensId]?.productName ?? j.lensId,
                      ),
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
