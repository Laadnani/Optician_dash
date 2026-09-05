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
import 'package:optic/models/order.dart';
import 'package:optic/models/quote.dart';
import 'package:optic/widgets/quote_card.dart';

String _quoteStatusLabel(String status) {
  switch (status) {
    case 'sent':
      return AppStrings.quoteStatusSent;
    case 'accepted':
      return AppStrings.quoteStatusAccepted;
    case 'declined':
      return AppStrings.quoteStatusDeclined;
    case 'expired':
      return AppStrings.quoteStatusExpired;
    case 'draft':
    default:
      return AppStrings.quoteStatusDraft;
  }
}

/// Module 11 — Quotes / Estimates. Every priced proposal on file, newest
/// first, with the metrics that matter before it becomes an [Order]: how
/// many were accepted, and how much is still sitting pending/sent.
class QuotesScreen extends StatelessWidget {
  const QuotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // When arriving from a client file's "New quote" quick action (see
    // `client_file_screen.dart`), `extra` carries that client's id so the
    // Add-quote dialog can open pre-scoped to them instead of landing on an
    // empty list with no indication why you're here.
    final extra = GoRouterState.of(context).extra;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;
    final openAdd = extra is Map && extra['openAdd'] == true;
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.quotes),
      bodyBuilder: (context, breakpoint) => _QuotesBody(
        breakpoint: breakpoint,
        initialClientId: initialClientId,
        openAdd: openAdd,
      ),
    );
  }
}

class _QuotesBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final String? initialClientId;
  final bool openAdd;
  const _QuotesBody({
    required this.breakpoint,
    this.initialClientId,
    this.openAdd = false,
  });

  @override
  State<_QuotesBody> createState() => _QuotesBodyState();
}

