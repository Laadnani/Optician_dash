import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/frame.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

class FrameCard extends StatelessWidget {
  final Frame frame;
  const FrameCard({super.key, required this.frame});

  static const int lowStockThreshold = 3;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLow = frame.stockAvailable <= lowStockThreshold;
    final isOut = frame.stockAvailable == 0;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${frame.brand} ${frame.model}').semiBold(),
              ),
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
          Text('${frame.color} · ${frame.size} · ${frame.sku}').muted().small(),
          const SizedBox(height: 8),
          Text('${AppStrings.cardFrameStock} ${frame.stockAvailable} (${AppStrings.cardFrameReserved} ${frame.stockReserved})').muted().small(),
          Text('${AppStrings.cardFramePrice} ${frame.price.toStringAsFixed(0)} MAD').muted().small(),
          Text('${AppStrings.cardFrameSupplier} ${frame.supplier}').muted().small(),
        ],
      ),
    );
  }
}
