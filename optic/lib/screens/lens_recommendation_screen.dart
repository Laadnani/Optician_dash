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
import 'package:optic/models/lens_recommendation.dart';
import 'package:optic/widgets/lens_recommendation_card.dart';

/// Module 9 — Lens Recommendation (Optical Consultation). Every lens-type/
/// coating recommendation on file, newest first, with the acceptance rate
/// an optician actually watches.
class LensRecommendationScreen extends StatelessWidget {
  const LensRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) =>
          buildAppNavItems(context, NavRoute.lensRecommendation),
      bodyBuilder: (context, breakpoint) =>
          _LensRecommendationBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _LensRecommendationBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _LensRecommendationBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_LensRecommendationBody> createState() =>
      _LensRecommendationBodyState();
}

class _LensRecommendationBodyState extends State<_LensRecommendationBody> with MonthFilterState<_LensRecommendationBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addRecommendation(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'LR${DateTime.now().millisecondsSinceEpoch}';

  void _addRecommendation(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogLensRecommendationTitle,
      journeyStep: NavRoute.lensRecommendation,
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
          key: 'frameSelectionId',
          label: AppStrings.recordFieldLinkedFrameSelection,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final s in dataProvider.frameSelectionSessions)
              MapEntry(s.id, '${s.id} — ${_formatDate(s.date)}'),
          ],
        ),
        RecordField(
          key: 'recommendedLensType',
          label: AppStrings.lensFieldType,
          options:  [
            MapEntry('singleVision', AppStrings.lensTypeSingleVision),
            MapEntry('bifocal', AppStrings.lensTypeBifocal),
            MapEntry('progressive', AppStrings.lensTypeProgressive),
            MapEntry('occupational', AppStrings.lensTypeOccupational),
            MapEntry('computer', AppStrings.lensTypeComputer),
            MapEntry('myopiaControl', AppStrings.lensTypeMyopiaControl),
            MapEntry('sunglasses', AppStrings.lensTypeSunglasses),
            MapEntry('specialty', AppStrings.lensTypeSpecialty),
          ],
        ),
        RecordField(
          key: 'reason',
          label: AppStrings.recordFieldReason,
          required: false,
          maxLines: 2,
        ),
        RecordField(
          key: 'accepted',
          label: AppStrings.recordFieldAccepted,
          options:  [
            MapEntry('false', AppStrings.cardLensRecPending),
            MapEntry('true', AppStrings.cardLensRecAccepted),
          ],
        ),
      ],
      onSubmit: (v) => dataProvider.addLensRecommendation(
        LensRecommendation(
          id: _newId(),
          clientId: v['clientId']!,
          date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
          prescriptionId:
              v['prescriptionId']!.isEmpty ? null : v['prescriptionId'],
          measurementId:
              v['measurementId']!.isEmpty ? null : v['measurementId'],
          frameSelectionId: v['frameSelectionId']!.isEmpty
              ? null
              : v['frameSelectionId'],
          recommendedLensType: v['recommendedLensType']!,
          reason: v['reason']!,
          accepted: v['accepted'] == 'true',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allRecommendations = [...dataProvider.lensRecommendations]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recommendations = allRecommendations
        .where((r) => isInSelectedMonth(r.date))
        .toList();

    final now = DateTime.now();
    final thisMonth = allRecommendations
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .length;
    final accepted = recommendations.where((r) => r.accepted).length;

    final clientsById = {for (final p in dataProvider.clients) p.id: p};
    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.navLensRecommendation).large().bold(),
              ),
              PrimaryButton(
                onPressed: () => _addRecommendation(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.lensRecommendationAddButton),
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
                label: AppStrings.lensRecommendationKpiTotal,
                value: '${recommendations.length}',
                icon: Icons.medical_services_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.lensRecommendationKpiThisMonth,
                value: '$thisMonth',
                icon: Icons.calendar_today_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.lensRecommendationKpiAcceptanceRate,
                value: recommendations.isEmpty
                    ? '0%'
                    : '${(accepted / recommendations.length * 100).round()}%',
                icon: Icons.check_circle_outline,
                accent: Colors.green.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recommendations.isEmpty)
            EmptyState(
              icon: Icons.medical_services_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final r in recommendations)
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
                            clientsById[r.clientId] != null
                                ? '${clientsById[r.clientId]!.firstName} ${clientsById[r.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ).muted().small(),
                        ),
                        LensRecommendationCard(recommendation: r),
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