class _QuotesBodyState extends State<_QuotesBody> with MonthFilterState<_QuotesBody> {
  String _newId() => 'QT${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    if (widget.initialClientId != null || widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _addQuote(context.read<DataProvider>(), initialClientId: widget.initialClientId);
      });
    }
  }

  void _showDetail(Quote q, String clientName, DataProvider dataProvider) {
    final alreadyConverted = dataProvider.orders.any((o) => o.quoteId == q.id);
    showRecordDetailDialog(
      context: context,
      title: '${q.totalAmount.toStringAsFixed(0)} MAD',
      subtitle: clientName,
      rows: [
        DetailRow(AppStrings.recordFieldClient, clientName),
        DetailRow(AppStrings.cardFieldDate, _formatDate(q.date)),
        DetailRow(AppStrings.recordFieldDescription, q.description),
        DetailRow(AppStrings.recordFieldStatus, _quoteStatusLabel(q.status)),
        if (q.validUntil != null)
          DetailRow(AppStrings.recordFieldValidUntil, _formatDate(q.validUntil!)),
      ],
      actions: [
        if (q.status == 'accepted' && !alreadyConverted)
          DetailAction(
            label: AppStrings.quoteConvertToOrder,
            icon: Icons.arrow_forward,
            primary: true,
            onPressed: () => _convertToOrder(dataProvider, q),
          ),
      ],
      onDelete: () => dataProvider.deleteQuote(q.id),
    );
  }

  void _convertToOrder(DataProvider dataProvider, Quote quote) {
    dataProvider.addOrder(
      Order(
        id: 'ORD${DateTime.now().millisecondsSinceEpoch}',
        clientId: quote.clientId,
        date: DateTime.now(),
        quoteId: quote.id,
        description: quote.description,
        totalAmount: quote.totalAmount,
        status: 'pending',
        // Carried straight over from the quote — this is what keeps the
        // order's clinical/product record chain intact instead of Orders
        // being just a free-text total, per the CRM flow diagram.
        prescriptionId: quote.prescriptionId,
        measurementId: quote.measurementId,
        frameId: quote.frameId,
        lensId: quote.lensId,
        accessoryId: quote.accessoryId,
      ),
    );
    // Reserving stock is the diagram's "Frame Stock: Reserve / Deduct
    // stock" step — happens the moment an order commits to a specific
    // frame, not later at delivery.
    if (quote.frameId != null) {
      final frameIndex = dataProvider.frames.indexWhere(
        (f) => f.id == quote.frameId,
      );
      if (frameIndex != -1) {
        final frame = dataProvider.frames[frameIndex];
        if (frame.stockAvailable > 0) {
          dataProvider.updateFrame(
            frame.copyWith(
              stockAvailable: frame.stockAvailable - 1,
              stockReserved: frame.stockReserved + 1,
            ),
          );
        }
      }
    }
    material.ScaffoldMessenger.of(context).showSnackBar(
      material.SnackBar(content: Text(AppStrings.quoteConvertedSnackbar)),
    );
    context.go(NavRoute.orders.path);
  }

  void _addQuote(DataProvider dataProvider, {String? initialClientId}) {
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
      title: AppStrings.addDialogQuoteTitle,
      journeyStep: NavRoute.quotes,
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
          key: 'description',
          label: AppStrings.recordFieldDescription,
          maxLines: 2,
        ),
        RecordField(
          key: 'totalAmount',
          label: AppStrings.recordFieldAmount,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'lensRecommendationId',
          label: AppStrings.recordFieldLinkedLensRecommendation,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final r in dataProvider.lensRecommendations)
              MapEntry(r.id, '${r.id} — ${_formatDate(r.date)}'),
          ],
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
          key: 'frameId',
          label: AppStrings.recordFieldFrame,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final f in dataProvider.frames)
              MapEntry(f.id, '${f.brand} ${f.model}'),
          ],
        ),
        RecordField(
          key: 'lensId',
          label: AppStrings.recordFieldLens,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final l in dataProvider.lenses)
              MapEntry(l.id, l.productName),
          ],
        ),
        RecordField(
          key: 'accessoryId',
          label: AppStrings.recordFieldLinkedAccessory,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final a in dataProvider.accessories)
              MapEntry(a.id, a.name),
          ],
        ),
        RecordField(
          key: 'status',
          label: AppStrings.recordFieldStatus,
          options:  [
            MapEntry('draft', AppStrings.quoteStatusDraft),
            MapEntry('sent', AppStrings.quoteStatusSent),
            MapEntry('accepted', AppStrings.quoteStatusAccepted),
            MapEntry('declined', AppStrings.quoteStatusDeclined),
            MapEntry('expired', AppStrings.quoteStatusExpired),
          ],
        ),
        RecordField(
          key: 'validUntil',
          label: AppStrings.recordFieldValidUntil,
          hint: 'YYYY-MM-DD',
          required: false,
        ),
      ],
      onSubmit: (v) => dataProvider.addQuote(
        Quote(
          id: _newId(),
          clientId: v['clientId']!,
          date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
          description: v['description']!,
          totalAmount: double.tryParse(v['totalAmount']!) ?? 0,
          status: v['status']!,
          validUntil: v['validUntil']!.isEmpty
              ? null
              : DateTime.tryParse(v['validUntil']!),
          lensRecommendationId: v['lensRecommendationId']!.isEmpty
              ? null
              : v['lensRecommendationId'],
          prescriptionId:
              v['prescriptionId']!.isEmpty ? null : v['prescriptionId'],
          measurementId:
              v['measurementId']!.isEmpty ? null : v['measurementId'],
          frameId: v['frameId']!.isEmpty ? null : v['frameId'],
          lensId: v['lensId']!.isEmpty ? null : v['lensId'],
          accessoryId: v['accessoryId']!.isEmpty ? null : v['accessoryId'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allQuotes = [...dataProvider.quotes]
      ..sort((a, b) => b.date.compareTo(a.date));
    final quotes = allQuotes.where((q) => isInSelectedMonth(q.date)).toList();

    // "This month" always anchors to the real calendar month (unaffected by
    // browsing a different month below), so it stays a useful fixed
    // reference point even while "Total"/"Accepted"/"Pending value" track
    // whichever month is currently selected.
    final now = DateTime.now();
    final thisMonth = allQuotes
        .where((q) => q.date.year == now.year && q.date.month == now.month)
        .length;
    final accepted = quotes.where((q) => q.status == 'accepted').length;
    final pendingValue = quotes
        .where((q) => q.status == 'draft' || q.status == 'sent')
        .fold<double>(0, (sum, q) => sum + q.totalAmount);

    final clientsById = {for (final p in dataProvider.clients) p.id: p};
    final convertedQuoteIds = dataProvider.orders
        .where((o) => o.quoteId != null)
        .map((o) => o.quoteId)
        .toSet();
    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 4;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navQuotes).large().bold()),
              PrimaryButton(
                onPressed: () => _addQuote(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.quotesAddButton),
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
                label: AppStrings.quotesKpiTotal,
                value: '${quotes.length}',
                icon: Icons.request_quote_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.quotesKpiThisMonth,
                value: '$thisMonth',
                icon: Icons.calendar_today_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.quotesKpiAccepted,
                value: '$accepted',
                icon: Icons.check_circle_outline,
                accent: Colors.green.shade700,
              ),
              DashboardStatCard(
                label: AppStrings.quotesKpiPendingValue,
                value: '${pendingValue.toStringAsFixed(0)} MAD',
                icon: Icons.payments_outlined,
                accent: Colors.orange.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (quotes.isEmpty)
            EmptyState(
              icon: Icons.request_quote_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final q in quotes)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 340,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            clientsById[q.clientId] != null
                                ? '${clientsById[q.clientId]!.firstName} ${clientsById[q.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ).muted().small(),
                        ),
                        material.InkWell(
                          onTap: () => _showDetail(
                            q,
                            clientsById[q.clientId] != null
                                ? '${clientsById[q.clientId]!.firstName} ${clientsById[q.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                            dataProvider,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: QuoteCard(
                            quote: q,
                            alreadyConverted: convertedQuoteIds.contains(q.id),
                            onConvertToOrder: q.status == 'accepted'
                                ? () => _convertToOrder(dataProvider, q)
                                : null,
                          ),
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
