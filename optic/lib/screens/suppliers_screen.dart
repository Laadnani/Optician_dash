import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/empty_state.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/helpers/add_record_dialog.dart';
import 'package:optic/helpers/record_detail_dialog.dart';
import 'package:optic/helpers/stat_card.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/supplier.dart';
import 'package:optic/widgets/supplier_card.dart';

String _supplierCategoryLabel(String s) {
  switch (s) {
    case 'frames':
      return AppStrings.supplierCategoryFrames;
    case 'lenses':
      return AppStrings.supplierCategoryLenses;
    case 'contactLenses':
      return AppStrings.supplierCategoryContactLenses;
    case 'accessories':
      return AppStrings.supplierCategoryAccessories;
    case 'general':
    default:
      return AppStrings.supplierCategoryGeneral;
  }
}

/// Module 21 — Suppliers (Procurement). Store-wide vendor directory —
/// what [PurchaseOrder] (module 22) references by id.
class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.suppliers),
      bodyBuilder: (context, breakpoint) =>
          _SuppliersBody(breakpoint: breakpoint),
    );
  }
}

class _SuppliersBody extends StatefulWidget {
  final Breakpoint breakpoint;
  const _SuppliersBody({required this.breakpoint});

  @override
  State<_SuppliersBody> createState() => _SuppliersBodyState();
}

class _SuppliersBodyState extends State<_SuppliersBody> {
  String _newId() => 'SUP${DateTime.now().millisecondsSinceEpoch}';

  void _showDetail(Supplier s) {
    showRecordDetailDialog(
      context: context,
      title: s.name,
      subtitle: _supplierCategoryLabel(s.category),
      rows: [
        DetailRow(AppStrings.recordFieldCategory, _supplierCategoryLabel(s.category)),
        if (s.contactPerson.isNotEmpty)
          DetailRow(AppStrings.recordFieldContactPerson, s.contactPerson),
        if (s.phone.isNotEmpty) DetailRow(AppStrings.recordFieldPhone, s.phone),
        if (s.email.isNotEmpty) DetailRow(AppStrings.recordFieldEmail, s.email),
        if (s.paymentTerms.isNotEmpty)
          DetailRow(AppStrings.recordFieldPaymentTerms, s.paymentTerms),
        DetailRow(AppStrings.suppliersKpiAvgRating, '${s.rating}/5'),
      ],
      onDelete: () => context.read<DataProvider>().deleteSupplier(s.id),
    );
  }

  void _addSupplier(DataProvider dataProvider) {
    showAddRecordDialog(
      context: context,
      title: AppStrings.addDialogSupplierTitle,
      fields: [
        RecordField(key: 'name', label: AppStrings.recordFieldName),
        RecordField(
          key: 'category',
          label: AppStrings.recordFieldCategory,
          options:  [
            MapEntry('frames', AppStrings.supplierCategoryFrames),
            MapEntry('lenses', AppStrings.supplierCategoryLenses),
            MapEntry(
              'contactLenses',
              AppStrings.supplierCategoryContactLenses,
            ),
            MapEntry('accessories', AppStrings.supplierCategoryAccessories),
            MapEntry('general', AppStrings.supplierCategoryGeneral),
          ],
        ),
        RecordField(
          key: 'contactPerson',
          label: AppStrings.recordFieldContactPerson,
          required: false,
        ),
        RecordField(
          key: 'phone',
          label: AppStrings.recordFieldPhone,
          required: false,
        ),
        RecordField(
          key: 'email',
          label: AppStrings.recordFieldEmail,
          required: false,
        ),
        RecordField(
          key: 'paymentTerms',
          label: AppStrings.recordFieldPaymentTerms,
          required: false,
        ),
      ],
      onSubmit: (v) => dataProvider.addSupplier(
        Supplier(
          id: _newId(),
          name: v['name']!,
          category: v['category']!,
          contactPerson: v['contactPerson']!,
          phone: v['phone']!,
          email: v['email']!,
          paymentTerms: v['paymentTerms']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final suppliers = [...dataProvider.suppliers]
      ..sort((a, b) => a.name.compareTo(b.name));

    final avgRating = suppliers.isEmpty
        ? 0.0
        : suppliers.fold<int>(0, (sum, s) => sum + s.rating) /
            suppliers.length;

    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navSuppliers).large().bold()),
              PrimaryButton(
                onPressed: () => _addSupplier(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.suppliersAddButton),
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
            childAspectRatio: 3,
            children: [
              DashboardStatCard(
                label: AppStrings.suppliersKpiTotal,
                value: '${suppliers.length}',
                icon: Icons.storefront_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.suppliersKpiAvgRating,
                value: '${avgRating.toStringAsFixed(1)}/5',
                icon: Icons.star_outline,
                accent: Colors.orange.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (suppliers.isEmpty)
            EmptyState(
              icon: Icons.storefront_outlined,
              title: AppStrings.emptyRecordsGeneric,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final s in suppliers)
                  SizedBox(
                    width: widget.breakpoint == Breakpoint.mobile
                        ? double.infinity
                        : 300,
                    child: material.InkWell(
                      onTap: () => _showDetail(s),
                      borderRadius: BorderRadius.circular(12),
                      child: SupplierCard(supplier: s),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
