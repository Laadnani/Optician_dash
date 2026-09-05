import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/empty_state.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/helpers/add_record_dialog.dart';
import 'package:optic/helpers/stat_card.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/lens.dart';
import 'package:optic/widgets/lens_card.dart';

/// Module 5 — Lens Product Management. Store-wide lens catalog — every
/// lens product carried, filterable by type, with a KPI strip covering
/// catalog size, average price, and how many products carry premium
/// coatings (anything beyond plain scratch/AR).
class LensCatalogScreen extends StatelessWidget {
  const LensCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.lensCatalog),
      bodyBuilder: (context, breakpoint) =>
          _LensCatalogBody(breakpoint: breakpoint),
    );
  }
}

class _LensCatalogBody extends StatefulWidget {
  final Breakpoint breakpoint;
  const _LensCatalogBody({required this.breakpoint});

  @override
  State<_LensCatalogBody> createState() => _LensCatalogBodyState();
}

class _LensCatalogBodyState extends State<_LensCatalogBody> {
  String? _typeFilter;

  String _newId() => 'LN${DateTime.now().millisecondsSinceEpoch}';

  void _addLens(DataProvider dataProvider) {
    showAddRecordDialog(
      context: context,
      title: AppStrings.addDialogLensTitle,
      fields: [
        RecordField(key: 'sku', label: AppStrings.recordFieldSku),
        RecordField(
          key: 'manufacturer',
          label: AppStrings.recordFieldManufacturer,
        ),
        RecordField(key: 'brand', label: AppStrings.recordFieldBrand),
        RecordField(
          key: 'productName',
          label: AppStrings.recordFieldProductName,
        ),
        RecordField(
          key: 'lensType',
          label: AppStrings.lensFieldType,
          options:  [
            MapEntry('singleVision', AppStrings.lensTypeSingleVision),
            MapEntry('bifocal', AppStrings.lensTypeBifocal),
            MapEntry('progressive', AppStrings.lensTypeProgressive),
            MapEntry('occupational', AppStrings.lensTypeOccupational),
            MapEntry('computer', AppStrings.lensTypeComputer),
            MapEntry('myopiaControl', AppStrings.lensTypeMyopiaControl),
            MapEntry('plano', AppStrings.lensTypePlano),
            MapEntry('sunglasses', AppStrings.lensTypeSunglasses),
            MapEntry('specialty', AppStrings.lensTypeSpecialty),
          ],
        ),
        RecordField(
          key: 'material',
          label: AppStrings.cardLensMaterial,
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
      ],
      onSubmit: (v) => dataProvider.addLens(
        Lens(
          id: _newId(),
          sku: v['sku']!,
          manufacturer: v['manufacturer']!,
          brand: v['brand']!,
          productName: v['productName']!,
          lensType: v['lensType']!,
          material: v['material']!,
          price: double.tryParse(v['price']!) ?? 0,
          cost: double.tryParse(v['cost']!) ?? 0,
          supplier: v['supplier']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final lenses = [...dataProvider.lenses]
      ..sort((a, b) => a.productName.compareTo(b.productName));

    final avgPrice = lenses.isEmpty
        ? 0.0
        : lenses.fold<double>(0, (sum, l) => sum + l.price) / lenses.length;
    final premium = lenses.where((l) => l.coatings.length >= 3).length;

    final filtered = _typeFilter == null
        ? lenses
        : lenses.where((l) => l.lensType == _typeFilter).toList();

    final typeOptions = <String?, String>{
      null: AppStrings.lensFilterAllTypes,
      'singleVision': AppStrings.lensTypeSingleVision,
      'bifocal': AppStrings.lensTypeBifocal,
      'progressive': AppStrings.lensTypeProgressive,
      'occupational': AppStrings.lensTypeOccupational,
      'computer': AppStrings.lensTypeComputer,
      'myopiaControl': AppStrings.lensTypeMyopiaControl,
      'plano': AppStrings.lensTypePlano,
      'sunglasses': AppStrings.lensTypeSunglasses,
      'specialty': AppStrings.lensTypeSpecialty,
    };

    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navLensCatalog).large().bold()),
              PrimaryButton(
                onPressed: () => _addLens(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.lensCatalogAddButton),
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
                label: AppStrings.lensCatalogKpiTotal,
                value: '${lenses.length}',
                icon: Icons.blur_on_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.lensCatalogKpiAvgPrice,
                value: '${avgPrice.toStringAsFixed(0)} MAD',
                icon: Icons.payments_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.lensCatalogKpiPremium,
                value: '$premium',
                icon: Icons.stars_outlined,
                accent: Colors.purple.shade400,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 220,
            child: material.DropdownButtonFormField<String>(
              value: _typeFilter,
              isDense: true,
              // Same fix as add_record_dialog.dart — lets the ellipsis on
              // long option labels actually take effect instead of
              // overflowing the fixed-width field on narrow screens.
              isExpanded: true,
              items: [
                for (final entry in typeOptions.entries)
                  material.DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _typeFilter = v),
              decoration: const material.InputDecoration(
                border: material.OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            EmptyState(
              icon: Icons.blur_on_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final l in filtered)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 320,
                    child: LensCard(lens: l),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
