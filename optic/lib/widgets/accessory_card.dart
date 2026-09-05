import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/accessory.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

String _categoryLabel(String category) {
  switch (category) {
    case 'case':
      return AppStrings.accessoryCategoryCase;
    case 'cleaningSolution':
      return AppStrings.accessoryCategoryCleaningSolution;
    case 'cloth':
      return AppStrings.accessoryCategoryCloth;
    case 'chain':
      return AppStrings.accessoryCategoryChain;
    case 'repairKit':
      return AppStrings.accessoryCategoryRepairKit;
    default:
      return AppStrings.accessoryCategoryOther;
  }
}

class AccessoryCard extends StatelessWidget {
  final Accessory accessory;
  const AccessoryCard({super.key, required this.accessory});

  static const int lowStockThreshold = 5;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLow = accessory.stock <= lowStockThreshold;
    final isOut = accessory.stock == 0;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(accessory.name).semiBold()),
              StatusChip(
                label: isOut
                    ? AppStrings.stockOut
                    : (isLow ? AppStrings.stockLow : AppStrings.stockOk),
                color: isOut
                    ? colorScheme.destructive
                    : (isLow ? Colors.orange.shade700 : Colors.green.shade700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${_categoryLabel(accessory.category)} · ${accessory.sku}')
              .muted()
              .small(),
          const SizedBox(height: 8),
          Text('${AppStrings.cardFrameStock} ${accessory.stock}')
              .muted()
              .small(),
          Text(
            '${AppStrings.cardFramePrice} ${accessory.price.toStringAsFixed(0)} MAD',
          ).muted().small(),
          Text('${AppStrings.cardFrameSupplier} ${accessory.supplier}')
              .muted()
              .small(),
        ],
      ),
    );
  }
}
