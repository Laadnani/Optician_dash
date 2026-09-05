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
import 'package:optic/widgets/final_fitting_card.dart';

String _fittingTypeLabel(String s) {
  switch (s) {
    case 'templeLength':
      return AppStrings.fittingTypeTempleLength;
    case 'frameAlignment':
      return AppStrings.fittingTypeFrameAlignment;
    case 'lensPosition':
      return AppStrings.fittingTypeLensPosition;
    case 'other':
      return AppStrings.fittingTypeOther;
    case 'nosePads':
    default:
      return AppStrings.fittingTypeNosePads;
  }
}

/// Module 16 — Final Fitting (Client Delivery). Every in-person
/// adjustment session on file, newest first, with the average comfort
/// rating clients report right after.
class FinalFittingScreen extends StatelessWidget {
  const FinalFittingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.finalFitting),
      bodyBuilder: (context, breakpoint) =>
          _FinalFittingBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _FinalFittingBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _FinalFittingBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_FinalFittingBody> createState() => _FinalFittingBodyState();
}

class _FinalFittingBodyState extends State<_FinalFittingBody> with MonthFilterState<_FinalFittingBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addFitting(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'FF${DateTime.now().millisecondsSinceEpoch}';

  void _showDetail(FinalFitting f) {
    showRecordDetailDialog(
      context: context,
      title: _fittingTypeLabel(f.adjustmentType),
      subtitle: f.orderId,
      rows: [
        DetailRow(AppStrings.recordFieldOrderId, f.orderId),
        DetailRow(AppStrings.cardFieldDate, _formatDate(f.date)),
        DetailRow(
          AppStrings.recordFieldAdjustmentType,
          _fittingTypeLabel(f.adjustmentType),
        ),
        DetailRow(AppStrings.recordFieldComfortRating, '${f.comfortRating}/5'),
        if (f.notes.isNotEmpty) DetailRow(AppStrings.recordFieldNotes, f.notes),
      ],
      onDelete: () => context.read<DataProvider>().deleteFinalFitting(f.id),
    );
  }

  void _addFitting(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogFinalFittingTitle,
      journeyStep: NavRoute.finalFitting,
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
          key: 'adjustmentType',
          label: AppStrings.recordFieldAdjustmentType,
          options:  [
            MapEntry('nosePads', AppStrings.fittingTypeNosePads),
            MapEntry('templeLength', AppStrings.fittingTypeTempleLength),
            MapEntry('frameAlignment', AppStrings.fittingTypeFrameAlignment),
            MapEntry('lensPosition', AppStrings.fittingTypeLensPosition),
            MapEntry('other', AppStrings.fittingTypeOther),
          ],
        ),
        RecordField(
          key: 'comfortRating',
          label: AppStrings.recordFieldComfortRating,
          initialValue: '5',
          keyboardType: material.TextInputType.number,
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
        final passingChecks = dataProvider.qualityChecks
            .where(
              (c) =>
                  c.orderId == v['orderId'] &&
                  (c.result == 'pass' || c.result == 'conditionalPass'),
            )
            .toList();
        dataProvider.addFinalFitting(
          FinalFitting(
            id: _newId(),
            orderId: v['orderId']!,
            clientId: order.clientId,
            date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
            adjustmentType: v['adjustmentType']!,
            comfortRating: int.tryParse(v['comfortRating']!) ?? 5,
            notes: v['notes']!,
            qualityCheckId:
                passingChecks.isEmpty ? null : passingChecks.last.id,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allFittings = [...dataProvider.finalFittings]
      ..sort((a, b) => b.date.compareTo(a.date));
    final fittings = allFittings.where((f) => isInSelectedMonth(f.date)).toList();

    final now = DateTime.now();
    final thisMonth = allFittings
        .where((f) => f.date.year == now.year && f.date.month == now.month)
        .length;
    final avgComfort = fittings.isEmpty
        ? 0.0
        : fittings.fold<int>(0, (sum, f) => sum + f.comfortRating) /
            fittings.length;

    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.navFinalFitting).large().bold(),
              ),
              PrimaryButton(
                onPressed: () => _addFitting(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.finalFittingAddButton),
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
                label: AppStrings.finalFittingKpiTotal,
                value: '${fittings.length}',
                icon: Icons.tune_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.finalFittingKpiThisMonth,
                value: '$thisMonth',
                icon: Icons.calendar_today_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.finalFittingKpiAvgComfort,
                value: '${avgComfort.toStringAsFixed(1)}/5',
                icon: Icons.sentiment_satisfied_outlined,
                accent: Colors.green.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (fittings.isEmpty)
            EmptyState(
              icon: Icons.tune_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final f in fittings)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 300,
                    child: material.InkWell(
                      onTap: () => _showDetail(f),
                      borderRadius: BorderRadius.circular(12),
                      child: FinalFittingCard(fitting: f),
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
