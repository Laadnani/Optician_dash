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
import 'package:optic/helpers/heartbeat_highlight.dart';
import 'package:optic/helpers/record_detail_dialog.dart';
import 'package:optic/helpers/stat_card.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/contact_lens.dart';
import 'package:optic/widgets/contact_lens_card.dart';

/// Module 6 — Contact Lens Management. Two halves on one screen, matching
/// the spec's own split: the store's sellable product catalog/stock (top),
/// and every client's active contact lens prescription on file (bottom) —
/// the same "worklist" shape `PrescriptionsScreen`/`MeasurementsScreen` use
/// for their client-scoped records.
class ContactLensesScreen extends StatelessWidget {
  const ContactLensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.contactLenses),
      bodyBuilder: (context, breakpoint) =>
          _ContactLensesBody(breakpoint: breakpoint),
    );
  }
}

class _ContactLensesBody extends StatefulWidget {
  final Breakpoint breakpoint;
  const _ContactLensesBody({required this.breakpoint});

  @override
  State<_ContactLensesBody> createState() => _ContactLensesBodyState();
}

class _ContactLensesBodyState extends State<_ContactLensesBody> {
  // Same "tap the KPI → scroll to and heartbeat the matching card" wiring
  // as `FrameInventoryScreen`'s "Out of stock" KPI — see
  // `heartbeat_highlight.dart` for the shared visual.
  String? _highlightedProductId;
  int _highlightToken = 0;
  final Map<String, GlobalKey> _productKeys = {};

  GlobalKey _keyFor(String productId) =>
      _productKeys.putIfAbsent(productId, () => GlobalKey());

