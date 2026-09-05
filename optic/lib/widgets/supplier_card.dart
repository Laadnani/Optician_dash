import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/supplier.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

String _categoryLabel(String category) {
  switch (category) {
    case 'frames':
      return AppStrings.supplierCategoryFrames;
    case 'lenses':
      return AppStrings.supplierCategoryLenses;
    case 'contactLenses':
      return AppStrings.supplierCategoryContactLenses;
    case 'accessories':
      return AppStrings.supplierCategoryAccessories;
    default:
      return AppStrings.supplierCategoryGeneral;
  }
}

class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  const SupplierCard({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(supplier.name).semiBold()),
              StatusChip(
                label: '★ ${supplier.rating}/5',
                color: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_categoryLabel(supplier.category)).muted().small(),
          const SizedBox(height: 8),
          if (supplier.contactPerson.isNotEmpty)
            Text(
              '${AppStrings.cardSupplierContact} ${supplier.contactPerson}',
            ).muted().small(),
          if (supplier.phone.isNotEmpty)
            Text(supplier.phone).muted().small(),
          if (supplier.paymentTerms.isNotEmpty)
            Text(
              '${AppStrings.cardSupplierTerms} ${supplier.paymentTerms}',
            ).muted().small(),
        ],
      ),
    );
  }
}
