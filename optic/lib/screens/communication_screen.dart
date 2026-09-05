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
import 'package:optic/models/communication_log.dart';
import 'package:optic/widgets/communication_log_card.dart';

/// Module 7 — Communication. Cross-client worklist of every call/SMS/
/// WhatsApp/email touchpoint on file, newest first, with how many are
/// flagged for follow-up.
class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    return AppShell(
      navItems: (context) =>
          buildAppNavItems(context, NavRoute.communication),
      bodyBuilder: (context, breakpoint) =>
          _CommunicationBody(breakpoint: breakpoint, openAdd: openAdd, initialClientId: initialClientId),
    );
  }
}

class _CommunicationBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final bool openAdd;
  final String? initialClientId;
  const _CommunicationBody({
    required this.breakpoint,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_CommunicationBody> createState() => _CommunicationBodyState();
}

class _CommunicationBodyState extends State<_CommunicationBody> with MonthFilterState<_CommunicationBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addLog(
          context.read<DataProvider>(),
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  String _newId() => 'COM${DateTime.now().millisecondsSinceEpoch}';

  void _addLog(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogCommunicationTitle,
      journeyStep: NavRoute.communication,
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
        RecordField(key: 'subject', label: AppStrings.recordFieldSubject),
        RecordField(
          key: 'channel',
          label: AppStrings.recordFieldChannel,
          options:  [
            MapEntry('phone', AppStrings.commChannelPhone),
            MapEntry('sms', AppStrings.commChannelSms),
            MapEntry('whatsapp', AppStrings.commChannelWhatsapp),
            MapEntry('email', AppStrings.commChannelEmail),
            MapEntry('inPerson', AppStrings.commChannelInPerson),
          ],
        ),
        RecordField(
          key: 'direction',
          label: AppStrings.recordFieldDirection,
          options:  [
            MapEntry('outbound', AppStrings.commDirectionOutbound),
            MapEntry('inbound', AppStrings.commDirectionInbound),
          ],
        ),
        RecordField(
          key: 'note',
          label: AppStrings.recordFieldNotes,
          required: false,
          maxLines: 3,
        ),
      ],
      onSubmit: (v) => dataProvider.addCommunicationLog(
        CommunicationLog(
          id: _newId(),
          clientId: v['clientId']!,
          date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
          subject: v['subject']!,
          channel: v['channel']!,
          direction: v['direction']!,
          note: v['note']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allLogs = [...dataProvider.communicationLogs]
      ..sort((a, b) => b.date.compareTo(a.date));
    final logs = allLogs.where((l) => isInSelectedMonth(l.date)).toList();

    final now = DateTime.now();
    final thisMonth = allLogs
        .where((l) => l.date.year == now.year && l.date.month == now.month)
        .length;
    final followUps = logs.where((l) => l.followUpRequired).length;

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
                child: Text(AppStrings.navCommunication).large().bold(),
              ),
              PrimaryButton(
                onPressed: () => _addLog(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.communicationAddButton),
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
                label: AppStrings.communicationKpiTotal,
                value: '${logs.length}',
                icon: Icons.forum_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.communicationKpiThisMonth,
                value: '$thisMonth',
                icon: Icons.calendar_today_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.communicationKpiFollowUps,
                value: '$followUps',
                icon: Icons.flag_outlined,
                accent: Colors.orange.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (logs.isEmpty)
            EmptyState(
              icon: Icons.forum_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final l in logs)
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
                            clientsById[l.clientId] != null
                                ? '${clientsById[l.clientId]!.firstName} ${clientsById[l.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ).muted().small(),
                        ),
                        CommunicationLogCard(log: l),
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
