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
import 'package:optic/models/optical_consultation.dart';
import 'package:optic/widgets/optical_consultation_card.dart';

String _screenUsageLabel(String s) {
  switch (s) {
    case 'low':
      return AppStrings.consultationScreenUsageLow;
    case 'high':
      return AppStrings.consultationScreenUsageHigh;
    case 'moderate':
    default:
      return AppStrings.consultationScreenUsageModerate;
  }
}

/// Optical Consultation — the lifestyle/visual-needs intake that follows an
/// [Appointment] and precedes Prescription/Measurement/Frame Selection on
/// the CRM flow diagram. Every consultation on file, newest first.
class ConsultationScreen extends StatelessWidget {
  const ConsultationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.consultation),
      bodyBuilder: (context, breakpoint) =>
          _ConsultationBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _ConsultationBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _ConsultationBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_ConsultationBody> createState() => _ConsultationBodyState();
}

class _ConsultationBodyState extends State<_ConsultationBody> with MonthFilterState<_ConsultationBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addConsultation(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'CON${DateTime.now().millisecondsSinceEpoch}';

  void _showDetail(OpticalConsultation c, String clientName) {
    showRecordDetailDialog(
      context: context,
      title: AppStrings.cardConsultationTitle,
      subtitle: clientName,
      rows: [
        DetailRow(AppStrings.recordFieldClient, clientName),
        DetailRow(AppStrings.cardFieldDate, _formatDate(c.date)),
        if (c.visualNeeds.isNotEmpty)
          DetailRow(AppStrings.consultationFieldVisualNeeds, c.visualNeeds),
        if (c.dailyActivities.isNotEmpty)
          DetailRow(
            AppStrings.consultationFieldDailyActivities,
            c.dailyActivities,
          ),
        DetailRow(
          AppStrings.consultationFieldScreenUsage,
          _screenUsageLabel(c.screenUsage),
        ),
        DetailRow(
          AppStrings.consultationFieldDriving,
          c.driving ? AppStrings.dialogYes : AppStrings.dialogNo,
        ),
        DetailRow(
          AppStrings.consultationFieldReading,
          c.reading ? AppStrings.dialogYes : AppStrings.dialogNo,
        ),
        if (c.workEnvironment.isNotEmpty)
          DetailRow(
            AppStrings.consultationFieldWorkEnvironment,
            c.workEnvironment,
          ),
        if (c.previousProblems.isNotEmpty)
          DetailRow(
            AppStrings.consultationFieldPreviousProblems,
            c.previousProblems,
          ),
      ],
      onDelete: () => context.read<DataProvider>().deleteConsultation(c.id),
    );
  }

  void _addConsultation(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogConsultationTitle,
      journeyStep: NavRoute.consultation,
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
          key: 'visualNeeds',
          label: AppStrings.consultationFieldVisualNeeds,
          required: false,
          maxLines: 2,
        ),
        RecordField(
          key: 'dailyActivities',
          label: AppStrings.consultationFieldDailyActivities,
          required: false,
          maxLines: 2,
        ),
        RecordField(
          key: 'screenUsage',
          label: AppStrings.consultationFieldScreenUsage,
          options: [
            MapEntry('low', AppStrings.consultationScreenUsageLow),
            MapEntry('moderate', AppStrings.consultationScreenUsageModerate),
            MapEntry('high', AppStrings.consultationScreenUsageHigh),
          ],
        ),
        RecordField(
          key: 'driving',
          label: AppStrings.consultationFieldDriving,
          options: [
            MapEntry('false', AppStrings.dialogNo),
            MapEntry('true', AppStrings.dialogYes),
          ],
        ),
        RecordField(
          key: 'reading',
          label: AppStrings.consultationFieldReading,
          options: [
            MapEntry('false', AppStrings.dialogNo),
            MapEntry('true', AppStrings.dialogYes),
          ],
        ),
        RecordField(
          key: 'workEnvironment',
          label: AppStrings.consultationFieldWorkEnvironment,
          required: false,
        ),
        RecordField(
          key: 'previousProblems',
          label: AppStrings.consultationFieldPreviousProblems,
          required: false,
          maxLines: 2,
        ),
      ],
      onSubmit: (v) => dataProvider.addConsultation(
        OpticalConsultation(
          id: _newId(),
          clientId: v['clientId']!,
          date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
          visualNeeds: v['visualNeeds']!,
          dailyActivities: v['dailyActivities']!,
          screenUsage: v['screenUsage']!,
          driving: v['driving'] == 'true',
          reading: v['reading'] == 'true',
          workEnvironment: v['workEnvironment']!,
          previousProblems: v['previousProblems']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allConsultations = [...dataProvider.consultations]
      ..sort((a, b) => b.date.compareTo(a.date));
    final consultations =
        allConsultations.where((c) => isInSelectedMonth(c.date)).toList();

    final now = DateTime.now();
    final thisMonth = allConsultations
        .where((c) => c.date.year == now.year && c.date.month == now.month)
        .length;
    final highScreenUsage =
        consultations.where((c) => c.screenUsage == 'high').length;

    final clientsById = {for (final p in dataProvider.clients) p.id: p};
    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navConsultation).large().bold()),
              PrimaryButton(
                onPressed: () => _addConsultation(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.consultationAddButton),
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
                label: AppStrings.consultationKpiTotal,
                value: '${consultations.length}',
                icon: Icons.psychology_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.consultationKpiThisMonth,
                value: '$thisMonth',
                icon: Icons.calendar_today_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.consultationKpiHighScreenUsage,
                value: '$highScreenUsage',
                icon: Icons.devices_outlined,
                accent: Colors.orange.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (consultations.isEmpty)
            EmptyState(
              icon: Icons.psychology_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in consultations)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 380,
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
                          child: OpticalConsultationCard(consultation: c),
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
