import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/empty_state.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/helpers/record_action_menu.dart';
import 'package:optic/helpers/record_detail_dialog.dart';
import 'package:optic/helpers/add_record_dialog.dart';
import 'package:optic/helpers/month_filter_bar.dart';
import 'package:optic/helpers/stat_card.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/prescription.dart';
import 'package:optic/widgets/prescription_card.dart';

String _prescriptionTypeLabel(String type) {
  switch (type) {
    case 'reading':
      return AppStrings.prescriptionTypeReading;
    case 'progressive':
      return AppStrings.prescriptionTypeProgressive;
    case 'occupational':
      return AppStrings.prescriptionTypeOccupational;
    case 'contactLens':
      return AppStrings.prescriptionTypeContactLens;
    case 'distance':
    default:
      return AppStrings.prescriptionTypeDistance;
  }
}

/// Module 2 — Optical Prescription Management. A cross-client worklist
/// (every prescription on file, newest first) plus the metrics an optician
/// actually checks day to day: how many are on file, how many are expiring
/// soon, how many already lapsed. Per-client prescriptions still show on
/// that client's own file too (see `client_file_screen.dart`'s
/// Prescriptions tab) — this screen is the store-wide view across everyone.
class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) =>
          buildAppNavItems(context, NavRoute.prescriptions),
      bodyBuilder: (context, breakpoint) =>
          _PrescriptionsBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _PrescriptionsBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _PrescriptionsBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_PrescriptionsBody> createState() => _PrescriptionsBodyState();
}

