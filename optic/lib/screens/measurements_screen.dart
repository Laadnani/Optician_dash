import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/empty_state.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/helpers/record_detail_dialog.dart';
import 'package:optic/helpers/add_record_dialog.dart';
import 'package:optic/helpers/month_filter_bar.dart';
import 'package:optic/helpers/stat_card.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/measurement.dart';
import 'package:optic/widgets/measurement_card.dart';

/// Module 3 — Visual / Optical Measurements. Same cross-client worklist
/// shape as `PrescriptionsScreen`: every measurement session on file,
/// newest first, plus how many were taken this month and a breakdown of
/// which method was used to take them (manual vs. digital equipment).
class MeasurementsScreen extends StatelessWidget {
  const MeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.measurements),
      bodyBuilder: (context, breakpoint) =>
          _MeasurementsBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _MeasurementsBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _MeasurementsBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_MeasurementsBody> createState() => _MeasurementsBodyState();
}

class _MeasurementsBodyState extends State<_MeasurementsBody> with MonthFilterState<_MeasurementsBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addMeasurement(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'MS${DateTime.now().millisecondsSinceEpoch}';

  void _addMeasurement(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogMeasurementTitle,
      journeyStep: NavRoute.measurements,
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
          key: 'consultationId',
          label: AppStrings.recordFieldLinkedConsultation,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final c in dataProvider.consultations)
              MapEntry(c.id, '${c.id} — ${_formatDate(c.date)}'),
          ],
        ),
        RecordField(
          key: 'pd',
          label: AppStrings.recordFieldPdMm,
          initialValue: '63',
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'fittingHeight',
          label: AppStrings.cardMeasurementFittingHeight,
          initialValue: '20',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'bridge',
          label: AppStrings.recordFieldBridgeMm,
          initialValue: '18',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'templeLength',
          label: AppStrings.recordFieldTempleLengthMm,
          initialValue: '140',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'vertexDistance',
          label: AppStrings.cardMeasurementVertexDistance,
          initialValue: '12',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'method',
          label: AppStrings.cardMeasurementMethod,
          options:  [
            MapEntry('manual', AppStrings.measurementMethodManual),
            MapEntry('pupillometer', AppStrings.measurementMethodPupillometer),
            MapEntry(
              'digitalCentration',
              AppStrings.measurementMethodDigitalCentration,
            ),
            MapEntry('opticalScanner', AppStrings.measurementMethodOpticalScanner),
            MapEntry('imported', AppStrings.measurementMethodImported),
          ],
        ),
        RecordField(
          key: 'operator',
          label: AppStrings.cardMeasurementOperator,
        ),
      ],
      onSubmit: (v) => dataProvider.addMeasurement(
        Measurement(
          id: _newId(),
          clientId: v['clientId']!,
          consultationId:
              v['consultationId']!.isEmpty ? null : v['consultationId'],
          date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
          pd: double.tryParse(v['pd']!) ?? 0,
          fittingHeight: double.tryParse(v['fittingHeight']!) ?? 0,
          bridge: double.tryParse(v['bridge']!) ?? 0,
          templeLength: double.tryParse(v['templeLength']!) ?? 0,
          vertexDistance: double.tryParse(v['vertexDistance']!) ?? 0,
          method: v['method']!,
          operator: v['operator']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allMeasurements = [...dataProvider.measurements]
      ..sort((a, b) => b.date.compareTo(a.date));
    final measurements =
        allMeasurements.where((m) => isInSelectedMonth(m.date)).toList();

    final now = DateTime.now();
    final thisMonth = allMeasurements
        .where((m) => m.date.year == now.year && m.date.month == now.month)
        .length;
    final digital = measurements
        .where(
          (m) =>
              m.method == 'digitalCentration' ||
              m.method == 'pupillometer' ||
              m.method == 'opticalScanner',
        )
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
              Expanded(child: Text(AppStrings.navMeasurements).large().bold()),
              PrimaryButton(
                onPressed: () => _addMeasurement(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.measurementsAddButton),
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
                label: AppStrings.measurementsKpiTotal,
                value: '${measurements.length}',
                icon: Icons.straighten_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.measurementsKpiThisMonth,
                value: '$thisMonth',
                icon: Icons.calendar_today_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.measurementsKpiDigital,
                value: '$digital',
                icon: Icons.precision_manufacturing_outlined,
                accent: Colors.teal.shade600,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (measurements.isEmpty)
            EmptyState(
              icon: Icons.straighten_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final m in measurements)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile ? double.infinity : 380,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            clientsById[m.clientId] != null
                                ? '${clientsById[m.clientId]!.firstName} ${clientsById[m.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ).muted().small(),
                        ),
                        MeasurementCard(measurement: m),
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
