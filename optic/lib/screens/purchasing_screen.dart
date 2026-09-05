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
import 'package:optic/models/purchase_order.dart';
import 'package:optic/widgets/purchase_order_card.dart';

String _poStatusLabel(String s) {
  switch (s) {
    case 'sent':
      return AppStrings.poStatusSent;
    case 'confirmed':
      return AppStrings.poStatusConfirmed;
    case 'received':
      return AppStrings.poStatusReceived;
    case 'cancelled':
      return AppStrings.poStatusCancelled;
    case 'draft':
    default:
      return AppStrings.poStatusDraft;
  }
}

/// Module 22 — Purchasing (Procurement). Every purchase order to a
/// [Supplier] on file, newest first — the closing module of the spec's own
/// architecture tree.
class PurchasingScreen extends StatelessWidget {
  const PurchasingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.purchasing),
      bodyBuilder: (context, breakpoint) =>
          _PurchasingBody(breakpoint: breakpoint),
    );
  }
}

class _PurchasingBody extends StatefulWidget {
  final Breakpoint breakpoint;
  const _PurchasingBody({required this.breakpoint});

  @override
  State<_PurchasingBody> createState() => _PurchasingBodyState();
}

class _PurchasingBodyState extends State<_PurchasingBody> with MonthFilterState<_PurchasingBody> {
  String _newId() => 'PO${DateTime.now().millisecondsSinceEpoch}';

  void _showDetail(PurchaseOrder o, String supplierLabel) {
    showRecordDetailDialog(
      context: context,
      title: '${o.totalAmount.toStringAsFixed(0)} MAD',
      subtitle: supplierLabel,
      rows: [
        DetailRow(AppStrings.recordFieldSupplier, supplierLabel),
        DetailRow(AppStrings.cardFieldDate, _formatDate(o.date)),
        DetailRow(AppStrings.recordFieldDescription, o.description),
        DetailRow(AppStrings.recordFieldStatus, _poStatusLabel(o.status)),
        if (o.expectedDate != null)
          DetailRow(AppStrings.recordFieldExpectedDate, _formatDate(o.expectedDate!)),
      ],
      actions: [
        DetailAction(
          label: AppStrings.navSuppliers,
          icon: Icons.storefront_outlined,
          onPressed: () => context.go(NavRoute.suppliers.path),
        ),
      ],
      onDelete: () => context.read<DataProvider>().deletePurchaseOrder(o.id),
    );
  }

  void _addOrder(DataProvider dataProvider) {
    if (dataProvider.suppliers.isEmpty) {
      // Previously silently did nothing here — this record always needs an
      // existing supplier to attach to, so with none yet, tell the user
      // that instead of the button just appearing dead.
      showRecordDetailDialog(
        context: context,
        title: AppStrings.missingDependencyTitle,
        subtitle: AppStrings.missingSupplierDependencyMessage,
        rows: const [],
        actions: [
          DetailAction(
            label: AppStrings.navSuppliers,
            icon: Icons.arrow_forward,
            primary: true,
            onPressed: () => context.go(NavRoute.suppliers.path),
          ),
        ],
      );
      return;
    }
    showAddRecordDialog(
      context: context,
      title: AppStrings.addDialogPurchaseOrderTitle,
      fields: [
        RecordField(
          key: 'supplierId',
          label: AppStrings.recordFieldSupplier,
          options: [
            for (final s in dataProvider.suppliers)
              MapEntry(s.id, s.name),
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
          key: 'orderId',
          label: AppStrings.recordFieldTriggeringOrder,
          required: false,
          options: [
            MapEntry('', AppStrings.recordFieldNoneOption),
            for (final o in dataProvider.orders)
              MapEntry(o.id, '${o.id} — ${o.description}'),
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
          key: 'status',
          label: AppStrings.recordFieldStatus,
          options:  [
            MapEntry('draft', AppStrings.poStatusDraft),
            MapEntry('sent', AppStrings.poStatusSent),
            MapEntry('confirmed', AppStrings.poStatusConfirmed),
            MapEntry('received', AppStrings.poStatusReceived),
            MapEntry('cancelled', AppStrings.poStatusCancelled),
          ],
        ),
        RecordField(
          key: 'expectedDate',
          label: AppStrings.recordFieldExpectedDate,
          hint: 'YYYY-MM-DD',
          required: false,
        ),
      ],
      onSubmit: (v) => dataProvider.addPurchaseOrder(
        PurchaseOrder(
          id: _newId(),
          supplierId: v['supplierId']!,
          date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
          description: v['description']!,
          totalAmount: double.tryParse(v['totalAmount']!) ?? 0,
          status: v['status']!,
          expectedDate: v['expectedDate']!.isEmpty
              ? null
              : DateTime.tryParse(v['expectedDate']!),
          orderId: v['orderId']!.isEmpty ? null : v['orderId'],
          frameId: v['frameId']!.isEmpty ? null : v['frameId'],
          lensId: v['lensId']!.isEmpty ? null : v['lensId'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allOrders = [...dataProvider.purchaseOrders]
      ..sort((a, b) => b.date.compareTo(a.date));
    final orders = allOrders.where((o) => isInSelectedMonth(o.date)).toList();

    final pendingValue = orders
        .where((o) => o.status != 'received' && o.status != 'cancelled')
        .fold<double>(0, (sum, o) => sum + o.totalAmount);
    final received = orders.where((o) => o.status == 'received').length;

    final suppliersById = {for (final s in dataProvider.suppliers) s.id: s};
    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navPurchasing).large().bold()),
              PrimaryButton(
                onPressed: () => _addOrder(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.purchasingAddButton),
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
                label: AppStrings.purchasingKpiTotal,
                value: '${orders.length}',
                icon: Icons.shopping_cart_checkout_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.purchasingKpiPendingValue,
                value: '${pendingValue.toStringAsFixed(0)} MAD',
                icon: Icons.payments_outlined,
                accent: Colors.orange.shade700,
              ),
              DashboardStatCard(
                label: AppStrings.purchasingKpiReceived,
                value: '$received',
                icon: Icons.check_circle_outline,
                accent: Colors.green.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (orders.isEmpty)
            EmptyState(
              icon: Icons.shopping_cart_checkout_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final o in orders)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 320,
                    child: material.InkWell(
                      onTap: () => _showDetail(
                        o,
                        suppliersById[o.supplierId]?.name ?? o.supplierId,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: PurchaseOrderCard(
                        order: o,
                        supplierLabel:
                            suppliersById[o.supplierId]?.name ?? o.supplierId,
                        onSupplierTap: () => context.go(NavRoute.suppliers.path),
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
