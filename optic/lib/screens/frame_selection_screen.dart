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
import 'package:optic/models/frame_selection.dart';
import 'package:optic/widgets/frame_selection_card.dart';

/// Module 8 — Frame Selection / Virtual Sale. Every fitting session on
/// file (in-store or virtual try-on), newest first, with how many turned
/// into a pick versus how many are still undecided.
class FrameSelectionScreen extends StatelessWidget {
  const FrameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) =>
          buildAppNavItems(context, NavRoute.frameSelection),
      bodyBuilder: (context, breakpoint) =>
          _FrameSelectionBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _FrameSelectionBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _FrameSelectionBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_FrameSelectionBody> createState() => _FrameSelectionBodyState();
}

class _FrameSelectionBodyState extends State<_FrameSelectionBody> with MonthFilterState<_FrameSelectionBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addSession(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'FS${DateTime.now().millisecondsSinceEpoch}';

  void _addSession(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogFrameSelectionTitle,
      journeyStep: NavRoute.frameSelection,
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
          key: 'method',
          label: AppStrings.recordFieldMethod,
          options:  [
            MapEntry('inStore', AppStrings.frameSelectionMethodInStore),
            MapEntry('virtual', AppStrings.frameSelectionMethodVirtual),
          ],
        ),
        RecordField(
          key: 'selectedFrameId',
          label: AppStrings.recordFieldSelectedFrame,
          required: false,
          initialValue: '',
          options: [
            MapEntry('', AppStrings.cardFrameSelectionUndecided),
            for (final f in dataProvider.frames)
              MapEntry(f.id, '${f.brand} ${f.model}'),
          ],
        ),
        RecordField(
          key: 'notes',
          label: AppStrings.recordFieldNotes,
          required: false,
          maxLines: 3,
        ),
      ],
      onSubmit: (v) => dataProvider.addFrameSelectionSession(
        FrameSelectionSession(
          id: _newId(),
          clientId: v['clientId']!,
          consultationId:
              v['consultationId']!.isEmpty ? null : v['consultationId'],
          date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
          method: v['method']!,
          selectedFrameId: v['selectedFrameId']!.isEmpty
              ? null
              : v['selectedFrameId'],
          notes: v['notes']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allSessions = [...dataProvider.frameSelectionSessions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final sessions =
        allSessions.where((s) => isInSelectedMonth(s.date)).toList();

    final now = DateTime.now();
    final thisMonth = allSessions
        .where((s) => s.date.year == now.year && s.date.month == now.month)
        .length;
    final virtualCount = sessions.where((s) => s.method == 'virtual').length;
    final selectedCount = sessions
        .where((s) => s.selectedFrameId != null)
        .length;

    final clientsById = {for (final p in dataProvider.clients) p.id: p};
    final framesById = {for (final f in dataProvider.frames) f.id: f};
    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 4;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.navFrameSelection).large().bold(),
              ),
              PrimaryButton(
                onPressed: () => _addSession(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.frameSelectionAddButton),
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
                label: AppStrings.frameSelectionKpiTotal,
                value: '${sessions.length}',
                icon: Icons.camera_alt_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.frameSelectionKpiThisMonth,
                value: '$thisMonth',
                icon: Icons.calendar_today_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.frameSelectionKpiVirtual,
                value: '$virtualCount',
                icon: Icons.smartphone_outlined,
                accent: Colors.purple.shade400,
              ),
              DashboardStatCard(
                label: AppStrings.frameSelectionKpiConversion,
                value: sessions.isEmpty
                    ? '0%'
                    : '${(selectedCount / sessions.length * 100).round()}%',
                icon: Icons.check_circle_outline,
                accent: Colors.green.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (sessions.isEmpty)
            EmptyState(
              icon: Icons.camera_alt_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final s in sessions)
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
                            clientsById[s.clientId] != null
                                ? '${clientsById[s.clientId]!.firstName} ${clientsById[s.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ).muted().small(),
                        ),
                        FrameSelectionCard(
                          session: s,
                          selectedFrameLabel: s.selectedFrameId != null
                              ? framesById[s.selectedFrameId] != null
                                    ? '${framesById[s.selectedFrameId]!.brand} ${framesById[s.selectedFrameId]!.model}'
                                    : s.selectedFrameId
                              : null,
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