  void _focusLowStock(List<ContactLensProduct> products) {
    ContactLensProduct? target;
    for (final p in products) {
      if (p.stock <= ContactLensProductCard.lowStockThreshold) {
        target = p;
        break;
      }
    }
    if (target == null) return;
    final id = target.id;

    setState(() {
      _highlightedProductId = id;
      _highlightToken++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _productKeys[id]?.currentContext;
      if (ctx == null || !mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    });
  }

  String _newProductId() => 'CLP${DateTime.now().millisecondsSinceEpoch}';
  String _newRxId() => 'CLRX${DateTime.now().millisecondsSinceEpoch}';

  void _addProduct(DataProvider dataProvider) {
    showAddRecordDialog(
      context: context,
      title: AppStrings.addDialogContactLensProductTitle,
      fields:  [
        RecordField(key: 'sku', label: AppStrings.recordFieldSku),
        RecordField(key: 'brand', label: AppStrings.recordFieldBrand),
        RecordField(key: 'model', label: AppStrings.recordFieldModel),
        RecordField(key: 'material', label: AppStrings.cardLensMaterial, required: false),
        RecordField(
          key: 'boxQuantity',
          label: AppStrings.contactLensFieldBoxQuantity,
          initialValue: '6',
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'stock',
          label: AppStrings.cardFrameStock,
          initialValue: '0',
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'price',
          label: AppStrings.cardFramePrice,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'supplier',
          label: AppStrings.cardFrameSupplier,
          required: false,
        ),
      ],
      onSubmit: (v) => dataProvider.addContactLensProduct(
        ContactLensProduct(
          id: _newProductId(),
          sku: v['sku']!,
          brand: v['brand']!,
          model: v['model']!,
          material: v['material']!,
          boxQuantity: int.tryParse(v['boxQuantity']!) ?? 6,
          stock: int.tryParse(v['stock']!) ?? 0,
          price: double.tryParse(v['price']!) ?? 0,
          supplier: v['supplier']!,
        ),
      ),
    );
  }

  void _addPrescription(DataProvider dataProvider) {
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
      title: AppStrings.addDialogContactLensRxTitle,
      fields: [
        RecordField(
          key: 'clientId',
          label: AppStrings.recordFieldClient,
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
        RecordField(key: 'brand', label: AppStrings.recordFieldBrand),
        RecordField(
          key: 'powerOD',
          label: AppStrings.recordFieldPowerOD,
          initialValue: '0',
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'baseCurveOD',
          label: AppStrings.recordFieldBcOD,
          initialValue: '8.6',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'diameterOD',
          label: AppStrings.recordFieldDiaOD,
          initialValue: '14.2',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'powerOS',
          label: AppStrings.recordFieldPowerOS,
          initialValue: '0',
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'baseCurveOS',
          label: AppStrings.recordFieldBcOS,
          initialValue: '8.6',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'diameterOS',
          label: AppStrings.recordFieldDiaOS,
          initialValue: '14.2',
          required: false,
          keyboardType: material.TextInputType.number,
        ),
      ],
      onSubmit: (v) => dataProvider.addContactLensPrescription(
        ContactLensPrescription(
          id: _newRxId(),
          clientId: v['clientId']!,
          date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
          brand: v['brand']!,
          powerOD: double.tryParse(v['powerOD']!) ?? 0,
          baseCurveOD: double.tryParse(v['baseCurveOD']!) ?? 0,
          diameterOD: double.tryParse(v['diameterOD']!) ?? 0,
          powerOS: double.tryParse(v['powerOS']!) ?? 0,
          baseCurveOS: double.tryParse(v['baseCurveOS']!) ?? 0,
          diameterOS: double.tryParse(v['diameterOS']!) ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final products = [...dataProvider.contactLensProducts]
      ..sort((a, b) => a.brand.compareTo(b.brand));
    final prescriptions = [...dataProvider.contactLensPrescriptions]
      ..sort((a, b) => b.date.compareTo(a.date));

    final lowStock = products
        .where((p) => p.stock <= ContactLensProductCard.lowStockThreshold)
        .length;
    final stockValue = products.fold<double>(
      0,
      (sum, p) => sum + p.cost * p.stock,
    );

    final clientsById = {for (final p in dataProvider.clients) p.id: p};
    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.navContactLenses).large().bold(),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: [
              DashboardStatCard(
                label: AppStrings.contactLensesKpiProducts,
                value: '${products.length}',
                icon: Icons.visibility_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.frameInventoryKpiStockValue,
                value: '${stockValue.toStringAsFixed(0)} MAD',
                icon: Icons.payments_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.frameInventoryKpiLowStock,
                value: '$lowStock',
                icon: Icons.warning_amber_outlined,
                accent: Colors.orange.shade700,
                onTap: lowStock == 0 ? null : () => _focusLowStock(products),
              ),
              DashboardStatCard(
                label: AppStrings.contactLensesKpiClients,
                value: '${prescriptions.length}',
                icon: Icons.people_outline,
                accent: Colors.teal.shade600,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.contactLensesSectionProducts).semiBold(),
              ),
              Button.outline(
                onPressed: () => _addProduct(dataProvider),
                leading: const Icon(Icons.add, size: 14),
                child: Text(AppStrings.contactLensesAddProductButton),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (products.isEmpty)
            EmptyState(
              icon: Icons.visibility_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final p in products)
                  SizedBox(
                    key: _keyFor(p.id),
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 300,
                    child: HeartbeatHighlight(
                      key: p.id == _highlightedProductId
                          ? ValueKey('hb-${p.id}-$_highlightToken')
                          : ValueKey('hb-${p.id}'),
                      active: p.id == _highlightedProductId,
                      color: colorScheme.destructive,
                      child: ContactLensProductCard(product: p),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.contactLensesSectionPrescriptions,
                ).semiBold(),
              ),
              Button.outline(
                onPressed: () => _addPrescription(dataProvider),
                leading: const Icon(Icons.add, size: 14),
                child: Text(AppStrings.contactLensesAddRxButton),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                for (final rx in prescriptions)
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
                            clientsById[rx.clientId] != null
                                ? '${clientsById[rx.clientId]!.firstName} ${clientsById[rx.clientId]!.lastName}'
                                : AppStrings.taskUnknownClient,
                          ).muted().small(),
                        ),
                        ContactLensPrescriptionCard(prescription: rx),
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