class _PrescriptionsBodyState extends State<_PrescriptionsBody> with MonthFilterState<_PrescriptionsBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addPrescription(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'RX${DateTime.now().millisecondsSinceEpoch}';

  void _addPrescription(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogPrescriptionTitle,
      journeyStep: NavRoute.prescriptions,
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
          key: 'expirationDate',
          label: AppStrings.cardPrescriptionExpires,
          hint: 'YYYY-MM-DD',
          required: false,
          initialValue: _formatDate(
            DateTime.now().add(const Duration(days: 365)),
          ),
        ),
        RecordField(
          key: 'type',
          label: AppStrings.prescriptionFieldType,
          options:  [
            MapEntry('distance', AppStrings.prescriptionTypeDistance),
            MapEntry('reading', AppStrings.prescriptionTypeReading),
            MapEntry('progressive', AppStrings.prescriptionTypeProgressive),
            MapEntry('occupational', AppStrings.prescriptionTypeOccupational),
            MapEntry('contactLens', AppStrings.prescriptionTypeContactLens),
          ],
        ),
        RecordField(
          key: 'sphOD',
          label: AppStrings.recordFieldSphOD,
          initialValue: '0',
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'cylOD',
          label: AppStrings.recordFieldCylOD,
          initialValue: '0',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'axisOD',
          label: AppStrings.recordFieldAxisOD,
          initialValue: '0',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'sphOS',
          label: AppStrings.recordFieldSphOS,
          initialValue: '0',
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'cylOS',
          label: AppStrings.recordFieldCylOS,
          initialValue: '0',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'axisOS',
          label: AppStrings.recordFieldAxisOS,
          initialValue: '0',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'pd',
          label: AppStrings.recordFieldPdMm,
          initialValue: '63',
          keyboardType: material.TextInputType.number,
        ),
      ],
      onSubmit: (v) => dataProvider.addPrescription(
        Prescription(
          id: _newId(),
          clientId: v['clientId']!,
          consultationId:
              v['consultationId']!.isEmpty ? null : v['consultationId'],
          date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
          expirationDate: v['expirationDate']!.isEmpty
              ? null
              : DateTime.tryParse(v['expirationDate']!),
          type: v['type']!,
          sphOD: double.tryParse(v['sphOD']!) ?? 0,
          cylOD: double.tryParse(v['cylOD']!) ?? 0,
          axisOD: int.tryParse(v['axisOD']!) ?? 0,
          sphOS: double.tryParse(v['sphOS']!) ?? 0,
          cylOS: double.tryParse(v['cylOS']!) ?? 0,
          axisOS: int.tryParse(v['axisOS']!) ?? 0,
          pd: double.tryParse(v['pd']!) ?? 0,
        ),
      ),
    );
  }

  void _showDetail(
    Prescription p,
    String clientName,
    DataProvider dataProvider,
  ) {
    showRecordDetailDialog(
      context: context,
      title: '${AppStrings.cardPrescriptionTitle} — ${_formatDate(p.date)}',
      subtitle: clientName,
      rows: [
        DetailRow(AppStrings.recordFieldClient, clientName),
        DetailRow(AppStrings.prescriptionFieldType, _prescriptionTypeLabel(p.type)),
        if (p.expirationDate != null)
          DetailRow(AppStrings.cardPrescriptionExpires, _formatDate(p.expirationDate!)),
        DetailRow(
          AppStrings.recordFieldSphOD,
          '${p.sphOD}  ${AppStrings.recordFieldCylOD} ${p.cylOD}  ${AppStrings.recordFieldAxisOD} ${p.axisOD}',
        ),
        DetailRow(
          AppStrings.recordFieldSphOS,
          '${p.sphOS}  ${AppStrings.recordFieldCylOS} ${p.cylOS}  ${AppStrings.recordFieldAxisOS} ${p.axisOS}',
        ),
        DetailRow(AppStrings.recordFieldPdMm, '${p.pd}'),
        if (p.notes.isNotEmpty)
          DetailRow(AppStrings.recordFieldNotes, p.notes),
      ],
      onDelete: () => dataProvider.deletePrescription(p.id),
    );
  }

  void _editPrescription(Prescription p, DataProvider dataProvider) {
    showAddRecordDialog(
      context: context,
      title: AppStrings.editDialogPrescriptionTitle,
      journeyStep: NavRoute.prescriptions,
      fields: [
        RecordField(
          key: 'clientId',
          label: AppStrings.recordFieldClient,
          initialValue: p.clientId,
          options: [
            for (final c in dataProvider.clients)
              MapEntry(c.id, '${c.firstName} ${c.lastName}'),
          ],
        ),
        RecordField(
          key: 'date',
          label: AppStrings.cardFieldDate,
          hint: 'YYYY-MM-DD',
          initialValue: _formatDate(p.date),
        ),
        RecordField(
          key: 'consultationId',
          label: AppStrings.recordFieldLinkedConsultation,
          required: false,
          initialValue: p.consultationId ?? '',
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final c in dataProvider.consultations)
              MapEntry(c.id, '${c.id} — ${_formatDate(c.date)}'),
          ],
        ),
        RecordField(
          key: 'expirationDate',
          label: AppStrings.cardPrescriptionExpires,
          hint: 'YYYY-MM-DD',
          required: false,
          initialValue: p.expirationDate != null ? _formatDate(p.expirationDate!) : '',
        ),
        RecordField(
          key: 'type',
          label: AppStrings.prescriptionFieldType,
          initialValue: p.type,
          options: [
            MapEntry('distance', AppStrings.prescriptionTypeDistance),
            MapEntry('reading', AppStrings.prescriptionTypeReading),
            MapEntry('progressive', AppStrings.prescriptionTypeProgressive),
            MapEntry('occupational', AppStrings.prescriptionTypeOccupational),
            MapEntry('contactLens', AppStrings.prescriptionTypeContactLens),
          ],
        ),
        RecordField(
          key: 'sphOD',
          label: AppStrings.recordFieldSphOD,
          initialValue: '${p.sphOD}',
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'cylOD',
          label: AppStrings.recordFieldCylOD,
          initialValue: '${p.cylOD}',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'axisOD',
          label: AppStrings.recordFieldAxisOD,
          initialValue: '${p.axisOD}',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'sphOS',
          label: AppStrings.recordFieldSphOS,
          initialValue: '${p.sphOS}',
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'cylOS',
          label: AppStrings.recordFieldCylOS,
          initialValue: '${p.cylOS}',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'axisOS',
          label: AppStrings.recordFieldAxisOS,
          initialValue: '${p.axisOS}',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'pd',
          label: AppStrings.recordFieldPdMm,
          initialValue: '${p.pd}',
          keyboardType: material.TextInputType.number,
        ),
      ],
      onSubmit: (v) => dataProvider.updatePrescription(
        Prescription(
          id: p.id,
          clientId: v['clientId']!,
          consultationId:
              v['consultationId']!.isEmpty ? null : v['consultationId'],
          date: DateTime.tryParse(v['date']!) ?? p.date,
          expirationDate: v['expirationDate']!.isEmpty
              ? null
              : DateTime.tryParse(v['expirationDate']!),
          type: v['type']!,
          sphOD: double.tryParse(v['sphOD']!) ?? 0,
          cylOD: double.tryParse(v['cylOD']!) ?? 0,
          axisOD: int.tryParse(v['axisOD']!) ?? 0,
          addOD: p.addOD,
          visualAcuityOD: p.visualAcuityOD,
          sphOS: double.tryParse(v['sphOS']!) ?? 0,
          cylOS: double.tryParse(v['cylOS']!) ?? 0,
          axisOS: int.tryParse(v['axisOS']!) ?? 0,
          addOS: p.addOS,
          visualAcuityOS: p.visualAcuityOS,
          pd: double.tryParse(v['pd']!) ?? 0,
          dominantEye: p.dominantEye,
          notes: p.notes,
        ),
      ),
    );
  }

  void _showActionMenu(
    Prescription p,
    String clientName,
    DataProvider dataProvider,
  ) {
    showRecordActionMenu(
      context: context,
      title: '${AppStrings.cardPrescriptionTitle} — ${_formatDate(p.date)}',
      subtitle: clientName,
      onViewDetails: () => _showDetail(p, clientName, dataProvider),
      onGoToClient: () => context.go('/clients/${p.clientId}'),
      onEdit: () => _editPrescription(p, dataProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allPrescriptions = [...dataProvider.prescriptions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final prescriptions =
        allPrescriptions.where((p) => isInSelectedMonth(p.date)).toList();

    final now = DateTime.now();
    final expiringSoon = prescriptions.where((p) {
      final exp = p.expirationDate;
      if (exp == null) return false;
      final daysLeft = exp.difference(now).inDays;
      return daysLeft >= 0 && daysLeft <= 30;
    }).length;
    final expired = prescriptions
        .where((p) => p.expirationDate != null && p.expirationDate!.isBefore(now))
        .length;
    final thisMonth = allPrescriptions
        .where((p) => p.date.year == now.year && p.date.month == now.month)
        .length;

    final clientsById = {
      for (final p in dataProvider.clients) p.id: p,
    };

    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navPrescriptions).large().bold()),
              PrimaryButton(
                onPressed: () => _addPrescription(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.prescriptionsAddButton),
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
                label: AppStrings.prescriptionsKpiTotal,
                value: '${prescriptions.length}',
                icon: Icons.assignment_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.prescriptionsKpiThisMonth,
                value: '$thisMonth',
                icon: Icons.calendar_today_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.prescriptionsKpiExpiringSoon,
                value: '$expiringSoon',
                icon: Icons.warning_amber_outlined,
                accent: Colors.orange.shade700,
              ),
              DashboardStatCard(
                label: AppStrings.prescriptionsKpiExpired,
                value: '$expired',
                icon: Icons.event_busy_outlined,
                accent: colorScheme.destructive,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (prescriptions.isEmpty)
            EmptyState(
              icon: Icons.assignment_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final p in prescriptions)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile ? double.infinity : 380,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            clientsById[p.clientId] != null
                                ? '${clientsById[p.clientId]!.firstName} ${clientsById[p.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ).muted().small(),
                        ),
                        material.InkWell(
                          onTap: () => _showActionMenu(
                            p,
                            clientsById[p.clientId] != null
                                ? '${clientsById[p.clientId]!.firstName} ${clientsById[p.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                            dataProvider,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: PrescriptionCard(prescription: p),
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
