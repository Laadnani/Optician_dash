import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/empty_state.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/helpers/add_record_dialog.dart';
import 'package:optic/helpers/heartbeat_highlight.dart';
import 'package:optic/helpers/stat_card.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/accessory.dart';
import 'package:optic/widgets/accessory_card.dart';

/// Module 10 — Accessories. Store-wide catalog for cases, cleaning kits,
/// chains, and repair kits — same shape as `FrameInventoryScreen`/
/// `LensCatalogScreen` (not per-client).
class AccessoriesScreen extends StatelessWidget {
  const AccessoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.accessories),
      bodyBuilder: (context, breakpoint) =>
          _AccessoriesBody(breakpoint: breakpoint),
    );
  }
}

class _AccessoriesBody extends StatefulWidget {
  final Breakpoint breakpoint;
  const _AccessoriesBody({required this.breakpoint});

  @override
  State<_AccessoriesBody> createState() => _AccessoriesBodyState();
}

class _AccessoriesBodyState extends State<_AccessoriesBody> {
  // Same "tap the KPI → scroll to and heartbeat the matching card" wiring
  // as `FrameInventoryScreen`'s "Out of stock" KPI — see
  // `heartbeat_highlight.dart` for the shared visual.
  String? _highlightedAccessoryId;
  int _highlightToken = 0;
  final Map<String, GlobalKey> _accessoryKeys = {};

  GlobalKey _keyFor(String accessoryId) =>
      _accessoryKeys.putIfAbsent(accessoryId, () => GlobalKey());

  void _focusLowStock(List<Accessory> accessories) {
    Accessory? target;
    for (final a in accessories) {
      if (a.stock > 0 && a.stock <= AccessoryCard.lowStockThreshold) {
        target = a;
        break;
      }
    }
    if (target == null) return;
    final id = target.id;

    setState(() {
      _highlightedAccessoryId = id;
      _highlightToken++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _accessoryKeys[id]?.currentContext;
      if (ctx == null || !mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    });
  }

  String _newId() => 'AC${DateTime.now().millisecondsSinceEpoch}';

  void _addAccessory(DataProvider dataProvider) {
    showAddRecordDialog(
      context: context,
      title: AppStrings.addDialogAccessoryTitle,
      fields: [
        RecordField(key: 'sku', label: AppStrings.recordFieldSku),
        RecordField(key: 'name', label: AppStrings.recordFieldName),
        RecordField(
          key: 'category',
          label: AppStrings.recordFieldCategory,
          options:  [
            MapEntry('case', AppStrings.accessoryCategoryCase),
            MapEntry(
              'cleaningSolution',
              AppStrings.accessoryCategoryCleaningSolution,
            ),
            MapEntry('cloth', AppStrings.accessoryCategoryCloth),
            MapEntry('chain', AppStrings.accessoryCategoryChain),
            MapEntry('repairKit', AppStrings.accessoryCategoryRepairKit),
            MapEntry('other', AppStrings.accessoryCategoryOther),
          ],
        ),
        RecordField(
          key: 'brand',
          label: AppStrings.recordFieldBrand,
          required: false,
        ),
        RecordField(
          key: 'price',
          label: AppStrings.cardFramePrice,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'cost',
          label: AppStrings.recordFieldCost,
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'supplier',
          label: AppStrings.cardFrameSupplier,
          required: false,
        ),
        RecordField(
          key: 'stock',
          label: AppStrings.cardFrameStock,
          initialValue: '0',
          keyboardType: material.TextInputType.number,
        ),
      ],
      onSubmit: (v) => dataProvider.addAccessory(
        Accessory(
          id: _newId(),
          sku: v['sku']!,
          name: v['name']!,
          category: v['category']!,
          brand: v['brand']!,
          price: double.tryParse(v['price']!) ?? 0,
          cost: double.tryParse(v['cost']!) ?? 0,
          supplier: v['supplier']!,
          stock: int.tryParse(v['stock']!) ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final accessories = [...dataProvider.accessories]
      ..sort((a, b) => a.name.compareTo(b.name));

    final stockValue = accessories.fold<double>(
      0,
      (sum, a) => sum + a.cost * a.stock,
    );
    final lowStock = accessories
        .where(
          (a) =>
              a.stock > 0 && a.stock <= AccessoryCard.lowStockThreshold,
        )
        .length;

    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navAccessories).large().bold()),
              PrimaryButton(
                onPressed: () => _addAccessory(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.accessoriesAddButton),
              ),
            ],
          ),
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
                label: AppStrings.accessoriesKpiTotal,
                value: '${accessories.length}',
                icon: Icons.shopping_bag_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.accessoriesKpiStockValue,
                value: '${stockValue.toStringAsFixed(0)} MAD',
                icon: Icons.payments_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.accessoriesKpiLowStock,
                value: '$lowStock',
                icon: Icons.warning_amber_outlined,
                accent: Colors.orange.shade700,
                onTap: lowStock == 0
                    ? null
                    : () => _focusLowStock(accessories),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (accessories.isEmpty)
            EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final a in accessories)
                  SizedBox(
                    key: _keyFor(a.id),
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 300,
                    child: HeartbeatHighlight(
                      key: a.id == _highlightedAccessoryId
                          ? ValueKey('hb-${a.id}-$_highlightToken')
                          : ValueKey('hb-${a.id}'),
                      active: a.id == _highlightedAccessoryId,
                      color: colorScheme.destructive,
                      child: AccessoryCard(accessory: a),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
